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

angleCount = 10;       // number of different fin angles to produce, including vertical and horizontal
// That parameter will need to become hard-coded here pretty quick in order to match the front end



/*
<json>
	{
		"Imports": {
			"basic.yellow_final_PosFinThkV":"greenVFinThk",
			"basic.yellow_final_NegFinThkV":"greenVSlotThk",
			"basic.yellow_final_PosFinThkH":"greenHSlotThk"
		}
	}
</json>
*/

// Results from the main eval model needed here, to be overridden by the GUI.
greenVFinThk = 0.1;
greenVSlotThk = 0.1;
greenHSlotThk = 0.1;


/*
<json>
    {
        "Name": "Vertical Pillars",
        "Desc": "Use the slider to indicate how many columns printed acceptably.",
        "LowKeyword": "Lost",
        "HighKeyword": "Printed",
        "varBase": "PosPillarDiaV",
        "minDefault": 0.1,
        "maxDefault": 2,
        "minDefaultND": "0.5 * nozzleDiameter",
        "maxDefaultND": "5 * nozzleDiameter",
        "cameraData": "9.57,-17.9,8.45,57.8,0,314.8,85",
        "sortOrder": 0
    }
</json>
*/

// Range of thicknesses 
minThk = 0.1;
maxThk = 0.3;
skipThk = -1;

pi = 3.1416;

// Constants from the main evaluation model
// TODO: Link these somehow to the main file!
finLenThkRatioV = 12;            // ratio of vertical fin thickness to length
finDepthLenRatioV = 0.8;          // ratio of width (depth) to height for center vertical fin

option_count = 6;       // number of different thicknesses to produce


// Derived parameters for the object
minGap = max(minThk, maxThk);
meanThk = 0.5 * (minThk + maxThk);

coreDia = (angleCount * maxThk) * 2.5 / pi;
coreLen = option_count * meanThk * finLenThkRatioV * finDepthLenRatioV + (option_count - 1) * minGap;

fudge = minThk * 0.02;

// Render the geometry
union()
{
	core();

	for(i = [0:angleCount - 1])
	{
		angle = 90 * i / (angleCount - 1);
		translate([0, i == 0 ? maxThk * 0.33 : 0, 0])	// offset just the vertical fins so it fits better.
		fin_set(angle, i % 2);
	}
}

// Draws the core of the object
module core()
{
	difference()
	{
		union()
		{
			rotate([0, 90, 0])
				cylinder(h=coreLen, d=coreDia, center=true, $fn=20);
			translate([0, 0, -maxThk * 0.5])
				cube(size=[coreLen, coreDia, maxThk], center=true);
		}
		translate([0, 0, -coreDia * 0.5 - maxThk])
			cube(size=[coreLen * 2, coreDia * 2, coreDia], center=true);
		translate([greenVFinThk * 2, 0, -maxThk])
		scale([1, (coreDia - greenVFinThk * 4) / coreDia, (coreDia + maxThk) / coreDia])
		rotate([45, 0, 0])
			cube(size=[coreLen, coreDia * 0.7071, coreDia * 0.7071], center=true);
	}
}

// Draws one set of fins at a given angle
module fin_set(min_thk, max_thk, angle, mirror=false)
{
	for(i = [0:option_count - 1])
	{
		fin_thk = fdia(i, min_thk, max_thk);
		fin_len = finThk * finLenThkRatioV;
		fin_width = fin_len * finDepthLenRatioV;
		
		rotate([mirror ? angle : -angle, 0, 0])
		locateX(i, min_thk * finLenThkRatioV * finDepthLenRatioV, max_thk * finLenThkRatioV * finDepthLenRatioV, coreLen)
		translate([-fin_width * 0.5, -fin_thk * 0.5, coreDia * 0.9 * 0.5])
			cube(size=[fin_width, fin_thk, fin_len]);
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