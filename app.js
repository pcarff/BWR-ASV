// Project Blue-Water Rover ASV Dashboard Simulator Logic

// --- ROUTE DEFINITIONS (Charleston to Tampa Bay around FL Keys) ---
const routePoints = [
  { name: "Charleston Start", lat: 32.776, lon: -79.931 },
  { name: "Off Georgia Coast", lat: 31.500, lon: -80.800 },
  { name: "Off Jacksonville", lat: 30.330, lon: -81.200 },
  { name: "Off St. Augustine", lat: 29.900, lon: -81.100 },
  { name: "Off Daytona", lat: 29.200, lon: -80.800 },
  { name: "Off Cape Canaveral", lat: 28.400, lon: -80.300 },
  { name: "Off Melbourne", lat: 28.000, lon: -80.400 },
  { name: "Off Fort Pierce", lat: 27.500, lon: -80.100 },
  { name: "Off West Palm", lat: 26.700, lon: -79.800 },
  { name: "Off Miami", lat: 25.700, lon: -79.900 },
  { name: "Key Largo", lat: 25.090, lon: -80.440 },
  { name: "Marathon", lat: 24.720, lon: -81.040 },
  { name: "Key West", lat: 24.550, lon: -81.780 },
  { name: "Dry Tortugas", lat: 24.600, lon: -82.800 },
  { name: "Off Marco Island", lat: 25.900, lon: -82.000 },
  { name: "Off Fort Myers", lat: 26.500, lon: -82.400 },
  { name: "Off Venice", lat: 27.100, lon: -82.500 },
  { name: "Off Sarasota", lat: 27.300, lon: -82.700 },
  { name: "Tampa Entrance", lat: 27.600, lon: -82.750 },
  { name: "Tampa Bay Finish", lat: 27.760, lon: -82.630 }
];

// --- MESHCORE REPEATER STATIONS (Onshore network nodes) ---
const repeaters = [
  { name: "SC-CHAS-01", lat: 32.776, lon: -79.931, hops: 1 },
  { name: "GA-SAV-01", lat: 32.080, lon: -81.090, hops: 2 },
  { name: "FL-JAX-01", lat: 30.330, lon: -81.650, hops: 3 },
  { name: "FL-AUG-01", lat: 29.890, lon: -81.310, hops: 4 },
  { name: "FL-DAY-01", lat: 29.210, lon: -81.020, hops: 5 },
  { name: "FL-CAPE-01", lat: 28.390, lon: -80.600, hops: 6 },
  { name: "FL-VERO-01", lat: 27.640, lon: -80.390, hops: 7 },
  { name: "FL-WPB-01", lat: 26.710, lon: -80.050, hops: 8 },
  { name: "FL-MIA-01", lat: 25.760, lon: -80.190, hops: 9 },
  { name: "FL-LARGO-01", lat: 25.090, lon: -80.440, hops: 10 },
  { name: "FL-KEYW-01", lat: 24.550, lon: -81.780, hops: 11 },
  { name: "FL-FTM-01", lat: 26.640, lon: -81.870, hops: 12 },
  { name: "FL-VEN-01", lat: 27.100, lon: -82.450, hops: 13 },
  { name: "FL-STPE-01", lat: 27.770, lon: -82.640, hops: 14 },
  { name: "FL-TAMP-01", lat: 27.950, lon: -82.450, hops: 15 }
];

// Coastline coordinates to draw land on SVG map
const landPoints = [
  { lat: 33.5, lon: -83.5 },
  { lat: 32.0, lon: -83.5 },
  { lat: 30.5, lon: -83.5 },
  { lat: 30.1, lon: -83.5 },
  { lat: 29.1, lon: -83.0 },
  { lat: 28.2, lon: -82.8 },
  { lat: 27.9, lon: -82.8 },
  { lat: 27.7, lon: -82.5 },
  { lat: 26.6, lon: -82.2 },
  { lat: 25.1, lon: -81.1 },
  { lat: 25.1, lon: -80.4 },
  { lat: 25.8, lon: -80.1 },
  { lat: 26.7, lon: -80.0 },
  { lat: 28.4, lon: -80.5 },
  { lat: 30.4, lon: -81.4 },
  { lat: 32.0, lon: -80.8 },
  { lat: 32.78, lon: -79.8 },
  { lat: 33.5, lon: -79.0 }
];

// --- SIMULATION INITIAL STATE ---
let state = {
  simTime: new Date("2026-06-23T16:42:38"),
  simSpeed: 5, // default accelerated
  weather: "sunny",
  isThrottling: true,
  isKilled: false,
  isHolding: false,
  boatLat: routePoints[0].lat,
  boatLon: routePoints[0].lon,
  boatSpeed: 5.0, // knots
  boatHeading: 180, // degrees
  batteryPercent: 82.5,
  batteryWh: 0, // dynamic
  netPower: 10.0,
  solarHarvest: 100.0,
  propulsionPower: 60.0,
  systemPower: 30.0,
  routeIndex: 0,
  routeSubIndex: 0.0,
  waypointsQueue: [], // custom NAV:WP
  history: [], // real-time chart tracking
  isBlackout: false,
  hullType: "monohull",
  propulsionType: "diff_thruster",
  solarW: 400,
  batteryAh: 115,
  computeType: "mcu",
  options: {
    satellite: false,
    ais: false,
    vision: false,
    lidar: false,
    solarExpanded: false
  },
  powerHookActive: true,
  lastPowerHookStatus: true,
  lastTelemetryMode: "lora", // lora, satellite, or offline
  avoidanceHeadingOffset: 0,
  loggedObstacles: {},
  loggedAisShips: {},
  aisShips: [
    { name: "CARRIER-ALFA", lat: 31.0, lon: -80.5, speed: 14, heading: 335, latStart: 31.0, lonStart: -80.5 },
    { name: "TANKER-BETA", lat: 26.2, lon: -79.7, speed: 10, heading: 185, latStart: 27.5, lonStart: -79.6 },
    { name: "TUG-GOLIATH", lat: 27.3, lon: -82.8, speed: 7, heading: 345, latStart: 26.8, lonStart: -82.6 }
  ]
};

// Static obstacles along the coastline (Option C / COLREGs)
const staticObstacles = [
  { id: "OB-01", name: "Debris Log", lat: 30.500, lon: -81.000 },
  { id: "OB-02", name: "Spotted Buoy", lat: 27.900, lon: -80.000 },
  { id: "OB-03", name: "Displaced Marker", lat: 27.200, lon: -82.500 }
];

// Interpolated dense path for smooth cruising
let densePath = [];

// --- MAP COORDINATE CONVERSION ---
const MAP_WIDTH = 600;
const MAP_HEIGHT = 800;
const LAT_MAX = 33.5;
const LAT_MIN = 24.0;
const LON_MAX = -79.0;
const LON_MIN = -83.5;

function gpsToSvg(lat, lon) {
  const x = ((lon - LON_MIN) / (LON_MAX - LON_MIN)) * MAP_WIDTH;
  const y = ((LAT_MAX - lat) / (LAT_MAX - LAT_MIN)) * MAP_HEIGHT;
  return { x, y };
}

function svgToGps(x, y) {
  const lon = LON_MIN + (x / MAP_WIDTH) * (LON_MAX - LON_MIN);
  const lat = LAT_MAX - (y / MAP_HEIGHT) * (LAT_MAX - LAT_MIN);
  return { lat, lon };
}

// Compute distance in nautical miles (approximate Haversine or simple)
function getDistanceNM(lat1, lon1, lat2, lon2) {
  const R = 3440.065; // Earth radius in NM
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// Generate smooth path
function generateDensePath() {
  densePath = [];
  for (let i = 0; i < routePoints.length - 1; i++) {
    const start = routePoints[i];
    const end = routePoints[i + 1];
    const dist = getDistanceNM(start.lat, start.lon, end.lat, end.lon);
    // 1 point per 0.5 NM
    const steps = Math.max(10, Math.floor(dist * 2));
    for (let j = 0; j < steps; j++) {
      const t = j / steps;
      densePath.push({
        lat: start.lat + (end.lat - start.lat) * t,
        lon: start.lon + (end.lon - start.lon) * t,
        targetName: end.name
      });
    }
  }
  densePath.push(routePoints[routePoints.length - 1]);
}

// --- TELEMETRY LOG LOGGER ---
function logConsole(message, type = "system") {
  const terminal = document.getElementById("console-terminal-log");
  if (!terminal) return;
  const timeStr = state.simTime.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });
  const entry = document.createElement("div");
  entry.className = `log-entry ${type}`;
  entry.innerText = `[${timeStr}] ${message}`;
  terminal.appendChild(entry);
  terminal.scrollTop = terminal.scrollHeight;
}

// --- INITIALIZE THE APPLICATION ---
window.onload = function () {
  generateDensePath();
  
  // Set up inputs from HTML
  document.getElementById("weather-select").value = state.weather;
  document.getElementById("sim-speed-select").value = state.simSpeed;
  document.getElementById("throttle-toggle").checked = state.isThrottling;
  
  // Set up initial state values based on default UI selections
  state.hullType = "monohull";
  state.propulsionType = "diff_thruster";
  state.solarW = 400;
  state.batteryAh = 115;
  state.computeType = "mcu";
  
  // Initialize battery Watt-hours
  const batteryMaxWh = state.batteryAh * 48;
  state.batteryWh = batteryMaxWh * (state.batteryPercent / 100);

  // Reset checkboxes to default on load
  document.getElementById("opt-satellite").checked = false;
  document.getElementById("opt-ais").checked = false;
  
  // Reset other state options
  state.options.satellite = false;
  state.options.ais = false;
  state.options.vision = false;
  state.options.lidar = false;

  // Set up SVG paths & visual layers
  setupMapGraphics();
  updateObstaclesGraphics();
  updateAisShipsGraphics();
  
  // Attach event handlers
  attachEventHandlers();
  
  // Sizing gap analysis & stats update
  updatePhysicalStats();
  runGapAnalysis();
  
  logConsole("MISSION SYSTEM ONLINE. MESHCORE TELEMETRY CONNECTED.", "system");
  logConsole("VESSEL BOOTED. EDGE AUTOPILOT WAITING FOR MISSION STATE.", "system");
  logConsole("CURRENT BASES: 48V 115Ah Battery Bank | 400W Solar Panel Array.", "system");
  
  // Start simulation loop (runs 5 times a second)
  setInterval(simulationStep, 200);
};

// --- SET UP STATIC & DENSE SVG MAP GRAPHICS ---
function setupMapGraphics() {
  const landPath = document.getElementById("landmass-coast");
  const routePath = document.getElementById("route-path");
  
  // 1. Draw Landmass
  let landD = `M ${gpsToSvg(33.5, -83.5).x} 0`;
  landPoints.forEach(p => {
    const pt = gpsToSvg(p.lat, p.lon);
    landD += ` L ${pt.x} ${pt.y}`;
  });
  // Close polygon via top-right
  landD += ` L ${gpsToSvg(33.5, -79.0).x} 0 Z`;
  landPath.setAttribute("d", landD);
  
  // 2. Draw Original Planned Route
  let routeD = `M ${gpsToSvg(routePoints[0].lat, routePoints[0].lon).x} ${gpsToSvg(routePoints[0].lat, routePoints[0].lon).y}`;
  routePoints.forEach(p => {
    const pt = gpsToSvg(p.lat, p.lon);
    routeD += ` L ${pt.x} ${pt.y}`;
  });
  routePath.setAttribute("d", routeD);
  
  // 3. Draw Onshore Repeaters
  const repeatersGroup = document.getElementById("repeaters-group");
  const linksGroup = document.getElementById("repeater-links-group");
  repeatersGroup.innerHTML = "";
  linksGroup.innerHTML = "";
  
  repeaters.forEach((rep, index) => {
    const pt = gpsToSvg(rep.lat, rep.lon);
    
    // Draw repeater circles
    const circle = document.createElementNS("http://www.w3.org/2000/svg", "circle");
    circle.setAttribute("cx", pt.x);
    circle.setAttribute("cy", pt.y);
    circle.setAttribute("r", index === 0 ? "5" : "3.5"); // Charleston is larger (hub)
    circle.setAttribute("fill", index === 0 ? "var(--color-purple)" : "var(--color-cyan)");
    circle.setAttribute("class", "repeater-node");
    circle.setAttribute("id", `node-${rep.name}`);
    
    const title = document.createElementNS("http://www.w3.org/2000/svg", "title");
    title.textContent = `${rep.name} (Hop Count: ${rep.hops})`;
    circle.appendChild(title);
    
    repeatersGroup.appendChild(circle);

    // Draw link line back to previous repeater (to show onshore mesh network backbone)
    if (index > 0) {
      const prevPt = gpsToSvg(repeaters[index - 1].lat, repeaters[index - 1].lon);
      const line = document.createElementNS("http://www.w3.org/2000/svg", "line");
      line.setAttribute("x1", prevPt.x);
      line.setAttribute("y1", prevPt.y);
      line.setAttribute("x2", pt.x);
      line.setAttribute("y2", pt.y);
      line.setAttribute("stroke", "rgba(0, 240, 255, 0.08)");
      line.setAttribute("stroke-width", "1");
      linksGroup.appendChild(line);
    }
  });

  // 4. Draw Florida Keys islands separately
  const keysPoints = [
    { lat: 25.0, lon: -80.5 },
    { lat: 24.9, lon: -80.6 },
    { lat: 24.8, lon: -80.8 },
    { lat: 24.7, lon: -81.1 },
    { lat: 24.6, lon: -81.3 },
    { lat: 24.57, lon: -81.5 },
    { lat: 24.55, lon: -81.8 }
  ];
  keysPoints.forEach(p => {
    const pt = gpsToSvg(p.lat, p.lon);
    const circle = document.createElementNS("http://www.w3.org/2000/svg", "circle");
    circle.setAttribute("cx", pt.x);
    circle.setAttribute("cy", pt.y);
    circle.setAttribute("r", "2");
    circle.setAttribute("fill", "#0c1221");
    circle.setAttribute("stroke", "#162440");
    circle.setAttribute("stroke-width", "1");
    repeatersGroup.appendChild(circle);
  });
}

// --- ATTACH EVENT HANDLERS ---
function attachEventHandlers() {
  document.getElementById("weather-select").onchange = function (e) {
    state.weather = e.target.value;
    logConsole(`WEATHER CHANGED TO: ${state.weather.toUpperCase()}`, "system");
  };

  document.getElementById("sim-speed-select").onchange = function (e) {
    state.simSpeed = parseInt(e.target.value);
    logConsole(`SIMULATION SPEED SET TO: ${state.simSpeed}x`, "system");
  };

  document.getElementById("throttle-toggle").onchange = function (e) {
    state.isThrottling = e.target.checked;
    logConsole(`PROPULSION THROTTLING ${state.isThrottling ? "ENABLED" : "DISABLED"}`, "system");
  };

  // Tab Switching Navigation
  const tabs = [
    { buttonId: "tab-design", contentId: "design-studio-tab" },
    { buttonId: "tab-telemetry", contentId: "telemetry-actions-tab" },
    { buttonId: "tab-math", contentId: "math-verify-tab" }
  ];
  
  tabs.forEach(tab => {
    document.getElementById(tab.buttonId).onclick = function () {
      tabs.forEach(t => {
        document.getElementById(t.buttonId).classList.remove("active");
        document.getElementById(t.contentId).style.display = "none";
      });
      document.getElementById(tab.buttonId).classList.add("active");
      document.getElementById(tab.contentId).style.display = "flex";
      
      if (tab.contentId === "telemetry-actions-tab") {
        setTimeout(drawHistoryChart, 50);
      }
    };
  });

  // Design Tab: Hull Selection
  const hullRadios = document.getElementsByName("design-hull");
  hullRadios.forEach(radio => {
    radio.onchange = function (e) {
      if (e.target.checked) {
        state.hullType = e.target.value;
        logConsole(`DESIGN: Hull structure set to ${state.hullType.toUpperCase()}`, "system");
        updatePhysicalStats();
        runGapAnalysis();
      }
    };
  });

  // Design Tab: Propulsion Selection
  document.getElementById("design-propulsion").onchange = function (e) {
    state.propulsionType = e.target.value;
    logConsole(`DESIGN: Propulsion steering set to ${state.propulsionType.toUpperCase()}`, "system");
    updatePhysicalStats();
    runGapAnalysis();
  };

  // Design Tab: Solar Input
  document.getElementById("design-solar-w").oninput = function (e) {
    state.solarW = parseFloat(e.target.value) || 400;
    updatePhysicalStats();
    runGapAnalysis();
  };

  // Design Tab: Battery Select
  document.getElementById("design-battery-ah").onchange = function (e) {
    state.batteryAh = parseFloat(e.target.value);
    logConsole(`DESIGN: LiFePO4 Battery bank set to ${state.batteryAh} Ah`, "system");
    const batteryMaxWh = state.batteryAh * 48;
    state.batteryWh = batteryMaxWh * (state.batteryPercent / 100);
    updatePhysicalStats();
    runGapAnalysis();
  };

  // Design Tab: Compute Selection
  const computeRadios = document.getElementsByName("design-compute");
  computeRadios.forEach(radio => {
    radio.onchange = function (e) {
      if (e.target.checked) {
        state.computeType = e.target.value;
        logConsole(`DESIGN: Edge compute set to ${state.computeType.toUpperCase()}`, "system");
        
        // Sync options for collision graphics and flags
        if (state.computeType === "mcu") {
          state.options.vision = false;
          state.options.lidar = false;
        } else if (state.computeType === "rpi5") {
          state.options.vision = true;
          state.options.lidar = false;
        } else if (state.computeType === "jetson") {
          state.options.vision = true;
          state.options.lidar = true;
        }
        
        updateObstaclesGraphics();
        updatePhysicalStats();
        runGapAnalysis();
      }
    };
  });

  // Design Tab: Optional Add-ons
  document.getElementById("opt-satellite").onchange = function (e) {
    state.options.satellite = e.target.checked;
    logConsole(`DESIGN: Satellite communications transceiver ${state.options.satellite ? "ENABLED" : "DISABLED"}`, "system");
    updatePhysicalStats();
    runGapAnalysis();
  };

  document.getElementById("opt-ais").onchange = function (e) {
    state.options.ais = e.target.checked;
    logConsole(`DESIGN: AIS transponder traffic feed ${state.options.ais ? "ENABLED" : "DISABLED"}`, "system");
    runGapAnalysis();
    updateAisShipsGraphics();
  };

  // Math Verification Tab inputs
  const verifyInputs = ["cfg-autonomy", "cfg-dod", "cfg-peak-sun", "cfg-efficiency"];
  verifyInputs.forEach(id => {
    document.getElementById(id).oninput = function () {
      runGapAnalysis();
    };
  });

  // Command buttons
  document.getElementById("btn-cmd-telreq").onclick = function () {
    executeCommand("TEL:REQ");
  };
  document.getElementById("btn-cmd-navhold").onclick = function () {
    executeCommand("NAV:HOLD");
  };
  document.getElementById("btn-cmd-navkill").onclick = function () {
    executeCommand("NAV:KILL");
  };

  // Terminal command submit
  document.getElementById("terminal-input-form").onsubmit = function (e) {
    e.preventDefault();
    const inputField = document.getElementById("terminal-input-text");
    const cmd = inputField.value.trim();
    if (cmd) {
      executeCommand(cmd);
      inputField.value = "";
    }
  };

  // Map Double-Click for Waypoints placement
  document.getElementById("tactical-svg-element").ondblclick = function (e) {
    const svg = document.getElementById("tactical-svg-element");
    const rect = svg.getBoundingClientRect();
    const x = ((e.clientX - rect.left) / rect.width) * MAP_WIDTH;
    const y = ((e.clientY - rect.top) / rect.height) * MAP_HEIGHT;
    const gps = svgToGps(x, y);
    
    // Add waypoint command
    const wpIndex = String(state.waypointsQueue.length + 1).padStart(2, '0');
    const cmd = `NAV:WP,${wpIndex},${gps.lat.toFixed(4)},${gps.lon.toFixed(4)}`;
    executeCommand(cmd);
  };
}

// --- EXECUTE TELEMETRY COMMANDS ---
function executeCommand(cmdStr) {
  logConsole(`[UPLINK] ${cmdStr}`, "uplink");
  
  const tokens = cmdStr.split(",");
  const prefix = tokens[0].trim().toUpperCase();

  if (prefix === "NAV:WP") {
    if (tokens.length < 4) {
      logConsole("[DOWNLINK] ERR: NAV:WP REQUIRES ARGUMENTS [INDEX],[LAT],[LON]", "downlink");
      return;
    }
    const idx = parseInt(tokens[1]);
    const lat = parseFloat(tokens[2]);
    const lon = parseFloat(tokens[3]);

    if (isNaN(idx) || isNaN(lat) || isNaN(lon)) {
      logConsole("[DOWNLINK] ERR: INVALID WAYPOINT COORDINATES OR INDEX", "downlink");
      return;
    }

    state.waypointsQueue.push({ index: idx, lat, lon });
    logConsole(`[DOWNLINK] TEL:ACK,NAV:WP,INDEX=${idx},LAT=${lat},LON=${lon},STATUS=ACCEPTED`, "downlink");
    updateWaypointsMapGraphics();

  } else if (prefix === "NAV:HOLD") {
    state.isHolding = true;
    state.isKilled = false;
    logConsole("[DOWNLINK] TEL:ACK,NAV:HOLD,STATUS=LOITERING", "downlink");

  } else if (prefix === "NAV:KILL") {
    state.isKilled = true;
    state.isHolding = false;
    logConsole("[DOWNLINK] TEL:ACK,NAV:KILL,EMERGENCY_SHUTDOWN=ACTIVE", "downlink");
    logConsole("CRITICAL WARNING: MOTORS CUT. EDGE AUTOPILOT HALTED.", "alert");

  } else if (prefix === "TEL:REQ") {
    // Compile diagnostic payload
    const activeWp = state.waypointsQueue.length > 0 ? `WP_Q_LEN=${state.waypointsQueue.length}` : "WP_Q=EMPTY";
    const throttleStr = state.isThrottling ? "THROTTLE=ACTIVE" : "THROTTLE=OFF";
    const status = state.isKilled ? "SHUTDOWN" : (state.isHolding ? "LOITERING" : "CRUISING");
    
    logConsole(`[DOWNLINK] TEL:DIAG,BAT=${state.batteryPercent.toFixed(1)}%,SOL=${state.solarHarvest.toFixed(1)}W,PROP=${state.propulsionPower.toFixed(1)}W,LAT=${state.boatLat.toFixed(4)},LON=${state.boatLon.toFixed(4)},SPEED=${state.boatSpeed.toFixed(1)}KT,STATE=${status},${throttleStr},${activeWp}`, "downlink");

  } else {
    logConsole(`[DOWNLINK] ERR: UNKNOWN COMMAND PREFIX "${prefix}"`, "downlink");
  }
}

// Update SVG waypoints markers
function updateWaypointsMapGraphics() {
  const wpGroup = document.getElementById("waypoints-group");
  const wpLines = document.getElementById("waypoints-lines");
  wpGroup.innerHTML = "";
  
  if (state.waypointsQueue.length === 0) {
    wpLines.setAttribute("d", "");
    return;
  }

  // Draw lines connecting waypoints
  let lineD = `M ${gpsToSvg(state.boatLat, state.boatLon).x} ${gpsToSvg(state.boatLat, state.boatLon).y}`;
  
  state.waypointsQueue.forEach((wp) => {
    const pt = gpsToSvg(wp.lat, wp.lon);
    lineD += ` L ${pt.x} ${pt.y}`;

    // Draw node circles
    const circle = document.createElementNS("http://www.w3.org/2000/svg", "circle");
    circle.setAttribute("cx", pt.x);
    circle.setAttribute("cy", pt.y);
    circle.setAttribute("r", "5");
    circle.setAttribute("fill", "transparent");
    circle.setAttribute("stroke", "var(--color-amber)");
    circle.setAttribute("stroke-width", "2");
    
    // Add text label
    const text = document.createElementNS("http://www.w3.org/2000/svg", "text");
    text.setAttribute("x", pt.x + 8);
    text.setAttribute("y", pt.y + 4);
    text.setAttribute("fill", "var(--color-amber)");
    text.setAttribute("font-size", "9px");
    text.setAttribute("font-family", "var(--font-mono)");
    text.textContent = `WP${wp.index}`;

    wpGroup.appendChild(circle);
    wpGroup.appendChild(text);
  });
  
  wpLines.setAttribute("d", lineD);
}

// --- DESIGN STUDIO PARAMETERS & STATS HELPERS ---
function getDesignPropulsionPower() {
  if (state.propulsionType === "diff_thruster") return 60.0;
  if (state.propulsionType === "azimuth_pod") return 45.0;
  if (state.propulsionType === "wind_hybrid") return 20.0;
  return 60.0;
}

function getDesignSystemPower() {
  let power = 0.0;
  if (state.computeType === "mcu") power = 10.0;
  else if (state.computeType === "rpi5") power = 22.0;
  else if (state.computeType === "jetson") power = 35.0;
  
  if (state.options.satellite) power += 1.5;
  if (state.options.ais) power += 2.0;
  return power;
}

function getHullSolarLimit(hull) {
  if (hull === "monohull") return 400;
  if (hull === "catamaran") return 600;
  if (hull === "trimaran") return 800;
  return 400;
}

function updatePhysicalStats() {
  let hullW = 45;
  if (state.hullType === "catamaran") hullW = 60;
  else if (state.hullType === "trimaran") hullW = 75;
  
  let batteryW = 48; // Ah 115
  if (state.batteryAh === 160) batteryW = 65;
  else if (state.batteryAh === 230) batteryW = 92;
  
  const solarW = (state.solarW / 100) * 2;
  
  let propW = 12;
  if (state.propulsionType === "azimuth_pod") propW = 8;
  else if (state.propulsionType === "wind_hybrid") propW = 18;
  
  let compW = 1;
  if (state.computeType === "rpi5") compW = 2;
  else if (state.computeType === "jetson") compW = 3;
  
  const totalWeight = hullW + batteryW + solarW + propW + compW + 10;
  
  let dragCd = 1.20;
  if (state.hullType === "catamaran") dragCd = 0.85;
  else if (state.hullType === "trimaran") dragCd = 0.75;
  
  document.getElementById("stat-weight").textContent = `${totalWeight} kg`;
  document.getElementById("stat-drag").textContent = `${dragCd.toFixed(2)} Cd`;
  document.getElementById("stat-solar-limit").textContent = `${getHullSolarLimit(state.hullType)} W`;
  document.getElementById("stat-base-load").textContent = `${getDesignSystemPower().toFixed(1)} W`;
  
  updateVesselGraphics();
}

function updateVesselGraphics() {
  const hullShape = document.getElementById("boat-hull-shape");
  if (!hullShape) return;
  
  if (state.hullType === "monohull") {
    hullShape.setAttribute("d", "M 0 -12 C 4 -6, 5 6, 0 10 C -5 6, -4 -6, 0 -12 Z");
    hullShape.setAttribute("fill", "rgba(0, 240, 255, 0.12)");
  } else if (state.hullType === "catamaran") {
    hullShape.setAttribute("d", "M -6 -11 C -4 -11, -3 -6, -3 9 C -3 9, -5 9, -6 9 C -7 9, -8 9, -8 9 C -8 -6, -7 -11, -6 -11 Z M 6 -11 C 8 -11, 7 -6, 7 9 C 7 9, 5 9, 6 9 C 7 9, 8 9, 8 9 C 8 -6, 7 -11, 6 -11 Z M -3 -3 L 3 -3 M -3 4 L 3 4");
    hullShape.setAttribute("fill", "rgba(0, 240, 255, 0.15)");
  } else if (state.hullType === "trimaran") {
    hullShape.setAttribute("d", "M 0 -12 C 2.5 -6, 3 8, 0 10 C -3 8, -2.5 -6, 0 -12 Z M -8 -7 C -7 -7, -6.5 -4, -6.5 6 C -6.5 6, -8.5 6, -8.5 6 C -8.5 -4, -8 -7, -8 -7 Z M 8 -7 C 9 -7, 8.5 -4, 8.5 6 C 8.5 6, 6.5 6, 6.5 6 C 6.5 -4, 7 -7, 8 -7 Z M -7 -2 L 7 -2 M -7 3 L 7 3");
    hullShape.setAttribute("fill", "rgba(0, 240, 255, 0.18)");
  }
}

// --- POWER SIZING CONFIGURATOR AND GAP ANALYSIS ---
function runGapAnalysis() {
  const batteryAh = state.batteryAh;
  const batteryV = 48; // 48V standard
  const dod = parseFloat(document.getElementById("cfg-dod").value) / 100;
  const autonomy = parseFloat(document.getElementById("cfg-autonomy").value);
  const solarW = state.solarW;
  const peakSun = parseFloat(document.getElementById("cfg-peak-sun").value);
  const efficiency = parseFloat(document.getElementById("cfg-efficiency").value) / 100;
  
  const propulsionW = getDesignPropulsionPower();
  const systemW = getDesignSystemPower();

  const dailyLoad = (propulsionW + systemW) * 24; // Wh/day
  const reqCapacityWh = (dailyLoad * autonomy) / dod;
  const reqAh = reqCapacityWh / batteryV;
  
  let stormRollLoss = 0.0;
  if (state.hullType === "monohull") stormRollLoss = 0.15;
  else if (state.hullType === "catamaran") stormRollLoss = 0.05;
  else if (state.hullType === "trimaran") stormRollLoss = 0.0;
  
  const reqSolar = dailyLoad / (peakSun * efficiency * (1.0 - stormRollLoss));

  const alertBox = document.getElementById("configurator-alert-box");
  const solarWarning = document.getElementById("solar-warning-text");

  const solarLimit = getHullSolarLimit(state.hullType);
  if (solarW > solarLimit) {
    solarWarning.style.display = "block";
    solarWarning.textContent = `⚠️ Exceeds deck limit (${solarLimit}W max for ${state.hullType.toUpperCase()}). Output capped.`;
  } else {
    solarWarning.style.display = "none";
  }

  let html = `<strong>Power calculations (ESD-01 rules):</strong><br>`;
  html += `Daily consumption load: ${Math.round(dailyLoad).toLocaleString()} Wh/day.<br>`;
  html += `Required Battery capacity: ${reqAh.toFixed(1)} Ah (Selected: ${batteryAh} Ah).<br>`;
  html += `Required Solar panel capacity: ${reqSolar.toFixed(1)} W (Selected: ${solarW} W).<br>`;

  const actualSolar = Math.min(solarW, solarLimit);
  if (batteryAh < reqAh && actualSolar < reqSolar) {
    alertBox.className = "spec-alert deficit";
    html += `<strong>CRITICAL GAP DETECTED:</strong> Both battery and solar capacity are insufficient. Throttling is MANDATORY.`;
  } else if (actualSolar < reqSolar) {
    alertBox.className = "spec-alert warning";
    html += `<strong>SOLAR GAP DETECTED (ESD gap):</strong> Sizing leaves a deficit. System will drain battery unless software throttles propulsion.`;
  } else if (batteryAh < reqAh) {
    alertBox.className = "spec-alert warning";
    html += `<strong>BATTERY STORAGE GAP:</strong> Storage is below the ${autonomy}-day target. Risk of blackout during storms.`;
  } else {
    alertBox.className = "spec-alert info";
    html += `<strong>DESIGN VALIDATED:</strong> Selected sizing meets all safety margins and autonomy calculations!`;
  }
  
  alertBox.innerHTML = html;
}

// --- SIMULATION STEP (RUNS AT 5Hz) ---
function simulationStep() {
  if (state.simSpeed === 0) return; // Paused

  // Time increment (seconds to advance per step: 0.2s real-time * speed)
  const dtSeconds = 0.2 * state.simSpeed;
  const dtHours = dtSeconds / 3600;

  // Advance simulation clock
  state.simTime = new Date(state.simTime.getTime() + dtSeconds * 1000);
  document.getElementById("simulation-time").innerText = state.simTime.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });

  // Get current design and math configurator values
  const batteryAh = state.batteryAh;
  const batteryV = 48;
  const systemW = getDesignSystemPower();
  const maxPropW = getDesignPropulsionPower();
  const dodLimit = parseFloat(document.getElementById("cfg-dod").value);
  const solarMaxW = Math.min(state.solarW, getHullSolarLimit(state.hullType));

  // --- 1. CALCULATE SOLAR HARVEST ---
  // Solar changes based on time-of-day (sunrise-sunset sine wave) and weather
  const hour = state.simTime.getHours() + state.simTime.getMinutes() / 60;
  let diurnalFactor = 0;
  if (hour > 6 && hour < 18) {
    diurnalFactor = Math.sin((hour - 6) / 12 * Math.PI);
  }

  let weatherScale = 1.0;
  if (state.weather === "overcast") weatherScale = 0.3;
  else if (state.weather === "stormy") weatherScale = 0.1;
  else if (state.weather === "night") weatherScale = 0.0;

  // Apply hull-specific rolling roll losses in stormy/overcast weather
  let rollLoss = 0.0;
  if (state.weather === "stormy" || state.weather === "overcast") {
    if (state.hullType === "monohull") rollLoss = 0.15;
    else if (state.hullType === "catamaran") rollLoss = 0.05;
    else if (state.hullType === "trimaran") rollLoss = 0.0;
  }

  state.solarHarvest = solarMaxW * weatherScale * diurnalFactor * (1.0 - rollLoss);
  if (state.weather === "night") state.solarHarvest = 0; // Absolute cutoff

  // --- 2. CALCULATE PROPULSION & LOADS ---
  
  // Power Hook Auto-Cutoff Logic (STM32 edge safeguard)
  if (state.batteryPercent < 40 && state.powerHookActive) {
    state.powerHookActive = false;
    logConsole("[ALERT] POWER CONTROL: Battery under 40% SoC. Deactivating high-level rails to prevent parasitic drain.", "alert");
    logConsole("[SYSTEM] POWER RAIL CUT: High-level compute and AIS feed are unpowered.", "system");
    updateAisShipsGraphics(); // hides ships
    updateObstaclesGraphics(); // dims obstacles
  } else if (state.batteryPercent >= 50 && !state.powerHookActive && !state.isBlackout) {
    state.powerHookActive = true;
    logConsole("[SYSTEM] POWER CONTROL: Battery recovered to >=50%. Restoring high-level power rails.", "system");
    updateAisShipsGraphics(); // restores ships if toggle is active
    updateObstaclesGraphics(); // restores bright obstacles
  }

  // Calculate dynamic loads based on power hook status
  let activeSystemPower = systemW;
  if (!state.powerHookActive) {
    // Drop back to low power MCU draw (10.0W)
    activeSystemPower = 10.0;
  }
  state.systemPower = activeSystemPower;
  
  // Update power hook status badge on UI
  const powerHookStatusBadge = document.getElementById("val-power-hook-status");
  if (powerHookStatusBadge) {
    if (state.isBlackout) {
      powerHookStatusBadge.className = "status-badge-inline shut-down";
      powerHookStatusBadge.textContent = "SYSTEM BLACKOUT";
    } else if (state.powerHookActive) {
      powerHookStatusBadge.className = "status-badge-inline active";
      powerHookStatusBadge.textContent = "ACTIVE (5V/12V ON)";
    } else {
      powerHookStatusBadge.className = "status-badge-inline shut-down";
      powerHookStatusBadge.textContent = "SHUT DOWN (AUTO)";
    }
  }
  
  if (state.isKilled) {
    state.propulsionPower = 0.0;
  } else if (state.isHolding) {
    state.propulsionPower = 15.0; // dynamic loitering
  } else {
    // Normal cruising throttle
    state.propulsionPower = maxPropW;

    // Wing sail wind propulsion drops thruster draw when breeze is active
    if (state.propulsionType === "wind_hybrid" && (state.weather === "sunny" || state.weather === "overcast")) {
      state.propulsionPower = 15.0; // sail assist
    }
  }

  // Apply Software Propulsion Throttling if active and net energy is negative
  let isThrottleActive = false;
  if (state.isThrottling && !state.isKilled && !state.isHolding && !state.isBlackout) {
    const rawNet = state.solarHarvest - (state.systemPower + state.propulsionPower);
    if (rawNet < 0) {
      const targetProp = Math.max(15.0, state.solarHarvest - state.systemPower);
      if (targetProp < state.propulsionPower) {
        state.propulsionPower = targetProp;
        isThrottleActive = true;
      }
    }
  }

  // --- 3. BATTERY STATE OF CHARGE INTEGRATION ---
  const batteryMaxWh = batteryAh * batteryV;
  state.netPower = state.solarHarvest - (state.systemPower + state.propulsionPower);
  
  if (state.isBlackout) {
    state.solarHarvest = 0;
    state.systemPower = 0;
    state.propulsionPower = 0;
    state.netPower = 0;
    state.boatSpeed = 0;
  } else {
    state.batteryWh += state.netPower * dtHours;
    
    // Safety caps
    if (state.batteryWh > batteryMaxWh) {
      state.batteryWh = batteryMaxWh;
    }
    
    state.batteryPercent = (state.batteryWh / batteryMaxWh) * 100;
    
    if (state.batteryPercent <= 0) {
      state.batteryPercent = 0;
      state.batteryWh = 0;
      state.isBlackout = true;
      logConsole("SYSTEM ERROR: CRITICAL POWER DEPLEATION. BATTERY IN BLACKOUT.", "alert");
    }
  }

  // --- 4. BOAT NAVIGATION POSITION STEP ---
  if (!state.isKilled && !state.isHolding && !state.isBlackout && densePath.length > 0) {
    // Calculate speed based on thrust power and hull drag coefficient
    let dragCoeff = 1.0;
    if (state.hullType === "monohull") dragCoeff = 1.20;
    else if (state.hullType === "catamaran") dragCoeff = 0.85;
    else if (state.hullType === "trimaran") dragCoeff = 0.75;

    state.boatSpeed = (5.0 * Math.sqrt(state.propulsionPower / maxPropW)) / dragCoeff;

    // Wing sail speed boost in favorable wind (sunny/overcast coastal breeze)
    if (state.propulsionType === "wind_hybrid" && (state.weather === "sunny" || state.weather === "overcast")) {
      state.boatSpeed += 0.8;
    }

    if (state.boatSpeed < 0.2) state.boatSpeed = 0;

    // Movement step
    const distanceStepNM = state.boatSpeed * dtHours;

    // --- 4.1 OBSTACLE DETECTOR & COLREGs AVOIDANCE ---
    state.avoidanceHeadingOffset = 0;
    let activeObstacle = null;
    let minObstacleDist = 999.0;
    
    staticObstacles.forEach(ob => {
      const dist = getDistanceNM(state.boatLat, state.boatLon, ob.lat, ob.lon);
      if (dist < minObstacleDist) {
        minObstacleDist = dist;
        activeObstacle = ob;
      }
    });

    const isVisionActive = state.options.vision && state.powerHookActive && !state.isBlackout;
    const isLidarActive = state.options.lidar && state.powerHookActive && !state.isBlackout;
    
    if (activeObstacle) {
      if (state.computeType === "mcu" || !state.powerHookActive) {
        // MCU: straight course, log warnings on close proximity
        if (minObstacleDist < 2.0) {
          if (!state.loggedObstacles[activeObstacle.id]) {
            state.loggedObstacles[activeObstacle.id] = "warned";
            logConsole(`[CRITICAL WARNING] CLOSE PROXIMITY: Passed within ${minObstacleDist.toFixed(2)} NM of "${activeObstacle.name}" with NO collision avoidance tracking!`, "alert");
          }
        } else {
          state.loggedObstacles[activeObstacle.id] = null;
        }
      } else if (state.computeType === "rpi5") {
        // RPi 5: standard starboard offset steer when within 5 NM
        if (minObstacleDist < 5.0) {
          if (minObstacleDist >= 1.5) {
            state.avoidanceHeadingOffset = 25; // 25° starboard offset
            if (state.loggedObstacles[activeObstacle.id] !== "avoiding") {
              state.loggedObstacles[activeObstacle.id] = "avoiding";
              logConsole(`[ALERT] AUTOPILOT (Pi5): Object "${activeObstacle.name}" detected at ${minObstacleDist.toFixed(1)} NM. Initiating starboard avoidance steer (+25°).`, "alert");
            }
          } else {
            state.avoidanceHeadingOffset = 0;
            if (state.loggedObstacles[activeObstacle.id] === "avoiding") {
              state.loggedObstacles[activeObstacle.id] = "cleared";
              logConsole(`[ALERT] AUTOPILOT (Pi5): Object "${activeObstacle.name}" cleared. Resuming waypoint plan.`, "system");
            }
          }
        }
      } else if (state.computeType === "jetson") {
        // Jetson Orin: advanced smooth vector steer when within 8 NM
        if (minObstacleDist < 8.0) {
          if (minObstacleDist >= 1.5) {
            // Steering offset is inversely proportional to distance (steers wider as it gets closer)
            state.avoidanceHeadingOffset = Math.round(35.0 / Math.max(1.0, minObstacleDist));
            if (state.loggedObstacles[activeObstacle.id] !== "avoiding") {
              state.loggedObstacles[activeObstacle.id] = "avoiding";
              logConsole(`[ALERT] EDGE AI (Jetson): Hazard "${activeObstacle.name}" tracked at ${minObstacleDist.toFixed(1)} NM. Activating smooth vector steering deviation (+${state.avoidanceHeadingOffset}°).`, "alert");
            }
          } else {
            state.avoidanceHeadingOffset = 0;
            if (state.loggedObstacles[activeObstacle.id] === "avoiding") {
              state.loggedObstacles[activeObstacle.id] = "cleared";
              logConsole(`[ALERT] EDGE AI (Jetson): Hazard "${activeObstacle.name}" cleared. Resuming waypoint plan.`, "system");
            }
          }
        }
      }
    }
    
    // Check if navigating custom waypoints first
    if (state.waypointsQueue.length > 0) {
      const targetWp = state.waypointsQueue[0];
      const distToWp = getDistanceNM(state.boatLat, state.boatLon, targetWp.lat, targetWp.lon);
      
      if (distToWp <= distanceStepNM) {
        state.boatLat = targetWp.lat;
        state.boatLon = targetWp.lon;
        state.waypointsQueue.shift();
        logConsole(`WAYPOINT WP${targetWp.index} REACHED. NEXT ROUTE waypoint LOADING.`, "system");
        updateWaypointsMapGraphics();
      } else {
        let bearing = Math.atan2(targetWp.lon - state.boatLon, targetWp.lat - state.boatLat);
        if (state.avoidanceHeadingOffset !== 0) {
          bearing += (state.avoidanceHeadingOffset * Math.PI / 180);
        }
        state.boatHeading = Math.floor((bearing * 180 / Math.PI + 360) % 360);
        state.boatLat += Math.cos(bearing) * (distanceStepNM / 60);
        state.boatLon += Math.sin(bearing) * (distanceStepNM / 60);
      }
      
    } else {
      const targetPt = densePath[state.routeIndex];
      const distToPt = getDistanceNM(state.boatLat, state.boatLon, targetPt.lat, targetPt.lon);
      
      if (distToPt <= distanceStepNM) {
        state.boatLat = targetPt.lat;
        state.boatLon = targetPt.lon;
        state.routeIndex++;
        if (state.routeIndex >= densePath.length) {
          state.routeIndex = densePath.length - 1;
          state.boatSpeed = 0;
          state.propulsionPower = 0;
          logConsole("MISSION COMPLETE: Rover reached Tampa Bay destination!", "system");
          state.simSpeed = 0; // Pause
          document.getElementById("sim-speed-select").value = 0;
        }
      } else {
        let bearing = Math.atan2(targetPt.lon - state.boatLon, targetPt.lat - state.boatLat);
        if (state.avoidanceHeadingOffset !== 0) {
          bearing += (state.avoidanceHeadingOffset * Math.PI / 180);
        }
        state.boatHeading = Math.floor((bearing * 180 / Math.PI + 360) % 360);
        state.boatLat += Math.cos(bearing) * (distanceStepNM / 60);
        state.boatLon += Math.sin(bearing) * (distanceStepNM / 60);
      }
    }
  } else {
    state.boatSpeed = 0.0;
  }

  // --- 4.2 AIS SHIP SIMULATION & PROXIMITY CHECKS ---
  const isAisActive = state.options.ais && state.powerHookActive && !state.isBlackout;
  if (isAisActive) {
    state.aisShips.forEach(ship => {
      ship.lat += Math.cos(ship.heading * Math.PI / 180) * (ship.speed * dtHours / 60);
      ship.lon += Math.sin(ship.heading * Math.PI / 180) * (ship.speed * dtHours / 60);

      if (ship.lat < 23.5 || ship.lat > 34.0 || ship.lon < -84.0 || ship.lon > -78.0) {
        ship.lat = ship.latStart;
        ship.lon = ship.lonStart;
      }

      const dist = getDistanceNM(state.boatLat, state.boatLon, ship.lat, ship.lon);
      if (dist < 15.0 && !state.loggedAisShips[ship.name]) {
        state.loggedAisShips[ship.name] = true;
        logConsole(`[ALERT] AIS: Commercial ship "${ship.name}" closing at ${dist.toFixed(1)} NM. CPA: ${(dist*0.25).toFixed(1)} NM. Monitoring CPA.`, "system");
      } else if (dist >= 18.0 && state.loggedAisShips[ship.name]) {
        state.loggedAisShips[ship.name] = false;
      }
    });
    updateAisShipsGraphics();
  }
  
  updateObstaclesGraphics();

  // --- 4.3 LiDAR ROTATIONAL SCAN CONE UPDATE ---
  const lidarCone = document.getElementById("lidar-scan-cone");
  const isLidarActive = state.options.lidar && state.powerHookActive && !state.isBlackout;
  if (isLidarActive) {
    lidarCone.style.display = "block";
    const sweepAngle = Math.sin(state.simTime.getTime() / 250) * 35;
    lidarCone.setAttribute("transform", `rotate(${sweepAngle})`);
  } else {
    lidarCone.style.display = "none";
  }

  // --- 5. MESHCORE TELEMETRY HOP INTEGRATION ---
  let nearestRep = repeaters[0];
  let minDist = getDistanceNM(state.boatLat, state.boatLon, repeaters[0].lat, repeaters[0].lon);
  
  repeaters.forEach(rep => {
    const dist = getDistanceNM(state.boatLat, state.boatLon, rep.lat, rep.lon);
    if (dist < minDist) {
      minDist = dist;
      nearestRep = rep;
    }
  });

  let rssi = -115;
  let hopCount = nearestRep.hops;
  let telemetryConnected = false;
  
  if (minDist <= 10) {
    rssi = Math.floor(-65 - (minDist * 1.5));
    telemetryConnected = true;
  } else if (minDist <= 35) {
    rssi = Math.floor(-80 - ((minDist - 10) * 1.0));
    telemetryConnected = true;
  } else if (minDist <= 55) {
    rssi = Math.floor(-105 - ((minDist - 35) * 0.5));
    telemetryConnected = true;
  }

  let isSatelliteActive = false;
  if (!telemetryConnected && state.options.satellite && !state.isBlackout) {
    telemetryConnected = true;
    isSatelliteActive = true;
  }

  const signalDot = document.getElementById("telemetry-status-dot");
  const signalText = document.getElementById("telemetry-status-text");
  const boatToRepLine = document.getElementById("boat-to-repeater-link");
  
  if (telemetryConnected && !state.isBlackout) {
    signalDot.className = "status-dot active";
    
    if (isSatelliteActive) {
      signalText.textContent = `MeshCore: Connected (Sat Backup)`;
      document.getElementById("val-repeater-name").textContent = "SAT GATEWAY (SWARM)";
      document.getElementById("val-hop-count").textContent = "1 (Sat)";
      document.getElementById("val-rssi").textContent = "-108 dBm";
      boatToRepLine.style.display = "none";
      
      if (state.lastTelemetryMode !== "satellite") {
        state.lastTelemetryMode = "satellite";
        logConsole("[SYSTEM] LoRa coastline connection lost. Satellite telemetry backup ONLINE.", "system");
      }
    } else {
      signalText.textContent = `MeshCore: Connected`;
      document.getElementById("val-repeater-name").textContent = nearestRep.name;
      document.getElementById("val-hop-count").textContent = hopCount;
      document.getElementById("val-rssi").textContent = `${rssi} dBm`;
      
      const boatPt = gpsToSvg(state.boatLat, state.boatLon);
      const repPt = gpsToSvg(nearestRep.lat, nearestRep.lon);
      boatToRepLine.setAttribute("x1", boatPt.x);
      boatToRepLine.setAttribute("y1", boatPt.y);
      boatToRepLine.setAttribute("x2", repPt.x);
      boatToRepLine.setAttribute("y2", repPt.y);
      boatToRepLine.style.display = "block";
      
      if (state.lastTelemetryMode !== "lora") {
        state.lastTelemetryMode = "lora";
        logConsole("[SYSTEM] Local LoRa mesh connection RESTORED.", "system");
      }
    }
  } else {
    signalDot.className = "status-dot offline";
    signalText.textContent = `MeshCore: Disconnected`;
    document.getElementById("val-repeater-name").textContent = "NO DATA LINK";
    document.getElementById("val-hop-count").textContent = "-";
    document.getElementById("val-rssi").textContent = "-";
    boatToRepLine.style.display = "none";
    
    if (state.lastTelemetryMode !== "offline") {
      state.lastTelemetryMode = "offline";
      logConsole("[WARNING] SIGNAL LOSS: No LoRa repeaters in range. Autopilot operating autonomously.", "alert");
    }
  }

  // --- 6. UPDATE DASHBOARD LABELS ---
  document.getElementById("val-battery-pct").innerText = state.batteryPercent.toFixed(1);
  document.getElementById("val-net-power").innerText = (state.netPower > 0 ? "+" : "") + state.netPower.toFixed(1);
  
  const balanceCard = document.getElementById("card-net-power");
  if (state.netPower > 0) {
    balanceCard.className = "metric-card green";
  } else if (state.netPower < -30) {
    balanceCard.className = "metric-card red";
  } else {
    balanceCard.className = "metric-card amber";
  }

  document.getElementById("val-solar-watts").innerText = state.solarHarvest.toFixed(1);
  document.getElementById("val-prop-watts").innerText = state.propulsionPower.toFixed(1);

  document.getElementById("val-latitude").innerText = `${Math.abs(state.boatLat).toFixed(4)}° ${state.boatLat >= 0 ? "N" : "S"}`;
  document.getElementById("val-longitude").innerText = `${Math.abs(state.boatLon).toFixed(4)}° ${state.boatLon >= 0 ? "E" : "W"}`;

  document.getElementById("val-speed").innerText = state.boatSpeed.toFixed(1);
  document.getElementById("val-heading").innerText = `${state.boatHeading}°`;

  const totalSteps = densePath.length;
  const progressPct = Math.min(100, Math.floor((state.routeIndex / totalSteps) * 100));
  const milesDone = Math.floor((state.routeIndex / totalSteps) * 650);
  document.getElementById("val-dist-pct").innerText = progressPct;
  document.getElementById("val-dist-miles").innerText = `${milesDone}/650 nm`;

  const diagDot = document.getElementById("sys-diagnostic-dot");
  if (state.isBlackout) {
    diagDot.className = "status-dot off";
  } else if (isThrottleActive) {
    diagDot.className = "status-dot warn";
  } else {
    diagDot.className = "status-dot active";
  }

  const battCard = document.getElementById("card-battery");
  if (state.batteryPercent < dodLimit) {
    battCard.className = "metric-card red";
  } else if (state.batteryPercent < 50) {
    battCard.className = "metric-card amber";
  } else {
    battCard.className = "metric-card green";
  }

  // --- 7. POWER FLOW diagram nodes text updates ---
  document.getElementById("flow-val-solar").textContent = `${Math.floor(state.solarHarvest)}W`;
  document.getElementById("flow-val-loads").textContent = `${Math.floor(state.systemPower + state.propulsionPower)}W`;
  
  const solarNode = document.getElementById("flow-node-solar");
  if (state.solarHarvest > 0) {
    solarNode.style.borderColor = "var(--color-amber)";
    solarNode.style.boxShadow = `0 0 10px rgba(245, 158, 11, ${diurnalFactor * 0.4})`;
  } else {
    solarNode.style.borderColor = "rgba(255,255,255,0.05)";
    solarNode.style.boxShadow = "none";
  }

  const battNode = document.getElementById("flow-node-battery");
  battNode.querySelector(".flow-power-value").textContent = `${state.batteryPercent.toFixed(0)}%`;
  if (state.netPower > 0) {
    battNode.style.borderColor = "var(--color-green)";
    battNode.style.boxShadow = "0 0 10px rgba(16, 185, 129, 0.2)";
  } else if (state.netPower < 0) {
    battNode.style.borderColor = "var(--color-red)";
    battNode.style.boxShadow = "0 0 10px rgba(239, 68, 68, 0.2)";
  } else {
    battNode.style.borderColor = "rgba(255,255,255,0.1)";
    battNode.style.boxShadow = "none";
  }

  const fillBar = document.getElementById("power-balance-fill-bar");
  const netRatio = state.solarHarvest / (state.systemPower + state.propulsionPower + 0.1);
  const fillPercent = Math.min(100, Math.max(10, Math.floor(netRatio * 50)));
  fillBar.style.width = `${fillPercent}%`;
  if (state.netPower >= 0) {
    fillBar.style.backgroundColor = "var(--color-green)";
  } else {
    fillBar.style.backgroundColor = "var(--color-red)";
  }

  // --- 8. MOVE BOAT GRAPHIC ON MAP ---
  const boatGroup = document.getElementById("boat-group");
  const boatPt = gpsToSvg(state.boatLat, state.boatLon);
  boatGroup.setAttribute("transform", `translate(${boatPt.x}, ${boatPt.y})`);
  
  const boatRotationGroup = document.getElementById("boat-rotation-group");
  if (boatRotationGroup) {
    boatRotationGroup.setAttribute("transform", `rotate(${state.boatHeading})`);
  }

  // Update dynamic line connection from boat to next custom waypoint
  if (state.waypointsQueue.length > 0) {
    updateWaypointsMapGraphics();
  }

  // --- 9. RECORD HISTORY & REDRAW CHART ---
  state.history.push({
    solar: state.solarHarvest,
    load: state.systemPower + state.propulsionPower,
    soc: state.batteryPercent
  });
  if (state.history.length > 50) {
    state.history.shift();
  }
  drawHistoryChart();
}

// --- DRAW REAL-TIME SG HISTOGRAM ---
function drawHistoryChart() {
  const chartSvg = document.getElementById("power-history-chart-svg");
  if (!chartSvg || state.history.length < 2) return;

  const w = chartSvg.clientWidth || 300;
  const h = 100;
  
  // Find max value in history to scale
  let maxVal = 100;
  state.history.forEach(d => {
    if (d.solar > maxVal) maxVal = d.solar;
    if (d.load > maxVal) maxVal = d.load;
  });

  const dx = w / 49;
  
  let solarPoints = "";
  let loadPoints = "";
  let socPoints = "";

  state.history.forEach((d, i) => {
    const x = i * dx;
    
    // Invert Y for SVG coordinates
    const ySolar = h - (d.solar / maxVal) * (h - 10) - 5;
    const yLoad = h - (d.load / maxVal) * (h - 10) - 5;
    const ySoc = h - (d.soc / 100) * (h - 10) - 5; // SoC is strictly 0-100%

    if (i === 0) {
      solarPoints = `M ${x} ${ySolar}`;
      loadPoints = `M ${x} ${yLoad}`;
      socPoints = `M ${x} ${ySoc}`;
    } else {
      solarPoints += ` L ${x} ${ySolar}`;
      loadPoints += ` L ${x} ${yLoad}`;
      socPoints += ` L ${x} ${ySoc}`;
    }
  });

  chartSvg.innerHTML = `
    <path d="${solarPoints}" fill="none" stroke="var(--color-amber)" stroke-width="1.5" />
    <path d="${loadPoints}" fill="none" stroke="var(--color-red)" stroke-width="1.5" />
    <path d="${socPoints}" fill="none" stroke="var(--color-green)" stroke-width="1.5" stroke-dasharray="2, 2" />
  `;
}

// Draw static obstacles on the SVG map (Option C)
function updateObstaclesGraphics() {
  const obstaclesGroup = document.getElementById("obstacles-group");
  if (!obstaclesGroup) return;
  obstaclesGroup.innerHTML = "";

  const isVisionActive = state.options.vision && state.powerHookActive && !state.isBlackout;
  
  staticObstacles.forEach(ob => {
    const pt = gpsToSvg(ob.lat, ob.lon);
    
    // 1. Draw detection/warning horizon rings around the hazards
    const hazardZone = document.createElementNS("http://www.w3.org/2000/svg", "circle");
    hazardZone.setAttribute("cx", pt.x);
    hazardZone.setAttribute("cy", pt.y);
    
    let rangeNM = 2.0;
    if (state.computeType === "rpi5") rangeNM = 5.0;
    else if (state.computeType === "jetson") rangeNM = 8.0;
    
    const ptEdge = gpsToSvg(ob.lat + (rangeNM / 60.0), ob.lon);
    const radiusSvg = Math.abs(ptEdge.y - pt.y);
    
    hazardZone.setAttribute("r", radiusSvg);
    hazardZone.setAttribute("class", "hazard-zone" + (isVisionActive ? " hazard-zone-active" : ""));
    obstaclesGroup.appendChild(hazardZone);
    
    // 2. Draw central obstacle core indicator
    const circle = document.createElementNS("http://www.w3.org/2000/svg", "circle");
    circle.setAttribute("cx", pt.x);
    circle.setAttribute("cy", pt.y);
    circle.setAttribute("r", "5");
    circle.setAttribute("class", "vision-obstacle");
    circle.setAttribute("fill", isVisionActive ? "var(--color-amber)" : "rgba(245, 158, 11, 0.25)");
    circle.setAttribute("stroke", isVisionActive ? "rgba(245, 158, 11, 0.6)" : "transparent");
    
    const title = document.createElementNS("http://www.w3.org/2000/svg", "title");
    title.textContent = `Obstacle: ${ob.name} (${ob.lat.toFixed(3)}, ${ob.lon.toFixed(3)}) - Avoidance Horizon: ${rangeNM} NM`;
    circle.appendChild(title);
    
    obstaclesGroup.appendChild(circle);
  });
}

// Draw AIS ship triangles on the SVG map (Option B)
function updateAisShipsGraphics() {
  const shipsGroup = document.getElementById("ais-ships-group");
  if (!shipsGroup) return;
  shipsGroup.innerHTML = "";

  const isAisActive = state.options.ais && state.powerHookActive && !state.isBlackout;
  if (!isAisActive) return;

  state.aisShips.forEach(ship => {
    const pt = gpsToSvg(ship.lat, ship.lon);
    
    const g = document.createElementNS("http://www.w3.org/2000/svg", "g");
    g.setAttribute("transform", `translate(${pt.x}, ${pt.y}) rotate(${ship.heading})`);
    
    const triangle = document.createElementNS("http://www.w3.org/2000/svg", "polygon");
    triangle.setAttribute("points", "0,-6 -4,4 4,4");
    triangle.setAttribute("class", "ais-ship");
    
    const title = document.createElementNS("http://www.w3.org/2000/svg", "title");
    title.textContent = `AIS Vessel: ${ship.name} (Speed: ${ship.speed} kt, Heading: ${ship.heading}°)`;
    g.appendChild(triangle);
    g.appendChild(title);
    
    shipsGroup.appendChild(g);
  });
}
