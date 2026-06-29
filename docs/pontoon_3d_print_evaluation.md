# Engineering Evaluation: 3D Printing Catamaran Pontoons for Option A

This report evaluates the feasibility of 3D printing the dual 2.53m (219.1mm OD) pontoon hulls for the Option A Autonomous Surface Vehicle (ASV), comparing it to the baseline off-the-shelf Schedule 40 PVC pipe solution.

---

## 1. Executive Summary

While **Schedule 40 PVC** provides unmatched impact durability and structural strength, its extreme weight (12.5 kg/m for 8" pipe) introduces a severe displacement deficit, causing the vessel to float with a >75\% draft. 

**3D printing the pontoons** using **ASA (Acrylic Styrene Acrylonitrile)** is a structurally viable alternative that saves over **50 kg of deadweight** and enables safety features like internal watertight bulkheads. However, it requires printing the hull in 10–12 modular segments, reinforcing them with an internal tension rod, and coating them in marine epoxy to ensure watertightness.

### Recommendation
* **Preferred Path**: Utilize thin-walled **SDR-35 PVC / Sewer Pipe** (3.8 kg/m) or rotomolded HDPE pontoons first. They offer the weight-saving benefits of 3D printing without the high labor, seam-weakness, and porosity risks.
* **If 3D Printing is Chosen**: Print modular segments using **ASA** with a minimum of 4 perimeters, join them with an internal carbon fiber structural spar in tension, and seal the entire hull inside and out with marine-grade epoxy (e.g., West System 105/205).

---

## 2. Engineering Comparison Table

| Metric | Schedule 40 PVC (8" Pipe) | 3D Printed Modular Hulls (ASA) | Alternative: Thin-Walled SDR-35 PVC |
| :--- | :--- | :--- | :--- |
| **Material Weight** | 12.5 kg/m (Very Heavy) | ~ 2.0 kg/m (Very Light) | 3.8 kg/m (Light) |
| **Total Hull Weight (Pair)** | ~ 63.3 kg | ~ 10.1 kg | ~ 19.2 kg |
| **Reserve Buoyancy (190kg Max)** | 27\% (High risk of deck wash) | **49\% (Optimal draft)** | 44\% (Good draft) |
| **Structural Integrity** | Indestructible (Continuous extruded) | Moderate-Low (Prone to seam shear) | High (Continuous extruded) |
| **Watertightness** | 100\% (Non-porous) | Porous (Requires epoxy sealing) | 100\% (Non-porous) |
| **Internal Safety** | Single chamber (Single leak sinks hull) | **Multi-bulkhead (Fail-safe)** | Single chamber |
| **Fabrication Time** | <2 hours (Simple cuts) | >300 print hours | <2 hours |
| **Material Cost** | ~ \150–\200 | ~ \250 (Filament) +  \80 (Epoxy)| ~ \60–\100 |

---

## 3. Detailed Engineering Analysis

### 3.1 Weight & Hydrodynamic Displacement
*   **The Schedule 40 Bottleneck**: 8" Schedule 40 PVC is rated for high pressure and has a massive 8.18mm wall thickness. A pair of 2.53m hulls weighs 63.3kg. Combined with the 85kg dry payload (batteries, frame, solar panels), the total ASV weight becomes 148.3kg. Against a total displaced volume of 190.8L (buoyancy limit), the boat sits at a **77\% draft**. Waves will constantly wash over the deck, reducing MPPT solar efficiency due to splash residue and increasing drag.
*   **3D Printed Advantage**: By utilizing a 3mm shell thickness and internal gyroid infill (10–15\%), a 3D-printed pontoon weighs just ~ 5kg per side (10.1kg total). The ASV's total weight drops to 95.1kg, yielding a **50\% draft**—the optimal hydrodynamic waterline for a catamaran.

### 3.2 Material Selection for Marine 3D Printing
*   > [!WARNING]
    > **PLA is Unacceptable**: PLA has low UV resistance, absorbs water, and has a low glass transition temperature (60°C). Direct summer sunlight in Florida can easily heat dark or even white hulls past this point, causing catastrophic sagging and warping.
*   **PETG**: Good UV resistance and chemically inert. However, it can creep under continuous load (such as the clamping force of the frame brackets) and is difficult to glue.
*   **ASA (Acrylic Styrene Acrylonitrile) - Recommended**: ASA is highly UV-resistant, has excellent impact strength, handles higher temperatures (95°C glass transition), and can be solvent-welded using acetone. It is the gold-standard filament for structural brackets and exterior components.
*   **Nylon (Polyamide) - Conditional**: Extremely tough and impact-resistant, making it ideal for structural parts like the magnetic coupling pressure barrier or motor collars. 
    *   *Moisture Absorption Trap*: Standard **PA6 (Nylon 6)** absorbs up to 8–9\% water, causing severe swelling (2–3\%) and warping when submerged. This will distort O-ring grooves and close critical clearances (like the 0.5 mm magnetic coupling gap).
    *   *Recommended Grade*: Use **PA12 (Nylon 12)** or **PA12-CF (Carbon-Fiber Filled Nylon)**, which has a low moisture absorption rate (~ 1.5\% at saturation) and high dimensional stability.

### 3.3 Manufacturing Constraints (Seams & Watertightness)
1.  **Modular Assembly**: A 2.53m hull exceeds the build envelope of standard 3D printers. The hulls must be sliced into 10–12 modular segments of ~ 220mm length.
2.  **Porosity & Delamination**: FDM prints have micro-voids between layers. Over a 700 NM voyage (7–10 days of continuous submersion), hydrostatic pressure will force water through these micro-voids, slowly waterlogging the hulls.
3.  **Post-Processing & Watertight Sealing**: All submerged 3D-printed parts (hulls, motor pods, pressure caps) require post-print sealing. 
    *   *Epoxy Coating*: Coat the inner and outer surfaces with a low-viscosity marine-grade epoxy (e.g., West System 105/205 or XTC-3D) to fill the gaps between layers.
    *   *Infill and Wall Settings*: Parts requiring watertight seals should be printed with **100% infill** and high perimeter settings (4-5 walls).
    *   *Sealing Face Preparation*: Gland seats and O-ring contact faces must be sanded smooth (400–800 grit) or lathe-machined before applying the thin epoxy sealing coat to ensure a reliable seal.

### 3.4 Joint Reinforcement Strategy
Standard flat butt-joints glued together will fail under the cyclic bending and torsional moments caused by ocean wave action. If 3D printing, you must implement:
*   **Interlocking Joints**: Slices must use matching tongue-and-groove or male/female alignment collars.
*   **Tension Spars**: Run a central carbon-fiber tube (25mm diameter) or a stainless steel threaded rod along the length of each hull's centerline. Tensioning the end-caps onto this central rod squeezes the printed segments together in compression, ensuring wave bending forces are carried by the spar rather than the printed plastic seams.

```
       [Dome Cap] === [Segment 1] === [Segment 2] === [Dome Cap]
           ||============================================||
                    (Internal Tension Rod / Spar)
```

*   **Integrated Bulkheads**: The main advantage of 3D printing is the ability to print solid partition walls inside the model. Slicing the hull into 5 separate watertight bulkheads ensures that a single hull puncture only floods 20\% of the hull volume, preventing a total capsize.

### 3.5 Post-Machining (Turning) of 3D-Printed Parts
FDM parts printed in Nylon 12 (PA12) or Carbon-Fiber Nylon (PA12-CF) can be post-machined on a lathe to achieve high-precision clearances for O-ring grooves and bearing seats, provided the following parameters are maintained:
*   **Solid Stock Prep**: The area to be machined **must be printed with 100% solid infill** and a high wall perimeter count. If the cutting tool encounters a hollow infill cavity, the part will instantly tear and fail.
*   **Heat Management & Tooling**: Plastics have low melting points (PA12 melts at ~ 178°C). To prevent melting:
    *   Use **extremely sharp cutting tools** with high positive rake angles (HSS or highly polished carbide inserts designed for aluminum). Avoid dull tools or steel inserts.
    *   Set moderate spindle speeds (500–1000 RPM) but a **high feed rate** with a continuous, relatively deep cut. Scraping or taking too shallow of a cut will generate friction heat and gum up the tool.
    *   Apply compressed air or liquid coolant constantly to carry chips away.
*   **Layer Alignment & Shear Stress**: Printed parts are weaker along inter-layer seams. Minimize shear loads by taking light finishing passes (<= 0.2 mm depth of cut) and, if possible, orienting the print layers perpendicular to the lathe spindle axis.
*   **Abrasive Fillers (Carbon Fiber)**: If turning PA12-CF, standard HSS tools will dull in seconds. You **must use carbide tools** (or PCD diamond). Wear a respirator and use dust containment, as composite dust is a severe inhalation hazard.

---

## 4. Final Recommendation Summary

3D printing the hulls is **feasible but labor-intensive**. If you have the print capacity and workspace to handle epoxy coating, printing in **ASA** with a central tension spar offers the best buoyancy-to-weight ratio. 

However, from a reliability and engineering simplicity standpoint, switching to **SDR-35 PVC pipe** (commonly used for gravity sewer systems) is the superior compromise. It features a thin 6.1mm wall, weighs only 3.8 kg/m, is completely watertight, requires zero prints/seams, and maintains high impact resistance at a lower cost.

> [!CAUTION]
> **SDR-35 vs. Schedule 40 Sizing Trap**: When purchasing SDR-35 pipe, note that its outer diameter is **8.400 in (213.4 mm)**, whereas standard 8" Schedule 40 PVC has an OD of **8.625 in (219.1 mm)**. Standard Schedule 40 end caps will not fit SDR-35. Custom 3D-printed dome caps with a 213.4 mm ID must be fabricated, and all bracket/collar diameters in the OpenSCAD files must be scaled to `pvc_od = 213.4` to prevent clamping play.
