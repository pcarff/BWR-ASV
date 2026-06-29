#!/usr/bin/env python3
"""
Blue-Water Rover: Main Autopilot, Sensor Aggregator & Telemetry Server
Coordinates RC manual override, GPS waypoint navigation, depth obstacle avoidance,
and starts the Flask server to host the local HUD dashboard.
"""

import sys
import os
import time
import threading
import logging
from flask import Flask, jsonify, request, send_from_directory

# Include parent directory in search path to load comms modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from src.spektrum_rc import SpektrumRC
from src.drive_control import DriveControl
from src.navigation import NavigationController
from src.perception import RealSenseDetector
from comms.telemetry_handler import TelemetryHandler

logger = logging.getLogger("AutopilotMain")
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

# Global Autopilot State
class AutopilotState:
    def __init__(self):
        self.mode = "MANUAL"       # "MANUAL" or "AUTO"
        self.cruise_throttle = 0.5  # 50% cruise speed
        self.battery_pct = 85.0
        self.battery_v = 51.2
        self.solar_w = 280.0
        self.prop_w = 0.0
        self.sys_w = 12.0
        self.killed = False

# Instantiate Flask App
hud_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "hud")
app = Flask(__name__, static_folder=hud_dir)
state = AutopilotState()

# Control instances (Global references)
rc = None
drive = None
nav = None
perception = None
tel = None

@app.route("/")
def serve_index():
    return send_from_directory(hud_dir, "index.html")

@app.route("/<path:path>")
def serve_static(path):
    return send_from_directory(hud_dir, path)

@app.route("/api/telemetry", methods=["GET"])
def get_telemetry():
    """Compiles all telemetry fields to serve the HUD dashboard poller."""
    nav_state = nav.get_navigation_state() if nav else {}
    per_dists = perception.get_distances() if perception else {"left": 20.0, "center": 20.0, "right": 20.0}
    avoid_offset = perception.get_steering_offset() if perception else 0.0
    drive_state = drive.get_current_values() if drive else {"throttle_us": 1500, "rudder_us": 1500, "killed": False}

    # Simulate battery consumption and solar charging
    # Battery bank: 48V 115Ah (~5520 Wh).
    if not state.killed:
        # Calculate propulsion power based on current throttle us (neutral is 1500)
        throttle_fraction = abs(drive_state["throttle_us"] - 1500.0) / 500.0
        state.prop_w = throttle_fraction * 350.0  # Max power is 350W for single T200 thruster
        
        # Calculate net change (Solar - Prop - Systems)
        net_w = state.solar_w - state.prop_w - state.sys_w
        # Scale consumption per hour (divided by 36000 for 10Hz loop step)
        state.battery_pct = max(0.0, min(100.0, state.battery_pct + (net_w / (5520.0 * 10.0))))
        state.battery_v = 44.0 + (state.battery_pct / 100.0) * 8.0 # scale 44V to 52V
    else:
        state.prop_w = 0.0

    return jsonify({
        "mode": state.mode,
        "killed": state.killed or drive_state["killed"],
        "battery_pct": round(state.battery_pct, 1),
        "battery_v": round(state.battery_v, 2),
        "solar_w": round(state.solar_w, 1),
        "prop_w": round(state.prop_w, 1),
        "sys_w": state.sys_w,
        "net_w": round(state.solar_w - state.prop_w - state.sys_w, 1),
        
        # Navigation
        "lat": nav_state.get("lat", 0.0),
        "lon": nav_state.get("lon", 0.0),
        "cog": round(nav_state.get("cog", 0.0), 1),
        "sog": round(nav_state.get("sog", 0.0), 2),
        "target_bearing": round(nav_state.get("target_bearing", 0.0), 1),
        "distance_to_wp": round(nav_state.get("distance_to_wp", 99999.0), 1),
        "queue_len": nav_state.get("queue_len", 0),
        "gps_connected": nav_state.get("gps_connected", False),
        
        # Perception (RealSense D455)
        "closest_left": round(per_dists["left"], 2),
        "closest_center": round(per_dists["center"], 2),
        "closest_right": round(per_dists["right"], 2),
        "avoid_offset": round(avoid_offset, 2),
        
        # Actuation
        "throttle_us": drive_state["throttle_us"],
        "rudder_us": drive_state["rudder_us"],
        
        # Companion RC status
        "rc_connected": rc.is_connected() if rc else False
    })

@app.route("/api/command", methods=["POST"])
def post_command():
    """Handles commands sent from the HUD console (e.g. manual overrides, waypoints)."""
    data = request.json
    cmd = data.get("command", "").upper()
    
    if cmd == "KILL":
        execute_kill()
        return jsonify({"status": "accepted", "message": "Emergency kill triggered"})
    elif cmd == "RESET_KILL":
        state.killed = False
        if drive:
            drive.reset_kill()
        return jsonify({"status": "accepted", "message": "Emergency kill reset"})
    elif cmd == "AUTO":
        state.mode = "AUTO"
        return jsonify({"status": "accepted", "mode": "AUTO"})
    elif cmd == "MANUAL":
        state.mode = "MANUAL"
        return jsonify({"status": "accepted", "mode": "MANUAL"})
    elif cmd == "CLEAR_WP":
        if nav:
            nav.clear_waypoints()
        return jsonify({"status": "accepted", "message": "Waypoints cleared"})
    elif cmd == "ADD_WP":
        lat = data.get("lat")
        lon = data.get("lon")
        idx = data.get("index", 1)
        if nav and lat is not None and lon is not None:
            nav.add_waypoint(idx, float(lat), float(lon))
            return jsonify({"status": "accepted", "message": f"Waypoint {idx} added"})
        return jsonify({"status": "error", "message": "Invalid latitude/longitude"})
    
    return jsonify({"status": "error", "message": "Unsupported command"})


# Telemetry Uplink Callbacks (translating MeshCore ASCII commands)
def on_meshcore_wp(index_str, lat_str, lon_str):
    try:
        idx = int(index_str)
        lat = float(lat_str)
        lon = float(lon_str)
        if nav:
            nav.add_waypoint(idx, lat, lon)
            tel.send_packet(f"TEL:ACK,NAV:WP,INDEX={idx:02d},STATUS=ACCEPTED")
    except ValueError as e:
        logger.error(f"Uplink WP parse error: {e}")
        tel.send_packet("TEL:ERR,MSG=INVALID_WP_ARGS")

def on_meshcore_hold():
    logger.warning("Uplink command received: NAV:HOLD")
    state.mode = "MANUAL"
    if drive:
        drive.set_throttle(0.0)
        drive.set_rudder(0.0)
    tel.send_packet("TEL:ACK,NAV:HOLD,STATUS=LOITERING")

def on_meshcore_kill():
    logger.critical("Uplink EMERGENCY KILL received!")
    execute_kill()
    tel.send_packet("TEL:ACK,NAV:KILL,EMERGENCY_SHUTDOWN=ACTIVE")

def on_meshcore_req():
    send_telemetry_diagnostic()

def execute_kill():
    state.killed = True
    state.mode = "MANUAL"
    if drive:
        drive.kill()

def send_telemetry_diagnostic():
    """Generates and sends standard $TEL:DIAG frame over the serial channel."""
    if not tel:
        return
        
    nav_state = nav.get_navigation_state() if nav else {}
    lat = nav_state.get("lat", 0.0)
    lon = nav_state.get("lon", 0.0)
    sog = nav_state.get("sog", 0.0)
    q_len = nav_state.get("queue_len", 0)
    
    # Compile frame arguments
    bat = round(state.battery_pct, 1)
    sol = round(state.solar_w, 1)
    prop = round(state.prop_w, 1)
    op_state = "SHUTDOWN" if state.killed else ("CRUISING" if state.mode == "AUTO" else "LOITERING")
    throt_state = "ACTIVE" if (state.mode == "AUTO" and not state.killed) else "OFF"
    
    payload = f"TEL:DIAG,BAT={bat}%,SOL={sol}W,PROP={prop}W,LAT={lat:.5f},LON={lon:.5f},SPEED={sog:.1f}KT,STATE={op_state},THROTTLE={throt_state},WP_Q={q_len}"
    tel.send_packet(payload)


def run_autopilot_loop():
    """10Hz Autopilot Main Loop coordinating RC, nav navigation, and perception avoidance."""
    logger.info("Autopilot navigation loop thread started (running at 10Hz).")
    
    last_diagnostic_time = time.time()
    
    while True:
        loop_start = time.time()
        
        # 1. Update Mode from Spektrum RC Switch
        if rc and rc.is_connected():
            rc_auto = rc.get_auto_mode()
            if rc_auto and state.mode == "MANUAL" and not state.killed:
                logger.info("RC Switch toggled to Autonomous Mode.")
                state.mode = "AUTO"
            elif not rc_auto and state.mode == "AUTO":
                logger.info("RC Switch toggled to Manual Mode.")
                state.mode = "MANUAL"

        # 2. Compute Steering and Throttle Outputs
        if state.killed:
            # Force zero output if killed
            if drive:
                drive.kill()
        elif state.mode == "MANUAL":
            # Manual Mode: Map RC transmitter directly to actuators
            if rc and rc.is_connected():
                throttle = rc.get_throttle() # 0 to 1.0
                rudder = rc.get_rudder()     # -1.0 to 1.0
                if drive:
                    drive.set_throttle(throttle, dt=0.1)
                    drive.set_rudder(rudder)
            else:
                # RC signal lost in manual mode: stop motor, center rudder
                if drive:
                    drive.set_throttle(0.0)
                    drive.set_rudder(0.0)
        elif state.mode == "AUTO":
            # Autonomous Mode: Fuse navigation PID output and perception avoidance
            nav_rudder = 0.0
            if nav:
                nav_state = nav.get_navigation_state()
                nav_rudder = nav_state.get("rudder_cmd", 0.0)
            
            avoid_offset = 0.0
            if perception:
                avoid_offset = perception.get_steering_offset()

            # Fuse steering commands and clamp output
            target_rudder = nav_rudder + avoid_offset
            target_rudder = max(-1.0, min(1.0, target_rudder))
            
            # Autopilot cruise throttle
            target_throttle = state.cruise_throttle
            
            # Apply dynamic throttling based on safety factors
            # If obstacle in front is extremely close (< 4m), slow down or reverse
            if perception:
                dists = perception.get_distances()
                if dists["center"] < 4.0:
                    target_throttle = -0.2  # Dynamic reverse to back off
                elif dists["center"] < 7.0:
                    target_throttle = 0.15  # Slow down speed

            if drive:
                drive.set_throttle(target_throttle, dt=0.1)
                drive.set_rudder(target_rudder)

        # 3. Handle Telemetry Diagnostics
        # Send diagnostic packets every 5 seconds
        if time.time() - last_diagnostic_time >= 5.0:
            send_telemetry_diagnostic()
            last_diagnostic_time = time.time()
            
            # Periodically query telemetry watchdog
            if tel:
                tel.check_link_status()

        # Enforce exact 10Hz loop rate (0.1s step)
        elapsed = time.time() - loop_start
        sleep_time = max(0.01, 0.1 - elapsed)
        time.sleep(sleep_time)


def start_flask_server():
    """Starts the Flask server in a separate thread."""
    # Suppress verbose Flask console logs
    cli = sys.modules['flask.cli']
    cli.show_server_banner = lambda *x: None
    logging.getLogger('werkzeug').setLevel(logging.ERROR)
    
    logger.info("Starting local HUD web server on port 5000...")
    app.run(host="0.0.0.0", port=5000, debug=False, use_reloader=False)


if __name__ == "__main__":
    logger.info("Initializing Blue-Water Rover ASV Control Stack...")
    
    # 1. Initialize Spektrum RC satellite receiver
    rc = SpektrumRC(port="/dev/ttyAMA0")
    rc.daemon = True
    rc.start()
    
    # 2. Initialize Drive PWM Controller
    drive = DriveControl(throttle_pin=18, rudder_pin=19)
    
    # 3. Initialize GPS Navigation Controller (automatically defaults to sim if no serial)
    nav = NavigationController(port="/dev/ttyACM0")
    nav.daemon = True
    nav.start()
    
    # 4. Initialize RealSense Obstacle Detector (automatically defaults to sim if no camera)
    perception = RealSenseDetector()
    perception.daemon = True
    perception.start()
    
    # 5. Initialize MeshCore Telemetry Serial Handler
    tel = TelemetryHandler(serial_conn=None) # Mock serial for testing, parses internally
    tel.register_callback("NAV:WP", on_meshcore_wp)
    tel.register_callback("NAV:HOLD", on_meshcore_hold)
    tel.register_callback("NAV:KILL", on_meshcore_kill)
    tel.register_callback("TEL:REQ", on_meshcore_req)
    
    # Hook up telemetry lost safety callback (revert to manual / hold on signal loss)
    tel.register_heartbeat_lost_callback(on_meshcore_hold)

    # 6. Start Autopilot Thread
    autopilot_thread = threading.Thread(target=run_autopilot_loop)
    autopilot_thread.daemon = True
    autopilot_thread.start()
    
    # 7. Start Dashboard Web server
    start_flask_server()
