"""
ModelParams

This is a small interface class which makes it easier to keep track of model parameters.
Now that model parameters have been moved to a configuration file, this class is also responsible for loading
the configuration file on startup.
"""

import json
import os


class ModelParams:
    # String constants containing metadata in the openscad file comments
    JSON_START = "<json>"
    JSON_END = "</json>"
    JSON_PARAM = "Param"        # name of Model parameter block in scad json metadata

    # A couple of hard-coded fields
    LAYER_HEIGHT_VAR = "layerHeight"
    NOZZLE_DIAMETER_VAR = "nozzleDiameter"

    # String json structure extracted from the scad file's metadata
    json_str = ''
    json_parsed = {}    # parsed version of json data
    # JSON data parsed into a list of valid variables. This will be used to keep arbitrary assignments from being
    # passed to the scad command line.
    param_list = [LAYER_HEIGHT_VAR, NOZZLE_DIAMETER_VAR]
    default_values = {}         # default values to use if no user input is supplied. Keys are entries in param_list
    default_nd_values = {}      # default values to use if only nozzle diameter is supplied
    camera_data = {}              # dict of variables and associated camera settings, used for visualization

    def __init__(self):
        """
        ModelParams class constructor.

        Initialize the params dictionary to a set of defaults.
        :return: None
        """
        self.params = ModelParams.default_values.copy()

    def load_json(self, json_struct):
        """Makes this ModelParams object match the settings from the JSON data provided by the front end.

        :param json_struct: Parsed json tree
        :returns (success, error_text)
        """

        err_text = ""
        success = True

        # check for the presence of a nozzleDiameter field. If there is one, then we'll initialize everything else
        # to a default specified in default_nd_values.
        if ModelParams.NOZZLE_DIAMETER_VAR in json_struct:
            self.params = ModelParams.default_nd_values.copy()

        for key, value in json_struct.items():
            if key in ModelParams.param_list:       # First, make sure it's a valid parameter
                # second, make sure it's numeric
                if not ModelParams.is_numberlike(value):
                    err_text = "Non-numeric input ignored"
                else:
                    self.params[key] = float(value)

        return success, err_text


    @staticmethod
    def init_settings(model_fname):
        """
        Parses the json metadata in the OpenSCAD model file, storing both the raw JSON (for use in building the
        web page) and the parsed parameters (for use in generating models)

        :param model_fname: (string) Filename of the OpenSCAD model file to parse.
        """
        with open(model_fname, "r") as fin:
            everything = fin.read()

        ModelParams.json_str = "["

        chunks = everything.split(ModelParams.JSON_START)
        chunks.pop(0)       # get rid of the first entry, which is the beginning of the file up to the first match

        for chunk in chunks:
            spt = chunk.split(ModelParams.JSON_END)
            if len(spt) == 1:
                # error
                raise Exception, "Error parsing OpenSCAD JSON metadata - couldn't find a matching %s field" % ModelParams.JSON_END
            chunk = spt[0].rstrip()
            if chunk[-1] != ",":
                chunk += ","
            ModelParams.json_str += chunk

        # clean up the end of the json
        if ModelParams.json_str[-1] == ',':
            ModelParams.json_str = ModelParams.json_str[0:-1]
        ModelParams.json_str += "]"

        # Now parse the json variables into the param_list structure
        ModelParams.json_parsed = json.loads(ModelParams.json_str)
        for item in ModelParams.json_parsed:
            var = item["varBase"]
            minvar = "min%s" % var
            ModelParams.param_list.append(minvar)
            ModelParams.default_values[minvar] = item["minDefault"]
            ModelParams.default_nd_values[minvar] = item["minDefaultND"]

            maxvar = "max%s" % var
            ModelParams.param_list.append(maxvar)
            ModelParams.default_values[maxvar] = item["maxDefault"]
            ModelParams.default_nd_values[maxvar] = item["maxDefaultND"]

            ModelParams.camera_data[var] = item["cameraData"]

    def to_hash(self):
        """Generate a string representation of the class. This is unique for the combination of class elements."""
        # TODO: Make this more reliable if we ever scale accross multiple Python instances. Right now it's
        # platform-dependent
        return hash(frozenset(self.params.items()))

    def to_openscad_defines(self):
        """Generate a list of OpenSCAD arguments of the form "-D %s=%f" where %s is the name of each variable and
        %f is its value."""
        out = []
        for key, value in self.params.items():
            out.extend(["-D", "%s=%s" % (key, str(value))])
        return out

    @staticmethod
    def is_numberlike(data):
        if type(data) is float or type(data) is int:
            return True
        if isinstance(data, basestring):
            try:
                temp = float(data)  # try parsing the string into a float
            except ValueError:
                return False
            return True
        return False
