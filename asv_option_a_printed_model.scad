// Project Blue-Water Rover ASV - Option A 3D-Printed Modular Variant
//
// This file renders a complete 3D model of the Option A catamaran with modular
// 3D-printed pontoon hulls, incorporating internal bulkheads, interlocking joints,
// and a central stainless steel tension spar.
//
// Enable "show_cutaway = 1" at the top to inspect the internal geometry of the hulls.

$fn = 60; // Curve resolution for rendering performance

// --- DIMENSIONS & CONFIGURATION ---
pvc_od = 219.1;           // 8" PVC Outer Diameter (mm)
hull_length = 2530.0;     // Overall hull length (mm)
overall_beam = 1600.0;    // Overall width of the boat (mm)
hull_spacing = overall_beam - pvc_od; // Center-to-center hull distance (mm)

// Modular Printed Segment parameters
stern_cap_length = 150.0;
bow_cap_length = 180.0;
seg_length = 220.0;       // Length of each of the 10 cylindrical segments (mm)
// Total length: 150 + 180 + 10 * 220 = 2530mm

// Frame Configuration (2020 extrusion)
extrusion_size = 20.0;    
crossbeam_length = 1600.0;
crossbeam_y = [300.0, 900.0, 1500.0, 2100.0];
long_rail_length = 1900.0; 
long_rail_x = [-350.0, 350.0]; 

// Mounting Bracket Parameters (matching pvc_extrusion_bracket.scad preset A)
bracket_width = 140.0;
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

// --- INTERACTION CONTROLS ---
show_cutaway = 1;    // 1 = slice hulls in half to show internal bulkheads & rod
show_hulls = 1;
show_frame = 1;
show_brackets = 1;
show_deck = 1;
show_solar = 1;
show_boxes = 1;
show_thrusters = 1;
show_mast = 1;


// --- MODULES ---

// 1. Modular Printed Segment (Cylindrical hull section)
module printed_segment(id_num) {
    seg_color = (id_num % 2 == 0) ? "white" : "lightgray";
    
    // Outer Shell
    color(seg_color) {
        difference() {
            cylinder(d=pvc_od, h=seg_length);
            translate([0, 0, -1])
                cylinder(d=pvc_od - 6, h=seg_length + 2); // 3mm wall
        }
        
        // Internal Watertight Bulkhead (4mm partition wall in the center)
        difference() {
            translate([0, 0, seg_length/2 - 2])
                cylinder(d=pvc_od - 0.1, h=4);
            // Hole for central tension spar guide sleeve
            translate([0, 0, seg_length/2 - 3])
                cylinder(d=17, h=6);
        }
        
        // Central Tension Rod Sleeve (guide tube for structural spar)
        difference() {
            cylinder(d=26, h=seg_length);
            translate([0, 0, -1])
                cylinder(d=17, h=seg_length + 2);
        }
    }
    
    // 2. Interlocking Joint Collar (colored orange for joint identification)
    color("orangered", 0.8) {
        difference() {
            translate([0, 0, seg_length - 5])
                cylinder(d=pvc_od - 0.2, h=10);
            translate([0, 0, seg_length - 6])
                cylinder(d=pvc_od - 6.2, h=12);
        }
    }
}

// 2. Stern End-Cap (tapered rear with tension nut compartment)
module stern_cap() {
    color("white") {
        difference() {
            // Outer shape
            union() {
                translate([0, stern_cap_length, 0])
                    rotate([90, 0, 0])
                        cylinder(d=pvc_od, h=stern_cap_length - pvc_od/2);
                translate([0, pvc_od/2, 0])
                    sphere(d=pvc_od);
            }
            // Hollow interior
            union() {
                translate([0, stern_cap_length + 1, 0])
                    rotate([90, 0, 0])
                        cylinder(d=pvc_od - 6, h=stern_cap_length - pvc_od/2 + 2);
                translate([0, pvc_od/2, 0])
                    sphere(d=pvc_od - 6);
            }
            // Recess compartment for structural nut and washer
            translate([0, -1, 0])
                rotate([-90, 0, 0])
                    cylinder(d=42, h=25);
        }
        
        // Compression Bulkhead (holds the tension nut)
        difference() {
            translate([0, 20, 0])
                rotate([-90, 0, 0])
                    cylinder(d=pvc_od - 6, h=10);
            translate([0, 19, 0])
                rotate([-90, 0, 0])
                    cylinder(d=17, h=12);
        }
    }
}

// 3. Bow End-Cap (aerodynamic nose cone with tip tension nut compartment)
module bow_cap() {
    color("white") {
        difference() {
            // Outer nose shape
            rotate([-90, 0, 0])
                cylinder(d1=pvc_od, d2=45, h=bow_cap_length);
            // Hollow interior
            translate([0, -1, 0])
                rotate([-90, 0, 0])
                    cylinder(d1=pvc_od - 6, d2=35, h=bow_cap_length - 15);
            // Recessed hole at the tip for rod tension nut
            translate([0, bow_cap_length - 20, 0])
                rotate([-90, 0, 0])
                    cylinder(d=38, h=22);
        }
        
        // Compression Bulkhead at the nose cone tip
        difference() {
            translate([0, bow_cap_length - 25, 0])
                rotate([-90, 0, 0])
                    cylinder(d1=80, d2=45, h=8);
            translate([0, bow_cap_length - 26, 0])
                rotate([-90, 0, 0])
                    cylinder(d=17, h=10);
        }
    }
}

// 4. One Full Assembly of the 3D-Printed Pontoon Hull
module modular_hull() {
    // A. Central Stainless Steel Tension Spar (16mm rod)
    color("silver")
        translate([0, 10, 0])
            rotate([-90, 0, 0])
                cylinder(d=16, h=hull_length - 20);
                
    // B. Hex Tension Nuts on both ends
    color("dimgray") {
        // Stern nut
        translate([0, 10, 0])
            rotate([-90, 30, 0])
                cylinder(d=28, h=10, $fn=6);
        // Bow nut
        translate([0, hull_length - 20, 0])
            rotate([-90, 30, 0])
                cylinder(d=28, h=10, $fn=6);
    }
    
    // C. Stern Cap
    stern_cap();
    
    // D. 10x Printed Cylindrical Segments
    for (i = [0 : 9]) {
        y_pos = stern_cap_length + i * seg_length;
        translate([0, y_pos, 0])
            rotate([-90, 0, 0])
                printed_segment(i);
    }
    
    // E. Bow Cap
    translate([0, hull_length - bow_cap_length, 0])
        bow_cap();
}

// 5. Apply Cutaway view to a single hull assembly (slices longitudinally)
module modular_hull_cutaway() {
    if (show_cutaway) {
        difference() {
            modular_hull();
            // Subtract a large block to slice the hulls along the YZ longitudinal plane
            translate([0, -100, -250])
                cube([300, hull_length + 200, 500]);
        }
    } else {
        modular_hull();
    }
}

// 6. PVC-to-2020 Bracket Module
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

// 7. Rubber sleeve friction pad between PVC hull and bracket
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

// 8. 2020 Aluminum Extrusion Bar
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

// 9. Thruster Module (Differential steering actuators)
module thruster() {
    color("black") {
        rotate([-90, 0, 0])
            cylinder(d=60, h=110, center=true);
        translate([0, -55, 0])
            rotate([90, 0, 0])
                cylinder(d1=60, d2=30, h=25);
        
        difference() {
            translate([0, 20, 0])
                rotate([-90, 0, 0])
                    cylinder(d=95, h=65, center=true);
            translate([0, 20, 0])
                rotate([-90, 0, 0])
                    cylinder(d=85, h=67, center=true);
        }
        
        color("dodgerblue") {
            translate([0, 30, 0]) {
                rotate([-90, 0, 0])
                    cylinder(d=22, h=25, center=true);
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

// 10. Watertight Dry Box Enclosure (Power Vault)
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

// 11. Sensor Mast and Antenna Array
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
    
    // 1. 3D-Printed Modular Hulls (with optional Cutaway view)
    if (show_hulls) {
        // Left Hull
        translate([-hull_spacing/2, 0, 0])
            modular_hull_cutaway();
            
        // Right Hull
        translate([hull_spacing/2, 0, 0])
            modular_hull_cutaway();
    }
    
    // 2. Mounting Brackets (8 in total) and Rubber Friction Sleeves
    if (show_brackets) {
        // Orange brackets
        color("orangered") {
            for (x = [-hull_spacing/2, hull_spacing/2]) {
                for (y = crossbeam_y) {
                    translate([x, y, 0])
                        pvc_2020_bracket();
                }
            }
        }
        // Black rubber dampening sleeves under brackets
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
        color("lightcyan", 0.6) { // Translucent deck sheet
            translate([-deck_w/2, crossbeam_y[0] - 50, deck_z])
                cube([deck_w, deck_l, deck_th]);
        }
    }
    
    // 5. Flexible Solar Panels (8 panels, 4x2 grid)
    panel_w = 540;
    panel_l = 1050;
    panel_th = 3;
    
    if (show_solar) {
        translate([0, 0, deck_z + deck_th]) {
            for (row = [0 : 1]) {
                for (col = [0 : 3]) {
                    x_pos = - (4 * panel_w)/2 + col * panel_w + 5 * col + 10;
                    y_pos = crossbeam_y[0] + row * panel_l + 10 * row + 30;
                    
                    translate([x_pos, y_pos, 0]) {
                        // Blue Solar cells
                        color("midnightblue")
                            cube([panel_w - 10, panel_l - 10, panel_th]);
                        // White border
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
        // Battery box
        translate([0, 800, frame_z + 20 + 90])
            dry_box();
        // Avionics box
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
        translate([0, 2100, deck_z])
            sensor_mast();
    }
}

// Instantiate the full assembly
asv_assembly();
