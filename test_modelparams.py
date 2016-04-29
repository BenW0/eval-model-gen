# Tests for modelparams module and the ModelParams class.
# These are not the best unit tests ever written, but I'm learning!


import unittest
from modelparams import ModelParams as mp
import json


class ModelParamsInitCase(unittest.TestCase):
    """Tests for initialization (static methods) for `modelparams.py`."""

    @staticmethod
    def suite():
        return unittest.TestLoader().loadTestsFromTestCase(ModelParamsInitCase)

    def test_init_settings_no_file(self):
        """init_settings should raise an exception if the model file doesn't exist"""
        with self.assertRaises(IOError):
            mp.init_settings('foo.bar')

    def test_init_invalid_file(self):
        """init_settings should raise an exception if the model file doesn't contain valid blocks of json.
        This test checks a bunch of test files with various errors."""
        mp.init_settings('test_data/no-json.scad')
        self.assertTrue(len(mp.json_parsed) == 0, msg="File with no json didn't load properly")

        with self.assertRaises(ValueError):
            mp.init_settings('test_data/bad-json-tag.scad')

        with self.assertRaises(ValueError):
            mp.init_settings('test_data/gibberish-in-tag.scad')

        with self.assertRaises(ValueError):
            mp.init_settings('test_data/json-syntax-error.scad')

        mp.init_settings('test_data/two-valid-json.scad')
        self.assertEqual(len(mp.json_parsed), 2, msg="Didn't get two loaded json blocks")
        self.assertEqual(len(mp.param_map.keys()), 6,
                         msg="Wrong number of entries in param_map.keys() for two-valid-json")
        self.assertNotEqual(json.loads(mp.json_str)[0]['varKey'], json.loads(mp.json_str)[1]['varKey'],
                            msg="Didn't get different keys for different variables!")

        mp.init_settings('test_data/one-valid-json.scad')
        self.assertEqual(len(mp.json_parsed), 1, msg="Didn't get only one loaded json block")
        self.assertEqual(mp.json_parsed[0]["varBase"], "VarBase1", msg="Didn't load varBase property")
        self.assertEqual(len(mp.param_map.keys()), 4, msg="Wrong number of entries in param_map.keys()")
        self.assertEqual(mp.param_map['min0'], 'minVarBase1', msg="Bad test entry in param_map")
        self.assertEqual(len(mp.default_values), 2, msg="Wrong number of default values")
        self.assertEqual(len(mp.default_nd_values), 2, msg="Wrong number of default ND values")
        self.assertEqual(len(mp.camera_data), 1, msg="Wrong number of entries in camera_data")
        self.assertTrue('varKey' in mp.json_parsed[0], msg="No Key attribute in json_parsed")
        self.assertEqual(mp.param_map['min%i' % mp.json_parsed[0]["varKey"]], 'min%s' % mp.json_parsed[0]['varBase'],
                         msg="param_map wasn't correctly constructed")
        self.assertEqual(json.loads(mp.json_str)[0]['varKey'], 0)

    def test_is_numberlike(self):
        """Tests whether is_numberlike works as expected"""
        self.assertTrue(mp.is_numberlike(2), msg="integer should be numberlike")
        self.assertTrue(mp.is_numberlike(1.3), msg="float should be numberlike")
        self.assertTrue(mp.is_numberlike(1.25463483719023e100), msg="Double should be numberlike")
        self.assertTrue(mp.is_numberlike("23.41"), msg="string float should be numberlike")
        self.assertTrue(mp.is_numberlike("1.623487657e100"), msg="string double should be numberlike")
        self.assertTrue(mp.is_numberlike("-63.0"), msg="negative integer string should be numberlike")
        self.assertFalse(mp.is_numberlike("A quick brown fox"), msg="Random text should not be numberlike")
        self.assertFalse(mp.is_numberlike({}), msg="A dict shouldn't be numberlike")


class ModelParamsTestCase(unittest.TestCase):
    """Tests for `modelparams.py`."""

    @staticmethod
    def suite():
        return unittest.TestLoader().loadTestsFromTestCase(ModelParamsTestCase)

    def setUp(self):
        mp.init_settings('test_data/test.scad')
        self.model = mp()
        # Load a bunch of query data for use in different tests
        self.json_data = json.load(open('test_data/modelparams.json'))

    def test_modelparams_init(self):
        """Tests for the __init__ function of ModelParams"""
        self.model.params["TestVar"] = 63
        self.assertFalse("TestVar" in mp.default_values,
                            msg="Modifying a model parameter shouldn't change the defaults")

    def test_normal_load(self):
        """Tests load_json with a valid structure"""
        self.model.load_json(self.json_data["Normal"])
        self.assertDictEqual(self.model.params, {"layerHeight": 0.1,
                                                 "minVar0": 0,
                                                 "maxVar0": 1,
                                                 "minVar1": 2,
                                                 "maxVar1": 3,
                                                 "minVar2": 2,
                                                 "maxVar2": 3},
                             msg="Failed to load and translate Normal json")

        self.model.load_json(self.json_data["Defaults"])
        self.assertEqual(self.model.params["minVar0"], 1, msg="Didn't reset to defaults after reloading json")


    def test_missing_param(self):
        """Tests load_json with a missing parameter"""
        self.model.load_json(self.json_data["MissingParam"])
        self.assertEqual(self.model.params['minVar2'], "layerHeight", msg="Failed to apply default when missing parameter")
        self.assertEqual(self.model.params['maxVar0'], 1, msg="Failed to load a supplied parameter when missing params")

    def test_missing_layerheight(self):
        """Tests load_json with a struct that's missing layerHeight"""
        self.model.load_json(self.json_data["MissingLayerHeight"])
        self.assertFalse(mp.LAYER_HEIGHT_VAR in self.model.params, msg="Missing LayerHeight mysteriously appeared!")

    def test_duplicate_param(self):
        """Tests a json with a duplicate parameter"""
        self.model.load_json(self.json_data["DuplicateParam"])
        self.assertTrue(self.model.params["minVar0"] in (6, 7), msg="Duplicate parameter load didn't work")

    def test_string_param(self):
        """Tests a json with a string parameter"""
        self.model.load_json(self.json_data["StringParam"])
        self.assertEqual(self.model.params["layerHeight"], 0.1, msg="String parameter load didn't parse correctly")

    def test_extra_param(self):
        """Tests a json with an extra parameter"""
        self.model.load_json(self.json_data["ExtraParam"])
        self.assertEqual(len(self.model.params.keys()), 7, msg="Extra parameter appears in model.params")

    def test_nd_param(self):
        """Tests a json with a nozleDiameter parameter"""
        self.model.load_json(self.json_data["NDParamSet"])
        self.assertEqual(self.model.params["minVar2"], "5 * nozzleDiameter", msg="ND default did not load")

    def test_nd_override_param(self):
        """Tests a json with a nozzleDiameter parameter and an override"""
        self.model.load_json(self.json_data["NDParamOverride"])
        self.assertEqual(self.model.params["minVar0"], 0, msg="ND Override parameter didn't load")

    def test_hash(self):
        """Tests the ModelParams.to_hash() function"""
        self.model.load_json(self.json_data["Normal"])
        self.assertEqual(self.model.to_hash(), self.model.to_hash(), msg="Hashes aren't deterministic!")

        model2 = mp()
        model2.load_json(self.json_data["Normal"])
        self.assertEqual(self.model.to_hash(), model2.to_hash(),
                         msg="Two objects with the same params should have the same hash")

        model2.params["minVar0"] = 63
        self.assertNotEqual(self.model.to_hash(), model2.to_hash(),
                            msg="Changing a parameter should change the hash")

        model3 = mp()
        model3.load_json(self.json_data["NDParamSet"])
        self.assertNotEqual(self.model.to_hash(), model3.to_hash(), msg="Different objects should have different hashes")

    def test_to_openscad_defines(self):
        """Tests ModelParams.to_openscad_defines() function"""

        self.model.load_json(self.json_data["Normal"])

        defines = reduce(lambda x,y: '%s %s' % (x,y), self.model.to_openscad_defines())
        self.assertTrue("-D layerHeight=0.1" in defines,
                        msg="layerHeight didn't wind up in defines")
        self.assertTrue("-D minVar0=0" in defines,
                        msg="minVar0 didn't wind up in defines")
        self.assertTrue("-D maxVar1=3" in defines,
                        msg="maxVar1 didn't wind up in defines")
        self.assertTrue("-D minVar2=2" in defines,
                        msg="minVar2 didn't wind up in defines")

        self.model.load_json(self.json_data["Defaults"])
        self.assertTrue("maxVar2=2 * layerHeight" in self.model.to_openscad_defines(),
                        msg="Didn't properly write defaults to openscad defines")


if __name__ == "__main__":
    #all_tests = unittest.TestSuite([ModelParamsInitCase.suite(), ModelParamsTestCase.suite()])
    #all_tests.run()
    unittest.main(module=ModelParamsTestCase)
