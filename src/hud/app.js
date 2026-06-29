// Project Blue-Water Rover ASV - HUD Frontend Controller

document.addEventListener("DOMContentLoaded", () => {
  // Telemetry variables
  const TELEMETRY_INTERVAL = 250; // 4Hz refresh rate
  const circlePerimeter = 2 * Math.PI * 50; // Radius = 50, perimeter = 314.16

  // Projection boundary variables for Florida East-Coast Route SVG Map
  const MAP_BOUNDS = {
    minLat: 24.0,
    maxLat: 33.0,
    minLon: -83.2,
    maxLon: -79.5
  };

  // Route definitions for reference (static visualization)
  const staticRoute = [
    { lat: 32.776, lon: -79.931 }, // Charleston
    { lat: 31.500, lon: -80.800 },
    { lat: 30.330, lon: -81.200 },
    { lat: 29.900, lon: -81.100 },
    { lat: 29.200, lon: -80.800 },
    { lat: 28.400, lon: -80.300 }, // Cape Canaveral
    { lat: 28.000, lon: -80.400 },
    { lat: 27.500, lon: -80.100 },
    { lat: 26.700, lon: -79.800 },
    { lat: 25.700, lon: -79.900 }, // Miami
    { lat: 25.090, lon: -80.440 }, // Key Largo
    { lat: 24.720, lon: -81.040 },
    { lat: 24.550, lon: -81.780 }, // Key West
    { lat: 24.600, lon: -82.800 }, // Dry Tortugas
    { lat: 25.900, lon: -82.000 },
    { lat: 26.500, lon: -82.400 },
    { lat: 27.100, lon: -82.500 },
    { lat: 27.300, lon: -82.700 },
    { lat: 27.600, lon: -82.750 },
    { lat: 27.760, lon: -82.630 }  // Tampa Bay Finish
  ];

  // DOM Elements
  const modeVal = document.getElementById("mode-val");
  const modeBadge = document.getElementById("mode-badge");
  const tagGps = document.getElementById("tag-gps");
  const tagRc = document.getElementById("tag-rc");
  const tagLora = document.getElementById("tag-lora");
  
  // Power DOMs
  const ringBattery = document.getElementById("ring-battery");
  const ringNet = document.getElementById("ring-net");
  const valBattery = document.getElementById("val-battery");
  const valNet = document.getElementById("val-net");
  const valVolts = document.getElementById("val-volts");
  const valSolar = document.getElementById("val-solar");
  const valProp = document.getElementById("val-prop");
  const valSys = document.getElementById("val-sys");

  // Actuation PWM DOMs
  const barThrottle = document.getElementById("bar-throttle");
  const labelThrottlePwm = document.getElementById("label-throttle-pwm");
  const barRudder = document.getElementById("bar-rudder");
  const labelRudderPwm = document.getElementById("label-rudder-pwm");

  // Navigation DOMs
  const compassRose = document.getElementById("compass-rose-element");
  const bearingPointer = document.getElementById("bearing-pointer-element");
  const valHeading = document.getElementById("val-heading");
  const valBearing = document.getElementById("val-bearing");
  const valSog = document.getElementById("val-sog");
  const valWpDist = document.getElementById("val-wp-dist");
  const valWpQ = document.getElementById("val-wp-q");

  // Proximity Sensors
  const radarLeft = document.getElementById("radar-left");
  const radarCenter = document.getElementById("radar-center");
  const radarRight = document.getElementById("radar-right");
  const lblLeft = document.getElementById("radar-lbl-left");
  const lblCenter = document.getElementById("radar-lbl-center");
  const lblRight = document.getElementById("radar-lbl-right");

  // SVG Elements
  const svgMap = document.getElementById("svg-map");
  const routeTrack = document.getElementById("map-route-track");
  const wpsGroup = document.getElementById("map-waypoints-group");
  const boatPointer = document.getElementById("boat-pointer");
  const boatTrailDot = document.getElementById("boat-trail-dot");
  const boatGroup = document.getElementById("map-boat-group");

  // Buttons & Forms
  const btnKill = document.getElementById("btn-kill");
  const btnResetKill = document.getElementById("btn-reset-kill");
  const btnModeToggle = document.getElementById("btn-mode-toggle");
  const btnClearWps = document.getElementById("btn-clear-wps");
  const formWpInject = document.getElementById("wp-inject-form");
  const inputLat = document.getElementById("input-lat");
  const inputLon = document.getElementById("input-lon");
  const inputPacket = document.getElementById("input-packet");
  const btnInjectPacket = document.getElementById("btn-inject-packet");
  const terminalFeed = document.getElementById("terminal-feed");

  // Initial Progress stroke setups
  ringBattery.style.strokeDasharray = `${circlePerimeter} ${circlePerimeter}`;
  ringNet.style.strokeDasharray = `${circlePerimeter} ${circlePerimeter}`;

  // Log message tracking
  let lastLoggedMode = "";
  let lastLoggedKilled = false;

  // Initialize Map
  renderStaticMapGrid();

  // Primary Telemetry Poll Loop
  setInterval(pollTelemetry, TELEMETRY_INTERVAL);

  function pollTelemetry() {
    fetch("/api/telemetry")
      .then(response => response.json())
      .then(data => {
        updateAvionicsHUD(data);
      })
      .catch(error => {
        console.error("Telemetry fetch error:", error);
        addLogLine("SYSTEM ERROR: Lost connection to Autopilot API server", "error");
      });
  }

  function updateAvionicsHUD(data) {
    // 1. Mode Status
    const isAuto = data.mode === "AUTO";
    modeVal.textContent = data.mode;
    if (isAuto) {
      modeVal.className = "indicator-value auto-active";
      btnModeToggle.textContent = "Switch to Manual";
      btnModeToggle.className = "btn btn-secondary";
    } else {
      modeVal.className = "indicator-value";
      btnModeToggle.textContent = "Switch to Auto";
      btnModeToggle.className = "btn";
    }

    if (data.mode !== lastLoggedMode) {
      addLogLine(`SYSTEM STATE CHANGE: Mode set to ${data.mode}`, "system");
      lastLoggedMode = data.mode;
    }

    // Failsafe / Killed Banner Glow
    if (data.killed) {
      modeVal.textContent = "EMERGENCY KILLED";
      modeVal.className = "indicator-value error-text";
      btnKill.classList.add("btn-danger-flash");
      if (!lastLoggedKilled) {
        addLogLine("WARNING: Drive outputs locked in EMERGENCY SHUTDOWN state!", "error");
        lastLoggedKilled = true;
      }
    } else {
      btnKill.classList.remove("btn-danger-flash");
      lastLoggedKilled = false;
    }

    // 2. Hardware connection tags
    updateTag(tagGps, data.gps_connected);
    updateTag(tagRc, data.rc_connected);
    updateTag(tagLora, data.rc_connected || isAuto); // simulate network activity

    // 3. Power Dials
    valBattery.textContent = data.battery_pct.toFixed(1);
    const batOffset = circlePerimeter - (data.battery_pct / 100) * circlePerimeter;
    ringBattery.style.strokeDashoffset = batOffset;

    valNet.textContent = `${data.net_w > 0 ? '+' : ''}${Math.round(data.net_w)}`;
    // Scale Net Power -350W (empty) to +350W (full)
    const netNormalized = Math.max(0.0, Math.min(100.0, ((data.net_w + 350.0) / 700.0) * 100));
    const netOffset = circlePerimeter - (netNormalized / 100) * circlePerimeter;
    ringNet.style.strokeDashoffset = netOffset;

    valVolts.textContent = data.battery_v.toFixed(2);
    valSolar.textContent = data.solar_w.toFixed(1);
    valProp.textContent = data.prop_w.toFixed(1);
    valSys.textContent = data.sys_w.toFixed(1);

    // 4. Actuator PWM Bars
    // Throttle PWM values (1000us - 2000us, neutral 1500us)
    const throttlePercent = ((data.throttle_us - 1500.0) / 500.0) * 100;
    labelThrottlePwm.textContent = `${data.throttle_us} us`;
    if (throttlePercent >= 0) {
      barThrottle.style.width = `${throttlePercent}%`;
      barThrottle.style.left = "0%";
      barThrottle.style.backgroundColor = "var(--cyan-glow)";
    } else {
      // Reverse
      barThrottle.style.width = `${Math.abs(throttlePercent)}%`;
      barThrottle.style.left = "0%";
      barThrottle.style.backgroundColor = "var(--crimson-glow)";
    }

    // Rudder PWM values (1100us - 1900us, center 1500us)
    // Map center offset (from -400 to +400)
    const rudderOffsetPercent = ((data.rudder_us - 1500.0) / 400.0) * 50; // max +/- 50% from center
    labelRudderPwm.textContent = `${data.rudder_us} us`;
    if (rudderOffsetPercent >= 0) {
      barRudder.style.left = "50%";
      barRudder.style.width = `${rudderOffsetPercent}%`;
    } else {
      barRudder.style.left = `${50 + rudderOffsetPercent}%`;
      barRudder.style.width = `${Math.abs(rudderOffsetPercent)}%`;
    }

    // 5. Compass Cards
    compassRose.style.transform = `rotate(${-data.cog}deg)`;
    bearingPointer.style.transform = `rotate(${data.target_bearing - data.cog}deg)`;
    valHeading.textContent = `${Math.round(data.cog)}°`;
    valBearing.textContent = `${Math.round(data.target_bearing)}°`;

    // 6. RealSense D455 Obstacles
    updateRadarSector(radarLeft, lblLeft, data.closest_left);
    updateRadarSector(radarCenter, lblCenter, data.closest_center);
    updateRadarSector(radarRight, lblRight, data.closest_right);

    // 7. Navigation Text
    valSog.textContent = data.sog.toFixed(1);
    // Convert meters to NM: 1 NM = 1852 meters
    const distNM = data.distance_to_wp / 1852.0;
    valWpDist.textContent = data.distance_to_wp > 50000 ? "N/A" : `${distNM.toFixed(2)} NM`;
    valWpQ.textContent = data.queue_len;

    // 8. Move Vessel on Map
    if (data.gps_connected) {
      const boatPos = projectCoords(data.lat, data.lon);
      boatGroup.setAttribute("transform", `translate(${boatPos.x}, ${boatPos.y})`);
      boatPointer.style.transform = `rotate(${data.cog}deg)`;
      
      // Update waypoints on SVG
      if (data.queue_len > 0) {
        // Redraw route if queue exists
        // Simply simulate route tracks from current boat pos to remaining waypoints
        // Real-time waypoint updates would go here
      }
    }

    // 9. Fake downlink log entries to simulate a live console feed
    if (Math.random() < 0.08) {
      const formattedTime = new Date().toLocaleTimeString();
      const stateStr = isAuto ? "CRUISING" : "LOITERING";
      const throttleStr = data.throttle_us > 1510 ? "ACTIVE" : "OFF";
      const packetStr = `$TEL:DIAG,BAT=${data.battery_pct.toFixed(1)}%,SOL=${data.solar_w.toFixed(0)}W,PROP=${data.prop_w.toFixed(0)}W,LAT=${data.lat.toFixed(5)},LON=${data.lon.toFixed(5)},SPEED=${data.sog.toFixed(1)}KT,STATE=${stateStr},THROTTLE=${throttleStr},WP_Q=${data.queue_len}`;
      const checksum = calculateXorChecksum(packetStr.substring(1));
      addLogLine(`${packetStr}*${checksum}`, "downlink");
    }
  }

  function updateTag(tagElement, isActive) {
    if (isActive) {
      tagElement.classList.add("active");
    } else {
      tagElement.classList.remove("active");
    }
  }

  function updateRadarSector(sectorElement, labelElement, distance) {
    const sectorFill = sectorElement.querySelector(".sector-fill");
    
    // Distances capped at 20m. 20m = 0% fill. 2m = 90% fill.
    const fillPercent = Math.max(0, Math.min(100, (1.0 - (distance / 20.0)) * 100));
    sectorFill.style.height = `${fillPercent}%`;
    
    labelElement.textContent = distance >= 20.0 ? "Clear" : `${distance.toFixed(1)}m`;

    if (distance < 6.0) {
      sectorFill.style.background = "linear-gradient(to top, rgba(255, 23, 68, 0.4), rgba(255, 23, 68, 0.1))";
      labelElement.style.color = "var(--crimson-glow)";
    } else if (distance < 10.0) {
      sectorFill.style.background = "linear-gradient(to top, rgba(255, 179, 0, 0.3), rgba(255, 179, 0, 0.1))";
      labelElement.style.color = "var(--amber-glow)";
    } else {
      sectorFill.style.background = "linear-gradient(to top, rgba(0, 229, 255, 0.2), rgba(0, 229, 255, 0.05))";
      labelElement.style.color = "var(--text-primary)";
    }
  }

  // Lat/Lon Projector onto SVG (500x350 box)
  function projectCoords(lat, lon) {
    const latRange = MAP_BOUNDS.maxLat - MAP_BOUNDS.minLat;
    const lonRange = MAP_BOUNDS.maxLon - MAP_BOUNDS.minLon;
    
    // Map Lon to X (50 to 450)
    const x = 50 + ((lon - MAP_BOUNDS.minLon) / lonRange) * 400;
    // Map Lat to Y (300 to 50)
    const y = 300 - ((lat - MAP_BOUNDS.minLat) / latRange) * 250;
    
    return { x, y };
  }

  function renderStaticMapGrid() {
    // 1. Draw Static Route Points
    let trackPoints = [];
    wpsGroup.innerHTML = ""; // Clear existing

    staticRoute.forEach((pt, index) => {
      const pos = projectCoords(pt.lat, pt.lon);
      trackPoints.push(`${pos.x},${pos.y}`);

      // Draw circles for waypoints
      const circle = document.createElementNS("http://www.w3.org/2000/svg", "circle");
      circle.setAttribute("cx", pos.x);
      circle.setAttribute("cy", pos.y);
      circle.setAttribute("r", index === 0 || index === staticRoute.length - 1 ? 5 : 3);
      circle.setAttribute("fill", index === 0 ? "#00e676" : (index === staticRoute.length - 1 ? "#ff1744" : "rgba(255, 255, 255, 0.3)"));
      circle.setAttribute("stroke", "rgba(255,255,255,0.1)");
      circle.setAttribute("stroke-width", "1");
      wpsGroup.appendChild(circle);
    });

    // Populate route polyline
    routeTrack.setAttribute("points", trackPoints.join(" "));
  }

  // Command POST Handlers
  btnKill.addEventListener("click", () => {
    sendCommand("KILL");
  });

  btnResetKill.addEventListener("click", () => {
    sendCommand("RESET_KILL");
  });

  btnModeToggle.addEventListener("click", () => {
    // Read current mode and toggle
    const currentMode = modeVal.textContent.trim();
    const nextMode = currentMode === "AUTO" ? "MANUAL" : "AUTO";
    sendCommand(nextMode);
  });

  btnClearWps.addEventListener("click", () => {
    sendCommand("CLEAR_WP");
  });

  formWpInject.addEventListener("submit", (e) => {
    e.preventDefault();
    const lat = parseFloat(inputLat.value);
    const lon = parseFloat(inputLon.value);
    
    fetch("/api/command", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ command: "ADD_WP", lat, lon, index: Math.floor(Math.random() * 90) + 10 })
    })
      .then(res => res.json())
      .then(resData => {
        if (resData.status === "accepted") {
          addLogLine(`UPLINK COMMAND SENT: ADD_WP at Lat ${lat}, Lon ${lon}`, "uplink");
          inputLat.value = "";
          inputLon.value = "";
        }
      });
  });

  btnInjectPacket.addEventListener("click", () => {
    const rawPacket = inputPacket.value.trim();
    if (!rawPacket) return;

    addLogLine(`CONSOLE INJECTED: ${rawPacket}`, "uplink");
    
    // Parse discrete packet command prefix locally for simulator feed
    if (rawPacket.startsWith("$")) {
      const asterIdx = rawPacket.indexOf("*");
      const payload = asterIdx !== -1 ? rawPacket.substring(1, asterIdx) : rawPacket.substring(1);
      const parts = payload.split(",");
      const cmd = parts[0];

      if (cmd === "NAV:KILL") {
        sendCommand("KILL");
      } else if (cmd === "NAV:HOLD") {
        sendCommand("MANUAL");
      } else if (cmd === "NAV:WP") {
        const lat = parseFloat(parts[2]);
        const lon = parseFloat(parts[3]);
        const index = parseInt(parts[1]);
        fetch("/api/command", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ command: "ADD_WP", lat, lon, index })
        });
      }
    }
    inputPacket.value = "";
  });

  function sendCommand(cmdStr) {
    fetch("/api/command", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ command: cmdStr })
    })
      .then(res => res.json())
      .then(data => {
        if (data.status === "accepted") {
          addLogLine(`UPLINK COMMAND SENT: ${cmdStr}`, "uplink");
        } else {
          addLogLine(`ERROR: Command Rejected: ${data.message || ""}`, "error");
        }
      })
      .catch(err => {
        addLogLine("ERROR: Command Transmit Fail", "error");
      });
  }

  function addLogLine(text, type = "system") {
    const line = document.createElement("div");
    line.className = `terminal-line ${type}-line`;
    const stamp = new Date().toLocaleTimeString();
    line.textContent = `[${stamp}] ${text}`;
    
    terminalFeed.appendChild(line);
    
    // Clamp to 50 lines max
    while (terminalFeed.children.length > 50) {
      terminalFeed.removeChild(terminalFeed.firstChild);
    }
    
    // Scroll to bottom
    terminalFeed.scrollTop = terminalFeed.scrollHeight;
  }

  function calculateXorChecksum(payload) {
    let xor = 0;
    for (let i = 0; i < payload.length; i++) {
      xor ^= payload.charCodeAt(i);
    }
    let hex = xor.toString(16).toUpperCase();
    return hex.length === 1 ? '0' + hex : hex;
  }
});
