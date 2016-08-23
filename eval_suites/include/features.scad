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
skip_chatter = true;

// quality settings. Since we don't control the scale, force the use of
// a reasonable number of fragments regardless of size.
$fn = 8;

// Defaults for common model parameters. These are overridden by the front end!
layerHeight = 0.2;      // mm
nozzleDiameter = 0.4;   // mm

xyPosGap = 5 * nozzleDiameter;
xyNegGap = 10 * nozzleDiameter;
zPosGap = 10 * layerHeight;
zNegGap = 10 * layerHeight;

overhangSupports = true;

// Ratios used for determining the relative sizes of different features in the
// test part, and the defaults used elsewhere when that parameter is not being
// evaluated.
// These are overridden by the FixedConfig block in config.json.
barLenDiaRatio = 10;		// ratio of length/dia for pos+negative h+v pillars

finLenThkRatio = 10;			// ratio of length/thickness for pos+negative h+v fins
finWidthThkRatio = 10;		// ratio of width (depth)/thickness for pos+neg h+v fins

bossLenDiaRatio = 1;        // ratio of height to diameter for pos+neg h+v bosses+lines


// Barcode variables.
do_barcode = true;
barcode_linewidth = 0.5;
barcode_height = 5;
barcode_thk = 2;
barcode_border = 2;
barcode_end_pad = barcode_border * 3;
barcode_digits = 8;

do_text = true;
text_height = 6;
text_thk = 1.5;
text_font = "Liberation Mono:style=Bold";

barcode_block_height = barcode_border * 2 + (do_barcode ? (barcode_height) : 0) + (do_text ? text_height : 0);

// Chamfer on the bottom of vertical holes is 3 layers
vchamfer_size = layerHeight * 3;


// Color parameters
normalColor = [125/255, 156/255, 159/255, 1];
highlightColor = [255/255, 230/255, 160/255, 1];


// ==============================================================
// Feature Modules
// ==============================================================


// Draws a single fin. Parameters:
//    thk: fin thickness (in x), centered at origin
//    width: fin width (in y), centered at origin
//    length: fin length (in z), starts at z=0
//    pad_thk/width/len: pad values for thickness, width, and length. These are not reported to the front end.
//    do_echo: set to false to suppress echoing the features to the front end.
//    smooth: render the geometry with smooth end caps (circular instead of square)
//    chamfer_size: instead of making cylinders, create an outward chamfer at the bottom of the feature with this size.
module fin(thk, width, length, pad_thk=0, pad_width=0, pad_len=0, do_echo=true, smooth=true, chamfer_size=0)
{

    real_thk = thk + pad_thk;
    real_width = width + pad_width;
    real_len = length + pad_len;
    union()
    {
        translate([0, 0, length * 0.5])
        {
            if(smooth)
            {
                // Smooth Version: Draw cylinders at the ends of the slot
                if(real_width > real_thk)
                {
                    union()
                    {
                        cube(size=[real_thk, real_width - real_thk, real_len], center=true);

                        translate([0, (real_width - real_thk) * 0.5, 0])
                            cylinder(d=real_thk, h=real_len, center=true);
                        translate([0, -(real_width - real_thk) * 0.5, 0])
                            cylinder(d=real_thk, h=real_len, center=true);
                    }
                }
                else
                {
                    cylinder(d=real_thk, h=real_len, center=true);
                }
            }
            else
                cube(size=[real_thk, real_width, real_len], center=true);
        }

        if(chamfer_size > 0)
        {
            chamf_thk = thk + pad_thk + chamfer_size * 2;
            chamf_width = width + pad_width + chamfer_size * 2;
            chamf_len = chamf_thk * 0.5;
            if(smooth)
            {
                // Smooth Version: Draw cylinders at the ends of the slot
                if(chamf_width > chamf_thk)
                {
                    union()
                    {
                        translate([0, 0, -pad_len * 0.5])
                        difference()
                        {
                            scale([1, 1, chamf_len / chamf_thk * 2])
                            rotate([0, 45, 0])
                            cube(size=[chamf_thk / sqrt(2), chamf_width - chamf_thk, chamf_thk / sqrt(2)], center=true);

                            translate([0, 0, -chamf_len])
                            cube(size=[chamf_thk * 2, chamf_width * 2, chamf_len * 2], center=true);
                        }

                        translate([0, (chamf_width - chamf_thk) * 0.5, -pad_len * 0.5])
                            cylinder(d1=chamf_thk, d2=0, h=chamf_len, center=false);
                        translate([0, -(chamf_width - chamf_thk) * 0.5, -pad_len * 0.5])
                            cylinder(d1=chamf_thk, d2=0, h=chamf_len, center=false);
                    }
                }
                else
                {
                    translate([0, 0, -pad_len * 0.5])
                    cylinder(d1=chamf_thk, d2=0, h=chamf_len, center=false);
                }
            }
            else
            {
                translate([0, 0, -pad_len * 0.5])
                difference()
                {
                    intersection()
                    {
                        scale([1, 1, chamf_len / chamf_thk * 2])
                        rotate([0, 45, 0])
                        cube(size=[chamf_thk / sqrt(2), chamf_width, chamf_thk / sqrt(2)], center=true);

                        scale([1, 1, chamf_len / chamf_thk * 2])
                        rotate([45, 0, 0])
                        cube(size=[chamf_thk, chamf_width / sqrt(2), chamf_width / sqrt(2)], center=true);
                    }

                    translate([0, 0, -chamf_len])
                    cube(size=[chamf_thk * 2, chamf_width * 2, chamf_len * 2], center=true);
                }
            }
        }
    }

    if(do_echo && !skip_chatter)
        echo(THK=thk, LEN=length, WIDTH=width > thk ? width : thk);

}

//fin(0.1, 0.2, 0.3, pad_width = 0.5, smooth=true, chamfer_size=0.05);


// Draws one set of positive fins along the x axis, centered at the origin, with height in z, thickness in x
// and width in y. Other parameters:
//    min/max_thk: Minimum and maximum fin thickness.
//    fin_count: Number of fins to create.
//    laspect: Length/thickness aspect ratio to use
//    waspect: Width/thickness aspect ratio to use
//    gap_size: Size of gap between fins. Provide this OR total_width.
//    total_width: Total width of the resulting pattern. Provide this OR gap_size.
//    long_ways: If true, causes fins to be printed end-to-end instead of side-to-side, i.e.
//           thickness in y and width in x.
//    pad_thk/width/len: pad each dimension by this value.
//           (NOT reported to front end; this is a fudge factor to make sure union works)
//    do_echo: Echo fin parameters to the console. Sometimes this is disabled when creating aux geometry that should
//           not be reported.
//    skip: skip the first <skip> entities in the series, for visualization purposes
//    justify_y: causes the y-coordinates to be set so that...
//          -1 : bottoms of all fins are aligned
//          0  : centers of all fins are aligned
//          1  : tops of all fins are aligned
//    override_xs: If desired, a list of fin_count x center coordinates can be supplied and override the normal constant-gap
//    chamfer_size: add a 45° chamfer of this size to the bottom of each fin
//    min_len: Features with length smaller than this will be stretched to be at least this long
module fin_set(min_thk, max_thk, fin_count, laspect, waspect, gap_size=-1, total_width=-1, long_ways=false, pad_thk=0, pad_width=0,
        pad_len=0, smooth=true, do_echo=true, skip=-1, justify_y=0, override_xs=[], chamfer_size=0, min_len=0)
{
	xs = (len(override_xs) == fin_count) ? override_xs :
	        (long_ways ? flocateXs(min_thk * waspect, max_thk * waspect, fin_count, gap_size, total_width) :
	        flocateXs(min_thk, max_thk, fin_count, gap_size, total_width));
	color(skip >= 0 ? highlightColor : normalColor)
	translate([0, -justify_y * max_thk * (long_ways ? 1 : waspect) * 0.5, 0])
	union()
	{
        for(i = [0:fin_count - 1])
        {
            if(i > skip)
            {
                fin_thk = fdia(i, min_thk, max_thk, fin_count);
                fin_len = max(fin_thk * laspect, min_len);
                fin_width = fin_thk * waspect;

                if(long_ways)
                {
                    translate([xs[i], justify_y * (fin_thk + pad_thk) * 0.5, 0])
                    rotate([0, 0, 90])
                        fin(fin_thk, fin_width, fin_len, pad_thk, pad_width, pad_len, do_echo, smooth=smooth, chamfer_size=chamfer_size);
                }
                else
                {
                    translate([xs[i], justify_y * (fin_width + pad_width) * 0.5, 0])
                    fin(fin_thk, fin_width, fin_len, pad_thk, pad_width, pad_len, do_echo, smooth=smooth, chamfer_size=chamfer_size);
                }
            }
        }
    }
}

//fin_set(0.1, 1, 5, 1, 5, gap_size=0.5, justify_y=0, long_ways=false, smooth=true, do_cone=true);

// Convenience function: pillar_set_pos just calls fin_set_pos with appropriate changes in arguments
module pillar_set(min_dia, max_dia, pillar_count, laspect, gap_size=-1, total_width=-1, pad_dia=0, pad_len=0,
            smooth=true, do_echo=true, skip=-1, justify_y=0, override_xs=[], min_len=0)
{
    fin_set(min_dia, max_dia, pillar_count, laspect, 1, gap_size=gap_size, total_width=total_width, long_wasy=false,
            pad_thk=pad_dia, pad_width=pad_dia, pad_len=pad_len, do_echo=do_echo, skip=skip, justify_y=justify_y,
            smooth=smooth, override_xs=override_xs, min_len=min_len);
}
//pillar_set(0.1, 1, 5, 10, total_width=5, justify_y=1, long_ways=true, smooth=false);

// Convenience function: Create a negative fin set by subtracting a normal fin from a larger one.
// by default, the size of the boundary region is gap_size, but this can be adjusted by overriding border_thk.
// if do_outside=true, the outside is rendered. If do_inside=true also, the inside is subtracted out. If
// do_outside=false and do_inside=true, the inside is rendered as positive geometry.
// Setting bottom_chamfer > 0 causes a 45° chamfer of the given size to be added to the bottom of the
// geometry. In this case, the total height is increased proportionally.
module fin_set_neg(min_thk, max_thk, fin_count, laspect, waspect, gap_size=-1, total_width=-1, long_ways=false, pad_thk=0, pad_width=0, pad_len=0,
        do_echo=true, skip=-1, border_thk=-1, do_outside=true, do_inside=true, justify_y=0, inner_smooth=true, outer_smooth=true,
        override_xs=[], bottom_chamfer=0, min_len=0)
{
    extra_len = max(min_thk * 0.1, max_thk * 0.02);//(max_thk - min_thk) / (fin_count - 1) * laspect * 2.1;
    border = max(min_thk * 0.01, border_thk > -1 ? border_thk : (gap_size >= 0 ? gap_size : fgapX(min_thk, max_thk, fin_count, total_width)));

    translate([0, 0, bottom_chamfer * 0.5])
    if(do_outside)
    {
        difference()
        {
            // Draw the outside
            translate([0, -justify_y * border, 0])
            fin_set(min_thk, max_thk, fin_count, laspect, waspect, gap_size=gap_size, total_width=total_width,
                    long_ways=long_ways, pad_thk=pad_thk + border * 2, pad_width=pad_width + border * 2,
                    pad_len=pad_len + bottom_chamfer, do_echo=false, justify_y=justify_y, smooth=outer_smooth,
                    override_xs=override_xs, min_len=min_len);
            // Draw the inside
            if(do_inside)
            {
                fin_set(min_thk, max_thk, fin_count, laspect, waspect, gap_size=gap_size, total_width=total_width,
                        long_ways=long_ways, pad_thk=pad_thk, pad_width=pad_width, pad_len=pad_len + extra_len + bottom_chamfer,
                        do_echo=do_echo, justify_y=justify_y, smooth=inner_smooth, override_xs=override_xs,
                        chamfer_size=bottom_chamfer + 0*extra_len, min_len=min_len);
            }
        }
    }
    else if(do_inside)
    {
        // this is identical to the fin_set above under if(do_inside).
        fin_set(min_thk, max_thk, fin_count, laspect, waspect, gap_size=gap_size, total_width=total_width,
                long_ways=long_ways, pad_thk=pad_thk, pad_width=pad_width, pad_len=pad_len + extra_len + bottom_chamfer,
                do_echo=do_echo, justify_y=justify_y, smooth=inner_smooth, override_xs=override_xs,
                chamfer_size=bottom_chamfer + 0*extra_len, min_len=min_len);
    }
}

/*
difference()
{
fin_set_neg(0.1, 0.2, 5, 3, 5, gap_size=0.5, justify_y=-1, long_ways=false, bottom_chamfer=0.1, inner_smooth=true);
translate([0, 0, 0.1])
cube(size=[10,10,0.6]);
translate([2, 0, 0.5])
rotate([0, 45, 0])
cube(size=[1,2,1], center=true);
}*/

// Convenience function: Use fin_set_neg to create a pillar set
module pillar_set_neg(min_dia, max_dia, pillar_count, laspect, gap_size=-1, total_width=-1, pad_dia=0, pad_len=0, do_echo=true, skip=-1,
        border_thk=-1, do_outside=true, do_inside=true, justify_y=0, inner_smooth=true, outer_smooth=true, override_xs=[],
        bottom_chamfer=0, min_len=0)
{
    fin_set_neg(min_dia, max_dia, pillar_count, laspect, waspect=1, gap_size=gap_size, total_width=total_width, long_ways=false,
            pad_thk=pad_dia, pad_width=pad_dia, pad_len=pad_len, do_echo=do_echo, skip=skip, border_thk=border_thk,
            do_outside=do_outside, do_inside=do_inside, justify_y=justify_y, inner_smooth=inner_smooth,
            outer_smooth=outer_smooth, override_xs=override_xs, bottom_chamfer=bottom_chamfer, min_len=min_len);
}

//pillar_set_neg(0.1, 1, 5, 10, gap_size=0.5, justify_y=1, do_outside=true, inner_smooth=true, outer_smooth=true);
//pillar_set_neg(0.1, 1, 5, 10, total_width=3, justify_y=1, do_outside=true, inner_smooth=true, outer_smooth=true);


// draw_barcode is a convenience function for creating a block with a barcode
// in it using the global barcode parameters.
// The result is centered in x and z and sits with y=0 at its top edge.
module draw_barcode(serialNo)
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
				barcode_block(serialNo, barcode_digits, line_width=barcode_linewidth, bar_height=barcode_height, bar_depth=barcode_thk, center=true, x_margin=barcode_end_pad, y_margin=barcode_border);
			}
			if(do_text)
			{
				translate([0, do_barcode ? (-barcode_height - barcode_border) : 0, 0])
				{
							
					translate([0,  -text_height * 0.5 - barcode_border * 0.5, 0])
					cube([barcode_block_length(serialNo), text_height + barcode_border * 0.5, barcode_thk], center=true);
					
					
					translate([0, -barcode_border * 0.5, 0])
					{
						linear_extrude(height=text_thk + barcode_thk * 0.5, convexity=30)
							text(text=strconcat(digits), size=text_height, font=text_font, halign="center", valign="top", $fn=10);
					}
				}
			}
		}
		if(do_text)
		{
			// carve the negative text on the bottom
			rotate([0, 180, 0])
			translate([0, -barcode_border * 0.5 - (do_barcode ? (barcode_height + barcode_border) : 0), barcode_thk * 0.5])
			{
				linear_extrude(height=barcode_thk, center=true, convexity=30)
					text(text=strconcat(digits), size=text_height, font=text_font, halign="center", valign="top", $fn=10);
			}
		}
	}
}

// Function which returns how long the barcode block turns out to be.
function barcode_block_length(serialNo) = max(
			do_barcode ? (barcode_length(barcode_digits, barcode_linewidth) + barcode_end_pad * 2) : 0,
			do_text ? (num_digits(serialNo) * text_height * 6.5 / 8 + barcode_border * 2) : 0);
//draw_barcode(14, 3);


// ==============================================================
// Resource Modules
// ==============================================================


// fgapX and fseriesSize compute, respectively, gap size and total width when the other is known for a series.
// fgapX will return the gap that should be placed between entities when the total width is known, and
// fseriesSize will return the total width of a series given diameter information and the gap size.
function fgapX(minDia, maxDia, featureCount, coreWidth) = coreWidth / featureCount - 0.5 * (maxDia + minDia);
function fseriesSize(minDia, maxDia, featureCount, gapSize) = (0.5 * (maxDia + minDia) + gapSize) * featureCount + gapSize;

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
				
// returns the x coordinate of feature idx in
// the series that targets constant gap widths, given dimensions and either
// a gap size or a total width over which the series must stretch. If both
// gap size and total width are set, gap size is used.
function flocateX(idx, minDia, maxDia, featureCount, gapSize=-1, totalWidth=-1) =
        let(gap = (gapSize >= 0) ? gapSize : fgapX(minDia, maxDia, featureCount, totalWidth),
            diaStep = fdiaStep(minDia, maxDia, featureCount))
        -fseriesSize(minDia, maxDia, featureCount, gap) / 2 + gap + minDia / 2 +       // pillarFirstX
            idx * 0.5 * (fdia(idx, minDia, maxDia, featureCount) + minDia) + idx * gap;

// Returns a list of x coordinates from flocateX for a series.
function flocateXs(minDia, maxDia, featureCount, gapSize=-1, totalWidth=-1) =
        [ for (i = [0:featureCount-1]) flocateX(i, minDia, maxDia, featureCount, gapSize, totalWidth)];

/*end = fseriesSize(0.2, 1.4, 7, 2) * 0.5;
echo(end);
low = flocateXs(0.2, 1.4, 7, gapSize=2) - [ for (i=[0:7]) fdia(i, 0.2, 1.4, 7) * 0.5];
high = flocateXs(0.2, 1.4, 7, gapSize=2) + [ for (i=[0:7]) fdia(i, 0.2, 1.4, 7) * 0.5];
echo(low=low);
echo(high=high);
echo(concat(-end, low) - concat(high, end));*/

// operator module that translates to the y coordinate of feature idx in
// the series that targets constant gap widths. This is hard-coded to use
// the variables in this module.
module locateY(idx, coreLen, minGap, widthsVector)
{
    pillarFirstY = -coreLen / 2 + minGap;
    
    cy = (pillarFirstY + (idx > 0 ? sumv(widthsVector, idx - 1) : 0) + widthsVector[idx] * 0.5 + idx * minGap);
    
    translate([0, cy, 0])
    children();
}