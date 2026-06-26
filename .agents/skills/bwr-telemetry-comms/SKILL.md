---
name: bwr-telemetry-comms
description: >-
  Guides the agent in maintaining, extending, and validating the Blue-Water Rover (BWR) serial telemetry protocol and reliability modules.
---

# BWR Telemetry & Communications Guide

## Overview
This skill provides instructions and references for managing the serial communications link between the **Raspberry Pi Zero W v1.1** (Autopilot) and the **Heltec V3** (LoRa Meshcore Node) on the Blue-Water Rover (BWR) Autonomous Surface Vehicle. It ensures code correctness, protocol documentation alignment, and the maintenance of critical safety features (buffer limits, watchdog timeouts, and mesh echo suppression).

## Dependencies
*   **Protocol Spec:** [docs/comms_protocol.md](file:///workspaces/BWR_ASV/docs/comms_protocol.md) (ASCII framing, command details, and Meshcore channel setup)
*   **Serial Parser:** [comms/telemetry_handler.py](file:///workspaces/BWR_ASV/comms/telemetry_handler.py) (Core processing logic)
*   **Test Suite:** [comms/test_telemetry.py](file:///workspaces/BWR_ASV/comms/test_telemetry.py) (Parser and reliability validation script)

## Quick Start

To instantiate the telemetry handler and register a custom command callback:

```python
from comms.telemetry_handler import TelemetryHandler

# 1. Define command callback
def handle_wpt_addition(index, lat, lon):
    print(f"Waypoint {index} parsed: ({lat}, {lon})")

# 2. Initialize handler
handler = TelemetryHandler()
handler.register_callback("NAV:WP", handle_wpt_addition)

# 3. Simulate incoming serial bytes
handler.process_data("$NAV:WP,04,27.7600,-82.6300*6A\n")
```

---

## Workflow (Instruction-Only)

When the user asks to add a new command, modify telemetry formats, or adjust safety behaviors, execute the following steps:

### 1. Update the Protocol Documentation
Edit [docs/comms_protocol.md](file:///workspaces/BWR_ASV/docs/comms_protocol.md) to define:
*   The exact frame format and ASCII syntax.
*   The parameters, argument types, and expected ranges.
*   A calculated XOR checksum example. (You can calculate checksums programmatically using `TelemetryHandler.calculate_checksum()`).

### 2. Implement the Callback Logic
Open [comms/telemetry_handler.py](file:///workspaces/BWR_ASV/comms/telemetry_handler.py):
*   For new incoming command types (uplinks), register the corresponding prefix handler in the main autopilot loop using `handler.register_callback()`.
*   For new diagnostic outputs (downlinks), implement formatting helpers using `handler.format_packet()` and transmit via `handler.send_packet()`.

### 3. Maintain Safety Guidelines
Ensure changes do not break or bypass these three reliability layers:
*   **Buffer Limit:** The parser must discard data and prune on buffers exceeding `max_buffer_size = 1024` to protect Pi memory.
*   **Link Watchdog:** If no packets are received within `timeout_seconds = 60`, the link status check must fail and trigger the safety loiter handler.
*   **Deduplication:** Repeated LoRa packets seen within a `dedup_window = 15.0` seconds must be suppressed to avoid mesh echoes.

### 4. Update the Test Suite
Edit [comms/test_telemetry.py](file:///workspaces/BWR_ASV/comms/test_telemetry.py) to:
*   Add a test case executing the new callback structure.
*   Assert that arguments parse into correct data types (float, int, etc.).
*   Verify that corrupted checksum variants of the new command are rejected.

### 5. Run Validation Tests
Run the unit test suite in the terminal to verify the changes:
```bash
python3 comms/test_telemetry.py
```
*Note: Do not commit changes unless the test runner outputs: `🎉 ALL TELEMETRY & RELIABILITY TESTS PASSED! 🎉`*

---

## Common Mistakes
*   **Incorrect Manual Checksums:** Guessing XOR checksums in documentation or tests. Always run `TelemetryHandler.calculate_checksum()` to compute the exact hex value.
*   **Failing to Disregard Duplicates:** Executing immediate consecutive commands of the same checksummed payload within the 15-second suppression window (often caused by LoRa mesh packet echoing).
*   **UART Software Emulation:** Using software serial emulation on low-spec MCUs (like Arduino Uno). Always enforce hardware serial UART channels when interfacing with the telemetry module.
