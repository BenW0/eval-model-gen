// Barcode generator test
// This script generates an interleaved 2of5 barcode for marking parts
// Source data: https://en.wikipedia.org/wiki/Interleaved_2_of_5
//
// NOTE: functions barcode() and barcode_block() only work
// for codes up to about 15 digits before we reach double precision
// roundoff. For longer codes, use barcode_long() and specify the
// digits as an array.

use <vector_math.scad>;

testing = false;
if(testing)
{
	input = 1;


	translate([5, 10, 0])
	color([0.1, 0.1, 0.1])
	echo(barcode_length=barcode_length(4, 0.5));
	barcode(input, min_digits=4, line_width=0.5,center=true);
}

// barcode() works for codes up to 15 digits long. After that, my ability to discern
// digits is constrained by floating point arithematic. To get more digits, use 
// barcode_long and pass it an array of digits.
//
// Parameters:
//   code: number to encode into the barcode
//   min_digits: minimum number of digits (so code=1, min_digits=4 encodes "0004")
//   invert: make the geometry the spaces instead of the bars. This is sometimes useful
//      for example when doing a difference().
//   line_width=1: width of a thin line or gap in model units
//   bar_heigth=10: height of the barcode bars in model units
//   bar_depth=1: depth of the barcode object (thickness into the page)
//   thick_thin_ratio=2.5: ratio of the thick line to thin line thickness. Should be 2.2-3.0
//   center=false: draw the object at the origin centered (similar to cube()).
module barcode(code, min_digits=0, invert=false, line_width=1, bar_height=10, bar_depth = 1, thick_thin_ratio=2.5, center=false)
{
	raw = get_digits(code);
	input = concat(zeros(min_digits - len(raw)), raw);
	barcode_long(input, min_digits, invert, line_width, bar_height, bar_depth, thick_thin_ratio, center);
}
module barcode_long(input_digits, min_digits=0, invert=false, line_width=1, bar_height=10, bar_depth = 1, thick_thin_ratio=2.5, center=false)
{
	

	bar_widths = [line_width, line_width * thick_thin_ratio];		// widths of the bars.
	start_code = [0, 0, 0, 0];
	end_code = [1, 0, 0];
	digit_codes = [[0,0,1,1,0],
						[1,0,0,0,1],
						[0,1,0,0,1],
						[1,1,0,0,0],
						[0,0,1,0,1],
						[1,0,1,0,0],
						[0,1,1,0,0],
						[0,0,0,1,1],
						[1,0,0,1,0],
						[0,1,0,1,0]];
	// We can only encode an even number of digits
	digits = len(input_digits) % 2 == 0 ? input_digits : concat(0, input_digits);
	if(testing) echo(digits=digits);
	
	// do the interleaving so we have a single vector of widths for each step
	widths = veclookup(bar_widths, concat(start_code,
									flatten([ for (i = [0 : 2 : len(digits) - 1]) 
												interleave(digit_codes[digits[i]], digit_codes[digits[i+1]]) ]),
									end_code));
	centers = sucsum(concat(0,widths)) + widths * 0.5;
	if(testing) echo(widths=widths);
	if(testing) echo(centers=centers);

	// Now we just have to generate the solids
	translate(center ? [-barcode_length(len(digits), line_width, thick_thin_ratio) * 0.5, -bar_height * 0.5, -bar_depth * 0.5] : [0, 0, 0])
	for(i = [(invert ? 1 : 0):2:(len(widths) - 1)])
	{
		translate([centers[i], bar_height * 0.5, bar_depth * 0.5])
		cube(size=[widths[i], bar_height, bar_depth], center=true);
	}
}

// Creates a negative barcode in a block (convenience function)
module barcode_block(code, min_digits=0, invert=false, line_width=1, bar_height=10, bar_depth = 1, thick_thin_ratio=2.5, center=false, x_margin=8, y_margin=4)
{
	translate(center ? [0, 0, 0] : [0.5 * barcode_length(num_digits(code)) + x_margin, 0.5 * bar_height + y_margin, bar_depth * 0.5])
	difference()
	{
		cube(size=[barcode_length(max(min_digits, num_digits(code)), line_width) + x_margin * 2, bar_height + y_margin * 2, bar_depth],center=true);
		barcode(code, min_digits, invert, line_width, bar_height, bar_depth * 1.01, thick_thin_ratio, center=true);
	}
}

// Utility function: returns the width of the barcode, given the number of digits
function barcode_length(num_digits, line_width=1, thick_thin_ratio=2.5) = (4 + (2 + thick_thin_ratio) + (thick_thin_ratio * 2 + 3) * ceil(num_digits/2)*2) * line_width;

// returns the successive digits in a number.
function num_digits(num) = num == 0 ? 1 : ceil(log(num + 0.001));
function get_digits(num) = [ for (i = [num_digits(num):-1:1]) floor((num % pow(10, i)) / pow(10, i-1)) ];
	
