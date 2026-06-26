// Parametric PVC-to-2020 Extrusion Mounting Bracket
// Designed for Project Blue-Water Rover ASV
//
// To use: Open this file in OpenSCAD (https://openscad.org), 
// select your ASV option preset, and go to File -> Export as STL.

$fn = 100; // Curve smoothness (resolution)

/* [ASV Model Options] */
// Select which design option to generate the bracket for:
// "A" = 2.53m scale (8" PVC)
// "B" = 3.40m centerline scale (6" PVC)
// "C" = 1.00m prototype scale (4" PVC)
asv_option = "C"; // [A, B, C]

// --- Parametric Defaults based on Option selection ---

// Outer Diameter of the PVC Pipe (mm)
pvc_od = (asv_option == "A") ? 219.1 :
         (asv_option == "B") ? 168.3 :
                               114.3; // Default Option C (4" Schedule 40 PVC)

// Overall width of the mounting block (mm)
bracket_width = (asv_option == "A") ? 140 :
                (asv_option == "B") ? 110 :
                                      80; // Default Option C

// Length of the bracket along the pipe direction (mm)
bracket_length = 50.0;

// Depth of the cradle cutout (how deep the pipe sits in the bracket, mm)
cradle_depth = 15.0;

// Thickness of the top section above the cradle cutout (mm)
top_thickness = 15.0;

// 2020 Extrusion alignment slot width (mm)
extrusion_width = 20.2; 
// 2020 Extrusion alignment slot depth (mm)
extrusion_depth = 3.0;

// Mounting hardware size (M5 hardware default)
bolt_diameter = 5.3;
counterbore_diameter = 9.5;
counterbore_depth = 7.0;

// Hose clamp wrap-around slot width (mm)
clamp_width = 14.5;
// Hose clamp slot thickness (mm)
clamp_thickness = 3.0;

// Thickness of rubber friction/dampening strip between bracket and PVC (mm)
rubber_thickness = 1.5; 

// --- Calculated Geometry Constants ---
pipe_center_z = 0;
pipe_radius = pvc_od / 2 + rubber_thickness;

block_top_z = pipe_radius + top_thickness;
block_bottom_z = pipe_radius - cradle_depth;
block_height = block_top_z - block_bottom_z;

module pvc_2020_bracket() {
    difference() {
        // 1. Main solid block of the bracket
        translate([-bracket_width/2, 0, block_bottom_z])
            cube([bracket_width, bracket_length, block_height]);
        
        // 2. Subtract PVC Pipe Cylinder (creates the cradle cutout at the bottom)
        translate([0, -1, pipe_center_z])
            rotate([-90, 0, 0])
                cylinder(r=pipe_radius, h=bracket_length + 2);
        
        // 3. Subtract 2020 Extrusion alignment slot on the flat top surface
        translate([-extrusion_width/2, -1, block_top_z - extrusion_depth])
            cube([extrusion_width, bracket_length + 2, extrusion_depth + 1]);
        
        // 4. Subtract Extrusion Mounting Bolt Holes (M5)
        // Two holes along the center line, spaced 25mm apart (adjust to your extrusion)
        for (y_offset = [bracket_length/2 - 12.5, bracket_length/2 + 12.5]) {
            // Main bolt shaft
            translate([0, y_offset, block_bottom_z - 1])
                cylinder(d=bolt_diameter, h=block_height + 2);
            
            // Counterbore for bolt heads (recessed from the top)
            translate([0, y_offset, block_top_z - counterbore_depth])
                cylinder(d=counterbore_diameter, h=counterbore_depth + 1);
        }
        
        // 5. Subtract Hose Clamp slot wrapping around the PVC
        // This is a concentric slot outside the pipe circumference allowing a metal band clamp or zip ties to pass through
        translate([0, bracket_length/2 - clamp_width/2, pipe_center_z])
            rotate([-90, 0, 0])
                difference() {
                    cylinder(r=pipe_radius + clamp_thickness, h=clamp_width);
                    translate([0, 0, -1])
                        cylinder(r=pipe_radius, h=clamp_width + 2);
                }
    }
}

pvc_2020_bracket();
