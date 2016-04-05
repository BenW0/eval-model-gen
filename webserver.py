""" webserver

This module runs the web server used for interactively generating printer evaluation parts. It uses the modelgen
module to handle the actual compilation of the STL files, and relies on static content in the local <public> folder
for statically served content, as well as on files in the <template> folder for html page source loaded from python.

Executing this module starts the web server. For a more user-friendly experience, execute main.py.

A note on sessions:
  This webapp doesn't use sessions. Instead, the "session" is entirely based on the state of the selection variables.
  So, effectively, the "session id" is the json describing the test part being used.

"""

import os
import cherrypy
from cherrypy.lib.static import serve_file
from cherrypy.process import plugins
from modelparams import ModelParams as mp
import modelgen


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
    def getmodel(self, name, mask=True):
        """ Return a model file for download in response to a user's request.
        name is filtered for some basic very basic security, but this maybe should be re-thought later.
        :param name: Name of model file. This is the name of a file
        :param mask: Boolean specifying whether to mask the name of the actual file with "Test Part.stl"
        :return: File server serving the file specified (if it exists)
        """
        new_name = name.replace('/', '').replace('\\', '').replace('..', '')
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


    @cherrypy.tools.json_in()
    @cherrypy.tools.json_out()
    def POST(self):
        in_data = cherrypy.request.json
        cherrypy.log("Handling Engine Post: " + str(in_data))
        # Make sure the json passed has the required elements, and they are the correct format.
        if not all(map(in_data.has_key, mp.JSON_FIELDS)):
            cherrypy.log("JSON structure is missing a required field!")
            return {"Status": "Error", "ErrMessage": "Missing JSON Field"}
        if "Command" not in in_data:
            cherrypy.log("JSON structure is missing command field")
            return {"Status": "Error", "ErrMessage": "Unknown command"}
        if not all(map(lambda key : self.is_numberlike(in_data[key]), mp.JSON_FIELDS)):
            cherrypy.log("JSON structure contains non-numeric data.")
            return {"Status": "Error", "ErrMessage": "Non-numeric input"}

        # Switch based on which kind of request this is...
        out_data = {"Status": "Testing!", "ErrMessage": "", "Filename": ""}
        if in_data["Command"].lower() == 'start':
            # Check to see if this model is already cached
            model = mp.from_json(in_data)
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
            model = mp.from_json(in_data)
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
    plugins.DropPrivileges(cherrypy.engine, uid=99, gid=99).subscribe()
    webapp = ModelChooserWeb()
    webapp.engine = ModelChooserEngine()
    cherrypy.quickstart(webapp, '/', conf)

if __name__ == '__main__':
    start()
