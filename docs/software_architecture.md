# Software Architecture & Control System Guide
## Project Blue-Water Rover (BWR) ASV
## Target Audience: Middle School Students to Senior Systems Engineers

Welcome to the control system guide for the Blue-Water Rover (BWR) Autonomous Surface Vehicle (ASV)! This guide explains how the software codebase in the [/src/](file:///workspaces/BWR_ASV/src/) folder works, which hardware runs which code, and how to set up and deploy the system.

---

## 1. High-Level Concept: The Robotics Analogy

To understand how our software works, we can compare the different code files to parts of a human body or an RC pilot:

| Code File | Robotic Part | Human Analogy | What it does |
| :--- | :--- | :--- | :--- |
| [main.py](file:///workspaces/BWR_ASV/src/main.py) | **The Brain** | Central Nervous System | Coordinates all components, decides between auto/manual modes, and serves the HUD dashboard. |
| [spektrum_rc.py](file:///workspaces/BWR_ASV/src/spektrum_rc.py) | **The Reflexes** | Listening for instructions | Listens to a human pilot holding a Spektrum remote control. |
| [navigation.py](file:///workspaces/BWR_ASV/src/navigation.py) | **The Map & Compass** | Inner Ear & Navigation sense | Reads NMEA GPS strings, figures out where the target is, and calculates how much to steer the rudder. |
| [perception.py](file:///workspaces/BWR_ASV/src/perception.py) | **The Eyes** | Depth Vision | Scans the water using an Intel RealSense D455 depth camera to see if any obstacles are in the way. |
| [drive_control.py](file:///workspaces/BWR_ASV/src/drive_control.py) | **The Muscles** | Hands on the steering wheel | Sends electrical Pulse Width Modulation (PWM) signals to push the motor and turn the rudder. |

---

## 2. Hardware-to-Software Deployment Map

The ASV splits its computational workload across four hardware components to ensure safety, speed, and energy efficiency.

```
+---------------------------------------------------------------------------------+
|                         HARDWARE SOFTWARE DEPLOYMENT MAP                        |
+---------------------------------------------------------------------------------+
| Device            | Operating System (OS)     | Code Files / Software Running   |
+-------------------+---------------------------+---------------------------------+
| Raspberry Pi 4 B  | Raspberry Pi OS Lite (64) | main.py, spektrum_rc.py,        |
|                   |                           | navigation.py, drive_control.py |
|                   |                           | (fallback), telemetry_handler.py|
+-------------------+---------------------------+---------------------------------+
| Jetson Orin Nano  | NVIDIA JetPack SDK        | perception.py                   |
|                   | (Ubuntu Linux 20.04/22.04)| Intel RealSense SDK (pyrealsense)|
+-------------------+---------------------------+---------------------------------+
| Pixhawk 6X        | NuttX RTOS (PX4/ArduPilot)| ArduPilot (ArduRover Firmware)  |
|                   |                           | EKF3 Att/Pos Estimation, Servo  |
+-------------------+---------------------------+---------------------------------+
| Arduino Nano      | Bare-Metal (No OS)        | watchdog.ino                    |
|                   |                           | (Watchdog & leak sensor loop)   |
+-------------------+---------------------------+---------------------------------+
```

---

## 3. Physical Inter-Connection Diagram

The following diagram illustrates how the computing boards, sensors, power lines, and actuators connect.

```
       +--------------------+
       |  Intel RealSense   |
       |    D455 Camera     |
       +---------+----------+
                 | (USB 3.0 Shielded)
                 v
       +--------------------+            (Gigabit Ethernet RJ45)           +--------------------+
       |  Jetson Orin Nano  |<============================================>|  Raspberry Pi 4 B  |
       |  (12V Power In)    |                                              |  (5V Power In)     |
       +---------+----------+                                              +------+---+---+--+--+
                 ^                                                                |   |   |  |  |
                 | (12V Switched Power Rail)                                      |   |   |  |  |
                 |                                                                |   |   |  |  | (5V Switched Rail)
        +--------+--------+                                  (I2C: SDA/SCL)       |   |   |  |  +------+
        | MOSFET Switches |<------------------------------------------------------+   |   |  |         |
        +--------+--------+                                  (Heartbeat GPIO)         |   |  |         |
                 ^                                                                    |   |  |         |
                 | (Gate Signals)                                                     |   |  |         |
       +---------+----------+                                                         |   |  |         |
       | Arduino Nano       |<--------------------------------------------------------+   |  |         |
       | (5V Awake 24/7)    |                                                             |  |         |
       +---+---+------------+                                                             |  |         |
           |   |                                                                          |  |         |
           |   +--------> SHT31 Humidity & Leak Probes                                    |  |         |
           +------------> 5V Relay -> Bilge Pump                                          |  |         |
                                                                                          |  |         |
       +--------------------+                         (MAVLink Serial / UART)             |  |         |
       | Pixhawk 6X         |<------------------------------------------------------------+  |         |
       | (5.3V via PM)      |                                                                |         |
       +---+---+------------+                                                                |         |
           |   |                                      (Spektrum Serial RX / GPIO 15)         |         |
           |   +--------> Dual H-RTK F9P GPS                                                 |         |
           |                                                                                 |         |
           +------------> PWM Main 1 -> Rudder Servo                                         |         |
           +------------> PWM Main 2 -> Drive Motor ESC                                      |         |
                                                                                             |         |
       +--------------------+                                                                |         |
       | Heltec V3 (LoRa)   |<---------------------------------------------------------------+         |
       +--------------------+                                                                          |
                                                                                                       |
       +--------------------+                                                                          |
       | RockBLOCK 9603     |<-------------------------------------------------------------------------+
       | (Iridium Satellite)|
       +--------------------+
```

---

## 4. Software Setup & Installation Instructions

This section outlines step-by-step instructions to configure each piece of hardware from scratch.

### 4.1 Raspberry Pi 4 B (The Systems Manager)
The Pi 4 coordinates communications and handles the main loop.

#### 1. OS Installation
1.  Download and open the **Raspberry Pi Imager** on a computer.
2.  Choose **Raspberry Pi OS Lite (64-bit)** (debian bookworm base, contains no graphical desktop interface to save RAM and power).
3.  Set host name to `bwr-pi` and enable **SSH** with a secure password or SSH key.
4.  Configure Wi-Fi details (for local yard testing) and flash the SD card.

#### 2. Serial & GPIO Configuration
Once booted, log into the Pi via SSH (`ssh pi@bwr-pi.local`) and execute:
1.  Run the config tool: `sudo raspi-config`.
2.  Navigate to **Interface Options** $\rightarrow$ **Serial Port**.
3.  Select **No** to *"Would you like a login shell to be accessible over serial?"* and **Yes** to *"Would you like the serial port hardware to be enabled?"*.
4.  Save and exit.
5.  Edit `/boot/firmware/config.txt` (or `/boot/config.txt`) to release UART0 for Spektrum serial:
    ```bash
    sudo nano /boot/firmware/config.txt
    # Append the following line to disable bluetooth overlays binding to UART
    dtoverlay=disable-bt
    ```
6.  Reboot the Pi: `sudo reboot`.

#### 3. Install Dependencies
```bash
# Update package list
sudo apt-get update && sudo apt-get upgrade -y

# Install Python package manager and Git
sudo apt-get install -y python3-pip python3-dev git pigpio python3-pigpio

# Start and enable the pigpio daemon (for hardware PWM)
sudo systemctl enable pigpiod
sudo systemctl start pigpiod

# Install python libraries
pip3 install pyserial flask pynmea2
```

#### 4. Auto-Start Service Configuration
To ensure the autopilot code starts automatically whenever the battery vault powers on:
1.  Create a systemd service file:
    ```bash
    sudo nano /etc/systemd/system/bwr_autopilot.service
    ```
2.  Paste the following configuration:
    ```ini
    [Unit]
    Description=Blue-Water Rover Autopilot Stack
    After=network.target pigpiod.service
    Requires=pigpiod.service

    [Service]
    ExecStart=/usr/bin/python3 /workspaces/BWR_ASV/src/main.py
    WorkingDirectory=/workspaces/BWR_ASV/src
    StandardOutput=inherit
    StandardError=inherit
    Restart=always
    User=root

    [Install]
    WantedBy=multi-user.target
    ```
3.  Enable and start the service:
    ```bash
    sudo systemctl daemon-reload
    sudo systemctl enable bwr_autopilot.service
    sudo systemctl start bwr_autopilot.service
    ```

---

### 4.2 Jetson Orin Nano (Perception Computer)
The Jetson processes depth images from the RealSense camera.

#### 1. OS Installation
1.  Download **NVIDIA JetPack 5.x / 6.x** matching the developer kit.
2.  Flash the JetPack OS image onto a fast NVMe SSD or SD card using NVIDIA SDK Manager or Balena Etcher.
3.  Complete the initial Ubuntu setup wizard, creating user `bwr-jetson`.

#### 2. Installing Intel RealSense SDK (librealsense)
Set up NVIDIA repositories and build/install the camera drivers:
```bash
# Register NVIDIA key and repo
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key F6E65AC044F831AC80A06380C8B3A55A6F88E2D9
sudo add-apt-repository "deb https://librealsense.intel.com/Debian/apt-repo $(lsb_release -cs) main" -u

# Install library
sudo apt-get install -y librealsense2-utils librealsense2-dev

# Install python bindings
pip3 install pyrealsense2 numpy opencv-python
```

#### 3. Running the Perception Script
Verify the RealSense camera works by running the python pipeline directly:
```bash
python3 /workspaces/BWR_ASV/src/perception.py
```

---

### 4.3 Pixhawk 6X (Autopilot)
The Pixhawk runs the low-level motor loops and coordinates the GPS.

#### 1. Firmware Flash
1.  Download and install **QGroundControl** on a ground station laptop.
2.  Connect the Pixhawk 6X to the laptop using a USB-C cable.
3.  Go to **Vehicle Setup** $\rightarrow$ **Firmware**.
4.  Select **ArduPilot** $\rightarrow$ **Rover** (ArduRover stable release) and click **OK** to flash.

#### 2. Parameter Tuning (via QGroundControl)
Once flashed, configure parameters to support the single motor + rudder layout:
*   `FRAME_CLASS` = `2` (Rover class).
*   `MOT_TYPE` = `0` (Normal steering and throttle outputs).
*   `SERVO1_FUNCTION` = `26` (Ground Steering - maps rudder PWM to Output port 1).
*   `SERVO3_FUNCTION` = `70` (Throttle - maps ESC PWM to Output port 3).
*   `SERIAL1_PROTOCOL` = `2` (MAVLink 2 - enables telemtry comms with Pi on TELEM1 port).
*   `SERIAL1_BAUD` = `115` (115200 baud).
*   `GPS_TYPE` = `2` (RTK GPS configuration on port GPS1).
*   `GPS_TYPE2` = `2` (Second GPS unit on GPS2 for GPS-for-yaw calculations).

---

### 4.4 Arduino Nano (Safety Monitor)
The Arduino stays powered on 24/7 to monitor safety metrics and power-cycle computers.

#### 1. Hardware Pin Mapping
*   **A0**: Leak Sensor Probe 1 (Avionics Box)
*   **A1**: Leak Sensor Probe 2 (Battery Box)
*   **Pin 2 (Input)**: Heartbeat signal from Pi 4 GPIO.
*   **Pin 4 (Output)**: MOSFET Gate 1 (controls Pi 4 power supply).
*   **Pin 5 (Output)**: MOSFET Gate 2 (controls Jetson power supply).
*   **Pin 6 (Output)**: Relay drive (controls Bilge Pump power line).

#### 2. Watchdog Firmware Setup
Write the following watchdog sketch to the Arduino Nano using the **Arduino IDE**:

```cpp
#include <Arduino.h>

const int PIN_HEARTBEAT = 2;
const int PIN_GATE_PI = 4;
const int PIN_GATE_JETSON = 5;
const int PIN_BILGE = 6;
const int PIN_LEAK_1 = A0;
const int PIN_LEAK_2 = A1;

unsigned long last_heartbeat_time = 0;
bool last_hb_state = false;

void setup() {
  pinMode(PIN_HEARTBEAT, INPUT);
  pinMode(PIN_GATE_PI, OUTPUT);
  pinMode(PIN_GATE_JETSON, OUTPUT);
  pinMode(PIN_BILGE, OUTPUT);
  
  // Power on computing boards by default
  digitalWrite(PIN_GATE_PI, HIGH);
  digitalWrite(PIN_GATE_JETSON, HIGH);
  digitalWrite(PIN_BILGE, LOW); // Keep bilge pump off
  
  last_heartbeat_time = millis();
}

void loop() {
  bool current_hb = digitalRead(PIN_HEARTBEAT);
  
  // Reset watchdog if heartbeat edge detected
  if (current_hb != last_hb_state) {
    last_heartbeat_time = millis();
    last_hb_state = current_hb;
  }
  
  // 1. Pi Watchdog: If Pi is frozen for > 45 seconds, cold reboot it
  if (millis() - last_heartbeat_time > 45000) {
    // Cut Pi power
    digitalWrite(PIN_GATE_PI, LOW);
    delay(5000);
    // Restore Pi power
    digitalWrite(PIN_GATE_PI, HIGH);
    last_heartbeat_time = millis();
  }
  
  // 2. Leak Detection
  int leak_val_1 = analogRead(PIN_LEAK_1);
  int leak_val_2 = analogRead(PIN_LEAK_2);
  
  // Analog threshold: raw water contact pulls values below 300
  if (leak_val_1 < 300 || leak_val_2 < 300) {
    // Leak detected! Start bilge pump
    digitalWrite(PIN_BILGE, HIGH);
  } else {
    // Dry condition, turn pump off
    digitalWrite(PIN_BILGE, LOW);
  }
  
  delay(100);
}
```
3.  In the Arduino IDE, select **Board: Arduino Nano** and click **Upload** to burn the watchdog loop.

---

## 5. How the Key Code Components Work

### 5.1 Reading the Remote Control: Serial Sync & Bit Shifting
**Middle School View**: The remote control transmitter sends wireless packets to a receiver on the boat. The receiver repeats these messages to our computer. Because characters can get jumbled in translation, the code waits for a "quiet moment" in the conversation (a time gap of 5 milliseconds) to know a new instruction package has begun.

**Senior Engineer View**: The Spektrum Satellite serial protocol operates at 115200 baud, sending 16-byte frames containing 7 proportional channels. Since UART is an asynchronous byte stream, aligning bytes requires a frame synchronization heuristic. The parser tracks byte arrival times; if `current_time - last_byte_time > 0.005` seconds, the buffer is flushed and the next byte is marked as byte 0.

Each channel is parsed as a 2-byte big-endian word:
```python
# Extract channel ID and 11-bit value from DSMX frame word
chan_id = (word >> 11) & 0x0F
value = word & 0x07FF  # values from 0 to 2047
```
If no valid frame arrives for 1.0 second, a connection watchdog triggers a safety fallback, centering the rudder and cutting throttle to neutral.

### 5.2 Autopilot Steering: PID Control
**Middle School View**: Imagine walking down a path toward a target flag. If a gust of wind blows you to the left, your brain senses the error and tells your legs to steer right. The closer you get, the less you need to correct. Our boat does this with a math formula called **PID (Proportional, Integral, Derivative) Control** to decide how much to turn the rudder:
*   **Proportional (P)**: Turn more if the heading error is large.
*   **Integral (I)**: Turn extra if wind or waves have been pushing us off-course for a long time.
*   **Derivative (D)**: Counter-steer to slow down the turn as we approach the correct direction, preventing the boat from zig-zagging.

**Senior Engineer View**: The navigation controller uses the Haversine formula to compute the distance $d$ and initial bearing $\theta_{bearing}$ between the boat $(Lat_1, Lon_1)$ and target waypoint $(Lat_2, Lon_2)$. The heading error is computed relative to the Course Over Ground (COG) and wrapped to $[-180, 180]$ degrees:
```python
heading_error = target_bearing - current_cog
heading_error = (heading_error + 180) % 360 - 180
```
The PID loop calculates the rudder correction:
$$u(t) = K_p \cdot e(t) + K_i \int e(t)dt + K_d \frac{de(t)}{dt}$$
*   **Anti-Windup**: The integral error sum is clamped to $[-30, 30]$ degrees to prevent integrator saturation during long turns.
*   **Output**: The final steering fraction $u(t)$ is clamped to $[-1.0, 1.0]$ representing full left/right rudder deflection.

### 5.3 Obstacle Avoidance: RealSense Proximity Grid
**Middle School View**: The Intel RealSense camera works like a bat's ears, but uses light instead of sound. It shines invisible infrared patterns and measures how long it takes for the patterns to bounce back. The code cuts this visual image into three vertical blocks: **Left**, **Center**, and **Right**. If an object appears closer than 8 meters, the autopilot swerves in the opposite direction.

**Senior Engineer View**: We stream depth buffers at a $640 \times 480$ resolution. To avoid water-surface glint (reflections) and sky noise, the scan checks only pixels in the vertical center band ($160 \le y \le 320$). The columns are partitioned into three sectors: Left $[0, 213]$, Center $[214, 426]$, and Right $[427, 639]$. 

If an obstacle is detected in the Center sector at a distance $D_{center} < D_{avoid}$:
*   Compare Left and Right sectors.
*   Apply steering offset offset toward the clearer side:
    $$\theta_{avoid} = \pm 0.8 \cdot \left(1.0 - \frac{D_{center}}{D_{avoid}}\right)$$
*   If the center obstacle distance drops below 4.0 meters, the drive controller triggers an emergency reverse throttle fraction ($-0.2$) to back off.

### 5.4 Motor Control: Pulse Width Modulation (PWM)
**Middle School View**: How do we tell an electric motor how fast to spin, or a rudder motor what angle to hold? We send them tiny pulses of electricity. A 1.5 millisecond pulse (1500 microseconds) means "stop" or "center". A longer pulse (2000 microseconds) means "full speed forward" or "turn right". A shorter pulse (1000 microseconds) means "full speed backward" or "turn left". Repeating this pulse 50 times every second is called Pulse Width Modulation.

**Senior Engineer View**: The Pi uses the `pigpio` library to generate hardware-timed PWM signals via the DMA (Direct Memory Access) controller. This bypasses Linux kernel execution scheduling jitter, preventing the rudder servo from vibrating or twitching. 
*   **Current Protection Slew Limit**: Sudden throttle changes from 0% to 100% can draw massive current spikes, potentially crashing the computers. The drive controller applies a rate-limit (slew rate) of $500\text{ us/second}$, forcing the throttle output to ramp up smoothly over 1.0 second.

---

## 6. The HUD Mission Control Web Dashboard

To monitor the boat in real-time, the system starts a Flask web server on port 5000:
1.  **Backend (Python)**: `main.py` hosts a JSON API `/api/telemetry` which aggregates variables from the RC, GPS, Navigation, and RealSense threads, and `/api/command` which accepts commands from the browser.
2.  **Frontend (HTML/CSS/JS)**: Accessing `http://<pi_ip>:5000/` loads the glassmorphic dark-mode HUD dashboard:
    *   **Circular gauges** render battery capacity and solar power levels.
    *   **Rotating needles** show heading and bearings.
    *   **Sonar indicators** glow red if obstacles approach.
    *   An **SVG projection** maps the coordinates of the boat onto the coastline map.
