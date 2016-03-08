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
    def generate(self, length=8):
        return ''


class ModelChooserEngine(object):
    exposed = True

    @cherrypy.tools.json_in()
    @cherrypy.tools.json_out()
    def POST(self):
        data = cherrypy.request.json
        # Make sure the json passed has the required elements, and they are the correct format.
        if not all(map(data.has_key, mp.JSON_FIELDS)):
            cherrypy.log("JSON structure is missing a required field!")
            return {"Status": "Error"}
        if not all(map(lambda key : type(data[key]) is float or type(data[key]) is int, mp.JSON_FIELDS)):
            cherrypy.log("JSON structure contains non-numeric data.")
            return {"Status": "Error"}
        cherrypy.log("Generating model: " + str(data))

        return {"Status": "Testing!"}


def start():
    """Starts the web server"""
    cherrypy.config.update({'server.socket_port': 8081})
    conf = {
        '/': {
            'tools.staticdir.root': os.path.abspath(os.getcwd())
        },
        '/engine': {
            'request.dispatch': cherrypy.dispatch.MethodDispatcher(),
            'tools.response_headers.on': True,
            'tools.response_headers.headers': [('Content-Type', 'text/plain')]
        },
        '/static': {
            'tools.staticdir.on': True,
            'tools.staticdir.dir': './public'
        }
    }

    webapp = ModelChooserWeb()
    webapp.engine = ModelChooserEngine()
    cherrypy.quickstart(webapp, '/', conf)

if __name__ == '__main__':
    start()
