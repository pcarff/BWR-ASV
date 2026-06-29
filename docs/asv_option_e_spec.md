# Design Specification Document (ESD-01-E)
## Project Blue-Water Rover: Option E (Keel-Bulb Stabilized Catamaran)
## Revision: 1.0

This document outlines the detailed mechanical, electrical, and telemetry specifications for the Option E (Keel-Bulb Stabilized Catamaran) configuration of the Blue-Water Rover ASV. This variant represents a SWATH-hybrid design optimized for **minimal hydrodynamic drag, high stability, self-righting capability, and apartment-scale fabrication** using basic tools and 3D printing.

---

## 1. Physical & Hydrodynamic Specifications

### 1.1 Dimensions & Hull Layout
*   **Outboard Pontoons**: Dual 6-inch (150mm nominal / 168.3mm OD) SDR-35 PVC pipes, 2.53m length, mounted **touching each other** along the centerline (total width: 336.6mm).
*   **3D-Printed Bow Cap**: A custom, aerodynamic dual-nosed bow cap printed in **ASA** that merges both 6-inch PVC hulls at the front to slice through water and prevent debris accumulation between the pipes.
*   **Vertical Keel Fin**: A single 3-inch (88.9mm OD) PVC pipe extending centerline from the bottom of the outer pontoons down to the keel bulb (length: 400mm). This pipe acts as a rigid structural strut and a watertight conduit for routing motor and battery wiring up to the deck.
*   **Central Keel Bulb**: A 140mm diameter, 900mm long PVC capsule suspended centerline at z = -450mm below the outer hulls. Features a custom 3D-printed aerodynamic nose cone.
*   **Overall Beam Width**: 1.0m (frame width).
*   **Solar Deck Size**: 1.4m width  x  2.0m length (2.8 m²). Made of 4mm Coroplast, overhanging the narrow hulls by 530mm on both sides.
*   **Total Dry Mass**: ~ 96.5 kg (Payload: 85 kg + Hulls/Frame: 11.5 kg).
*   **Draft**: ~ 61\% under full 96.5 kg load.

### 1.2 Self-Righting Moments (SWATH Physics)
*   **Center of Gravity (G)**: Housed deep inside the central keel bulb (z ~ -450mm below the waterline) where the heavy 35 kg battery bank is located.
*   **Center of Buoyancy (B)**: Located near the water line (z ~ -80mm).
*   **Self-Righting Capability**: With G slung 370mm below B, the vessel has an extremely high righting arm (GZ). In the event of a roll past 90° or a complete capsize (180°), the heavy battery ballast bulb will swing downwards, immediately self-righting the vessel.

---

## 2. Power & Electrical Architecture

*   **Submerged Battery Vault**: The 48V  115Ah LiFePO4 battery bank (35 kg) is packed inside the watertight central keel bulb. Sinking the battery cells underwater provides excellent passive cooling from the cold sea water.
*   **Solar Array**: Eight 100W flexible plastic-laminated solar panels (540mm  x  1050mm) arranged in a 4x2 grid on the overhanging deck.
*   **Redundant Charging**: The array is split into two independent 400W charging circuits running to two separate **Victron SmartSolar MPPT 75/15** controllers.

---

## 3. Propulsion & Steering (Keel-Integrated)

*   **Stern-Mounted Keel Thruster**: A single brushless thruster (e.g., BlueRobotics T200 with potted stator and ceramic water-lubricated bearings) bolted directly to the stern transom of the central keel bulb.
    *   *Cruise Speed*: ~ 3.4 knots at 60W power draw (increased efficiency due to lower drag and inline thrust alignment).
*   **Keel Rudder**: A custom Delrin rudder blade mounted directly behind the thruster nozzle at the stern of the keel bulb.
*   **Actuator**: A high-torque, titanium-gear waterproof servo (Savox SW-1210SG) housed inside a sealed compartment inside the keel bulb, connecting to the rudder shaft via a double-sealed rubber boot.

---

## 4. Telemetry & Communications

*   **Primary Coastal Link**: MeshCore LoRa companion node operating at 915 MHz, transmitting diagnostics (`TEL:DIAG`) to onshore repeaters up to 45 NM.
*   **Secondary Satellite Link**: RockBLOCK Iridium 9603 satellite transceiver mounted inside the deck vault, acting as a global fail-safe link if LoRa comms drop for >30 minutes.

---

## 5. Apartment-Scale Bill of Materials (BOM)

| Component Category | Description | Qty | Est. Cost |
| :--- | :--- | :--- | :--- |
| **Outboard Pontoons** | 6-inch SDR-35 Thin-Walled PVC Sewer Pipe (10 ft length) | 2 | \$60 |
| **Outboard Pontoons** | 6-inch PVC Domed End-Caps (Stern only) | 2 | \$20 |
| **Keel Fin & Bulb** | 3-inch Schedule 40 PVC Pipe (conduit) | 1 | \$15 |
| **Keel Fin & Bulb** | 140mm (approx. 5.5") PVC Drainage Pipe (keel bulb) | 1 | \$20 |
| **3D Printed Parts** | Custom dual-nosed 6" pontoon bow cap (ASA) | 1 | \$40 (filament) |
| **3D Printed Parts** | Custom 140mm keel bulb nose cone (ASA) | 1 | \$15 (filament) |
| **3D Printed Parts** | Keel root connection collar & drop brackets (ASA) | 1 | \$30 (filament) |
| **Structure** | 2020 (20mm x 20mm) T-Slot Anodized Aluminum Extrusions | 6 | \$70 |
| **Deck** | 4mm White Coroplast Sheet (1.4m  x  2.0m) | 1 | \$25 |
| **Power** | 48V 115Ah LiFePO4 battery cells (cylindrical) | 16 | \$900 |
| **Power** | Victron SmartSolar MPPT 75/15 Charge Controller | 2 | \$160 |
| **Solar** | Renogy 100W Flexible Solar Panel | 8 | \$800 |
| **Propulsion** | BlueRobotics T200 Brushless Thruster | 1 | \$250 |
| **Steering** | Savox SW-1210SG Waterproof High-Torque Servo | 1 | \$90 |
| **Steering** | Delrin Rudder Assembly and hardware | 1 | \$35 |
| **Electronics** | Raspberry Pi 5 + STM32 Autopilot Board | 1 | \$150 |
| **Telemetry** | MeshCore LoRa Transceiver + RockBLOCK Iridium 9603 | 1 | \$350 |
| **Total Est. Cost**| | | **\$3,030** |

---

## 6. Assembly & Construction Instructions

1.  **Outer Hulls Assembly**: Lay the two 6-inch PVC outboard pontoon pipes parallel and touching each other. Secure them using heavy-duty industrial straps and epoxy-glue them along the seam. At the bow, slip and cement the custom 3D-printed aerodynamic dual-nosed ASA cap over both pipes. Use standard PVC end-caps to seal the stern.
2.  **Keel Fin Root Installation**: Bolt the 3D-printed ASA keel root connection collar directly between the two outer pontoons. The collar clamps the vertical 3-inch PVC pipe (keel fin) centerline.
3.  **Keel Bulb Integration**: Cement the bottom of the 3-inch keel fin to a 3D-printed connection collar on the top of the 140mm PVC keel bulb. Slide the inline cylindrical battery cell pack inside the keel bulb, routing the main power lines up through the hollow keel fin. Use PVC cement to secure the 3D-printed nose cone on the bulb.
4.  **Rudder and Motor Mounting**: Bolt the BlueRobotics T200 thruster directly to the stern end-cap of the central keel bulb. Machine the rudder, run the shaft through a watertight boot, and link it to the Savox servo mounted inside the bulb before sealing the stern cap.
5.  **Frame and Deck Attachment**: Assemble a simple rectangular frame using 2020 aluminum extrusions (1.0m  x  2.0m). Secure it to the top of the outboard pontoons using standard brackets. Bolt the 4mm Coroplast deck, mount the 8 flexible solar panels, and route all wiring through glands into the deck-mounted electronics vault.
