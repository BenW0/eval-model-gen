""" modelgen

Uses openscad to build an STL file with a given set of parameters.
This is a small wrapper over the command line

TODO: Make this code capture return values and error messages
"""

import subprocess


class Modelgen():
    """Modelgen

    Main class which governs a single instance of openscad. If multiple threads need access simultaneously, spawn
    one copy per thread.

    Attributes:
        OPENSCAD_EXE (string): Path to the openscad.exe executable
        MODEL_NAME (string): Name of model code to compile (.scad)
        PILLAR_MIN_DIA_VAR (string): Name of variable associated with the minimum pillar diameter
        PILLAR_MAX_DIA_VAR (string): Name of variable associated with the maximum pillar diameter

    This code can be run asynchronously, by executing start() with parameters, then polling check_ready() until
    the process completes. Alternately, the compilation can be executed synchronously by calling run(). run() and
    start() use identical arguments.

    """
    OPENSCAD_EXE = r"C:\Program Files\OpenSCAD\openscad.exe"
    MODEL_NAME = "Eval Model.scad"
    PILLAR_MIN_DIA_VAR = "minPillarDia"
    PILLAR_MAX_DIA_VAR = "maxPillarDia"

    def __init__(self):
        self.proc = None

    def start(self, fname="test.stl", pillar_dia_min=0.1, pillar_dia_max=1):
        """Starts the openscad rendering process.

        Args:
            fname (Optional[string]): file name of the STL file to be produced.
            pillar_dia_min (Optional[float]): minimum pillar diameter
            pillar_dia_max (Optional[float]): maximum pillar diameter
        """

        self.proc = subprocess.Popen([self.OPENSCAD_EXE, "-o", fname, "-D", "%s=%f" % (self.PILLAR_MIN_DIA_VAR, pillar_dia_min),
                          "-D", "%s=%f" % (self.PILLAR_MAX_DIA_VAR, pillar_dia_max), self.MODEL_NAME])

    def check_ready(self):
        """Checks whether the current openscad process is finished"""
        if self.proc is not None:
            if self.proc.poll() is None:
                self.proc = None
                return True
            else:
                return False
        else:
            return True  # no process running

    def wait_till_done(self):
        """Waits until the current openscad process is finished"""
        if self.proc is not None:
            self.proc.wait()

    def run(self, fname="test.stl", pillar_dia_min=0.1, pillar_dia_max=1):
        """Performs the openscad rendering process, returning when complete.

        Args:
            fname (Optional[string]): file name of the STL file to be produced.
            pillar_dia_min (Optional[float]): minimum pillar diameter
            pillar_dia_max (Optional[float]): maximum pillar diameter
        """

        self.start(fname, pillar_dia_min, pillar_dia_max)
        self.wait_till_done()


if __name__ == "__main__":
    obj = Modelgen()
    obj.run()
