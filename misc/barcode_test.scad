use<barcode.scad>;
 
translate([40, 15, 0])
difference()
{
	code = 1234567;
	cube(size=[barcode_length(num_digits(code)) + 16, 10 + 6, 2],center=true);
	barcode(code, center=true, bar_depth=6, invert=false);
}
translate([40, -15, 0])
difference()
{
	code = 1234567;
	translate([0, 0, -1.1])
	cube(size=[barcode_length(num_digits(code)) + 16, 10 + 6, 4],center=true);
	barcode(code, center=true, bar_depth=2, invert=false);
}
	
	