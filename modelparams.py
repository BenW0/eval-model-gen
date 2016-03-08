"""
ModelParams

This is a small interface class which makes it easier to keep track of model parameters.
"""


class ModelParams:
    # Field names in the JSON structure provided by the front end
    J_COL_MIN = "col_min"
    J_COL_MAX = "col_max"
    J_ROW_MIN = "row_min"
    J_ROW_MAX = "row_max"
    JSON_FIELDS = [J_COL_MIN, J_COL_MAX, J_ROW_MIN, J_ROW_MAX]

    # variable names used by openscad in the back end
    S_PILLAR_MIN_DIA_VAR = "minPillarDia"
    S_PILLAR_MAX_DIA_VAR = "maxPillarDia"
    S_BAR_MIN_DIA_VAR = "minBarDia"
    S_BAR_MAX_DIA_VAR = "maxBarDia"

    def __init__(self, col_min=0, col_max=0, row_min=0, row_max=0):
        """
        ModelParams class constructor.

        Each parameter is a local variable (this class is effectively a structure), corresponding to a characteristic
        of the test part.
        :param col_min: Minimum column diameter
        :param col_max: Maximum column diameter
        :param row_min: Minimum bar diameter
        :param row_max: Maximum bar diameter
        :return: None
        """
        self.col_min = col_min
        self.col_max = col_max
        self.row_min = row_min
        self.row_max = row_max

    @staticmethod
    def from_json(json):
        """Construct a ModelParams object from JSON data provided by the front end."""
        obj = ModelParams(json[ModelParams.J_COL_MIN],
                          json[ModelParams.J_COL_MAX],
                          json[ModelParams.J_ROW_MIN],
                          json[ModelParams.J_ROW_MAX])

    def to_string(self):
        """Generate a string representation of the class. This is unique for the combination of class elements."""
        return "c%g-%g_r%g-%g" % (self.col_min, self.col_max, self.row_min, self.row_max)

    def to_openscad_defines(self):
        """Generate a list of OpenSCAD arguments of the form "-D %s=%f" where %s is the name of each variable and
        %f is its value."""
        out = []
        out.extend(["-D", "%s=%g" % (self.S_PILLAR_MIN_DIA_VAR, self.col_min)])
        out.extend(["-D", "%s=%g" % (self.S_PILLAR_MAX_DIA_VAR, self.col_max)])
        out.extend(["-D", "%s=%g" % (self.S_BAR_MIN_DIA_VAR, self.row_min)])
        out.extend(["-D", "%s=%g" % (self.S_BAR_MAX_DIA_VAR, self.row_max)])
        return out
