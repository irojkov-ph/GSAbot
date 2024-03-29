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
# Requirements
#############################################################################
require 'telegram/bot'
require 'parseconfig'

#############################################################################
# CONFIG VARIABLES
#############################################################################
config_file = "#{__dir__}/GSAbot.conf"
config = ParseConfig.new(config_file)
token = config['TELEGRAM_TOKEN']
admin = config['GSAbot_SERVER_ADMIN']

#############################################################################
# USEFUL FUNCTION
#############################################################################

def displaystyle (string)
  list_forbidden_char = [ '*', '[', ']', '(', ')', '~', '`',\
                          '>', '#', '+', '-', '=', '|', '{',\
                          '}', '.', '!', '_' ]
  
  new_string = string.clone
  for el in list_forbidden_char
    if new_string.include?(el)
      new_string = new_string.gsub! el, "\\#{el}"
    end
  end

  return new_string
end

#############################################################################
# MAIN LOOP (LISTEN FOR COMMANDS)
#############################################################################
just_started = 1
to_exit = 0

Telegram::Bot::Client.run(token) do |bot|
  begin
    bot.listen do |message|

      time = Time.now
      puts time.inspect + " @#{message.from.username} "\
           "in #{message.chat.id} : #{message.text}"
      
      chat = message.chat.id
      
      splitted_txt  = message.text.split
      command       = splitted_txt.shift 
      arguments     = splitted_txt      

      if arguments.length > 1 and not ["/add","/remove","/cron"].include?(command)
        reply = "\xE2\x9A\xA0 *Warning*\nI don't know what to do, "\
                "please specify the number of argument(s)!"
      else
        case command
          when /start/i
            cmd = "GSAbot --start #{chat}"
            tmp = `#{cmd}`
            reply = "Hi #{message.from.first_name},  nice to meet you! "\
                    "I am GSAbot 🤖 \nI can send you alerts when new papers, "\
                    "articles, books, etc. related to *your* favourite "\
                    "keywords are released on Google Scholar/arXiv.\n"\
                    "Btw the id of this chat is #{chat}.\n"\
                    "#{tmp}"\
                    "Send /help so see what kind of commands I understand!"
          when /help/i
            cmd = "GSAbot --commands"
            reply = `#{cmd}`
          when /version/i
            cmd = "GSAbot --version"
            reply = `#{cmd}`
          when /status/i
            cmd = "GSAbot --chat_id #{chat} --status"
            reply = `#{cmd}`
          when /alert/i
              cmd = ["GSAbot --chat_id #{chat} --alert",arguments].join(' ')
              reply = `#{cmd}`
          when /add/i
            cmd = ["GSAbot --chat_id #{chat} --add '",arguments,"' "].join(' ')
            reply = `#{cmd}`
            Process.spawn("GSAbot --chat_id #{chat} --check both")
          when /remove/i
            cmd = ["GSAbot --chat_id #{chat} --remove '",arguments,"' "].join(' ')
            reply = `#{cmd}`
            Process.spawn("GSAbot --chat_id #{chat} --check both")
          when /list/i
            cmd = "GSAbot --chat_id #{chat} --list"
            reply = `#{cmd}`
          when /cron/i
            arg = displaystyle arguments.join(' ')
            cmd = ["GSAbot --chat_id #{chat} --cron",arg," "].join(' ')
            reply = `#{cmd}`
          when /check_gscholar/i
            cmd = "GSAbot --chat_id #{chat} --check gscholar"
            tmp = `#{cmd}`
            reply = "I've just checked Google Scholar, if nothing appeared "\
                    "that means no new elements were released since the last check.\n"\
                    'Try out "*/check_arxiv*" for checking arXiv!'
          when /check_arxiv/i
            cmd = "GSAbot --chat_id #{chat} --check arxiv"
            tmp = `#{cmd}`
            reply = "I've just checked arXiv, if nothing appeared "\
                    "that means no new elements were released since the last check.\n"\
                    'Try out "*/check_gscholar*" for checking Google Scholar!'
          when /last_gscholar/i
            cmd = "GSAbot --chat_id #{chat} --last gscholar"
            tmp = `#{cmd}`
            reply = 'Try out "*/last_arxiv*" to see what are the last arXiv '\
                    'elements that I have in memory for every keyword.'
          when /last_arxiv/i
            cmd = "GSAbot --chat_id #{chat} --last arxiv"
            tmp = `#{cmd}`
            reply = 'Try out "*/last_gscholar*" to see what are the last Google Scholar '\
                    'elements that I have in memory for every keyword.'
          when /check_updates/i
            cmd = "GSAbot --chat_id #{chat} --check_updates"
            reply = `#{cmd}`
          when /stop/i
            # set exit flags
            if message.from.username == admin && just_started != 1
              reply = "GSAbot is stopped! To restart it run: "\
                      "\`GSAbot --start_bot\`"
              to_exit = 1
            elsif message.from.username != admin && just_started != 1
                reply = "\xE2\x9A\xA0 *Warning* \n"\
                        "You are not the admin user of the server "\
                        "where the bot is running, thus you cannot "\
                        "stop it."
                to_exit = 1
            else
              reply = "Thank you for reviving me! "\
                      "I'll try to not deceive you this time."
            end  
          else
            cmd_disp = displaystyle command
            reply = "I have no idea what #{cmd_disp} means."
        end
      end

      # send the message
      bot.api.send_message( chat_id: chat, \
                            text: reply, \
                            parse_mode: 'MarkDown' \
                          )

      # exit if exit flag was set
      if to_exit==1
        exit
      end

      just_started = 0
    end
  rescue Faraday::ConnectionFailed
    time = Time.now
    puts time.inspect + " Rescued 'Connection Failed': check the server's internet connection retry in 60s."
    sleep(60)
    retry
  rescue StandardError => e
    time = Time.now
    puts time.inspect + " Rescued: #{e.message}"
    puts "Cause: #{e.cause}"
    puts "Backtrace: #{e.backtrace}"
    retry
  end
end

#############################################################################
# END
#############################################################################
