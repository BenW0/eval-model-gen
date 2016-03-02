""" webserver

This module runs the web server used for interactively generating printer evaluation parts. It uses the modelgen
module to handle the actual compilation of the STL files, and relies on static content in the local <public> folder
for statically served content, as well as on files in the <template> folder for html page source loaded from python.

Executing this module starts the web server. For a more user-friendly experience, execute main.py.

"""

import random
import string

import cherrypy


class ModelChooserWeb(object):
    @cherrypy.expose
    def index(self):
        return """<html>
          <head></head>
          <body>
            <form method="get" action="generate">
              <input type="text" value="8" name="length" />
              <button type="submit">Give it now!</button>
            </form>
          </body>
        </html>"""

    @cherrypy.expose
    def generate(self, length=8):
        return ''.join(random.sample(string.hexdigits, int(length)))


def start():
    """Starts the web server"""
    cherrypy.quickstart(ModelChooserWeb())

if __name__ == '__main__':
    start()
