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

// NOTENOTENOTENOTE!!!! I changed the Eval Model default aspect ratios for testing!!!
// FIXME TODO //||\\!!!!!!
use<../../misc/barcode.scad>

testNo = 9;						// test number to encode in barcode

option_count = 6;       // number of different thicknesses to produce
onlyHalf = false;
// That parameter will need to become hard-coded here pretty quick in order to match the front end



/*

Note that the angles reported are 90° from the angle variable when they are actually computed. the angle variable stores the angle away from vertical.
<json>
	{
		"Imports": {
			"basic.yellow_final_PosFinThkV":"greenVFinThk",
			"basic.yellow_error_PosFinThkV":"greenVFinError",
			"basic.yellow_final_PosFinThkH":"greenHFinThk",
			"basic.yellow_error_PosFinThkH":"greenHFinError",
			"basic.yellow_final_NegFinThkV":"greenVSlotThk",
			"basic.yellow_final_NegFinThkH":"greenHSlotThk",
			"basic.yellow_final_PosPillarDiaH":"greenHBarDia"
		}
	}
</json>
*/

// Results from the main eval model needed here, to be overridden by the GUI.
greenVFinThk = 0.11;
greenVFinError = 0.06;
greenHFinThk = 0.11;
greenHFinError = 0.06;

greenVSlotThk = 1.5;
greenHSlotThk = 1.5;
greenHBarDia = 0.125;


/*
This is an array variable declaration. It will be expanded into a set of variables
by the backend on load and re-condensed only for communicating with openscad.
The variables min[varBase], max[varBase], and skip[varBase] will be arrays.
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
angleCount = 19;       // number of different fin angles to produce, including vertical and horizontal. Needs to match number of elements in the json Names vector.
angles = [ for (i = [0 : angleCount]) 90 * i / (angleCount - 1) * (onlyHalf ? 1 : 2) ];
minThks = [ for (i = [0 : 1 : angleCount]) 
				0.5 * (
					(greenVFinThk - greenVFinError) * pow(cos(angles[i]), 2) + 
					(greenHFinThk - greenHFinError) * pow(sin(angles[i]), 2)
				) ];
maxThks = [ for (i = [0 : 1 : angleCount]) 
				0.5 * (
					(greenVFinThk + greenVFinError) * pow(cos(angles[i]), 2) + 
					(greenHFinThk + greenHFinError) * pow(sin(angles[i]), 2)
				) ];
skipThks = [ for (i = [0 : 1 : 21]) -1 ];


pi = 3.1416;

// Constants from the main evaluation model
// TODO: Link these somehow to the main file!
finLenThkRatioV = 30;            // ratio of vertical fin thickness to length
finDepthLenRatioV = 0.8;          // ratio of width (depth) to height for center vertical fin



// Derived parameters for the object
maxThk = max(maxThks);
minThk = min(minThks);
minGap = greenVSlotThk / 2;
meanThk = max([ for (i=[0:len(maxThks)-1]) (minThks[i] + maxThks[i]) * 0.5]);
maxLen = maxThk * finLenThkRatioV;

coreDia = angleCount * (maxThk + greenHSlotThk / 2) * 2.5 / pi * (onlyHalf ? 1 : 0.5);
coreLen = option_count * meanThk * finLenThkRatioV * finDepthLenRatioV + (option_count - 1) * minGap;
echo(coreDia=coreDia);

mountDia = pow(2, round(ln(coreDia / 4 * (onlyHalf ? 1 : 2)) / ln(2)));
echo(MountDiameter=mountDia);

fudge = minThk * 0.02;		// diameter to use for the mounting holes

// Barcode variables. TODO: Parameterize these!
draw_barcode = true;
barcode_linewidth = 0.5;
barcode_height = 5;
barcode_border = 3;
barcode_end_pad = 8;
barcode_digits = 8;
barcode_thk = 2;



// Color parameters
normalColor = [125/255, 156/255, 159/255, 1];
highlightColor = [255/255, 230/255, 160/255, 1];

// Render the geometry
color(normalColor)
difference()
{
	union()
	{
		core();

		for(i = [0:angleCount-1])
		{
			angle = angles[i];
			translate([0, i == 0 ? greenHSlotThk * 0.25 : 0, 0])	// offset just the vertical fins so it fits better.
			translate([0, angle == 180 ? greenHSlotThk * 0.25 : 0, 0])	// offset just the vertical fins so it fits better.
			rotate([i % 2 ? angle : -angle, 0, 0])
			translate([0, 0, coreDia * 0.9 * 0.5])
				fin_set(minThks[i], maxThks[i], skipThks[i]);
		}
	}
	core_diff();
}
// Draws the core of the object
module core()
{
	union()
	{
		rotate([0, 90, 0])
			cylinder(h=coreLen, d=coreDia, center=true, $fn=20);
		translate([0, 0, -maxThk * 0.5])
			cube(size=[coreLen, coreDia, maxThk], center=true);
		
		// draw the barcode
		if(draw_barcode)
		{
			echo(barcode_length(barcode_digits, barcode_linewidth));
			translate([-barcode_length(barcode_digits, barcode_linewidth) * 0.5 - barcode_border * 2 - coreLen * 0.5 + fudge, 0, 0])
			barcode_block(testNo, barcode_digits, line_width=barcode_linewidth, bar_height=barcode_height, bar_depth=barcode_thk, center=true, x_margin=barcode_border * 2, y_margin=barcode_border);
		}
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
		
		wallThk = greenVFinThk * 4;
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

// Draws one set of fins at a given angle
module fin_set(min_thk, max_thk, skip=-1)
{
	color(skip >= 0 ? highlightColor : normalColor)
	for(i = [0:option_count - 1])
	{
		if(i > skip)
		{
			fin_thk = fdia(i, min_thk, max_thk);
			fin_len = fin_thk * finLenThkRatioV;
			fin_width = fin_len * finDepthLenRatioV;
			
			locateX(i, min_thk * finLenThkRatioV * finDepthLenRatioV, max_thk * finLenThkRatioV * finDepthLenRatioV, coreLen)
			translate([0, 0, fin_len * 0.5])
				cube(size=[fin_width, fin_thk, fin_len], center=true);
		}
	}
}


// ==============================================================
// Resource Functions
// ==============================================================

function fdiaStep(minDia, maxDia) = (maxDia - minDia) / (option_count - 1);
function fdia(idx, minDia, maxDia) = minDia + idx * fdiaStep(minDia, maxDia);
function fgapX(minDia, maxDia, seriesWidth) = (seriesWidth - 0.5 * (maxDia + minDia) * option_count) / option_count;

// ==============================================================
// Resource Modules
// ==============================================================

// operator module that translates to the x coordinate of feature idx in
// the series that targets constant gap widths
module locateX(idx, minDia, maxDia, seriesWidth, backwards=false)
{
    gap = fgapX(minDia, maxDia, seriesWidth);
    fudge = (minDia);    // this is enough extra height to fully intersect the base feature.
    diaStep = fdiaStep(minDia, maxDia);
    pillarFirstX = -seriesWidth / 2 + gap / 2 + minDia / 2;
    dia = fdia(idx, minDia, maxDia);
    
    cx = (pillarFirstX + idx * 0.5 * (dia + minDia) + idx * gap) * (backwards ? -1 : 1);
    
    translate([cx, 0, 0])
    children();
}