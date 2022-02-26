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

import arxiv
import configparser
import os
import re
import sys
import difflib

def shorten_name(fullname):
  lst = fullname.split()
  shortname = ""
  for i in range(len(lst)-1):
    str1 = lst[i]
    shortname += (str1[0].upper()+'.')
  shortname += lst[-1].title()
  return shortname 

#############################################################################
# READING CONFIG FILE
#############################################################################

# Determining $HOME directory
file_path = sys.argv[1]

# Reading the configuration file
# There is no section in the config file
# So here is a bypass found SOF
# See: https://stackoverflow.com/a/25493615
with open(file_path, 'r') as f:
    config_string = u'[foo]\n' + f.read()
config = configparser.ConfigParser()
config.read_string(config_string)

# Reading keywords
keywords = config['foo']['KEYWORDS'][1:-2]
if not keywords:
  sys.exit('GSAbot: No keywords !')

# Reading last results from previous request
last = config['foo']['LAST_ARXIV'][1:-2]

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
  # Sending the query
  outcome = arxiv.Search(query=llist[ind],
                         max_results=1)
  out = next(outcome.results())

  # If we don't find any article send warning
  if not any(outcome.results()):
    print(' - For _%s_:\n' % klist[ind])
    print("The last article name was *%s* but I can't find on arXiv right now." % llist[ind])
    print('------\n')

  # Grab the title of the article
  title = out.title

  title = re.sub('\[.*?\]', '', title)
  title = re.sub('<.*?>', '', title)
  title = re.sub('\n', '', title)
  title = re.sub('\u2026','',title)
  title = title.replace('_','\\_')
  title = re.escape(title)
  title = title.lstrip()
  title = title[0].upper() + title[1:].lower()

  authors = [shorten_name(x.name) for x in out.authors]
  authors = ', '.join(authors)

  # Print the article name and other information
  print(' - For _%s_:\n' % klist[ind])
  print('*%s*\n' % title)
  print('%s\n' % authors)
  print('_Last Update:_ %s \t _Published:_ %s\n' % (out.updated.date(),out.published.date()))
  print('%s\n' % out.entry_id)
  print('------\n')
   
if num_new_keywords:
  print(' - There are also _%i_ new keyword(s) that have ' % num_new_keywords)
  print("   not been checked on arXiv yet.\n ")
  print('------\n')

#############################################################################
# END
#############################################################################
