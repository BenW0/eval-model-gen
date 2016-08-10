/********************************************
 * Angle Interpolation Test Model for Fins
 *
 * Ben Weiss, University of Washington 2016
 *
 * This model is used to determine the minimum
 * thickness required to obtain printable and
 * acceptable results for negative fin (slot)
 * features at various angles between horizontal
 * and vertical.
 *
 * This model is part of a collection of models
 * for determining angle interpolation information
 * for a printer. 
 *******************************************/

include <../include/features.scad>;

serialNo = 13;						// test number to encode in barcode

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

			"basic.yellow_final_NegFinThkV":"vSizeMean",
			"basic.yellow_error_NegFinThkV":"vSizeOffset",
			"basic.yellow_final_NegFinThkH":"hSizeMean",
			"basic.yellow_error_NegFinThkH":"hSizeOffset",

			"basic.yellow_final_NegFinThkV":"greenVSlotThk",
			"basic.yellow_final_NegFinThkH":"greenHSlotThk",
			"basic.yellow_final_PosFinThkH":"greenHFinThk",
			"basic.yellow_final_PosFinThkV":"greenVFinThk"
		}
	}
</json>
*/

// Results from the main eval model needed here, to be overridden by the GUI.
vSizeMean = 1.5;
vSizeOffset = 0.5;
hSizeMean = 0.65;
hSizeOffset = 0.3;

greenVFinThk = 0.125;
greenHFinThk = 0.125;
greenVSlotThk = vSizeMean;
greenHSlotThk = hSizeMean;





/*
This is an array variable declaration. It will be expanded into a set of variables
by the backend on load and re-condensed only for communicating with openscad.
The variables min[varBase], max[varBase], and skip[varBase] will be arrays.

Note that the angles reported are 90° from the angle variable when they are actually computed. the angle variable stores the angle away from vertical.
<json>
    {
        "Name": ["90° Vertical Slots", 
								 "80° Slots",
								 "70° Slots",
								 "60° Slots",
								 "50° Slots",
								 "40° Slots",
								 "30° Slots",
								 "20° Slots",
								 "10° Slots",
								 "0° Horizontal Slots"],
        "Desc": "Use the slider to indicate how many fins printed acceptably.",
        "LowKeyword": "Lost",
        "HighKeyword": "Printed",
        "varBase": "Thks",
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
angles = [ for (i = [0:angleCount-1]) 
		90 * i / (angleCount - 1) * (onlyHalf ? 1 : 2) ];

minThks = fspread(count=angleCount, 
								low=vSizeMean - vSizeOffset,
								high=hSizeMean - hSizeOffset);
maxThks = fspread(count=angleCount, 
								low=vSizeMean + vSizeOffset,
								high=hSizeMean + hSizeOffset);
								
skipThks = ones(angleCount) * -1;



// Derived parameters for the object
maxThk = max(maxThks);
maxWidth = maxThk * finWidthThkRatio;
minThk = min(minThks);
minGap = max([greenVFinThk, greenHFinThk, greenVSlotThk, greenHSlotThk]);
meanThk = max([ for (i=[0:len(maxThks)-1]) (minThks[i] + maxThks[i]) * 0.5]);

coreDia = angleCount * (maxThk + minGap / 2) * 2.5 / pi * (onlyHalf ? 1 : 0.5);
coreLen = optionCount * meanThk * finWidthThkRatio + (optionCount + 1) * minGap;

symbolSize = maxThks[0] * finWidthThkRatio / 2;

fudge = minThk * 0.02;

// Render the geometry
color(normalColor)
difference()
{
	core();
	/*
	// Now subtract the individual slots
	for(i = [0:angleCount-1])
	{
		angle = angles[i];
		translate([0, i == 0 ? maxThks[0] * 0.33 : 0, 0])	// offset just the vertical fins so it fits better.
		rotate([i % 2 ? angle : -angle, 0, 0])
		translate([0, 0, fOffsetHeight(coreDia, angle)])
			fin_set(minThks[i], maxThks[i], skipThks[i], padLen=coreDia);
	}
	*/
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
				for(i = [0:angleCount-1])
				{
					angle = angles[i];
					translate([0, i == 0 ? maxThks[0] * 0.33 : 0, 0])	// offset just the vertical fins so it fits better.
					rotate([i % 2 ? angle : -angle, 0, 0])
					translate([0, 0, fOffsetHeight(coreDia, angle)])
						fin_set_long(minThks[i], maxThks[i], finLenThkRatio, finWidthThkRatio, coreLen, optionCount, force_width_x=maxThk * finWidthThkRatio + minGap + fudge);
				}
				// Add feet to the hull to make it flat on the bottom
				translate([-coreLen * 0.5 + minGap, 0, -minGap])
					cube(size=[minGap * 2, coreDia + 2 * minThks[len(maxThks)-1] * finLenThkRatio, 2 * minGap], center=true);
				translate([coreLen * 0.5 - minGap, 0, -minGap ])
					cube(size=[minGap * 2, coreDia + 2 * maxThks[len(maxThks)-1] * finLenThkRatio, 2 * minGap], center=true);
			}
			// core hollow
			rotate([45, 0, 0])
			cube(size=[coreLen * 2, coreDia * 0.7071, coreDia * 0.7071], center=true);
			
			// a wall at the small end to chop off unneeded extra geometry
			translate([-(coreLen + maxWidth) * 0.5, 0, 0])
			cube(size=[maxWidth, (maxWidth + coreDia) * 2, (maxWidth + coreDia) * 2], center=true);
			
			// a wall at the big end to chop off unneeded extra geometry
			translate([(coreLen + maxWidth) * 0.5, 0, 0])
			cube(size=[maxWidth, (maxWidth + coreDia) * 2, (maxWidth + coreDia) * 2], center=true);
		}
			
		// Add a marking to the big end in case it's hard to tell
		translate([(coreLen + minGap) * 0.5 - fudge, 0, (coreDia + maxWidth) * 0.5])
		{
			rotate([0, -90, 0])
				cylinder(h=minGap, d = symbolSize, center=true, $fn=3);
			// add the bottom of the arrow
			translate([0, 0, -symbolSize * 0.5 * 0.71828])
				cube(size=[minGap, symbolSize / 3, symbolSize / 3], center=true);
		}
	}
}


// A special function for determining how far out from the centerline to trave
// to intersect with the diamond-shaped core at a given angle.
// This is derived from a law of Sines argument from the geometry.
function fOffsetHeight(coreDia, angle) = coreDia * 1.4142 / 4 / sin(135 - angle);
