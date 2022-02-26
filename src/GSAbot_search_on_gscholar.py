#############################################################################
# Version 3.0.0
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
import re
import sys
import difflib

#############################################################################
# READING CONFIG FILE
#############################################################################

# General config file path
gen_file_path = sys.argv[1]

# Chat's config file path
chat_file_path = sys.argv[2]

# Reading the (general and chat) configuration file
# There is no section in the config file
# So here is a bypass found SOF
# See: https://stackoverflow.com/a/25493615
with open(gen_file_path, 'r') as f:
    gen_config_string = u'[foo]\n' + f.read()
with open(chat_file_path, 'r') as f:
    chat_config_string = u'[foo]\n' + f.read()

# Create config parser
config = configparser.ConfigParser()

# Reading Scale SERP token from general config
config.read_string(gen_config_string)
token = config['foo']['SCALESERP_TOKEN'][1:-1]

# Reading keywords from chat's config
config.read_string(chat_config_string)
keywords = config['foo']['KEYWORDS'][1:-2]
if not keywords:
  sys.exit('GSAbot: No keywords !')

# Reading last results from previous request
last = config['foo']['LAST_GSCHOLAR'][1:-2]

# Creating new results for current request
new = ''

# Creating a dummy list of titles used to filter out
# duplicates of new articles
dummy_title_list = []

# Splitting the keywords and last result
klist = keywords.split(';')
llist = last.split(';')
nlist = new.split(';')

if len(klist)>len(llist):
  llist.extend([u'']*(len(klist)-len(llist)))

nlist.extend([u'']*len(klist))

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
    'time_period': 'custom',
    'time_period_min': '01/01/1900',
    'output': 'json',
    'hl': 'en',
    'gl': 'us',
    'include_html': 'false',
    'scholar_patents_courts': '1',
    'scholar_include_citations': 'true'
  }

  # Making the http GET request to Scale SERP
  api_result = requests.get('https://api.scaleserp.com/search', params)

  # Storing the JSON response from Scale SERP
  outcome = api_result.json()

  # Check if the outcome json has any results
  if not 'scholar_results' in outcome:
    print("""\xE2\x9A\xA0 *Warning* \t the keyword *%s* is not good
             (either too restrictive, too loose or with an erroneous
             character) because I find no results on Google Scholar
             which are related to it! Please change it.\n
             ------\n""" % klist[ind] )
    nlist[ind]="None"

  # If no previous request's result then store the first one
  # No messages are sent by the bot
  elif not llist[ind]:
    nlist[ind] = outcome['scholar_results'][0]['title']

  # Else go through the ten results from the request and stop when
  # the title correspond to the last request's result
  # For every new element, the bot sends a message.
  else:
    for pos in range(10):
      # Creating the pair of elements [title,displayed link]
      pair = [outcome['scholar_results'][pos]['title'],
              outcome['scholar_results'][pos]['displayed_link'] ]

      # Formating the both elements to the right printing format
      # for Telegram
      for el in range(0,len(pair)-1):
        pair[el] = re.sub('\[.*?\]', '', pair[el])
        pair[el] = re.sub('<.*?>', '', pair[el])
        pair[el] = re.sub('\n', '', pair[el])
        pair[el] = re.sub('\u2026','',pair[el])
        pair[el] = pair[el].replace('_','\\_')
        pair[el] = re.escape(pair[el])
        pair[el] = pair[el].lstrip()
        pair[el] = pair[el][0].upper() + pair[el][1:].lower()

      # First element becomes the new 'last request'
      if pos == 0:
        nlist[ind] = pair[0]

      # Determining if new and last titles are similar
      sim_score=difflib.SequenceMatcher(a=pair[0].lower(), b=llist[ind].lower()).ratio()
      if sim_score>.8: break

      if pair[0] not in dummy_title_list:
        print('*%s*\n' % pair[0])
        print('[%s](%s)\n' % (pair[1],outcome['scholar_results'][pos]['link']) )
        print('------\n')
        dummy_title_list.append(pair[0])

#############################################################################
# WRITING CONFIG FILE
#############################################################################

new = re.escape(';'.join(nlist) + ';')
new = re.sub("'",' ',new)
os.system("sed -i \"/LAST_GSCHOLAR=/c\LAST_GSCHOLAR=\x27%s\x27\" \"%s\"" % (new,chat_file_path))

#############################################################################
# END
#############################################################################
