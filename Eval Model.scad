/* Cylindrical test feature object for determining
   several smallest feature capabilities
   Ben Weiss, 2015-2016
  
   TODO:
     - Improve sizing of outrigger to better accommodate aspect ratio requirements of negative
       features by allowing the left hand edge to not be aligned with the Y axis.
     - Add a test for depth of emboss/engrave needed to be visible
 */ 
 
// Special variable set explicitly by the eval server. Don't change this name without also changing it in
// the Python server AND in the javascript!
layerHeight = 0.2;      // mm
nozzleDiameter = 0.4;   // mm, only supplied in a default mode

// Variables set by Eval Model server. For each set of min/max variables, there is a very specific comment
// structure that needs to be present in this file to configure the server (backend and frontend). The
// comment begins with the special string "json" and ends with "/json" enclosed in gthan/lthan brackets, 
// and the text between them needs to be structured JSON text as shown below.
//
// After adding or removing blocks, run modelparams.py to update the static images used for visualization.
// The JSON fields are these:
//  - Name: Plain text name of the parameter (for web page use)
//  - Desc: Plain text description of what the user should do for this test
//  - LowKeyword: Keyword to show at the low end of the slider
//  - HighKeyword: Keyword to show at the high end of the slider
//  - varBase: Variable names. OpenSCAD should include these variables: min<varBase>, max<varBase>, skip<varBase>
//  - min/maxDefault: Values to use for a default test part. These may be 
//  - min/maxDefaultLH: Values to use if all we are given is a characteristic diameter and layer height.
//    These may be functions of layerHeight and nozzleDiameter.

/*
<json>
    {
        "Name": "Vertical Positive Pillars",
        "Desc": "Use the slider to indicate how many columns printed acceptably.",
        "LowKeyword": "Lost",
        "HighKeyword": "Printed",
        "varBase": "PosPillarDiaV",
        "minDefault": 0.1,
        "maxDefault": 2,
        "minDefaultND": "0.5 * nozzleDiameter",
        "maxDefaultND": "5 * nozzleDiameter",
        "cameraData": "-2.28,2.59,6.06,59.9,0,13.8,113.4"
    }
</json>
*/
        
minPosPillarDiaV = 1; //mm
maxPosPillarDiaV = 1.1;
skipPosPillarDiaV = -1;      // skip the first <> items when building (for visualization purposes)

/*
<json>
    {
        "Name": "Vertical Negative Pillars",
        "Desc": "Use the slider to indicate how many holes let light through.",
        "LowKeyword": "Lost",
        "HighKeyword": "Printed",
        "varBase": "NegPillarDiaV",
        "minDefault": 0.1,
        "maxDefault": 2,
        "minDefaultND": "0.5 * nozzleDiameter",
        "maxDefaultND": "5 * nozzleDiameter",
        "cameraData": "-3.95,5.44,4.58,28.4,0,149.6,91.85"
    }
</json>
*/
minNegPillarDiaV = 1;
maxNegPillarDiaV = 1.1;
skipNegPillarDiaV = -1;

minPosPillarDiaH = 1; //mm
maxPosPillarDiaH = 1.1;

minNegPillarDiaH = 1;
maxNegPillarDiaH = 1.1;

minPosButtonDiaH = 1; //mm
maxPosButtonDiaH = 2;

minNegButtonDiaH = 1;
maxNegButtonDiaH = 2;

minPosButtonDiaV = 1; //mm
maxPosButtonDiaV = 2;
minNegButtonDiaV = 1;
maxNegButtonDiaV = 2;

minPosFinThkH = 1;    //mm
maxPosFinThkH = 1.1;
minNegFinThkH = 1;
maxNegFinThkH = 1.1;

minPosFinThkV = 0.1;
maxPosFinThkV = 2;
minNegFinThkV = 0.1;
maxNegFinThkV = 2;

minYZRadius = 0.1;
maxYZRadius = 1;

minXYRadius = 0.1;
maxXYRadius = 1;

featureCount = 10;
skipH = -1;      // set to non-zero to skip rendering the first <skipH> bars
skipV = -1;      // set to non-zero to skip rendering the first <skipV> columns 

// Ratios used for determining the relative sizes of different features
positiveHSizeRatio = 7;        // ratio of height to diameter/thickness for horizontal pillars/fins
pillarVSizeRatio = 7;         // ratio of height to diameter/thickness for vertical pillars
negativeHSizeRatio = 7;         // ratio of height to diameter/thickness for negative horizontal pillars/fins
finDepthLenRatioV = 1.2;          // ratio of width (depth) to height for center vertical fin
minHFinWidthThkRatio = 2;       // minimum width/thickness ratio for horizontal fins
finLenThkRatioV = 6;            // ratio of vertical fin thickness to length

// quality settings. Since we don't control the scale, force the use of
// a reasonable number of fragments regardless of size.
$fn = 16;

// Derived Quantities =======================

meanNegFinThkV = (minNegFinThkV + maxNegFinThkV) / 2;
meanPosFinThkV = (minPosFinThkV + maxPosFinThkV) / 2;
meanNegPillarDiaV = (minNegPillarDiaV + maxNegPillarDiaV) / 2;
meanPosButtonDiaV = (minPosButtonDiaV + maxPosButtonDiaV) / 2;
meanNegButtonDiaV = (minNegButtonDiaV + maxNegButtonDiaV) / 2;

// vfinMinSpacing records the minimum X-direction space needed for each positive/negative fin pair,
// assuming they are arranged in opposite order (biggest positive next to smallest negative).
vfinMinSpacing = max(maxNegFinThkV + minPosFinThkV, minNegFinThkV + maxPosFinThkV) / 2;

// Minimum and maximum width variables for each of the major test components. Used in calculating the x-direction width of the total part.
minWidthVars = [minPosPillarDiaV, minPosPillarDiaH, minNegPillarDiaH, minPosFinThkH * minHFinWidthThkRatio, minNegFinThkH * minHFinWidthThkRatio, vfinMinSpacing];
maxWidthVars = [maxPosPillarDiaV, maxPosPillarDiaH, maxNegPillarDiaH, minNegFinThkH * minHFinWidthThkRatio, maxNegFinThkH * minHFinWidthThkRatio, vfinMinSpacing];

maxPosPillarDia = max(maxPosPillarDiaH, maxPosPillarDiaV);
minPosPillarDia = min(minPosPillarDiaH, minPosPillarDiaV);
meanPosPillarDia = (maxPosPillarDia + minPosPillarDia) / 2;
maxPillarDia = max(maxWidthVars);
minPillarDia = min(minWidthVars);
meanPillarDia = (maxPillarDia + minPillarDia) / 2;

fudge = minPillarDia * 0.02;        // a small buffer to make solids cleanly intersect.

yzFilletGap = maxPosFinThkV;
xyFilletGap = maxPosFinThkH;

xyFilletColumnWidth = maxPosPillarDiaV * 2;
xyFilletColumnHeight = pillarVSizeRatio * xyFilletColumnWidth / 4;

// Outrigger dimensions
outriggerMinDepth = max(maxPosPillarDiaV * 1.5 + xyFilletColumnWidth, minNegFinThkH * negativeHSizeRatio, minNegPillarDiaH * negativeHSizeRatio);
outriggerGapConstant = 0.5;
outriggerHeight = (max(maxPosPillarDiaH, maxPosButtonDiaH) + maxNegPillarDiaH + max(maxPosFinThkH, maxNegButtonDiaH) + maxNegFinThkH) * (1 + outriggerGapConstant);
outriggerGapV = outriggerHeight / (1 + outriggerGapConstant) * outriggerGapConstant / 4;

// coreHeight will be the average of the size the negative vertical columns and fins want, limited so it isn't too low to receive the horizontal pillars.
coreHeight = max(outriggerHeight - outriggerGapV - maxNegPillarDiaV, 
    (finLenThkRatioV * meanNegFinThkV + pillarVSizeRatio * meanNegPillarDiaV) / 2);
// coreWidth ensures the gapH between each pillar is at least 2/3 of either max pillar.
coreWidth = featureCount * (max([ for (i = [0:1:len(minWidthVars)-1]) (minWidthVars[i] + maxWidthVars[i]) / 2 ]) + maxPillarDia * 0.667);
    

negFinLengthV = coreHeight;
posFinLengthV = finLenThkRatioV * meanPosFinThkV;
finDepthV = max(finDepthLenRatioV * posFinLengthV, finDepthLenRatioV * negFinLengthV);

// Now we can define the coreDepth
coreYGap = maxPosFinThkV;
coreDepth = finDepthV + maxNegPillarDiaV + coreYGap * 1.5;

pillarSpacing = coreWidth / featureCount;
posPillarMinLengthH = maxPosPillarDiaV * 2;
posPillarMinLengthV = maxPosPillarDiaH * 2;

hButtonThk = meanPosPillarDia / 2;
vButtonThk = meanPosPillarDia / 2;      // TODO: limit this with layer height?

posFinWidthH = coreWidth / featureCount - meanPosFinThkV;
negFinWidthH = coreWidth / featureCount - meanNegFinThkV;

// Connecting bar size
connectingBarWidth = 1.5 * max(maxPosFinThkV, maxPosButtonDiaV, maxNegButtonDiaV);
connectingBarLength = max(coreDepth - foutriggerEndY(), featureCount * (max(meanPosButtonDiaV, meanNegButtonDiaV) + 0.667 * max(maxPosButtonDiaV, maxNegButtonDiaV)));
connectingBarCenterY = coreDepth - connectingBarLength / 2;

// Color parameters
normalColor = [125/255, 156/255, 159/255, 1];
highlightColor = [255/255, 230/255, 160/255, 1];

//color(normalColor)
{
difference()
{
    union()
    {
        
        // Build the core and outrigger
        core();
        outrigger();
        
        // Vertical fins
        translate([0,coreYGap * 0.5,coreHeight])
            vfins(true, skipV);
        
        // horizontal pillars
        translate([0,0,outriggerHeight - 1.5 * outriggerGapV - maxNegPillarDiaH - maxPosPillarDiaH / 2])
        rotate([90,0,0])
            pillars(minPosPillarDiaH, maxPosPillarDiaH, positiveHSizeRatio, posPillarMinLengthH, skipH);
        
        // horizontal buttons
        translate([0, foutriggerEndY(), outriggerHeight - 1.5 * outriggerGapV - maxNegPillarDiaH - maxPosButtonDiaH / 2])
        rotate([90,0,0])
            pillars(minPosButtonDiaH, maxPosButtonDiaH, 0, hButtonThk, skipH);
        
        // positive horizontal fins
        translate([fgapX(posFinWidthH, posFinWidthH) * 0.5, 0, outriggerGapV + maxPosFinThkH / 2])
        hfins(minPosFinThkH, maxPosFinThkH, posFinWidthH);
        
        // vertical pillars
        translate([0, foutriggerEndY() + maxPosPillarDiaV, outriggerHeight])
            pillars(minPosPillarDiaV, maxPosPillarDiaV, pillarVSizeRatio, posPillarMinLengthV, skipPosPillarDiaV);
            
        // vertical buttons
        translate([-(coreWidth + connectingBarWidth) / 2, connectingBarCenterY, coreHeight])
        rotate([0, 0, 90])
            pillars(minPosButtonDiaV, maxPosButtonDiaV, 0, vButtonThk, skipH, overrideWidth=connectingBarLength);
        
        // xy fillets
        translate([0, foutriggerEndY() + (outriggerMinDepth + 2 * maxPosPillarDiaV) / 2, outriggerHeight])
            xyfillets(minXYRadius, maxXYRadius, coreWidth, skipV);
                
    };
    
    // Negative features get subtracted out!
    // horizontal pillars
    translate([0,0,outriggerHeight - outriggerGapV - maxNegPillarDiaH / 2])
    rotate([90,0,0])
        pillars(minNegPillarDiaH, maxNegPillarDiaH, 0, abs(foutriggerEndY()) + 3 * fudge, skipH, backwards=true);
    
    // horizontal buttons
    translate([0, foutriggerEndY() + hButtonThk, outriggerGapV + maxNegButtonDiaH / 2])
    rotate([90,0,0])
        pillars(minNegButtonDiaH, maxNegButtonDiaH, 0, hButtonThk + 2 * fudge, skipH);
    
    // horizontal fins
    translate([0, -3 * fudge, 1.5 * outriggerGapV + max(maxPosFinThkH, maxNegButtonDiaH) + maxNegFinThkH / 2])
        hfins(maxNegFinThkH, minNegFinThkH, negFinWidthH);
    
    // vertical fins
    translate([0, coreYGap * 0.5, 0])
    vfins(false, skipV);
    
    // negative vertical pillars
    translate([0, coreDepth - coreYGap * 0.5 - maxNegPillarDiaV / 2, -2 * fudge])
    pillars(minNegPillarDiaV, maxNegPillarDiaV, 0, coreHeight + 4 * fudge, skipNegPillarDiaV);
    
    // negative vertical buttons
    translate([-(coreWidth + connectingBarWidth) / 2, connectingBarCenterY, -2 * fudge])
    rotate([0, 0, 90])
        pillars(minNegButtonDiaV, maxNegButtonDiaV, 0, vButtonThk, skipH, overrideWidth=connectingBarLength);
        
    // negative fillets
    translate([-connectingBarWidth / 2, coreDepth, coreHeight])
    scale([-1, 1, 1])
    yzfillets(minYZRadius, maxYZRadius, yzFilletGap, coreWidth + connectingBarWidth, skipH);

}
}

module core()
{
    color(normalColor)
    {
        translate([0, coreDepth/2, coreHeight/2])
            cube(size=[coreWidth, coreDepth, coreHeight], center=true);

        // make the connecting bar
        cbHeight = coreHeight;
        cbDepth = connectingBarLength;
        translate([-coreWidth/2 - connectingBarWidth / 2, connectingBarCenterY, cbHeight / 2])
        cube(size=[connectingBarWidth, cbDepth, cbHeight],center=true);
    }
}

// Creates vertical pillars; used to make each set of pillars in turn.
// @minDia, @maxDia - minimum and maximum pillar diameters.
// Pillars will have length (height) which is the greater of
// @minLength and @aspect * diameter
// if @skipFirst >= 0, the first @skipFirst elements are not generated (this is used for figure generation)
// if @onOutrigger = true, the pillars are built using the locateOutrigger() modifier instead of locateX
// backwards causes the pillars to be arranged in reverse order, but only works if onOutrigger = false.
// overrideWidth lets you override the use of coreWidth as the total target width for the pattern.
module pillars(minDia, maxDia, aspect, minLength, skipFirst=-1, onOutrigger=false, backwards=false, overrideWidth=0)
{
    color(skipFirst >= 0 ? highlightColor : normalColor)
    // Build each vertical pillar
    for(i=[0:featureCount-1])
    {
        if(i >= skipFirst)
        {
            translate([0, 0, -fudge / 2])
            if(onOutrigger)
            {
                locateOutrigger(i)
                translate([0,0,outriggerHeight/2])
                cylinder(h=fcylHeight(fdia(i, minDia, maxDia), aspect, minLength), 
                    d=fdia(i, minDia, maxDia));
            }
            else
            {
                locateX(i, minDia, maxDia, backwards, overrideWidth)
                cylinder(h=fcylHeight(fdia(i, minDia, maxDia), aspect, minLength), 
                    d=fdia(i, minDia, maxDia));
            }
        }
    }
}

// Horizontal fins generator
// Builds fins in the horizontal direction (used for positive and negative)
// Arguments:
//   * minThk/maxThk - minimum and maximum thickness
//   * width - fin width (in X direction)
//   * skipFirst - skips the first X entries 
module hfins(minThk, maxThk, width, skipFirst=-1)
{
    gapX = fgapX(width, width);
    finFirstX = -coreWidth / 2 + gapX / 2 + width / 2;
    color(skipFirst >= 0 ? highlightColor : normalColor)
    // Build each horizontal fin
    for(i = [0:featureCount-1])
    {
        if(i >= skipFirst)
        {
            thk = fdia(i, minThk, maxThk);
            // length needs to match bottom pillars...
            length = abs(foutriggerEndY());
            locateX(i, width, width)
            translate([0, -length/2 + fudge, 0])
            cube(size=[width, length, thk], center=true);
        }
    }
}

// draws both positive and negative fins. @doPos toggles between creating the positive
// and negative features; all other constants are directly imported.
// fin sizes are set based on the aspect ratio of the middle fin, and do not vary
// with each fin's thickness.
module vfins(doPos=true, skipFirst=-1)
{
    // we have constant spacing instead of constant gap for vertical fins
    finSpacing = coreWidth / (featureCount + 0.5) * (doPos ? 1 : -1);
    finFirstX = (coreWidth - abs(finSpacing)) / 2 * (doPos ? -1 : 1);
    finHeight = doPos ? posFinLengthV : negFinLengthV;    // same as Length
    color(skipFirst >= 0 ? highlightColor : normalColor)
    // Build each vertical fin
    for(i = [0:featureCount-1])
    {
        if(i >= skipFirst)
        {
            thk = doPos ? fdia(i, minPosFinThkV, maxPosFinThkV) : fdia(i, minNegFinThkV, maxNegFinThkV);
            translate([finFirstX + i * finSpacing, finDepthV/2, finHeight/2])
            cube(size=[thk, finDepthV, finHeight + 3 * fudge], center=true);
        }
    }

}

// Builds a series of fillets along the positive X axis, centered at the origin.
// These should be Differenced from the bulk body
// Parameters
//    * minR/maxR - minimum and maximum radius
//    * gapSize - size of the gap between sections of radius
//    * totalLength - total length of the target corner
//    * skipFirst - omit the first few features for visualization
module yzfillets(minR, maxR, gapSize, totalLength, skipFirst=-1)
{
    filletWidth = totalLength / featureCount - gapSize;
    // Build each radius differencing body
    color(skipFirst >= 0 ? highlightColor : normalColor)
    for(i=[0:featureCount-1])
    {
        if(i >= skipFirst)
        {
            r = fdia(i, minR, maxR);
            translate([-totalLength * 0.5 + gapSize * (i + 0.5) + filletWidth * (i + 0.5), 0, 0])
            difference()
            {
                cube(size=[filletWidth, r * 2, r * 2], center=true);
                
                translate([0, -r, -r])
                rotate([0, 90, 0])
                    cylinder(h=2 * (filletWidth + fudge), r=r,center=true);
            }
        }
    }
}

// Creates x/y fillet pillars.
module xyfillets(minR, maxR, totalLength, skipFirst=-1)
{
    gapSize = totalLength / featureCount - xyFilletColumnWidth;
    color(skipFirst >= 0 ? highlightColor : normalColor)
    // Build each column with a small radius cutout on the top half
    for(i=[0:featureCount-1])
    {
        r = fdia(i, minR, maxR);
        translate([-totalLength * 0.5 + gapSize * (i + 0.5) + xyFilletColumnWidth * (i + 0.5), 0, xyFilletColumnHeight / 4])
        union()
        {
            cube(size=[xyFilletColumnWidth, xyFilletColumnWidth, xyFilletColumnHeight / 2], center=true);
            
            if(i >= skipFirst)
            {
                translate([0,0,xyFilletColumnHeight / 2 - fudge])
                union()
                {
                    cube(size=[xyFilletColumnWidth, xyFilletColumnWidth - 2 * r, xyFilletColumnHeight / 2 ], center=true);
                    cube(size=[xyFilletColumnWidth - 2 * r, xyFilletColumnWidth, xyFilletColumnHeight / 2 ], center=true);
                    for(side=[0:4])
                    {
                        rotate([0,0,90*side])
                        translate([xyFilletColumnWidth * 0.5 - r, xyFilletColumnWidth * 0.5 - r, 0])
                            cylinder(h=xyFilletColumnHeight / 2, r=r,center=true);
                    }
                }
            }
        }
    }
}

// Creates the Outrigger (bulk structure on the left)
module outrigger()
{
    color(normalColor)
    hull()
    {
        // Build each vertical pillar
        for(i=[0:featureCount-1])
        {
            locateOutrigger(i)
                cube(size=foutriggerSize2(i) + [fudge, 0, 0], center=true);
        }
        // add a single block to the far corner to make it roughly triangular
        locateOutrigger(featureCount-1)
        translate([-coreWidth + foutriggerSize2(featureCount - 1)[0], 0, 0])
            cube(size=foutriggerSize2(featureCount - 1) + [fudge, 0, 0], center=true);
    }
}

// ==============================================================
// Resource Functions
// ==============================================================

function fgapX(minDia, maxDia, overrideWidth=0) = ((overrideWidth == 0 ? coreWidth : overrideWidth) - 0.5 * (maxDia + minDia) * featureCount) / ( featureCount + 0);
function fdiaStep(minDia, maxDia) = (maxDia - minDia) / (featureCount - 1);
function fdia(idx, minDia, maxDia) = minDia + idx * fdiaStep(minDia, maxDia);
function fcylHeight(dia, aspect, minLength) = max(aspect*dia, minLength) + fudge;
function foutriggerSize(dia, diaStep, aspect, gapX) = [dia + gapX, outriggerMinDepth, outriggerHeight];
function foutriggerSize2(idx) = 
        let(minDia = minPosPillarDiaH, maxDia = maxPosPillarDiaH, aspect = positiveHSizeRatio)
        foutriggerSize(fdia(idx, minDia, maxDia), fdiaStep(minDia, maxDia), aspect, fgapX(minDia, maxDia));
function foutriggerEndY() = 
        let(minDia = minPosPillarDiaH, maxDia = maxPosPillarDiaH, aspect = positiveHSizeRatio)
        -(foutriggerSize(fdia(featureCount - 1, minDia, maxDia), fdiaStep(minDia, maxDia), aspect, fgapX(minDia, maxDia))[1] + fcylHeight(fdia(featureCount - 1, minDia, maxDia), aspect, posPillarMinLengthH));

function foutriggerY(x=0) = 
    let(minDia = minPosPillarDiaH,
        maxDia = maxPosPillarDiaH,
        aspect = positiveHSizeRatio,
        x0 = (x + coreWidth / 2),
        gap = fgapX(minDia, maxDia),
        step = fdiaStep(minDia, maxDia))
    let(idx = (-minDia - gap + sqrt((minDia + gap)*(minDia + gap) + 2 * x0 * step)) / step)
    let(dia = fdia(idx, minDia, maxDia))
    -fcylHeight(dia, aspect, posPillarMinLengthH) - foutriggerSize(dia, step, aspect, gap)[1] / 2;

// ==============================================================
// Resource Modules
// ==============================================================

// operator module that translates to the x coordinate of feature idx in
// the series that targets constant gap widths
module locateX(idx, minDia, maxDia, backwards=false, overrideWidth=0)
{
    gap = fgapX(minDia, maxDia, overrideWidth);
    fudge = (minDia);    // this is enough extra height to fully intersect base/outrigger.
    diaStep = fdiaStep(minDia, maxDia);
    pillarFirstX = -(overrideWidth == 0 ? coreWidth : overrideWidth) / 2 + gap / 2 + minDia / 2;
    dia = fdia(idx, minDia, maxDia);
    
    cx = (pillarFirstX + idx * 0.5 * (dia + minDia) + idx * gap) * (backwards ? -1 : 1);
    
    translate([cx, 0, 0])
    children();
}

// operator module to translate to the center of the outrigger for a particular
// index idx. We know we'll be using min/maxPosPillarDiaH in this case.
module locateOutrigger(idx)
{
    minDia = minPosPillarDiaH;
    maxDia = maxPosPillarDiaH;
    aspect = positiveHSizeRatio;
    
    gap = fgapX(minDia, maxDia);
    diaStep = fdiaStep(minDia, maxDia);
    dia = fdia(idx, minDia, maxDia);
    cylH = fcylHeight(dia, aspect, posPillarMinLengthH);
    osize = foutriggerSize(dia, diaStep, aspect, gap);
    
    translate([0, -osize[1], osize[2]]/2)
    translate([0, -cylH, 0])
    locateX(idx, minDia, maxDia)
    children();
}
