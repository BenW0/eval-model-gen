/********************************************
 * Master Aspect Ratio Test Model for negative features
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

serialNo = 50;						// test number to encode in barcode

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
vSizeMean = 0.3;
vSizeSpread = 0.2;
hSizeMean = 0.3;
hSizeSpread = 0.2;

greenVFinThk = 0.125;
greenHFinThk = 0.125;
greenVSlotThk = vSizeMean;
greenHSlotThk = hSizeMean;


// Aspect ratios and angles to use for this model. These need to match the values provided in the json block!
seriesCount = 10;

localLenThkRatios = ones(seriesCount) * finLenThkRatio * 0.5;//[0.5, bossLenDiaRatio, 2, 3, 4, 5, 7, finLenThkRatio, 15, 20];//finLenThkRatio;
localWidthThkRatios = reverse([1, 2, 3, 4, 5, 7, finLenThkRatio, 15, 20, 30]); //ones(seriesCount) * finWidthThkRatio;

angles = ones(seriesCount) * 44.99;
angleCutoff = overhangSupports ? overhangAngle : 45;       // point at which to switch from horizontal to vertical



/*
This is an array variable declaration. It will be expanded into a set of variables
by the backend on load and re-condensed only for communicating with openscad.
The variables min[varBase], max[varBase], and skip[varBase] will be arrays.

Note that the angles reported are 90° from the angle variable when they are actually computed. the angle variable stores the angle away from vertical.
<json>
    {
        "varBase": "Thks",
        "Name": ["2:1 Aspect Ratio",
								 "1:1 Aspect Ratio",
								 "2:1 Aspect Ratio",
								 "3:1 Aspect Ratio",
								 "5:1 Aspect Ratio",
								 "9:1 Aspect Ratio",
								 "16:1 Aspect Ratio",
								 "20:1 Aspect Ratio",
								 "30:1 Aspect Ratio"],
        "Desc": "Use the slider to indicate how many fins printed acceptably.",
        "RedKeyword": "Lost",
        "GreenKeyword": "Printed",
        "cameraData": "9.57,-17.9,8.45,57.8,0,314.8,85",
        "sortOrder": 0,
		"instanceCount": 6,
        "coordSign": -1,
        "coordLTaspect":"=finLenThkRatio * 0.5",
        "coordWTaspect":"=finWidthThkRatio * 0.5",
        "coordAngleIncl":0
    }
</json>
*/

// Range of thicknesses. These arrays will be overridden by the front end.
/*minThks = fspread(count=seriesCount,
								low=vSizeMean - vSizeSpread,
								high=hSizeMean - hSizeSpread);
maxThks = fspread(count=seriesCount,
								low=vSizeMean + vSizeSpread,
								high=hSizeMean + hSizeSpread);
*/
minThks = reverse([0.428237550967913,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1]);
maxThks = reverse([2.42823755096791,1.64071750534706,1.26879830648414,1.08283870705268,0.971262947393805,0.843747793497946,0.748111428076053,0.673727588303469,0.636535668417176,0.599343748530885]);





skipThks = ones(seriesCount) * -1;

echo(angles=angles);
echo(minThks=minThks);
echo(maxThks=maxThks);




// Derived parameters for the object

maxThk = max(maxThks);
minThk = min(minThks);

fudge = (minThk + maxThk) * 0.01;

borderSize = max(xyNegGap, zNegGap);
minReleif = min(2 * borderSize - xyNegGap, xyPosGap * 1.5);

vEmpty = countlt(angles, angleCutoff) == 0;
hEmpty = countlt(angles, angleCutoff) == len(angles);
mergeParts = (localLenThkRatios[0] * maxThk < 4 * barcode_thk) || vEmpty || hEmpty;

// Tally up the biggest chunk in each option
vOptionWidths = [ for (option=[0:optionCount-1])
            max([ for (i=[0:seriesCount-1]) if(angles[i] < angleCutoff) fdia(option, minThks[i], maxThks[i], optionCount) * localWidthThkRatios[i] ]) + borderSize ];
hOptionWidths = [ for (option=[0:optionCount-1])
            max([ for (i=[0:seriesCount-1]) if(angles[i] >= angleCutoff) fdia(option, minThks[i], maxThks[i], optionCount) * localWidthThkRatios[i] ]) + borderSize ];

vCoreLen = sum(vOptionWidths) + 2 * borderSize + fudge;
hCoreLen = sum(hOptionWidths) + 2 * borderSize + fudge;
zBottom = -borderSize * 2;

hStartY = barcode_block_height + (mergeParts ? -fudge * 3 : xyPosGap);
hFirstSlotZ = maxThks[seriesCount-1] * 0.5 + max(borderSize, barcode_thk + borderSize * 0.25);

vOptionXCenters = [ for (option=[0:optionCount-1]) -vCoreLen * 0.5 + borderSize + sumv(vOptionWidths, option) - vOptionWidths[option] * 0.5 ];
hOptionXCenters = [ for (option=[0:optionCount-1]) -hCoreLen * 0.5 + borderSize + sumv(hOptionWidths, option) - hOptionWidths[option] * 0.5 ];

vOffsets = sucsum([ for (i = [0:seriesCount-1])
        let(dtheta = angles[1] - angles[0],
            perp_dist = maxThks[i] * 0.5 + borderSize + 0.5 * maxThks[i-1] * cos(dtheta))
         i > 0 && angles[i] < angleCutoff ? (perp_dist * cos(dtheta) / cos(angles[i-1]) + maxThks[i] * 0.5) : 0]);

hOffsets = reverse(sucsum(reverse([ for (i = [0:seriesCount-1])
        let(dtheta = angles[1] - angles[0],
            perp_dist = maxThks[i] * 0.5 + borderSize + 0.5 * maxThks[i+1] * cos(dtheta))
         i < (seriesCount-1) && angles[i] >= angleCutoff ? (perp_dist * cos(dtheta) / sin(angles[i+1]) + borderSize * 0.5) : 0])));

vCoreWidth = max(vOffsets) + maxThk + borderSize * 2;
hCoreHeight = max(hOffsets) + maxThk + borderSize * 2;

vCoreThk = (maxThk + borderSize) * sin(angleCutoff);
hCoreThk = (maxThk + borderSize) * cos(angleCutoff);


// Render the geometry
color(normalColor)
union()
{
    echo(SIGN=-1);
    if(!vEmpty)
    {
        difference()
        {
            union()
            {
                vCore();


                translate([-vCoreLen * 0.5, -maxThks[0] * 0.5 - borderSize, 0])
                for(i = [0:seriesCount-1])
                {
                    if(angles[i] < angleCutoff)
                    {
                        echo(str("SERIES=", i, "Thks"));

                        angle = angles[i];
                        echo(ANGLE=angle);

                        translate([0, -vOffsets[i], maxThks[i] * 0.5 * sin(angle)])
                        rotate([angle, 0, 0])
                            fin_set_neg(minThks[i], maxThks[i], optionCount, localLenThkRatios[i], localWidthThkRatios[i],
                                    long_ways=true, skip=skipThks[i], pad_len=0., border_thk=borderSize,
                                    do_echo=true, override_xs=vOptionXCenters, do_outside=true, min_len=layerHeight,
                                    bottom_chamfer=vchamfer_size, outer_smooth=false);
                    }
                }
            }

            // cut off the bottom
            translate([-vCoreLen * 0.5, -vCoreWidth * 0.5, -(maxThk + borderSize)])
            cube(size=[vCoreLen * 2, vCoreWidth * 2, 2 * (maxThk + borderSize)], center=true);
        }
    }

    if(!hEmpty)
    {
        difference()
        {
            difference()
            {
                hCore();
                translate([-hCoreLen * 0.5, hStartY, hFirstSlotZ])
                for(i = [0:seriesCount-1])
                {
                    if(angles[i] >= angleCutoff)
                    {
                        echo(str("SERIES=", i, "Thks"));

                        angle = angles[i];
                        echo(ANGLE=angle);

                        translate([0, maxThks[i] * 0.5 * cos(angle), hOffsets[i]])
                        rotate([-angle, 0, 0])
                        fin_set_neg(minThks[i], maxThks[i], optionCount, localLenThkRatios[i], localWidthThkRatios[i],
                                long_ways=true, skip=skipThks[i], pad_len=hCoreThk * 2, border_thk=borderSize,
                                do_echo=true, override_xs=hOptionXCenters, do_outside=false, min_len=nozzleDiameter,
                                outer_smooth=false);
                    }
                }
            }
            // cut off the left side
            translate([-hCoreLen * 0.5, hStartY - (maxThk + borderSize), hCoreHeight])
            cube(size=[hCoreLen * 2, 2 * (maxThk + borderSize), 2 * hCoreHeight], center=true);
        }
    }

	// add a barcode (the same barcode) to each piece
    translate([-barcode_block_length(serialNo) * 0.5, hStartY + fudge, barcode_thk * 0.5])
    draw_barcode(serialNo);

    if(!mergeParts)
    {
        translate([-fudge, -barcode_block_length(serialNo) * 0.5, barcode_thk * 0.5])
        rotate([0, 0, 90])
        draw_barcode(serialNo);
    }

}
// Draws the core of the object
module vCore()
{
	union()
	{
        translate([-vCoreLen * 0.5, -maxThks[0] * 0.5 - borderSize, 0])
	    difference()
	    {
	        // Add a base block
	        translate([0, -vCoreWidth * 0.5 + maxThks[0] * 0.5 + borderSize, vCoreThk * 0.5])
	        cube(size=[vCoreLen, vCoreWidth, vCoreThk], center=true);

            for(i = [0:seriesCount-1])//
            {
                if(angles[i] < angleCutoff)
                {

                    angle = angles[i];
                    translate([0, -vOffsets[i], maxThks[i] * 0.5 * sin(angle)])
                    rotate([angle, 0, 0])
                    {
                        //fin_set_neg(minThks[i], maxThks[i], optionCount, localLenThkRatio, localWidthThkRatio,
                        //        long_ways=true, skip=skipThks[i], pad_len=0, border_thk=borderSize,
                        //        do_echo=true, override_xs=vOptionXCenters, do_inside=false, min_len=layerHeight,
                        //        outer_smooth=false);

                        for(option=[0:optionCount-1])
                        {
                            dia = fdia(option, minThks[i], maxThks[i], optionCount);
                            translate([vOptionXCenters[option], 0, 0])
                            //difference()
                            //{
                                //cube(size=[dia * localWidthThkRatio + 2 * borderSize, dia + 2 * borderSize, (dia + borderSize) * 2], center=true);
                                //translate([0, 0, -(dia + borderSize)])
                                // the z coordinate is just "crazy big"
                                cube(size=[max(minReleif, dia * localWidthThkRatios[i] + 2 * vchamfer_size), dia + borderSize, vCoreWidth], center=true);
                                //rotate([-angle, 0, 0])
                                //translate([0, (dia * 0.5 + borderSize) * cos(angle) + (dia + borderSize) * 2, 0])
                                //cube(size=[dia * localWidthThkRatio + 4 * borderSize, (dia + borderSize) * 4, (dia + borderSize) * 2], center=true);
                            //}
                        }
                    }
                }
            }

        }

    }

}

module hCore()
{
    translate([-hCoreLen * 0.5, hStartY, 0])
    union()
    {
        difference()
        {
	        // Add a base block
	        translate([0, hCoreThk * 0.5, hCoreHeight * 0.5])
	        cube(size=[hCoreLen, hCoreThk, hCoreHeight], center=true);

            // sutbract from the base block the keepaway zones so the slits go all the way through
            translate([0, 0, hFirstSlotZ])
            for(i = [0:seriesCount-1])//7:8
            {
                if(angles[i] >= angleCutoff)
                {
                    angle = angles[i];

                    translate([0, maxThks[i] * 0.5 * cos(angle), hOffsets[i]])
                    rotate([-angle, 0, 0])
                    {
                    //translate([0, 0, fOffsetHeight(coreDia, angle)])
                    //    fin_set_neg(minThks[i], maxThks[i], optionCount, localLenThkRatio, localWidthThkRatio,
                    //            long_ways=true, skip=skipThks[i], pad_len=0., border_thk=borderSize,
                    //            do_echo=true, override_xs=hOptionXCenters, do_inside=false);
                        for(option=[0:optionCount-1])
                        {
                            dia = fdia(option, minThks[i], maxThks[i], optionCount);
                            translate([hOptionXCenters[option], 0, 0])
                                //cube(size=[dia * localWidthThkRatio + 2 * borderSize, dia + 2 * borderSize, (dia + borderSize) * 2], center=true);
                                //translate([0, 0, -(dia + borderSize)])
                                // the z coordinate is just "crazy big"
                                cube(size=[max(minReleif, dia * localWidthThkRatios[i]), dia + borderSize, vCoreWidth], center=true);
                        }
                    }
                }
            }

        }

        // Add the border (outer) part of the horizontal features and appropriate supports
        for(i = [0:seriesCount-1])//
        {
            if(angles[i] >= angleCutoff)
            {

                angle = angles[i];

                translate([0, maxThks[i] * 0.5 * cos(angle), hOffsets[i] + hFirstSlotZ])
                {
                    rotate([-angle, 0, 0])
                        fin_set_neg(minThks[i], maxThks[i], optionCount, localLenThkRatios[i], localWidthThkRatios[i],
                                long_ways=true, skip=skipThks[i], pad_len=0., border_thk=borderSize,
                                do_echo=false, override_xs=hOptionXCenters, do_inside=false, min_len=nozzleDiameter,
                                outer_smooth=false);

                    // build the overhangs
                    if(overhangSupports)
                    {
                        l_start = 0;
                        y_start = l_start * sin(angle);
                        z_start = -(hOffsets[i] + hFirstSlotZ);

                        for(option=[0:optionCount-1])
                        {
                            dia = fdia(option, minThks[i], maxThks[i], optionCount);
                            x_span = dia * localWidthThkRatios[i] + 2 * borderSize - 2 * fudge;
                            x_center = hOptionXCenters[option];
                            l_size = dia * localLenThkRatios[i];
                            y_end = (l_start + l_size) * sin(angle) + ((borderSize + dia * 0.5) * cos(angle) - fudge);
                            z_end = (l_start + l_size) * cos(angle);
                            y_span = abs(y_end - y_start);
                            z_span = abs(z_end - z_start);
                            //echo(x_center=x_center, x_span=x_span, y_start=y_start, y_end=y_end, z_start=z_start, z_end=z_end);

                            difference()
                            {
                                translate([x_center, 0.5 * (y_start + y_end), 0.5 * (z_start + z_end)])
                                cube(size=[x_span, y_span, z_span], center=true);

                                rotate([-angle, 0, 0])
                                translate([x_center, -0.5 * y_span, l_start + l_size * 0.5])
                                cube(size=[x_span * 2, dia + 2 * borderSize - fudge * 2 + y_span, l_size * 2], center=true);

                                translate([x_center, 0.5 * (y_start + y_end), 0.5 * (z_start + z_end)])
                                cube(size=[x_span - xyNegGap * 2 - fudge, y_span * 2, z_span * 2], center=true);

                                cut_size = max(y_span, z_span);
                                translate([x_center, y_end, z_end - (borderSize + dia * 0.5) * sin(angle)])
                                rotate([-overhangAngle, 0, 0])
                                translate([0, cut_size, -0.5 * cut_size])
                                cube(size=[x_span * 2, 2 * cut_size, 2 * cut_size], center=true);
                            }
                        }
                    }
                }
            }
        }
	}
}