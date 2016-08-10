/********************************************
 * Angle Interpolation Test Model for Bosses
 *
 * Ben Weiss, University of Washington 2016
 *
 * This model is used to determine the minimum
 * thickness required to obtain printable and
 * acceptable results for positive boss
 * features at various angles between horizontal
 * and vertical.
 *
 * This model is part of a collection of models
 * for determining angle interpolation information
 * for a printer. 
 *******************************************/

use <../include/vector_math.scad>;
include <../include/features.scad>;

serialNo = 10;

optionCount = 6;       // number of different thicknesses to produce
onlyHalf = false;
// That parameter will need to become hard-coded here pretty quick in order to match the front end

layerHeight = 0.1;      // mm
nozzleDiameter = 0.1;   // mm


/*
<json>
	{
		"Imports": {
			"basic.yellow_final_PosButtonDiaV":"vSizeMean",
			"basic.yellow_error_PosButtonDiaV":"vSizeSpread",
			"basic.yellow_final_PosButtonDiaH":"hSizeMean",
			"basic.yellow_error_PosButtonDiaH":"hSizeSpread",
			
			"basic.yellow_final_PosPillarDiaH":"greenHBarDia",
			"basic.yellow_final_PosPillarDiaV":"greenVBarDia",
			"basic.yellow_final_NegFinThkV":"greenVSlotThk",
			"basic.yellow_final_NegFinThkH":"greenHSlotThk"
			"basic.yellow_final_PosFinThkV":"greenVFinThk",
			"basic.yellow_final_PosFinThkH":"greenHFinThk"
		}
	}
</json>
*/

// Results from the main eval model needed here, to be overridden by the GUI.
vSizeMean = 0.2;
vSizeSpread = 0.1;
hSizeMean = 0.2;
hSizeSpread = 0.1;

greenHBarDia = 0.125;
greenVBarDia = 0.125;
greenVSlotThk = 1.5;
greenHSlotThk = 0.65;
greenVFinThk = 0.5;
greenHFinThk = 0.5;


/*
This is an array variable declaration. It will be expanded into a set of variables
by the backend on load and re-condensed only for communicating with openscad.
The variables min[varBase], max[varBase], and skip[varBase] will be arrays.

Note that the angles reported are 90° from the angle variable when they are actually computed. the angle variable stores the angle away from vertical.
<json>
    {
        "Name": ["90° Vertical Bosses", 
								 "80° Bosses",
								 "70° Bosses",
								 "60° Bosses",
								 "50° Bosses",
								 "40° Bosses",
								 "30° Bosses",
								 "20° Bosses",
								 "10° Bosses",
								 "0° Horizontal Bosses",
								 "-10° Bosses",
								 "-20° Bosses",
								 "-30° Bosses",
								 "-40° Bosses",
								 "-50° Bosses",
								 "-60° Bosses",
								 "-70° Bosses",
								 "-80° Bosses",
								 "-90° Vertical Bosses"],
        "Desc": "Use the slider to indicate how many bosses printed acceptably.",
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
angleCount = onlyHalf ? 10 : 19;       // number of different fin angles to produce, including vertical and horizontal. Needs to match number of elements in the json Names vector.
angles = [ for (i = [0 : angleCount - 1]) 90 * i / (angleCount - 1) * (onlyHalf ? 1 : 2) ];
minDias = fangleSpread(angles, vSizeMean - vSizeSpread, hSizeMean - hSizeSpread);
maxDias = fangleSpread(angles, vSizeMean + vSizeSpread, hSizeMean + hSizeSpread);
skipDias = ones(angleCount) * -1;

echo(minDias=minDias);
echo(maxDias=maxDias);




// Derived parameters for the object
maxDia = max(maxDias);
minDia = min(minDias);
minGap = max([greenVSlotThk, greenHSlotThk]);
meanDia = max([ for (i=[0:len(maxDias)-1]) (minDias[i] + maxDias[i]) * 0.5]);

coreDia = angleCount * (maxDia + minGap / 2) * 2 / pi * (onlyHalf ? 1 : 0.5);
coreLen = optionCount * meanDia + (optionCount - 1) * minGap;


mountDia = coreDia * 0.5; //pow(2, round(ln(coreDia / 4 * (onlyHalf ? 1 : 2)) / ln(2)));

lowestZ = -minGap + (onlyHalf ? 0 : (-coreDia * 0.5 - vButtonThk(greenVBarDia, nozzleDiameter)));
wallThk = max(greenHFinThk, greenVFinThk) * 4;

fudge = meanDia * 0.01;		// diameter to use for the mounting holes
barcode_thk = greenHFinThk * 4;

// Render the geometry
color(normalColor)
difference()
{
	union()
	{
		core();

        echo(NEGATIVE=false);

		for(i = [0:angleCount-1])
		{
		    echo(str("SERIES=", i, "Dias"));

			angle = angles[i];
			length = fbossHeight(angle, greenHBarDia, greenVBarDia, layerHeight, nozzleDiameter);
			//translate([0, angle == 0 ? maxDias[0] * 0.33 : 0, 0])	// offset just the vertical fins so it fits better.
			//translate([0, angle == 180 ? -maxDias[0] * 0.33 : 0, 0])	// offset just the vertical fins so it fits better.
			rotate([i % 2 ? angle : -angle, 0, 0])
			translate([0, 0, coreDia * 0.5 - length])
			pillar_set(minDias[i], maxDias[i], 0, coreLen, optionCount,
		        override_len=length,
		        pad_len=length,
		        skip=skipDias[i],
		        do_echo=true);
        }
	}
	core_diff();
}
// Draws the core of the object
module core()
{
	union()
	{
		translate([-wallThk * 0.5, 0, 0])
		rotate([0, 90, 0])
			cylinder(h=coreLen + wallThk, d=coreDia, center=true, $fn=40);
		if(onlyHalf)
			translate([0, 0, -maxDia * 0.5])
				cube(size=[coreLen, coreDia, maxDia], center=true);
		
		// draw the barcode
		translate([-0.5 * (barcode_block_length(serialNo) + coreLen), barcode_block_height * 0.5, barcode_thk * 0.5 + lowestZ])
		draw_barcode(serialNo, barcode_thk);

		// draw the connecting bar that links the barcode and the body
		translate([-0.5 * (coreLen + wallThk), 0, lowestZ * 0.5])
		    cube(size=[wallThk, coreDia, abs(lowestZ)], center=true);
	}
}

// Subtract out some unused space at the center of the core
module core_diff()
{
	union()
	{
		if(onlyHalf)
		{
			translate([0, 0, -coreDia * 0.5 - maxDia])
				cube(size=[coreLen * 2, coreDia * 2, coreDia], center=true);
		}

		translate([0, 0, -maxDia * (onlyHalf ? 1 : 0)])
		scale([1, (coreDia - wallThk) / coreDia, (coreDia - maxDia * (onlyHalf ? 1 : 2)) / coreDia])
		rotate([45, 0, 0])
			cube(size=[coreLen - wallThk * 2, coreDia * 0.7071, coreDia * 0.7071], center=true);
		
		// Add holes for clamping this piece to each end of the part
		translate([-coreLen / 2, 0, onlyHalf ? coreDia / 5 : 0])
		{
		rotate([0, 90, 0])
			cylinder(h=coreLen / 2, d=mountDia, center=true, $fn=20);
		translate([coreLen, 0, 0])
		rotate([0, -90, 0])
			cylinder(h=coreLen / 2, d = mountDia * 1.25, center=true, $fn=3);
		}
		// add the bottom of the arrow
		translate([coreLen / 2, 0, -mountDia * 0.5 * 0.71828])
			cube(size=[wallThk * 4, mountDia / 3, mountDia / 3], center=true);
	}
}

