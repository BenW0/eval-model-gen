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
import glob

# Global index of EvalModel objects based on the contents of /eval_suites/
EvalSuites = {}


class EvalSuite:
    """EvalSuites stores information related to a suite of evaluation models, mostly loaded from the config file in
    one of the folders in /eval_suites.
    """

    def __init__(self, folder_name):
        """Initialize an EvalSuite instance based on the "config.json" file in the folder eval_suites/<folder>"""

        # Set some defaults
        self.key = None
        self.name = "Untitled Test Suite"
        self.subtitle = ""
        self.rank = 100
        self.models = {}

        dirname = os.path.join("eval_suites", folder_name)
        filename = os.path.join(dirname, "config.json")
        with open(filename) as fin:
            self.json = json.load(fin)

        # Parse out the json we just loaded
        if "Key" in self.json:
            self.key = self.json["Key"]
        else:
            raise ValueError, "Required element 'key' missing in %s." % filename

        if "Name" in self.json:
            self.key = self.json["Name"]

        if "Subtitle" in self.json:
            self.key = self.json["Subtitle"]

        if "Rank" in self.json:
            self.rank = int(self.json["Rank"])

        if "Models" in self.json:
            for key, model in self.json["Models"]:
                name = ''
                if "Name" in model:
                    name = model["Name"]
                if "Filename" in model:
                    m = Model(self, os.path.join(key, dirname, model["Filename"]), name)
                    self.models[m.key] = m
        else:
            self.rank = 100

    @staticmethod
    def populate_suites():
        """Go through all the evaluation suites in the folder ./eval_suites and populate the global EvalSuites list"""
        EvalSuites.clear()

        # Get a list of folders inside the eval_suites directory
        dirs = glob.glob(os.path.join("eval_suites/*"))

        for d in dirs:
            if os.path.isdir(d) and os.path.exists(os.path.join("eval_suites", d, "config.json")):
                es = EvalSuite(d)
                EvalSuites[es.key] = es

    @staticmethod
    def get_params_json():
        """
        Generate a json object string describing all the parameters in each model of each suite available.

        The structure is
        {
            "suite_key":{
                "Name":suite_name,
                "Subtitle":subtitle,
                "Rank":rank,
                "Models":{
                    "model_key":{
                        "Name":name,
                        "Params":<Model parameters list>
                    }
                }
            }
        }
        """

        out_json = {}

        for ste in EvalSuites:
            obj = {"Name": ste.name,
                   "Subtitle": ste.subtitle,
                   "Rank": ste.rank,
                   "Models": {}}

            for key, model in ste.models:
                model_params = model.json_parsed
                mod = {"Name":model.name,
                       "Params":model_params}
                obj["Models"][key] = mod

            out_json[ste.key] = obj

        return json.dumps(out_json)


class Model:
    """Class which stores static information about a given model in a suite."""

    # String constants containing metadata in the openscad file comments
    JSON_START = "<json>"
    JSON_END = "</json>"

    # A couple of hard-coded fields
    LAYER_HEIGHT_VAR = "layerHeight"
    NOZZLE_DIAMETER_VAR = "nozzleDiameter"

    def __init__(self, parent, key, model_fname, model_name=''):
        """
        Initialize a Model instance given a parent (instance of EvalSuite) and a filename to the .scad file to parse

        Parses the json metadata in the OpenSCAD model file, storing both the raw JSON (for use in building the
        web page) and the parsed parameters (for use in generating models). This method also assigns a numeric
        key which is used to keep url and variable names short on the front end.

        :param parent: (instance of EvalSuite) EvalSuite this Model is a part of.
        :param key: (string) unique model key in this set of models.
        :param model_fname: (string) Filename of the OpenSCAD model file to parse.
        :param model_name[default:'']: (string) UI-presentable name of this model (optional in case there is only one)
        """

        # Set up the shared datastructures we'll be setting in this module
        self.parent = parent
        self.key = key
        self.name = model_name
        self.model_fname = model_fname

        # String json structure extracted from the scad file's metadata
        self.json_parsed = {}  # parsed version of json data

        # JSON data parsed into a list of valid variables from the front end, which use keys instead of variable names
        # to keep urls shorter. Each entry is keyed by a front end variable, and maps to a back end variable.
        #  This will be used to keep arbitrary assignments from being passed to the scad command line.
        self.param_map = {Model.LAYER_HEIGHT_VAR: Model.LAYER_HEIGHT_VAR,
                          Model.NOZZLE_DIAMETER_VAR: Model.NOZZLE_DIAMETER_VAR}

        # The following dicts follow the structure of self.params and are keyed by backend variable names (dependent
        # variables in the param_map dict).
        self.default_values = {}  # default values to use if no user input is supplied. Keys are values in param_map
        self.default_nd_values = {}  # default values to use if only nozzle diameter is supplied

        # An extra dict with camera data for generating images.
        self.camera_data = {}  # dict of variables and associated camera settings, used for visualization

        with open(model_fname, "r") as fin:
            everything = fin.read()

        jstr = "{"

        chunks = everything.split(Model.JSON_START)
        chunks.pop(0)  # get rid of the first entry, which is the beginning of the file up to the first match

        for chunk in chunks:
            spt = chunk.split(Model.JSON_END)
            if len(spt) == 1:
                # error
                raise ValueError, "Error parsing OpenSCAD JSON metadata - couldn't find a matching %s field" % Model.JSON_END
            chunk = spt[0].rstrip()
            if chunk[-1] != ",":
                chunk += ","
                jstr += chunk

        # clean up the end of the json
        if jstr[-1] == ',':
            jstr = jstr[0:-1]

        jstr += "}"

        # Now parse the json variables into the param_list structure
        self.json_parsed = json.loads(jstr)
        key = 0
        for item in self.json_parsed:
            item["varKey"] = key

            var = item["varBase"]
            minvar = "min%s" % var
            self.param_map["min%i" % key] = minvar
            self.default_values[minvar] = item["minDefault"]
            self.default_nd_values[minvar] = item["minDefaultND"]

            maxvar = "max%s" % var
            self.param_map["max%i" % key] = maxvar
            self.default_values[maxvar] = item["maxDefault"]
            self.default_nd_values[maxvar] = item["maxDefaultND"]

            self.camera_data[var] = item["cameraData"]

            key += 1


class ModelParams:
    def __init__(self, parent):
        """
        ModelParams class constructor.

        Associate this instance of ModelParams to a parent Model and initialize the params dictionary to
        a set of defaults
        :return: None
        """
        self.parent = parent
        self.params = parent.default_values.copy()

    @staticmethod
    def from_json(json_struct):
        """Creates a ModelParams object from the settings in the JSON data provided by the front end.

        :param json_struct: Parsed json tree
        :returns (object, success, error_text): object is a new ModelParams; success is boolean, error_text is string
        """

        err_text = ""
        success = True

        # Find out which model this json belongs to...
        if "suite" not in json_struct or "model" not in json_struct:
            success = False
            err_text = "Could not find 'suite' and 'model' parameters in json"
            return None, success, err_text

        ste_key = json_struct["suite"]
        model_key = json_struct["model"]
        json_struct.pop("suite")
        json_struct.pop("model")

        # make sure this suite and model exist
        if ste_key not in EvalSuites or model_key not in EvalSuites[ste_key].models:
            success = False
            err_text = "Invalid suite key or invalid model key in json query"
            return None, success, err_text

        ste = EvalSuites[ste_key]
        model = ste.models[model_key]

        mp = ModelParams(model)

        # check for the presence of a nozzleDiameter field. If there is one, then we'll initialize everything else
        # to a default specified in default_nd_values.
        if model.NOZZLE_DIAMETER_VAR in json_struct:
            mp.params = mp.parent.default_nd_values.copy()
        else:
            mp.params = mp.parent.default_values.copy()

        for key, value in json_struct.items():
            if key in mp.parent.param_map.keys():  # First, make sure it's a valid parameter
                # duplicated entry?
                if type(value) is list:
                    value = value[0]
                # second, make sure it's numeric
                if not ModelParams.is_numberlike(value):
                    err_text = "Non-numeric input ignored"
                else:
                    mp.params[mp.parent.param_map[key]] = float(value)

        return mp, success, err_text

    def to_hash(self):
        """Generate a string representation of the class. This is unique for the combination of class elements."""
        # TODO: Make this more reliable if we ever scale accross multiple Python instances. Right now it's
        # platform-dependent and probably not very robust...
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
    EvalSuite.populate_suites()

    if os.path.exists("modelcache/validation"):
        shutil.rmtree("modelcache/validation")
    os.mkdir("modelcache/validation")

    for ste in EvalSuites.items():
        print "Processing suite %s" % ste.key
        for model in ste.models.items():
            print "Processing model %s" % model.key

            folder = "modelcache/validation/%s-%s" % (ste.key, model.key)
            os.mkdir(folder)

            # Generate a pair of models for layerHeight.
            var = Model.LAYER_HEIGHT_VAR

            # first, do a small variant
            model1 = ModelParams(model)
            model1.params[var] = "0.05"

            eng.start_job(model1)

            # next, do a big variant
            model2 = ModelParams(model)
            model2.params[var] = "0.5"

            eng.start_job(model2)
            done = False
            while not done:
                time.sleep(1)
                res2 = eng.check_job(model2)
                res1 = eng.check_job(model1)
                done = res2[0] and res1[0]

            shutil.copy("modelcache/" + res2[1], "%s/%s-big.stl" % (folder, var))
            shutil.copy("modelcache/" + res1[1], "%s/%s-small.stl" % (folder, var))
            print("%s-big done" % var)

            for item in model.json_parsed:
                var = item["varBase"]

                # first, do a small variant
                model1 = ModelParams(model)
                model1.params["min" + var] = "0.5 * " + str(item["minDefault"])
                model1.params["max" + var] = "0.5 * " + str(item["minDefault"])

                eng.start_job(model1)

                # next, do a big variant. We'll let both jobs run so we can use two cores
                model2 = ModelParams(model)
                model2.params["min" + var] = "2 * " + str(item["maxDefault"])
                model2.params["max" + var] = "2 * " + str(item["maxDefault"])

                eng.start_job(model2)
                done = False
                while not done:
                    time.sleep(1)
                    res1 = eng.check_job(model1)
                    res2 = eng.check_job(model2)
                    done = res2[0] and res1[0]

                shutil.copy("modelcache/" + res2[1], "%s/%s-big.stl" % (folder, var))
                shutil.copy("modelcache/" + res1[1], "%s/%s-small.stl" % (folder, var))
                print("%s done" % var)


if __name__ == "__main__":
    main()
