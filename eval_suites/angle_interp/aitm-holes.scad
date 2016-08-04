/********************************************
 * Angle Interpolation Test Model for Holes
 *
 * Ben Weiss, University of Washington 2016
 *
 * This model is used to determine the minimum
 * thickness required to obtain printable and
 * acceptable results for hole
 * features at various angles between horizontal
 * and vertical.
 *
 * This model is part of a collection of models
 * for determining angle interpolation information
 * for a printer. 
 *******************************************/

use <../include/vector_math.scad>;
include <../include/features.scad>;

testNo = 13;						// test number to encode in barcode

optionCount = 6;       // number of different thicknesses to produce
onlyHalf = true;
// That parameter will need to become hard-coded here pretty quick in order to match the front end

// Special variables set by front end.
layerHeight = 0.1;      // mm
nozzleDiameter = 0.1;   // mm


/*
<json>
	{
		"Imports": {
			"basic.yellow_final_NegHoleDiaV":"vSizeMean",
			"basic.yellow_error_NegHoleDiaV":"vSizeOffset",
			"basic.yellow_final_NegHoleDiaH":"hSizeMean",
			"basic.yellow_error_NegHoleDiaH":"hSizeOffset",

			"basic.yellow_final_NegFinThkV":"greenVSlotThk",
			"basic.yellow_final_NegFinThkH":"greenHSlotThk",
			"basic.yellow_final_PosFinThkH":"greenHFinThk",
			"basic.yellow_final_PosFinThkV":"greenVFinThk"
		}
	}
</json>
*/

// Results from the main eval model needed here, to be overridden by the GUI.
vSizeMean = 3.2;
vSizeOffset = 0.5;
hSizeMean = 2;
hSizeOffset = 0.3;

greenVFinThk = 0.125;
greenHFinThk = 0.125;
greenVSlotThk = 1.5;
greenHSlotThk = 0.65;


/*
This is an array variable declaration. It will be expanded into a set of variables
by the backend on load and re-condensed only for communicating with openscad.
The variables min[varBase], max[varBase], and skip[varBase] will be arrays.

Note that the angles reported are 90° from the angle variable when they are actually computed. the angle variable stores the angle away from vertical.
<json>
    {
        "Name": ["90° Vertical Holes", 
								 "80° Holes",
								 "70° Holes",
								 "60° Holes",
								 "50° Holes",
								 "40° Holes",
								 "30° Holes",
								 "20° Holes",
								 "10° Holes",
								 "0° Horizontal Holes"],
        "Desc": "Use the slider to indicate how many fins printed acceptably.",
        "LowKeyword": "Lost",
        "HighKeyword": "Printed",
        "varBase": "Dias",
        "minDefault": 0.075,
        "maxDefault": 0.175,
        "minDefaultND": "0.5 * nozzleDiameter",
        "maxDefaultND": "5 * nozzleDiameter",
        "cameraData": "9.57,-17.9,8.45,57.8,0,314.8,85",
        "sortOrder": 0,
				"instanceCount": 6
    }
</json>
*/

// Range of thicknesses. These arrays will be overridden by the front end.
angleCount = 10;
angles = [ for (i = [0:angleCount-1]) 90 * i / (angleCount - 1) * (onlyHalf ? 1 : 2) ];

minDias = fspread(count=angleCount, 
								low=vSizeMean - vSizeOffset,
								high=hSizeMean - hSizeOffset);
maxDias = fspread(count=angleCount, 
								low=vSizeMean + vSizeOffset,
								high=hSizeMean + hSizeOffset);
								
skipDias = ones(angleCount) * -1;





// Derived parameters for the object
maxDia = max(maxDias);
maxLen = maxDia * pillarLenDiaRatio;
minDia = min(minDias);
minGap = max([greenVSlotThk, greenHSlotThk, greenVFinThk, greenHFinThk]) * 2;
meanDia = max([ for (i=[0:len(maxDias)-1]) (minDias[i] + maxDias[i]) * 0.5]);

// Tally up the biggest chunk in x for each option
optionWidths = [ for (option=[0:optionCount-1]) max([ for (i=[0:angleCount-1]) fdia(option, minDias[i], maxDias[i], optionCount) ]) + minGap ];

coreDia = angleCount * (maxDia + minGap / 2) * 2.5 / pi * (onlyHalf ? 1 : 0.5);
coreLen = sum(optionWidths);

optionXCenters = [ for (option=[0:optionCount-1]) -coreLen * 0.5 + sumv(optionWidths, option) - optionWidths[option] * 0.5 ];

symbolSize = maxDias[0] * pillarLenDiaRatio * 0.5;

fudge = minDia * 0.02;		// diameter to use for the mounting holes


// Render the geometry
color(normalColor)
difference()
{
	core();
	
	for(i = [0:angleCount-1])
	{
		angle = angles[i];
		translate([0, i == 0 ? maxDias[0] * 0.33 : 0, 0])	// offset just the vertical hole so it fits better.
		rotate([i % 2 ? angle : -angle, 0, 0])
		translate([0, 0, fOffsetHeight(coreDia, angle)])
			pillar_set(minDias[i], maxDias[i], pillarLenDiaRatio, coreLen, optionCount, skipDias[i], pad_len=coreDia, do_echo=true, overrideXs=optionXCenters);
	}
	
}
// Draws the core of the object
module core()
{
	union()
	{
		difference()
		{
			union()
			{
				// Instead of using a hull, which would be saner, I've chosen to
				// extrude the shape of each segment (one option at a time).
				// This is really messy and I wish I had a better way. Using Hull
				// fails if the sections midway between H and V get too short compared
				// to the ends. 
				for(option = [0:optionCount-1])
				{
					tip_verts = [ for (i = [0:angleCount-1]) 
								let(angle = i % 2 ? angles[i] : -angles[i],
									r0 = fOffsetHeight(coreDia, angles[i]),
									dr = fdia(option, minDias[i], maxDias[i], optionCount) * pillarLenDiaRatio)
								[-sin(angle) * (r0 + dr) + (i == 0 ? maxDias[0] * 0.33 : 0), cos(angle) * (r0 + dr)] ];
					n = len(tip_verts);
					
					last_two_xs = [elem(tip_verts, -1)[0], elem(tip_verts, -2)[0]];
					edge_verts = [[min(last_two_xs), -minGap * 2], [max(last_two_xs), -minGap * 2]];
					echo(elem(tip_verts, -1));
					
					verts = concat(tip_verts, edge_verts);
					order = concat(series(0, 2, n-1), n + 1, n, reverse(series(1, 2, n-1)));
					echo(order);
					
					translate([optionXCenters[option], 0, 0])
					rotate([90, 0, 90])
					linear_extrude(height=optionWidths[option] + fudge, center=true, slices=1)
						polygon(verts, [order], convexity=optionCount);
				}
					
			}
			
			// core hollow
			rotate([45, 0, 0])
			cube(size=[coreLen * 2, coreDia * 0.7071, coreDia * 0.7071], center=true);
			
			// a wall at the small end to chop off unneeded extra geometry
			translate([-(coreLen + maxLen) * 0.5, 0, 0])
			cube(size=[maxLen, (maxLen + coreDia) * 2, (maxLen + coreDia) * 2], center=true);
			
			// a wall at the big end to chop off unneeded extra geometry
			translate([(coreLen + maxLen) * 0.5, 0, 0])
			cube(size=[maxLen, (maxLen + coreDia) * 2, (maxLen + coreDia) * 2], center=true);
			
		}
			
		// Add a marking to the big end in case it's hard to tell
		translate([(coreLen + minGap) * 0.5 - fudge, 0, (coreDia + maxLen) * 0.5])
		{
			rotate([0, -90, 0])
				cylinder(h=minGap, d = symbolSize, center=true, $fn=3);
			// add the bottom of the arrow
			translate([0, 0, -symbolSize * 0.5 * 0.71828])
				cube(size=[minGap, symbolSize / 3, symbolSize / 3], center=true);
		}
		// Add a barcode
		translate([0, coreDia > barcode_length2 ? (coreDia - barcode_length2) * 0.5 : 0, 0])		// move the barcode if the object is too big.
		rotate([0, 0, 90])
		translate([0, -coreLen * 0.5 + fudge, -minGap * 2 + greenHFinThk * 2])
		draw_barcode(testNo, greenHFinThk * 4);

	}
}

// A special function for determining how far out from the centerline to trave
// to intersect with the diamond-shaped core at a given angle.
// This is derived from a law of Sines argument from the geometry.
function fOffsetHeight(coreDia, angle) = coreDia * 1.4142 / 4 / sin(135 - angle);
