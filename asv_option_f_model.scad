// Project Blue-Water Rover ASV - Option F (Hydro-Stabilized Ocean Catamaran)
//
// This file renders a complete 3D model of the Option F design, which integrates:
// 1. Two separated 6" PVC outboard pontoons (800mm spacing center-to-center).
// 2. A 3D-printed aerodynamic bow cap on each hull.
// 3. A swept-back solid metal foil keel spar (45-degree aft rake to shed marine weeds).
// 4. A compact, submerged solid lead ballast bulb (no batteries, purely mechanical ballast).
// 5. Dual thrusters mounted on the stern of the hulls for rudderless differential steering.
// 6. Two deck-mounted IP67 boxes: one Battery Power Vault and one Avionics/RF Box.
// 7. Overhanging Coroplast deck with an 800W solar array (8x 100W panels).
//
// Open this file in OpenSCAD (https://openscad.org) to view the assembly.

$fn = 60; // Curve resolution for rendering performance

// --- DIMENSIONS & CONFIGURATION ---
pvc_od = 168.3;           // 6" PVC Outer Diameter (mm)
hull_length = 2530.0;     // Hulls length (mm)
overall_beam = 1200.0;    // Wider beam for stability and differential steering (mm)
hull_spacing = 800.0;     // Separated center-to-center spacing (mm)
keel_z_offset = -450.0;   // Vertical depth of the ballast bulb center (mm)

// Ballast Bulb Sizing (Submerged solid lead, streamlined casing)
bulb_diameter = 90.0;     // Slimmer bulb since batteries are moved to deck
bulb_length = 500.0;
bulb_y_center = 1000.0;   // Positioned aft-center for optimal trim

// Frame Configuration (2020 extrusion)
extrusion_size = 20.0;    
crossbeam_length = 1200.0;
crossbeam_y = [300.0, 900.0, 1500.0, 2100.0];
long_rail_length = 1900.0; 
long_rail_x = [-400.0, 400.0]; 

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

// 1. Single PVC-to-2020 Bracket (clamps a single hull to frame)
module single_hull_bracket() {
    bolt_diameter = 5.3;
    counterbore_diameter = 9.5;
    counterbore_depth = 7.0;
    
    block_w = pvc_od + 40;
    block_bottom_z = pipe_radius - cradle_depth;
    block_height = block_top_z - block_bottom_z;
    
    difference() {
        // Main block
        translate([-block_w/2, -bracket_length/2, block_bottom_z])
            cube([block_w, bracket_length, block_height]);
        
        // Hull cutout
        translate([0, -bracket_length/2 - 1, 0])
            rotate([-90, 0, 0])
                cylinder(r=pipe_radius, h=bracket_length + 2);
        
        // Top extrusion slot
        translate([-extrusion_width/2, -bracket_length/2 - 1, block_top_z - extrusion_depth])
            cube([extrusion_width, bracket_length + 2, extrusion_depth + 1]);
        
        // Mounting bolt holes
        for (x_offset = [-block_w/2 + 12, block_w/2 - 12]) {
            for (y_offset = [-12.5, 12.5]) {
                translate([x_offset, y_offset, block_bottom_z - 1])
                    cylinder(d=bolt_diameter, h=block_height + 2);
                translate([x_offset, y_offset, block_top_z - counterbore_depth])
                    cylinder(d=counterbore_diameter, h=counterbore_depth + 1);
            }
        }
    }
}

// 2. Rubber sleeve pad for single hull
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

// 3. Custom 3D-Printed Bow Cap (Aerodynamic nose piece for single hull)
module printed_bow_cap() {
    color("orangered") { // Orange printed parts visual identity
        difference() {
            // Main solid body
            hull() {
                rotate([-90, 0, 0])
                    cylinder(d=pvc_od, h=30);
                translate([0, 200, 0])
                    sphere(d=30); // Pointy bow tip
            }
            
            // Subtract hollow cavity for the PVC pipe end to slide inside
            translate([0, -1, 0])
                rotate([-90, 0, 0])
                    cylinder(d=pvc_od - 4, h=32);
        }
    }
}

// 4. Swept-Back Foil Keel Fin (Steel/Aluminum profile)
module swept_foil_keel() {
    fin_top_z = -pvc_od/2 + 20;
    fin_bottom_z = keel_z_offset + bulb_diameter/2 - 5;
    
    // Keel Root Mounting Box (slung between crossbeams at center)
    color("orangered") {
        difference() {
            translate([-60, bulb_y_center - 150, -pvc_od/2 - 20])
                cube([120, 300, 70]);
            // Horizontal crossbeam clearances
            translate([-70, bulb_y_center - 150 - 1, -pvc_od/2 - 25])
                cube([140, 40, 80]);
            // Slot for the metal keel plate
            translate([-10, bulb_y_center - 120, -pvc_od/2 - 25])
                cube([20, 240, 80]);
        }
    }
    
    // Swept-Back Hydrofoil Blade (Steel core with molded composite shell)
    color("slategray") {
        hull() {
            // Top of foil (attached to deck)
            translate([0, bulb_y_center + 100, fin_top_z])
                rotate([0, 90, 0])
                    scale([1, 2.5, 1])
                        cylinder(d=15, h=16, center=true);
            
            // Bottom of foil (swept back by 200mm, attached to ballast bulb)
            translate([0, bulb_y_center - 100, fin_bottom_z])
                rotate([0, 90, 0])
                    scale([1, 2.0, 1])
                        cylinder(d=15, h=16, center=true);
        }
    }
}

// 5. Submerged Lead Ballast Bulb (Streamlined capsule, solid metal ballast)
module lead_ballast_bulb() {
    cyl_len = bulb_length - bulb_diameter;
    
    translate([0, bulb_y_center, keel_z_offset]) {
        // Main solid metal body
        color("dimgray") {
            rotate([-90, 0, 0])
                cylinder(d=bulb_diameter, h=cyl_len, center=true);
            
            // Streamlined Nose Cone
            translate([0, cyl_len/2, 0])
                rotate([-90, 0, 0])
                    cylinder(d1=bulb_diameter, d2=10, h=bulb_diameter/2 + 20);
            
            // Streamlined Tail Cone
            translate([0, -cyl_len/2, 0])
                rotate([90, 0, 0])
                    cylinder(d1=bulb_diameter, d2=5, h=bulb_diameter + 30);
        }
    }
}

// 6. Standard 2020 Extrusion Profile
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

// 7. IP67 Watertight Enclosures (Deck Mounted)
module ip67_enclosure(w, l, h, color_str) {
    color(color_str, 0.95) {
        difference() {
            cube([w, l, h], center=true);
            translate([0, 0, 4])
                cube([w - 8, l - 8, h], center=true);
        }
        // Lid clamp tabs
        translate([0, 0, h/2 + 2])
            cube([w + 8, l + 8, 4], center=true);
        for (y_offset = [-l/2 + 30, l/2 - 30]) {
            for (x_offset = [-w/2 - 2, w/2 + 2]) {
                translate([x_offset, y_offset, h/2 - 5])
                    cube([4, 20, 20], center=true);
            }
        }
    }
}

// 8. BlueRobotics T200 Thruster (Potted core, brushless)
module t200_thruster() {
    color("black") {
        rotate([-90, 0, 0])
            cylinder(d=55, h=100, center=true);
        translate([0, -50, 0])
            rotate([90, 0, 0])
                cylinder(d1=55, d2=25, h=15);
        
        // Hydrofoil shroud (duct)
        difference() {
            translate([0, 10, 0])
                rotate([-90, 0, 0])
                    cylinder(d=92, h=55, center=true);
            translate([0, 10, 0])
                rotate([-90, 0, 0])
                    cylinder(d=82, h=57, center=true);
        }
        
        // Rigid mounting leg
        translate([0, 0, 40])
            cube([16, 25, 45], center=true);
    }
    
    // Propeller (3-blade blue nylon)
    color("dodgerblue") {
        translate([0, -15, 0]) {
            rotate([-90, 0, 0])
                cylinder(d=18, h=18, center=true);
            for (angle = [0, 120, 240]) {
                rotate([0, angle, 0])
                    translate([0, 0, 10])
                        cube([6, 32, 2.5], center=true);
            }
        }
    }
}

// 9. Sensor Mast & GPS / LoRa Antennas
module sensor_mast() {
    mast_h = 1200;
    mast_d = 25;
    
    color("darkslategray") {
        cylinder(d=mast_d, h=mast_h);
    }
    // Crossbar / platform
    color("black") {
        translate([0, 0, mast_h])
            cylinder(d=120, h=10);
    }
    // RTK-GPS Dome (white)
    color("white") {
        translate([-35, 0, mast_h + 10])
            cylinder(d=70, h=25);
    }
    // LoRa Whip Antenna (black)
    color("black") {
        translate([35, 20, mast_h + 10])
            cylinder(d=4, h=250);
        translate([35, 20, mast_h + 10])
            cylinder(d=12, h=25);
    }
    // Iridium Satellite Antenna (white square patch)
    color("white") {
        translate([0, -35, mast_h + 10])
            cube([45, 45, 15], center=true);
    }
}

// --- MAIN ASSEMBLY ---
module asv_assembly() {
    
    // 1. Outboard separated pontoons
    if (show_hulls) {
        for (x = [-hull_spacing/2, hull_spacing/2]) {
            translate([x, 0, 0]) {
                // Main PVC cylinders
                color("white")
                    translate([0, pipe_radius, 0])
                        rotate([-90, 0, 0])
                            cylinder(r=pvc_od/2, h=hull_length - pvc_od - 150);
                
                // Stern end caps (sealed PVC caps)
                translate([0, pipe_radius, 0])
                    sphere(r=pvc_od/2);
                
                // Custom Aerodynamic Bow Caps
                translate([0, hull_length - pvc_od/2 - 120, 0])
                    printed_bow_cap();
            }
        }
        
        // Swept keel fin & lead ballast bulb at centerline
        swept_foil_keel();
        lead_ballast_bulb();
    }
    
    // 2. Extrusion mounting brackets (clamping single hulls)
    if (show_brackets) {
        for (x = [-hull_spacing/2, hull_spacing/2]) {
            for (y = crossbeam_y) {
                translate([x, y, 0]) {
                    color("orangered")
                        single_hull_bracket();
                    rubber_sleeve();
                }
            }
        }
    }
    
    // 3. Aluminum crossbeams & rails
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
    
    // 4. Overhanging Coroplast deck
    deck_w = 1400; // Cantilevered over both sides
    deck_l = 2000;
    deck_th = 4;
    
    if (show_deck) {
        color("lightcyan", 0.55) { 
            translate([-deck_w/2, crossbeam_y[0] - 50, deck_z])
                cube([deck_w, deck_l, deck_th]);
        }
    }
    
    // 5. Solar panels (8x 100W flexible panels in 4x2 grid)
    panel_w = 330;  
    panel_l = 950;
    panel_th = 3;
    
    if (show_solar) {
        translate([0, 0, deck_z + deck_th]) {
            for (row = [0 : 1]) {
                for (col = [0 : 3]) {
                    x_pos = - (4 * panel_w)/2 + col * panel_w + 10 * col + 15;
                    y_pos = crossbeam_y[0] + row * panel_l + 15 * row + 25;
                    
                    translate([x_pos, y_pos, 0]) {
                        // Blue photovoltaic core
                        color("midnightblue")
                            cube([panel_w - 6, panel_l - 6, panel_th]);
                        // White laminate border
                        color("ghostwhite")
                            difference() {
                                cube([panel_w, panel_l, panel_th - 0.2]);
                                translate([3, 3, -0.5])
                                    cube([panel_w - 6, panel_l - 6, panel_th + 1]);
                            }
                    }
                }
            }
        }
    }
    
    // 6. Dual IP67 Enclosures on Aft Deck
    if (show_boxes) {
        // Enclosure 1: Watertight Battery Power Vault (Aft Left)
        translate([-220, 1650, frame_z + 20 + 75])
            ip67_enclosure(350, 250, 150, "darkslategray");
            
        // Enclosure 2: Avionics, RF, & MPPT Box (Aft Right)
        translate([220, 1650, frame_z + 20 + 75])
            ip67_enclosure(350, 250, 150, "dimgray");
    }
    
    // 7. Dual propulsion thrusters at stern (differential steering)
    if (show_propulsion) {
        for (x = [-hull_spacing/2, hull_spacing/2]) {
            translate([x, -100, -pvc_od/2 - 40])
                t200_thruster();
        }
    }
    
    // 8. Carbon-fiber mast and sensor rigs
    if (show_mast) {
        translate([0, 2100, deck_z])
            sensor_mast();
    }
}

// Render the Option F assembly
asv_assembly();
