// Project Blue-Water Rover ASV - Option A (2.53m Proportional Scale Catamaran)
//
// This file renders a complete, parametric 3D model of the Option A catamaran,
// incorporating PVC hulls, 2020 aluminum extrusion frame, 3D printed brackets,
// Coroplast deck, flexible solar panels, power boxes, thrusters, and mast.
//
// Open this file in OpenSCAD (https://openscad.org) to view the assembly.

$fn = 60; // Curve resolution for rendering performance

// --- DIMENSIONS & CONFIGURATION ---
// Option A specific parameters
pvc_od = 219.1;           // 8" Schedule 40 PVC Outer Diameter (mm)
hull_length = 2530.0;     // Hull length (mm)
overall_beam = 1600.0;    // Overall width of the boat (mm)
hull_spacing = overall_beam - pvc_od; // Center-to-center hull distance (mm)

// Frame Configuration (2020 extrusion)
extrusion_size = 20.0;    // 20mm x 20mm extrusion
crossbeam_length = 1600.0;
num_crossbeams = 4;
// Y positions of the four transverse crossbeams
crossbeam_y = [300.0, 900.0, 1500.0, 2100.0];

// Longitudinal rails
long_rail_length = 1900.0; // Spans from rear to front crossbeams
long_rail_x = [-350.0, 350.0]; // Extrusions to mount dry boxes & support deck

// Mounting Bracket Parameters (matching pvc_extrusion_bracket.scad preset A)
bracket_width = 140.0;
bracket_length = 50.0;
cradle_depth = 15.0;
top_thickness = 15.0;
extrusion_width = 20.2;
extrusion_depth = 3.0;

// Thickness of rubber friction/dampening strip between bracket and PVC (mm)
rubber_thickness = 1.5;

// Calculated Z-offsets
pipe_radius = pvc_od / 2 + rubber_thickness;
block_top_z = pipe_radius + top_thickness; // Top surface of mounting bracket
frame_z = block_top_z - extrusion_depth;   // Z coordinate of frame bottom
deck_z = frame_z + extrusion_size;         // Z coordinate of deck surface

// Display Controls (1 = show, 0 = hide)
show_hulls = 1;
show_frame = 1;
show_brackets = 1;
show_deck = 1;
show_solar = 1;
show_boxes = 1;
show_thrusters = 1;
show_mast = 1;


// --- MODULES ---

// 1. PVC-to-2020 Bracket Module (Redefined locally to avoid scope conflicts)
module pvc_2020_bracket() {
    bolt_diameter = 5.3;
    counterbore_diameter = 9.5;
    counterbore_depth = 7.0;
    clamp_width = 14.5;
    clamp_thickness = 3.0;
    
    block_bottom_z = pipe_radius - cradle_depth;
    block_height = block_top_z - block_bottom_z;
    
    difference() {
        // Main block
        translate([-bracket_width/2, -bracket_length/2, block_bottom_z])
            cube([bracket_width, bracket_length, block_height]);
        
        // PVC hull cutout
        translate([0, -bracket_length/2 - 1, 0])
            rotate([-90, 0, 0])
                cylinder(r=pipe_radius, h=bracket_length + 2);
        
        // Extrusion slot
        translate([-extrusion_width/2, -bracket_length/2 - 1, block_top_z - extrusion_depth])
            cube([extrusion_width, bracket_length + 2, extrusion_depth + 1]);
        
        // Mounting bolt holes
        for (y_offset = [-12.5, 12.5]) {
            translate([0, y_offset, block_bottom_z - 1])
                cylinder(d=bolt_diameter, h=block_height + 2);
            translate([0, y_offset, block_top_z - counterbore_depth])
                cylinder(d=counterbore_diameter, h=counterbore_depth + 1);
        }
        
        // Hose clamp channel
        translate([0, -clamp_width/2, 0])
            rotate([-90, 0, 0])
                difference() {
                    cylinder(r=pipe_radius + clamp_thickness, h=clamp_width);
                    translate([0, 0, -1])
                        cylinder(r=pipe_radius, h=clamp_width + 2);
                }
    }
}

// 2. 2020 Aluminum Extrusion Bar
module aluminum_extrusion(length) {
    color("silver") {
        difference() {
            // Main solid bar
            cube([extrusion_size, length, extrusion_size]);
            
            // Subtract grooves on 4 sides (T-slots) for realism
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

// 3. PVC Hull Pontoon with Domed End Caps
module pvc_hull() {
    color("white") {
        // Main cylinder body
        translate([0, pipe_radius, 0])
            rotate([-90, 0, 0])
                cylinder(r=pipe_radius, h=hull_length - pvc_od);
        
        // Rear domed end-cap
        translate([0, pipe_radius, 0])
            sphere(r=pipe_radius);
        
        // Front domed end-cap
        translate([0, hull_length - pipe_radius, 0])
            sphere(r=pipe_radius);
    }
}

// 4. Thruster Module (resembling BlueRobotics T200)
module thruster() {
    color("black") {
        // Main motor body
        rotate([-90, 0, 0])
            cylinder(d=60, h=110, center=true);
        // Motor nose cone
        translate([0, -55, 0])
            rotate([90, 0, 0])
                cylinder(d1=60, d2=30, h=25);
        
        // Shroud/nozzle surrounding the prop
        difference() {
            translate([0, 20, 0])
                rotate([-90, 0, 0])
                    cylinder(d=95, h=65, center=true);
            translate([0, 20, 0])
                rotate([-90, 0, 0])
                    cylinder(d=85, h=67, center=true);
        }
        
        // Propeller hub and blades
        color("dodgerblue") {
            translate([0, 30, 0]) {
                rotate([-90, 0, 0])
                    cylinder(d=22, h=25, center=true);
                // 3 blades
                for (angle = [0, 120, 240]) {
                    rotate([0, angle, 0])
                        translate([0, 0, 10])
                            cube([10, 35, 2], center=true);
                }
            }
        }
    }
    
    // Acetal/PETG Mounting Bracket to PVC Hull
    color("dimgray") {
        translate([0, -20, 45])
            cube([25, 60, 50], center=true);
        translate([0, -20, 75])
            cube([bracket_width, 15, 15], center=true);
    }
}

// 5. Watertight Dry Box Enclosure (Power Vault)
module dry_box() {
    box_w = 400;
    box_l = 300;
    box_h = 180;
    
    color("dimgray", 0.9) {
        // Base container
        difference() {
            cube([box_w, box_l, box_h], center=true);
            translate([0, 0, 5])
                cube([box_w - 10, box_l - 10, box_h], center=true);
        }
        // Snap-lock lid
        translate([0, 0, box_h/2 + 2])
            cube([box_w + 10, box_l + 10, 8], center=true);
        
        // Lock latches (colored blue)
        color("dodgerblue") {
            for (x_offset = [-box_w/2 - 4, box_w/2 + 4]) {
                translate([x_offset, 0, box_h/2 - 10])
                    cube([6, 50, 30], center=true);
            }
        }
    }
}

// 6. Sensor Mast and Antenna Array
module sensor_mast() {
    mast_h = 1200;
    mast_d = 25;
    
    // Carbon fiber mast pole
    color("darkslategray") {
        cylinder(d=mast_d, h=mast_h);
    }
    
    // Top mount platform
    color("black") {
        translate([0, 0, mast_h])
            cylinder(d=100, h=10);
    }
    
    // White RTK-GPS Dome
    color("white") {
        translate([-25, 0, mast_h + 10])
            cylinder(d=80, h=30);
    }
    
    // LoRa Whip Antenna
    color("black") {
        translate([30, 20, mast_h + 10])
            cylinder(d=5, h=250);
        translate([30, 20, mast_h + 10])
            cylinder(d=12, h=30); // base
    }
    
    // Optical Avoidance Camera Box
    color("gray") {
        translate([0, -40, mast_h + 20]) {
            cube([40, 40, 40], center=true);
            // Camera lens
            color("black")
                translate([0, -21, 0])
                    rotate([-90, 0, 0])
                        cylinder(d=15, h=3);
        }
    }
}

// 7. Rubber Friction & Dampening Sleeve between Hull and Bracket
module rubber_sleeve() {
    color("black") {
        rotate([-90, 0, 0])
            difference() {
                // outer sleeve matching bracket cradle cutout radius
                cylinder(r=pvc_od/2 + rubber_thickness, h=bracket_length, center=true);
                // inner sleeve fitting tightly on PVC OD
                translate([0, 0, -1])
                    cylinder(r=pvc_od/2, h=bracket_length + 2, center=true);
            }
    }
}


// --- MAIN ASSEMBLY ---
module asv_assembly() {
    
    // 1. PVC Hulls
    if (show_hulls) {
        translate([-hull_spacing/2, 0, 0]) pvc_hull();
        translate([hull_spacing/2, 0, 0]) pvc_hull();
    }
    
    // 2. Mounting Brackets (8 in total) and Rubber Sleeves
    if (show_brackets) {
        // Brackets
        color("orangered") {
            for (x = [-hull_spacing/2, hull_spacing/2]) {
                for (y = crossbeam_y) {
                    translate([x, y, 0])
                        pvc_2020_bracket();
                }
            }
        }
        // Rubber sleeves sitting directly inside the bracket cradle cutouts
        for (x = [-hull_spacing/2, hull_spacing/2]) {
            for (y = crossbeam_y) {
                translate([x, y, 0])
                    rubber_sleeve();
            }
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
    
    // 4. Coroplast Deck
    deck_w = 1600;
    deck_l = 2000;
    deck_th = 4;
    
    if (show_deck) {
        color("lightcyan", 0.6) { // Translucent Coroplast sheet
            translate([-deck_w/2, crossbeam_y[0] - 50, deck_z])
                cube([deck_w, deck_l, deck_th]);
        }
    }
    
    // 5. Flexible Solar Panels (8 panels arranged in a 4x2 grid)
    // Individual panel dimensions: 1050mm x 540mm
    panel_w = 540;
    panel_l = 1050;
    panel_th = 3;
    
    if (show_solar) {
        // Lay panels on top of the deck.
        // We arrange them 4 panels wide (4 * 540mm = 2160mm) and 2 panels long (2 * 1050mm = 2100mm).
        // To center them over the deck:
        translate([0, 0, deck_z + deck_th]) {
            for (row = [0 : 1]) {
                for (col = [0 : 3]) {
                    x_pos = - (4 * panel_w)/2 + col * panel_w + 5 * col + 10;
                    y_pos = crossbeam_y[0] + row * panel_l + 10 * row + 30;
                    
                    translate([x_pos, y_pos, 0]) {
                        // Blue Solar cell area
                        color("midnightblue")
                            cube([panel_w - 10, panel_l - 10, panel_th]);
                        // White panel border
                        color("ghostwhite")
                            difference() {
                                cube([panel_w, panel_l, panel_th - 0.2]);
                                translate([5, 5, -0.5])
                                    cube([panel_w - 10, panel_l - 10, panel_th + 1]);
                            }
                    }
                }
            }
        }
    }
    
    // 6. Waterproof Power Vaults (Dual Dry Boxes)
    if (show_boxes) {
        // Box 1 (Batteries): Placed forward center
        translate([0, 800, frame_z + 20 + 90])
            dry_box();
            
        // Box 2 (AV & Controller): Placed aft center
        translate([0, 1400, frame_z + 20 + 90])
            dry_box();
    }
    
    // 7. Propulsion Thrusters (Stern of each hull)
    if (show_thrusters) {
        translate([-hull_spacing/2, -80, -100])
            thruster();
        translate([hull_spacing/2, -80, -100])
            thruster();
    }
    
    // 8. Mast and Sensor Rig
    if (show_mast) {
        // Mounted on the front crossbeam, centerline
        translate([0, 2100, deck_z])
            sensor_mast();
    }
}

// Instantiate the full Option A ship assembly
asv_assembly();
