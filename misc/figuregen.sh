#!/bin/bash
#
# Quick script for generating images from model part for the website.

OPENSCAD_EXE=../openscad/openscad
MODEL_NAME=../Eval\ Model.scad
#IMAGEMAGICK_EXE=C:/Program\\ Files/ImageMagick-6.9.0-Q16/convert

# First remove columns
COL_CAMERA=-0.16,13.58,1.06,71.8,0,0,82.7       #translatex,y,z,rotx,y,z,dist Read from bottom of window in OpenSCAD
COUNTER=0
while [ $COUNTER -lt 11 ];
do
    OUT_FILE=../public/images/partN-columns$COUNTER.png
    ${OPENSCAD_EXE} -o ${OUT_FILE} -D skipV=$COUNTER --camera=${COL_CAMERA} --autocenter --imgsize=220,220 --projection=ortho "$MODEL_NAME"
    #${IMAGEMAGICK_EXE} ${OUT_FILE} -crop 220x220+75+33 ${OUT_FILE}
    let COUNTER+=1
done


# Now remove bars
BAR_CAMERA=-0.83,-5.56,-6.44,20,0,0,82.7       #translatex,y,z,rotx,y,z,dist
COUNTER=0
while [ $COUNTER -lt 11 ];
do
    OUT_FILE=../public/images/partN-bars$COUNTER.png
    ${OPENSCAD_EXE} -o ${OUT_FILE} -D skipH=$COUNTER --camera=${BAR_CAMERA} --autocenter --imgsize=220,220 --projection=ortho "$MODEL_NAME"
    #${IMAGEMAGICK_EXE} ${OUT_FILE} -crop 220x220+75+33 ${OUT_FILE}
    let COUNTER+=1
done