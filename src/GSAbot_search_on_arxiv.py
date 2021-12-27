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
  query = re.sub("-",' ',klist[ind]).split(' ')
  query_title    = ["ti:" + x for x in query]
  query_abstract = ["abs:" + x for x in query]
  query = '(' + ' AND '.join(query_title) \
        + ') OR ('+ ' AND '.join(query_abstract) \
        + ')'

  # Maximum number of results to retrieve
  max_results = 20

  # Sending the query
  outcome = arxiv.Search(query=query,
                        max_results=max_results,
                        sort_by=arxiv.SortCriterion.LastUpdatedDate)

  # Check if the outcome is empty, if yes send a warning !
  if not outcome:
    print("""\xE2\x9A\xA0 *Warning* \t the keyword *%s* is not good )
             (either too restrictive, too loose or with an erroneous character)
             because I find no results on arXiv
             which are related to it ! Please change it.\n
             ------\n""" % klist[ind] )

  # If not previous request's result then store the first one
  # No messages are sent by the bot
  elif not llist[ind]:
    nlist[ind] = outcome[0].title

  # Else go through the ten results from the request and stop when
  # the title correspond to the last request's result
  # For every new element, the bot sends a message.
  else:

    pos=0

    for out in outcome.results():
    #for pos in range(len(outcome)):
      title = out.title

      # First element becomes the new 'last request'
      if pos == 0:
        nlist[ind] = title
        pos += 1

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
      print('_Last Update:_ %s \t _Published:_ %s\n' % (out.updated.date(),out.published.date()))
      print('%s\n' % out.entry_id)
      print('------\n')

#############################################################################
# WRITING CONFIG FILE
#############################################################################

new = re.escape(';'.join(nlist) + ';')
new = re.sub("'",' ',new)
os.system('sed -i "/LAST_ARXIV=/c\LAST_ARXIV=\x27%s\x27" "$HOME/.GSAbot/GSAbot.conf"' % (new))

#############################################################################
# END
#############################################################################
