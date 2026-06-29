#!/usr/bin/env python3
"""
Blue-Water Rover: Spektrum Remote Receiver (Satellite) Serial Parser
Parses Spektrum DSMX/DSM2 serial frames (16 bytes at 115200 baud) over UART.
"""

import serial
import threading
import time
import logging

logger = logging.getLogger("SpektrumRC")
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

class SpektrumRC(threading.Thread):
    def __init__(self, port="/dev/ttyAMA0", baudrate=115200, timeout=0.1):
        super().__init__()
        self.port = port
        self.baudrate = baudrate
        self.timeout = timeout
        self.running = False
        
        # Thread-safe telemetry state
        self._lock = threading.Lock()
        self._channels = {
            0: 1024,  # Throttle (ID 0): 0 to 2047 (neutral ~1024, or 0 if unipolar)
            1: 1024,  # Aileron (ID 1)
            2: 1024,  # Elevator (ID 2)
            3: 1024,  # Rudder (ID 3): 0 to 2047 (neutral ~1024)
            4: 1024,  # Gear/Mode (ID 4): High/Low toggle
            5: 1024,  # Aux1 (ID 5)
            6: 1024,  # Aux2 (ID 6)
        }
        self._last_frame_time = 0.0
        self._connected = False

    def run(self):
        self.running = True
        logger.info(f"Starting Spektrum RC parser thread on serial port: {self.port}")
        
        ser = None
        while self.running:
            try:
                ser = serial.Serial(self.port, self.baudrate, timeout=self.timeout)
                logger.info(f"Successfully opened serial port: {self.port}")
                break
            except Exception as e:
                logger.error(f"Failed to open serial port {self.port}: {e}. Retrying in 2 seconds...")
                time.sleep(2)

        if not ser:
            self.running = False
            return

        frame_buf = bytearray()
        last_byte_time = time.time()

        while self.running:
            try:
                # Read incoming bytes
                data = ser.read(1)
                if not data:
                    # Timeout reached
                    self._check_connection()
                    continue

                curr_time = time.time()
                
                # Frame Sync: quiet period between Spektrum bursts is typically > 5ms
                if curr_time - last_byte_time > 0.005:
                    # Clear buffer on quiet gap, next byte is start of frame
                    frame_buf.clear()

                frame_buf.extend(data)
                last_byte_time = curr_time

                if len(frame_buf) == 16:
                    self._parse_frame(frame_buf)
                    frame_buf.clear()

            except Exception as e:
                logger.error(f"Error in serial reading loop: {e}")
                time.sleep(0.1)

            self._check_connection()

        if ser and ser.is_open:
            ser.close()
            logger.info("Closed Spektrum serial port.")

    def stop(self):
        self.running = False

    def _check_connection(self):
        """Connection watchdog. Failsafe triggers if no frame for > 1.0 second."""
        with self._lock:
            if time.time() - self._last_frame_time > 1.0:
                if self._connected:
                    logger.warning("Spektrum RC signal lost! Failsafe values applied.")
                    self._connected = False
                # Revert to safe defaults
                self._channels[0] = 1024  # Neutral/Stop Throttle
                self._channels[3] = 1024  # Centered Rudder
                self._channels[4] = 1024  # Manual default

    def _parse_frame(self, frame):
        """
        Parses a valid 16-byte Spektrum satellite frame.
        DSMX/DSM2 Frame structure:
        - Byte 0: Fades / status count
        - Byte 1: System ID (0xA2/0xB2 = DSMX 11-bit, 0x01/0x02 = DSM2 10-bit)
        - Bytes 2-15: 7 channels of 16-bit words (big-endian)
        """
        sys_id = frame[1]
        
        # Determine protocol format: DSMX (11-bit resolution) vs DSM2 (10-bit resolution)
        is_11bit = sys_id in (0xA2, 0xB2) or sys_id > 0x10 # Standard heuristic
        
        channels_updated = {}
        
        for i in range(1, 8):
            offset = i * 2
            word = (frame[offset] << 8) | frame[offset + 1]
            
            if is_11bit:
                # 11-bit: 4 bits channel ID (bits 14-11), 11 bits value (bits 10-0)
                # Word mask: ID is bits 14-11 (shift 11, mask 0x0F)
                chan_id = (word >> 11) & 0x0F
                value = word & 0x07FF  # 0 to 2047
            else:
                # 10-bit: 4 bits channel ID (bits 13-10), 10 bits value (bits 9-0)
                chan_id = (word >> 10) & 0x0F
                value = word & 0x03FF  # 0 to 1023
                # Scale 10-bit values to 11-bit (0-2047) for unified access
                value = value * 2

            if chan_id < 16:
                channels_updated[chan_id] = value

        with self._lock:
            for chan_id, val in channels_updated.items():
                if chan_id in self._channels:
                    self._channels[chan_id] = val
            self._last_frame_time = time.time()
            self._connected = True

    # Thread-safe getters
    def get_channel(self, channel_id):
        with self._lock:
            return self._channels.get(channel_id, 1024)

    def is_connected(self):
        with self._lock:
            return self._connected

    def get_throttle(self):
        """Returns throttle input scaled from -1.0 to +1.0 (or 0.0 to 1.0 for unipolar)."""
        val = self.get_channel(0)  # Channel 0 is standard Throttle
        # Map 11-bit (0 to 2047) to float
        # Assuming unipolar throttle: 0 (stop) to 2047 (full speed forward)
        return val / 2047.0

    def get_rudder(self):
        """Returns rudder input scaled from -1.0 (full left) to +1.0 (full right)."""
        val = self.get_channel(3)  # Channel 3 is standard Rudder
        # Map 11-bit (0 to 2047, center 1024) to float -1.0 to 1.0
        return (val - 1024.0) / 1024.0

    def get_auto_mode(self):
        """Returns True if the Mode switch selects Autonomous, False for Manual."""
        # Typically Gear (Channel 4) or Aux1 (Channel 5) is mapped to Mode
        # Spektrum 3-position switch: Low (<700), Mid (700-1400), High (>1400)
        # We treat High (> 1500) as Autonomous Mode
        val = self.get_channel(4)
        return val > 1500


# Self-test block
if __name__ == "__main__":
    logging.info("Starting Spektrum Satellite Receiver Parser self-test...")
    parser = SpektrumRC(port="/dev/ttyAMA0") # Adjust port as needed for testing
    parser.daemon = True
    parser.start()
    
    try:
        while True:
            if parser.is_connected():
                print(f"RC Connected | Throttle: {parser.get_throttle():.2f} | Rudder: {parser.get_rudder():.2f} | Auto: {parser.get_auto_mode()}", end="\r")
            else:
                print("Waiting for RC Transmitter signal...", end="\r")
            time.sleep(0.1)
    except KeyboardInterrupt:
        parser.stop()
        print("\nTest terminated by user.")
