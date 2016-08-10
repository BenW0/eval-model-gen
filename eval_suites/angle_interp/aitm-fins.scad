/********************************************
 * Angle Interpolation Test Model for Fins
 *
 * Ben Weiss, University of Washington 2016
 *
 * This model is used to determine the minimum
 * thickness required to obtain printable and
 * acceptable results for positive fin
 * features at various angles between horizontal
 * and vertical.
 *
 * This model is part of a collection of models
 * for determining angle interpolation information
 * for a printer. 
 *******************************************/

use <../include/vector_math.scad>;
include <../include/features.scad>;

serialNo = 11;						// test number to encode in barcode

optionCount = 6;       // number of different thicknesses to produce
onlyHalf = false;
// That parameter will need to become hard-coded here pretty quick in order to match the front end

// Special variables set by front end.
layerHeight = 0.1;      // mm
nozzleDiameter = 0.1;   // mm


/*
<json>
	{
		"Imports": {
			"basic.yellow_final_PosFinThkV":"vSizeMean",
			"basic.yellow_error_PosFinThkV":"vSizeSpread",
			"basic.yellow_final_PosFinThkH":"hSizeMean",
			"basic.yellow_error_PosFinThkH":"hSizeSpread",

			"basic.yellow_final_NegFinThkV":"greenVSlotThk",
			"basic.yellow_final_NegFinThkH":"greenHSlotThk",
			"basic.yellow_final_PosPillarDiaH":"greenHBarDia"
		}
	}
</json>
*/

// Results from the main eval model needed here, to be overridden by the GUI.
vSizeMean = 0.16;
vSizeSpread = 0.06;
hSizeMean = 0.16;
hSizeSpread = 0.06;

greenVSlotThk = 1.5;
greenHSlotThk = 1.5;
greenVFinThk = vSizeMean;
greenHFinThk = hSizeMean;
greenHBarDia = 0.125;


/*
This is an array variable declaration. It will be expanded into a set of variables
by the backend on load and re-condensed only for communicating with openscad.
The variables min[varBase], max[varBase], and skip[varBase] will be arrays.

Note that the angles reported are 90° from the angle variable when they are actually computed. the angle variable stores the angle away from vertical.
<json>
    {
        "Name": ["90° Vertical Fins", 
								 "80° Fins",
								 "70° Fins",
								 "60° Fins",
								 "50° Fins",
								 "40° Fins",
								 "30° Fins",
								 "20° Fins",
								 "10° Fins",
								 "0° Horizontal Fins",
								 "-10° Fins",
								 "-20° Fins",
								 "-30° Fins",
								 "-40° Fins",
								 "-50° Fins",
								 "-60° Fins",
								 "-70° Fins",
								 "-80° Fins",
								 "-90° Vertical Fins"],
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
angleCount = onlyHalf ? 10 : 19;       // number of different fin angles to produce, including vertical and horizontal. Needs to match number of elements in the json Names vector.
angles = [ for (i = [0 : angleCount - 1]) 90 * i / (angleCount - 1) * (onlyHalf ? 1 : 2) ];
minThks = fangleSpread(angles, vSizeMean - vSizeSpread, hSizeMean - hSizeSpread);
maxThks = fangleSpread(angles, vSizeMean + vSizeSpread, hSizeMean + hSizeSpread);
skipThks = ones(angleCount) * -1;

echo(minDias=minThks);
echo(maxDias=maxThks);





// Derived parameters for the object
maxThk = max(maxThks);
minThk = min(minThks);
minGap = max(greenVSlotThk, greenHSlotThk);
meanThk = max([ for (i=[0:len(maxThks)-1]) (minThks[i] + maxThks[i]) * 0.5]);
maxLen = maxThk * finLenThkRatio;

coreDia = angleCount * (maxThk + minGap * 0.5) * 2.5 / pi * (onlyHalf ? 1 : 0.5);
coreLen = optionCount * meanThk * finWidthThkRatio + (optionCount - 1) * minGap;


mountDia = coreDia * 0.5; //pow(2, round(ln(coreDia / 4 * (onlyHalf ? 1 : 2)) / ln(2)));

lowestZ = -minGap + (onlyHalf ? 0 : (-coreDia * 0.5 + min([ for (i = [0:angleCount-1]) maxThks[i] * cos(angles[i]) * finLenThkRatio])));
wallThk = max(greenHFinThk, greenVFinThk) * 4;

fudge = coreDia * 0.05;	
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
		    echo(str("SERIES=", i, "Thks"));

			angle = angles[i];
			translate([0, i == 0 ? greenHSlotThk * 0.25 : 0, 0])	// offset just the vertical fins so it fits better.
			translate([0, angle == 180 ? greenHSlotThk * 0.25 : 0, 0])	// offset just the vertical fins so it fits better.
			rotate([i % 2 ? angle : -angle, 0, 0])
			translate([0, 0, coreDia * 0.5 - fudge])
				fin_set_long(minThks[i], maxThks[i], finLenThkRatio, finWidthThkRatio, coreLen, optionCount,
				        skip=skipThks[i],
				        pad_len=fudge,
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
			translate([0, 0, -coreDia * 0.5 - maxThk])
				cube(size=[coreLen * 2, coreDia * 2, coreDia], center=true);
		}

		translate([0, 0, -maxThk * (onlyHalf ? 1 : 0)])
		scale([1, (coreDia - wallThk) / coreDia, (coreDia - maxThk * (onlyHalf ? 1 : 2)) / coreDia])
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
