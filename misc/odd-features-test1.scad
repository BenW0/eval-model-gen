/********************************************
 * This file produces a version of aitm-slots with different aspect ratios, orientation, etc. for evaluation of hypotheses.
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

use <../eval_suites/include/vector_math.scad>;
include <../eval_suites/include/features_old.scad>;

serialNo = 39;						// test number to encode in barcode

weirdFinLenThkRatio = 4;
weirdFinWidthThkRatio = 3;

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
			"basic.yellow_error_NegFinThkV":"vSizeSpread",
			"basic.yellow_final_NegFinThkH":"hSizeMean",
			"basic.yellow_error_NegFinThkH":"hSizeSpread",

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
vSizeSpread = 1;
hSizeMean = 1.5;
hSizeSpread = 1;

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

/*minThks = fspread(count=angleCount,
								low=vSizeMean - vSizeSpread,
								high=hSizeMean - hSizeSpread);
maxThks = fspread(count=angleCount, 
								low=vSizeMean + vSizeSpread,
								high=hSizeMean + hSizeSpread);
*/
minThks = [0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1];
maxThks = [0.778133205473479,0.918396022587103,0.918396022587103,0.918396022587103,0.918396022587103,0.918396022587103,0.918396022587103,0.918396022587103,0.918396022587103,0.918396022587103];



skipThks = ones(angleCount) * -1;


echo(series=angles);
echo(minDias=minThks);
echo(maxDias=maxThks);


// Derived parameters for the object
maxThk = max(maxThks);
maxWidth = maxThk * weirdFinWidthThkRatio;
minThk = min(minThks);
minGap = max([greenVFinThk, greenHFinThk, greenVSlotThk, greenHSlotThk]);
meanThk = max([ for (i=[0:len(maxThks)-1]) (minThks[i] + maxThks[i]) * 0.5]);

// Tally up the biggest chunk in each option
optionWidths = [ for (option=[0:optionCount-1]) max([ for (i=[0:angleCount-1]) fdia(option, minThks[i], maxThks[i], optionCount) * weirdFinWidthThkRatio ]) + minGap ];

coreDia = angleCount * (maxThk + minGap / 2) * 2.5 / pi * (onlyHalf ? 1 : 0.5);
coreLen = sum(optionWidths);

optionXCenters = [ for (option=[0:optionCount-1]) -coreLen * 0.5 + sumv(optionWidths, option) - optionWidths[option] * 0.5 ];

symbolSize = maxThks[0] * weirdFinWidthThkRatio / 2;

fudge = minThk * 0.02;

// Render the geometry
color(normalColor)
union()
{
    // make it oddly oriented!
    translate([coreLen * 0.5, 0, 0])
    rotate([0, -38, 0])
    translate([-coreLen * 0.5, 0, 0])
    difference()
    {
        core();

        echo(NEGATIVE=true);

        for(i = [0:angleCount-1])
        {
            echo(str("SERIES=", i, "Thks"));

            angle = angles[i];
            translate([0, i == 0 ? maxThks[0] * 0.33 : 0, 0])	// offset just the vertical fins so it fits better.
            rotate([i % 2 ? angle : -angle, 0, 0])
            translate([0, 0, fOffsetHeight(coreDia, angle)])
                fin_set_long(minThks[i], maxThks[i], weirdFinLenThkRatio, weirdFinWidthThkRatio, coreLen, optionCount, skipThks[i], pad_len=coreDia * 0.5, do_echo=true, overrideXs=optionXCenters);
        }

    }

    // Add a barcode
    translate([0, coreDia > barcode_block_length(serialNo) ? (coreDia - barcode_block_length(serialNo)) * 0.5 : 0, 0])		// move the barcode if the object is too big.
    rotate([0, 0, 90])
    translate([0, -coreLen * 0.5 + fudge, -minGap * 2 + greenHFinThk * 2])
    draw_barcode(serialNo, greenHFinThk * 4);
}
// Draws the core of the object
module core()
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
                                dr = fdia(option, minThks[i], maxThks[i], optionCount) * weirdFinLenThkRatio)
                            [-sin(angle) * (r0 + dr) + (i == 0 ? maxThks[0] * 0.33 : 0), cos(angle) * (r0 + dr)] ];
                n = len(tip_verts);

                last_two_xs = [elem(tip_verts, -1)[0], elem(tip_verts, -2)[0]];
                edge_verts = [[min(last_two_xs), -minGap * 2], [max(last_two_xs), -minGap * 2]];
                //echo(elem(tip_verts, -1));

                verts = concat(tip_verts, edge_verts);
                order = concat(series(0, 2, n-1), n + 1, n, reverse(series(1, 2, n-1)));
                //echo(order);

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


// A special function for determining how far out from the centerline to trave
// to intersect with the diamond-shaped core at a given angle.
// This is derived from a law of Sines argument from the geometry.
function fOffsetHeight(coreDia, angle) = coreDia * 1.4142 / 4 / sin(135 - angle);
