// Cylindrical test feature object for Minimum Printable Feature Size determination
// Ben Weiss, 2015

pillarAspect = 10;
pillarCount = 10;
minPillarDiaH = .2; //mm
maxPillarDiaH = 2;
minPillarDiaV = 0.2; //mm
maxPillarDiaV = 2;
outrigger = true;
horiz_aspect = true;
skipH = 0;      // set to non-zero to skip rendering the first <skipH> bars
skipV = 0;      // set to non-zero to skip rendering the first <skipV> columns 

// quality settings. Since we don't control the scale, force the use of
// a reasonable number of fragments regardless of size.
//$fa = 10; // 5 degrees/fragment minimum
//$fs = 0.003; // minimum size of fragments, in mm
$fn = 20;

// derived quantities
maxPillarDia = max(maxPillarDiaH, maxPillarDiaV);
coreWidth = maxPillarDia * 1.5;
// coreLength ensures the gap between each pillar is at least 2/3 of either max pillar.
coreLength = max(((minPillarDiaH + maxPillarDiaH) / 2 + maxPillarDia * 0.667) * pillarCount,
                 ((minPillarDiaV + maxPillarDiaV) / 2 + maxPillarDia * 0.667) * pillarCount);
pillarLengthH = pillarAspect * maxPillarDiaH;
pillarStartHV = coreWidth / 2;
pillarEndH = pillarStartHV + pillarLengthH;
pillarSpacing = coreLength / pillarCount;

color([125/255, 156/255, 159/255, 1])
{
union()
{
    
    // Build the core
    cube(size=[coreLength, coreWidth, coreWidth], center=true);
    
    // Build the outrigger
    //translate([0, -(pillarEndH + coreWidth / 2)])
    //    cube(size=[coreLength, coreWidth, coreWidth], center=true);
    
    // vertical pillars
    pillars(minPillarDiaV, maxPillarDiaV, pillarAspect, maxPillarDiaH * 2, false, skipV);
    
    // horizontal pillars
    rotate([90,0,0])
        if(horiz_aspect)
            pillars(minPillarDiaH, maxPillarDiaH, pillarAspect, maxPillarDiaV * 2, outrigger, skipH);
        else
            pillars(minPillarDiaH, maxPillarDiaH, 0, pillarLengthH, outrigger, skipH);
}
}

// Creates vertical pillars; used to make each set of pillars in turn.
// @minDia, @maxDia - minimum and maximum pillar diameters.
// Pillars will have length (height) which is the greater of
// @minLength and @aspect * diameter
// uses global variables pillarCount, pillarFirstX, pillarSpacing
// pillarStartYZ, and coreWidth
// if @outrigger is true, also build an outrigger at the end of the pillars.
// if @skipFirst > 0, the first @skipFirst elements are not generated (this is used for figure generation)
module pillars(minDia, maxDia, aspect, minLength, outrigger=false, skipFirst=0)
{
    gap =(coreLength - 0.5 * (maxDia + minDia) * pillarCount) / ( pillarCount + 0);
    fudge = minDia * 0.02;    // this is enough extra height to fully intersect base/outrigger.
    diaStep = (maxDia - minDia) / (pillarCount - 1);
    pillarFirstX = -coreLength / 2 + gap / 2 + minDia / 2;
    union()
    {
        
        // Build each vertical pillar
        for(i=[0:pillarCount-1])
        {
            // per-pillar variables
            assign(dia = minDia + i * diaStep)
            {
            assign(cx = pillarFirstX + i * 0.5 * (dia + minDia) + i * gap,              h = max(aspect*dia, minLength) + fudge,
                  out_width = dia + gap + (dia + diaStep) * 0.75 * sign(i),              out_height = max(diaStep * aspect * 1.5, coreWidth))
            {
                if(i >= skipFirst)
                {
                    translate([cx, 0, pillarStartHV - fudge / 2])
                        cylinder(h=h, d=dia);
                }
            
                if(outrigger)
                {
                    // sign(i) lets us have different behavior on the first (smallest)
                    // entry so it doesn't overhang awkwardly.
                    translate([cx + dia / 2 + gap / 2 - out_width / 2, 0, pillarStartHV + h + out_height / 2])
                        cube(size=[out_width, coreWidth, out_height], center=true);
                }
            }
            }
        }
    }
}



