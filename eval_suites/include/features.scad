/********************************************
 * Shared Functions used by many test parts.
 *
 * Ben Weiss, University of Washington 2016
 *
 * This resource function contains methods and variables
 * used by various test parts to avoid repeating code.
 *******************************************/
 
 use <barcode.scad>;
 use <vector_math.scad>;
 
// ==============================================================
// Global Constants
// ==============================================================

pi = 3.1416;

// Testing variable -- turn off most of the echo chatter produced by this module
skip_chatter = false;

// quality settings. Since we don't control the scale, force the use of
// a reasonable number of fragments regardless of size.
$fn = 20;


// Ratios used for determining the relative sizes of different features in the
// test part, and the defaults used elsewhere when that parameter is not being
// evaluated.
pillarLenDiaRatio = 7;		// ratio of length/dia for pos+negative h+v pillars

finLenThkRatio = 12;			// ratio of length/thickness for pos+negative h+v fins
finWidthThkRatio = 10;		// ratio of width (depth)/thickness for pos+neg h+v fins


// Barcode variables. TODO: Parameterize these!
do_barcode = true;
barcode_linewidth = 0.5;
barcode_height = 5;
barcode_border = 2;
barcode_end_pad = 6;
barcode_digits = 8;

do_text = true;
text_height = 8;
text_thk = 1.5;
text_end_pad = 2;
text_font = "Liberation Mono:style=Bold";

barcode_block_height = barcode_border * 2 + (do_barcode ? (barcode_height) : 0) + (do_text ? text_height : 0);


// Color parameters
normalColor = [125/255, 156/255, 159/255, 1];
highlightColor = [255/255, 230/255, 160/255, 1];


// ==============================================================
// Feature Modules
// ==============================================================


// Draws one set of fins at a given length aspect ratios waspect and laspect.
// for constructing the part body, we will specify
// cube_pad_x (x dimension of cube will be hole_dia + cube_pad_x) and
// force_width_y (y dimension of cube will be exactly cube_width_y).
//
// NOTE that cube_pad_x does not affect the number reported to the console
// but force_width_y does.
module fin_set(min_thk, max_thk, laspect, waspect, coreWidth, featureCount, skip=-1, cube_pad_x=0, force_width_y=0, do_echo=false, override_len=0)
{
	color(skip >= 0 ? highlightColor : normalColor)
	for(i = [0:featureCount - 1])
	{
		if(i > skip)
		{
			fin_thk = fdia(i, min_thk, max_thk, featureCount);
			fin_len = override_len > 0 ? override_len : (fin_thk * laspect);
			fin_width = force_width_y > 0 ? force_width_y : fin_thk * waspect;
			
			locateX(i, min_thk, max_thk, coreWidth, featureCount)
			translate([0, 0, fin_len * 0.5])
				cube(size=[fin_thk + cube_pad_x, fin_width, fin_len], center=true);
			
			if(do_echo && !skip_chatter)
				echo(THK=fin_thk, LEN=fin_len, WIDTH=fin_width);
		}
	}
}


// Same as above, but draws the fins long-wise (end-to-end) instead of
// thin to thin. Note that cube_pad_y and force_width_x have the opposite
// letters as above for consistency with the geometry being rendered
//
// cube_pad_y and pad_len do not affect the reported dimensions, but force_width_x
// does.
module fin_set_long(min_thk, max_thk, laspect, waspect, coreWidth, featureCount, skip=-1, cube_pad_y=0, force_width_x=0, do_echo=false, pad_len=0, backwards=false, overrideXs=[])
{
	color(skip >= 0 ? highlightColor : normalColor)
	for(i = [0:featureCount - 1])
	{
		if(i > skip)
		{
			fin_thk = fdia(i, min_thk, max_thk, featureCount);
			fin_len = fin_thk * laspect;
			fin_width = force_width_x > 0 ? force_width_x : fin_thk * waspect;
			
			locateX(i, min_thk * waspect, max_thk * waspect, coreWidth, featureCount, backwards, overrideXs)
			translate([0, 0, fin_len * 0.5])
				cube(size=[fin_width, fin_thk + cube_pad_y, fin_len + pad_len], center=true);
			
			if(do_echo && !skip_chatter)
				echo(THK=fin_thk, LEN=fin_len, WIDTH=fin_width);
		}
	}
}



// Draws one set of holes at a given length aspect ratio laspect.
// for constructing the part body in negative features, we set 
// draw_cubes=true, then specify
//   cube_pad_x (x dimension of cube will be hole_dia + cube_pad_x, not included in
//      echoed geometry) and
//   cube_width_y (y dimension of cube will be exactly cube_width_y, reported in echo).
module pillar_set(min_dia, max_dia, laspect, coreWidth, featureCount, skip=-1, override_len=0, draw_cubes=false, cube_pad_x=0, cube_width_y=0, pad_len=0, backwards=false, do_echo=false, overrideXs=[])
{
	color(skip >= 0 ? highlightColor : normalColor)
	for(i = [0:featureCount - 1])
	{
		if(i > skip)
		{
			hole_dia = fdia(i, min_dia, max_dia, featureCount);
			hole_len = override_len > 0 ? override_len : (hole_dia * laspect);
			
			locateX(i, min_dia, max_dia, coreWidth, featureCount, backwards, overrideXs)
			translate([0, 0, hole_len * 0.5])
			if(draw_cubes)		// for constructing the hull
				cube(size=[hole_dia + cube_pad_x, cube_width_y, hole_len + pad_len], center=true);
			else
				cylinder(d=hole_dia, h=hole_len + pad_len, center=true);
			if(do_echo && !skip_chatter)
				echo(THK=hole_dia, LEN=hole_len, WIDTH=hole_dia);
		}
	}
}

// draw_barcode is a convenience function for creating a block with a barcode
// in it using the global barcode parameters.
// The result is centered in x and z and sits with y=0 at its top edge.
module draw_barcode(serialNo, bar_depth)
{
    if(!skip_chatter)
        echo(SERIAL_NO=serialNo);
	digits = reverse(get_digits(serialNo));
	difference()
	{
		union()
		{
			if(do_barcode)
			{
				translate([0, -0.5 * barcode_height - barcode_border, 0])
				barcode_block(serialNo, barcode_digits, line_width=barcode_linewidth, bar_height=barcode_height, bar_depth=bar_depth, center=true, x_margin=barcode_end_pad, y_margin=barcode_border);
			}
			if(do_text)
			{
				translate([0, do_barcode ? (-barcode_height - barcode_border) : 0, 0])
				{
							
					translate([0,  -text_height * 0.5 - barcode_border * 0.5, 0])
					cube([barcode_block_length(serialNo), text_height + barcode_border * 0.5, bar_depth], center=true);
					
					
					translate([0, -barcode_border * 0.5, 0])
					{
						linear_extrude(height=text_thk + bar_depth * 0.5, convexity=30)
							text(text=strconcat(digits), size=text_height, font=text_font, halign="center", valign="top", $fn=10);
					}
				}
			}
		}
		if(do_text)
		{
			// carve the negative text on the bottom
			rotate([0, 180, 0])
			translate([0, -barcode_border * 0.5 - (do_barcode ? (barcode_height + barcode_border) : 0), bar_depth * 0.5])
			{
				linear_extrude(height=bar_depth, center=true, convexity=30)
					text(text=strconcat(digits), size=text_height, font=text_font, halign="center", valign="top", $fn=10);
			}
		}
	}
}

// Function which returns how long the barcode block turns out to be.
function barcode_block_length(serialNo) = max(
			do_barcode ? (barcode_length(barcode_digits, barcode_linewidth) + barcode_end_pad * 2) : 0,
			do_text ? (num_digits(serialNo) * 6.5 + text_end_pad * 2) : 0);
//draw_barcode(14, 3);


// ==============================================================
// Resource Modules
// ==============================================================


function fgapX(minDia, maxDia, featureCount, coreWidth) = coreWidth / featureCount - 0.5 * (maxDia + minDia);
function fdiaStep(minDia, maxDia, featureCount) = (maxDia - minDia) / (featureCount - 1);
function fdia(idx, minDia, maxDia, featureCount) = minDia + idx * fdiaStep(minDia, maxDia, featureCount);

// Creates a vector containing an linear spread between low and high. 
// Setting low_at and high_at specifies the index at which the low and high ends 
// should be placed in the series (allowing extrapolation).
// Setting min_val forces all entries in the list to be at least min_val
function fspread(count, low, high, lowIdx=0, highIdx=-1, minVal=-99999) = 
				let(high_at = (highIdx > 0 ? highIdx : count - 1),
					low_at = (lowIdx > 0 ? lowIdx : 0),
					slope = (high - low) / (high_at - low_at))
				[ for (i = [0 : count - 1]) 
					max(low + slope * (i - low_at), minVal) ];

// Creates a vector containing a trigonometric interpolation between horizontal 
// and vertical by angle, according to v * cos(theta)^2 + h * sin(theta)^2
// assumes that 0° is vertical, in accordance with my convention in these files.
function fangleSpread(angles, v, h) = 
				[ for (i = [0 : 1 : len(angles) - 1])
					v * pow(cos(angles[i]), 2) + 
					h * pow(sin(angles[i]), 2)
				];
				
// tests for fspread
//echo(OneToTen=fspread(10, 1, 10));
//echo(ZeroToOne=fspread(11, 0, 1));
//echo(LowIdx=fspread(10, 5, 10, lowIdx=4));
//echo(HighIdx=fspread(10, 1, 5, highIdx=4));
//echo(BothIdx=fspread(10, 5, 6, lowIdx=4, highIdx=5));
//echo(MinVal=fspread(10, 1, 10, minVal=4));

function hButtonThk(greenHBarDia, layerHeight) = max(greenHBarDia / 2, layerHeight * 3);
function vButtonThk(greenVBarDia, nozzleDiameter) = max(greenVBarDia / 2, nozzleDiameter * 3);
				
// function to tell us how high to make the bosses
function fbossHeight(angle, greenHBarDia, greenVBarDia, layerHeight, nozzleDiameter) = (vButtonThk(greenVBarDia, nozzleDiameter) * abs(90 - angle) + hButtonThk(greenHBarDia, layerHeight) * (90 - abs(90 - angle))) / 90;
				
// operator module that translates to the x coordinate of feature idx in
// the series that targets constant gap widths.
// specifying overrideXs as a list featureCount long causes this routine
//   to just move to the x location overrideXs[idx].
module locateX(idx, minDia, maxDia, coreWidth, featureCount, backwards=false, overrideXs=[])
{
	if(len(overrideXs) == featureCount)
	{
		translate([overrideXs[idx], 0, 0])
		children();
	}
	else
	{
    gap = fgapX(minDia, maxDia, featureCount, coreWidth);
    diaStep = fdiaStep(minDia, maxDia, featureCount);
    pillarFirstX = -coreWidth / 2 + gap / 2 + minDia / 2;
    dia = fdia(idx, minDia, maxDia, featureCount);
    
    cx = (pillarFirstX + idx * 0.5 * (dia + minDia) + idx * gap) * (backwards ? -1 : 1);
    
    translate([cx, 0, 0])
    children();
	}
}


// operator module that translates to the y coordinate of feature idx in
// the series that targets constant gap widths. This is hard-coded to use
// the variables in this module.
module locateY(idx, coreLen, minGap, widthsVector)
{
    pillarFirstY = -coreLen / 2 + minGap / 2;
    
    cy = (pillarFirstY + (idx > 0 ? sumv(widthsVector, idx - 1) : 0) + widthsVector[idx] * 0.5 + idx * minGap);
    
    translate([0, cy, 0])
    children();
}