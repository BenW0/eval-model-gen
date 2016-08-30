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

use <../include/vector_math.scad>;
include <../include/features2.scad>;

serialNo = 0;						// test number to encode in barcode

optionCount = 6;       // number of different thicknesses to produce
onlyHalf = true;
// That parameter will need to become hard-coded here pretty quick in order to match the front end


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
vSizeSpread = 0.5;
hSizeMean = 0.65;
hSizeSpread = 0.3;

greenVFinThk = 0.125;
greenHFinThk = 0.125;
greenVSlotThk = vSizeMean;
greenHSlotThk = hSizeMean;


// Aspect ratios to use for this model. These need to match the values provided in the json block!
localLenThkRatio = finLenThkRatio;
localWidthThkRatio = finWidthThkRatio;



/*
This is an array variable declaration. It will be expanded into a set of variables
by the backend on load and re-condensed only for communicating with openscad.
The variables min[varBase], max[varBase], and skip[varBase] will be arrays.

Note that the angles reported are 90° from the angle variable when they are actually computed. the angle variable stores the angle away from vertical.
<json>
    {
        "varBase": "Thks",
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
        "RedKeyword": "Lost",
        "GreenKeyword": "Printed",
        "cameraData": "9.57,-17.9,8.45,57.8,0,314.8,85",
        "sortOrder": 0,
		"instanceCount": 6,
        "coordSign": -1,
        "coordLTaspect":"=finLenThkRatio",
        "coordWTaspect":"=finWidthThkRatio",
        "coordAngleIncl":0
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
minThks = [1.19952861392373,1.23017747573357,1.15926066666667,0.835920716839035,0.761001696140126,0.379628666666667,0.322222666666667,0.208072656990399,0.314814,0.400068994543121];
maxThks = [1.80303360143825,1.74410937952429,2.07037466666667,1.60852709348161,1.49398407852769,1.15740966666667,1.05555566666667,0.896958656990399,0.959262,0.74933120449398];

skipThks = ones(angleCount) * -1;

echo(angles=angles);
echo(minThks=minThks);
echo(maxThks=maxThks);




// Derived parameters for the object
maxThk = max(maxThks);
maxWidth = maxThk * localWidthThkRatio;
minThk = min(minThks);
borderSize = max(xyNegGap, zNegGap);
meanThk = max([ for (i=[0:len(maxThks)-1]) (minThks[i] + maxThks[i]) * 0.5]);

// Tally up the biggest chunk in each option
optionWidths = [ for (option=[0:optionCount-1]) max([ for (i=[0:angleCount-1]) fdia(option, minThks[i], maxThks[i], optionCount) * localWidthThkRatio ]) + borderSize ];

coreDia = angleCount * (maxThk + borderSize / 2) * 2.5 / pi * (onlyHalf ? 1 : 0.5);
coreLen = sum(optionWidths) + 2 * borderSize;
zBottom = -borderSize * 2;

optionXCenters = [ for (option=[0:optionCount-1]) -coreLen * 0.5 + borderSize + sumv(optionWidths, option) - optionWidths[option] * 0.5 ];

symbolSize = maxThks[0] * localLenThkRatio * 0.5;

fudge = minThk * 0.02;

// Render the geometry
color(normalColor)
difference()
{
	//core();

    echo(SIGN=-1);

    loffsets = sucsum([ for (i = [0:2:angleCount-1])
            let(dtheta = i > 1 ? angles[2] - angles[0] : angles[1] - angles[0],
                perp_dist = maxThks[i] * 0.5 + borderSize + 0.5 * maxThks[i-1] * cos(dtheta))
             i > 0 ? (perp_dist * cos(dtheta) / cos(angles[i-1])) : 0]);

    roffsets = sucsum([ for (i = [1:2:angleCount-1])
            let(dtheta = i > 1 ? angles[2] - angles[0] : angles[1] - angles[0],
                perp_dist = maxThks[i] * 0.5 + borderSize + 0.5 * maxThks[i-1] * cos(dtheta))
             i > 0 ? -min(perp_dist * cos(dtheta) / cos(angles[i-1]), sin(angles[i-1]) * maxThks[i-1] * localLenThkRatio + cos(angles[i-1]) * perp_dist) : 0]);

	for(i = [0:angleCount-1])
	{
		echo(str("SERIES=", i, "Thks"));

		angle = angles[i];
		dir = i % 2 ? 1 : -1;
		echo(dir=dir);
		echo(ANGLE=angle);
		//translate([0, i == 0 ? maxThks[0] * 0.33 : 0, 0])	// offset just the vertical fins so it fits better.
		//translate([0, -(borderSize + maxThks[i] * 0.5) * i * dir - (i > 0 ? (borderSize + maxThks[0]) * 0.5 : 0), 0])

		translate([0, dir < 0 ? loffsets[floor(i/2)] : roffsets[floor(i/2)], 0])
		translate([0, 0, 0])
		rotate([dir * angle, 0, 0])
		//translate([0, 0, fOffsetHeight(coreDia, angle)])
            fin_set_neg(minThks[i], maxThks[i], optionCount, localLenThkRatio, localWidthThkRatio,
                    total_width=coreLen, long_ways=true, skip=skipThks[i], pad_len=coreDia * 0., border_thk=borderSize,
                    do_echo=true, override_xs=optionXCenters, do_outside=true);
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
				for(i = [0:angleCount-1])
                {
                    angle = angles[i];
                    real_angle = i % 2 ? angle : -angle;
                    echo(optionWidths[0] + borderSize);
                    //override_xs = optionXCenters - 0.5 * fdias(minThks[i], maxThks[i], optionCount) * localWidthThkRatio + optionWidths * 0.5;//(optionWidths[0] + borderSize) * ones(optionCount) * 0.5;
                    translate([0, i == 0 ? maxThks[0] * 0.33 : 0, 0])	// offset just the vertical fins so it fits better.
                    rotate([real_angle, 0, 0])
                    translate([0, 0, fOffsetHeight(coreDia, angle) - borderSize])
                        fin_set_neg(minThks[i], maxThks[i], optionCount, localLenThkRatio, localWidthThkRatio,
                                total_width=coreLen, long_ways=true, skip=skipThks[i], pad_len=borderSize * 2, border_thk=borderSize,
                                do_echo=false, override_xs=optionXCenters, do_inside=false, outer_smooth=false);

                    // create some support structure on each end of each block
                    if(angle > overhangAngle && overhangSupports)
                    {
                        l_start = fOffsetHeight(coreDia, angle);
                        y_start = l_start * sin(-real_angle);
                        z_start = zBottom;//l_start * cos(real_angle);
                        sign = i % 2 ? -1 : 1;

                        for(option = [0:optionCount-1])
                        {
                            dia = fdia(option, minThks[i], maxThks[i], optionCount);
                            x_span = dia * localWidthThkRatio + 2 * borderSize;
                            x_center = optionXCenters[option];
                            l_size = dia * localLenThkRatio;
                            y_end = (l_start + l_size) * sin(-real_angle) + sign * ((borderSize + dia * 0.5) * cos(-real_angle) - fudge);
                            z_end = (l_start + l_size) * cos(-real_angle);
                            echo(x_center=x_center, x_span=x_span, y_start=y_start, y_end=y_end, z_start=z_start, z_end=z_end);

                            difference()
                            {
                                translate([x_center, 0.5 * (y_start + y_end), 0.5 * (z_start + z_end)])
                                cube(size=[x_span, abs(y_end - y_start), abs(z_end - z_start)], center=true);

                                rotate([real_angle, 0, 0])
                                translate([x_center, -sign * coreDia * 0.5, l_start + l_size * 0.5])
                                cube(size=[x_span * 2, coreDia + dia + 2 * borderSize - fudge * 2, l_size * 2], center=true);

                                translate([x_center, 0.5 * (y_start + y_end), 0.5 * (z_start + z_end)])
                                cube(size=[x_span - xyNegGap * 2, abs(y_end-y_start) * 2, abs(z_end-z_start * 2)], center=true);
                            }
                        }
                    }
                }

                // a region just above the core to make sure everything sticks together
                rotate([45, 0, 0])
                cube(size=[coreLen, (coreDia + 2*borderSize) * 0.7071, (coreDia + 2*borderSize) * 0.7071], center=true);

			    // add a foot below the 50% point on the core to give us a big enough footprint to stick to an fdm build plate
			    translate([0, 0, zBottom * 0.5])
			    cube(size=[coreLen, coreDia + borderSize * 2, abs(zBottom)], center=true);
			}
			
			// core hollow
			rotate([45, 0, 0])
			cube(size=[coreLen * 2, coreDia * 0.7071, coreDia * 0.7071], center=true);

			// core bottom
			translate([0, 0, -coreDia + zBottom])
			cube(size=[coreLen * 2, coreDia * 2, coreDia * 2], center=true);
			
			// a wall at the small end to chop off unneeded extra geometry
			translate([-(coreLen + maxWidth) * 0.5, 0, 0])
			cube(size=[maxWidth, (maxWidth + coreDia) * 2, (maxWidth + coreDia) * 2], center=true);
			
			// a wall at the big end to chop off unneeded extra geometry
			translate([(coreLen + maxWidth) * 0.5, 0, 0])
			cube(size=[maxWidth, (maxWidth + coreDia) * 2, (maxWidth + coreDia) * 2], center=true);
			
		}
			
		// Add a marking to the big end in case it's hard to tell
		//translate([(coreLen + borderSize) * 0.5 - fudge, 0, (coreDia + maxThks[0] * localLenThkRatio) * 0.5])
		//{
		//	rotate([0, -90, 0])
		//		cylinder(h=borderSize, d = symbolSize, center=true, $fn=3);
		//	// add the bottom of the arrow
		//	translate([0, 0, -symbolSize * 0.5 * 0.71828])
		//		cube(size=[borderSize, symbolSize / 3, symbolSize / 3], center=true);
		//}
		
		// Add a barcode
		//translate([0, coreDia > barcode_block_length(serialNo) ? (-coreDia + barcode_block_length(serialNo)) * 0.5  - maxThks[angleCount-1] * localLenThkRatio : 0, 0])		// move the barcode if the object is too big.
		rotate([0, 0, 90])
		translate([0, -coreLen * 0.5 + fudge, zBottom + barcode_thk * 0.5])
		draw_barcode(serialNo, min_width=coreDia + 2 * borderSize);
	}
}


// A special function for determining how far out from the centerline to trave
// to intersect with the diamond-shaped core at a given angle.
// This is derived from a law of Sines argument from the geometry.
function fOffsetHeight(coreDia, angle) = coreDia * 1.4142 / 4 / sin(135 - angle);
