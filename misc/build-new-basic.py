# A quick script for building the new basic model with parameters from the excel spreadsheet.
# This is a hack and will be supplanted by the new website.

import glob
import os
import subprocess

file = "../eval_suites/basic/New Basic.scad"
args = ["-DserialNo=33", "-DminVHole=2", "-DminVSlot=0.5", "-DminHHole=1", "-DminHSlot=0.1", "-DminHPunch=0.1", "-DminHSlit=0.1", "-DmaxVBar=0.7", "-DmaxVFin=0.7", "-DmaxVBoss=0.7", "-DmaxVLine=0.7", "-DmaxHBar=0.7", "-DmaxHFin=0.7", "-DmaxHBoss=0.7", "-DmaxHLine=0.7", "-DmaxVHole=4", "-DmaxVSlot=1.5", "-DmaxVPunch=0.7", "-DmaxVSlit=0.7", "-DmaxHHole=3", "-DmaxHSlot=0.7", "-DmaxHPunch=0.7", "-DmaxHSlit=0.7"]


# First generate the echo output
popen_params = ["../openscad/openscad.exe", "-o", "../logs/" + file.split("/")[-1] + ".echo"]
popen_params.extend(args)
popen_params.append(file)
print popen_params

proc = subprocess.Popen(popen_params)
proc.wait()

popen_params = ["../openscad/openscad.exe", "-o", "../modelcache/" + file.split("/")[-1][:-5] + ".stl"]
popen_params.extend(args)
popen_params.append(file)

print popen_params
proc = subprocess.Popen(popen_params)
proc.wait()
print("Done with " + file)

