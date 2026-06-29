// Project Blue-Water Rover ASV - ESD-02-A
// Design Option A: Potted Wet-Running Direct-Drive Propulsion Model
//
// Open this file in OpenSCAD (https://openscad.org) to view the assembly.

$fn = 60; // Curve resolution

// Color constants
color_stator_epoxy = [0.8, 0.4, 0.1, 0.9]; // Potted epoxy (translucent orange-brown)
color_stator_metal = [0.3, 0.3, 0.3, 1.0]; // Steel core
color_rotor = [0.5, 0.5, 0.55, 0.8];       // Aluminum rotor (translucent)
color_magnet_n = [0.8, 0.2, 0.2, 1.0];      // North magnets (red)
color_magnet_s = [0.2, 0.2, 0.8, 1.0];      // South magnets (blue)
color_ceramic = [0.93, 0.93, 0.91, 1.0];     // ZrO2 Ceramic (ivory)
color_collar = [0.1, 0.6, 0.3, 1.0];        // ASA collar (green)
color_foil = [0.75, 0.75, 0.75, 0.8];       // Aluminum spar (translucent)
color_prop = [0.15, 0.15, 0.15, 1.0];       // Carbon fiber prop
color_shaft = [0.85, 0.85, 0.85, 1.0];      // Stainless steel shaft
color_anode = [0.6, 0.6, 0.7, 1.0];         // Zinc anode

// Model dimensions (mm)
stator_dia = 50.0;
stator_length = 35.0;
air_gap = 0.8;
rotor_thickness = 3.0;
rotor_dia = stator_dia + 2 * air_gap + 2 * rotor_thickness;
rotor_length = 40.0;
shaft_dia = 8.0;
shaft_length = 120.0;

// Explode distance for viewing internal parts
explode = 0.0; // Set to >0 in OpenSCAD to see internal parts

module foil_spar() {
    // 8mm thick aluminum foil profile (approximate NACA 0012)
    color(color_foil)
    linear_extrude(height=150)
    scale([1, 0.15])
    difference() {
        circle(d=80);
        translate([40, -40]) square([80, 80]); // trailing edge taper
    }
}

module mounting_collar() {
    // ASA split collar clamping the foil and housing the shaft
    color(color_collar)
    difference() {
        union() {
            // Main cylindrical body
            cylinder(d=65, h=50, center=true);
            // Wing clamping the foil spar
            translate([0, 30, 25])
            cube([25, 60, 100], center=true);
        }
        // Slot for foil spar
        translate([0, 30, 25])
        cube([8.2, 80, 110], center=true);
        // Shaft passage
        cylinder(d=22, h=60, center=true);
        // Bolt holes
        translate([0, 45, 50]) rotate([0, 90, 0]) cylinder(d=5.2, h=40, center=true);
        translate([0, 45, 0]) rotate([0, 90, 0]) cylinder(d=5.2, h=40, center=true);
    }
}

module stator_core() {
    // Stator coils and teeth
    color(color_stator_metal)
    cylinder(d=shaft_dia+4, h=stator_length, center=true);
    
    // Teeth and windings (12 slots)
    for (i = [0:11]) {
        rotate([0, 0, i * 30]) {
            // Steel tooth
            color(color_stator_metal)
            translate([stator_dia/4 + 2, 0, 0])
            cube([stator_dia/2 - 4, 4, stator_length], center=true);
            
            // Copper windings potted in epoxy
            color(color_stator_epoxy)
            translate([stator_dia/3 + 1, 0, 0])
            cube([8, 12, stator_length - 2], center=true);
        }
    }
}

module rotor_cup() {
    color(color_rotor)
    difference() {
        union() {
            // Outer bell
            cylinder(d=rotor_dia, h=rotor_length, center=true);
            // Rear hub
            translate([0, 0, -rotor_length/2 - 5])
            cylinder(d=20, h=10, center=true);
        }
        // Hollow interior
        translate([0, 0, 2])
        cylinder(d=rotor_dia - 2*rotor_thickness, h=rotor_length + 2, center=true);
        // Shaft bore
        cylinder(d=shaft_dia, h=100, center=true);
    }
    
    // Magnets inside the cup wall (14 poles)
    for (i = [0:13]) {
        rotate([0, 0, i * (360/14)])
        translate([stator_dia/2 + air_gap + 0.5, 0, 0])
        color(i % 2 == 0 ? color_magnet_n : color_magnet_s)
        cube([1.5, 8, stator_length], center=true);
    }
}

module ceramic_bearing() {
    // Open ZrO2 bearing
    color(color_ceramic)
    difference() {
        cylinder(d=16, h=5, center=true);
        cylinder(d=8, h=6, center=true);
    }
    // Balls representation
    for (i = [0:7]) {
        rotate([0, 0, i * 45])
        translate([6, 0, 0])
        color("White")
        sphere(d=3);
    }
}

module propeller() {
    // Folding hub
    color(color_prop)
    cylinder(d=24, h=12, center=true);
    
    // Blades (folded back slightly for rendering)
    for (dir = [-1, 1]) {
        translate([dir * 12, 0, 0])
        rotate([dir * 15, 5, dir * 90])
        color(color_prop)
        scale([1, 0.1, 0.05])
        translate([0, 100, 0])
        sphere(r=100);
    }
}

// --- ASSEMBLY VIEW ---
// Foil Spar
translate([0, 30, 45]) foil_spar();

// Mounting Collar
mounting_collar();

// Fixed Shaft
color(color_shaft)
cylinder(d=shaft_dia, h=shaft_length, center=true);

// Ceramic Bearings
translate([0, 0, -15]) ceramic_bearing();
translate([0, 0, 15]) ceramic_bearing();

// Stator (Fixed in middle)
stator_core();

// Rotor (Exploded or assembled)
translate([0, 0, -explode]) {
    rotor_cup();
}

// Zinc Anode (on exposed shaft behind rotor)
translate([0, 0, -rotor_length/2 - 12])
color(color_anode)
difference() {
    cylinder(d=16, h=8, center=true);
    cylinder(d=shaft_dia, h=10, center=true);
}

// Propeller (at the bottom/rear shaft end)
translate([0, 0, rotor_length/2 + 25 + explode]) {
    propeller();
}
