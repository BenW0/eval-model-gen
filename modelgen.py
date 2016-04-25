""" modelgen

Uses openscad to build an STL file with a given set of parameters.
This is a small wrapper over the command line, capable of running multiple jobs in parallel from
a main Engine class.

RUNNING THIS FILE: Running just this file will create the preview images in public/images if they don't already exist,
  and if they do, it will run a test of the model engine's code.

NOTE: This code is written on Windows and assumes openscad is present in the openscad folder. Tweaks may be required
for other OS's to the global constants at the top of this file for tests to work; server.conf also sets these variables.

TODO: see github
"""

import subprocess
import sys
import os
import time
import difflib

from modelparams import ModelParams

# Default settings. Override these with the modelgen namespace of server.conf
if os.name == 'posix':      # linux and mac
    OPENSCAD_EXE = "openscad/bin/openscad"
else:                       # windows
    OPENSCAD_EXE = "openscad/openscad"

MODEL_NAME = "Eval Model.scad"

# path to images used for visualization
IMAGES_PATH = "public/images"




class Engine:
    """Modelgen Engine

    Handles a set of running Modelgen instances, each associated with a different model being compiled.

    """

    openscad_exe = OPENSCAD_EXE
    model_name = MODEL_NAME

    def __init__(self):
        """Engine constructor."""
        # mgs will be a dictionary of Modelgen objects, identified by the stringified form of their parameters.
        self.mgs = {}
        # Make sure some folders we need are present.
        if not os.path.exists("logs"):
            os.mkdir("logs")
        if not os.path.exists("modelcache"):
            os.mkdir("modelcache")
        if not os.path.exists("openscad"):
            print("Error! Can't find openscad! Model creation will fail!")

    @staticmethod
    def modelgen_settings(key, value):
        """Handler for cherrypy's config system, called when it encounters the 'modelgen' namespace of the [global]
        section"""
        try:
            if key.lower() == 'openscad':
                Engine.openscad_exe = value
            if key.lower() == 'model':
                Engine.model_name = value
        finally:
            pass

    @staticmethod
    def check_exists(model):
        """
        Check to see if a file exists in the model cache. Returns (exists, path_to_file).
        :param model: ModelParams instance
        :return: (exists, model_filename). exists is True if a cached STL that matches params' signature is present; else False
            in the False case, model_filename is the file name in the Job.CACHE_DIR folder where the file may someday be created.
        """
        fname = Job.cache_name(model)
        path = Job.cache_path(model)
        return os.path.exists(path), fname

    def start_job(self, model):
        """
        Starts a Modelgen job using ModelParams object model. This will start it regardless of whether a cached
        solution already exists.

        :param model: ModelParams object defining the model to be created
        :return: (success, errortext), where success is a Boolean and errortext is a string explaining the error if
                success == False
        """
        key = model.to_hash()
        if key in self.mgs:
            # This key is duplicate; a job is already running.
            return True, ""

        mg = Job(model)
        ret = mg.start()
        if not ret[0]:
            return ret

        self.mgs[key] = mg

        return True, ""

    def check_job(self, model):
        """
        Returns the status of a model: (finished, path_to_file, success, errortext)

        :param model: ModelParams object specifying which model to check
        :return: Tuple: (finished, path_to_file, success, errortext)
        """
        key = model.to_hash()

        ready = False
        success = True
        err = ""
        if key in self.mgs:
            ready, success, err = self.mgs[key].check_ready()
            path = Job.cache_name(model)
            if ready:
                self.mgs.pop(key)       # let the GC destroy the object
        else:
            ready, path = self.check_exists(model)
            if not ready:
                err = "check_job has no job running and no file in the cache for model %s" % key
                self.start_job(model)
            else:
                err = "cached file found."

        return ready, path, success, err

    def lint_jobs(self):
        """Cleans up jobs which have finished but haven't been deleted. This should be run once in a while in a
        server environment"""
        raise NotImplementedError

    @staticmethod
    def _build_images():
        """A script to generate the cache of images used to visualize the relevant feature on the front end"""

        for var, camera in ModelParams.camera_data.items():
            for i in range(11):
                outfile = os.path.join(IMAGES_PATH, "%s-%i.png" % (var, i))
                popen_params = [Engine.openscad_exe, "-o", outfile, "-D", "skip%s=%i" % (var, i),
                                "--camera=%s" % camera, "--autocenter", "--imgsize=440,440",
                                "--projection=ortho", Engine.model_name]
                print(repr(popen_params))
                proc = subprocess.Popen(popen_params)
                proc.wait()  # wait for the process to finish


class Job:
    """Modelgen Job

    Main class which governs a single instance of openscad. If multiple threads need access simultaneously, spawn
    one copy per thread.

    This code can be run asynchronously, by executing start() with parameters, then polling check_ready() until
    the process completes. Alternately, the compilation can be executed synchronously by calling run(). run() and
    start() use identical arguments.

    The resulting file is located in a local cache of models
    kept to speed up duplicate queries. Check to see if a model is already in the cache using .check_exists

    In general, fields labeled params should be an instance of the ModelParams class.

    """

    CACHE_DIR = "modelcache"

    def __init__(self, model):
        """ Modelgen constructor
        :param model: A ModelParam object associated with this Modelgen instance.
        :return:
        """
        self.model = model
        self.proc = None
        self.fname = self.cache_name(self.model)
        self.haveError = False
        self.lastError = ""
        self.logfile = None
        self.logfilename = "logs/%i-%i.log" % (model.to_hash(), time.time())      # make sure it's unique

    def __del__(self):
        try:
            if self.logfile is not None:
                self.logfile.close()
        except Exception:
            pass

    @staticmethod
    def cache_name(model):
        """
        Define the local cache save name for a given parameter set params
        :param model: ModelParams instance (not checked)
        :return: String containing the name of the (potentially nonexistant) cached file
        """
        return "%i.stl" % model.to_hash()

    @staticmethod
    def cache_path(model):
        """
        Define the relative path and filename for a given parameter set params
        :param model: ModelParams instance (not checked)
        :return: String containing the path to the (potentially nonexistant) cached file
        """
        return os.path.join(Job.CACHE_DIR, Job.cache_name(model))

    def start(self):
        """Starts the openscad rendering process.

        Return:
            A tuple: (success, error). success is True if the process started successfully and False otherwise.
                If success = False, error is populated with a string description of the error encountered.
        """

        try:
            popen_params = [Engine.openscad_exe, "-o", os.path.join(Job.CACHE_DIR, self.fname)]
            popen_params.extend(self.model.to_openscad_defines())
            popen_params.append(Engine.model_name)
            print popen_params
        except Exception as e:
            self.haveError = True
            self.lastError = str(e)
            return False, str(e)

        try:
            self.logfile = open(self.logfilename, "w")
            self.proc = subprocess.Popen(popen_params, stdout=self.logfile, stderr=subprocess.STDOUT, bufsize=-1)
        except Exception as e:
            self.haveError = True
            self.lastError = str(e)
            return False, str(e)

        return True, ""

    def _finish(self):
        """Perform cleanup when finished executing an OpenSCAD call. Returns (success, errortext)"""
        self.proc.wait()        # in case it isn't already done
        self.logfile.close()
        if self.proc.returncode != 0:
            self.haveError = True
            with open(self.logfilename, "r") as fin:
                self.lastError = fin.read()
        try:
            os.remove(self.logfilename)
        except Exception:
            pass
        self.proc = None

        return not self.haveError, self.lastError

    def check_ready(self):
        """Check whether the current openscad process is finished. Returns a
        :rtype: tuple: (done, success, errortext)
        """
        if self.proc is not None:
            if self.proc.poll() is not None:
                ret = self._finish()
                return True, ret[0], ret[1]
            else:
                return False, True, ""
        else:
            return True, not self.haveError, self.lastError  # no process running

    def wait_till_done(self):
        """Waits until the current openscad process is finished. Returns tuple: (success, errorstring)"""
        if self.proc is not None:
            self.proc.wait()
            return self._finish()
        return not self.haveError, self.lastError

    def run(self):
        """Performs the openscad rendering process, returning when complete.

        Return: Tuple (success, errortext)
            True if the process completed
            False if an error occurred when starting the process; errortext is filled with a string description of the error.
        """

        ret = self.start()
        if not ret[0]:
            return ret
        return self.wait_till_done()


if __name__ == "__main__":
    # load model parameters into modelparams
    ModelParams.init_settings(Engine.model_name)

    # Check to see if images need to be generated...
    if True or not os.path.exists(os.path.join(IMAGES_PATH, "%s-0.png" % ModelParams.camera_data.keys()[0])):
        # Need to generate the images...
        Engine._build_images()
    else:
        print "Running Modelgen tests"
        # this script implements a test of the modelgen module.
        automated = False
        authoritative = False       # if True, the output from this script will be sent to the reference file.

        if automated:
            fout = open("temp.txt", "w")
            #sys.stdout = fout
        elif authoritative:
            print "Authoritative test. Recording to file."
            fout = open("modelgen.test", "w")
            #sys.systdout = fout
        else:
            fout = sys.stdout


        mymodel1 = ModelParams()
        mymodel1.params[ModelParams.LAYER_HEIGHT_VAR] = 0.2
        mymodel2 = ModelParams()
        mymodel2.params[ModelParams.LAYER_HEIGHT_VAR] = 0.3

        print >>fout, "Deleting cached models..."
        if os.path.exists(Job.cache_path(mymodel1)):
            os.remove(Job.cache_path(mymodel1))
        if os.path.exists(Job.cache_path(mymodel2)):
            os.remove(Job.cache_path(mymodel2))

        start = time.time()
        eng = Engine()
        print >>sys.stderr, "Startup: %is" % (time.time() - start)
        start = time.time()
        print >>fout, "Model 1 exists? " + str(eng.check_exists(mymodel1)[0]) + " Model 2 exists? " + str(eng.check_exists(mymodel2)[0])
        eng.start_job(mymodel1)
        print >>fout, "Started"
        print >>sys.stderr, "Start_job: %is" % (time.time() - start)
        start = time.time()

        def checkdone():
            (done, pth, suc, errtxt) = eng.check_job(mymodel1)
            print >>fout, "Model 1 done=%i fname=%s, success=%i, err='%s'" % (done, pth, suc, errtxt),
            (done, pth, suc, errtxt) = eng.check_job(mymodel2)
            print >>fout, "Model 2 done=%i fname=%s, success=%i, err='%s'" % (done, pth, suc, errtxt)

        print >>fout, "Immediately after start: "
        checkdone()
        print >>sys.stderr, "Check done: %is" % (time.time() - start)
        time.sleep(1)

        print >>fout, "1s after start: "
        start = time.time()
        checkdone()
        print >>sys.stderr, "Check done: %is" % (time.time() - start)
        time.sleep(20)      # time enough for the process to finish

        print >>fout, "11s after start:"
        start = time.time()
        checkdone()
        print >>sys.stderr, "Check done: %is" % (time.time() - start)
        start = time.time()
        checkdone()
        print >>sys.stderr, "Check done: %is" % (time.time() - start)

        print >>fout, "Model 1 exists? " + str(eng.check_exists(mymodel1)[0]) + " Model 2 exists? " + str(eng.check_exists(mymodel2)[0])

        if authoritative:
            fout.close()
        if automated:
            fout.close()

            # compare with autoritative output
            with open("modelgen.test") as fauth:
                with open("temp.txt") as fthis:
                    auth = []
                    for line in fauth:
                        auth.append(line)
                    this = []
                    for line in fthis:
                        this.append(line)
                    diff = difflib.context_diff(auth, this, 'Reference', 'This run')
                    sdiff = ''.join(diff)
                    if sdiff == '':
                        print "Tests passed!"
                    print sdiff
                    fthis.close()
