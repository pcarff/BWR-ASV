# Blue-Water Rover: Telemetry & Communications Protocol (BWR-TCP-01)
**Version:** 1.1  
**Author:** Systems Engineering  
**Primary Hardware:** Raspberry Pi Zero W v1.1 (Autopilot) & Heltec V3 (Meshcore LoRa Node)

---

## 1. Physical & Data Link Layer

The communication between the Raspberry Pi Zero W (Autopilot) and the Heltec V3 (Meshcore Modem) is established using standard asynchronous serial (UART).

### 1.1 Serial Parameters
*   **Baud Rate:** `115200` bps
*   **Data Bits:** `8`
*   **Parity:** `None`
*   **Stop Bits:** `1`
*   **Flow Control:** `None`

### 1.2 Physical Connection Options

```
Method A: USB OTG Interface (Recommended)
+------------------------+                          +-----------------------+
|  Raspberry Pi Zero W   |                          |   Heltec V3 (LoRa)    |
|  [USB Data Port]       |=======[USB-C Cable]======|  [USB-C Port]         |
+------------------------+                          +-----------------------+
(Note: Recognized by Linux OS as /dev/ttyUSB0 or /dev/ttyACM0. Native 5V-to-3.3V conversion)

Method B: GPIO Pin Header Interface (Space-Saving)
+------------------------+                          +-----------------------+
|  Raspberry Pi Zero W   |                          |   Heltec V3 (LoRa)    |
|  Pin 8 (GPIO 14 - TX)  |---------[Direct]-------->|  Pin RX               |
|  Pin 10 (GPIO 15 - RX) |<--------[Direct]---------|  Pin TX               |
|  Pin 6 (GND)           |---------[Direct]---------|  Pin GND              |
+------------------------+                          +-----------------------+
(Note: Natively compatible 3.3V logic levels. Requires disabling Bluetooth in Pi config to map /dev/ttyAMA0)
```

---

## 2. Frame Structure & Integrity

To protect the autopilot against bit-flips caused by electromagnetic interference (EMI) from the dual thrusters and the solar charge controllers, every message must reside inside an integrity frame containing a **one-byte XOR checksum**.

### 2.1 Frame Format
\texttt{\$[Payload]*[2-Character Hex Checksum]\textbackslash n}

*   `$` (0x24) : Start of Frame delimiter.
*   `*` (0x2A) : Checksum separator.
*   `[Checksum]` : The XOR sum of all characters between `$` and `*` (exclusive), formatted as a 2-character uppercase hexadecimal value.
*   `\n` (0x0A) : End of Frame newline character.

### 2.2 Checksum Algorithm (Python Implementation)
```python
def calculate_checksum(payload: str) -> str:
    xor_sum = 0
    for char in payload:
        xor_sum ^= ord(char)
    return f"{xor_sum:02X}"
```
*Example:* For payload `"NAV:HOLD"`, the XOR sum of `'N'`, `'A'`, `'V'`, `':'`, `'H'`, `'O'`, `'L'`, `'D'` is `108` (decimal) or `6C` (hexadecimal).  
**Final Frame:** `"$NAV:HOLD*6C\n"`

---

## 3. Command Dictionary

### 3.1 Uplink (Commands from Ground Station to Autopilot)

These commands are sent over the Meshcore encrypted channel, output by the Heltec V3 serial, and executed by the Pi Zero W.

#### `$NAV:WP,[Index],[Lat],[Lon]*[CS]\n`
*   **Description:** Appends a target global coordinate to the autopilot's navigation queue.
*   **Arguments:**
    *   `[Index]` : Two-digit padded integer representing the sequence ID (e.g., `01` to `99`).
    *   `[Lat]` : Float representing latitude in decimal degrees (range: `-90.0000` to `90.0000`).
    *   `[Lon]` : Float representing longitude in decimal degrees (range: `-180.0000` to `180.0000`).
*   **Example:** `$NAV:WP,04,27.7600,-82.6300*6A\n`

#### `$NAV:HOLD*[CS]\n`
*   **Description:** Instantly suspends waypoint navigation. The autopilot commands the dual thrusters to dynamically loiter/hold the current GPS coordinates.
*   **Example:** `$NAV:HOLD*6C\n`

#### `$NAV:KILL*[CS]\n`
*   **Description:** Emergency physical override. Immediately cuts throttle (neutral PWM) on both electronic speed controllers, halts all navigation threads, and puts the autopilot script into a safe shutdown state.
*   **Example:** `$NAV:KILL*61\n`

#### `$TEL:REQ*[CS]\n`
*   **Description:** Forces an immediate telemetry diagnostics broadcast.
*   **Example:** `$TEL:REQ*21\n`

---

### 3.2 Downlink (Telemetry and Acknowledgments from Autopilot to Ground Station)

These frames are sent by the Pi Zero W over serial to the Heltec V3, which broadcasts them over LoRa.

#### Command Acknowledgment (`$TEL:ACK,...`)
Confirms receipt, parsing, and execution status of an uplink command.
*   **Syntax:** `$TEL:ACK,[UPLINK_CMD],[PARAM_STATION_FEEDBACK]*[CS]\n`
*   **Examples:**
    *   `$TEL:ACK,NAV:WP,INDEX=04,STATUS=ACCEPTED*29\n`
    *   `$TEL:ACK,NAV:HOLD,STATUS=LOITERING*22\n`
    *   `$TEL:ACK,NAV:KILL,EMERGENCY_SHUTDOWN=ACTIVE*60\n`

#### Telemetry Diagnostic Broadcast (`$TEL:DIAG,...`)
Sent automatically every 5 minutes, or upon a system state change, or in response to a `$TEL:REQ` command.
*   **Syntax:**  
    `$TEL:DIAG,BAT=[BatPercent]%,SOL=[SolarPower]W,PROP=[PropPower]W,LAT=[Lat],LON=[Lon],SPEED=[Knots]KT,STATE=[Status],THROTTLE=[ThrotState],WP_Q=[QueueLen]*[CS]\n`
*   **Field Definitions:**
    *   `BAT` : Battery state of charge (percentage, e.g. `85.2%`).
    *   `SOL` : Current solar harvest in Watts (e.g. `180.4W`).
    *   `PROP` : Real-time propulsion power consumption in Watts (e.g. `60.0W`).
    *   `LAT` / `LON` : Autopilot's current GPS location in decimal degrees.
    *   `SPEED` : Speed over ground (SOG) in Knots.
    *   `STATE` : Operational state (`CRUISING`, `LOITERING`, `SHUTDOWN`).
    *   `THROTTLE` : Propulsion override state (`ACTIVE`, `OFF`).
    *   `WP_Q` : Count of remaining waypoints in the queue (e.g. `4`).
*   **Example Packet:**  
    `$TEL:DIAG,BAT=85.2%,SOL=180.4W,PROP=60.0W,LAT=27.7610,LON=-82.6321,SPEED=5.0KT,STATE=CRUISING,THROTTLE=ACTIVE,WP_Q=4*5B\n`

---

## 4. Meshcore Private Channel Encryption Configuration

To prevent unauthorized entities from sending telemetry overrides, communication is restricted to an isolated, encrypted channel using an AES-256 symmetric Pre-Shared Key (PSK).

### 4.1 Key Generation
Generate a secure, high-entropy 256-bit key on a command terminal using OpenSSL:
```bash
openssl rand -base64 32
# Save the printed string (e.g., "dGhpcyBpcyBhIHNlY3VyZSBjaGFubmVsIGtleWJsYWg=")
```

### 4.2 Configuration Script
Connect the Heltec V3 via USB to your development environment and execute the following configuration steps using `meshcore-cli`:

```bash
# 1. Define the dedicated channel name
meshcore-cli set channel.name "BWR_NAV"

# 2. Configure the shared symmetric encryption key
meshcore-cli set channel.key "dGhpcyBpcyBhIHNlY3VyZSBjaGFubmVsIGtleWJsYWg="

# 3. Disable public/anonymous network eavesdropping on this channel
meshcore-cli set channel.public false

# 4. Set the device operating role to Companion Node 
# (This stops the node from routing third-party transit messages, saving battery power)
meshcore-cli set node.role COMPANION

# 5. Write configuration changes to non-volatile flash memory
meshcore-cli save
```

---

## 5. Communications Reliability & Safety Specification

To guarantee survival during long voyages with high EMI and potential packet collisions, three software failsafes are implemented in the telemetry parser.

### 5.1 Serial Buffer Memory Safety (Anti-Overflow)
*   **Trigger:** If the serial connection is corrupted or loses a line-termination character (`\n`), characters will pile up.
*   **Action:** The buffer is strictly bounded to **1024 characters**. If the incoming data pushes the buffer past this limit, the parser raises a critical log alert and purges the buffer contents to prevent RAM runaway.

### 5.2 Telemetry Link Watchdog (Connection Heartbeat)
*   **Trigger:** If the LoRa transceiver fails, runs out of power, or enters a dead zone, the Autopilot must detect the link failure.
*   **Action:**
    *   On receipt of any valid checksummed packet, the Autopilot resets its connection timestamp.
    *   The link status is checked periodically. If no valid frame is received within a **60-second window**, a link timeout event triggers a fallback safety routine.
    *   *Autopilot Safety Response:* Disables active path guidance and forces the vessel into dynamic loiter mode (`NAV:HOLD`) until communication is restored.

### 5.3 Multi-Hop Echo Suppression (Deduplication)
*   **Trigger:** In mesh networks, repeaters relay packages multiple times, causing a receiver to read the same packet multiple times.
*   **Action:**
    *   The parser maintains a sliding cache of recently processed packet payloads.
    *   If a packet with an identical payload is received within a **15-second duplicate suppression window**, it is discarded immediately without executing its callbacks.
