# Engineering Analysis: Minimal Solar Power Configurations

By replacing the Raspberry Pi 5 with the **Raspberry Pi Zero W v1.1**, the baseline edge compute load drops from **21.6W** to **~1.0W**. This massive power saving allows us to consider much smaller, lighter, and cheaper solar arrays. 

Below is the power breakdown for the three minimal solar configurations we can consider depending on the mission scope.

---

## 1. Power Consumption Baselines

*   **Avionics Core (Pi Zero W + sensors + GPS):** $1.0\text{ W} + 0.5\text{ W} = \mathbf{1.5\text{ W}}$
*   **MPPT Charge Controller Efficiency ($\eta$):** $95\%$
*   **Solar Harvest Coefficient (Flat Marine Deck):** $75\%$ (due to splash residue, panel angle, and temp degradation)
*   **Daylight Factor (Coastal US):** Average of $5.0$ Peak Sun Hours per day.

Daily solar energy production formula:
$$E_{harvest} = P_{solar} \times 5.0\text{ hours} \times 0.75 \times 0.95 \approx P_{solar} \times 3.56\text{ Wh/day per Watt of panel}$$

---

## 2. Minimal Solar Configurations

| Metric | Scenario A: Survival / Drift Mode | Scenario B: Local Prototype (1.0m) | Scenario C: Throttled Ocean Cruiser |
| :--- | :--- | :--- | :--- |
| **Objective** | Keep telemetry & GPS alive indefinitely (no propulsion) | Short lake runs, daytime cruising, overnight loitering | Complete the 650–700 NM ocean voyage at reduced speed |
| **Edge Avionics** | 1.5 W (Continuous) | 1.5 W (Continuous) | 1.5 W (Continuous) |
| **Propulsion Power**| 0 W | 15.0 W (Cruising) | 30.0 W (Continuous Cruising) |
| **Continuous Load**| **1.5 W** | **16.5 W** | **31.5 W** |
| **Daily energy load**| $36.0\text{ Wh/day}$ | $396.0\text{ Wh/day}$ | $756.0\text{ Wh/day}$ |
| **Calculated Solar Panel**| **$10.1\text{ W}$** | **$111.2\text{ W}$** | **$212.4\text{ W}$** |
| **Recommended Array**| **15W to 20W Panel** | **Single 100W Panel** | **Single 200W or Dual 100W Panels** |
| **Vessel Speed** | 0.0 Knots (Drifting) | 2.5 Knots (approx. 15W throttle) | 3.5 Knots (approx. 30W throttle) |

---

## 3. Detailed Scenario Breakdowns

### Scenario A: Survival / Drift Mode (15W – 20W Panel)
*   **Use Case:** Emergency backup or passive drifting research buoy.
*   **Hardware:** A small marine-grade 15W or 20W flexible panel (approx. $30\text{cm} \times 35\text{cm}$).
*   **Feasibility:** Extremely high. This array fits on almost any hull (even a tiny buoy) and guarantees that the GPS, IMU, Pi Zero, and LoRa Meshcore link run indefinitely. If propulsion fails, this system will transmit tracking signals for recovery.

### Scenario B: Local Prototype / 1.0m Option C (100W Panel)
*   **Use Case:** Calm-water testing, debugging waypoint algorithms, and local telemetry range checks.
*   **Hardware:** Single standard 100W flexible solar panel (approx. $100\text{cm} \times 50\text{cm}$).
*   **Feasibility:** Matches the footprint of the 1.0m Prototype (Option C). Under typical daylight conditions, a 100W panel generates about $356\text{ Wh/day}$. 
    *   *Energy balance:* Running a 15W cruising throttle consumes $396\text{ Wh/day}$. This leaves a minor deficit of $40\text{ Wh/day}$, which is easily buffered by a small 12V 20Ah battery bank (240 Wh), allowing multiple days of active lake trials.

### Scenario C: Throttled Ocean Cruiser (200W Array)
*   **Use Case:** The full 650–700 NM ocean voyage (Charleston to Tampa) on a scaled-down budget and deck size.
*   **Hardware:** Single 200W or dual 100W panels (approx. $1.0\text{ m}^2$ total deck footprint).
*   **Feasibility:** In the original Pi 5 design, we required at least a **576W solar array** (demanding a heavy 600W catamaran deck). 
    *   With the Pi Zero W, we can drop the continuous cruising propulsion to 30W (pushing a lightweight catamaran at ~3.5 knots). 
    *   The total daily load is $756\text{ Wh/day}$. A **200W solar array** will harvest $712\text{ Wh/day}$, bringing the vessel within a negligible $44\text{ Wh/day}$ deficit. This deficit can be managed by throttling propulsion down slightly during overcast hours.
