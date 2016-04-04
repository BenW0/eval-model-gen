########################################## Eval Models #########################
#
# A tool for iteratively qualifying the capabilities of a 3D printing platform.
#
# (c) 2016 Ben Weiss, University of Washington
# Not currently licensed. Internal use/development only.
#
###############################################################################

# This wrapper module just starts the webserver and opens the appropriate page in the user's browser

import webserver
import webbrowser


webbrowser.open("http://127.0.0.1:8081/index")
webserver.start()