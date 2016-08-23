/********************************************
 * This file produces a basic test part as part
 * of the Evaluation Models test suite for
 * minimum feature size characterization
 * of additive manufacturing machines
 *
 * Ben Weiss, University of Washington 2016
 *
 * This model is used to determine the minimum
 * thickness required to obtain printable and
 * acceptable results for a set of 16
 * features.
 *
 * This model is designed to be manipulated
 * and built by another program which
 * adapts the features to match printer
 * performance
 *******************************************/

include <../include/features.scad>;

instanceCount = 7;       // also change this in each block of the JSON below...

// List of features in this model, by base variable name
// VBar
// VFin
// VBoss - note that this represents the diameter of the boss, not the thickness
// VLine
//
// HBar
// HFin
// HBoss
// HLine
//
// VHole - this is a deep vertical through hole
// VSlot
// VPunch - this is a shallow vertical through hole; the variable referred to is the hole diameter
// VSlit
//
// HHole
// HSlot
// HPunch
// HSlit

//BEGIN VARIABLE SETUP =================================================================================================

// Variables set by Eval Model server. For each set of min/max variables, there is a very specific comment
// structure that needs to be present in this file to configure the server (backend and frontend). The
// comment begins with the special string "json" and ends with "/json" enclosed in gthan/lthan brackets,
// and the text between them needs to be structured JSON text as shown below.
//
// After adding or removing blocks, run modelparams.py to update the static images used for visualization.
// The JSON fields are these:
//  - varBase: Variable names. OpenSCAD should include these variables: min<varBase>, max<varBase>, skip<varBase>
//    NOTE: These names are also the database keys, so changeing them will break compatibility with old models.
//  - Name: Plain text name of the parameter (for web page use)
//  - Desc: Plain text description of what the user should do for this test
//  - GreenKeyword: Keyword for the Green state (UI only)
//  - RedKeyword: Keyword for the Red state (UI only)
//  - clampMin/Max: (optional) minimum and maximum values this parameter should be allowed to take; enforced by the front end
//  - sortOrder: This (optional) variable specifies an ordering number for sorting the parameters on the front end
//    (otherwise they will be sorted arbitrarily). Low value is higher in the list of parameters.
//  - instanceCount: Number of copies of the feature present in the test part. For this model, these are all 7,
//    because instanceCount = 7.
// * All of the following are nominal values of the coordinate for each feature in the feature space. The real
//   produced geometry is echoed to the console and stored in the Raw table in the database. These values
//   are used for high-level comparisons and should be correct > 90% of the time.
//  - coordSign: Sign of this feature (1/-1). Positive features extend beyond the part (bar, fin, etc); negative
//    features are holes/slots/etc within the part
//  - coordLTaspect: Len/Thickness aspect for this feature
//  - coordWTaspect: Width/Thickness aspect for this feature
//  - coordAngleIncl: Incline angle of the primary face (0 = vertical, 90 = horizontal)

/*
<json>
    {
        "varBase": "VBar",
        "Name": "Vertical Pillars",
        "Desc": "Use the toggles to indicate which columns printed acceptably.",
        "RedKeyword": "Lost",
        "GreenKeyword": "Printed",
        "clampMin": "nozzleDiameter",
        "cameraData": "",
        "sortOrder": 0,
        "instanceCount": 7,
        "coordSign": 1,
        "coordLTaspect":"barLenDiaRatio",
        "coordWTaspect":1,
        "coordAngleIncl":0
    }
</json>
*/

minVBar = nozzleDiameter; //mm
maxVBar = instanceCount * nozzleDiameter;
skipVBar = -1;      // skip the first <> items when building (for visualization purposes)

/*
<json>
    {
        "varBase": "VFin",
        "Name": "Vertical Fins",
        "Desc": "Use the toggles to indicate which fins printed acceptably.",
        "RedKeyword": "Lost",
        "GreenKeyword": "Printed",
        "clampMin": "nozzleDiameter",
        "cameraData": "",
        "sortOrder": 0,
        "instanceCount": 7,
        "coordSign": 1,
        "coordLTaspect":"finLenDiaRatio",
        "coordWTaspect":"finWidthThkRatio",
        "coordAngleIncl":0
    }
</json>
*/

minVFin = nozzleDiameter; //mm
maxVFin = instanceCount * nozzleDiameter;
skipVFin = -1;      // skip the first <> items when building (for visualization purposes)

/*
<json>
    {
        "varBase": "VBoss",
        "Name": "Vertical Bosses",
        "Desc": "Use the toggles to indicate which bosses printed acceptably.",
        "RedKeyword": "Lost",
        "GreenKeyword": "Printed",
        "clampMin": "nozzleDiameter",
        "cameraData": "",
        "sortOrder": 0,
        "instanceCount": 7,
        "coordSign": 1,
        "coordLTaspect":"bossLenDiaRatio",
        "coordWTaspect":1,
        "coordAngleIncl":0
    }
</json>
*/

minVBoss = nozzleDiameter; //mm
maxVBoss = instanceCount * nozzleDiameter;
skipVBoss = -1;      // skip the first <> items when building (for visualization purposes)

/*
<json>
    {
        "varBase": "VLine",
        "Name": "Vertical Line",
        "Desc": "Use the toggles to indicate which lines printed acceptably.",
        "RedKeyword": "Lost",
        "GreenKeyword": "Printed",
        "clampMin": "nozzleDiameter",
        "cameraData": "",
        "sortOrder": 0,
        "instanceCount": 7,
        "coordSign": 1,
        "coordLTaspect":"bossLenDiaRatio",
        "coordWTaspect":1,
        "coordAngleIncl":0
    }
</json>
*/

minVLine = nozzleDiameter; //mm
maxVLine = instanceCount * nozzleDiameter;
skipVLine = -1;      // skip the first <> items when building (for visualization purposes)




/*
<json>
    {
        "varBase": "HBar",
        "Name": "Horizontal Pillars",
        "Desc": "Use the toggles to indicate which columns printed acceptably.",
        "RedKeyword": "Lost",
        "GreenKeyword": "Printed",
        "clampMin": "layerHeight",
        "cameraData": "",
        "sortOrder": 0,
        "instanceCount": 7,
        "coordSign": 1,
        "coordLTaspect":"barLenDiaRatio",
        "coordWTaspect":1,
        "coordAngleIncl":90
    }
</json>
*/

minHBar = layerHeight; //mm
maxHBar = instanceCount * layerHeight;
skipHBar = -1;      // skip the first <> items when building (for visualization purposes)

/*
<json>
    {
        "varBase": "HFin",
        "Name": "Horizontal Fins",
        "Desc": "Use the toggles to indicate which fins printed acceptably.",
        "RedKeyword": "Lost",
        "GreenKeyword": "Printed",
        "clampMin": "layerHeight",
        "cameraData": "",
        "sortOrder": 0,
        "instanceCount": 7,
        "coordSign": 1,
        "coordLTaspect":"finLenDiaRatio",
        "coordWTaspect":"finWidthThkRatio",
        "coordAngleIncl":90
    }
</json>
*/

minHFin = layerHeight; //mm
maxHFin = instanceCount * layerHeight;
skipHFin = -1;      // skip the first <> items when building (for visualization purposes)

/*
<json>
    {
        "varBase": "HBoss",
        "Name": "Horizontal Bosses",
        "Desc": "Use the toggles to indicate which bosses printed acceptably.",
        "RedKeyword": "Lost",
        "GreenKeyword": "Printed",
        "clampMin": "layerHeight",
        "cameraData": "",
        "sortOrder": 0,
        "instanceCount": 7,
        "coordSign": 1,
        "coordLTaspect":"bossLenDiaRatio",
        "coordWTaspect":1,
        "coordAngleIncl":90
    }
</json>
*/

minHBoss = layerHeight; //mm
maxHBoss = instanceCount * layerHeight;
skipHBoss = -1;      // skip the first <> items when building (for visualization purposes)

/*
<json>
    {
        "varBase": "HLine",
        "Name": "Horizontal Lines",
        "Desc": "Use the toggles to indicate which lines printed acceptably.",
        "RedKeyword": "Lost",
        "GreenKeyword": "Printed",
        "clampMin": "layerHeight",
        "cameraData": "",
        "sortOrder": 0,
        "instanceCount": 7,
        "coordSign": 1,
        "coordLTaspect":"bossLenDiaRatio",
        "coordWTaspect":1,
        "coordAngleIncl":90
    }
</json>
*/

minHLine = layerHeight; //mm
maxHLine = instanceCount * layerHeight;
skipHLine = -1;      // skip the first <> items when building (for visualization purposes)




/*
<json>
    {
        "varBase": "VHole",
        "Name": "Vertical Holes",
        "Desc": "Use the toggles to indicate which holes printed acceptably.",
        "RedKeyword": "Lost",
        "GreenKeyword": "Printed",
        "cameraData": "",
        "sortOrder": 0,
        "instanceCount": 7,
        "coordSign": -1,
        "coordLTaspect":"barLenDiaRatio",
        "coordWTaspect":1,
        "coordAngleIncl":0
    }
</json>
*/

minVHole = nozzleDiameter; //mm
maxVHole = instanceCount * nozzleDiameter;
skipVHole = -1;      // skip the first <> items when building (for visualization purposes)

/*
<json>
    {
        "varBase": "VSlot",
        "Name": "Vertical Slots",
        "Desc": "Use the toggles to indicate which slots printed acceptably.",
        "RedKeyword": "Lost",
        "GreenKeyword": "Printed",
        "cameraData": "",
        "sortOrder": 0,
        "instanceCount": 7,
        "coordSign": -1,
        "coordLTaspect":"finLenDiaRatio",
        "coordWTaspect":"finWidthThkRatio",
        "coordAngleIncl":0
    }
</json>
*/

minVSlot = nozzleDiameter; //mm
maxVSlot = instanceCount * nozzleDiameter;
skipVSlot = -1;      // skip the first <> items when building (for visualization purposes)

/*
<json>
    {
        "varBase": "VPunch",
        "Name": "Vertical Thin Holes",
        "Desc": "Use the toggles to indicate which thin holes printed acceptably.",
        "RedKeyword": "Lost",
        "GreenKeyword": "Printed",
        "cameraData": "",
        "sortOrder": 0,
        "instanceCount": 7,
        "coordSign": -1,
        "coordLTaspect":"bossLenDiaRatio",
        "coordWTaspect":1,
        "coordAngleIncl":0
    }
</json>
*/

minVPunch = nozzleDiameter; //mm
maxVPunch = instanceCount * nozzleDiameter;
skipVPunch = -1;      // skip the first <> items when building (for visualization purposes)

/*
<json>
    {
        "varBase": "VSlit",
        "Name": "Vertical Thin Slits",
        "Desc": "Use the toggles to indicate which thin slits printed acceptably.",
        "RedKeyword": "Lost",
        "GreenKeyword": "Printed",
        "cameraData": "",
        "sortOrder": 0,
        "instanceCount": 7,
        "coordSign": -1,
        "coordLTaspect":"bossLenDiaRatio",
        "coordWTaspect":1,
        "coordAngleIncl":0
    }
</json>
*/

minVSlit = nozzleDiameter; //mm
maxVSlit = instanceCount * nozzleDiameter;
skipVSlit = -1;      // skip the first <> items when building (for visualization purposes)




/*
<json>
    {
        "varBase": "HHole",
        "Name": "Horizontal Holes",
        "Desc": "Use the toggles to indicate which holes printed acceptably.",
        "RedKeyword": "Lost",
        "GreenKeyword": "Printed",
        "cameraData": "",
        "sortOrder": 0,
        "instanceCount": 7,
        "coordSign": -1,
        "coordLTaspect":"barLenDiaRatio",
        "coordWTaspect":1,
        "coordAngleIncl":90
    }
</json>
*/

minHHole = layerHeight; //mm
maxHHole = instanceCount * layerHeight;
skipHHole = -1;      // skip the first <> items when building (for visualization purposes)

/*
<json>
    {
        "varBase": "HSlot",
        "Name": "Horizontal Slots",
        "Desc": "Use the toggles to indicate which slots printed acceptably.",
        "RedKeyword": "Lost",
        "GreenKeyword": "Printed",
        "cameraData": "",
        "sortOrder": 0,
        "instanceCount": 7,
        "coordSign": -1,
        "coordLTaspect":"finLenDiaRatio",
        "coordWTaspect":"finWidthThkRatio",
        "coordAngleIncl":90
    }
</json>
*/

minHSlot = layerHeight; //mm
maxHSlot = instanceCount * layerHeight;
skipHSlot = -1;      // skip the first <> items when building (for visualization purposes)

/*
<json>
    {
        "varBase": "HPunch",
        "Name": "Horizontal Thin Holes",
        "Desc": "Use the toggles to indicate which thin holes printed acceptably.",
        "RedKeyword": "Lost",
        "GreenKeyword": "Printed",
        "cameraData": "",
        "sortOrder": 0,
        "instanceCount": 7,
        "coordSign": -1,
        "coordLTaspect":"bossLenDiaRatio",
        "coordWTaspect":1,
        "coordAngleIncl":90
    }
</json>
*/

minHPunch = layerHeight; //mm
maxHPunch = instanceCount * layerHeight;
skipHPunch = -1;      // skip the first <> items when building (for visualization purposes)

/*
<json>
    {
        "varBase": "HSlit",
        "Name": "Horizontal Thin Slits",
        "Desc": "Use the toggles to indicate which thin slits printed acceptably.",
        "RedKeyword": "Lost",
        "GreenKeyword": "Printed",
        "cameraData": "",
        "sortOrder": 0,
        "instanceCount": 7,
        "coordSign": -1,
        "coordLTaspect":"bossLenDiaRatio",
        "coordWTaspect":1,
        "coordAngleIncl":90
    }
</json>
*/

minHSlit = layerHeight; //mm
maxHSlit = instanceCount * layerHeight;
skipHSlit = -1;      // skip the first <> items when building (for visualization purposes)

//END VARIABLE SETUP ===================================================================================================

// Model Variables
// Nomenclature: Each set of features has two dimensions, the FEATURE WIDTH (width of largest fin, for example)
// and the SERIES SIZE (size of all 7 fins with appropriate gaps inserted). For the most part, each block of 4
// feature sets is arranged side by side, making a block of size TOTAL_WIDTH (sum feature width) and TOTAL_HEIGHT 
// (sum series size)
vpos_total_height = max(fseriesSize(minVBar, maxVBar, instanceCount, xyPosGap),
                              fseriesSize(minVFin, maxVFin, instanceCount, xyPosGap),
                              fseriesSize(minVBoss, maxVBoss, instanceCount, xyPosGap),
                              fseriesSize(minVLine, maxVLine, instanceCount, xyPosGap));
vpos_widths = [maxVBar, maxVFin * finWidthThkRatio, maxVBoss, maxVLine * finWidthThkRatio];
vpos_total_width = xyPosGap * (1 + len(vpos_widths)) + sum(vpos_widths);

vneg_total_height = max(fseriesSize(minVSlot, maxVSlot, instanceCount, xyNegGap),
                              fseriesSize(minVHole, maxVHole, instanceCount, xyNegGap),
                              fseriesSize(minVPunch, maxVPunch, instanceCount, xyNegGap),
                              fseriesSize(minVSlit, maxVSlit, instanceCount, xyNegGap));
vneg_widths = [maxVSlot * finWidthThkRatio, maxVHole, maxVPunch, maxVSlit * finWidthThkRatio];
vneg_total_width = xyNegGap * (1 + len(vneg_widths)) + sum(vneg_widths);


hpos_x_sizes = [fseriesSize(minHFin, maxHFin, instanceCount, zPosGap),
                fseriesSize(minHBoss, maxHBoss, instanceCount, zPosGap),
                fseriesSize(minHLine, maxHLine, instanceCount, zPosGap),
                maxHBar];
hpos_total_height = zPosGap + max(hpos_x_sizes[0], max(hpos_x_sizes[1], hpos_x_sizes[2]) + hpos_x_sizes[3]);
hpos_widths = [maxHFin * finWidthThkRatio + zPosGap, maxHBoss, maxHLine * finWidthThkRatio,
                fseriesSize(minHBar, maxHBar, instanceCount, zPosGap)];
hpos_total_width = zPosGap * 1 + hpos_widths[0] +
                max(hpos_widths[1] + hpos_widths[2] + zPosGap, hpos_widths[3]);


hneg_total_height = zNegGap + max(fseriesSize(minHSlot, maxHSlot, instanceCount, zNegGap),
                              fseriesSize(minHHole, maxHHole, instanceCount, zNegGap),
                              fseriesSize(minHPunch, maxHPunch, instanceCount, zNegGap),
                              fseriesSize(minHSlit, maxHSlit, instanceCount, zNegGap));
hneg_widths = [maxHSlot * finWidthThkRatio, maxHHole, maxHPunch, maxHSlit * finWidthThkRatio];
hneg_total_width = zNegGap * (1 + len(hneg_widths)) + sum(hneg_widths);


color(normalColor)
union()
{
    translate([vpos_total_width * 0.5 - xyPosGap * 0.1, hpos_total_width + 0.5 * vpos_total_height - xyPosGap * 0.1, 0])
    rotate([0, 0, 90])
    VPosBlock();
    
    translate([-vneg_total_height * 0.5, vneg_total_width * 0.5, 0])
    VNegBlock();

    translate([-xyNegGap, hpos_total_width * 0.5, hpos_total_height * 0.5])
    HPosBlock();

    translate([hpos_total_height * 0.5 + hneg_total_height * 0.5, 0, 0])
    HNegBlock();
}

// Draws the vertical positive features in a block.
module VPosBlock()
{
    vpos_start_z = zNegGap * 2;

    translate([0, 0, vpos_start_z])
    union()
    {
        // Create a base for the features to sit on
        translate([0, 0, -vpos_start_z * 0.5])
            cube(size=[vpos_total_height, vpos_total_width, vpos_start_z], center=true);

        // VBar
        echo("SERIES=VBar");
        echo("ANGLE=0");
        echo("SIGN=1");
        locateY(0, vpos_total_width, xyPosGap, vpos_widths)
        pillar_set(minVBar, maxVBar, instanceCount, barLenDiaRatio, gap_size=xyPosGap, skip=skipVBar);

        // VFin
        echo("SERIES=VFin");
        echo("ANGLE=0");
        echo("SIGN=1");
        locateY(1, vpos_total_width, xyPosGap, vpos_widths)
        fin_set(minVFin, maxVFin, instanceCount, finLenThkRatio, finWidthThkRatio, gap_size=xyPosGap, skip=skipVFin);

        // VBoss
        echo("SERIES=VBoss");
        echo("ANGLE=0");
        echo("SIGN=1");
        locateY(2, vpos_total_width, xyPosGap, vpos_widths)
        pillar_set(minVBoss, maxVBoss, instanceCount, bossLenDiaRatio, gap_size=xyPosGap, skip=skipVBoss, min_len=layerHeight);

        // VLine
        echo("SERIES=VLine");
        echo("ANGLE=0");
        echo("SIGN=1");
        locateY(3, vpos_total_width, xyPosGap, vpos_widths)
        fin_set(minVLine, maxVLine, instanceCount, bossLenDiaRatio, finWidthThkRatio, gap_size=xyPosGap, skip=skipVLine,
                min_len=layerHeight);

    }
}


// Draws the vertical negative features in a block.
module VNegBlock()
{
    difference()
    {
        union()
        {
            // VSlot
            locateY(0, vneg_total_width, xyNegGap, vneg_widths)
            fin_set_neg(minVSlot, maxVSlot, instanceCount, finLenThkRatio, finWidthThkRatio, gap_size=xyNegGap,
                        skip=skipVSlot, justify_y=-1, bottom_chamfer=vchamfer_size, do_inside=false, do_echo=false);

            // VHole
            locateY(1, vneg_total_width, xyNegGap, vneg_widths)
            pillar_set_neg(minVHole, maxVHole, instanceCount, barLenDiaRatio, gap_size=xyNegGap, skip=skipVHole,
                        justify_y=1, bottom_chamfer=vchamfer_size, do_inside=false, do_echo=false);

            // VPunch
            locateY(2, vneg_total_width, xyNegGap, vneg_widths)
            pillar_set_neg(minVPunch, maxVPunch, instanceCount, bossLenDiaRatio, gap_size=xyNegGap, skip=skipVPunch,
                        justify_y=-1, bottom_chamfer=vchamfer_size, do_inside=false, do_echo=false, min_len=layerHeight);

            // VSlit
            locateY(3, vneg_total_width, xyNegGap, vneg_widths)
            fin_set_neg(minVSlit, maxVSlit, instanceCount, bossLenDiaRatio, finWidthThkRatio, gap_size=xyNegGap,
                        skip=skipVSlit, justify_y=1, bottom_chamfer=vchamfer_size, do_inside=false, do_echo=false,
                        min_len=layerHeight);

        }

        // VSlot
        echo("SERIES=VSlot");
        echo("ANGLE=0");
        echo("SIGN=-1");
        locateY(0, vneg_total_width, xyNegGap, vneg_widths)
        fin_set_neg(minVSlot, maxVSlot, instanceCount, finLenThkRatio, finWidthThkRatio, gap_size=xyNegGap,
                    skip=skipVSlot, justify_y=-1, bottom_chamfer=vchamfer_size, do_outside=false);

        // VHole
        echo("SERIES=VHole");
        echo("ANGLE=0");
        echo("SIGN=-1");
        locateY(1, vneg_total_width, xyNegGap, vneg_widths)
        pillar_set_neg(minVHole, maxVHole, instanceCount, barLenDiaRatio, gap_size=xyNegGap, skip=skipVHole,
                    justify_y=1, bottom_chamfer=vchamfer_size, do_outside=false);

        // VPunch
        echo("SERIES=VPunch");
        echo("ANGLE=0");
        echo("SIGN=-1");
        locateY(2, vneg_total_width, xyNegGap, vneg_widths)
        pillar_set_neg(minVPunch, maxVPunch, instanceCount, bossLenDiaRatio, gap_size=xyNegGap, skip=skipVPunch,
                    justify_y=-1, bottom_chamfer=vchamfer_size, do_outside=false, min_len=layerHeight);

        // VSlit
        echo("SERIES=VSlit");
        echo("ANGLE=0");
        echo("SIGN=-1");
        locateY(3, vneg_total_width, xyNegGap, vneg_widths)
        fin_set_neg(minVSlit, maxVSlit, instanceCount, bossLenDiaRatio, finWidthThkRatio, gap_size=xyNegGap,
                    skip=skipVSlit, justify_y=1, bottom_chamfer=vchamfer_size, do_outside=false, min_len=layerHeight);
    }
}

// Draws the horizontal positive features in a block. All references to x/y/z are in the un-rotated
// coordinate frame... i.e. I built the model un-rotated, then flipped it on edge.
module HPosBlock()
{
    hpos_start_z = xyNegGap;

    rotate([0, 90, 0])
    rotate([0, 0, 180])
    translate([0, 0, hpos_start_z])
    union()
    {
        // Create a base for the features to sit on
        translate([0, 0, -hpos_start_z * 0.5])
            cube(size=[hpos_total_height, hpos_total_width, hpos_start_z], center=true);

        // HBar
        //echo("SERIES=HBar");
        //echo("ANGLE=90");
        //echo("SIGN=1");
        //locateY(0, hpos_total_width, zPosGap, hpos_widths)
        //pillar_set(minHBar, maxHBar, instanceCount, barLenDiaRatio, gap_size=zPosGap, skip=skipHBar);

        // HFin
        echo("SERIES=HFin");
        echo("ANGLE=90");
        echo("SIGN=1");
        locateY(0, hpos_total_width, zPosGap, hpos_widths)
        {
            fin_set(minHFin, maxHFin, instanceCount, finLenThkRatio, finWidthThkRatio, gap_size=zPosGap, skip=skipHFin,
                    justify_y=1, pad_len=xyNegGap * 0.25);

            if(overhangSupports)
            {
                support_thk = xyNegGap;
                translate([-hpos_total_height * 0.5, -0.5*hpos_widths[0], maxHFin * finLenThkRatio + xyNegGap])
                {
                    //cube(size=[3,3,3], center=true);

                    for(i = [0:instanceCount-1])
                    {
                        thk = fdia(i, minHFin, maxHFin, instanceCount);
                        support_x_size = hpos_total_height * 0.5 + flocateX(i, minHFin, maxHFin, instanceCount, gapSize=zPosGap) + thk;

                        support_height = maxHFin * finLenThkRatio + xyNegGap - thk * finLenThkRatio;
                        translate([support_x_size * 0.5, 0, -support_height * 0.5])
                        {
                            cube(size=[support_x_size, support_thk, support_height], center=true);
                            translate([0, thk * finWidthThkRatio - 0*xyNegGap, 0])
                            cube(size=[support_x_size, support_thk, support_height], center=true);
                        }
                    }
                }
                translate([-0.5*hpos_total_height + zPosGap * 0.5, -0.5*hpos_widths[0] + minHFin * finWidthThkRatio * 0.5, (minHFin * finLenThkRatio + support_thk - xyNegGap * 0.5) * 0.5])
                cube(size=[zPosGap,support_thk + minHFin * finWidthThkRatio,minHFin * finLenThkRatio + support_thk + xyNegGap * 0.5], center=true);
            }
        }

        // HBoss
        echo("SERIES=HBoss");
        echo("ANGLE=90");
        echo("SIGN=1");
        translate([0.5 * (hpos_total_height - hpos_x_sizes[1]), 0, -xyNegGap * 0.25])
        locateY(1, hpos_total_width, zPosGap, hpos_widths)
        pillar_set(minHBoss, maxHBoss, instanceCount, bossLenDiaRatio, gap_size=zPosGap, skip=skipHBoss,
                pad_len=xyNegGap * 0.5);

        // HLine
        echo("SERIES=HLine");
        echo("ANGLE=90");
        echo("SIGN=1");
        translate([0.5 * (hpos_total_height - hpos_x_sizes[2]), 0, -xyNegGap * 0.25])
        locateY(2, hpos_total_width, zPosGap, hpos_widths)
        fin_set(minHLine, maxHLine, instanceCount, bossLenDiaRatio, finWidthThkRatio, gap_size=zPosGap, skip=skipHLine,
                pad_len=xyNegGap * 0.5);

        // HBar
        echo("SERIES=HBar");
        echo("ANGLE=90");
        echo("SIGN=1");
        translate([-0.5 * (hpos_total_height - hpos_x_sizes[3]) + zPosGap, 0, 0])
        translate([0, 0.5 * (hpos_total_width - hpos_widths[3])])
        rotate([0, 0, 90])
        {
            pillar_set(minHBar, maxHBar, instanceCount, barLenDiaRatio, gap_size=zPosGap, skip=skipHBar, pad_len=zPosGap * 0.1);

            support_thk = xyNegGap;
            if(overhangSupports)
            {
                for(i = [0:instanceCount-1])
                {
                    x = flocateX(i, minHBar, maxHBar, instanceCount, gapSize=zPosGap);
                    translate([x - maxHBar * 0.5, zPosGap * 0.5, fdia(i, minHBar, maxHBar, instanceCount) * barLenDiaRatio + support_thk * 0.5])
                    cube(size=[zPosGap + minHBar + maxHBar,maxHBar + zPosGap,support_thk], center=true);
                }

                translate([-hpos_widths[3] * 0.5 - xyNegGap * 0.5, (maxHBar + zPosGap) * 0.5, (minHBar * barLenDiaRatio + support_thk - xyNegGap * 0.5) * 0.5])
                cube(size=[xyNegGap,zPosGap,minHBar * barLenDiaRatio + support_thk + xyNegGap * 0.5], center=true);
            }
        }
    }
}


// Draws the horizontal negative features in a block.
module HNegBlock()
{
    rotate([0, 90, 0])
    union()
    {

        // HSlot
        echo("SERIES=HSlot");
        echo("ANGLE=0");
        echo("SIGN=-1");
        locateY(0, hneg_total_width, zNegGap, hneg_widths)
        fin_set_neg(minHSlot, maxHSlot, instanceCount, finLenThkRatio, finWidthThkRatio, gap_size=zNegGap,
                    skip=skipHSlot, justify_y=-1, outer_smooth=false);

        // HHole
        echo("SERIES=HHole");
        echo("ANGLE=0");
        echo("SIGN=-1");
        locateY(1, hneg_total_width, zNegGap, hneg_widths)
        pillar_set_neg(minHHole, maxHHole, instanceCount, barLenDiaRatio, gap_size=zNegGap, skip=skipHHole,
                    justify_y=1, outer_smooth=false);

        // HPunch
        echo("SERIES=HPunch");
        echo("ANGLE=0");
        echo("SIGN=-1");
        locateY(2, hneg_total_width, zNegGap, hneg_widths)
        pillar_set_neg(minHPunch, maxHPunch, instanceCount, bossLenDiaRatio, gap_size=zNegGap, skip=skipHPunch,
                    justify_y=-1, outer_smooth=false, min_len=nozzleDiameter);

        // HSlit
        echo("SERIES=HSlit");
        echo("ANGLE=0");
        echo("SIGN=-1");
        locateY(3, hneg_total_width, zNegGap, hneg_widths)
        fin_set_neg(minHSlit, maxHSlit, instanceCount, bossLenDiaRatio, finWidthThkRatio, gap_size=zNegGap,
                    skip=skipHSlit, justify_y=1, outer_smooth=false, min_len=nozzleDiameter);
    }
}
