# Engineering Review & Recommendations: SeaCharger & SunChallenger

This report reviews the successful transoceanic crossings and design architectures of the **SeaCharger** (Pacific crossing, 2016) and **SunChallenger II** (long-endurance catamaran, 2019) to extract helpful insights and recommend structural, electrical, and telemetry improvements for the Blue-Water Rover ASV.

---

## 1. Key Engineering Takeaways

### 1.1 SeaCharger (2.3m Monohull)
*   **Extreme Weight Efficiency**: SeaCharger weighed only **$22.7\text{ kg}$** ($50\text{ lbs}$) including its foam/fiberglass hull, $200\text{W}$ solar panels, and $500\text{Wh}$ battery bank. This allowed it to cruise at $2\text{ knots}$ drawing only $\approx 30\text{W}$ of propulsion power.
*   **Magnetic Coupling Drive**: Instead of dynamic shaft seals (which degrade and leak under continuous rotation), SeaCharger used a brushless motor inside a sealed compartment driving the propeller shaft via magnetic coupling. This eliminated a primary marine failure point.
*   **Actuator Failures**: The vessel suffered a rudder steering failure on its second leg. Movable steering rudders and exposed linkages are highly vulnerable to marine growth, kelp entanglement, and mechanical wear.
*   **Plast-Laminated Panels**: Renogy bendable plastic-laminated panels were used rather than heavy glass-aluminum panels, reducing weight and eliminating aluminum corrosion.

### 1.2 SunChallenger II (4.8m Catamaran)
*   **Redundancy is Vital**: The first SunChallenger prototype failed after 7 days due to component wear with no backup. SunChallenger II incorporated dual trolling motors, dual MPPT charge controllers, and dual computers (Raspberry Pi & Jetson Nano).
*   **Catamaran Hull Choice**: SunChallenger II selected a catamaran form factor to maximize horizontal deck area for a $1500\text{W}$ glass solar array while keeping drag low.
*   **Object Avoidance**: Waypoint navigation was coupled with active vision processing (Jetson Nano) and sonar to avoid coastal debris, marine life, and shallow areas.

---

## 2. Recommended Changes for Blue-Water Rover (BWR) ASV

Based on the review of these two projects, we recommend integrating the following modifications into our ASV design:

### 2.1 Propulsion & Steering: Maintain Rudderless, Add Magnetic Seals
*   **Keep Differential Steering**: Our design utilizes twin brushless thrusters for differential steering (no rudders). This aligns with the lesson that mechanical rudder actuators are high-wear failure points.
*   **Thruster Sealing**: Ensure the selected thrusters (e.g., BlueRobotics T200) use potted stators and water-lubricated ceramic bearings (or magnetic couplings) rather than mechanical shaft seals.

### 2.2 Electrical Power: Redundant Charge Controllers
*   **Dual MPPT Charge Controllers**: Split our $800\text{W}$ solar array into two independent $400\text{W}$ circuits (e.g., left hull panels vs. right hull panels) connected to two separate MPPT charge controllers.
    *   *Justification*: If one charge controller fails or is shaded by the mast, the other controller continues charging the battery bank at $50\%$ capacity.

### 2.3 Telemetry: Hybrid LoRa + Satellite Fail-Safe
*   > [!IMPORTANT]
    > **Satellite Backup Transceiver**: Add a low-power satellite transceiver (e.g., RockBLOCK Iridium 9603 module) to the electronics box.
    *   *Justification*: Our 915 MHz MeshCore LoRa network is excellent for low-power, high-frequency coastal tracking, but is limited to a $45\text{ NM}$ range. If the vessel drifts offshore due to currents or wind, it will lose comms. An Iridium satellite transceiver broadcasting a basic diagnostic GPS payload (`TEL:DIAG`) every 2–4 hours ensures we never lose track of the vessel.

### 2.4 Structural: SDR-35 PVC Hull Upgrade
*   **Mandatory SDR-35 PVC Hulls**: Solidify the use of thin-walled SDR-35 PVC pipe ($3.8\text{ kg/m}$) over Schedule 40 ($12.5\text{ kg/m}$) for the Option A and B catamarans.
    *   *Justification*: Emulating SeaCharger's weight-conscious approach is critical. Reducing hull weight by $40\text{–}50\text{ kg}$ keeps our draft at $50\%$, minimizing drag and preventing constant deck wash.
