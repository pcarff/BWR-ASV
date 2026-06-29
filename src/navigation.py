#!/usr/bin/env python3
"""
Blue-Water Rover: GPS Parsing & Navigation Controller
Parses NMEA serial data, sequences waypoints, and executes a heading PID loop
to control the rudder deflection. Includes a simulator fallback.
"""

import threading
import time
import math
import serial
import logging

logger = logging.getLogger("Navigation")
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

class NavigationController(threading.Thread):
    def __init__(self, port="/dev/ttyACM0", baudrate=9600, timeout=0.1, kp=0.02, ki=0.0001, kd=0.005):
        super().__init__()
        self.port = port
        self.baudrate = baudrate
        self.timeout = timeout
        self.running = False
        
        # Waypoints queue: list of dicts {"lat": float, "lon": float, "index": int}
        self._waypoints = []
        self._current_wp_idx = 0
        self.acceptance_radius_m = 15.0  # 15 meters acceptance radius
        
        # PID Controller constants
        self.kp = kp
        self.ki = ki
        self.kd = kd
        
        # PID State
        self.error_sum = 0.0
        self.last_error = 0.0
        self.last_pid_time = time.time()
        
        # Thread-safe telemetry state
        self._lock = threading.Lock()
        self._lat = 0.0
        self._lon = 0.0
        self._cog = 0.0         # Course Over Ground (degrees)
        self._sog = 0.0         # Speed Over Ground (knots)
        self._target_bearing = 0.0
        self._distance_to_wp = 99999.0
        self._rudder_command = 0.0 # -1.0 (left) to 1.0 (right)
        self._gps_connected = False
        
        # Simulator state variables (used if GPS serial fails)
        self.sim_mode = False
        self.sim_lat = 32.776
        self.sim_lon = -79.931
        self.sim_heading = 180.0
        self.sim_speed = 5.0

    def run(self):
        self.running = True
        logger.info(f"Starting GPS & Navigation thread on port: {self.port}")
        
        ser = None
        try:
            ser = serial.Serial(self.port, self.baudrate, timeout=self.timeout)
            logger.info(f"Opened GPS serial port: {self.port}")
        except Exception as e:
            logger.warning(f"Could not open GPS port {self.port}: {e}. Running in Simulator Mode.")
            self.sim_mode = True
            
        if self.sim_mode:
            self._run_sim_loop()
        else:
            self._run_hardware_loop(ser)

    def stop(self):
        self.running = False

    def _run_hardware_loop(self, ser):
        """Hardware loop: reads serial NMEA sentences and runs PID control."""
        buffer = ""
        while self.running:
            try:
                data = ser.readline().decode("ascii", errors="ignore")
                if not data:
                    continue
                
                buffer += data
                if "\n" in buffer:
                    line = buffer.split("\n")[0].strip()
                    buffer = buffer.split("\n")[1]
                    
                    if line.startswith(("$GPRMC", "$GNRMC", "$GPGGA", "$GNGGA")):
                        self._parse_nmea(line)
                        self._run_navigation_step()
            except Exception as e:
                logger.error(f"Error in hardware GPS loop: {e}")
                time.sleep(0.05)
                
        if ser and ser.is_open:
            ser.close()

    def _run_sim_loop(self):
        """Simulated navigation loop when hardware GPS is not present."""
        last_time = time.time()
        while self.running:
            curr_time = time.time()
            dt = curr_time - last_time
            last_time = curr_time
            
            # Simple kinematic simulation of the catamaran
            # Speed is knots, convert to m/s: 1 knot = 0.5144 m/s
            speed_m_s = self.sim_speed * 0.5144
            
            # Calculate distance traveled
            distance = speed_m_s * dt
            
            # Translate lat/lon based on heading
            # 1 degree lat = 111,000 meters
            # 1 degree lon = 111,000 * cos(lat) meters
            heading_rad = math.radians(self.sim_heading)
            delta_lat = (distance * math.cos(heading_rad)) / 111000.0
            delta_lon = (distance * math.sin(heading_rad)) / (111000.0 * math.cos(math.radians(self.sim_lat)))
            
            self.sim_lat += delta_lat
            self.sim_lon += delta_lon
            
            # Simulate heading response to rudder input
            # Rudder input of 1.0 deflects heading at 15 degrees/second
            with self._lock:
                rudder = self._rudder_command
                
            self.sim_heading = (self.sim_heading + (rudder * 15.0 * dt)) % 360.0
            
            # Update telemetry values
            with self._lock:
                self._lat = self.sim_lat
                self._lon = self.sim_lon
                self._cog = self.sim_heading
                self._sog = self.sim_speed
                self._gps_connected = True
                
            self._run_navigation_step()
            time.sleep(0.1)

    def _parse_nmea(self, sentence):
        """Parses standard GPS RMC sentences for Lat, Lon, COG, and SOG."""
        parts = sentence.split(",")
        if len(parts) < 10:
            return

        header = parts[0]
        try:
            # Parse RMC: $xxRMC,time,status,lat,N/S,lon,E/W,speed_knots,heading_cog,date,...
            if "RMC" in header and parts[2] == "A":
                # Latitude
                lat_raw = float(parts[3])
                lat_deg = int(lat_raw / 100)
                lat_min = lat_raw - (lat_deg * 100)
                lat = lat_deg + (lat_min / 60.0)
                if parts[4] == "S":
                    lat = -lat
                
                # Longitude
                lon_raw = float(parts[5])
                lon_deg = int(lon_raw / 100)
                lon_min = lon_raw - (lon_deg * 100)
                lon = lon_deg + (lon_min / 60.0)
                if parts[6] == "W":
                    lon = -lon

                sog = float(parts[7]) if parts[7] else 0.0
                cog = float(parts[8]) if parts[8] else 0.0

                with self._lock:
                    self._lat = lat
                    self._lon = lon
                    self._sog = sog
                    self._cog = cog
                    self._gps_connected = True
        except ValueError:
            pass

    def _run_navigation_step(self):
        """Computes distance, target bearing, and runs PID heading controls."""
        with self._lock:
            lat = self._lat
            lon = self._lon
            cog = self._cog
            wps = list(self._waypoints)

        if not wps:
            # No waypoints, set rudder to center
            with self._lock:
                self._rudder_command = 0.0
                self._distance_to_wp = 99999.0
                self._target_bearing = 0.0
            return

        target_wp = wps[0]
        
        # Calculate distance and bearing to waypoint
        dist_m = self._calculate_distance(lat, lon, target_wp["lat"], target_wp["lon"])
        bearing_deg = self._calculate_bearing(lat, lon, target_wp["lat"], target_wp["lon"])
        
        # Check waypoint acceptance radius
        if dist_m < self.acceptance_radius_m:
            logger.info(f"Waypoint {target_wp.get('index', 0)} reached! Switching to next waypoint.")
            with self._lock:
                if self._waypoints:
                    self._waypoints.pop(0)
                    self._current_wp_idx += 1
            return

        # Heading error wrapped to [-180, 180] degrees
        heading_error = bearing_deg - cog
        heading_error = (heading_error + 180) % 360 - 180
        
        # Execute PID Controller
        curr_time = time.time()
        dt = curr_time - self.last_pid_time
        if dt < 0.01:
            dt = 0.01
        self.last_pid_time = curr_time
        
        # Proportional term
        p_term = self.kp * heading_error
        
        # Integral term (windup protection: limit error sum to +/- 30 degrees)
        self.error_sum = max(-30.0, min(30.0, self.error_sum + (heading_error * dt)))
        i_term = self.ki * self.error_sum
        
        # Derivative term
        d_term = self.kd * ((heading_error - self.last_error) / dt)
        self.last_error = heading_error
        
        # Output is rudder fraction: positive is right (steer right to correct left error)
        # Negative is left. Clamp output to [-1.0, 1.0]
        output = p_term + i_term + d_term
        output = max(-1.0, min(1.0, output))
        
        with self._lock:
            self._rudder_command = output
            self._distance_to_wp = dist_m
            self._target_bearing = bearing_deg

    def _calculate_distance(self, lat1, lon1, lat2, lon2):
        """Haversine formula to compute distance in meters between two points."""
        R = 6371000.0  # Earth radius in meters
        phi1 = math.radians(lat1)
        phi2 = math.radians(lat2)
        d_phi = math.radians(lat2 - lat1)
        d_lambda = math.radians(lon2 - lon1)
        
        a = math.sin(d_phi / 2.0)**2 + math.cos(phi1) * math.cos(phi2) * math.sin(d_lambda / 2.0)**2
        c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
        return R * c

    def _calculate_bearing(self, lat1, lon1, lat2, lon2):
        """Calculates initial bearing (degrees) from point 1 to point 2."""
        phi1 = math.radians(lat1)
        phi2 = math.radians(lat2)
        delta_lon = math.radians(lon2 - lon1)
        
        y = math.sin(delta_lon) * math.cos(phi2)
        x = math.cos(phi1) * math.sin(phi2) - math.sin(phi1) * math.cos(phi2) * math.cos(delta_lon)
        
        bearing = math.atan2(y, x)
        return (math.degrees(bearing) + 360.0) % 360.0

    # Thread-safe getters & setters
    def add_waypoint(self, index, lat, lon):
        with self._lock:
            self._waypoints.append({"index": index, "lat": lat, "lon": lon})
            logger.info(f"Added waypoint {index} at {lat:.5f}, {lon:.5f}")

    def clear_waypoints(self):
        with self._lock:
            self._waypoints.clear()
            self._current_wp_idx = 0
            self._distance_to_wp = 99999.0
            self._target_bearing = 0.0
            self._rudder_command = 0.0
            logger.info("Cleared all waypoints from queue.")

    def get_navigation_state(self):
        with self._lock:
            q_len = len(self._waypoints)
            next_wp = self._waypoints[0] if q_len > 0 else None
            return {
                "lat": self._lat,
                "lon": self._lon,
                "cog": self._cog,
                "sog": self._sog,
                "target_bearing": self._target_bearing,
                "distance_to_wp": self._distance_to_wp,
                "rudder_cmd": self._rudder_command,
                "queue_len": q_len,
                "gps_connected": self._gps_connected,
                "sim_mode": self.sim_mode,
                "next_wp": next_wp
            }

# Self-test block
if __name__ == "__main__":
    logger.info("Running Navigation Controller self-test in simulator mode...")
    controller = NavigationController()
    controller.sim_mode = True
    
    # Add some local waypoints (approx. 100m steps in a triangle)
    controller.add_waypoint(1, 32.777, -79.931)
    controller.add_waypoint(2, 32.777, -79.930)
    controller.add_waypoint(3, 32.776, -79.931)
    
    controller.daemon = True
    controller.start()
    
    try:
        while True:
            state = controller.get_navigation_state()
            if state["queue_len"] > 0:
                print(f"WP: {state['next_wp']['index']} | Dist: {state['distance_to_wp']:.1f}m | Lat: {state['lat']:.5f} Lon: {state['lon']:.5f} | HDG: {state['cog']:.1f} | Bearing: {state['target_bearing']:.1f} | Rudder: {state['rudder_cmd']:+.2f}", end="\r")
            else:
                print("All waypoints completed! Mission Finished.                      ")
                break
            time.sleep(0.2)
    except KeyboardInterrupt:
        controller.stop()
        print("\nTest terminated.")
