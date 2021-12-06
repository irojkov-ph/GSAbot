#############################################################################
# Version 2.0.0
#############################################################################

#############################################################################
# Licensed under GNU GPLv3
#
# See https://opensource.org/licenses/GPL-3.0
#
# Contact:
# > e-mail      irojkov@ethz.ch
# > GitHub      irojkov-ph
#############################################################################

#############################################################################
# IMPORTS
#############################################################################

import requests
import json
import configparser
import os
import subprocess
import re
import sys
import difflib

#############################################################################
# READING CONFIG FILE
#############################################################################

# Determining $HOME directory
home = os.path.expanduser("~")

# Reading the configuration file
# There is no section in the config file
# So here is a bypass found SOF
# See: https://stackoverflow.com/a/25493615
with open(home+'/.GSAbot/GSAbot.conf', 'r') as f:
    config_string = u'[foo]\n' + f.read()
config = configparser.ConfigParser()
config.read_string(config_string)

# Reading Scale SERP token
token = config['foo']['SCALESERP_TOKEN'][1:-1]

# Reading keywords
keywords = config['foo']['KEYWORDS'][1:-2]
if not keywords:
  sys.exit('GSAbot: No keywords !')

# Reading last results from previous request
last = config['foo']['LAST_GSCHOLAR'][1:-2]

# Creating new results for current request
new = ''

# Splitting the keywords and last result
klist = keywords.split(';')
llist = last.split(';')
nlist = new.split(';')

if len(klist)>len(llist):
  llist.extend([u'']*(len(klist)-len(llist)))
elif len(klist)<len(llist):
  llist = llist[:len(llist)-len(klist)-1]

nlist.extend([u'']*(len(klist)-len(nlist)))

#############################################################################
# SENDING REQUESTS
#############################################################################

for ind in range(len(klist)):
  # Setting up the request parameters
  params = {
    'api_key': token,
    'q': klist[ind],
    'search_type': 'scholar',
    'sort_by': 'date',
    'time_period': 'last_year',
    'output': 'json',
    'hl': 'en',
    'gl': 'us',
    'scholar_patents_courts': '1',
    'scholar_include_citations': 'true'
  }

  # Making the http GET request to Scale SERP
  api_result = requests.get('https://api.scaleserp.com/search', params)

  # Storing the JSON response from Scale SERP
  outcome = api_result.json()
  
  # If not previous request's result then store the first one
  # No messages are sent by the bot
  if not llist[ind]:
    nlist[ind] = outcome['scholar_results'][0]['title']

  # Else go through the ten results from the request and stop when
  # the title correspond to the last request's result
  # For every new element, the bot sends a message.
  else:
    for pos in range(10):
      title = outcome['scholar_results'][pos]['title']

      # First element becomes the new 'last request'
      if pos == 0:
        nlist[ind] = title

      # Determining if new and last titles are similar
      sim_score=difflib.SequenceMatcher(a=title.lower(), b=llist[ind].lower()).ratio()
      if sim_score>.8: break

      title = re.sub('\[.*?\]', '', title)
      title = re.sub('<.*?>', '', title)
      title = re.sub('\n', '', title)
      title = re.sub('\u2026','',title)
      title = title.replace('_','\\_')
      title = re.escape(title)
      title = title.lstrip()
      title = title[0].upper() + title[1:].lower()

      print('*%s*\n' % title)
      print('[link](%s)\n' % outcome['scholar_results'][pos]['link'])
      print('------\n')

#############################################################################
# WRITING CONFIG FILE
#############################################################################

new = re.escape(';'.join(nlist) + ';')
new = re.sub("'",' ',new)
os.system("sed -i \"/LAST_GSCHOLAR=/c\LAST_GSCHOLAR=\x27%s\x27\" \"$HOME/.GSAbot/GSAbot.conf\"" % (new))

#############################################################################
# END
#############################################################################