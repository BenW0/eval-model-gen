// Cylindrical test feature object for Minimum Printable Feature Size determination
// Ben Weiss, 2015

pillarLength = 10;
pillarCount = 10;
minPillarDia = 0.3; //mm
maxPillarDia = 3;
outrigger = true;

// quality settings
$fa = 2; // 2 degrees/fragment minimum
$fs = 0.03; // minimum size of fragments, in mm


// derived quantities
coreWidth = maxPillarDia * 1.5;
totalLength = maxPillarDia * pillarCount * 1.5;
pillarStartYZ = coreWidth / 2;
pillarEndYZ = pillarStartYZ + pillarLength;
pillarSpacing = totalLength / pillarCount;
pillarFirstX = -totalLength / 2 + pillarSpacing / 2;

color([125/255, 156/255, 159/255, 1])
{
union()
{
    
    // Build the core
    cube(size=[totalLength, coreWidth, coreWidth], center=true);
    
    // Build the outrigger
    translate([0, -(pillarEndYZ + coreWidth / 2)])
    {
        cube(size=[totalLength, coreWidth, coreWidth], center=true);
    }
    
    // vertical pillars
    pillars();
    
    // horizontal pillars
    rotate([90,0,0])
        pillars();
}
}

// Creates vertical pillars; used to make each set of pillars in turn.
module pillars()
{
    // Build each vertical pillar
    for(i=[0:pillarCount-1])
    {
        // per-pillar variables
        dia = minPillarDia + i * (maxPillarDia - minPillarDia) / pillarCount;
        cx = pillarFirstX + i * pillarSpacing;
        translate([pillarFirstX + i * pillarSpacing, 0, 0])
        {
            cylinder(h=pillarLength + pillarStartYZ + 0.0001, d=dia);
        }
    }
}

