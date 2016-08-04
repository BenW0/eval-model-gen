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
 *******************************************/

use <../include/barcode.scad>;

testNo = 6;						// test number to encode in barcode

optionCount = 6;       // number of different thicknesses to produce

// Special variables set by front end.
layerHeight = 0.1;      // mm
nozzleDiameter = 0.1;   // mm

/*
<json>
	{
		"Imports": {
			"basic.yellow_final_NegPillarDiaV":"greenVHoleDia",
			"basic.yellow_error_NegPillarDiaV":"greenVHoleError",
			"basic.yellow_final_NegFinThkV":"greenVSlotThk",
			"basic.yellow_error_NegFinThkV":"greenVSlotError",
			
			"basic.yellow_final_PosPillarDiaH":"greenHFinThk",
			"basic.yellow_final_PosFinThkH":"greenHFinThk",
			"basic.yellow_final_NegFinThkV":"greenVSlotThk",
		}
	}
</json>
*/

// Results from the main eval model needed here, to be overridden by the GUI.
greenVHoleDia = 2.5;
greenVHoleError = 1;
greenVSlotThk = 0.8;
greenVSlotError = 0.4;

greenHBarDia = 0.35;
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

// These are roughly 2^[0:0.4:4.4]
aspectRatios = [1, 1.25, 1.75, 2.3, 3, 4, 5.25, 7, 9, 12, 16, 20, 30]; 
ratioCount = len(aspectRatios);

// Ratios from the basic model, not super critical, but helps with default guesses:
finLenThkRatioV = 12;            // ratio of vertical fin thickness to length
finDepthLenRatioV = 0.8;          // ratio of width (depth) to height for center vertical fin



// Range of thicknesses. These arrays will be overridden by the front end.
ref_index = 8;		// index of aspectRatios that contains pillarVSizeRatio.
minDias = [ for (i = [0 : 1 : ratioCount - 1]) ((greenVHoleDia - greenVHoleError) * (ref_index - i) + (greenVSlotThk - greenVSlotError) * i) / ref_index ];
maxDias = [ for (i = [0 : 1 : ratioCount - 1]) ((greenVHoleDia + greenVHoleError) * (ref_index - i) + (greenVSlotThk + greenVSlotError) * i) / ref_index ];
skipDias = [ for (i = [0 : 1 : ratioCount - 1]) -1 ];


// Derived variables
maxFinWidths = [ for (i = [0 : ratioCount - 1]) maxDias[i] * aspectRatios[i] ];
maxDia = max(maxDias);
minDia = min(minDias);
minGap = max([greenVSlotThk, greenHFinThk]) * 2;
meanDia = max([ for (i=[0:len(maxDias)-1]) (minDias[i] + maxDias[i]) * 0.5]);

coreWidth = optionCount * meanDia + (optionCount + 1) * minGap;
coreLen = sum(maxFinWidths) + (ratioCount) * minGap;
coreThk = greenHFinThk * 6;
echo(coreLen=coreLen);

fudge = greenHFinThk * 0.02;

// Barcode variables. TODO: Parameterize these!
barcode_linewidth = 0.5;
barcode_height = 5;
barcode_border = 2;
barcode_end_pad = 6;
barcode_digits = 8;

// Color parameters
normalColor = [125/255, 156/255, 159/255, 1];
highlightColor = [255/255, 230/255, 160/255, 1];

$fn=20;


union()
{
	core();
	
	for(i = [0:ratioCount-1])
	{
		// Locating in y is pretty complicated because of the arbitrary aspect ratios. So we us a module.
		locateY(i)
		difference()
		{
			translate([0, 0, fudge])
			union()
			{
				hull()
					fin_set(minDias[i], maxDias[i], aspectRatios[i], coreWidth, optionCount, -1, force_width=maxFinWidths[i] + 1.5 * minGap);
				
				// wall on the big end
				translate([coreWidth * 0.5 - minGap * 0.5, 0, maxDias[i] * finLenThkRatioV * 0.5])
					cube([minGap + fudge, maxFinWidths[i] + 1.5 * minGap, maxDias[i] * finLenThkRatioV], center=true);
				
				// wall on the little end
				translate([-coreWidth * 0.5 + minGap * 0.5, 0, minDias[i] * finLenThkRatioV * 0.5])
					cube([minGap + fudge, maxFinWidths[i] + 1.5 * minGap, minDias[i] * finLenThkRatioV], center=true);
			}
			
			scale([1, 1, 2])
			fin_set(minDias[i], maxDias[i], aspectRatios[i], coreWidth, optionCount, skipDias[i]);
		}
	}
}

module core()
{
	union()
	{
		//cube(size=[coreWidth, coreLen, coreThk], center=true);
		
		// add a barcode
		translate([coreWidth * 0.50, 0, coreThk * 0.5])
		rotate([0, 0, 90])
		{
			translate([0, -0.5 * barcode_height - barcode_border + fudge, 0])
			{
				difference()
				{
					cube(size=[barcode_length(barcode_digits, barcode_linewidth) + barcode_end_pad * 2, barcode_height + barcode_border * 2, coreThk - 2 * fudge], center=true);
					barcode(testNo, barcode_digits, line_width=barcode_linewidth, bar_height=barcode_height, bar_depth=coreThk, center=true);
				}
			}
		}
	}
}



// Draws one set of fins at a given width aspect ratio
module fin_set(min_thk, max_thk, waspect, coreWidth, featureCount, skip=-1, force_width=0)
{
	color(skip >= 0 ? highlightColor : normalColor)
	for(i = [0:featureCount - 1])
	{
		if(i > skip)
		{
			fin_thk = fdia(i, min_thk, max_thk, featureCount);
			fin_len = fin_thk * finLenThkRatioV;
			fin_width = force_width > 0 ? force_width : fin_thk * waspect;
			
			locateX(i, min_thk, max_thk, coreWidth, featureCount)
			translate([0, 0, fin_len * 0.5])
				cube(size=[fin_thk, fin_width, fin_len], center=true);
		}
	}
}

// ==============================================================
// Resource Materials
// ==============================================================

function fgapX(minDia, maxDia, featureCount, coreWidth) = (coreWidth - 0.5 * (maxDia + minDia) * featureCount) / ( featureCount + 0);
function fdiaStep(minDia, maxDia, featureCount) = (maxDia - minDia) / (featureCount - 1);
function fdia(idx, minDia, maxDia, featureCount) = minDia + idx * fdiaStep(minDia, maxDia, featureCount);
function fcylHeight(dia, aspect, minLength) = max(aspect*dia, minLength) + fudge;

// operator module that translates to the x coordinate of feature idx in
// the series that targets constant gap widths
module locateX(idx, minDia, maxDia, coreWidth, featureCount, backwards=false)
{
    gap = fgapX(minDia, maxDia, featureCount, coreWidth);
    diaStep = fdiaStep(minDia, maxDia, featureCount);
    pillarFirstX = -coreWidth / 2 + gap / 2 + minDia / 2;
    dia = fdia(idx, minDia, maxDia, featureCount);
    
    cx = (pillarFirstX + idx * 0.5 * (dia + minDia) + idx * gap) * (backwards ? -1 : 1);
    
    translate([cx, 0, 0])
    children();
}


// operator module that translates to the y coordinate of feature idx in
// the series that targets constant gap widths. This is hard-coded to use
// the variables in this module.
module locateY(idx)
{
    pillarFirstY = -coreLen / 2 + minGap / 2;
    
    cy = (pillarFirstY + (idx > 0 ? sumv(maxFinWidths, idx - 1) : 0) + maxFinWidths[idx] * 0.5 + idx * minGap);
    
    translate([0, cy, 0])
    children();
}