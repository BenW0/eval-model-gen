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
import datetime

# Global index of EvalModel objects based on the contents of /eval_suites/
EvalSuites = {}


class EvalSuite:
    """EvalSuites stores information related to a suite of evaluation models, mostly loaded from the config file in
    one of the folders in /eval_suites.
    """

    def __init__(self, key, config, root_folder='eval_suites'):
        """Initialize an EvalSuite instance.

        :param folder (string): folder name which contains the actual scad models. Also becomes the key for this suite.
        :param config (dict): portion of the eval_suites/config.json configuration file that pertains to this suite.
        """

        # Set some defaults
        self.key = key
        self.name = "Untitled Test Suite"
        self.subtitle = ""
        self.rank = 100
        self.dependencies = []      # list of keys to other evaluation suites that need to be run before this one.
        self.models = {}
        self.json = config

        # Parse out the json configuration we were handed
        if "Name" in self.json:
            self.name = self.json["Name"]

        if "Subtitle" in self.json:
            self.subtitle = self.json["Subtitle"]

        if "Rank" in self.json:
            self.rank = int(self.json["Rank"])

        if "Dependencies" in self.json:
            self.dependencies = self.json["Dependencies"]

        if "Models" in self.json:
            for key, model in self.json["Models"].iteritems():
                name = key
                if "Name" in model:
                    name = model["Name"]
                if "Filename" in model:
                    m = Model(self, key, os.path.join(root_folder, self.key, model["Filename"]), name)
                    self.models[m.key] = m
                else:
                    print("Model entries must contain at least a filename field! Model %s will not be loaded." % key)

    @staticmethod
    def populate_suites(override_folder=''):
        """Go through all the evaluation suites in the folder ./eval_suites and populate the global EvalSuites list.

        :param override_folder (string): Overrides the filename of the configuration json file. By default
                                        ./eval_suites/config.json is used. This is mostly for unit tests."""
        EvalSuites.clear()

        # Load the configuration file which contains information about the suites to use
        path = "eval_suites"
        if override_folder != '':
            path = override_folder

        fname = os.path.join(path, "config.json")

        with open(fname, "r") as fin:
            config = json.load(fin)

        for key, value in config.iteritems():
            if key == "Comment":
                continue

            es = EvalSuite(key, value, path)
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

        for skey, ste in EvalSuites.itervalues():
            obj = {"Name": ste.name,
                   "Key": skey,
                   "Subtitle": ste.subtitle,
                   "Rank": ste.rank,
                   "Models": {},
                   "Dependencies": ste.dependencies}

            for key, model in ste.models.iteritems():
                model_params = model.json_parsed
                mod = {"Name": model.name,
                       "Key": key,
                       "Params": model_params}
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
        self.filename = model_fname
        if parent is not None:
            self.log_filename = os.path.join("logs", "%s-%s.log" % (self.parent.key, self.key))
        else:
            self.log_filename = os.path.join("logs", "%s.log" % self.key)

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
        self.instance_counts = {}     # number of possible selections for each parameter.

        # An extra dict with camera data for generating images.
        self.camera_data = {}  # dict of variables and associated camera settings, used for visualization

        # A list which will contain the output field names used when outputing results to file. We're using a list
        # because order matters and dicts reorganize their key ordering...
        self.output_field_vars = ['printerType',
                                  'printerModel',
                                  'printerName',
                                  'groupName',
                                  'feedstockType',
                                  'feedstockColor',
                                  'notes',
                                  'feedback']

        # variable names to put under each heading in the output
        self.output_field_headings = ['Printer Type',
                                      'Printer Model',
                                      'Printer Name',
                                      'Group Name',
                                      'Feedstock Material',
                                      'Feedstock Vendor/Color',
                                      'Notes',
                                      'Feedback']

        if not os.path.exists(model_fname):
            print("Couldn't find model %s" % model_fname)
            return

        with open(model_fname, "r") as fin:
            everything = fin.read()

        jstr = "["

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

        jstr += "]"

        # Now parse the json variables into the param_list structure
        key_list = ("varBase", "minDefault", "minDefaultND", "maxDefault", "maxDefaultND", "cameraData", "instanceCount")
        self.json_parsed = json.loads(jstr)
        for key, item in enumerate(self.json_parsed):
            item["varKey"] = key

            # make sure all the items have an associated key!
            if not all([k in item for k in key_list]):
                print("Variable in %s missing one or more required parameters in json block! That variable will not be available." % self.key)
                continue

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
            self.instance_counts[var] = item["instanceCount"]

            # populate the output variables headings and content
            self.output_field_vars.append('yellow_final%i' % key)
            self.output_field_headings.append(item['Name'] + ' Yellow Minimum')
            self.output_field_vars.append('yellow_error%i' % key)
            self.output_field_headings.append(item['Name'] + ' Yellow Error')

            self.output_field_vars.append('red_final%i' % key)
            self.output_field_headings.append(item['Name'] + ' Red Minimum')
            self.output_field_vars.append('red_error%i' % key)
            self.output_field_headings.append(item['Name'] + ' Red Error')

    @staticmethod
    def submit_to_log(json_struct, submit_id):
        """Receives JSON from the front end and submits results to the log file for the specified suite-model pair.

        :param json_struct: Parsed json tree
        :param submit_id: submission ID to record in the file.
        :returns (success, error_text): success is boolean, error_text is string
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

        # make sure this suite and model exist
        if ste_key not in EvalSuites or model_key not in EvalSuites[ste_key].models:
            success = False
            err_text = "Invalid suite key or invalid model key in json query"
            return None, success, err_text

        ste = EvalSuites[ste_key]
        model = ste.models[model_key]

        str_out = ''
        for key in model.output_field_vars:
            if key in json_struct:
                str_out += str(json_struct[key]).replace('\n', '\\n')
            str_out += '\t'

        try:
            # If it doesn't exist, initialize the results file
            if not os.path.exists(model.log_filename):
                with open(model.log_filename, 'w') as fout:
                    fout.write('ID\tTimestamp\t' + reduce(lambda x, y: x + '\t' + y, model.output_field_headings) + '\n')

            str_out = '%i\t%s\t%s' % (
                            submit_id, '{:%Y-%m-%d %H:%M:%S}'.format(datetime.datetime.now()), str_out)
            # Write out our entry
            with open(model.log_filename, 'a') as fout:
                fout.write(str_out + '\n')

        except Exception as e:
            success = False
            err_text = str(e)

        return success, err_text

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
            if key in model.param_map.keys():  # First, make sure it's a valid parameter
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

    for skey, ste in EvalSuites.iteritems():
        print "Processing suite %s" % skey
        for mkey, model in ste.models.iteritems():
            print "Processing model %s" % model.key

            folder = "modelcache/validation/%s-%s" % (skey, mkey)
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

            for var in model.instance_counts.keys():

                # first, do a small variant
                model1 = ModelParams(model)
                model1.params["min" + var] = "0.5 * " + str(model.default_values["min" + var])
                model1.params["max" + var] = "0.5 * " + str(model.default_values["min" + var])

                eng.start_job(model1)

                # next, do a big variant. We'll let both jobs run so we can use two cores
                model2 = ModelParams(model)
                model2.params["min" + var] = "2 * " + str(model.default_values["max" + var])
                model2.params["max" + var] = "2 * " + str(model.default_values["max" + var])

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
