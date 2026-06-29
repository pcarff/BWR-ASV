# Systems Engineering Assessment & Recommendations
## Project Blue-Water Rover: Long-Range Solar ASV (ESD-01)
## Author: Systems Engineering Agent & Team

This integrated document combines the structural feasibility studies for the ASV pontoon hulls (3D printing vs. PVC extrusion) and the comparative reviews of historical long-range autonomous solar vessels (**SeaCharger** and **SunChallenger II**). It presents a unified engineering assessment and outlines design recommendations to maximize the probability of mission success for the Charleston-to-Tampa Bay voyage.

---

## 1. Executive Summary

To successfully navigate an unassisted 650–700 NM ocean voyage, the Blue-Water Rover (BWR) must maintain a careful balance between structural robustness, power generation, weight, and system redundancy. 

Our findings indicate:
1.  **Hull Material**: Extruded **Schedule 40 PVC** is too heavy (12.5 kg/m for 8" pipe) and would force the vessel to float at a >77\% draft. **3D printing the hulls in ASA** or using thin-walled **SDR-35 PVC pipe** (3.8 kg/m) reduces deadweight by over 40–50 kg, lowering the draft to a safe and efficient 50\%.
2.  **Redundancy**: The primary cause of autonomous vessel failure in historical voyages (such as the first *SunChallenger* prototype) is component wear-out without backup systems. We must implement redundant power charging, dual thrusters, and hybrid telemetry.
3.  **Drive Mechanics**: Mechanical rudder linkages are high-risk failure points. Differential thruster steering (rudderless) must be maintained, utilizing fully potted, wet-running brushless motors to eliminate dynamic shaft seal failure.

---

## 2. Pontoon Hull Structural Evaluation: 3D Printing vs. PVC Extrusion

### 2.1 Weight & Buoyancy Calculations
For the Option A catamaran hull (2.53m length, 219.1mm outer diameter), the total displaced volume (freshwater equivalent) is:
Displaced Volume = pi  *  r²  *  L ~ pi  *  (109.55 mm)²  *  2530 mm ~ 95.4 Liters per hull
Total Buoyancy (Pair) ~ 190.8 kg

The dry weight of the ASV payload (batteries, frame, solar panels, and electronics) is estimated at **85 kg**.

*   **Schedule 40 PVC**: Wall thickness of 8.18 mm results in a weight of 12.5 kg/m, totaling **63.3 kg** for a pair of hulls.
    Total Wet Weight = 85 kg (payload) + 63.3 kg (hulls) = 148.3 kg
    Vessel Draft = (148.3 kg) / (190.8 kg) ~ 77\%
    *A 77\% draft exposes the solar deck to constant washing from waves, introducing heavy drag and solar cell shading.*
*   **3D-Printed ASA**: Wall thickness of 3.0 mm with 15\% gyroid infill yields a weight of 2.0 kg/m, totaling **10.1 kg** for a pair.
    Total Wet Weight = 85 kg (payload) + 10.1 kg (hulls) = 95.1 kg
    Vessel Draft = (95.1 kg) / (190.8 kg) ~ 50\%
    *A 50\% draft is the hydrodynamic sweet spot, keeping the deck clear of splashes and minimizing wave-making resistance.*
*   **SDR-35 PVC / Sewer Pipe**: Wall thickness of 6.1 mm results in a weight of 3.8 kg/m, totaling **19.2 kg** for a pair.
    Total Wet Weight = 85 kg (payload) + 19.2 kg (hulls) = 104.2 kg
    Vessel Draft = (104.2 kg) / (190.8 kg) ~ 55\%
    *Provides a very safe waterline while using continuous, robust extruded pipe.*

### 2.2 Material Selection for Marine 3D Printing
*   **PLA (Polylactic Acid)**: *Unacceptable.* Low UV resistance, absorbs water, and has a glass transition temperature of only 60°C. Direct summer sun exposure on water will warp the hulls.
*   **PETG (Polyethylene Terephthalate Glycol)**: *Marginal.* Good UV and chemical resistance, but prone to plastic creep under structural clamp tension.
*   **ASA (Acrylic Styrene Acrylonitrile)**: *Recommended.* Excellent UV resistance, high impact strength, high thermal tolerance (95°C glass transition), and can be solvent-welded using acetone.

### 3.3 3D-Printed Modular Assembly Challenges & Solutions
1.  **Segmented Slicing**: Standard printers cannot print a 2.53m part. The hulls must be printed in 10–12 modular segments of ~ 220mm length.
2.  **Porosity**: FDM prints have micro-voids between layers. Continuous submersion over a 7–10 day voyage will force water inside.
    *   *Mitigation*: The inner and outer surfaces must be sealed with a marine-grade epoxy coating (e.g., West System 105/205).
3.  **Seam Shear Bending Moments**: Wave impact forces can shear flat butt-joints.
    *   *Mitigation*: Implement male/female interlocking joint collars and run a central **16mm stainless steel tension spar** down the centerline of each hull. Tensioning the end-caps squeezes the segments together in compression, transferring bending loads to the metal spar.
4.  **Fail-Safe Bulkheads**: Unlike continuous PVC pipes, 3D printing allows for integrated internal partition bulkheads within each segment. This creates isolated watertight chambers, ensuring a hull puncture does not sink the craft.

---

## 3. Historical Autonomous Solar Vessel Case Studies

### 3.1 SeaCharger (California to Hawaii, 2016)
SeaCharger was a 2.3m monohull that completed a 2,100 NM Pacific crossing on solar power alone.
*   **Weight Minimization**: Total weight was only **22.7 kg** (50 lbs). Its 200W solar array and tiny 500Wh battery bank were sufficient because the low mass required only ~ 30W of cruising power.
*   **Magnetic Coupling Drive**: SeaCharger bypassed dynamic shaft seals by housing its brushless motor in a dry chamber, transferring torque to the propeller shaft via a magnetic coupler through a solid plastic wall.
*   **Steering Wear-Out**: The vessel suffered a rudder failure on a subsequent leg due to actuator wear, demonstrating that moving external steering parts are primary marine failure points.
*   **Corrosion-Free Panels**: Used Renogy flexible plastic-laminated panels, which avoided the corrosion and weight of glass/aluminum frames.

### 3.2 SunChallenger II (Catamaran Ocean Platform, 2019)
SunChallenger II is a 16ft (4.8m) catamaran designed for autonomous marine observation.
*   **Active Redundancy**: Designed specifically to combat the failure of its predecessor (which broke down after 7 days due to lack of backups). It features dual trolling motors (differential steering), dual MPPT solar controllers, and redundant computers (2x Pi, 2x Jetson Nano).
*   **Catamaran Stability**: The twin hulls provided a stable, wide platform for 1500W of solar panels.
*   **Obstacle Avoidance**: Utilized active computer vision (Jetson Nano) and sonar to avoid debris, shallows, and maritime traffic in coastal zones.

---

## 4. Integrated Design Recommendations for BWR ASV

To integrate the lessons from SeaCharger, SunChallenger II, and our structural evaluations, we recommend the following modifications to the BWR ASV specifications:

### 4.1 Structural Hulls: Adopt SDR-35 PVC
*   **SDR-35 PVC Baseline**: Rather than heavy Schedule 40 PVC or high-labor modular 3D printing, standardize the baseline hulls on thin-walled **SDR-35 PVC pipe** (3.8 kg/m). This saves 44 kg over Schedule 40, ensuring a safe draft (~ 55%) while retaining the impact resistance of continuous extruded plastic.
*   > [!CAUTION]
    > **SDR-35 vs. Schedule 40 Dimensional Mismatch Trap**: Although both are nominally "8-inch" pipes, their actual outer diameters differ. 8" Schedule 40 has an OD of **219.1 mm (8.625 in)**, while 8" SDR-35 has an OD of **213.4 mm (8.400 in)**. Standard 8" Schedule 40 slip-on caps will not fit SDR-35 pipe (leaving a sloppy 2.8 mm radial gap). You must use custom 3D-printed dome caps (designed with a 213.4 mm ID) and adjust the CAD mounting bracket parameters in OpenSCAD (`pvc_od = 213.4`) to prevent the hulls from slipping.
*   *Note*: The modular 3D-printed ASA hull remains a viable high-performance alternative if weight-minimization and internal bulkheads are prioritized, provided they are sealed in marine epoxy and reinforced with central tension spars.

### 4.2 Propulsion & Steering: Rudderless, Potted Motors
*   **Maintain Differential Thrusters**: Keep our rudderless, dual-thruster differential steering layout. This eliminates steering servos and mechanical linkages, bypassing the actuator failures seen on SeaCharger and SunChallenger I.
*   **Wet-Running Potted Motors**: Select thrusters (e.g., BlueRobotics T200) that use fully potted stators and water-lubricated ceramic bearings. This avoids the use of dynamic shaft seals, eliminating the leak risk.

### 4.3 Electrical Architecture: Split MPPT Charging
*   **Dual MPPT Charge Controllers**: Split the 800W solar array into two independent 400W charging circuits (e.g., left deck/hull panels vs. right deck/hull panels) connected to two separate MPPT solar charge controllers.
    *   *Justification*: If one controller fails, or is shaded by the sensor mast, the other controller continues harvesting power to the 48V battery bank.

### 4.4 Telemetry & Comms: Hybrid LoRa + Satellite Fail-Safe
*   **Satellite Transceiver Integration**: Add a low-power satellite transceiver module (e.g., RockBLOCK Iridium 9603) inside the electronics box.
    *   *Justification*: The primary MeshCore LoRa network is limited to a 45 NM range. If the vessel drifts offshore due to current or wind, all communication will be lost. An Iridium transceiver configured to broadcast a minimal heartbeat diagnostic payload (`TEL:DIAG`) every 2–4 hours provides a global backup link.

---

## 5. Option D: Keel-Stabilized Narrow Catamaran (SeaCharger Hybrid)

This design adapts SeaCharger's weight-saving, ballast-keel philosophy to a catamaran platform. It is engineered specifically for **ultra-low cost, minimal workshop space, and simple hand tools**.

### 5.1 Physical Layout & Concept
*   **Triple-Tube Configuration**: Rather than two large hulls, this design uses **two narrow outer pontoons** (e.g., 4" or 6" PVC pipes) for lateral stability, and **one central keel tube** (4" or 6" PVC pipe) suspended below the waterline.
*   **Ballast Keel Battery Vault**: The heavy 48V  115Ah battery bank (35 kg) is housed entirely inside the bottom of the central keel tube.
*   **Narrow Beam**: The overall beam width is compressed to **0.8m–1.0m** (compared to Option A's 1.6m).
*   **Solar Overhang**: The 800W solar array is mounted on a wide, lightweight Coroplast deck that sits on cantilevered 2020 extrusions, overhanging the narrow hulls by 30cm on each side.

### 5.2 Apartment & Bench Build Advantages
*   **Ultra-Compact Footprint**: A 1.0m beam fits easily on a single standard workbench or kitchen table.
*   **Ease of Transport**: Unlike a 1.6m wide catamaran which requires a trailer or disassembly, a 1.0m wide vessel can be loaded fully assembled onto standard car roof racks or in the back of an SUV.
*   **Lower Material Cost**: Standard 4" and 6" PVC sewer pipes are widely available at local home centers for a fraction of the cost of 8" Schedule 40/SDR-35 industrial pipes.

### 5.3 Technical & Mechanical Trade-offs
*   **Self-Righting Capability**: Standard catamarans are highly stable but suffer from "catastrophic stability limit"—if they flip, they remain inverted. By placing 35 kg of battery ballast in the submerged central keel tube, the Center of Gravity (G) sits far below the Center of Buoyancy (B). If a storm rolls the ASV, the weighted keel swings down and **automatically self-rights the vessel**, combining the flat deck area of a catamaran with the survival physics of a monohull.
*   **Buoyancy Contribution**: The central keel tube is watertight and submerged, meaning its displaced volume contributes directly to buoyancy. This allows the outer pontoons to be smaller and lighter (e.g., 4" PVC instead of 8" PVC) because the central tube carries the battery load directly.
*   **Propulsion & Steering Adaptations**:
    *   *Differential Steering Constraint*: The narrow 0.8m beam reduces the differential steering torque vector. To navigate effectively against ocean waves, the autopilot must run the thrusters with large thrust differences, wasting energy.
    *   *Single-Motor Option*: To maximize efficiency, we can mount a **single centerline thruster** at the stern of the central keel tube, paired with a small mechanical rudder. While this introduces a rudder failure point (the issue that disabled SeaCharger), it increases battery endurance by up to 30\%.
    *   *Dual-Motor Option*: Keep the twin thrusters on the outer pontoons for redundancy and differential steering. Although the torque arm is reduced, it remains sufficient for coastal navigation.

---

## 6. Option E: Keel-Bulb Stabilized Catamaran (SWATH Hybrid) - Critical Assessment

This design represents a SWATH (Small Waterplane Area Twin Hull) hybrid, combining two touching outboard 6" PVC pontoons, a vertical 3" PVC keel fin, and a submerged central 140mm PVC capsule acting as a battery vault, with a single centerline motor and rudder.

### 6.1 Critical Vulnerability Review
While Option E provides apartment-scale transportability and high theoretical righting moments, it suffers from several severe, potentially mission-ending vulnerabilities:
1. **Structural Keel Fatigue**: The heavy 35 kg battery pack sits at the end of a 400mm leverage arm (the 3" PVC pipe). Open-ocean waves rolling the hulls will create massive bending moments on the 3D-printed ASA root collar and joints. Any collision with coastal sandbars or debris will snap this connection, sinking the batteries.
2. **Submerged Battery Vault Leakage**: Housing the 48V  115Ah lithium battery bank under continuous hydrostatic pressure (z = -450mm) is highly dangerous. A minor leak in the 3D-printed caps or PVC cement will flood the vault with saltwater, causing a short-circuit, rapid corrosion, or thermal runaway.
3. **Single Point of Steering & Propulsion Failure**: Using a single thruster and mechanical rudder is a high-risk failure profile. If the rudder servo jams, or if the rudder's rubber sealing boot fails under hydrostatic pressure, the vessel will be disabled.
4. **Seaweed "Rake" effect**: The vertical keel fin and bulb will act as a seaweed scoop, dragging sargassum and marine lines, creating immense drag and wrapping the propeller.
5. **High Waterplane Draft**: Because the outer hulls are touching and float at a 73–76\% draft, the solar deck sits extremely close to the waterline, exposing panels to constant wave washing, drag, and shading.

---

## 7. Option F: Hydro-Stabilized Ocean Catamaran (Ballast-Keel Hybrid)

Option F is a corrected configuration designed specifically to eliminate the failure points of Option E while preserving its compact transport benefits and self-righting physics. The detailed specification is located at [asv_option_f_spec.md](file:///workspaces/BWR_ASV/docs/asv_option_f_spec.md).

### 7.1 Physical Layout & Concept
* **Separated Outboard Pontoons**: Two 6-inch SDR-35 PVC pontoons (2.53m length) spaced **800mm center-to-center** (overall beam 1.0m). This true catamaran shape floats at a safe 50\% draft, keeping the overhanging 1.4m solar deck dry.
* **Swept-Back Metal Foil Spar**: The structural keel fin is replaced by a continuous, high-strength 8mm aluminum foil spar, swept back at a **45° angle** to naturally shed seaweed and lines.
* **Solid Lead Ballast Bulb**: Sinking a compact **15 kg solid lead bulb** (encapsulated in epoxy-fiberglass) to z = -450mm. The bulb contains **no electrical parts**, completely eliminating leak risks.
* **Deck-Mounted Power Vault**: The 35 kg LiFePO4 battery bank and all electronics are moved to dual IP67 deck-mounted enclosures, ensuring serviceability and absolute protection from seawater flooding.
* **Differential Propulsion**: Dual BlueRobotics T200 thrusters mounted at the stern of the outer hulls. Eliminates the mechanical rudder, servo, and boot. Provides full steering and thrust redundancy.

---

## 8. Comparison Matrix

| Design Parameter | Option A (Extruded PVC) | Option D (Keel-Stabilized) | Option E (Keel-Bulb SWATH) | Option F (Hydro-Stabilized Cat) | BWR Integrated Recommendation |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Hull Configuration** | Catamaran (Dual Hulls) | Catamaran (Triple-Tube) | SWATH Hybrid (Touching + Bulb) | **Catamaran (Separated + Bulb)** | **Catamaran (Dual Hulls)** |
| **Hull Material** | 8" Sch 40 PVC | 4" or 6" PVC (3 tubes) | 6" PVC (touching) + 140mm Bulb | **6" SDR-35 PVC + 100mm Lead Bulb** | **8" SDR-35 Sewer PVC** |
| **Overall Beam** | 1.6 m | 0.8 m–1.0 m | 1.0 m (Solar Deck 1.4 m) | **1.0 m (Solar Deck 1.4 m)** | **1.6 m (Option A)** / **1.2 m (Option B)** |
| **Total Hull Mass** | 63.3 kg | ~ 14.5 kg | ~ 11.5 kg | **~ 11.5 kg (plus 15kg lead)** | **19.2 kg** |
| **Stability Mode** | Wide Beam Stability | Weighted Ballast Keel | Submerged Keel Bulb Ballast | **Swept-Keel Ballast + Wide Beam** | Wide Beam Stability |
| **Self-Righting** | No | Yes (Self-Righting) | Yes (Self-Righting - High Arm) | **Yes (Self-Righting - Highly Safe)** | No |
| **Steering** | Differential | Single Motor + Rudder | Keel Thruster + Rudder | **Differential Steering (Rudderless)**| **Differential (Ceramic/Potted)** |
| **Build Location** | Garage / Workshop | Apartment / Workbench | Apartment / Workbench | **Apartment / Workbench** | Garage / Workshop |
| **Transport** | Trailer / Flatbed | Car Roof Rack / SUV | Car Roof Rack / SUV | **Car Roof Rack / SUV** | Trailer / Roof Rack |
| **Material Cost** | High (~ \200) | Low (~ \80–\120) | Low-Medium (~ \100–\140) | **Medium (~ \160–\200)**| Low-Medium (~ \100) |



