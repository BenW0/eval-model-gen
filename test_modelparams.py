# Tests for modelparams module and the ModelParams class.
# These are not the best unit tests ever written, but I'm learning!


import unittest
from modelparams import ModelParams, Model, EvalSuite, EvalSuites
import json


class EvalSuiteCase(unittest.TestCase):
    """Tests for the EvalSuite class. These test are very NOT unit tests, as they test EvalSuite
    and Model at once"""

    @staticmethod
    def suite():
        return unittest.TestLoader().loadTestsFromTestCase(EvalSuiteCase)

    def setUp(self):
        """Initialization - load up the test configuration file and associated models"""
        EvalSuite.populate_suites("test_data/eval_suites")

    def test_get_params_json(self):
        """Tests the json output of EvalSuite. This uses methods and structures from EvalSuite and Model."""
        jss = EvalSuite.get_params_json()    # retrieve the json and parse it
        js = json.loads(jss)

        # check some stuff from test1, which is missing some fields
        self.assertEqual(len(js["test1"]["Models"]), 0, msg="Test with no filename still loaded!")

        # Check some things from the test1b suite, which has a single model
        self.assertEqual(len(js["test1b"]["Models"]), 1, msg="Failed to load model in test 1b")
        self.assertEqual(js["test1b"]["Models"]["basic"]["Params"][0]["varBase"], 'TestParam1', msg="Could not find TestParam1 in test 1b")

        # Check that a bunch of fields got loaded from test 2, which has all the fields present
        with open('test_data/evalmodels ref data.json') as fin:
            ref_json = json.load(fin)

        self.assertDictEqual(js["test2"], ref_json)


class ModelCase(unittest.TestCase):
    """Tests for the Model class"""

    @staticmethod
    def suite():
        return unittest.TestLoader().loadTestsFromTestCase(ModelCase)

    def test_init_settings_no_file(self):
        """init should not hit an exception if the model file doesn't exist"""
        test = Model(None, '', 'foo.bar')
        self.assertEqual(len(test.param_map), 2)

    def test_init_invalid_file(self):
        """init_settings should raise an exception if the model file doesn't contain valid blocks of json.
        This test checks a bunch of test files with various errors."""
        m = Model(None, '', 'test_data/no-json.scad')
        self.assertTrue(len(m.json_parsed) == 0, msg="File with no json didn't load properly")

        with self.assertRaises(ValueError):
            Model(None, '', 'test_data/bad-json-tag.scad')

        with self.assertRaises(ValueError):
            Model(None, '', 'test_data/gibberish-in-tag.scad')

        with self.assertRaises(ValueError):
            Model(None, '', 'test_data/json-syntax-error.scad')

        m = Model(None, '', 'test_data/two-valid-json.scad')
        self.assertEqual(len(m.json_parsed), 2, msg="Didn't get two loaded json blocks")
        self.assertEqual(len(m.param_map.keys()), 6,
                         msg="Wrong number of entries in param_map.keys() for two-valid-json")
        self.assertNotEqual(m.json_parsed[0]['varKey'], m.json_parsed[1]['varKey'],
                            msg="Didn't get different keys for different variables!")

        m = Model(None, '', 'test_data/one-valid-json.scad')
        self.assertEqual(len(m.json_parsed), 1, msg="Didn't get only one loaded json block")
        self.assertEqual(m.json_parsed[0]["varBase"], "VarBase1", msg="Didn't load varBase property")
        self.assertEqual(len(m.param_map.keys()), 4, msg="Wrong number of entries in param_map.keys()")
        self.assertEqual(m.param_map['min0'], 'minVarBase1', msg="Bad test entry in param_map")
        self.assertEqual(len(m.default_values), 2, msg="Wrong number of default values")
        self.assertEqual(len(m.default_nd_values), 2, msg="Wrong number of default ND values")
        self.assertEqual(len(m.camera_data), 1, msg="Wrong number of entries in camera_data")
        self.assertTrue('varKey' in m.json_parsed[0], msg="No Key attribute in json_parsed")
        self.assertEqual(m.param_map['min%i' % m.json_parsed[0]["varKey"]], 'min%s' % m.json_parsed[0]['varBase'],
                         msg="param_map wasn't correctly constructed")
        self.assertEqual(m.json_parsed[0]['varKey'], 0)

    def test_init_arrays(self):
        """ Tests a few different conditions involving arrays of parameters collapsed into a single json block."""

        m = Model(None, '', 'test_data/list-test1.scad')
        self.assertTrue("VarBase1" in m.array_vars)
        self.assertTrue("0_VarBase1" in m.default_values)
        self.assertTrue("0_VarBase1" in m.camera_data)
        self.assertEqual()

class ModelParamsInitCase(unittest.TestCase):
    """Tests for initialization (static methods) for `modelparams.py`."""
    
    @staticmethod
    def suite():
        return unittest.TestLoader().loadTestsFromTestCase(ModelParamsInitCase)

    def test_is_numberlike(self):
        """Tests whether is_numberlike works as expected"""
        self.assertTrue(ModelParams.is_numberlike(2), msg="integer should be numberlike")
        self.assertTrue(ModelParams.is_numberlike(1.3), msg="float should be numberlike")
        self.assertTrue(ModelParams.is_numberlike(1.25463483719023e100), msg="Double should be numberlike")
        self.assertTrue(ModelParams.is_numberlike("23.41"), msg="string float should be numberlike")
        self.assertTrue(ModelParams.is_numberlike("1.623487657e100"), msg="string double should be numberlike")
        self.assertTrue(ModelParams.is_numberlike("-63.0"), msg="negative integer string should be numberlike")
        self.assertFalse(ModelParams.is_numberlike("A quick brown fox"), msg="Random text should not be numberlike")
        self.assertFalse(ModelParams.is_numberlike({}), msg="A dict shouldn't be numberlike")


class ModelParamsTestCase(unittest.TestCase):
    """Tests for ModelParams in `modelparams.py`. This leverages EvalModels and Model classes, tested above."""

    @staticmethod
    def suite():
        return unittest.TestLoader().loadTestsFromTestCase(ModelParamsTestCase)

    def setUp(self):
        EvalSuite.populate_suites('test_data/eval_suites')
        self.suite = EvalSuites["test3"]
        self.model = self.suite.models["test"]
        # Load a bunch of query data for use in different tests
        self.json_data = json.load(open('test_data/modelparams.json'))

    def test_modelparams_init(self):
        """Tests for the __init__ function of ModelParams"""
        # Make sure we're actually copying the defaults and not just referencing the parent's collection.
        obj, success, errtext = ModelParams.from_json(self.json_data["Normal"])
        obj.params["TestVar"] = 63
        self.assertFalse("TestVar" in obj.parent.default_values,
                         msg="Modifying a model parameter shouldn't change the defaults")

    def test_normal_load(self):
        """Tests load_json with a valid structure"""
        obj, success, errtext = ModelParams.from_json(self.json_data["Normal"])
        self.assertDictEqual(obj.params, {"layerHeight": 0.1,
                                                 "minVar0": 0,
                                                 "maxVar0": 1,
                                                 "minVar1": 2,
                                                 "maxVar1": 3,
                                                 "minVar2": 2,
                                                 "maxVar2": 3},
                             msg="Failed to load and translate Normal json")

        obj, success, errtext = ModelParams.from_json(self.json_data["Defaults"])
        self.assertEqual(obj.params["minVar0"], 1, msg="Didn't reset to defaults after reloading json")

    def test_missing_param(self):
        """Tests load_json with a missing parameter"""
        obj, success, errtext = ModelParams.from_json(self.json_data["MissingParam"])
        self.assertEqual(obj.params['minVar2'], "layerHeight", msg="Failed to apply default when missing parameter")
        self.assertEqual(obj.params['maxVar0'], 1, msg="Failed to load a supplied parameter when missing params")

    def test_missing_layerheight(self):
        """Tests load_json with a struct that's missing layerHeight"""
        obj, success, errtext = ModelParams.from_json(self.json_data["MissingLayerHeight"])
        self.assertFalse(self.model.LAYER_HEIGHT_VAR in obj.params, msg="Missing LayerHeight mysteriously appeared!")

    def test_duplicate_param(self):
        """Tests a json with a duplicate parameter"""
        obj, success, errtext = ModelParams.from_json(self.json_data["DuplicateParam"])
        self.assertTrue(obj.params["minVar0"] in (6, 7), msg="Duplicate parameter load didn't work")

    def test_string_param(self):
        """Tests a json with a string parameter"""
        obj, success, errtext = ModelParams.from_json(self.json_data["StringParam"])
        self.assertEqual(obj.params["layerHeight"], 0.1, msg="String parameter load didn't parse correctly")

    def test_extra_param(self):
        """Tests a json with an extra parameter"""
        obj, success, errtext = ModelParams.from_json(self.json_data["ExtraParam"])
        self.assertEqual(len(obj.params.keys()), 7, msg="Extra parameter appears in model.params")

    def test_nd_param(self):
        """Tests a json with a nozleDiameter parameter"""
        obj, success, errtext = ModelParams.from_json(self.json_data["NDParamSet"])
        self.assertEqual(obj.params["minVar2"], "5 * nozzleDiameter", msg="ND default did not load")

    def test_nd_override_param(self):
        """Tests a json with a nozzleDiameter parameter and an override"""
        obj, success, errtext = ModelParams.from_json(self.json_data["NDParamOverride"])
        self.assertEqual(obj.params["minVar0"], 0, msg="ND Override parameter didn't load")

    def test_hash(self):
        """Tests the ModelParams.to_hash() function"""
        obj, success, errtext = ModelParams.from_json(self.json_data["Normal"])
        self.assertEqual(obj.to_hash(), obj.to_hash(), msg="Hashes aren't deterministic!")

        model2, success, errtext = ModelParams.from_json(self.json_data["Normal"])
        self.assertEqual(obj.to_hash(), model2.to_hash(),
                         msg="Two objects with the same params should have the same hash")

        model2.params["minVar0"] = 63
        self.assertNotEqual(obj.to_hash(), model2.to_hash(),
                            msg="Changing a parameter should change the hash")

        model3, success, errtext = ModelParams.from_json(self.json_data["NDParamSet"])
        self.assertNotEqual(obj.to_hash(), model3.to_hash(), msg="Different objects should have different hashes")

    def test_to_openscad_defines(self):
        """Tests ModelParams.to_openscad_defines() function"""

        obj, success, errtext = ModelParams.from_json(self.json_data["Normal"])

        defines = reduce(lambda x,y: '%s %s' % (x,y), obj.to_openscad_defines())
        self.assertTrue("-D layerHeight=0.1" in defines,
                        msg="layerHeight didn't wind up in defines")
        self.assertTrue("-D minVar0=0" in defines,
                        msg="minVar0 didn't wind up in defines")
        self.assertTrue("-D maxVar1=3" in defines,
                        msg="maxVar1 didn't wind up in defines")
        self.assertTrue("-D minVar2=2" in defines,
                        msg="minVar2 didn't wind up in defines")

        obj, success, errtext = ModelParams.from_json(self.json_data["Defaults"])
        self.assertTrue("maxVar2=2 * layerHeight" in obj.to_openscad_defines(),
                        msg="Didn't properly write defaults to openscad defines")


if __name__ == "__main__":
    #all_tests = unittest.TestSuite([ModelParamsInitCase.suite(), ModelParamsTestCase.suite()])
    #all_tests.run()
    unittest.main(module=ModelParamsTestCase)
