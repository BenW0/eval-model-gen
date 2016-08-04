/********************************************
 * Angle Interpolation Test Model for Bosses
 *
 * Ben Weiss, University of Washington 2016
 *
 * This model is used to determine the minimum
 * thickness required to obtain printable and
 * acceptable results for positive boss
 * features at various angles between horizontal
 * and vertical.
 *
 * This model is part of a collection of models
 * for determining angle interpolation information
 * for a printer. 
 *******************************************/

use<../../misc/barcode.scad>

testNo = 5;

option_count = 6;       // number of different thicknesses to produce
onlyHalf = false;
// That parameter will need to become hard-coded here pretty quick in order to match the front end

layerHeight = 0.1;      // mm
nozzleDiameter = 0.1;   // mm, only supplied in a default mode


/*
<json>
	{
		"Imports": {
			"basic.yellow_final_PosButtonDiaV":"greenVBossDia",
			"basic.yellow_error_PosButtonDiaV":"greenVBossError",
			"basic.yellow_final_PosButtonDiaH":"greenHBossDia",
			"basic.yellow_error_PosButtonDiaH":"greenHBossError",
			
			"basic.yellow_final_PosPillarDiaH":"greenHBarDia",
			"basic.yellow_final_PosPillarDiaV":"greenVBarDia",
			"basic.yellow_final_NegFinThkV":"greenVSlotThk",
			"basic.yellow_final_NegFinThkH":"greenHSlotThk"
			"basic.yellow_final_PosFinThkV":"greenVFinThk",
			"basic.yellow_final_PosFinThkH":"greenHFinThk"
		}
	}
</json>
*/

// Results from the main eval model needed here, to be overridden by the GUI.
greenVBossDia = 0.3;
greenVBossError = 0.1;
greenHBossDia = 0.6;
greenHBossError = 0.2;

greenHBarDia = 0.125;
greenVBarDia = 0.125;
greenVSlotThk = 1.5;
greenHSlotThk = 0.65;
greenVFinThk = 0.5;
greenHFinThk = 0.5;


/*
This is an array variable declaration. It will be expanded into a set of variables
by the backend on load and re-condensed only for communicating with openscad.
The variables min[varBase], max[varBase], and skip[varBase] will be arrays.

Note that the angles reported are 90° from the angle variable when they are actually computed. the angle variable stores the angle away from vertical.
<json>
    {
        "Name": ["90° Vertical Bosses", 
								 "80° Bosses",
								 "70° Bosses",
								 "60° Bosses",
								 "50° Bosses",
								 "40° Bosses",
								 "30° Bosses",
								 "20° Bosses",
								 "10° Bosses",
								 "0° Horizontal Bosses",
								 "-10° Bosses",
								 "-20° Bosses",
								 "-30° Bosses",
								 "-40° Bosses",
								 "-50° Bosses",
								 "-60° Bosses",
								 "-70° Bosses",
								 "-80° Bosses",
								 "-90° Vertical Bosses"],
        "Desc": "Use the slider to indicate how many bosses printed acceptably.",
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

// Range of thicknesses. These arrays will be overridden by the front end.
angleCount = 19;       // number of different fin angles to produce, including vertical and horizontal. Needs to match number of elements in the json Names vector.
angles = [ for (i = [0 : angleCount]) 90 * i / (angleCount - 1) * (onlyHalf ? 1 : 2) ];
minDias = [ for (i = [0 : 1 : angleCount]) 
				0.5 * (
					(greenVBossDia - greenVBossError) * pow(cos(angles[i]), 2) + 
					(greenHBossDia - greenHBossError) * pow(sin(angles[i]), 2)
				) ];
maxDias = [ for (i = [0 : 1 : angleCount]) 
				0.5 * (
					(greenVBossDia + greenVBossError) * pow(cos(angles[i]), 2) + 
					(greenHBossDia + greenHBossError) * pow(sin(angles[i]), 2)
				) ];;
skipDias = [ for (i = [0 : 1 : angleCount]) -1 ];


pi = 3.1416;

// Constants from the main evaluation model
// TODO: Link these somehow to the main file!
hButtonThk = max(greenHBarDia / 2, layerHeight * 3);
vButtonThk = max(greenHBarDia / 2, nozzleDiameter * 3);




// Derived parameters for the object
maxDia = max(maxDias);
minDia = min(minDias);
minGap = max([greenVSlotThk, greenHSlotThk]);
meanDia = max([ for (i=[0:len(maxDias)-1]) (minDias[i] + maxDias[i]) * 0.5]);

coreDia = angleCount * (maxDia + minGap / 2) * 2 / pi * (onlyHalf ? 1 : 0.5);
coreLen = option_count * meanDia + (option_count - 1) * minGap;
echo(coreDia=coreDia);

mountDia = pow(2, round(ln(coreDia / 4 * (onlyHalf ? 1 : 2)) / ln(2)));
echo(MountDiameter=mountDia);

fudge = meanDia * 0.01;		// diameter to use for the mounting holes


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
			translate([0, angle == 0 ? maxDias[0] * 0.33 : 0, 0])	// offset just the vertical fins so it fits better.
			translate([0, angle == 180 ? -maxDias[0] * 0.33 : 0, 0])	// offset just the vertical fins so it fits better.
			rotate([i % 2 ? angle : -angle, 0, 0])
			translate([0, 0, coreDia * 0.5 - fudge])
			pillar_set(minDias[i], maxDias[i], fbossHeight(angle), skipDias[i]);
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
			cylinder(h=coreLen, d=coreDia, center=true, $fn=40);
		if(onlyHalf)
			translate([0, 0, -maxDia * 0.5])
				cube(size=[coreLen, coreDia, maxDia], center=true);
		
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
			translate([0, 0, -coreDia * 0.5 - maxDia])
				cube(size=[coreLen * 2, coreDia * 2, coreDia], center=true);
		}
		
		wallDia = max(greenHFinThk, greenVFinThk) * 4;
		translate([0, 0, -maxDia * (onlyHalf ? 1 : 0)])
		scale([1, (coreDia - wallDia) / coreDia, (coreDia - maxDia * (onlyHalf ? 1 : 2)) / coreDia])
		rotate([45, 0, 0])
			cube(size=[coreLen - wallDia * 2, coreDia * 0.7071, coreDia * 0.7071], center=true);
		
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
			cube(size=[wallDia * 4, mountDia / 3, mountDia / 3], center=true);
	}
}

// Draws one set of fins at a given angle
module pillar_set(min_dia, max_dia, height, skip=-1)
{
	color(skip >= 0 ? highlightColor : normalColor)
	for(i = [0:option_count - 1])
	{
		if(i > skip)
		{
			boss_dia = fdia(i, min_dia, max_dia);
			
			locateX(i, min_dia, max_dia, coreLen)
			translate([0, 0, height * 0.5 - fudge])
				cylinder(d=boss_dia, h=height, center=true, $fn=20);
		}
	}
}


// ==============================================================
// Resource Functions
// ==============================================================

function fdiaStep(minDia, maxDia) = (maxDia - minDia) / (option_count - 1);
function fdia(idx, minDia, maxDia) = minDia + idx * fdiaStep(minDia, maxDia);
function fgapX(minDia, maxDia, seriesWidth) = (seriesWidth - 0.5 * (maxDia + minDia) * option_count) / option_count;

// function to tell us how high to make the bosses
function fbossHeight(angle) = (vButtonThk * abs(90 - angle) + hButtonThk * (90 - abs(90 - angle))) / 90;
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