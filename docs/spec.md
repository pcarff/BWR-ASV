# Engineering Specification Document (ESD-01)
## Project Blue-Water Rover: Autonomous Surface Vehicle (ASV)

* **Origin**: Charleston Metro Hub (SC)
* **Destination**: Tampa Bay (FL)
* **Current Revision**: 1.0 (Initial Draft - Transcribed from PDF)

---

### 1. Overall Description
Project Blue-Water Rover is a long-range, solar-assisted Autonomous Surface Vehicle (ASV) engineered to navigate an unassisted ocean voyage from Charleston, SC, around the Florida Keys, to Tampa Bay, FL (approx. 650–700 nautical miles). The vehicle will utilize multi-hop LoRa data telemetry along the Atlantic coastline for remote management, while relying on localized edge compute for real-time navigation, situational awareness, and COLREGs (collision avoidance) compliance.

---

### 2. Technical Justification for the Architecture

#### 2.1 The Hybrid Software Isolation Strategy
Traditional remote-controlled vehicles stream high-frequency control signals (e.g., 50Hz joystick coordinates). This approach fails in long-range ocean deployments due to latency spikes and signal dropouts. 

By decoupling High-Level Mission Control from Low-Level Actuation, high-level mission states (e.g., updating target global waypoints or requesting status) are handled via a low-bandwidth, multi-hop mesh network. Low-level loops (e.g., motor throttle modulation, raw path corrections against waves) are computed entirely on the boat at the edge, eliminating round-trip latency over the air.

#### 2.2 Why MeshCore for Telemetry?
* **Scalability**: MeshCore features up to a 64-hop capability, allowing packets to skip across a network of low-cost, fixed onshore repeaters along the Intracoastal Waterway and coastline.
* **Low Power Consumption**: Unlike standard peer-to-peer protocols that force every node to act as an energy-draining repeating router, MeshCore allows the vehicle to compile as a Companion Node. The vessel sips power, listening only for its own target packets and broadcasting minimal outbound sensor strings.

---

### 3. Initial Bill of Materials (BOM)

| Category | Component Description |
| :--- | :--- |
| **Telemetry & Control Core** | LilyGO T-Deck (ESP32-S3, SX1262 LoRa module @ 915 MHz, built-in display/keyboard) |
| **Telemetry & Control Core** | Heltec V3 (ESP32-S3, SX1262 LoRa module @ 915 MHz, IP67 enclosure) |
| **Telemetry & Control Core** | Vessel Navigation Controller: Hardened STM32 or Raspberry Pi 5 edge compute module |
| **Electrical & Power** | Primary Battery Storage: 48V Lithium Iron Phosphate (LiFePO4) battery bank (115 Ah baseline) |
| **Electrical & Power** | Solar Energy Collection: Dual 200W marine-grade monocrystalline flexible solar panels (400W total array) |
| **Electrical & Power** | Charge Controller: MPPT Solar Charge Controller (48V output step-down configuration) |
| **Propulsion & Actuation** | Thrusters: Dual 48V brushless underwater thrusters configured for differential steering |

---

### 4. Command Library (Discrete Operational State Packets)

| Prefix Header | Arguments | Example Payload | System Behavior |
| :--- | :--- | :--- | :--- |
| `NAV:WP` | `[Index],[Lat],[Lon]` | `NAV:WP,04,27.76,-82.63` | Appends target GPS coordinates to the local autopilot stack. |
| `NAV:HOLD` | None | `NAV:HOLD` | Suspends active waypoint navigation; vehicle dynamically loiters in place. |
| `NAV:KILL` | None | `NAV:KILL` | Immediate emergency motor shutdown; overrides all edge scripts. |
| `TEL:REQ` | None | `TEL:REQ` | Explicit request forcing the boat to transmit its diagnostic payload. |

---

### 5. Preliminary Power Budget & Calculations

#### 5.1 System Power Consumption Load (Estimates)
We define the power load under continuous 24-hour operation on open water:
\[P_{total} = P_{compute} + P_{sensors} + P_{propulsion}\]

* **Edge Compute + Telemetry Node**: \(12\text{V} \times 1.5\text{A} = 18\text{W}\)
* **Sensors** (GPS, IMU, Marine Cameras): \(12\text{V} \times 1.0\text{A} = 12\text{W}\)
* **Propulsion** (Average cruising thrust over water): \(48\text{V} \times 1.25\text{A} = 60\text{W}\)

**Continuous Watt-Hour Load per day**:
\[(18\text{W} + 12\text{W} + 60\text{W}) \times 24\text{ hours} = 2,160\text{ Wh/day}\]

#### 5.2 Battery Capacity Sizing (LiFePO4)
To protect system health, we enforce a maximum Depth of Discharge (DoD) of 80% (\(DoD = 0.8\)) and size for 2 days of complete solar autonomy (e.g., traveling through extended storm fronts).

\[\text{Required Battery Capacity (Wh)} = \frac{\text{Daily Load} \times \text{Autonomy Days}}{\text{DoD}}\]
\[\text{Required Capacity} = \frac{2,160\text{ Wh/day} \times 2\text{ days}}{0.8} = 5,400\text{ Wh}\]

Converted to a standard 48V system metric:
\[\text{Amp-Hour Rating} = \frac{5,400\text{ Wh}}{48\text{V}} = 112.5\text{ Ah}\]
* **Vessel Specification Baseline**: Minimum 48V battery bank rated for **115 Ah**.

#### 5.3 Solar Array Sizing
The solar array must replenish a daily consumption of \(2,160\text{ Wh}\) within average daylight conditions. Assuming a conservative 5 Peak Sun Hours per day along the Southern US coastline, and an overall marine system efficiency factor of 75% due to panel angling and splash residue:

\[\text{Required Solar Power (Watts)} = \frac{\text{Daily Consumption (Wh)}}{\text{Peak Sun Hours} \times \text{Efficiency}}\]
\[\text{Required Solar Power} = \frac{2,160\text{ Wh}}{5\text{ hours} \times 0.75} = 576\text{ W}\]

* **Solar Specification Gap Note**: Our initial baseline 400W solar panel array leaves a deficit under continuous propulsion. To maintain net-positive power charging without relying on secondary fuel generators, the physical design must expand to a 600W solar array or the software profile must throttle propulsion down to lower duty cycles during low-light days.
