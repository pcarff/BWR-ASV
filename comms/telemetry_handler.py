#!/usr/bin/env python3
"""
Blue-Water Rover: Telemetry Serial Protocol Handler
Handles XOR-checksummed ASCII packet framing over UART with reliability upgrades.
"""

import logging
import time

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("TelemetryHandler")

class TelemetryHandler:
    def __init__(self, serial_conn=None, max_buffer_size=1024, dedup_window=15.0):
        self.serial = serial_conn
        self._buffer = ""
        self._callbacks = {}
        self.max_buffer_size = max_buffer_size
        self.dedup_window = dedup_window
        self.last_rx_time = time.time()
        self._heartbeat_lost_callback = None
        self._received_packets = {}  # maps payload -> receive_timestamp

    def register_callback(self, command_prefix: str, callback_func):
        """
        Registers a callback function for a specific command prefix (e.g., 'NAV:WP').
        The callback function should accept (*args) parsed from the comma-separated arguments.
        """
        prefix = command_prefix.strip().upper()
        self._callbacks[prefix] = callback_func
        logger.info(f"Registered handler for command: {prefix}")

    def register_heartbeat_lost_callback(self, callback_func):
        """
        Registers a callback function triggered when the telemetry watchdog timer expires.
        """
        self._heartbeat_lost_callback = callback_func
        logger.info("Registered heartbeat lost safety callback")

    @staticmethod
    def calculate_checksum(payload: str) -> str:
        """
        Calculates the 1-byte XOR checksum of the string and returns it as a 2-char hex.
        """
        xor_sum = 0
        for char in payload:
            xor_sum ^= ord(char)
        return f"{xor_sum:02X}"

    def format_packet(self, payload: str) -> str:
        """
        Wraps a raw payload into an integrity packet frame: $[payload]*[checksum]\n
        """
        checksum = self.calculate_checksum(payload)
        return f"${payload}*{checksum}\n"

    def send_packet(self, payload: str) -> bool:
        """
        Formats and transmits a packet over the registered serial interface.
        """
        packet = self.format_packet(payload)
        if self.serial and self.serial.is_open:
            try:
                self.serial.write(packet.encode("ascii"))
                logger.debug(f"Transmitted packet: {packet.strip()}")
                return True
            except Exception as e:
                logger.error(f"Failed to write to serial: {e}")
                return False
        else:
            logger.warning(f"Serial port not open. Mock transmit: {packet.strip()}")
            return False

    def process_data(self, data: str):
        """
        Feeds incoming serial data (characters or strings) into the parsing buffer.
        Processes completed frames immediately. Enforces max buffer limits.
        """
        if len(self._buffer) + len(data) > self.max_buffer_size:
            logger.critical("Serial buffer overflow protection triggered! Pruning buffer.")
            combined = self._buffer + data
            dollar_idx = combined.rfind("$")
            if dollar_idx != -1 and len(combined) - dollar_idx <= self.max_buffer_size:
                self._buffer = combined[dollar_idx:]
            else:
                self._buffer = ""
            return

        self._buffer += data
        
        while "\n" in self._buffer:
            line_end_idx = self._buffer.index("\n")
            line = self._buffer[:line_end_idx].strip()
            self._buffer = self._buffer[line_end_idx + 1:]
            
            if not line:
                continue

            self._parse_line(line)

    def check_link_status(self, timeout_seconds=60) -> bool:
        """
        Checks if the telemetry link is active. If the timeout has expired and
        a heartbeat lost callback is registered, triggers the callback.
        Returns True if link is active, False if expired.
        """
        current_time = time.time()
        elapsed = current_time - self.last_rx_time
        if elapsed > timeout_seconds:
            logger.error(f"Telemetry link timeout! No packets received for {elapsed:.1f}s")
            if self._heartbeat_lost_callback:
                try:
                    logger.warning("Executing heartbeat lost safety routine...")
                    self._heartbeat_lost_callback()
                except Exception as e:
                    logger.error(f"Error in heartbeat lost callback: {e}")
            return False
        return True

    def _prune_dedup_cache(self, current_time: float):
        """
        Removes expired packet hashes from the deduplication memory.
        """
        expired = [
            payload for payload, timestamp in self._received_packets.items()
            if current_time - timestamp > self.dedup_window
        ]
        for payload in expired:
            del self._received_packets[payload]

    def _parse_line(self, line: str):
        """
        Parses a single newline-terminated line, validates the checksum,
        suppresses mesh echoes, and routes the command payload.
        """
        logger.debug(f"Raw line received: {line}")

        if not line.startswith("$"):
            logger.warning(f"Discarding malformed line (missing start delimiter '$'): {line}")
            return

        if "*" not in line:
            logger.warning(f"Discarding malformed line (missing checksum separator '*'): {line}")
            return

        try:
            # Extract components: $Payload*CS
            payload = line[1:line.rindex("*")]
            rx_checksum = line[line.rindex("*") + 1 :].upper()
        except ValueError:
            logger.error(f"Malformed framing indices in line: {line}")
            return

        # Calculate expected checksum
        expected_checksum = self.calculate_checksum(payload)
        if rx_checksum != expected_checksum:
            logger.warning(
                f"Checksum mismatch! Received payload '{payload}' with CS '{rx_checksum}', expected '{expected_checksum}'"
            )
            return

        # Update link watchdog heartbeat (receiving a valid frame confirms connectivity)
        current_time = time.time()
        self.last_rx_time = current_time

        # Check for duplicates (mesh echo suppression)
        self._prune_dedup_cache(current_time)
        if payload in self._received_packets:
            last_rx = self._received_packets[payload]
            if current_time - last_rx < self.dedup_window:
                logger.info(f"Suppressed duplicate mesh echo payload: {payload}")
                return

        self._received_packets[payload] = current_time

        # Route verified payload
        self._route_command(payload)

    def _route_command(self, payload: str):
        """
        Splits the CSV payload, extracts the prefix, and routes it to callbacks.
        """
        tokens = payload.split(",")
        if not tokens:
            return

        prefix = tokens[0].strip().upper()
        args = [t.strip() for t in tokens[1:]]

        if prefix in self._callbacks:
            try:
                logger.info(f"Routing command '{prefix}' with args: {args}")
                self._callbacks[prefix](*args)
            except TypeError as te:
                logger.error(f"Callback argument mismatch for '{prefix}': {te}")
            except Exception as e:
                logger.error(f"Unhandled error in callback for '{prefix}': {e}")
        else:
            logger.warning(f"No callback registered for command prefix: {prefix}")
            self.send_packet(f"TEL:ERR,UNSUPPORTED_CMD={prefix}")
