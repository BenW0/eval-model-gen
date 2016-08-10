/********************************************
 * Width/thickness Aspect Ratio Interpolation Test Model for thin positive lines
 *
 * Ben Weiss, University of Washington 2016
 *
 * This model is used to determine the minimum
 * thickness required to obtain printable and
 * acceptable results for vertical thin positive line
 * features at various width/thickness aspect ratios.
 *
 * This model is part of a collection of models
 * for determining angle interpolation information
 * for a printer. 
 *******************************************/

include <../include/features.scad>;

serialNo = 21;						// test number to encode in barcode

optionCount = 6;       // number of different thicknesses to produce

// Special variables set by front end.
layerHeight = 0.1;      // mm
nozzleDiameter = 0.1;   // mm

/*
<json>
	{
		"Imports": {
			"basic.yellow_final_PosFinThkV":"maxSizeMean",
			"basic.yellow_error_PosFinThkV":"maxSizeSpread",
			"basic.yellow_final_PosButtonDiaV":"minSizeMean",
			"basic.yellow_error_PosButtonDiaV":"minSizeSpread",
			
			"basic.yellow_final_PosPillarDiaH":"greenHBarDia",
			"basic.yellow_final_PosPillarDiaV":"greenVBarDia",
			"basic.yellow_final_PosFinThkH":"greenHFinThk",
			"basic.yellow_final_NegFinThkV":"greenVSlotThk",
		}
	}
</json>
*/

// Results from the main eval model needed here, to be overridden by the GUI.
maxSizeMean = 0.4;
maxSizeSpread = 0.3;
minSizeMean = 0.2;
minSizeSpread = 0.1;

greenHBarDia = 0.35;
greenVBarDia = 0.35;
greenHFinThk = 0.25;
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

absMinDia = min(minSizeMean - minSizeSpread, maxSizeMean - maxSizeSpread) / 2;
ref_index = 8;		// index of aspectRatios that contains the maxSizeMean datapoint.
minDias = fspread(count=ratioCount, 
								low=minSizeMean - minSizeSpread,
								high=maxSizeMean - maxSizeSpread,
								highIdx=ref_index,
								minVal=absMinDia);
maxDias = fspread(count=ratioCount, 
								low=minSizeMean + minSizeSpread,
								high=maxSizeMean + maxSizeSpread,
								highIdx=ref_index,
								minVal=absMinDia * 2);
								
skipDias = ones(ratioCount) * -1;

echo(minDias=minDias);
echo(maxDias=maxDias);

// Derived variables
maxFinWidths = [ for (i = [0 : ratioCount - 1]) maxDias[i] * aspectRatios[i] ];
maxDia = max(maxDias);
minDia = min(minDias);
minGap = max([greenVSlotThk, greenHFinThk]) * 2;
meanDia = max([ for (i=[0:len(maxDias)-1]) (minDias[i] + maxDias[i]) * 0.5]);

coreWidth = optionCount * meanDia + (optionCount + 1) * minGap;
coreLen = sum(maxFinWidths) + (ratioCount) * minGap;
coreThk = greenHFinThk * 6;

fudge = greenHFinThk * 0.02;



union()
{
	core();
	
	echo(NEGATIVE=false);
	
	for(i = [0:ratioCount-1])
	{
		length = fbossHeight(0, greenHBarDia, greenVBarDia, layerHeight, nozzleDiameter);
		echo(str("SERIES=", i, "Dias"));
		locateY(i, coreLen, minGap, maxFinWidths)
		translate([0, 0, coreThk * 0.5 - fudge])
		fin_set(minDias[i], maxDias[i], 0, aspectRatios[i], coreWidth, optionCount, skipDias[i], do_echo=true,
		        override_len=length, pad_len=fudge*2);
	}
}

module core()
{
	union()
	{
		cube(size=[coreWidth, coreLen, coreThk], center=true);
		
		// add a barcode
		translate([coreWidth * 0.5 - fudge, 0, 0])
		rotate([0, 0, 90])
			draw_barcode(serialNo, coreThk);
	}

}

