#!/usr/bin/python
from logging import basicConfig, getLogger, DEBUG, INFO
import sys
from SimpleHTTPServer import SimpleHTTPRequestHandler
import SocketServer
import libsaas_gitlab as gitlab
from libsaas.services import base

basicConfig(level=DEBUG)
getLogger('libsaas.executor.urllib2_executor').setLevel(INFO)
logger = getLogger(__name__)

# ---------------------------
# monkey patching to libsaas_gitlab
# ---------------------------

@base.resource(gitlab.users.UsersBase)
def user(self, user_id):
    """
    Get team user by id
    """
    return gitlab.users.UsersBase(self, user_id)

@base.resource(gitlab.users.UsersBase)
def users(self):
    """
    Get team users
    """
    return gitlab.users.UsersBase(self)

gitlab.projects.Project.user = user
gitlab.projects.Project.users = users

# ---------------------------
# Gitlab service
# ---------------------------

class GitlabService(object):
  ACCESS_LEVEL_GUEST     = 10
  ACCESS_LEVEL_REPORTER  = 20
  ACCESS_LEVEL_DEVELOPER = 30
  ACCESS_LEVEL_MASTER    = 40
  ACCESS_LEVEL_OWNER     = 50

  def __init__(self, gitlab_url, oauth2_token):
    self.service = gitlab.Gitlab(gitlab_url, None, oauth_token=oauth2_token)

  def find_project(self, project_id):
    return self.service.project(project_id).get()

  def get_access_level(self, project):
    levels = map(lambda key:
      (project['permissions'].get(key, None) or {}).get('access_level', None),
      ['group_access', 'project_access'])
    return min([x for x in levels if x is not None])

  def find_user(self, project_id, username):
    users = self.service.project(project_id).users().get({'search': username})
    # search query matches partial. needs to get by strict username
    return next(iter(filter(lambda u: u['username'] == username, users)), None)


# ---------------------------
# web app
# ---------------------------

class AuthedHandler(SimpleHTTPRequestHandler):
  def do_FORBIDDEN(self, message = ''):
    self.send_response(403, "forbidden")
    self.send_header('Content-type', 'text/html')
    self.send_header('Content-Length', len(message))
    self.end_headers()
    self.wfile.write(message)
    self.wfile.close()

  #Handler for the GET requests
  def do_GET(self):
    logger.info("Request Headers: %s", self.headers)
    token = self.headers['X-Forwarded-Access-Token']
    email = self.headers['X-Forwarded-Email']
    logger.debug("email: %s, token: %s", email, token)

    project_id = self.project_id()
    if project_id is None:
      self.do_FORBIDDEN(
          "Access Denied. project_id does not contain in URL")
      return

    if not self.allows_access(token, project_id):
      self.do_FORBIDDEN(
          "Access Denied. project: %s, user: %s" % (project_id, email))
      return

    return SimpleHTTPRequestHandler.do_GET(self)

  def project_id(self):
    # required url format is '/any-string/PROJECT_ID/any-atring...'
    paths = self.path.split('?', 2)[0].split('/')
    return paths[2] if len(paths) >= 3 else None

  def allows_access(self, token, project_id):
    service = GitlabService(GITLAB_SERVER, token)
    project = service.find_project(project_id)
    access_level = service.get_access_level(project)
    logger.debug("access level in project %s: %d", project_id, access_level)
    return access_level >= GitlabService.ACCESS_LEVEL_REPORTER

def main(port):

  try:
    SocketServer.TCPServer.allow_reuse_address = True
    server = SocketServer.TCPServer(('', port), AuthedHandler)
    logger.info('Started httpserver on port %d', port)

    server.serve_forever()

  except KeyboardInterrupt:
    logger.info('^C received, shutting down the web server')
    server.socket.close()

if __name__ == '__main__':
  if (len(sys.argv) < 3):
    print 'Usage: # python %s PORT GITLAB_URL' % sys.argv[0]
    quit()

  PORT_NUMBER = int(sys.argv[1], 10)
  GITLAB_SERVER = sys.argv[2]

  main(PORT_NUMBER)

