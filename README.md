# Project Blue-Water Rover (BWR) ASV

Project Blue-Water Rover is a long-range, solar-assisted Autonomous Surface Vehicle (ASV) engineered to navigate an unassisted ocean voyage from Charleston, SC, around the Florida Keys, to Tampa Bay, FL (approximately 650–700 nautical miles). 

This repository contains the physical specifications, control system architectures, telemetry protocol definitions, and an interactive mission control simulator for the vessel.

---

## 1. System Overview

### 1.1 Hydro-Stabilized Catamaran (Option F)
The vessel utilizes a true catamaran hull configuration optimized for seaworthiness, low hydrodynamic drag, and high solar panel surface area:
*   **Hulls**: Dual 6-inch SDR-35 PVC pontoons ($2.53\text{m}$ length) spaced $800\text{mm}$ center-to-center, floating at a safe and efficient $50\%$ draft.
*   **Stability**: Swept-back aluminum foil keel fin ($45^\circ$ rake angle) terminating in a submerged $15\text{ kg}$ solid lead ballast bulb. This configuration provides a powerful recovery righting moment for automated self-righting during capsize without housing any sensitive electronics underwater.
*   **Propulsion**: Dual transom-mounted BlueRobotics T200 brushless underwater thrusters. Directional steering is achieved entirely via differential thrust (rudderless), eliminating mechanical steering linkages.
*   **Power**: An $800\text{W}$ deck-mounted monocrystalline flexible solar array split into dual independent MPPT charging circuits feeding a deck-mounted $48\text{V } 115\text{Ah}$ LiFePO4 battery bank.

### 1.2 Three-Tier Control Stack Architecture
The onboard avionics are isolated into independent tiers to guarantee core navigation and survival even during software lockups or perception reboots:
1.  **Tier 1: Perception & Decision (Jetson Orin Nano)**: Processes 3D depth feeds from an **Intel RealSense D455** depth camera using ROS2. Responsible for COLREGs obstacle avoidance. Powered ON/OFF dynamically by the Pi to conserve energy.
2.  **Tier 2: Companion & Telemetry Hub (Raspberry Pi 4 Model B)**: Operates 24/7. Manages communication routing, processes incoming command frames, transmits diagnostics, and handles power state switching.
3.  **Tier 3: Navigation & Actuation (Pixhawk 6X)**: Runs PX4 or ArduPilot on a real-time RTOS. Performs sensor fusion and attitude/heading control. Connects to **Dual Holybro F9P RTK-GPS** modules to calculate heading using GPS carrier-phase yaw, bypassing compass magnetic interference.
4.  **Tier 0: Environmental Watchdog (Arduino Nano)**: Monitors watertight enclosure temperature/humidity and leak sensors. Automatically power-cycles companion compute rails via MOSFET switches if a watchdog heartbeat is lost.

---

## 2. Directory Layout & Document Map

### 2.1 File Structure
```
├── comms/                       # Python telemetry handler & test suites
│   ├── telemetry_handler.py     # XOR-checksummed ASCII packet parser & watchdog
│   └── test_telemetry.py        # Telemetry testing script
├── docs/                        # Specifications, comparisons, and design notes
│   ├── asv_option_f_spec.md     # Catamaran Option F primary design specification
│   ├── asv_vessel_design.md     # Comparative hull designs (Option A to E)
│   ├── comms_protocol.md        # UART serial packet specs & MeshCore setup
│   ├── spec.md                  # Initial draft spec and solar power balance math
│   └── vessel_assessment_recommendations.md  # Structural evaluation & historical studies
├── index.html                   # Mission Control Dashboard & Simulator webpage
├── app.js                       # Frontend simulation logic & physics engine
├── style.css                    # Dashboard interface styles
├── pvc_extrusion_bracket.scad   # Parametric 3D-printable hull mounting bracket code
└── README.md                    # Project landing page (this document)
```

### 2.2 Core Documentation Links
Detailed engineering specifications and design justifications are linked below:
*   [Option F Specification (docs/asv_option_f_spec.md)](file:///workspaces/BWR_ASV/docs/asv_option_f_spec.md): Complete mechanical details, updated BOM, and step-by-step assembly instructions.
*   [Vessel Design Study (docs/asv_vessel_design.md)](file:///workspaces/BWR_ASV/docs/asv_vessel_design.md): Deep-dive analysis of monohull vs. catamaran hydrodynamics and solar deck layouts.
*   [Telemetry Protocol Spec (docs/comms_protocol.md)](file:///workspaces/BWR_ASV/docs/comms_protocol.md): Serial packet framing, duplicate echo suppression, and MeshCore AES-256 CLI configurations.
*   [Systems Engineering Recommendations (docs/vessel_assessment_recommendations.md)](file:///workspaces/BWR_ASV/docs/vessel_assessment_recommendations.md): Comparative reviews of historical transoceanic crossings (*SeaCharger* & *SunChallenger II*) and PVC weight-to-buoyancy evaluations.
*   [Avionics Hardware Architecture](file:///home/pcarff/.gemini/antigravity-ide/brain/0ac91ee5-cb3c-4ac3-8ae8-dadeb8bd1fae/hardware_architecture.md): The detailed block diagram, component roles, interface matrix, and power state transitions.

---

## 3. Mission Control Dashboard & Simulator

This repository contains an interactive, web-based simulation tool to validate propulsion power draw, solar energy harvesting, battery depleting curves, and waypoint tracking under varying conditions:

1.  Open the [index.html](file:///workspaces/BWR_ASV/index.html) file in a modern web browser.
2.  Adjust the **Weather System** (Sunny, Overcast, Storm Front, Night) to simulate changes in solar panel efficiency.
3.  Modify the **Simulation Speed** (1x to 60x time lapse) to fast-forward the voyage.
4.  Monitor the live diagnostic telemetry panel, showing real-time battery SoC %, thruster outputs, coordinate tracking, and serial command frames.
