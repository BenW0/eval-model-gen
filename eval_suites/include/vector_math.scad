// vector_math.scad - a scad file containing resource functions for working with vectors.
// Ben Weiss, University of Washington 2016


// returns a list of zeros of a specified length
function zeros(size) = size > 0 ? [ for (i = [0:size-1]) 0 ] : [];
function ones(size) = size > 0 ? [ for (i = [0:size-1]) 1 ] : [];

// flattens a list
// output : list with the outer level nesting removed
function flatten(l) = [ for (a = l) for (b = a) b ] ;

// interleaves two vectors and returns the result. The vectors must be the same length.
function interleave(first, second) = flatten([ for (i = [0 : 1 : len(first) - 1]) [first[i], second[i]] ]);

// returns the map [a[b[0]], a[b[1]], ..., a[b[n]]]
function veclookup(a, b) = [ for (i = [0 : 1 : len(b) - 1]) a[b[i]] ];

// generate a list of ordinal numbers (0, 1, 2...), as you would normally get using
// [start:step:end].
function series(start, step, end) = [ for (i = [start : step : end]) i ];
	
// Reverses the order in a list
function reverse(list) = [ for (i = [0:len(list)-1]) list[len(list) - 1 - i] ];

// recursion - find the sum of the values in a vector (array)
// from the start (or s'th element) to the i'th element - remember elements are zero based

function sumv(v,i,s=0) = (i==s ? v[i] : v[i] + sumv(v,i-1,s));
function sum(v) = sumv(v, len(v) - 1);
function sucsum(v) = [ for (i = [0 : len(v) - 1]) sumv(v, i)];

// Similar to the above, but recursively combines all elements into a single string, without commas.
function strconcatv(v, i, s=0) = (i==s ? str(v[i]) : str(str(v[i]), strconcatv(v,i-1,s)));
function strconcat(v) = strconcatv(v, len(v) - 1);
	
// Take the first or last few elements of a vector. Use negative n to read from the end.
function take(vec, n=1) = [ for (i = [0 : abs(n)-1]) n < 0 ? vec[len(vec) - i - 1] : vec[i] ];
	
// Pick a single element out of a list. This is like [k], except [-k] counts from the end. FUTURE: Support splicing by specifying k as a list.
function elem(vec, k) = k >= 0 ? vec[k] : vec[len(vec) + k];

// Count the number of elements in the list equal to, greater than, or less than the second argument
function counteq(vec, val) = len([ for (i = [0:len(vec) - 1]) if(vec[i] == val) 1]);
function countgt(vec, minval) = len([for (i = [0:len(vec) - 1]) if(vec[i] > minval) 1]);
function countlt(vec, minval) = len([for (i = [0:len(vec) - 1]) if(vec[i] < minval) 1]);

//echo(counteq([1, 2, 3, 4, 5, 2, 3, 2], 2));     // 3
//echo(counteq([1, 2, 3, 4, 5, 2, 3, 2], 3));     // 2
//echo(counteq([1, 2, 3, 4, 5, 2, 3, 2], 8));     // 0
//echo(countgt([1, 2, 3, 4, 5, 2, 3, 2], 8));     // 0
//echo(countgt([1, 2, 3, 4, 5, 2, 3, 2], 4));     // 1
//echo(countgt([1, 2, 3, 4, 5, 2, 3, 2], 1));     // 7