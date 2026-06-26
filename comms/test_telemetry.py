#!/usr/bin/env python3
"""
Blue-Water Rover: Telemetry Validation Tests with Reliability
Tests checksum validation, stream parsing, callback routing, and reliability safety nets.
"""

import sys
import os
import time

# Adjust path to import telemetry_handler
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from telemetry_handler import TelemetryHandler

# Test trackers
received_waypoints = []
hold_called = 0
kill_called = False
tel_req_called = False
heartbeat_lost_called = False

# Callback functions
def on_nav_wp(idx, lat, lon):
    global received_waypoints
    received_waypoints.append({"index": idx, "lat": float(lat), "lon": float(lon)})

def on_nav_hold():
    global hold_called
    hold_called += 1

def on_nav_kill():
    global kill_called
    kill_called = True

def on_tel_req():
    global tel_req_called
    tel_req_called = True

def on_heartbeat_lost():
    global heartbeat_lost_called
    heartbeat_lost_called = True

def test_telemetry_handler():
    global received_waypoints, hold_called, kill_called, tel_req_called, heartbeat_lost_called
    
    # 1. Initialize handler with test settings (short 0.5s deduplication window)
    handler = TelemetryHandler(max_buffer_size=100, dedup_window=0.5)
    
    # 2. Register callbacks
    handler.register_callback("NAV:WP", on_nav_wp)
    handler.register_callback("NAV:HOLD", on_nav_hold)
    handler.register_callback("NAV:KILL", on_nav_kill)
    handler.register_callback("TEL:REQ", on_tel_req)
    handler.register_heartbeat_lost_callback(on_heartbeat_lost)
    
    print("\n--- Test 1: Checksum Calculations ---")
    cs_hold = handler.calculate_checksum("NAV:HOLD")
    assert cs_hold == "6C", f"Checksum failed. Expected '6C', got '{cs_hold}'"
    print("✓ Checksum calculation matches reference spec: NAV:HOLD -> 6C")
    
    print("\n--- Test 2: Formatting Outgoing Packets ---")
    packet = handler.format_packet("TEL:ACK,NAV:WP,STATUS=ACCEPTED")
    expected_packet = "$TEL:ACK,NAV:WP,STATUS=ACCEPTED*62\n"
    assert packet == expected_packet, f"Formatting failed. Expected '{expected_packet}', got '{packet}'"
    print(f"✓ Formatted packet output matches: {packet.strip()}")
    
    print("\n--- Test 3: Processing Valid Command Frames ---")
    received_waypoints = []
    valid_wp_packet = "$NAV:WP,04,27.7600,-82.6300*6A\n"
    handler.process_data(valid_wp_packet)
    assert len(received_waypoints) == 1, "Failed to capture waypoint callback."
    assert received_waypoints[0]["index"] == "04", "Incorrect waypoint index."
    assert received_waypoints[0]["lat"] == 27.7600, "Incorrect latitude."
    assert received_waypoints[0]["lon"] == -82.6300, "Incorrect longitude."
    print("✓ Valid waypoint packet processed and routed correctly.")
    
    print("\n--- Test 4: Rejecting Corrupted Checksums ---")
    hold_called = 0
    corrupted_packet = "$NAV:HOLD*FF\n"
    handler.process_data(corrupted_packet)
    assert hold_called == 0, "Corrupted packet triggered callback! Failure."
    print("✓ Corrupted packet successfully rejected by checksum validation.")
    
    print("\n--- Test 5: Stream Fragmentation & Accumulation ---")
    kill_called = False
    handler.process_data("$NAV:")
    handler.process_data("KI")
    handler.process_data("LL*61")
    assert not kill_called, "Incomplete packet prematurely triggered callback."
    handler.process_data("\n")
    assert kill_called, "Complete packet failed to trigger after concatenation."
    print("✓ Parser successfully reconstructed fragmented stream bytes.")

    print("\n--- Test 6: Buffer Overflow Protection ---")
    handler._buffer = "A" * 90
    # Feeding 15 characters to cross the max_buffer_size of 100
    handler.process_data("B" * 15)
    assert handler._buffer == "", "Buffer was not cleared on overflow."
    print("✓ Buffer overflow triggered and safely truncated runaway buffer.")

    print("\n--- Test 7: Multi-Hop Duplicate Command Suppression ---")
    hold_called = 0
    # First valid command
    handler.process_data("$NAV:HOLD*6C\n")
    assert hold_called == 1, "First command failed to trigger."
    # Immediate duplicate payload (simulated mesh echo)
    handler.process_data("$NAV:HOLD*6C\n")
    assert hold_called == 1, "Duplicate command bypassed echo suppression!"
    print("✓ Mesh echo duplicate packet suppressed successfully.")
    
    # Wait for deduplication window (0.5s) to expire, check if allowed again
    print("Waiting 0.6s to check duplicate cache expiration...")
    time.sleep(0.6)
    handler.process_data("$NAV:HOLD*6C\n")
    assert hold_called == 2, "Command blocked after deduplication window expired."
    print("✓ Command accepted again after deduplication window elapsed.")

    print("\n--- Test 8: Telemetry Link Heartbeat Watchdog ---")
    heartbeat_lost_called = False
    # Manually backdate the last rx time to simulate inactivity
    handler.last_rx_time = time.time() - 10.0
    # Run check with a 5.0 second timeout
    handler.check_link_status(timeout_seconds=5.0)
    assert heartbeat_lost_called, "Heartbeat watchdog did not trigger callback on timeout."
    print("✓ Connection watchdog detected link timeout and executed safety callback.")

    print("\n-------------------------------------------")
    print("🎉 ALL TELEMETRY & RELIABILITY TESTS PASSED! 🎉")
    print("-------------------------------------------\n")

if __name__ == "__main__":
    test_telemetry_handler()
