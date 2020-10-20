#############################################################################
# Version 1.1.0 (20-10-2019)
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
require 'telegram_bot'
require 'parseconfig'

#############################################################################
# CONFIG VARIABLES
#############################################################################
config_file = [Dir.home,'/.GSAbot/GSAbot.conf'].join
config = ParseConfig.new(config_file)
token = config['TELEGRAM_TOKEN']
chat_id = config['TELEGRAM_CHAT']

#############################################################################
# BOT
#############################################################################
bot = TelegramBot.new(token: token)
if not (chat_id.nil? || chat_id.empty?)
  chat = TelegramBot::Channel.new(id: chat_id)
else
  chat = ''
end

#############################################################################
# MAIN LOOP (LISTEN FOR COMMANDS)
#############################################################################
just_started = 1
to_exit = 0

bot.get_updates(fail_silently: true) do |message|
  
  puts "@#{message.from.username}: #{message.text}"
  
  splitted_txt = message.get_command_for(bot).split
  command      = splitted_txt.shift
  arguments    = splitted_txt

  message.reply do |reply|
    if arguments.length > 1 and not ["/add","/remove","/cron"].include?(command)
      reply.text = "\xE2\x9A\xA0 *Warning* I don't know what to do, please specify only one argument !"
    else
      case command
        when /start/i
          cmd = "./GSAbot.sh --start #{message.chat.id}"
          tmp = `#{cmd}`
          reply.text = "Hi #{message.from.first_name},  nice to meet you ! "\
                       "I am GSAbot 🤖 \nI can send you alerts when new papers, "\
                       "articles, books, etc. related to *your* favourite "\
                       "keywords are published on Google Scholar. \nBtw the id of "\
                       "this chat is #{message.chat.id}.\n"\
                       "Send /help so see what kind of commands I understand !"
        when /help/i
          cmd = "./GSAbot.sh --commands"
          reply.text = `#{cmd}`
        when /version/i
          cmd = "./GSAbot.sh --version"
          reply.text = `#{cmd}`
        when /status/i
          cmd = "./GSAbot.sh --status"
          reply.text = `#{cmd}`
        when /alert/i
            cmd = ["./GSAbot.sh --alert",arguments].join(' ')
            reply.text = `#{cmd}`
        when /add/i
          cmd = ["./GSAbot.sh --add '",arguments,"' "].join(' ')
          reply.text = `#{cmd}`
        when /remove/i
          cmd = ["./GSAbot.sh --remove '",arguments,"' "].join(' ')
          reply.text = `#{cmd}`
        when /list/i
          cmd = "./GSAbot.sh --list"
          reply.text = `#{cmd}`
        when /cron/i
          cmd = ["./GSAbot.sh --cron '",arguments,"' "].join(' ')
          reply.text = `#{cmd}`
        when /check_gscholar/i
          cmd = "./GSAbot.sh --check gscholar"
          tmp = `#{cmd}`
          reply.text = "I've just checked Google Scholar, if nothing appeared "\
                       "that means no new articles were published since the last check.\n"\
                       'Try out "*/check_arxiv*" for checking arXiv !'
        when /check_arxiv/i
          cmd = "./GSAbot.sh --check arxiv"
          tmp = `#{cmd}`
          reply.text = "I've just checked arXiv, if nothing appeared "\
                       "that means no new articles were published since the last check.\n"\
                       'Try out "*/check_gscholar*" for checking Google Scholar !'
        when /check_updates/i
          cmd = "./GSAbot.sh --check_updates"
          reply.text = `#{cmd}`
        when /stop/i
          # set exit flags
          if just_started != 1
            reply.text = "GSAbot is stopped ! To restart it run 'ruby GSAbot.rb' on the server."
            to_exit = 1
          else
            reply.text = "Thank you for reviving me ! I'll try to not deceive you this time."
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

          reply.text = "I have no idea what #{command_new} means."
      end
    end
    
    # Chosing the parse mode for the message to send
    reply.parse_mode = 'MarkDown'

    # send the message
    # puts "sending #{reply.text.inspect} to @#{message.from.username}"
    reply.send_with(bot)

    # exit if exit flag was set
    if to_exit==1
      exit
    end
    
  end

  just_started = 0
end

#############################################################################
# END
#############################################################################