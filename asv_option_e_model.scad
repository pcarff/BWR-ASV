// Project Blue-Water Rover ASV - Option E (Keel-Bulb Stabilized Catamaran)
//
// This file renders a complete 3D model of the Option E design, which integrates:
// 1. Two touching 6" PVC outboard pontoons.
// 2. A 3D-printed dual-nosed aerodynamic bow cap.
// 3. A vertical 3" PVC keel fin (wiring conduit) slung centerline.
// 4. A submerged central keel bulb (140mm diameter capsule) housing the battery bank.
// 5. A single thruster and mechanical rudder mounted directly to the keel bulb.
//
// Open this file in OpenSCAD (https://openscad.org) to view the assembly.

$fn = 60; // Curve resolution for rendering performance

// --- DIMENSIONS & CONFIGURATION ---
pvc_od = 168.3;           // 6" PVC Outer Diameter (mm)
hull_length = 2530.0;     // Hulls length (mm)
overall_beam = 1000.0;    // Narrow beam width (mm)
hull_spacing = pvc_od;    // Hulls are touching center-to-center (mm)
keel_z_offset = -450.0;   // Vertical depth of the keel bulb center (mm)

// Keel Bulb Sizing
bulb_diameter = 140.0;
bulb_length = 900.0;
bulb_y_center = 1200.0;   // Positioned slightly aft-center for optimal trim

// Frame Configuration (2020 extrusion)
extrusion_size = 20.0;    
crossbeam_length = 1000.0;
crossbeam_y = [300.0, 900.0, 1500.0, 2100.0];
long_rail_length = 1900.0; 
long_rail_x = [-200.0, 200.0]; 

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

// 1. PVC-to-2020 Bracket (clamps touching outer hulls to frame)
module double_hull_bracket() {
    bolt_diameter = 5.3;
    counterbore_diameter = 9.5;
    counterbore_depth = 7.0;
    
    block_w = pvc_od * 2 + 30; // Spans both touching hulls
    block_bottom_z = pipe_radius - cradle_depth;
    block_height = block_top_z - block_bottom_z;
    
    difference() {
        // Main block spanning both pontoons
        translate([-block_w/2, -bracket_length/2, block_bottom_z])
            cube([block_w, bracket_length, block_height]);
        
        // Left hull cutout
        translate([-hull_spacing/2, -bracket_length/2 - 1, 0])
            rotate([-90, 0, 0])
                cylinder(r=pipe_radius, h=bracket_length + 2);
        
        // Right hull cutout
        translate([hull_spacing/2, -bracket_length/2 - 1, 0])
            rotate([-90, 0, 0])
                cylinder(r=pipe_radius, h=bracket_length + 2);
        
        // Top extrusion slot
        translate([-extrusion_width/2, -bracket_length/2 - 1, block_top_z - extrusion_depth])
            cube([extrusion_width, bracket_length + 2, extrusion_depth + 1]);
        
        // Mounting bolt holes
        for (x_offset = [-hull_spacing/2, hull_spacing/2]) {
            for (y_offset = [-12.5, 12.5]) {
                translate([x_offset, y_offset, block_bottom_z - 1])
                    cylinder(d=bolt_diameter, h=block_height + 2);
                translate([x_offset, y_offset, block_top_z - counterbore_depth])
                    cylinder(d=counterbore_diameter, h=counterbore_depth + 1);
            }
        }
    }
}

// 2. Rubber sleeve pad for double hulls
module double_rubber_sleeve() {
    color("black") {
        for (x = [-hull_spacing/2, hull_spacing/2]) {
            translate([x, 0, 0])
                rotate([-90, 0, 0])
                    difference() {
                        cylinder(r=pvc_od/2 + rubber_thickness, h=bracket_length, center=true);
                        translate([0, 0, -1])
                            cylinder(r=pvc_od/2, h=bracket_length + 2, center=true);
                    }
        }
    }
}

// 3. Custom 3D-Printed Bow Cap (Aerodynamic dual-nosed piece)
module printed_double_bow_cap() {
    color("orangered") { // Orange printed parts visual identity
        difference() {
            // Main solid body wrapping the nose of both pipes
            hull() {
                translate([-hull_spacing/2, 2380, 0])
                    rotate([-90, 0, 0])
                        cylinder(d=pvc_od, h=30);
                translate([hull_spacing/2, 2380, 0])
                    rotate([-90, 0, 0])
                        cylinder(d=pvc_od, h=30);
                
                // Taper to aerodynamic nose tips
                translate([-hull_spacing/2, 2530, 0])
                    sphere(d=40);
                translate([hull_spacing/2, 2530, 0])
                    sphere(d=40);
            }
            
            // Subtract hollow cavities for the PVC pipe ends to slide inside
            translate([-hull_spacing/2, 2370, 0])
                rotate([-90, 0, 0])
                    cylinder(d=pvc_od - 4, h=50);
            translate([hull_spacing/2, 2370, 0])
                rotate([-90, 0, 0])
                    cylinder(d=pvc_od - 4, h=50);
        }
    }
}

// 4. Custom 3D-Printed Keel Bulb Nose Cone
module printed_bulb_nose_cone() {
    color("orangered") {
        difference() {
            // Tapered nose shape
            rotate([-90, 0, 0])
                cylinder(d1=bulb_diameter, d2=30, h=150);
            // Hollow inner cavity
            translate([0, -1, 0])
                rotate([-90, 0, 0])
                    cylinder(d1=bulb_diameter - 6, d2=20, h=135);
        }
    }
}

// 5. Vertical Keel Fin Foil & Root Clamps (PVC conduit + printed foil shell)
module keel_fin_and_root() {
    fin_top_z = -pvc_od/2 + 20;
    fin_bottom_z = keel_z_offset + bulb_diameter/2 - 10;
    fin_h = fin_top_z - fin_bottom_z;
    
    // A. 3D-Printed Keel Root Collar (clamps fin between pontoons)
    color("orangered") {
        difference() {
            // Block filling gap and wrapping outer hulls
            translate([-50, 1265 - 50, -pvc_od/2 - 10])
                cube([100, 100, 60]);
            
            // Outer hull cutouts
            translate([-hull_spacing/2, 1265, 0])
                rotate([-90, 0, 0])
                    cylinder(d=pvc_od + 1, h=102, center=true);
            translate([hull_spacing/2, 1265, 0])
                rotate([-90, 0, 0])
                    cylinder(d=pvc_od + 1, h=102, center=true);
            
            // Vertical 3" PVC fin pipe hole
            translate([0, 1265, -pvc_od/2 - 15])
                cylinder(d=89.5, h=70);
        }
    }
    
    // B. Vertical 3" PVC Fin (wiring conduit)
    color("lightgray") {
        translate([0, 1265, fin_bottom_z])
            cylinder(d=88.9, h=fin_h);
    }
    
    // C. Aerodynamic Hydrofoil Fin Shroud (printed)
    color("orangered", 0.7) {
        difference() {
            // Foil shape wrapping the fin
            hull() {
                translate([0, 1265 - 60, fin_bottom_z + 20])
                    cylinder(d=20, h=fin_h - 40);
                translate([0, 1265 + 30, fin_bottom_z + 20])
                    cylinder(d=95, h=fin_h - 40);
                translate([0, 1265 + 100, fin_bottom_z + 20])
                    cylinder(d=10, h=fin_h - 40); // trailing edge
            }
            // Inner 3" pipe cutout
            translate([0, 1265, fin_bottom_z + 10])
                cylinder(d=90, h=fin_h);
        }
    }
}

// 6. Submerged Central Keel Bulb (Houses batteries, motor & rudder attached)
module keel_bulb() {
    cyl_len = bulb_length - 200; // body length excluding caps
    
    translate([0, bulb_y_center, keel_z_offset]) {
        // A. Main Cylinder body
        color("white") {
            difference() {
                translate([0, -cyl_len/2, 0])
                    rotate([-90, 0, 0])
                        cylinder(d=bulb_diameter, h=cyl_len);
                // Hollow cavity for batteries
                translate([0, -cyl_len/2 - 1, 0])
                    rotate([-90, 0, 0])
                        cylinder(d=bulb_diameter - 6, h=cyl_len + 2);
            }
        }
        
        // B. 3D-Printed Aerodynamic Nose Cone (front)
        translate([0, cyl_len/2, 0])
            printed_bulb_nose_cone();
            
        // C. Stern Cap (rear)
        color("white") {
            difference() {
                translate([0, -cyl_len/2, 0])
                    rotate([90, 0, 0])
                        cylinder(d=bulb_diameter, h=50);
                translate([0, -cyl_len/2 + 1, 0])
                    rotate([90, 0, 0])
                        cylinder(d=bulb_diameter - 6, h=52);
            }
            // Rounded dome end
            translate([0, -cyl_len/2 - 50, 0])
                difference() {
                    sphere(d=bulb_diameter);
                    translate([-bulb_diameter, -bulb_diameter, -bulb_diameter])
                        cube([bulb_diameter*2, bulb_diameter, bulb_diameter*2]);
                }
        }
        
        // D. Propulsion Thruster & Rudder mounted directly to Keel Bulb Stern
        translate([0, -cyl_len/2 - 80, 0]) {
            // Brushless thruster
            color("black") {
                rotate([-90, 0, 0])
                    cylinder(d=55, h=100, center=true);
                translate([0, -50, 0])
                    rotate([90, 0, 0])
                        cylinder(d1=55, d2=25, h=20);
                
                difference() {
                    translate([0, 20, 0])
                        rotate([-90, 0, 0])
                            cylinder(d=90, h=60, center=true);
                    translate([0, 20, 0])
                        rotate([-90, 0, 0])
                            cylinder(d=80, h=62, center=true);
                }
                
                // Mounting connection to bulb dome
                translate([0, 45, 0])
                    rotate([-90, 0, 0])
                        cylinder(d=22, h=40);
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
            
            // Delrin Rudder blade directly behind thruster
            color("silver") { // Shaft
                translate([0, -85, 30])
                    cylinder(d=8, h=100, center=true);
            }
            color("darkslategray") { // Blade
                translate([0, -120, -10])
                    cube([6, 70, 90], center=true);
            }
        }
    }
}

// 7. 2020 Aluminum Extrusion Bar
module aluminum_extrusion(length) {
    color("silver") {
        difference() {
            cube([extrusion_size, length, extrusion_size]);
            groove_w = 6.0;
            groove_d = 5.0;
            
            translate([extrusion_size/2 - groove_w/2, -1, extrusion_size - groove_d])
                cube([groove_w, length + 2, groove_d + 1]);
            translate([extrusion_size/2 - groove_w/2, -1, -1])
                cube([groove_w, length + 2, groove_d + 1]);
            translate([-1, extrusion_size/2 - groove_w/2, extrusion_size/2 - groove_w/2])
                cube([groove_d + 1, length + 2, groove_w]);
            translate([extrusion_size - groove_d, -1, extrusion_size/2 - groove_w/2])
                cube([groove_d + 1, length + 2, groove_w]);
        }
    }
}

// 8. Watertight Enclosure (Avionics / MPPT deck box)
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

// 9. Sensor Mast
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
            cylinder(d=12, h=30);
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
    
    // 1. Outboard Pontoons (Touching parallel cylinders)
    if (show_hulls) {
        // Left Pontoon
        translate([-hull_spacing/2, 0, 0]) {
            // Main cylinder body (excluding bow cap)
            color("white")
                translate([0, pipe_radius, 0])
                    rotate([-90, 0, 0])
                        cylinder(r=pvc_od/2, h=hull_length - pvc_od - 150);
            // Stern end cap
            translate([0, pipe_radius, 0])
                sphere(r=pvc_od/2);
        }
        
        // Right Pontoon
        translate([hull_spacing/2, 0, 0]) {
            color("white")
                translate([0, pipe_radius, 0])
                    rotate([-90, 0, 0])
                        cylinder(r=pvc_od/2, h=hull_length - pvc_od - 150);
            translate([0, pipe_radius, 0])
                sphere(r=pvc_od/2);
        }
        
        // Custom 3D-Printed Bow Cap
        printed_double_bow_cap();
        
        // Keel Fin & Submerged Keel Bulb
        keel_fin_and_root();
        keel_bulb();
    }
    
    // 2. Frame Mounting Brackets
    if (show_brackets) {
        // Standard brackets holding the touching hulls
        color("orangered") {
            for (y = crossbeam_y) {
                translate([0, y, 0])
                    double_hull_bracket();
            }
        }
        // Black rubber sleeves under brackets
        for (y = crossbeam_y) {
            translate([0, y, 0])
                double_rubber_sleeve();
        }
    }
    
    // 3. Extrusion Frame
    if (show_frame) {
        for (y = crossbeam_y) {
            translate([-crossbeam_length/2, y - extrusion_size/2, frame_z])
                rotate([0, 90, 0])
                    aluminum_extrusion(crossbeam_length);
        }
        for (x = long_rail_x) {
            translate([x - extrusion_size/2, crossbeam_y[0], frame_z + extrusion_size])
                aluminum_extrusion(long_rail_length);
        }
    }
    
    // 4. Overhanging Coroplast Deck
    deck_w = 1400; // Cantilevered deck
    deck_l = 2000;
    deck_th = 4;
    
    if (show_deck) {
        color("lightcyan", 0.6) { 
            translate([-deck_w/2, crossbeam_y[0] - 50, deck_z])
                cube([deck_w, deck_l, deck_th]);
        }
    }
    
    // 5. Flexible Solar Panels (8 panels, 4x2 grid)
    panel_w = 340;  
    panel_l = 950;
    panel_th = 3;
    
    if (show_solar) {
        translate([0, 0, deck_z + deck_th]) {
            for (row = [0 : 1]) {
                for (col = [0 : 3]) {
                    x_pos = - (4 * panel_w)/2 + col * panel_w + 5 * col + 10;
                    y_pos = crossbeam_y[0] + row * panel_l + 10 * row + 30;
                    
                    translate([x_pos, y_pos, 0]) {
                        color("midnightblue")
                            cube([panel_w - 8, panel_l - 8, panel_th]);
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
    
    // 8. Mast and Sensor Rig
    if (show_mast) {
        translate([0, 2100, deck_z])
            sensor_mast();
    }
}

// Instantiate Option E assembly
asv_assembly();
