# Systems Engineering & Vessel Design Document
## Project Blue-Water Rover: Long-Range Solar ASV (ESD-01)

This document details the physical, electrical, and computational design of the Blue-Water Rover Autonomous Surface Vehicle (ASV) optimized for an unassisted 650–700 nautical mile voyage from Charleston, SC, to Tampa Bay, FL.

![Vessel Design Blueprint Schematic](./asv_blueprint_schematic.png)

---

## 1. Hull Selection & Hydrodynamics

Selecting the optimal hull shape represents the fundamental trade-off in solar-electric vessel design. We evaluate three configurations:

| Metric | Monohull (Deep-V) | Catamaran (Dual-Pontoon) | Trimaran (Stabilized Outriggers) |
| :--- | :--- | :--- | :--- |
| **Drag Coefficient (\(C_d\))** | 1.20 (Base) | 0.85 (Low) | 0.75 (Very Low) |
| **Solar Deck Area** | Max 400W | Max 600W | Max 800W |
| **Hull Weight** | 45 kg | 60 kg | 75 kg |
| **Transverse Stability** | Low (Heels in wind/waves) | High (Resists heeling) | Very High (Highly stable) |
| **Wave Roll Sensitivity** | High (Wave action shades panels) | Low (Maintains flat deck) | Minimal (Near-constant solar angle) |

```mermaid
graph TD
    A[Vessel Design Selection] --> B[Monohull]
    A --> C[Catamaran]
    A --> D[Trimaran]
    B --> E[400W Solar Limit / High Drag / High Wave Loss]
    C --> F[600W Solar Limit / Low Drag / Low Wave Loss]
    D --> G[800W Solar Limit / Very Low Drag / Zero Wave Loss]
```

### Recommendation
> [!IMPORTANT]
> The **Catamaran** is selected as the optimal baseline design. It provides a wide, flat deck area to accommodate up to **600W** of flexible solar panels, achieves a **15% reduction in drag** compared to a monohull, and minimizes transverse roll which directly prevents solar panel shading in open water.

---

## 2. Power Architecture & Sizing

The ASV operates on a closed-loop energy cycle. The power balance equation is defined as:
\[P_{net} = P_{solar} \cdot \eta_{mppt} - (P_{propulsion} + P_{edge} + P_{sensors})\]

### 2.1 Daily Energy Consumption
The continuous power draw for the subsystems is calculated as follows:
* **Edge Compute + Avionics**: \(12\text{V} \times 1.8\text{A} = 21.6\text{W}\) (Pi 5 baseline)
* **Sub-Avionics & Sensors**: \(12\text{V} \times 0.7\text{A} = 8.4\text{W}\) (RTK-GPS, IMU, LoRa transceiver)
* **Propulsion (Cruising Speed)**: \(48\text{V} \times 1.25\text{A} = 60\text{W}\)

\[P_{loads} = 21.6\text{W} + 8.4\text{W} + 60\text{W} = 90\text{W}\]
\[\text{Daily Consumption} = 90\text{W} \times 24\text{ hours} = 2,160\text{ Wh/day}\]

### 2.2 Battery Bank Sizing (LiFePO4)
To ensure system survival during stormy conditions, we design for **2 days of complete autonomy** at a maximum **80% Depth of Discharge (DoD)**:

\[\text{Required Battery Capacity} = \frac{2,160\text{ Wh/day} \times 2\text{ days}}{0.8} = 5,400\text{ Wh}\]

Standardized to our 48V system:
\[\text{Battery Capacity (Ah)} = \frac{5,400\text{ Wh}}{48\text{V}} = 112.5\text{ Ah}\]
* **Selected Battery**: **48V 115Ah LiFePO4 bank** (5,520 Wh capacity).

### 2.3 Solar Array Sizing & Solar Deficit
Assuming a conservative **5 Peak Sun Hours** per day along the Florida coast, and a **75% efficiency coefficient** (due to panel pitch, splash residue, and temperature losses):

\[\text{Required Solar Power} = \frac{2,160\text{ Wh}}{5\text{ hours} \times 0.75} = 576\text{ W}\]

> [!WARNING]
> **The 400W Sizing Gap**: The initial 400W solar panel configuration can generate at most \(400\text{W} \times 5 \times 0.75 = 1,500\text{ Wh/day}\), leaving a daily deficit of **660 Wh**.
> To resolve this without manual refueling:
> 1. Expand the solar deck area to a **600W array** (requires Catamaran/Trimaran hull).
> 2. Implement **Software Propulsion Throttling** to automatically reduce motor power during low-light/overcast days.

---

## 3. Propulsion & Differential Actuation

The vessel utilizes **dual 48V brushless underwater thrusters** mounted in a differential steering configuration. This eliminates the mechanical failure points of a traditional rudder servo.

```
       [Left Thruster]  =======\
                                \=======> Forward Thrust & Differential Steering
       [Right Thruster] =======/
```

* **Differential Heading Formula**:
  The rate of rotation \(\omega\) is proportional to the difference in thrust between the left and right thrusters:
  \[\omega \propto (T_{right} - T_{left}) \cdot L_{beam}\]
  Where \(L_{beam}\) is the vessel's beam width.
* **Propulsion Speed Power Curve**:
  \[V_{boat} = V_{max} \cdot \sqrt{\frac{P_{thrust}}{P_{max}}}\]
  A cruise throttle of 60W drives the boat at approximately 5.0 knots.

---

## 4. Edge Avionics & Navigation Stack

The software stack utilizes a hybrid isolation architecture to guarantee system stability:

```
+-------------------------------------------------------------+
|               HIGH-LEVEL MISSION CONTROL (Edge SBC)         |
|   Sensors: RTK-GPS, IMU, Optical Cameras, Radar             |
|   Tasks: COLREGs Avoidance, Path Finding, Telemetry Uplink  |
+-------------------------------------------------------------+
                              | (SPI/UART isolated link)
                              v
+-------------------------------------------------------------+
|              LOW-LEVEL ACTUATOR CORE (STM32 MCU)            |
|   Tasks: Motor throttle PWM, Loiter PID, Keepalive Watchdog |
+-------------------------------------------------------------+
```

### 4.1 Collision Avoidance (COLREGs Compliance)
Using the Edge Compute board, the vessel processes sensory data to avoid coastal marine hazards:
1. **STM32 Only**: Static waypoint follower. No avoidance.
2. **Raspberry Pi 5 / Jetson Orin Nano**: Active vector steering. If an obstacle is detected within 15 NM, the high-level navigator computes an avoidance offset:
   \[\theta_{avoid} = \theta_{target} + \frac{K_{avoid}}{d_{obstacle}} \cdot \text{sign}(\phi)\]
   Where \(d_{obstacle}\) is the distance, and \(\phi\) is the angle to the obstacle center relative to the course.

---

## 5. Telemetry & Communications Mesh

The telemetry system utilizes a low-power **MeshCore LoRa transceiver** operating on the 915 MHz band, configured as a low-power **Companion Node**.

* **Backbone repeater hop network**: 15 onshore mesh repeaters skip telemetry packets from the boat back to the Charleston metro hub command station.
* **Link Budget**:
  - Max direct range: 45 nautical miles over flat ocean water.
  - Frequency: 915 MHz Spread Spectrum (LoRa).
  - Sleep Cycle: The Companion Node wakes up every 10 seconds to check for incoming discrete command packets (`NAV:WP`, `NAV:HOLD`, `NAV:KILL`) and broadcasts a telemetry payload (`TEL:DIAG`) only upon change in ship state or every 5 minutes.

---

## 6. Vessel Construction Plans

This section serves as the fabrication blueprint and assembly manual for constructing the optimized catamaran ASV.

### 6.1 Mechanical Frame & Hull Integration
1. **Pontoon Preparation**: Select dual rotomolded UV-resistant high-density polyethylene (HDPE) pontoons (length: 2.2m, beam diameter: 0.25m). Mold integrated threaded brass inserts on the upper deck of each pontoon to serve as crossbeam anchor points.
2. **Crossbeam Assembly**: Cut four lengths of 40mm x 40mm T-slot anodized aluminum structural extrusions (80/20 profile). Bolt these crossbeams transversely across the pontoons using M8 marine-grade 316 stainless steel bolts with nylon-insert lock nuts.
3. **Bridge Deck Installation**: Secure a 3.5mm thick carbon-fiber composite sheet across the middle three crossbeams. Apply marine silicone sealant (e.g., 3M Marine Adhesive Sealant 4000UV) along the extrusion channels before fastening to eliminate vibration and squeaking.
4. **Extrusion-to-PVC Mounting Brackets**: For PVC pipe hull options (Options A, B, and C), utilize the 3D-printable parametric mounting brackets designed in [pvc_extrusion_bracket.scad](file:///workspaces/BWR_ASV/pvc_extrusion_bracket.scad). These brackets provide a circular cradle for the PVC pipe, routing slots for metal band hose clamps, and a recessed top slot for bolting down the 2020 aluminum extrusion frame.
   - **Rubber Friction Pad**: Wrap a 1.5mm thick neoprene or EPDM rubber strip around the PVC hull at each bracket junction. The bracket's cradle radius includes a parametric clearance (`rubber_thickness = 1.5`) to accommodate this pad. This creates a high-friction, non-slip fit, dampens wave vibration, and prevents the brackets and metal clamps from scratching or slicing the PVC hulls.
   - **Hose Clamp Tensioning**: The stainless steel metal bands are threaded through the integrated wrap-around tunnel channels inside the bracket bodies, wrapped over the rubber strip, and tightened via worm-gear tension screws. Clamping force is distributed evenly around the hulls, pulling the cradle tight against the top surface and locking the bracket from sliding or rotating without drilling into the watertight pontoon chambers.


### 6.2 Watertight Power Vault (Central Box)
1. **Box Selection**: Utilize an IP67-rated polycarbonate enclosure (minimum size: 400mm x 300mm x 180mm).
2. **Pressure Equalization**: Install a waterproof gore-tex ventilation plug (e.g., Amphenol Vent Gland) to equalize air pressure during temperature changes without allowing humidity or sea water ingress.
3. **Internal Component Layout**:
   - Secure the 48V 115Ah LiFePO4 battery bank to the floor of the box using heavy-duty hook-and-loop straps anchored to epoxy-reinforced eyelets.
   - Mount the MPPT solar charge controller to an internal aluminum cooling plate that contacts the bottom of the enclosure to conduct heat outward into the wet hull deck.
   - Place a marine-grade MRBF (Marine Rated Battery Fuse) block directly on the battery positive terminal (fuse rated for 1.25x max expected system surge current).
4. **Waterproof Pass-Throughs**: Drill holes for all cables (solar input, motor output, system power out) and install PG-9 and PG-13 nickel-plated brass cable glands with rubber compression gaskets.

### 6.3 Propulsion Steering Mounts
1. **Clamp Machining**: Machined custom brackets from 15mm thick marine grade acetal (Delrin) or 3D-printed PETG (solid infill, 8 perimeter walls).
2. **Thruster Rigging**: Mount the brushless thrusters into the brackets and secure them to the stern aluminum crossbeam, spaced exactly 0.9m apart to maximize the differential steering torque vector.
3. **Conduit Guide**: Encase the thruster power lines in flexible split-loom UV-resistant nylon conduit. Clip the conduit along the pontoon decks to prevent contact with coastal seagrass or marine debris.

### 6.4 Electronics Avionics Housing
1. **RF Isolation & Compartments**: Place the Raspberry Pi 5/Jetson Orin Nano and STM32 MCU inside a separate IP67 electronics enclosure, physically separated from the high-voltage battery vault to mitigate RF noise.
2. **Dampening Mounts**: Mount the electronics board using rubber vibration isolation standoffs (M3 bobbin mounts) to insulate the sensitive inertial measurement unit (IMU) and computer processor from high-frequency hull vibration caused by wave impacts.

### 6.5 Mast Assembly & Sensor Rigs
1. **Mast Structure**: Construct a 1.2m vertical mast using a 25mm diameter lightweight carbon-fiber tube. Insert the mast base into a reinforced aluminum deck socket bolted directly to the forward deck crossbeam.
2. **Head Rigging**: Mount the RTK-GPS receiver antenna, the 915 MHz LoRa whip antenna, and optical camera housing to the top mast bracket. Run the shielded signal cables down the interior of the hollow carbon fiber mast tube, emerging through a waterproof cable entry gland at the base.
3. **Grounding & Shielding**: Ground all cable shields and the aluminum frame to a common negative bus bar connected to a sacrificial zinc anode mounted below the water line on the transom to prevent galvanic corrosion.

---

## 7. 800W Sizing Options & Construction Plans

To upgrade the vessel to a larger **800W solar array** under budget constraints and in a minimal construction space, we present two design configurations. Both leverage off-the-shelf hardware, modular assembly, and require no advanced fabrication facilities.

### 7.1 Option A: Proportional 2.53m Scale Catamaran

This design scales the baseline catamaran up by 15% to increase deck area while maintaining identical hydrodynamics.

![Option A: 2.53m Catamaran Blueprint](./asv_option_a_blueprint.png)

#### Technical Specifications & Sizing
* **Pontoon Hulls**: Dual 8-inch (200mm) SDR-35 PVC pipes (recommended for weight savings; see the [Hull 3D Printing & Weight Evaluation](file:///home/pcarff/.gemini/antigravity-ide/brain/c5a15662-1010-4b0d-a70a-d77a53272316/pontoon_3d_print_evaluation.md)), 2.53m length, sealed with domed end-caps.
* **Beam Width**: 1.6m (total overall width).
* **Frame**: 2020 (20mm x 20mm) T-slot anodized aluminum extrusions.
* **Solar Deck**: $4.1\text{ m}^2$ rectangular flat deck made of 4mm Coroplast, supporting eight 100W flexible solar panels (4s2p wiring).
* **Waterproofing**: Dual snap-lock heavy-duty dry boxes with compression glands for cable pass-throughs.
* **3D Assembly Model**: A parametric 3D CAD model is available at [asv_option_a_model.scad](file:///workspaces/BWR_ASV/asv_option_a_model.scad) for structural visualization.

#### Space-Saving Construction Steps
1. **Modular Tube Hulls**: Cut two PVC pipes to 2.53m. Use PVC primer and cement to glue domed end-caps. No molding or sanding is required.
2. **Bolt-On Crossbeams**: Strap the hulls to four 2020 aluminum crossbeams using galvanized U-bolts cushioned with rubber strips.
3. **Coroplast Deck Mount**: Rivet the 4mm Coroplast deck sheets directly to the 2020 extrusion slots.
4. **Disassembly**: The frame can be unbolted from the hulls, breaking the model down into three flat components for easy transport and apartment storage.

---

### 7.2 Option B: Aspect-Optimized 3.40m Centerline Catamaran

This design utilizes a long, narrow deck specifically optimized for standard-dimension flexible panels placed end-to-end along the centerline, reducing overall beam width and drag.

![Option B: 3.40m Centerline Catamaran Blueprint](./asv_option_b_blueprint.png)

#### Technical Specifications & Sizing
* **Pontoon Hulls**: Dual 6-inch (150mm) SDR-35 PVC pipes (recommended for weight savings; see the [Hull 3D Printing & Weight Evaluation](file:///home/pcarff/.gemini/antigravity-ide/brain/c5a15662-1010-4b0d-a70a-d77a53272316/pontoon_3d_print_evaluation.md)), 3.40m length, sealed with aerodynamic dome end-caps.
* **Beam Width**: 1.2m (sleeker aspect ratio to reduce wave-making resistance).
* **Frame**: 2020 (20mm x 20mm) T-slot anodized aluminum.
* **Solar Deck**: Long centerline corridor deck ($3.0\text{m} \times 1.4\text{m}$) holding four 200W flexible panels in an end-to-end centerline grid.
* **Waterproofing**: Compact locking food-grade polycarbonate containers positioned aft of the panels.

#### Space-Saving Construction Steps
1. **Slim Hull Preparation**: Cut two 6-inch PVC pipes to 3.4m. Cement end-caps.
2. **Narrow Cross-Bracing**: Assemble a narrow structural ladder frame using 2020 aluminum extrusions. Bridge spacing is kept at 1.2m total width.
3. **Inline Panel Layout**: Lay the four 200W flexible panels in series along the centerline of the ladder frame, securing them with marine zip-ties or snaps through the panel eyelets.
4. **Electronics Integration**: Place the STM32 avionics and Raspberry Pi 5 in a single large snap-lock enclosure mounted at the stern to keep the centerline clear for solar exposure.

---

### 7.3 Option C: 1.0m Prototype/Development Model (Scale & Comms Testing)

This design is a scaled-down development platform of Option A, optimized for testing electronics, controls, and communications locally in calm water (lakes/ponds). It is not intended for open-water or multi-day excursions.

![Option C: 1.0m Prototype Blueprint](./asv_option_c_blueprint.png)

#### Technical Specifications & Sizing
* **Pontoon Hulls**: Dual 4-inch (100mm) Schedule 40 PVC pipes, 1.0m length, sealed with PVC end-caps.
* **Beam Width**: 0.6m (total overall width).
* **Frame**: 2020 (20mm x 20mm) T-slot anodized aluminum.
* **Solar Array**: Single 100W flexible solar panel (approx. 1000mm x 520mm) or dual 50W panels.
* **Power System**: 24V or 12V LiFePO4 battery bank (e.g., 24V 10Ah or 12V 20Ah, approx. 240 Wh).
* **Propulsion**: Dual BlueRobotics T200 thrusters run at lower voltage (12V-24V) drawing 15W-20W cruising thrust.
* **Electronics**: Raspberry Pi 5 + STM32 MCU mounted inside a single watertight IP67 snap-lock container.

#### Space-Saving Construction Steps
1. **Compact Tube Hulls**: Cut two 4-inch PVC pipes to 1.0m. Cement end-caps.
2. **Simplified Framing**: Assemble a simple rectangular frame using 2020 aluminum extrusions ($1.0\text{m} \times 0.6\text{m}$).
3. **Single Panel Mounting**: Mount the single 100W flexible solar panel directly across the center deck extrusions.
4. **Bench-Friendly Sizing**: This prototype fits easily on a standard workbench/kitchen table and can be transported fully assembled in the trunk of a car.
