# Systems Engineering Assessment & Recommendations
## Project Blue-Water Rover: Long-Range Solar ASV (ESD-01)
## Author: Systems Engineering Agent & Team

This integrated document combines the structural feasibility studies for the ASV pontoon hulls (3D printing vs. PVC extrusion) and the comparative reviews of historical long-range autonomous solar vessels (**SeaCharger** and **SunChallenger II**). It presents a unified engineering assessment and outlines design recommendations to maximize the probability of mission success for the Charleston-to-Tampa Bay voyage.

---

## 1. Executive Summary

To successfully navigate an unassisted $650\text{–}700\text{ NM}$ ocean voyage, the Blue-Water Rover (BWR) must maintain a careful balance between structural robustness, power generation, weight, and system redundancy. 

Our findings indicate:
1.  **Hull Material**: Extruded **Schedule 40 PVC** is too heavy ($12.5\text{ kg/m}$ for 8" pipe) and would force the vessel to float at a $>77\%$ draft. **3D printing the hulls in ASA** or using thin-walled **SDR-35 PVC pipe** ($3.8\text{ kg/m}$) reduces deadweight by over $40\text{–}50\text{ kg}$, lowering the draft to a safe and efficient $50\%$.
2.  **Redundancy**: The primary cause of autonomous vessel failure in historical voyages (such as the first *SunChallenger* prototype) is component wear-out without backup systems. We must implement redundant power charging, dual thrusters, and hybrid telemetry.
3.  **Drive Mechanics**: Mechanical rudder linkages are high-risk failure points. Differential thruster steering (rudderless) must be maintained, utilizing fully potted, wet-running brushless motors to eliminate dynamic shaft seal failure.

---

## 2. Pontoon Hull Structural Evaluation: 3D Printing vs. PVC Extrusion

### 2.1 Weight & Buoyancy Calculations
For the Option A catamaran hull ($2.53\text{m}$ length, $219.1\text{mm}$ outer diameter), the total displaced volume (freshwater equivalent) is:
$$\text{Displaced Volume} = \pi \cdot r^2 \cdot L \approx \pi \cdot (109.55\text{ mm})^2 \cdot 2530\text{ mm} \approx 95.4\text{ Liters per hull}$$
$$\text{Total Buoyancy (Pair)} \approx 190.8\text{ kg}$$

The dry weight of the ASV payload (batteries, frame, solar panels, and electronics) is estimated at **$85\text{ kg}$**.

*   **Schedule 40 PVC**: Wall thickness of $8.18\text{ mm}$ results in a weight of $12.5\text{ kg/m}$, totaling **$63.3\text{ kg}$** for a pair of hulls.
    $$\text{Total Wet Weight} = 85\text{ kg (payload)} + 63.3\text{ kg (hulls)} = 148.3\text{ kg}$$
    $$\text{Vessel Draft} = \frac{148.3\text{ kg}}{190.8\text{ kg}} \approx 77\%$$
    *A $77\%$ draft exposes the solar deck to constant washing from waves, introducing heavy drag and solar cell shading.*
*   **3D-Printed ASA**: Wall thickness of $3.0\text{ mm}$ with $15\%$ gyroid infill yields a weight of $2.0\text{ kg/m}$, totaling **$10.1\text{ kg}$** for a pair.
    $$\text{Total Wet Weight} = 85\text{ kg (payload)} + 10.1\text{ kg (hulls)} = 95.1\text{ kg}$$
    $$\text{Vessel Draft} = \frac{95.1\text{ kg}}{190.8\text{ kg}} \approx 50\%$$
    *A $50\%$ draft is the hydrodynamic sweet spot, keeping the deck clear of splashes and minimizing wave-making resistance.*
*   **SDR-35 PVC / Sewer Pipe**: Wall thickness of $6.1\text{ mm}$ results in a weight of $3.8\text{ kg/m}$, totaling **$19.2\text{ kg}$** for a pair.
    $$\text{Total Wet Weight} = 85\text{ kg (payload)} + 19.2\text{ kg (hulls)} = 104.2\text{ kg}$$
    $$\text{Vessel Draft} = \frac{104.2\text{ kg}}{190.8\text{ kg}} \approx 55\%$$
    *Provides a very safe waterline while using continuous, robust extruded pipe.*

### 2.2 Material Selection for Marine 3D Printing
*   **PLA (Polylactic Acid)**: *Unacceptable.* Low UV resistance, absorbs water, and has a glass transition temperature of only $60^\circ\text{C}$. Direct summer sun exposure on water will warp the hulls.
*   **PETG (Polyethylene Terephthalate Glycol)**: *Marginal.* Good UV and chemical resistance, but prone to plastic creep under structural clamp tension.
*   **ASA (Acrylic Styrene Acrylonitrile)**: *Recommended.* Excellent UV resistance, high impact strength, high thermal tolerance ($95^\circ\text{C}$ glass transition), and can be solvent-welded using acetone.

### 3.3 3D-Printed Modular Assembly Challenges & Solutions
1.  **Segmented Slicing**: Standard printers cannot print a $2.53\text{m}$ part. The hulls must be printed in $10\text{–}12$ modular segments of $\approx 220\text{mm}$ length.
2.  **Porosity**: FDM prints have micro-voids between layers. Continuous submersion over a $7\text{–}10$ day voyage will force water inside.
    *   *Mitigation*: The inner and outer surfaces must be sealed with a marine-grade epoxy coating (e.g., West System 105/205).
3.  **Seam Shear Bending Moments**: Wave impact forces can shear flat butt-joints.
    *   *Mitigation*: Implement male/female interlocking joint collars and run a central **$16\text{mm}$ stainless steel tension spar** down the centerline of each hull. Tensioning the end-caps squeezes the segments together in compression, transferring bending loads to the metal spar.
4.  **Fail-Safe Bulkheads**: Unlike continuous PVC pipes, 3D printing allows for integrated internal partition bulkheads within each segment. This creates isolated watertight chambers, ensuring a hull puncture does not sink the craft.

---

## 3. Historical Autonomous Solar Vessel Case Studies

### 3.1 SeaCharger (California to Hawaii, 2016)
SeaCharger was a $2.3\text{m}$ monohull that completed a $2,100\text{ NM}$ Pacific crossing on solar power alone.
*   **Weight Minimization**: Total weight was only **$22.7\text{ kg}$** ($50\text{ lbs}$). Its $200\text{W}$ solar array and tiny $500\text{Wh}$ battery bank were sufficient because the low mass required only $\approx 30\text{W}$ of cruising power.
*   **Magnetic Coupling Drive**: SeaCharger bypassed dynamic shaft seals by housing its brushless motor in a dry chamber, transferring torque to the propeller shaft via a magnetic coupler through a solid plastic wall.
*   **Steering Wear-Out**: The vessel suffered a rudder failure on a subsequent leg due to actuator wear, demonstrating that moving external steering parts are primary marine failure points.
*   **Corrosion-Free Panels**: Used Renogy flexible plastic-laminated panels, which avoided the corrosion and weight of glass/aluminum frames.

### 3.2 SunChallenger II (Catamaran Ocean Platform, 2019)
SunChallenger II is a $16\text{ft}$ ($4.8\text{m}$) catamaran designed for autonomous marine observation.
*   **Active Redundancy**: Designed specifically to combat the failure of its predecessor (which broke down after 7 days due to lack of backups). It features dual trolling motors (differential steering), dual MPPT solar controllers, and redundant computers (2x Pi, 2x Jetson Nano).
*   **Catamaran Stability**: The twin hulls provided a stable, wide platform for $1500\text{W}$ of solar panels.
*   **Obstacle Avoidance**: Utilized active computer vision (Jetson Nano) and sonar to avoid debris, shallows, and maritime traffic in coastal zones.

---

## 4. Integrated Design Recommendations for BWR ASV

To integrate the lessons from SeaCharger, SunChallenger II, and our structural evaluations, we recommend the following modifications to the BWR ASV specifications:

### 4.1 Structural Hulls: Adopt SDR-35 PVC
*   **SDR-35 PVC Baseline**: Rather than heavy Schedule 40 PVC or high-labor modular 3D printing, standardize the baseline hulls on thin-walled **SDR-35 PVC pipe** ($3.8\text{ kg/m}$). This saves $44\text{ kg}$ over Schedule 40, ensuring a safe draft ($\approx 55\%$) while retaining the impact resistance of continuous extruded plastic.
*   *Note*: The modular 3D-printed ASA hull remains a viable high-performance alternative if weight-minimization and internal bulkheads are prioritized, provided they are sealed in marine epoxy and reinforced with central tension spars.

### 4.2 Propulsion & Steering: Rudderless, Potted Motors
*   **Maintain Differential Thrusters**: Keep our rudderless, dual-thruster differential steering layout. This eliminates steering servos and mechanical linkages, bypassing the actuator failures seen on SeaCharger and SunChallenger I.
*   **Wet-Running Potted Motors**: Select thrusters (e.g., BlueRobotics T200) that use fully potted stators and water-lubricated ceramic bearings. This avoids the use of dynamic shaft seals, eliminating the leak risk.

### 4.3 Electrical Architecture: Split MPPT Charging
*   **Dual MPPT Charge Controllers**: Split the $800\text{W}$ solar array into two independent $400\text{W}$ charging circuits (e.g., left deck/hull panels vs. right deck/hull panels) connected to two separate MPPT solar charge controllers.
    *   *Justification*: If one controller fails, or is shaded by the sensor mast, the other controller continues harvesting power to the 48V battery bank.

### 4.4 Telemetry & Comms: Hybrid LoRa + Satellite Fail-Safe
*   **Satellite Transceiver Integration**: Add a low-power satellite transceiver module (e.g., RockBLOCK Iridium 9603) inside the electronics box.
    *   *Justification*: The primary MeshCore LoRa network is limited to a $45\text{ NM}$ range. If the vessel drifts offshore due to current or wind, all communication will be lost. An Iridium transceiver configured to broadcast a minimal heartbeat diagnostic payload (`TEL:DIAG`) every 2–4 hours provides a global backup link.

---

## 5. Comparison Matrix

| Design Parameter | Baseline BWR (2.2m) | Option A (Extruded PVC) | Option A (3D-Printed ASA) | BWR Integrated Recommendation |
| :--- | :--- | :--- | :--- | :--- |
| **Hull Material** | HDPE Pontoons | 8" Sch 40 PVC | 8" Modular ASA | **8" SDR-35 Sewer PVC** |
| **Total Hull Mass**| $60\text{ kg}$ | $63.3\text{ kg}$ | $10.1\text{ kg}$ | **$19.2\text{ kg}$** |
| **Est. Draft** | $65\%$ | $77\%$ | $50\%$ | **$55\%$** |
| **Solar Array** | $600\text{W}$ | $800\text{W}$ (Single MPPT) | $800\text{W}$ (Single MPPT) | **$800\text{W}$ (Dual Redundant MPPT)** |
| **Steering** | Differential | Differential | Differential | **Differential (Ceramic/Potted)** |
| **Telemetry** | LoRa Only | LoRa Only | LoRa Only | **Hybrid (LoRa Mesh + Iridium Satellite)** |
