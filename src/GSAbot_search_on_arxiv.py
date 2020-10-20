#############################################################################
# Version 1.0.0 (20-10-2019)
#############################################################################

#############################################################################
# Licenced under GNU GPLv3
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

# Reading keywords
keywords = config['foo']['KEYWORDS'][1:-2]
if not keywords:
  sys.exit('GSAbot: No keywords !')

# Reading last results from previous request
last = config['foo']['LAST_ARXIV'][1:-2]

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
  # Constructing the query with the keyword
  query = klist[ind].split(' ')
  query = ["ti:" + x for x in query]
  query = ' AND '.join(query)

  # Maximum number of results to retrieve
  max_results = 10

  # Sending the query
  outcome = arxiv.query(query=query,
                       max_results=max_results,
                       sort_by="lastUpdatedDate",
                       max_chunk_results=1,
                       iterative=False)

  # Check if the outcome is empty, if yes send a warning !
  if not outcome:
    print('\xE2\x9A\xA0 *Warning* \t the keyword *%s* is not good ' % klist)
    print('(either too restrictive or too loose) because I find no results on arXiv ')
    print('which are related to it ! Please change it.\n')
    print('------\n')

  # If not previous request's result then store the first one
  # No messages are sent by the bot
  elif not llist[ind]:
    nlist[ind] = outcome[0].title

  # Else go through the ten results from the request and stop when
  # the title correspond to the last request's result
  # For every new element, the bot sends a message.
  else:
    for pos in range(len(outcome)):
      title = outcome[pos].title
      # Determining if new and last titles are similar
      sim_score=difflib.SequenceMatcher(a=title.lower(), b=llist[ind].lower()).ratio()
      if sim_score>.9: break

      # First element becomes the new 'last request'
      if pos == 0:
        nlist[ind] = title

      title = re.sub('\[.*?\]', '', title)
      title = re.sub('<.*?>', '', title)
      title = re.sub('\n', '', title)
      title = title.replace('_','\\_')
      title = re.escape(title)
      title = title.lstrip()
      title = title[0].upper() + title[1:].lower()

      print('*%s*\n' % title)
      print('_Last Update:_ %s \t _Published:_ %s\n' % (outcome[pos].updated[0:10],outcome[pos].published[0:10]))
      print('%s\n' % outcome[pos].arxiv_url)
      print('------\n')

#############################################################################
# WRITING CONFIG FILE
#############################################################################

new = re.escape(';'.join(nlist) + ';')
last = re.escape(last + ';')
os.system('sed -i "s/LAST_ARXIV=\'%s\'/LAST_ARXIV=\'%s\'/" "$HOME/.GSAbot/GSAbot.conf"' % (last,new))

#############################################################################
# END
#############################################################################