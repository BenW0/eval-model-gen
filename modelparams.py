"""
ModelParams

This is a small interface class which makes it easier to keep track of model parameters.
Now that model parameters have been moved to a configuration file, this class is also responsible for loading
the configuration file on startup.

RUNNING THIS FILE: Running just this file generates a set of models for validating the flexibility of the openscad
   model by creating one model with each variable at 2x its default max and 0.5x its default min.
"""

import json
import os


class ModelParams:
    # String constants containing metadata in the openscad file comments
    JSON_START = "<json>"
    JSON_END = "</json>"

    # A couple of hard-coded fields
    LAYER_HEIGHT_VAR = "layerHeight"
    NOZZLE_DIAMETER_VAR = "nozzleDiameter"

    # String json structure extracted from the scad file's metadata
    json_str = ''
    json_parsed = {}    # parsed version of json data
    # JSON data parsed into a list of valid variables from the front end, which use keys instead of variable names
    # to keep urls shorter. Each entry is keyed by a front end variable, and maps to a back end variable.
    #  This will be used to keep arbitrary assignments from being passed to the scad command line.
    param_map = {}
    # The following dicts follow the structure of self.params and are keyed by backend variable names (dependent
    # variables in the param_map dict).
    default_values = {}         # default values to use if no user input is supplied. Keys are values in param_map
    default_nd_values = {}      # default values to use if only nozzle diameter is supplied
    # An extra dict with camera data for generating images.
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
        else:
            self.params = ModelParams.default_values.copy()

        for key, value in json_struct.items():
            if key in ModelParams.param_map.keys():       # First, make sure it's a valid parameter
                # duplicated entry?
                if type(value) is list:
                    value = value[0]
                # second, make sure it's numeric
                if not ModelParams.is_numberlike(value):
                    err_text = "Non-numeric input ignored"
                else:
                    self.params[ModelParams.param_map[key]] = float(value)

        return success, err_text


    @staticmethod
    def init_settings(model_fname):
        """
        Parses the json metadata in the OpenSCAD model file, storing both the raw JSON (for use in building the
        web page) and the parsed parameters (for use in generating models). This method also assigns a numeric
        key which is used to keep url and variable names short on the front end.

        :param model_fname: (string) Filename of the OpenSCAD model file to parse.
        """
        # Clear the shared datastructures we'll be setting in this module
        ModelParams.default_values = {}
        ModelParams.default_nd_values = {}
        ModelParams.param_map = {ModelParams.LAYER_HEIGHT_VAR: ModelParams.LAYER_HEIGHT_VAR,
                                 ModelParams.NOZZLE_DIAMETER_VAR: ModelParams.NOZZLE_DIAMETER_VAR}
        ModelParams.camera_data = {}

        with open(model_fname, "r") as fin:
            everything = fin.read()

        jstr = "["

        chunks = everything.split(ModelParams.JSON_START)
        chunks.pop(0)       # get rid of the first entry, which is the beginning of the file up to the first match

        for chunk in chunks:
            spt = chunk.split(ModelParams.JSON_END)
            if len(spt) == 1:
                # error
                raise ValueError, "Error parsing OpenSCAD JSON metadata - couldn't find a matching %s field" % ModelParams.JSON_END
            chunk = spt[0].rstrip()
            if chunk[-1] != ",":
                chunk += ","
                jstr += chunk

        # clean up the end of the json
        if jstr[-1] == ',':
            jstr = jstr[0:-1]

        jstr += "]"

        # Now parse the json variables into the param_list structure
        ModelParams.json_parsed = json.loads(jstr)
        key = 0
        for item in ModelParams.json_parsed:
            item["varKey"] = key

            var = item["varBase"]
            minvar = "min%s" % var
            ModelParams.param_map["min%i" % key] = minvar
            ModelParams.default_values[minvar] = item["minDefault"]
            ModelParams.default_nd_values[minvar] = item["minDefaultND"]

            maxvar = "max%s" % var
            ModelParams.param_map["max%i" % key] = maxvar
            ModelParams.default_values[maxvar] = item["maxDefault"]
            ModelParams.default_nd_values[maxvar] = item["maxDefaultND"]

            ModelParams.camera_data[var] = item["cameraData"]

            key += 1

        # re-compile the modified json to a string for the server
        ModelParams.json_str = json.dumps(ModelParams.json_parsed,)

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


def main():
    # Generate a series of eval models (to be checked manually) to verify the model's flexibility to different inputs.
    # This is not a unit test!
    import modelgen
    import time
    import shutil

    print("Building a variety of models to check scad flexibility...")

    eng = modelgen.Engine()
    ModelParams.init_settings(eng.model_name)

    if os.path.exists("modelcache/validation"):
        shutil.rmtree("modelcache/validation")
    os.mkdir("modelcache/validation")

    # Generate a pair of models for layerHeight.
    var = ModelParams.LAYER_HEIGHT_VAR

    # first, do a small variant
    model1 = ModelParams()
    model1.params[var] = "0.05"

    eng.start_job(model1)

    # next, do a big variant
    model2 = ModelParams()
    model2.params[var] = "0.5"

    eng.start_job(model2)
    done = False
    while not done:
        time.sleep(1)
        res2 = eng.check_job(model2)
        res1 = eng.check_job(model1)
        done = res2[0] and res1[0]

    shutil.copy("modelcache/" + res2[1], "modelcache/validation/%s-big.stl" % var)
    shutil.copy("modelcache/" + res1[1], "modelcache/validation/%s-small.stl" % var)
    print("%s-big done" % var)

    for item in ModelParams.json_parsed:
        var = item["varBase"]

        # first, do a small variant
        model1 = ModelParams()
        model1.params["min" + var] = "0.5 * " + str(item["minDefault"])
        model1.params["max" + var] = "0.5 * " + str(item["minDefault"])

        eng.start_job(model1)

        # next, do a big variant. We'll let both jobs run so we can use two cores
        model2 = ModelParams()
        model2.params["min" + var] = "2 * " + str(item["maxDefault"])
        model2.params["max" + var] = "2 * " + str(item["maxDefault"])

        eng.start_job(model2)
        done = False
        while not done:
            time.sleep(1)
            res1 = eng.check_job(model1)
            res2 = eng.check_job(model2)
            done = res2[0] and res1[0]

        shutil.copy("modelcache/" + res1[1], "modelcache/validation/%s-small.stl" % var)
        shutil.copy("modelcache/" + res2[1], "modelcache/validation/%s-big.stl" % var)
        print("%s done" % var)




if __name__ == "__main__":
    main()