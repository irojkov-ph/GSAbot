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

# Splitting the keywords and last result
klist = keywords.split(';')
llist = last.split(';')

if len(klist)>len(llist):
  num_new_keywords = len(klist)-len(llist)
else:
  num_new_keywords = 0

#############################################################################
# SENDING REQUESTS
#############################################################################

for ind in range(len(llist)):
  # Setting up the request parameters
  # Carreful we now search by last result titles rather than keywords
  # could cause errors
  params = {
    'api_key': token,
    'q': llist[ind],
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

  # If we don't find any article send warning
  if not 'scholar_results' in outcome:
    print(' - For _%s_:\n' % klist[ind])
    print("The last article name was *%s* but I can't find on Google Scholar right now." % llist[ind])
    print('------\n')
    continue

  # Creating the pair of elements [title,displayed link]
  pair = [outcome['scholar_results'][0]['title'],
          outcome['scholar_results'][0]['displayed_link'] ]

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

  print(' - For _%s_:\n' % klist[ind])
  print('*%s*\n' % pair[0])
  print('[%s](%s)\n' % (pair[1],outcome['scholar_results'][0]['link']) )
  print('------\n')

if num_new_keywords:
  print(' - There are also _%i_ new keyword(s) that have ' % num_new_keywords)
  print("   not been checked on Google Scholar yet.\n ")
  print('------\n')

#############################################################################
# END
#############################################################################
