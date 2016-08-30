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
include <../include/features2.scad>;

serialNo = 0;						// test number to encode in barcode

optionCount = 6;       // number of different thicknesses to produce
onlyHalf = true;
// That parameter will need to become hard-coded here pretty quick in order to match the front end


/*
<json>
	{
		"Imports": {
			"basic.yellow_final_NegHoleDiaV":"vSizeMean",
			"basic.yellow_error_NegHoleDiaV":"vSizeSpread",
			"basic.yellow_final_NegHoleDiaH":"hSizeMean",
			"basic.yellow_error_NegHoleDiaH":"hSizeSpread",

			"basic.yellow_final_NegFinThkV":"greenVSlotThk",
			"basic.yellow_final_NegFinThkH":"greenHSlotThk",
			"basic.yellow_final_PosFinThkH":"greenHFinThk",
			"basic.yellow_final_PosFinThkV":"greenVFinThk"
		}
	}
</json>
*/

// Results from the main eval model needed here, to be overridden by the GUI.
vSizeMean = 3.5;
vSizeSpread = 1;
hSizeMean = 2;
hSizeSpread = 0.5;

greenVFinThk = 0.125;
greenHFinThk = 0.125;
greenVSlotThk = 1.5;
greenHSlotThk = 0.65;


// Aspect ratios to use for this model. These need to match the values provided in the json block!
localLenThkRatio = barLenDiaRatio;
localWidthThkRatio = 1;


/*
This is an array variable declaration. It will be expanded into a set of variables
by the backend on load and re-condensed only for communicating with openscad.
The variables min[varBase], max[varBase], and skip[varBase] will be arrays.

Note that the angles reported are 90° from the angle variable when they are actually computed. the angle variable stores the angle away from vertical.
<json>
    {
        "varBase": "Thks",
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
        "RedKeyword": "Lost",
        "GreenKeyword": "Printed",
        "cameraData": "9.57,-17.9,8.45,57.8,0,314.8,85",
        "sortOrder": 0,
		"instanceCount": 6,
        "coordSign": -1,
        "coordLTaspect":"=barLenDiaRatio",
        "coordWTaspect":1,
        "coordAngleIncl":0
    }
</json>
*/

// Range of thicknesses. These arrays will be overridden by the front end.
angleCount = 10;
angles = [ for (i = [0:angleCount-1]) 90 * i / (angleCount - 1) * (onlyHalf ? 1 : 2) ];

/*minThks = fspread(count=angleCount, 
								low=vSizeMean - vSizeSpread,
								high=hSizeMean - hSizeSpread);
maxThks = fspread(count=angleCount, 
								low=vSizeMean + vSizeSpread,
								high=hSizeMean + hSizeSpread);
*/

//minThks=[4.5,2.99409098772906,2.38889,3.13279565695739,2.27778,2.62,2.583335,1.98758263989,2.57407666666667,2.28027703001625,2.3055525,2.1516809050441,2.27777666666667,2.70964067096207,1.92592333333333,1.94771372493474,1.8888875,1.47255406440453,1.25189743381003];
//maxThks=[8.5,4.91409098772906,6.16667,4.97279565695739,5.83334,3.5,4.249995,3.66758263989,4.12962666666667,3.17919975824393,3.7500025,3.06553186333568,3.61111666666667,4.14964067096207,3.14814333333333,2.47942649739809,2.9999975,2.59209743693078,3.03435463993906];
minThks=[3.28993013796467,2.37221303359186,3.4129844478166,2.96931610168763,1.57407166666667,2.38694668183231,2.75128354375539,1.79230600887754,1.6666675,1.39816834030223];
maxThks=[5.57283699295068,5.2952970415224,4.29680669029393,3.59073920728164,5.12963166666667,3.22293952615663,3.51354935212947,2.92279917382476,3.2222175,2.71472459543363];

skipThks = ones(angleCount) * -1;

echo(angles=angles);
echo(minThks=minThks);
echo(maxThks=maxThks);




// Derived parameters for the object
maxThk = max(maxThks);
maxLen = maxThk * localLenThkRatio;
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
	core();
	
    echo(SIGN=-1);

	for(i = [0:angleCount-1])
	{
		echo(str("SERIES=", i, "Thks"));

		angle = angles[i];
		echo(ANGLE=angle);
		translate([0, i == 0 ? maxThks[0] * 0.33 : 0, 0])	// offset just the vertical fins so it fits better.
		rotate([i % 2 ? angle : -angle, 0, 0])
		translate([0, 0, fOffsetHeight(coreDia, angle)])
            fin_set_neg(minThks[i], maxThks[i], optionCount, localLenThkRatio, localWidthThkRatio,
                    total_width=coreLen, long_ways=true, skip=skipThks[i], pad_len=coreDia * 0.5, border_thk=borderSize,
                    do_echo=true, override_xs=optionXCenters, do_outside=false);
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
			translate([-(coreLen + maxLen) * 0.5, 0, 0])
			cube(size=[maxLen, (maxLen + coreDia) * 2, (maxLen + coreDia) * 2], center=true);
			
			// a wall at the big end to chop off unneeded extra geometry
			translate([(coreLen + maxLen) * 0.5, 0, 0])
			cube(size=[maxLen, (maxLen + coreDia) * 2, (maxLen + coreDia) * 2], center=true);
			
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
