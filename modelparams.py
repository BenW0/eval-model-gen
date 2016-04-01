"""
ModelParams

This is a small interface class which makes it easier to keep track of model parameters.
"""


class ModelParams:
    # Field names in the JSON structure provided by the front end
    J_COL_MIN = "col_min"
    J_COL_MAX = "col_max"
    J_BAR_MIN = "bar_min"
    J_BAR_MAX = "bar_max"
    J_LAYER_HEIGHT = "layer_height"
    JSON_FIELDS = [J_COL_MIN, J_COL_MAX, J_BAR_MIN, J_BAR_MAX, J_LAYER_HEIGHT]

    # variable names used by openscad in the back end
    S_PILLAR_MIN_DIA_VAR = "minPillarDiaV"
    S_PILLAR_MAX_DIA_VAR = "maxPillarDiaV"
    S_BAR_MIN_DIA_VAR = "minPillarDiaH"
    S_BAR_MAX_DIA_VAR = "maxPillarDiaH"
    S_LAYER_HEIGHT_VAR = "layerHeight"

    def __init__(self, layer_height=0.0, col_min=0.0, col_max=0.0, bar_min=0.0, bar_max=0.0):
        """
        ModelParams class constructor.

        Each parameter is a local variable (this class is effectively a structure), corresponding to a characteristic
        of the test part.
        :param layer_height: Layer height of the print
        :param col_min: Minimum column diameter
        :param col_max: Maximum column diameter
        :param bar_min: Minimum bar diameter
        :param bar_max: Maximum bar diameter
        :return: None
        """
        self.layer_height = layer_height
        self.col_min = col_min
        self.col_max = col_max
        self.bar_min = bar_min
        self.bar_max = bar_max

    @staticmethod
    def from_json(json):
        """Construct a ModelParams object from JSON data provided by the front end."""
        return ModelParams(float(json[ModelParams.J_LAYER_HEIGHT]),
                           float(json[ModelParams.J_COL_MIN]),
                           float(json[ModelParams.J_COL_MAX]),
                           float(json[ModelParams.J_BAR_MIN]),
                           float(json[ModelParams.J_BAR_MAX]))

    def to_string(self):
        """Generate a string representation of the class. This is unique for the combination of class elements."""
        return "l%gc%g-%g_r%g-%g" % (self.layer_height, self.col_min, self.col_max, self.bar_min, self.bar_max)

    def to_openscad_defines(self):
        """Generate a list of OpenSCAD arguments of the form "-D %s=%f" where %s is the name of each variable and
        %f is its value."""
        out = []
        out.extend(["-D", "%s=%g" % (self.S_LAYER_HEIGHT_VAR, self.layer_height)])
        out.extend(["-D", "%s=%g" % (self.S_PILLAR_MIN_DIA_VAR, self.col_min)])
        out.extend(["-D", "%s=%g" % (self.S_PILLAR_MAX_DIA_VAR, self.col_max)])
        out.extend(["-D", "%s=%g" % (self.S_BAR_MIN_DIA_VAR, self.bar_min)])
        out.extend(["-D", "%s=%g" % (self.S_BAR_MAX_DIA_VAR, self.bar_max)])
        return out
