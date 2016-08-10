""" webserver

This module runs the web server used for interactively generating printer evaluation parts. It uses the modelgen
module to handle the actual compilation of the STL files, and relies on static content in the local <public> folder
for statically served content, as well as on files in the <template> folder for html page source loaded from python.

Executing this module starts the web server. For a more user-friendly experience, execute main.py.

A note on sessions:
  This webapp doesn't use sessions. Instead, the "session" is entirely based on the state of the selection variables.
  So, effectively, the "session id" is the json describing the test part being used.

TODO: see Github

"""

import os
import cherrypy
from cherrypy.lib.static import serve_file
from cherrypy.process import plugins
from modelparams import ModelParams, Model, EvalSuite, EvalSuites
import modelgen
import datetime


class ModelChooserWeb(object):
    @cherrypy.expose
    def index(self):
        return open('template/index.html')

    @cherrypy.expose
    def start(self):
        return open('template/start.html')

    @cherrypy.expose
    def iterate(self):
        return open('template/iterate.html')

    @cherrypy.expose
    def finish(self):
        return open('template/finish.html')

    @cherrypy.expose
    def modelchooser(self):
        return open('template/modelchooser.html')

    @cherrypy.expose
    def getmodel(self, name, mask=True):
        """ Return a model file for download in response to a user's request.
        name is filtered for some basic very basic security, but this maybe should be re-thought later.
        :param name: Name of model file. This is the name of a file
        :param mask: Boolean specifying whether to mask the name of the actual file with "Test Part.stl"
        :return: File server serving the file specified (if it exists)
        """
        # Harden the request string against attempts to break out of the sandbox
        bad_chars = ['/', '\\', '..', ';', '&', '(', ')', '{', '}', '`', '$']
        new_name = name
        for char in bad_chars:
            new_name = new_name.replace(char, '')

        path = os.path.join(os.path.abspath(os.getcwd()), modelgen.Job.CACHE_DIR, new_name)
        # hopefully this will keep us quarantined in the modelcache directory.
        if os.path.exists(path):
            cherrypy.log("%s Serving download of %s" % (mask, path))
            if mask != "False" and mask != "false" and mask != "0":
                return serve_file(path, "application/x-download", "attachment", "Test Part.stl")
            else:
                return serve_file(path, "application/x-download", "attachment")
        else:
            return "<html><body>Requested resource not found</body></html>"


class ModelChooserEngine(object):
    exposed = True

    def __init__(self):
        # Create the engine which will actually do the model construction.
        self.engine = modelgen.Engine()
        # Load the list of evaluation suites and parse the parameters for each model file
        EvalSuite.populate_suites()
        # Save off a copy of the json that we just loaded from the openscad 
        with open("public/js/params.js", "w") as fout:
            fout.write("//This is a generated code file. All changes will be lost on next server load!\n")
            fout.write("params_json = '%s';\n" % EvalSuite.get_params_json().replace("\n", " "))

        # Open the results files (one for each suite-model pairing) and find the biggest entry value
        self.next_submit_id = 0
        for ste in EvalSuites.values():
            for model in ste.models.values():
                if os.path.exists(model.log_filename):
                    with open(model.log_filename, 'r') as fin:
                        last_line = ''
                        for line in fin:
                            last_line = line
                        val = last_line.split('\t')[0]
                        if ModelParams.is_numberlike(val) and int(val) >= self.next_submit_id:
                            self.next_submit_id = int(val) + 1

    @cherrypy.tools.json_in()
    @cherrypy.tools.json_out()
    def POST(self):
        in_data = cherrypy.request.json
        cherrypy.log("Handling Engine Post: " + str(in_data))
        # Make sure the json passed has the required elements, and they are the correct format.
        if "Command" not in in_data:
            cherrypy.log("JSON structure is missing command field")
            return {"Status": "Error", "ErrMessage": "Unknown command"}

        # Switch based on which kind of request this is...
        out_data = {"Status": "Testing!", "ErrMessage": "", "Filename": ""}
        if in_data["Command"].lower() == 'start':
            # Check to see if this model is already cached
            in_data.pop("Command")
            model, success, errtext = ModelParams.from_json(in_data)
            if not success:
                out_data["Status"] = "Error"
                out_data["ErrMessage"] = "Invalid query. %s" % errtext
                cherrypy.log("Engine Error - could not parse json. %s" % errtext)
                return out_data

            exists, path = self.engine.check_exists(model)
            if exists:
                out_data["Status"] = "Ready"
                out_data["Filename"] = path
            else:
                cherrypy.log("Generating model: " + str(in_data))
                success, errtext = self.engine.start_job(model)
                if success:
                    out_data["Status"] = "Working"
                else:
                    out_data["Status"] = "Error"
                    out_data["ErrMessage"] = errtext
                    cherrypy.log("Engine error! Job: " + str(in_data) + " Error: " + errtext)

        elif in_data["Command"].lower() == 'check':
            in_data.pop("Command")

            model, success, errtext = ModelParams.from_json(in_data)
            if not success:
                out_data["Status"] = "Error"
                out_data["ErrMessage"] = "Invalid query. %s" % errtext
                cherrypy.log("Engine Error - could not parse json. %s" % errtext)
                return out_data

            done, path, success, errtext = self.engine.check_job(model)
            out_data["Status"] = "Working"
            if done:
                out_data["Status"] = "Ready"
                cherrypy.log("Finished generating model: " + str(in_data))
            out_data["Filename"] = path
            if done and not success:
                out_data["Status"] = "Error"
                cherrypy.log("Engine error! Job: " + str(in_data) + " Error: " + errtext)
                out_data["ErrMessage"] = errtext

        elif in_data["Command"].lower() == 'submit':
            in_data.pop("Command")

            success, errtext = Model.submit_to_log(in_data, self.next_submit_id)

            if success:
                out_data["Status"] = "OK"
                out_data["Confirm"] = self.next_submit_id
            else:
                cherrypy.log("Submit Error: " + errtext)
                out_data["Status"] = "Error"
                out_data["ErrMessage"] = errtext

            self.next_submit_id += 1

        return out_data


def secureheaders():
    headers = cherrypy.response.headers
    headers['X-Frame-Options'] = 'DENY'
    headers['X-XSS-Protection'] = '1; mode=block'
    # TODO: ADD THIS BACK IN
    #headers['Content-Security-Policy'] = "default-src='self'"


def start():
    """Starts the web server"""
    cherrypy.config.namespaces['modelgen'] = modelgen.Engine.modelgen_settings
    cherrypy.config.update('server.conf')
    conf = {
        '/': {
            'tools.staticdir.root': os.path.abspath(os.getcwd()),
            'tools.secureheaders.on': True
        },
        '/engine': {
            'request.dispatch': cherrypy.dispatch.MethodDispatcher(),
            'tools.response_headers.on': True,
            'tools.response_headers.headers': [('Content-Type', 'application/json')],
            'tools.secureheaders.on': True
        },
        '/static': {
            'tools.staticdir.on': True,
            'tools.staticdir.dir': './public',
            'tools.secureheaders.on': True
        }
    }

    # set the priority according to your needs if you are hooking something
    # else on the 'before_finalize' hook point.
    cherrypy.tools.secureheaders = cherrypy.Tool('before_finalize', secureheaders, priority=60)

    # TODO: Make these values editable in server.conf
    # For now, use the default "nobody" user on the platform I'm using.
    plugins.DropPrivileges(cherrypy.engine, uid=65534, gid=65534).subscribe()
    webapp = ModelChooserWeb()
    webapp.engine = ModelChooserEngine()
    cherrypy.quickstart(webapp, '/', conf)

if __name__ == '__main__':
    start()
