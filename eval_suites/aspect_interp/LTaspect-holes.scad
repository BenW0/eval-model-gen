/********************************************
 * Length/thickness Aspect Ratio Interpolation Test Model for slots
 *
 * Ben Weiss, University of Washington 2016
 *
 * This model is used to determine the minimum
 * thickness required to obtain printable and
 * acceptable results for vertical slot
 * features at various width/thickness aspect ratios.
 *
 * This model is part of a collection of models
 * for determining angle interpolation information
 * for a printer. 
 *
 * TODO: Parameterize this model so the base thickness
 * does not drop below PosFinThkH.
 *******************************************/

include <../include/features.scad>;

testNo = 10;						// test number to encode in barcode

optionCount = 6;       // number of different thicknesses to produce

// Special variables set by front end.
layerHeight = 0.1;      // mm
nozzleDiameter = 0.1;   // mm

/*
<json>
	{
		"Imports": {
			"basic.yellow_final_NegPillarDiaV":"maxSizeMean",
			"basic.yellow_error_NegPillarDiaV":"maxSizeOffset",
			"basic.yellow_final_NegButtonDiaV":"minSizeMean",
			"basic.yellow_error_NegButtonDiaV":"minSizeOffset",
			
			"basic.yellow_final_PosPillarDiaH":"greenHFinThk",
			"basic.yellow_final_PosFinThkH":"greenHFinThk",
			"basic.yellow_final_NegFinThkV":"greenVSlotThk",
			"basic.yellow_final_PosFinThkV":"greenVFinThk"
		}
	}
</json>
*/

// Results from the main eval model needed here, to be overridden by the GUI.
maxSizeMean = 2.5;
maxSizeOffset = 1;
minSizeMean = 0.5;
minSizeOffset = 0.3;

greenHBarDia = 0.35;
greenHFinThk = 0.25;
greenVSlotThk = 1.5;
greenVFinThk = 0.3;


/*
This is an array variable declaration. It will be expanded into a set of variables
by the backend on load and re-condensed only for communicating with openscad.
The variables min[varBase], max[varBase], and skip[varBase] will be arrays.
<json>
    {
        "Name": ["3:1 Aspect Ratio", 
								 "2:1 Aspect Ratio",
								 "3:2 Aspect Ratio",
								 "3:4 Aspect Ratio",
								 "1:1 Aspect Ratio",
								 "1:1.5 Aspect Ratio",
								 "1:2 Aspect Ratio",
								 "1:2.5 Aspect Ratio",
								 "1:3 Aspect Ratio",
								 "1:4 Aspect Ratio",
								 "1:5 Aspect Ratio",
								 "1:7 Aspect Ratio",
								 "1:9 Aspect Ratio",
								 "1:12 Aspect Ratio"],
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

// These are roughly 2^[-1.6:0.4:3.6]
aspectRatios = [0.333, 0.5, 0.667, 0.75, 1, 1.5, 2, 2.5, 3, 4, 5, 7, 9, 12, 16, 20]; 
ratioCount = len(aspectRatios);


absMinDia = min(minSizeMean - minSizeOffset, maxSizeMean - maxSizeOffset) / 2;
ref_index = 8;		// index of aspectRatios that contains the maxSizeMean datapoint.
minDias = fspread(count=ratioCount, 
								low=minSizeMean - minSizeOffset,
								high=maxSizeMean - maxSizeOffset,
								highIdx=ref_index,
								minVal=absMinDia);
maxDias = fspread(count=ratioCount, 
								low=minSizeMean + minSizeOffset,
								high=maxSizeMean + maxSizeOffset,
								highIdx=ref_index,
								minVal=absMinDia * 2);
								
skipDias = ones(ratioCount) * -1;

// Derived variables
maxDia = max(maxDias);
minDia = min(minDias);
minGap = max([greenVSlotThk, greenHFinThk, greenVFinThk]) * 2;
meanDia = max([ for (i=[0:len(maxDias)-1]) (minDias[i] + maxDias[i]) * 0.5]);

coreWidth = optionCount * meanDia + (optionCount + 1) * minGap;
coreLen = sum(maxDias) + (ratioCount) * minGap;
coreThk = greenHFinThk * 6;

fudge = greenHFinThk * 0.02;



union()
{
	core();
	
	echo(NEGATIVE=true);
	
	for(i = [0:ratioCount-1])
	{
		echo(str("SERIES=", i, "Dias"));
		locateY(i, coreLen, minGap, maxDias)
		difference()
		{
			translate([0, 0, fudge])
			union()
			{
				pillar_set(minDias[i], maxDias[i], aspectRatios[i], coreWidth, optionCount, draw_cubes=true, cube_pad_x=fgapX(minDias[i], maxDias[i], optionCount, coreWidth) + fudge, cube_width_y=maxDias[i] + minGap + 2 * fudge);
			}
			
			scale([1, 1, 2])
			pillar_set(minDias[i], maxDias[i], aspectRatios[i], coreWidth, optionCount, skipDias[i], do_echo=true);
		}
	}
}

module core()
{
	union()
	{
		//cube(size=[coreWidth, coreLen, coreThk], center=true);
		
		// add a barcode
		translate([coreWidth * 0.50 - fudge, 0, coreThk * 0.5])
		rotate([0, 0, 90])
		{
			draw_barcode(testNo, coreThk);
		}
	}
}

