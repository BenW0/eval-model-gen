# A quick script for building all the models in the eval_models folders, as well as saving their echo logs.

import glob
import os
import subprocess

files = glob.glob("../eval_suites/*/*.scad")
print(files)

for file in files:
    if "misc" in file:
        continue

    # First generate the echo output
    popen_params = ["../openscad/openscad.exe", "-o", "../logs/" + file.split("\\")[-1] + ".echo",
                    file]
    print popen_params

    proc = subprocess.Popen(popen_params)
    proc.wait()

    popen_params = ["../openscad/openscad.exe", "-o", "../modelcache/" + file.split("\\")[-1] + ".stl",
                    file]
    #print popen_params
    proc = subprocess.Popen(popen_params)
    proc.wait()
    print("Done with " + file)

