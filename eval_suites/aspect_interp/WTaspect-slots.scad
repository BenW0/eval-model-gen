/********************************************
 * Width/thickness Aspect Ratio Interpolation Test Model for slots
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
 * TODO: Make sure the minDias doesn't go less than 0.
 *******************************************/

include <../include/features.scad>;

testNo = 11;						// test number to encode in barcode

optionCount = 6;       // number of different thicknesses to produce

// Special variables set by front end.
layerHeight = 0.1;      // mm
nozzleDiameter = 0.1;   // mm

/*
<json>
	{
		"Imports": {
			"basic.yellow_final_NegFinThkV":"maxSizeMean",
			"basic.yellow_error_NegFinThkV":"maxSizeOffset",
			"basic.yellow_final_NegPillarDiaV":"minSizeMean",
			"basic.yellow_error_NegPillarDiaV":"minSizeOffset",
			
			"basic.yellow_final_PosPillarDiaH":"greenHFinThk",
			"basic.yellow_final_PosFinThkH":"greenHFinThk",
			"basic.yellow_final_PosFinThkV":"greenVFinThk",
			"basic.yellow_final_NegFinThkV":"greenVSlotThk"
		}
	}
</json>
*/

// Results from the main eval model needed here, to be overridden by the GUI.
maxSizeMean = 0.8;
maxSizeOffset = 0.4;
minSizeMean = 2.5;
minSizeOffset = 1;

greenHBarDia = 0.35;
greenHFinThk = 0.25;
greenVFinThk = 0.3;
greenVSlotThk = 1.5;


/*
This is an array variable declaration. It will be expanded into a set of variables
by the backend on load and re-condensed only for communicating with openscad.
The variables min[varBase], max[varBase], and skip[varBase] will be arrays.
<json>
    {
        "Name": ["1:1 Aspect Ratio", 
								 "1:1.25 Aspect Ratio",
								 "1:1.75 Aspect Ratio",
								 "1:2.3 Aspect Ratio",
								 "1:3 Aspect Ratio",
								 "1:4 Aspect Ratio",
								 "1:5.25 Aspect Ratio",
								 "1:7 Aspect Ratio",
								 "1:9 Aspect Ratio",
								 "1:12 Aspect Ratio",
								 "1:16 Aspect Ratio",
								 "1:20 Aspect Ratio",
								 "1:30 Aspect Ratio"],
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

// These are roughly 2^[0:0.4:4.4]
aspectRatios = [1, 1.25, 1.75, 2.3, 3, 4, 5.25, 7, 9, 12, 16, 20, 30]; 
ratioCount = len(aspectRatios);

// Range of thicknesses. These arrays will be overridden by the front end.

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
maxFinWidths = [ for (i = [0 : ratioCount - 1]) maxDias[i] * aspectRatios[i] ];
maxDia = max(maxDias);
minDia = min(minDias);
minGap = max([greenVSlotThk, greenHFinThk, greenVFinThk]) * 2;
meanDia = max([ for (i=[0:len(maxDias)-1]) (minDias[i] + maxDias[i]) * 0.5]);

coreWidth = optionCount * meanDia + (optionCount + 1) * minGap;
coreLen = sum(maxFinWidths) + (ratioCount) * minGap;
coreThk = greenHFinThk * 6;

fudge = greenHFinThk * 0.02;



union()
{
	core();
	
	echo(NEGATIVE=true);
	
	for(i = [0:ratioCount-1])
	{
		echo(str("SERIES=", i, "Dias"));
		locateY(i, coreLen, minGap, maxFinWidths)
		difference()
		{
			translate([0, 0, fudge])
			union()
			{
				fin_set(minDias[i], maxDias[i], finLenThkRatio, aspectRatios[i], coreWidth, optionCount, cube_pad_x=fgapX(minDias[i], maxDias[i], optionCount, coreWidth) + fudge, force_width_y=maxFinWidths[i] + minGap + 2 * fudge);
			}
			
			scale([1, 1, 2])
			fin_set(minDias[i], maxDias[i], finLenThkRatio, aspectRatios[i], coreWidth, optionCount, skipDias[i], do_echo=true);
		}
	}
}

module core()
{
		// add a barcode
	translate([coreWidth * 0.5 - fudge, 0, coreThk * 0.5])
		rotate([0, 0, 90])
		draw_barcode(testNo, coreThk);

}

