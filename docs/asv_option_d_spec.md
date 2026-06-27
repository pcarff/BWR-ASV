# Design Specification Document (ESD-01-D)
## Project Blue-Water Rover: Option D (Keel-Stabilized Narrow Catamaran)
## Revision: 1.0

This document outlines the detailed mechanical, electrical, and telemetry specifications for the Option D (Keel-Stabilized Narrow Catamaran) configuration of the Blue-Water Rover ASV. This variant is optimized for **apartment-scale assembly, low fabrication cost, and self-righting survival physics** during the Charleston-to-Tampa ocean crossing.

---

## 1. Physical & Hydrodynamic Specifications

### 1.1 Dimensions & Waterline
*   **Outer Stabilizing Pontoons**: Dual 6-inch (150mm nominal / $168.3\text{mm}$ OD) SDR-35 thin-walled PVC pipes, $2.53\text{m}$ length, sealed with domed end-caps.
*   **Central Ballast Keel**: Single 6-inch ($168.3\text{mm}$ OD) SDR-35 PVC pipe, $2.53\text{m}$ length, slung centerline and suspended $120\text{mm}$ below the horizontal plane of the outer pontoons.
*   **Overall Beam Width**: $1.0\text{m}$ (highly compact footprint).
*   **Solar Deck Size**: $1.4\text{m}$ width $\times 2.0\text{m}$ length ($2.8\text{ m}^2$). Made of $4\text{mm}$ Coroplast, cantilevered to overhang the outer pontoons by $200\text{mm}$ on both sides.
*   **Total Dry Mass**: $\approx 99.5\text{ kg}$ (Payload: $85\text{ kg}$ + Hulls/Frame: $14.5\text{ kg}$).
*   **Volumetric Displacement**:
    *   Outer Hulls: $2 \times 56.1\text{ Liters} = 112.2\text{ Liters}$ (when fully submerged).
    *   Central Keel Hull: $56.1\text{ Liters}$ (when fully submerged).
    *   Total Displacement Capacity: $168.3\text{ Liters}$ (freshwater equivalent).
*   **Draft**: $\approx 59\%$ under full $99.5\text{ kg}$ load, maintaining a safe deck clearance above the splash zone.

### 1.2 Self-Righting Mechanics
*   **Center of Gravity ($G$)**: Housed at the bottom of the central keel tube ($z \approx -150\text{mm}$ below the water line), where the heavy $35\text{ kg}$ battery bank sits.
*   **Center of Buoyancy ($B$)**: Placed at the volumetric center of the three tubes ($z \approx -40\text{mm}$).
*   **Stability physics**: Because $G$ is situated significantly below $B$ ($GM > 100\text{mm}$), the vessel acts like a keelboat. If rolled $180^\circ$ by a breaking wave, the weighted central keel generates a massive righting moment that **automatically flips the vessel upright**.

---

## 2. Power & Electrical Architecture

*   **Primary Battery Vault**: $48\text{V } 115\text{Ah}$ Lithium Iron Phosphate (LiFePO4) bank ($5,520\text{ Wh}$ capacity, $35\text{ kg}$) arranged in a single inline cylindrical pack sliding inside the central keel PVC tube.
*   **Solar Array**: Eight $100\text{W}$ flexible plastic-laminated solar panels ($540\text{mm} \times 1050\text{mm}$) arranged in a 4x2 grid on the overhanging deck.
*   **Redundant Charging Circuits**:
    *   The array is split into two independent $400\text{W}$ circuits (Left 4 panels vs. Right 4 panels).
    *   Each circuit runs to its own **Victron SmartSolar MPPT 75/15** charge controller inside the deck vault.
    *   *Failure Mode*: If one controller or side of the deck suffers damage or severe shading, the other charges the battery bank at $50\%$ capacity.

---

## 3. Propulsion & Steering (SeaCharger Adaptation)

*   **Centerline Thruster**: A single centerline brushless thruster (e.g., BlueRobotics T200 with potted stator and ceramic water-lubricated bearings) mounted at the stern transom of the central keel tube.
    *   *Operating Cruise Power*: $60\text{W}$ output at $48\text{V}$.
    *   *Cruise Speed*: $\approx 3.2\text{ knots}$.
*   **Mechanical Steering Rudder**: A custom-machined $10\text{mm}$ Delrin (acetal) rudder blade mounted directly behind the centerline thruster nozzle to redirect thrust.
*   **Rudder Actuation**: A high-torque, IP67-rated waterproof titanium-gear digital servo (e.g., Savox SW-1210SG) mounted inside a watertight hatch compartment in the stern end-cap of the central keel tube. Connects to the rudder shaft via a double-sealed boot linkage.

---

## 4. Telemetry & Communications

*   **Primary Coastal Link**: MeshCore LoRa companion node operating at $915\text{ MHz}$, skipping telemetry packets back to the Charleston metro hub command station via fixed onshore mesh repeaters. (Max range: $45\text{ NM}$).
*   **Secondary Satellite Link**: RockBLOCK Iridium 9603 satellite transceiver mounted inside the deck vault.
    *   *Heartbeat Protocol*: Transmits a compact binary packet containing GPS coordinates, battery voltage, solar charge state, and autopilot mode (`TEL:DIAG`) every 2 hours.
    *   *Fail-safe*: Activates automatically if LoRa communications are lost for $>30\text{ minutes}$.

---

## 5. Apartment-Scale Bill of Materials (BOM)

| Component Category | Description | Qty | Est. Cost |
| :--- | :--- | :--- | :--- |
| **Hulls** | 6-inch SDR-35 Thin-Walled PVC Sewer Pipe (10 ft length) | 3 | \$90 |
| **Hulls** | 6-inch PVC Domed End-Caps | 6 | \$60 |
| **Structure** | 2020 (20mm x 20mm) T-Slot Anodized Aluminum Extrusion (1.0m) | 4 | \$40 |
| **Structure** | 2020 T-Slot Aluminum Extrusions (2.0m longitudinal) | 2 | \$30 |
| **Brackets** | 3D-Printed Custom Drop Brackets (ASA Filament, 100% infill) | 4 | \$20 (filament) |
| **Brackets** | 3D-Printed Standard outer cradle brackets (ASA) | 8 | \$30 (filament) |
| **Deck** | 4mm White Coroplast Sheet ($1.4\text{m} \times 2.0\text{m}$) | 1 | \$25 |
| **Power** | 48V 115Ah LiFePO4 battery cells (cylindrical) | 16 | \$900 |
| **Power** | Victron SmartSolar MPPT 75/15 Charge Controller | 2 | \$160 |
| **Solar** | Renogy 100W Flexible Solar Panel | 8 | \$800 |
| **Propulsion** | BlueRobotics T200 Brushless Thruster | 1 | \$250 |
| **Steering** | Savox SW-1210SG Waterproof High-Torque Servo | 1 | \$90 |
| **Steering** | Delrin Sheet (10mm thick for custom rudder blade) | 1 | \$30 |
| **Electronics** | Raspberry Pi 5 + STM32 Autopilot Board | 1 | \$150 |
| **Telemetry** | MeshCore LoRa Transceiver + RockBLOCK Iridium 9603 | 1 | \$350 |
| **Total Est. Cost**| | | **\$3,025** |

---

## 6. Assembly & Construction Instructions

1.  **Hull Preparation**: Cut the three PVC sewer pipes to exactly $2.53\text{m}$. Use PVC cement to secure the domed end-caps to the outer pontoons. For the central keel, install a watertight access hatch in the stern dome cap to route steering wires and battery cables.
2.  **Keel Battery Packaging**: Secure the 16 LiFePO4 battery cells in a single inline cylindrical pack wrapped in thick foam padding. Slide this assembly into the central keel PVC tube, centering the weight along the length of the tube. Secure the batteries with internal bulkheads to prevent shifting.
3.  **Frame Assembly**: Build a rectangular frame using 2020 aluminum extrusions ($1.0\text{m} \times 2.0\text{m}$).
4.  **Suspension Bracket Integration**: 
    *   Mount the outer hulls to the frame using the standard [pvc_extrusion_bracket.scad](file:///workspaces/BWR_ASV/pvc_extrusion_bracket.scad) brackets (lined with 1.5mm rubber pads).
    *   Mount the central keel using custom drop brackets that suspend the keel tube centerline $120\text{mm}$ below the level of the outer hulls, ensuring it is fully submerged.
5.  **Steering & Motor Rigging**: Bolt the BlueRobotics T200 thruster to the transom of the central keel. Machine the rudder from Delrin, mount it to a $6\text{mm}$ stainless steel shaft, and run the linkage through a waterproof boot to the internal Savox servo.
6.  **Deck and Solar Installation**: Bolt the $4\text{mm}$ Coroplast deck sheet to the 2020 extrusion slots. Apply heavy-duty double-sided outdoor mounting tape to secure the 8 flexible solar panels, routing their wires through IP68 compression glands into the dry box compartments.
