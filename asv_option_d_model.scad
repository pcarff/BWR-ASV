// Project Blue-Water Rover ASV - Option D (Keel-Stabilized Narrow Catamaran)
//
// This file renders a complete 3D model of the Option D design, which integrates
// two narrow outer stabilizing pontoons, a central slung ballast keel housing
// the heavy battery bank, a single centerline stern thruster, and a mechanical steering rudder.
//
// Open this file in OpenSCAD (https://openscad.org) to view the assembly.

$fn = 60; // Curve resolution for rendering performance

// --- DIMENSIONS & CONFIGURATION ---
pvc_od = 168.3;           // 6" PVC Outer Diameter (mm)
hull_length = 2530.0;     // Hulls length (mm)
overall_beam = 1000.0;    // Narrow beam width (mm)
hull_spacing = overall_beam - pvc_od; // Outer hulls spacing center-to-center (mm)
keel_z_offset = -120.0;   // Vertical distance central keel is slung below outer pontoons (mm)

// Frame Configuration (2020 extrusion)
extrusion_size = 20.0;    
crossbeam_length = 1000.0;
crossbeam_y = [300.0, 900.0, 1500.0, 2100.0];
long_rail_length = 1900.0; 
long_rail_x = [-250.0, 250.0]; 

// Mounting Bracket Parameters (matching pvc_extrusion_bracket.scad preset B)
bracket_width = 110.0;
bracket_length = 50.0;
cradle_depth = 15.0;
top_thickness = 15.0;
extrusion_width = 20.2;
extrusion_depth = 3.0;

// Thickness of rubber friction/dampening strip (mm)
rubber_thickness = 1.5;

// Calculated Z-offsets
pipe_radius = pvc_od / 2 + rubber_thickness;
block_top_z = pipe_radius + top_thickness; 
frame_z = block_top_z - extrusion_depth;   
deck_z = frame_z + extrusion_size;         

// Display Controls
show_hulls = 1;
show_frame = 1;
show_brackets = 1;
show_deck = 1;
show_solar = 1;
show_boxes = 1;
show_propulsion = 1;
show_mast = 1;


// --- MODULES ---

// 1. standard PVC-to-2020 Bracket (Lined with rubber)
module pvc_2020_bracket() {
    bolt_diameter = 5.3;
    counterbore_diameter = 9.5;
    counterbore_depth = 7.0;
    clamp_width = 14.5;
    clamp_thickness = 3.0;
    
    block_bottom_z = pipe_radius - cradle_depth;
    block_height = block_top_z - block_bottom_z;
    
    difference() {
        translate([-bracket_width/2, -bracket_length/2, block_bottom_z])
            cube([bracket_width, bracket_length, block_height]);
        
        translate([0, -bracket_length/2 - 1, 0])
            rotate([-90, 0, 0])
                cylinder(r=pipe_radius, h=bracket_length + 2);
        
        translate([-extrusion_width/2, -bracket_length/2 - 1, block_top_z - extrusion_depth])
            cube([extrusion_width, bracket_length + 2, extrusion_depth + 1]);
        
        for (y_offset = [-12.5, 12.5]) {
            translate([0, y_offset, block_bottom_z - 1])
                cylinder(d=bolt_diameter, h=block_height + 2);
            translate([0, y_offset, block_top_z - counterbore_depth])
                cylinder(d=counterbore_diameter, h=counterbore_depth + 1);
        }
        
        translate([0, -clamp_width/2, 0])
            rotate([-90, 0, 0])
                difference() {
                    cylinder(r=pipe_radius + clamp_thickness, h=clamp_width);
                    translate([0, 0, -1])
                        cylinder(r=pipe_radius, h=clamp_width + 2);
                }
    }
}

// 2. Custom Drop Hanger Bracket for Suspended Keel
module keel_drop_bracket() {
    hanger_width = 40.0;
    hanger_thick = 15.0;
    drop_h = abs(keel_z_offset) + cradle_depth;
    
    color("dimgray") {
        difference() {
            // Main vertical drop block
            translate([-hanger_width/2, -bracket_length/2, keel_z_offset])
                cube([hanger_width, bracket_length, drop_h + block_top_z]);
            
            // Central keel pipe cutout
            translate([0, -bracket_length/2 - 1, keel_z_offset])
                rotate([-90, 0, 0])
                    cylinder(r=pipe_radius, h=bracket_length + 2);
            
            // Top crossbeam extrusion slot
            translate([-extrusion_width/2, -bracket_length/2 - 1, block_top_z - extrusion_depth])
                cube([extrusion_width, bracket_length + 2, extrusion_depth + 1]);
            
            // Mounting bolt holes to top extrusion
            for (y_offset = [-12.5, 12.5]) {
                translate([0, y_offset, keel_z_offset - 1])
                    cylinder(d=5.3, h=drop_h + block_top_z + 2);
            }
        }
    }
}

// 3. Rubber sleeve pad
module rubber_sleeve() {
    color("black") {
        rotate([-90, 0, 0])
            difference() {
                cylinder(r=pvc_od/2 + rubber_thickness, h=bracket_length, center=true);
                translate([0, 0, -1])
                    cylinder(r=pvc_od/2, h=bracket_length + 2, center=true);
            }
    }
}

// 4. PVC Hull Pontoon with Domed End Caps
module pvc_hull() {
    color("white") {
        translate([0, pipe_radius, 0])
            rotate([-90, 0, 0])
                cylinder(r=pvc_od/2, h=hull_length - pvc_od);
        
        translate([0, pipe_radius, 0])
            sphere(r=pvc_od/2);
        
        translate([0, hull_length - pipe_radius, 0])
            sphere(r=pvc_od/2);
    }
}

// 5. 2020 Aluminum Extrusion Bar
module aluminum_extrusion(length) {
    color("silver") {
        difference() {
            cube([extrusion_size, length, extrusion_size]);
            groove_w = 6.0;
            groove_d = 5.0;
            
            // Top groove
            translate([extrusion_size/2 - groove_w/2, -1, extrusion_size - groove_d])
                cube([groove_w, length + 2, groove_d + 1]);
            // Bottom groove
            translate([extrusion_size/2 - groove_w/2, -1, -1])
                cube([groove_w, length + 2, groove_d + 1]);
            // Left groove
            translate([-1, extrusion_size/2 - groove_w/2, extrusion_size/2 - groove_w/2])
                cube([groove_d + 1, length + 2, groove_w]);
            // Right groove
            translate([extrusion_size - groove_d, -1, extrusion_size/2 - groove_w/2])
                cube([groove_d + 1, length + 2, groove_w]);
        }
    }
}

// 6. Single Stern Thruster & Delrin Mechanical Rudder Assembly
module centerline_thruster_and_rudder() {
    // A. Brushless Thruster Pod
    color("black") {
        translate([0, -40, 0]) {
            rotate([-90, 0, 0])
                cylinder(d=55, h=100, center=true);
            translate([0, -50, 0])
                rotate([90, 0, 0])
                    cylinder(d1=55, d2=25, h=20);
            
            // Shroud
            difference() {
                translate([0, 20, 0])
                    rotate([-90, 0, 0])
                        cylinder(d=90, h=60, center=true);
                translate([0, 20, 0])
                    rotate([-90, 0, 0])
                        cylinder(d=80, h=62, center=true);
            }
        }
        
        // Propeller
        color("dodgerblue") {
            translate([0, -10, 0]) {
                rotate([-90, 0, 0])
                    cylinder(d=20, h=20, center=true);
                for (angle = [0, 120, 240]) {
                    rotate([0, angle, 0])
                        translate([0, 0, 10])
                            cube([8, 30, 2], center=true);
                }
            }
        }
    }
    
    // B. Stern Mounting Hanger Bracket to Keel
    color("dimgray") {
        translate([0, -10, 45])
            cube([20, 40, 50], center=true);
        translate([0, -10, 75])
            cube([bracket_width - 20, 12, 12], center=true);
    }
    
    // C. Delrin Rudder Assembly
    // Rudder shaft & hinge
    color("silver") {
        translate([0, -90, 40])
            cylinder(d=10, h=110, center=true);
    }
    // Rudder Blade
    color("darkslategray") {
        translate([0, -130, -10])
            cube([6, 80, 100], center=true);
    }
}

// 7. Watertight Dry Box Enclosure
module dry_box() {
    box_w = 400;
    box_l = 300;
    box_h = 180;
    
    color("dimgray", 0.9) {
        difference() {
            cube([box_w, box_l, box_h], center=true);
            translate([0, 0, 5])
                cube([box_w - 10, box_l - 10, box_h], center=true);
        }
        translate([0, 0, box_h/2 + 2])
            cube([box_w + 10, box_l + 10, 8], center=true);
        
        color("dodgerblue") {
            for (x_offset = [-box_w/2 - 4, box_w/2 + 4]) {
                translate([x_offset, 0, box_h/2 - 10])
                    cube([6, 50, 30], center=true);
            }
        }
    }
}

// 8. Sensor Mast and Antenna Array
module sensor_mast() {
    mast_h = 1200;
    mast_d = 25;
    
    color("darkslategray") {
        cylinder(d=mast_d, h=mast_h);
    }
    color("black") {
        translate([0, 0, mast_h])
            cylinder(d=100, h=10);
    }
    color("white") {
        translate([-25, 0, mast_h + 10])
            cylinder(d=80, h=30);
    }
    color("black") {
        translate([30, 20, mast_h + 10])
            cylinder(d=5, h=250);
        translate([30, 20, mast_h + 10])
            cylinder(d=12, h=30); // base
    }
    color("gray") {
        translate([0, -40, mast_h + 20]) {
            cube([40, 40, 40], center=true);
            color("black")
                translate([0, -21, 0])
                    rotate([-90, 0, 0])
                        cylinder(d=15, h=3);
        }
    }
}


// --- MAIN ASSEMBLY ---
module asv_assembly() {
    
    // 1. Hulls (Triple-tube configuration)
    if (show_hulls) {
        // Left Outer Pontoon
        translate([-hull_spacing/2, 0, 0]) pvc_hull();
        // Right Outer Pontoon
        translate([hull_spacing/2, 0, 0]) pvc_hull();
        
        // Central Submerged Keel Tube (Houses heavy battery bank)
        translate([0, 0, keel_z_offset]) pvc_hull();
    }
    
    // 2. Mounting Brackets & Rubber Sleeves
    if (show_brackets) {
        // standard brackets on outer hulls (orange)
        color("orangered") {
            for (x = [-hull_spacing/2, hull_spacing/2]) {
                for (y = crossbeam_y) {
                    translate([x, y, 0])
                        pvc_2020_bracket();
                }
            }
        }
        // Black rubber sleeves under standard brackets
        for (x = [-hull_spacing/2, hull_spacing/2]) {
            for (y = crossbeam_y) {
                translate([x, y, 0])
                    rubber_sleeve();
            }
        }
        
        // Drop hanger brackets suspending the central keel
        for (y = crossbeam_y) {
            translate([0, y, 0])
                keel_drop_bracket();
        }
        // Black rubber sleeve under drop brackets on central keel
        for (y = crossbeam_y) {
            translate([0, y, keel_z_offset])
                rubber_sleeve();
        }
    }
    
    // 3. Extrusion Frame
    if (show_frame) {
        // Four transverse crossbeams
        for (y = crossbeam_y) {
            translate([-crossbeam_length/2, y - extrusion_size/2, frame_z])
                rotate([0, 90, 0])
                    aluminum_extrusion(crossbeam_length);
        }
        // Longitudinal rails
        for (x = long_rail_x) {
            translate([x - extrusion_size/2, crossbeam_y[0], frame_z + extrusion_size])
                aluminum_extrusion(long_rail_length);
        }
    }
    
    // 4. Overhanging Coroplast Deck
    // Deck is wider than hulls to maximize solar area on a narrow beam
    deck_w = 1400; // Overhangs frame by 200mm on each side
    deck_l = 2000;
    deck_th = 4;
    
    if (show_deck) {
        color("lightcyan", 0.6) { 
            translate([-deck_w/2, crossbeam_y[0] - 50, deck_z])
                cube([deck_w, deck_l, deck_th]);
        }
    }
    
    // 5. Flexible Solar Panels (8 panels in a 4x2 grid)
    panel_w = 340;  // slightly smaller visualization footprint to fit 1.4m deck width
    panel_l = 950;
    panel_th = 3;
    
    if (show_solar) {
        translate([0, 0, deck_z + deck_th]) {
            for (row = [0 : 1]) {
                for (col = [0 : 3]) {
                    x_pos = - (4 * panel_w)/2 + col * panel_w + 5 * col + 10;
                    y_pos = crossbeam_y[0] + row * panel_l + 10 * row + 30;
                    
                    translate([x_pos, y_pos, 0]) {
                        // Blue cells
                        color("midnightblue")
                            cube([panel_w - 8, panel_l - 8, panel_th]);
                        // White border
                        color("ghostwhite")
                            difference() {
                                cube([panel_w, panel_l, panel_th - 0.2]);
                                translate([4, 4, -0.5])
                                    cube([panel_w - 8, panel_l - 8, panel_th + 1]);
                            }
                    }
                }
            }
        }
    }
    
    // 6. Waterproof Electronics Box (Aft Center)
    if (show_boxes) {
        translate([0, 1600, frame_z + 20 + 90])
            dry_box();
    }
    
    // 7. Centerline Propulsion & Steering Rudder (SeaCharger style)
    if (show_propulsion) {
        translate([0, -80, keel_z_offset])
            centerline_thruster_and_rudder();
    }
    
    // 8. Mast and Sensor Rig
    if (show_mast) {
        translate([0, 2100, deck_z])
            sensor_mast();
    }
}

// Instantiate Option D assembly
asv_assembly();
