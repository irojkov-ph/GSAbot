#############################################################################
# Version 1.0.0
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
# Requirements
#############################################################################
require 'telegram/bot'
require 'parseconfig'

#############################################################################
# CONFIG VARIABLES
#############################################################################
config_file = [Dir.home,'/.GSAbot/GSAbot.conf'].join
config = ParseConfig.new(config_file)
token = config['TELEGRAM_TOKEN']
chat_id = config['TELEGRAM_CHAT']

#############################################################################
# MAIN LOOP (LISTEN FOR COMMANDS)
#############################################################################
just_started = 1
to_exit = 0

Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|

    if (chat_id.nil? || chat_id.empty?)
      chat = message.chat_id
    end
  
    puts "@#{message.from.username}: #{message.text}"
    
    splitted_txt = message.text.split
    command      = splitted_txt.shift
    arguments    = splitted_txt
    
    if arguments.length > 1 and not ["/add","/remove","/cron"].include?(command)
      reply = "\xE2\x9A\xA0 *Warning* I don't know what to do, please specify only one argument !"
    else
      case command
        when /start/i
          cmd = "GSAbot --start #{message.chat.id}"
          tmp = `#{cmd}`
          reply = "Hi #{message.from.first_name},  nice to meet you ! "\
                      "I am GSAbot 🤖 \nI can send you alerts when new papers, "\
                      "articles, books, etc. related to *your* favourite "\
                      "keywords are published on Google Scholar. \nBtw the id of "\
                      "this chat is #{message.chat.id}.\n"\
                      "Send /help so see what kind of commands I understand !"
        when /help/i
          cmd = "GSAbot --commands"
          reply = `#{cmd}`
        when /version/i
          cmd = "GSAbot --version"
          reply = `#{cmd}`
        when /status/i
          cmd = "GSAbot --status"
          reply = `#{cmd}`
        when /alert/i
            cmd = ["GSAbot --alert",arguments].join(' ')
            reply = `#{cmd}`
        when /add/i
          cmd = ["GSAbot --add '",arguments,"' "].join(' ')
          reply = `#{cmd}`
        when /remove/i
          cmd = ["GSAbot --remove '",arguments,"' "].join(' ')
          reply = `#{cmd}`
        when /list/i
          cmd = "GSAbot --list"
          reply = `#{cmd}`
        when /cron/i
          cmd = ["GSAbot --cron '",arguments,"' "].join(' ')
          reply = `#{cmd}`
        when /check_gscholar/i
          cmd = "GSAbot --check gscholar"
          tmp = `#{cmd}`
          reply = "I've just checked Google Scholar, if nothing appeared "\
                      "that means no new articles were published since the last check.\n"\
                      'Try out "*/check_arxiv*" for checking arXiv !'
        when /check_arxiv/i
          cmd = "GSAbot --check arxiv"
          tmp = `#{cmd}`
          reply = "I've just checked arXiv, if nothing appeared "\
                      "that means no new articles were published since the last check.\n"\
                      'Try out "*/check_gscholar*" for checking Google Scholar !'
        when /check_updates/i
          cmd = "GSAbot --check_updates"
          reply = `#{cmd}`
        when /stop/i
          # set exit flags
          if just_started != 1
            reply = "GSAbot is stopped ! To restart it run 'ruby GSAbot.rb' on the server."
            to_exit = 1
          else
            reply = "Thank you for reviving me ! I'll try to not deceive you this time."
          end  
        else
          list_forbidden_char = [ '*', '[', ']', '(', ')', '~', '`',\
                                  '>', '#', '+', '-', '=', '|', '{',\
                                  '}', '.', '!', '_' ]
          command_new = command
          for el in list_forbidden_char
            if command_new.include?(el)
              command_new = command_new.gsub! el, "\\#{el}"
            end
          end

          reply = "I have no idea what #{command_new} means."
      end
      
      # send the message
      # puts "sending #{reply.text.inspect} to @#{message.from.username}"
      bot.api.send_message( chat_id: message.chat.id, \
                            text: reply, \
                            parse_mode: 'MarkDown' \
                          )
      # exit if exit flag was set
      if to_exit==1
        exit
      end
      
    end

    just_started = 0
  end
end

#############################################################################
# END
#############################################################################