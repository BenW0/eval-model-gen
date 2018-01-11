# Evaluation Model Generator
### Iterative, Guided 3D Printer Qualificatio
Ben Weiss at the University of Washington, (c) 2016

This is an OLD and NOT FULLY FUNCTIONAL application for characterizing 3D printers. A simpler and more capable one is forthcoming. It is NOT the tool used in my dissertation.

This web application (server and client) work to evaluate a suite of minimum feature sizes produceable on a given printer. The main benefits of this approach are
* Low time/material cost - wasted printed features are minimized by iteratively printing several parts which only produce features likely to be near failure
* Flexibility - this part is designed to work across the spectrum of the addtive manufacturing landscape, on everything from electron beam sintering printers to low-cost extrusion machines
* Specificity - instead of working off of general guidelines for printers in your class, produce design rules based on a specific machine, slicing, material, and process parameters combination. Low cost to implement and iterate allows you to easily characterize many combinations.

## Dependencies
This program requires Python 2.7.x or later.

The server depends on [CherryPy](cherrypy.org), which needs to be installed in your Python implementation (built against version 5.0.1)

This server uses [OpenSCAD](openscad.org) binaries, which is assumed by default to reside in a local folder named "openscad" (built against version 2015.03-2). The default location can be changed using server.conf

The front end is written in javascript and HTML5, with help from JQuery, JQuery UI, and [noUiSlider](http://refreshless.com/nouislider/)

Though not necessary to the functioning of any other components of the system, the results log visualizer misc/resultVis.py
uses pandas in an Anaconda environment.

## Usage
Most configuration options are in server.conf. See example_server.conf for a sample.

Run the python server (webserver.py or main.py) and open your browser to the location specified in server.conf. Additional instructions for using the tool are available in help.html.

### Customization
If desired, you may customize the OpenSCAD model that is used. If you do this, for the website to work properly, you will need to re-generate the images used by iterate.html (which are based on the cameraData field in each parameter defined in the scad file). To do this, run modelgen.py as the main program.

As a tool to help build models that scale well to different choices of feature size, running modelparams.py as the main program will generate a set of models with different choices for different size parameters.