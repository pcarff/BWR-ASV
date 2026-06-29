// Project Blue-Water Rover ASV - ESD-02-B
// Design Option B: Coaxial Magnetic Coupling Propulsion Model
//
// Open this file in OpenSCAD (https://openscad.org) to view the assembly.

$fn = 60; // Curve resolution

// Color constants
color_pvc = [0.7, 0.7, 0.75, 0.4];          // Translucent grey PVC
color_delrin = [0.95, 0.95, 0.95, 1.0];       // White Delrin
color_oring = [0.1, 0.1, 0.1, 1.0];           // Black rubber O-rings
color_motor = [0.8, 0.5, 0.1, 1.0];          // Motor coils/housing (orange/silver)
color_hub = [0.4, 0.4, 0.4, 1.0];            // Back-iron steel hubs
color_magnet_n = [0.8, 0.2, 0.2, 1.0];      // North magnets (red)
color_magnet_s = [0.2, 0.2, 0.8, 1.0];      // South magnets (blue)
color_shaft = [0.85, 0.85, 0.85, 1.0];      // Stainless steel shaft
color_polymer = [0.6, 0.6, 0.6, 1.0];        // Igus xiros polymer bearings
color_ceramic = [0.93, 0.93, 0.91, 1.0];     // Ceramic thrust bearing (ivory)
color_prop = [0.15, 0.15, 0.15, 1.0];       // Propeller (black)
color_collar = [0.1, 0.6, 0.3, 1.0];        // Mounting collar (green)

// Model dimensions (mm)
pvc_od = 88.9;        // 3-inch SDR-35 PVC outer diameter
pvc_id = 82.2;        // 3-inch SDR-35 PVC inner diameter
pvc_length = 120.0;
delrin_dia = pvc_id;
barrier_thickness = 1.5;
magnet_gap = 2.5;     // Total gap between internal and external magnets

// Explode distance
explode = 0.0; // Set to >0 in OpenSCAD to see internal parts

module dry_chamber() {
    // PVC dry tube
    color(color_pvc)
    difference() {
        cylinder(d=pvc_od, h=pvc_length, center=true);
        cylinder(d=pvc_id, h=pvc_length + 2, center=true);
    }
}

module delrin_cap() {
    // Machined Delrin cap with O-ring grooves and thin barrier face
    color(color_delrin)
    difference() {
        union() {
            // Main plug body
            cylinder(d=delrin_dia, h=30, center=true);
            // Flange collar matching PVC OD
            translate([0, 0, 15 + 2.5])
            cylinder(d=pvc_od, h=5, center=true);
        }
        // Hollow internal cup for internal magnet hub
        translate([0, 0, -5])
        cylinder(d=delrin_dia - 10, h=30, center=true);
        
        // O-ring grooves (AS568-152)
        // Two radial grooves on the plug body
        translate([0, 0, -8])
        difference() {
            cylinder(d=delrin_dia + 2, h=3.6, center=true);
            cylinder(d=delrin_dia - 4.04, h=4, center=true);
        }
        translate([0, 0, 2])
        difference() {
            cylinder(d=delrin_dia + 2, h=3.6, center=true);
            cylinder(d=delrin_dia - 4.04, h=4, center=true);
        }
    }
    
    // O-rings (representing Nitrile rings placed in the grooves)
    color(color_oring) {
        translate([0, 0, -8])
        difference() {
            cylinder(d=delrin_dia - 0.2, h=2.6, center=true);
            cylinder(d=delrin_dia - 5.0, h=3, center=true);
        }
        translate([0, 0, 2])
        difference() {
            cylinder(d=delrin_dia - 0.2, h=2.6, center=true);
            cylinder(d=delrin_dia - 5.0, h=3, center=true);
        }
    }
}

module brushless_motor() {
    // Internal 5010 brushless motor
    color([0.3, 0.3, 0.35, 1.0]) // Stator
    cylinder(d=50, h=10, center=true);
    color(color_motor) // Copper windings
    for (i = [0:11]) {
        rotate([0, 0, i * 30])
        translate([18, 0, 0])
        cylinder(d=10, h=8, center=true);
    }
    // Rotor cup and shaft
    color([0.8, 0.8, 0.85, 1.0]) {
        translate([0, 0, 8])
        cylinder(d=50, h=6, center=true);
        translate([0, 0, 15])
        cylinder(d=8, h=20, center=true);
    }
}

module magnet_coupling_hub(internal=true) {
    dia = internal ? delrin_dia - 16 : delrin_dia + 6;
    h_len = 15;
    
    // Steel back-iron ring
    color(color_hub)
    difference() {
        cylinder(d=dia, h=h_len, center=true);
        cylinder(d=dia-6, h=h_len+2, center=true);
    }
    
    // Neodymium magnets (12 poles)
    for (i = [0:11]) {
        rotate([0, 0, i * 30]) {
            translate([internal ? dia/2 - 2 : dia/2 - 4, 0, 0])
            color(i % 2 == 0 ? color_magnet_n : color_magnet_s)
            cube([3, 10, 10], center=true);
        }
    }
}

module polymer_bearing() {
    // Igus xiros polymer bearing
    color(color_polymer)
    difference() {
        cylinder(d=15, h=5, center=true);
        cylinder(d=6, h=6, center=true);
    }
}

module ceramic_thrust_washer() {
    // Silicon Nitride ceramic thrust bearing
    color(color_ceramic)
    difference() {
        cylinder(d=14, h=2, center=true);
        cylinder(d=6.2, h=3, center=true);
    }
}

module wet_bracket() {
    // ASA bracket holding external shaft and bearings
    color(color_collar)
    difference() {
        union() {
            // Main ring clamping Delrin cap
            cylinder(d=pvc_od + 8, h=10, center=true);
            // Struts extending aft
            translate([0, 0, 20])
            cylinder(d=30, h=30, center=true);
        }
        // Inner bore matching Delrin cap flange
        cylinder(d=pvc_od, h=12, center=true);
        // Shaft and bearing seat passage
        translate([0, 0, 20])
        cylinder(d=15.1, h=35, center=true);
    }
}

module propeller() {
    // Folding hub
    color(color_prop)
    cylinder(d=20, h=10, center=true);
    
    // Blades (folded)
    for (dir = [-1, 1]) {
        translate([dir * 10, 0, 0])
        rotate([dir * 15, 5, dir * 90])
        color(color_prop)
        scale([1, 0.1, 0.05])
        translate([0, 100, 0])
        sphere(r=100);
    }
}

// --- ASSEMBLY VIEW ---
// Dry PVC Tube
translate([0, 0, -pvc_length/2]) dry_chamber();

// Internal Motor (Fixed inside tube)
translate([0, 0, -45]) rotate([180, 0, 0]) brushless_motor();

// Internal Magnet Hub (on motor shaft, close to cap)
translate([0, 0, -15 - explode]) magnet_coupling_hub(internal=true);

// Delrin Cap (sealing the end of the tube)
translate([0, 0, 0]) delrin_cap();

// Wet Side Bracket (holding external shaft)
translate([0, 0, 10]) wet_bracket();

// External Magnet Hub (Wet side)
translate([0, 0, 5 + magnet_gap + explode]) magnet_coupling_hub(internal=false);

// Ceramic Thrust Washer (bearing the axial attraction load)
translate([0, 0, 15 + explode]) ceramic_thrust_washer();

// Polymer Bearings (supporting the wet shaft)
translate([0, 0, 25 + explode]) polymer_bearing();
translate([0, 0, 35 + explode]) polymer_bearing();

// Wet-Side Shaft
translate([0, 0, 28 + explode])
color(color_shaft)
cylinder(d=6, h=55, center=true);

// Propeller (attached to external shaft)
translate([0, 0, 60 + explode * 2]) propeller();
