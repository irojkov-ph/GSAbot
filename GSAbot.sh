#!/bin/bash

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
# VARIABLES
#############################################################################

# GSAbot version
GSAbot_VERSION='3.0.0'
GSAbot_PATH="/etc/GSAbot"
CRON_PATH="/etc/cron.d"

# check whether GSAbot.conf is available and source it
if [ -f $GSAbot_PATH/GSAbot.conf ]; then
    source $GSAbot_PATH/GSAbot.conf
else
    # Options which require GSAbot.conf
    # will not work if a chat id hasn't been specified
    GSAbot_CONFIG='disabled'

    # and default to stable branch
    GSAbot_BRANCH='v3.beta'
fi

#############################################################################
# ARGUMENTS
#############################################################################

# save amount of arguments for validity check
ARGUMENTS="${#}"

# enable help, version and a cli option
while test -n "$1"; do
    case "$1" in
        
        --chat_id)
            ARGUMENT_CHAT_ID='1'
            OPTION_CHAT_ID="$2"
            shift
            shift
            ;;

        --start)
            ARGUMENT_START='1'
            OPTION_START="$2"
            shift
            shift
            ;;

        --help|-help|help|--h|-h)
            ARGUMENT_HELP='1'
            shift
            ;;

        --commands|--cmd|-cmd)
            ARGUMENT_COMMANDS='1'
            shift
            ;;

        --version|-version|version|--v|-v)
            ARGUMENT_VERSION='1'
            shift
            ;;

        --status)
            ARGUMENT_STATUS='1'
            shift
            ;;

        --alert)
            ARGUMENT_ALERT='1'
            OPTION_ALERT="$2"
            shift
            shift
            ;;

        --add|-a)
            ARGUMENT_ADD='1'
            OPTION_ADD="$2"
            shift
            shift
            ;;

        --remove|-rm)
            ARGUMENT_REMOVE='1'
            OPTION_REMOVE="$2"
            shift
            shift
            ;;

        --list|-l)
            ARGUMENT_LIST='1'
            shift
            ;;

        --cron)
            ARGUMENT_CRON='1'
            OPTION_CRON="$2"
            shift
            shift
            ;;

        --check)
            ARGUMENT_CHECK='1'
            OPTION_CHECK="$2"
            shift
            shift
            ;;

        --check_updates)
            ARGUMENT_UPDATES='1'
            shift
            ;;

        --install)
            ARGUMENT_INSTALL='1'
            shift
            ;;

        --which_config)
            ARGUMENT_WHICH='1'
            shift
            ;;

        --start_bot)
            ARGUMENT_START_BOT='1'
            OPTION_TELEGRAM_TOKEN="$2"
            OPTION_SCALESERP_TOKEN="$3"
            shift
            shift
            shift
            ;;

        --upgrade)
            ARGUMENT_UPGRADE='1'
            shift
            ;;

        --silent-upgrade)
            ARGUMENT_SILENT_UPGRADE='1'
            shift
            ;;

        --self-upgrade)
            ARGUMENT_SELF_UPGRADE='1'
            shift
            ;;

        --uninstall)
            ARGUMENT_UNINSTALL='1'
            shift
            ;;

        # other
        *)
            ARGUMENT_NONE='1'
            shift
            ;;
    esac
done

#############################################################################
# ERROR FUNCTIONS
#############################################################################

function error_invalid_option {
    printf "\xE2\x9A\xA0 *Warning* You specified invalid arguments\n"
    printf 'Send "*/help*" for a list of valid arguments.\n'
    exit 1
}

function error_wrong_amount_of_arguments {
    printf '\xE2\x9A\xA0 *Warning* You did not specify enough arguments\n'
    printf 'Send "*/help*" for a list of valid arguments.\n'
    exit 1
}

function error_not_available {
    printf '\xE2\x9A\xA0 *Warning* Make sure that the configuration'
    printf 'file is present on server and is at the right location.\n'
    exit 1
}

function error_type_yes_or_no {
    echo "GSAbot: type yes or no and press enter to continue.\n"
}

function error_os_not_supported {
    echo 'GSAbot: operating system is not supported.\n'
    exit 1
}

function error_no_root_privileges {
    echo 'GSAbot: you need to be root to perform this command'
    echo "use 'sudo GSAbot', 'sudo -s' or run GSAbot as root user.\n"
    exit 1
}

function error_no_internet_connection {
    echo 'GSAbot: access to the internet is required.\n'
    exit 1
}

#############################################################################
# REQUIREMENT FUNCTIONS
#############################################################################

function requirement_argument_validity {

    # --chat_id specified but no more argument
    if [ "${ARGUMENT_CHAT_ID}" == '1' ] && [ -z "${OPTION_CHAT_ID}" ]; then
        error_invalid_option
    # --start specified but no more argument
    elif [ "${ARGUMENT_START}" == '1' ] && [ -z "${OPTION_START}" ]; then
        error_invalid_option
    # /alert specified but no more argument
    elif [ "${ARGUMENT_ALERT}" == '1' ] && [ -z "${OPTION_ALERT}" ]; then
        error_invalid_option
    # /alert specified but the next argument is not 'on' nor 'off'
    elif [ "${ARGUMENT_ALERT}" == '1' ] && [ "${OPTION_ALERT}" != 'on' ] && [ "${OPTION_ALERT}" != 'off' ]; then
        error_invalid_option
    # /add specified but no more argument
    elif [ "${ARGUMENT_ADD}" == '1' ] && [ -z "${OPTION_ADD}" ]; then
        error_invalid_option
    # /remove specified but no more argument
    elif [ "${ARGUMENT_REMOVE}" == '1' ] && [ -z "${OPTION_REMOVE}" ]; then
        error_invalid_option
    # /remove specified but no more argument
    elif [ "${ARGUMENT_CRON}" == '1' ] && [ -z "${OPTION_CRON}" ]; then
        error_invalid_option
    # --check specified but no more argument 
    elif [ "${ARGUMENT_CHECK}" == '1' ] && [ -z "${OPTION_CHECK}" ]; then
        error_invalid_option
    # --start_bot specified but no other elements
    elif [ "${ARGUMENT_START_BOT}" == '1' ] && [ -z "${OPTION_TELEGRAM_TOKEN}" ] && [ -z "${OPTION_SCALESERP_TOKEN}" ] ; then
        OPTION_NO_TOKEN='1'
    # --start_bot and only one of the two token specified but not the second one
    elif [ "${ARGUMENT_START_BOT}" == '1' ] && ( [ -z "${OPTION_TELEGRAM_TOKEN}" ] || [ -z "${OPTION_SCALESERP_TOKEN}" ] ); then
        error_invalid_option
    fi
}

function requirement_root {
    # check whether the script runs as root
    if [ "$EUID" -ne 0 ]; then
        error_no_root_privileges
    fi
}

function requirement_os {
    # check whether supported package manager is installed and populate relevant variables
    if [ "$(command -v dnf)" ]; then
        PACKAGE_MANAGER='dnf'
    elif [ "$(command -v yum)" ]; then
        PACKAGE_MANAGER='yum'
    elif [ "$(command -v apt-get)" ]; then
        PACKAGE_MANAGER='apt-get'
    elif [ "$(command -v pkg)" ]; then
        PACKAGE_MANAGER='pkg'
    elif [ "$(command -v pacman)" ]; then
        PACKAGE_MANAGER='pacman'
    else
        error_os_not_supported
    fi

    # check whether supported service manager is installed and populate relevant variables
    # systemctl
    if [ "$(command -v systemctl)" ]; then
        SERVICE_MANAGER='systemctl'
    # service
    elif [ "$(command -v service)" ]; then
        SERVICE_MANAGER='service'
    # openrc
    elif [ "$(command -v rc-service)" ]; then
        SERVICE_MANAGER='openrc'
    else
        error_os_not_supported
    fi
}

function requirement_internet {
    # check internet connection
    if ping -q -c 1 -W 1 google.com >/dev/null; then
        echo '[i] Info: device is connected to the internet...'
    else
        error_no_internet_connection
    fi
}

#############################################################################
# TELEGRAM COMMANDS FUNCTIONS
#############################################################################

function GSAbot_chat_conf {
    # return error when config file isn't installed on the system
    if [ "${GSAbot_CONFIG}" == 'disabled' ]; then
        error_not_available
    fi

    GSAbot_CONFIG_CHAT="${$GSAbot_PATH}/chat_conf.d/GSAbot_chat_${OPTION_CHAT_ID}.conf"
    if [ -f $GSAbot_CONFIG_CHAT]; then
        source $GSAbot_CONFIG_CHAT
    else
        cp $GSAbot_PATH/chat_conf.d/GSAbot_chat_XXX.conf $GSAbot_CONFIG_CHAT
        source $GSAbot_CONFIG_CHAT
    fi
}

function GSAbot_start {
    # return error when config file isn't installed on the system
    if [ "${GSAbot_CONFIG}" == 'disabled' ]; then
        error_not_available
    fi

    # update the configuration file with the chat id
    printf "\t\t \[\xE2\x9E\x95] Creating chat's config file..."
    sed -i "s/TELEGRAM_CHAT='$TELEGRAM_CHAT'/TELEGRAM_CHAT='$OPTION_START'/" $GSAbot_CONFIG_CHAT

    # creating or updating cronjobs
    printf "\t\t \[\xE2\x9E\x95] Creating default cronjobs..."
    if [ -f $CRON_PATH/GSAbot_cron_$TELEGRAM_CHAT]; then
        touch $CRON_PATH/GSAbot_cron_$TELEGRAM_CHAT
        chmod 644 $CRON_PATH/GSAbot_cron_$TELEGRAM_CHAT
    fi
    /bin/bash /usr/bin/GSAbot --chat_id $TELEGRAM_CHAT --cron
}

function GSAbot_version {
    # return error when config file isn't installed on the system
    if [ "${GSAbot_CONFIG}" == 'disabled' ]; then
        error_not_available
    fi

    echo "GSAbot ${GSAbot_VERSION}"
    echo "Copyright 2020, Ivan Rojkov."
    echo "GNU General Public License version 3."
    echo
    echo "Written by Ivan Rojkov"
}

function GSAbot_commands { 
    printf "I can send you alerts when new papers, articles, books, etc. "
    printf "related to some keywords are published on Google Scholar/arXiv. \n\n"
    printf "You can control me by sending these commands: \n\n"
    printf "/start - Start the bot and display the welcome message\n\n"
    printf "/help - Show this help message\n\n"
    printf "/status - Show the alert status (_on_ or _off_)\n\n"
    printf "/alert - Change the alert status, you should specify "
    printf "_on_ or _off_\n\n"
    printf "/add - Add one or multiple keywords/keyphrases to the list "
    printf "such that I know what to look for on Google Scholar/arXiv, "
    printf 'please separate them by ";" otherwise I will be lost\n\n'
    printf "/remove - Remove a keyword/keyphrase from my listening list. "
    printf "You should specify only one keyword/keyphrase at a time\n\n"
    printf "/list - Show the list of keywords to search of Google Scholar/arXiv\n\n"
    printf "/cron - Change the frequency at which GSAbot checks Google Scholar/arXiv, you "
    printf "should specify a cron schedule expression (check "
    printf "[Crontab Guru](https://crontab.guru) for more details)\n\n"
    printf "/version - Show information about my version\n\n"
    printf "/check\_gscholar - Check Google Scholar manually (can take quite some time)\n\n"
    printf "/check\_arxiv - Check arXiv manually (can take quite some time)\n\n"
    printf "/check\_updates - Check GSAbot's updates manually\n\n"
    printf "/stop - Stop the bot on the server\n\n"
}

function GSAbot_status {
    # return error when config file isn't installed on the system
    if [ "${GSAbot_CONFIG}" == 'disabled' ]; then
        error_not_available
    fi

    printf "Here is my current status (_on_ means I am allowed to send you alerts and _off_ means I am not).\n"

    if [ "${ALERT_STATUS}" == 'on' ]; then
        printf '\t\t *Status :* \t\t *%s* \t \xE2\x9C\x85\n' $ALERT_STATUS
    else
        printf "\t\t <b>Status :</b> \t\t <strong>%s</strong> \t \xE2\x9B\x94\n" $ALERT_STATUS
    fi
}

function GSAbot_alert {
    # return error when config file isn't installed on the system
    if [ "${GSAbot_CONFIG}" == 'disabled' ]; then
        error_not_available
    fi

    if [ "${ALERT_STATUS}" == "${OPTION_ALERT}" ]; then
        printf "The alert is already set on %s, I don't change it.\n" $ALERT_STATUS
    else
        # update the configuration file
        sed -i "s/ALERT_STATUS='$ALERT_STATUS'/ALERT_STATUS='$OPTION_ALERT'/" $GSAbot_CONFIG_CHAT
        # GSAbot_validate

        # print the msg
        printf "I changed my alert status from %s to %s. \n" $ALERT_STATUS $OPTION_ALERT
        printf "You can check it by sending the command /status. \n"
    fi
}

function GSAbot_list { 
    # return error when config file isn't installed on the system
    if [ "${GSAbot_CONFIG}" == 'disabled' ]; then
        error_not_available
    fi

    # print msg if no keywords in the list
    if [ "${KEYWORDS}" == '' ]; then
        printf "Currently I am a free bot \xF0\x9F\x8E\x89 \n"
        printf "No keywords defined yet ! Use the command /add "
        printf "followed by all the keywords you want me to listen to.\n"
        exit 0
    fi

    if [ "${ALERT_STATUS}" == 'on' ]; then
        printf "Here are all the keywords I am listening to: \n"
    else
        printf "Here are all the keywords which are in the list, "
        printf "but the alerts are currently disabled. Send "
        printf '"*/alert _on_*" to enable them.\n'
    fi
    
    # use internal field separator (IFS) to parse the string into an array
    IFS=';' read -ra ADDR <<< "$KEYWORDS"
    for i in "${ADDR[@]}"; do
        printf "\t\t -$i\n"
    done
}

function GSAbot_add {
    # return error when config file isn't installed on the system
    if [ "${GSAbot_CONFIG}" == 'disabled' ]; then
        error_not_available
    fi

    OPTION_ADD="${KEYWORDS};${OPTION_ADD}"
    NEW_KEYWORDS=''

    # print the begining of the msg
    printf "Here is the updated list with all the keywords "
    printf "that I have to search on Google Scholar/arXiv."
    if [ "${ALERT_STATUS}" == 'off' ]; then
        printf "The alerts are currently disabled, send "
        printf '"*/alert _on_*" to enable them.'
    fi
    printf "\n"

    # use internal field separator (IFS) to parse the string into an array
    IFS=';' read -ra ADDR <<< "$OPTION_ADD"
    for i in "${ADDR[@]}"; do
        i=$(echo "$i" | sed -e 's/^[ \t]*//' | sed -e 's/ *$//' )
        if [ -n "${i}" ]; then
            printf "\t\t -$i\n"
            NEW_KEYWORDS="${NEW_KEYWORDS}${i};"
        fi
    done

    # update the configuration file
    sed -i "s/KEYWORDS='$KEYWORDS'/KEYWORDS='$NEW_KEYWORDS'/" $GSAbot_CONFIG_CHAT
 
}

function GSAbot_remove {
    # return error when config file isn't installed on the system
    if [ "${GSAbot_CONFIG}" == 'disabled' ]; then
        error_not_available
    fi

    # prepare variables
    OPTION_REMOVE=$(echo "$OPTION_REMOVE" | sed -e 's/^[ \t]*//' | sed -e 's/ *$//' )
    NEW_KEYWORDS=''

    # print the begining of the msg
    printf "Here is the updated list with all the keywords "
    printf "that I have to search on Google Scholar/arXiv. _However, "
    printf "I have to warn you that if the name that you gave "
    printf "me do not exactly correspond to a element of the "
    printf "list, I will not remove it!_\n"
    if [ "${ALERT_STATUS}" == 'off' ]; then
        printf "The alerts are currently disabled, send "
        printf '"*/alert _on_*" to enable them.\n'
    fi

    # use internal field separator (IFS) to parse the string into an array
    IFS=';' read -ra ADDR <<< "$KEYWORDS"
    for i in "${ADDR[@]}"; do
        if [ "${i}" != "${OPTION_REMOVE}" ]; then
            printf "\t\t -$i\n"
            NEW_KEYWORDS="${NEW_KEYWORDS}${i};"
        fi
    done

    # update the configuration file
    sed -i "s/KEYWORDS='$KEYWORDS'/KEYWORDS='$NEW_KEYWORDS'/" $GSAbot_CONFIG_CHAT

}

function GSAbot_cron {
    # return error when config file isn't installed on the system
    if [ "${GSAbot_CONFIG}" == 'disabled' ]; then
        error_not_available
    fi

    # begining of the msg
    printf "Here is what I am doing on the server's side\n\n"
    printf '\*\*\*UPDATING CRONJOBS\*\*\* \n\n'

    # remove cronjobs so automated tasks can also be deactivated
    printf '\t\t \[\xE2\x9E\x96] Removing old GSAbot cronjobs...\n'
    > $CRON_PATH/GSAbot_cron_$TELEGRAM_CHAT

    # go through all the possible tasks and add them one by one
    # add an automatic upgrade of the bot task
    if [ "${GSAbot_UPGRADE}" == 'yes' ]; then
        printf '\t\t \[\xE2\x9E\x95] Updating cronjob for automated upgrade of GSAbot...\n'
        echo -e "# This cronjob activates automatic upgrade of GSAbot on the chosen schedule\n${GSAbot_UPGRADE_CRON} /usr/bin/GSAbot --silent-upgrade >/dev/null 2>&1" >> $CRON_PATH/GSAbot_cron_$TELEGRAM_CHAT
    fi
    # add a bot's update alerts task
    if [ "${GSAbot_UPDATES}" == 'yes' ]; then
        printf "\t\t \[\xE2\x9E\x95] Updating cronjob for automated alerts of available GSAbot's updates ...\n"
        echo -e "# This cronjob activates automated checks of available updates of GSAbot on the chosen schedule\n${GSAbot_UPDATES_CRON} /usr/bin/GSAbot --check_updates >/dev/null 2>&1" >> $CRON_PATH/GSAbot_cron_$TELEGRAM_CHAT
    fi
    # add a check & alert task if the status is on
    if [ "${ALERT_STATUS}" == 'on' ]; then
        # Cronjob for Google Scholar
        printf '\t\t \[\xE2\x9E\x95] Adding a cronjob for automated checks of Google Scholar and alerts on Telegram...\n'
        echo -e "# This cronjob activates automated checks of Google Scholar and alerts on Telegram on the chosen schedule\n${ALERT_CRON_GSCHOLAR} /usr/bin/GSAbot --check gscholar >/dev/null 2>&1" >> $CRON_PATH/GSAbot_cron_$TELEGRAM_CHAT
        # Cronjob for arXiv
        printf '\t\t \[\xE2\x9E\x95] Adding a cronjob for automated checks of arXiv and alerts on Telegram...\n'
        echo -e "# This cronjob activates automated checks of arXiv and alerts on Telegram on the chosen schedule\n${ALERT_CRON_ARXIV} /usr/bin/GSAbot --check arxiv >/dev/null 2>&1" >> $CRON_PATH/GSAbot_cron_$TELEGRAM_CHAT
    fi

    # give user feedback when all automated tasks are disabled
    if [ "${ALERT_STATUS}" != 'on' ] && \
    [ "${GSAbot_UPDATES}" != 'yes' ]; then
        printf '\n\xE2\x9D\x95 All automated tasks are disabled, I will not disturb you anymore...\n'
        exit 0
    fi

    # restart cron to really effectuate the new cronjobs
    printf '\n\xE2\x8F\xB0 The new automated tasks can take up to an hour to come into force... \n'

    exit 0
}

function GSAbot_check {
    # return error when config file isn't installed on the system
    if [ "${GSAbot_CONFIG}" == 'disabled' ]; then
        error_not_available
    fi

    # check either gscholar, arxiv or both
    if [ "${OPTION_CHECK}" == 'gscholar' ]; then
        RESULT_CHECK="$(python3 -W ignore ${GSAbot_PATH}/GSAbot_search_on_gscholar.py)"
    elif [ "${OPTION_CHECK}" == 'arxiv' ]; then
        RESULT_CHECK="$(python3 -W ignore ${GSAbot_PATH}/GSAbot_search_on_arxiv.py)"
    elif [ "${OPTION_CHECK}" == 'both' ]; then
        RESULT_CHECK="$(python3 -W ignore ${GSAbot_PATH}/GSAbot_search_on_gscholar.py && 
                        python3 -W ignore ${GSAbot_PATH}/GSAbot_search_on_arxiv.py)"
    fi

    # use Ruby for sending Telegram messages
    ruby <<EOF
      require 'telegram/bot'
      
      Telegram::Bot::Client.run("${TELEGRAM_TOKEN}") do |bot|

        scholar_result = "${RESULT_CHECK}".split('------')
        for res in scholar_result
          
          bot.api.send_message( \
            chat_id: "${TELEGRAM_CHAT}", \
            text: res, \
            parse_mode: 'MarkDown' \
            )
        end
      end
EOF
}

function GSAbot_check_updates {
    # return error when config file isn't installed on the system
    if [ "${GSAbot_CONFIG}" == 'disabled' ]; then
        error_not_available
    fi

    # compare current and GitHub versions
    compare_version

    if [ "${NEW_VERSION_AVAILABLE}" == '1' ]; then
        printf "I can be upgraded to the version ${VERSION_GSAbot} \xF0\x9F\x8E\x89"
        printf "(currently ${GSAbot_VERSION})\n"
        printf 'Run "GSAbot --upgrade" on the server side to upgrade me !\n'
    else
        printf "No new version of GSAbot available.\n"
        printf "I am at the top of my form \xF0\x9F\x8E\x89\n"
    fi
}

#############################################################################
# SERVER COMMANDS FUNCTIONS
#############################################################################

function GSAbot_help {
    echo "Usage:"
    echo " GSAbot [command]..."
    echo " GSAbot [command]... [parameter]..."
    echo
    echo "Commands:"
    echo " --install           Install GSAbot on the system and unlocks all features"
    echo " --which_config      Print the path to the config file"
    echo " --start_bot TELEGRAM_TOKEN SCALESERP_TOKEN   "
    echo "                     Put tokens in the config file and start GSAbot"
    echo " --cron '* * * * *'  Effectuate cron changes from GSAbot config"
    echo " --check OPTION      Trigger the check for new publications"
    echo "                     OPTION is either gscholar, arxiv or both"
    echo " --check_updates     Trigger the check for updates of the bot"
    echo " --upgrade           Upgrade GSAbot to the latest stable version"
    echo " --uninstall         Uninstall GSAbot from the system"
    echo " --help              Display this help"
    echo " --version           Display version information"
}

function GSAbot_install_check {
    # check wheter GSAbot.conf is already installed
    if [ -f $GSAbot_PATH/GSAbot.conf ]; then
        # if true, ask the user whether a reinstall is intended
        while true
            do
                read -r -p '[?] GSAbot is already installed, would you like to reinstall? (yes/no): ' REINSTALL
                [ "${REINSTALL}" = "yes" ] || [ "${REINSTALL}" = "no" ] && break
                error_type_yes_or_no
            done

        # exit if not intended
        if [ "${REINSTALL}" = "no" ]; then
            exit 0
        fi

        # reinstall when intended
        if [ "${REINSTALL}" = "yes" ]; then
            echo "[!] GSAbot will be reinstalled now..."
            GSAbot_install
        fi
    else
        # if GSAbot isn't currently installed, install it right away
        GSAbot_install
    fi
}

function GSAbot_install {
    # function requirements
    requirement_root

    echo "[!] GSAbot will be installed now..."

    # install os packages
    echo "[+] Installing packages dependencies..."

    PACKAGES_OS=('sed' 'mktemp' 'wget' 'curl' 'nohup' 'ruby' 'python3')
    for PCKG in "${PACKAGES_OS[@]}"
    do 
        if [ ! "$(command -v $PCKG)" ];then
            echo "---> Installing ${PCKG} ..."
            if [ "${PACKAGE_MANAGER}" == "dnf" ]; then
                dnf install $PCKG --assumeyes --quiet
            elif [ "${PACKAGE_MANAGER}" == "yum" ]; then
                yum install $PCKG --assumeyes --quiet
            elif [ "${PACKAGE_MANAGER}" == "apt-get" ]; then
                apt-get install $PCKG --assume-yes --quiet
            elif [ "${PACKAGE_MANAGER}" == "pkg" ]; then
                pkg install -y $PCKG 
            elif [ "${PACKAGE_MANAGER}" == "pacman" ]; then
                pacman -S $PCKG --noconfirm
            fi
        fi        
    done

    # install python packages
    echo "[+] Installing Python library dependencies..."

    if [ ! "$(command -v pip3)" ];then
        curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
        python3 get-pip.py
    fi

    PACKAGES_PIP=('requests' 'arxiv')
    for PCKG in "${PACKAGES_PIP[@]}"
    do 
        if [ ! "$(pip3 list --format=legacy | grep "${PCKG}")" ];then
            echo "---> Installing ${PCKG} ..."
            pip3 install $PCKG -q
        fi        
    done

    # install ruby packages
    echo "[+] Installing Ruby library dependencies..."

    PACKAGES_GEM=('parseconfig' 'telegram-bot-ruby')
    for PCKG in "${PACKAGES_GEM[@]}"
    do 
        if [ ! "$(gem list | grep "${PCKG}")" ];then
            echo "---> Installing ${PCKG} ..."
            gem install $PCKG
        fi        
    done

    # add GSAbot folder to /etc and add permissions
    echo "[+] Adding folders to system..."
    mkdir -m 755 -p $GSAbot_PATH
    mkdir -m 777 -p $GSAbot_PATH/chat_conf.d
    # install latest version GSAbot and add permissions
    echo "[+] Installing latest version of GSAbot..."
    wget --quiet https://raw.githubusercontent.com/irojkov-ph/GSAbot/$GSAbot_BRANCH/GSAbot.sh -O /usr/bin/GSAbot
    wget --quiet https://raw.githubusercontent.com/irojkov-ph/GSAbot/$GSAbot_BRANCH/src/GSAbot.rb -O $GSAbot_PATH/GSAbot.rb
    wget --quiet https://raw.githubusercontent.com/irojkov-ph/GSAbot/$GSAbot_BRANCH/src/GSAbot_search_on_gscholar.py -O $GSAbot_PATH/GSAbot_search_on_gscholar.py
    wget --quiet https://raw.githubusercontent.com/irojkov-ph/GSAbot/$GSAbot_BRANCH/src/GSAbot_search_on_arxiv.py -O $GSAbot_PATH/GSAbot_search_on_arxiv.py    
    chmod 755 /usr/bin/GSAbot
    chmod 755 $GSAbot_PATH/GSAbot.rb
    chmod 755 $GSAbot_PATH/GSAbot_search_on_gscholar.py
    chmod 755 $GSAbot_PATH/GSAbot_search_on_arxiv.py
    # create a log file in the $GSAbot_PATH folder
    touch $GSAbot_PATH/GSAbot.log
    chmod 666 $GSAbot_PATH/GSAbot.log
    # add GSAbot configuration file to $GSAbot_PATH and add permissions
    echo "[+] Adding configuration file to system..."
    wget --quiet https://raw.githubusercontent.com/irojkov-ph/GSAbot/$GSAbot_BRANCH/lib/GSAbot.conf -O $GSAbot_PATH/GSAbot.conf
    wget --quiet https://raw.githubusercontent.com/irojkov-ph/GSAbot/$GSAbot_BRANCH/lib/GSAbot_chat_XXX.conf -O $GSAbot_PATH/chat_conf.d/GSAbot_chat_XXX.conf
    chmod 766 $GSAbot_PATH/GSAbot.conf
    chmod 766 $GSAbot_PATH/chat_conf.d/GSAbot_chat_XXX.conf


    # optionally configure method telegram
    while true
        do
            read -r -p '[?] Configure Telegram? (yes/no): ' TELEGRAM_CONFIGURE
            [ "${TELEGRAM_CONFIGURE}" = "yes" ] || [ "${TELEGRAM_CONFIGURE}" = "no" ] && break
            error_type_yes_or_no
        done

    if [ "${TELEGRAM_CONFIGURE}" == 'yes' ]; then
        read -r -p '[?] Enter Telegram bot token: ' TELEGRAM_TOKEN
        echo "[+] Adding telegram access token to configuration file..."
        read -r -p '[?] Enter ScaleSERP token: ' SCALESERP_TOKEN
        echo "[+] Adding scaleserp token to configuration file..."
        /bin/bash /usr/bin/GSAbot --start_bot "${TELEGRAM_TOKEN}" "${SCALESERP_TOKEN}"
    else
        echo "[-] GSAbot was not started because tokens not specified yet."
        echo "    Once you know them run the following command: GSAbot --start_bot 'TELEGRAM_TOKEN' 'SCALESERP_TOKEN'"
    fi

    # use current major version in $GSAbot_PATH/GSAbot.conf
    echo "[+] Adding default config parameters to configuration file..."
    sed -i s%'major_version_here'%"$(echo "${GSAbot_VERSION}" | cut -c1)"%g $GSAbot_PATH/GSAbot.conf
    sed -i s%'branch_here'%"$(echo "${GSAbot_BRANCH}")"%g $GSAbot_PATH/GSAbot.conf
    # sed -i s%'username_goes_here'%"$(echo "${USER}")"%g $GSAbot_PATH/GSAbot.conf

    # restart cron to make sure that cron service is runing
    echo '[+] Restarting the cron service...'
    if [ "${SERVICE_MANAGER}" == "systemctl" ] && [ "${PACKAGE_MANAGER}" == "dnf" ]; then
        systemctl restart crond.service
    elif [ "${SERVICE_MANAGER}" == "systemctl" ] && [ "${PACKAGE_MANAGER}" == "yum" ]; then
        systemctl restart crond.service
    elif [ "${SERVICE_MANAGER}" == "systemctl" ] && [ "${PACKAGE_MANAGER}" == "apt-get" ]; then
        systemctl restart cron.service
    elif [ "${SERVICE_MANAGER}" == "service" ] && [ "${PACKAGE_MANAGER}" == "apt-get" ]; then
        service cron restart
    elif [ "${SERVICE_MANAGER}" == "systemctl" ] && [ "${PACKAGE_MANAGER}" == "pacman" ]; then
        systemctl restart cronie.service
    fi

}

function GSAbot_start_bot {
    # function requirements
    requirement_root

    if [ "${OPTION_NO_TOKEN}" != '1' ]; then
        # replace the default values by the new token
        sed -i "s/TELEGRAM_TOKEN='$TELEGRAM_TOKEN'/TELEGRAM_TOKEN='$OPTION_TELEGRAM_TOKEN'/" "$GSAbot_PATH/GSAbot.conf"
        sed -i "s/SCALESERP_TOKEN='$SCALESERP_TOKEN'/SCALESERP_TOKEN='$OPTION_SCALESERP_TOKEN'/" "$GSAbot_PATH/GSAbot.conf"
    fi

    # run and keep the bot running even after exiting the shell or terminal
    nohup ruby $GSAbot_PATH/GSAbot.rb > $GSAbot_PATH/GSAbot.log &
}

function GSAbot_which_config {

   echo "The config file is here: ${GSAbot_PATH}/GSAbot.conf"

}


function GSAbot_upgrade {
    # function requirements
    requirement_root
    compare_version

    # install new version if more recent version is available
    if [ "${NEW_VERSION_AVAILABLE}" == '1' ]; then
        echo "[i] New version of GSAbot available, installing now..."
        echo "[i] Create temporary file for self-upgrade..."
        TMP_INSTALL="$(mktemp)"
        echo "[i] Download most recent version of GSAbot..."
        wget --quiet https://raw.githubusercontent.com/irojkov-ph/GSAbot/$GSAbot_BRANCH/GSAbot.sh -O "${TMP_INSTALL}"
        echo "[i] Set permissions on installation script..."
        chmod 700 "${TMP_INSTALL}"
        echo "[i] Executing installation script..."
        /bin/bash "${TMP_INSTALL}" --self-upgrade
    else
        echo "[i] No new version of GSAbot available."
        exit 0
    fi
}

function GSAbot_silent_upgrade {
    # function requirements
    requirement_root
    compare_version

    if [ "${NEW_VERSION_AVAILABLE}" == '1' ]; then
        # create temporary file for self-upgrade
        TMP_INSTALL="$(mktemp)"
        # download most recent version of GSAbot
        wget --quiet https://raw.githubusercontent.com/irojkov-ph/GSAbot/$GSAbot_BRANCH/GSAbot.sh -O "${TMP_INSTALL}"
        # set permissions on installation script
        chmod 700 "${TMP_INSTALL}"
        # executing installation script
        /bin/bash "${TMP_INSTALL}" --self-upgrade
    else
        # exit when no updates are available
        exit 0
    fi
}

function GSAbot_self_upgrade {
    # function requirements
    requirement_root

    # stop GSAbot to be sure that it updates correctly
    if [ ! -z "$(ps aux | grep GSAbot.rb | grep -v grep | awk '{print $2}')" ]; then
        kill $(ps aux | grep GSAbot.rb | grep -v grep | awk '{print $2}')
    fi

    # download most recent version and add permissions
    wget --quiet https://raw.githubusercontent.com/irojkov-ph/GSAbot/$GSAbot_BRANCH/GSAbot.sh -O /usr/bin/GSAbot
    wget --quiet https://raw.githubusercontent.com/irojkov-ph/GSAbot/$GSAbot_BRANCH/src/GSAbot.rb -O $GSAbot_PATH/GSAbot.rb
    wget --quiet https://raw.githubusercontent.com/irojkov-ph/GSAbot/$GSAbot_BRANCH/src/GSAbot_search_on_gscholar.py -O $GSAbot_PATH/GSAbot_search_on_gscholar.py
    wget --quiet https://raw.githubusercontent.com/irojkov-ph/GSAbot/$GSAbot_BRANCH/src/GSAbot_search_on_arxiv.py -O $GSAbot_PATH/GSAbot_search_on_arxiv.py    
    chmod 755 /usr/bin/GSAbot
    chmod 755 $GSAbot_PATH/GSAbot.rb
    chmod 755 $GSAbot_PATH/GSAbot_search_on_gscholar.py
    chmod 755 $GSAbot_PATH/GSAbot_search_on_arxiv.py

    # start the GSAbot again
    /bin/bash /usr/bin/GSAbot --start_bot "${TELEGRAM_TOKEN}" "${SCALESERP_TOKEN}"

    echo "[i] GSAbot upgraded to version ${GSAbot_VERSION}..."

    # notify on telegram
    if [ "${GSAbot_UPDATES}" == 'yes' ]; then
        # use Ruby for sending Telegram messages
        ruby <<EOF
            require 'telegram/bot'

            Telegram::Bot::Client.run("${TELEGRAM_TOKEN}") do |bot|
            
                scholar_result = "${RESULT_CHECK}".split('------')
                for res in scholar_result
                    bot.api.send_message( \
                                chat_id: "${TELEGRAM_CHAT}", \
                                text: "I've just upgraded to version ${GSAbot_VERSION} \xF0\x9F\x8E\x89", \
                                parse_mode: 'MarkDown' \
                                )
                end
            end
EOF
    fi

}

function GSAbot_uninstall {
    # function requirements
    requirement_root

    # ask whether uninstall was intended
    while true
        do
            read -r -p '[?] Are you sure you want to uninstall GSAbot? (yes/no): ' UNINSTALL
            [ "${UNINSTALL}" = "yes" ] || [ "${UNINSTALL}" = "no" ] && break
            error_type_yes_or_no
       done

        # exit if not intended
        if [ "${UNINSTALL}" = "no" ]; then
            exit 0
        fi

        # uninstall when intended
        if [ "${UNINSTALL}" = "yes" ]; then

            echo "[i] GSAbot will be uninstalled now..."
            echo "[-] Stopping GSAbot..."
            if [ ! -z "$(ps aux | grep GSAbot.rb | grep -v grep | awk '{print $2}')" ]; then
                kill $(ps aux | grep GSAbot.rb | grep -v grep | awk '{print $2}')
            fi
            echo "[-] Removing GSAbot cronjobs from system..."
            rm -f $CRON_PATH/GSAbot_*
            echo "[-] Removing GSAbot from system..."
            rm -f /usr/bin/GSAbot
            rm -rf $GSAbot_PATH
            exit 0
        fi
}

#############################################################################
# GENERAL FUNCTIONS
#############################################################################

function compare_version {
    # source version information from github and remove dots
    VERSION_GSAbot=$(curl -s https://api.github.com/repos/irojkov-ph/GSAbot/releases/latest | grep tag_name)
    VERSION_GSAbot="${VERSION_GSAbot: -7: 5}"

    # Remove points in version numbers
    GSAbot_VERSION_CURRENT_NUMBER="$(echo "${GSAbot_VERSION}" | tr -d '.')"
    GSAbot_VERSION_RELEASE_NUMBER="$(echo "${VERSION_GSAbot}" | tr -d '.')"

    # check whether release version has a higher version number
    if [ "${GSAbot_VERSION_RELEASE_NUMBER}" -gt "${GSAbot_VERSION_CURRENT_NUMBER}" ]; then
        NEW_VERSION_AVAILABLE='1'
    fi
}

#############################################################################
# MAIN FUNCTION
#############################################################################

function GSAbot_main {
    # check if os is supported
    requirement_os

    # check argument validity
    requirement_argument_validity

    # call relevant functions based on arguments
    if [ "${ARGUMENT_CHAT_ID}" == '1' ]; then
        GSAbot_chat_conf
    else
        # Options which require GSAbot_chat_XXX.conf
        # will not work if a chat id hasn't been specified
        GSAbot_CONFIG='disabled'
    fi
    if [ "${ARGUMENT_START}" == '1' ]; then
        GSAbot_start
    fi
    if [ "${ARGUMENT_VERSION}" == '1' ]; then
        GSAbot_version
    fi
    if [ "${ARGUMENT_HELP}" == '1' ]; then
        GSAbot_help
    fi 
    if [ "${ARGUMENT_COMMANDS}" == '1' ]; then
        GSAbot_commands
    fi
    if [ "${ARGUMENT_STATUS}" == '1' ]; then
        GSAbot_status
    fi
    if [ "${ARGUMENT_ALERT}" == '1' ]; then
        GSAbot_alert
    fi
    if [ "${ARGUMENT_ADD}" == '1' ]; then
        GSAbot_add
    fi
    if [ "${ARGUMENT_REMOVE}" == '1' ]; then
        GSAbot_remove
    fi
    if [ "${ARGUMENT_LIST}" == '1' ]; then
        GSAbot_list
    fi
    if [ "${ARGUMENT_CRON}" == '1' ]; then
        GSAbot_cron
    fi
    if [ "${ARGUMENT_CHECK}" == '1' ]; then
        GSAbot_check
    fi
    if [ "${ARGUMENT_UPDATES}" == '1' ]; then
        GSAbot_check_updates
    fi
    if [ "${ARGUMENT_INSTALL}" == '1' ]; then
        GSAbot_install_check
    fi
    if [ "${ARGUMENT_START_BOT}" == '1' ]; then
        GSAbot_start_bot
    fi
    if [ "${ARGUMENT_WHICH}" == '1' ]; then
        GSAbot_which_config
    fi
    if [ "${ARGUMENT_UPGRADE}" == '1' ]; then
        GSAbot_upgrade
    fi
    if [ "${ARGUMENT_SILENT_UPGRADE}" == '1' ]; then
        GSAbot_silent_upgrade
    fi
    if [ "${ARGUMENT_SELF_UPGRADE}" == '1' ]; then
        GSAbot_self_upgrade
    fi
    if [ "${ARGUMENT_UNINSTALL}" == '1' ]; then
        GSAbot_uninstall
    fi
    if [ "${ARGUMENT_NONE}" == '1' ]; then
        error_invalid_option
    fi
}

#############################################################################
# CALL MAIN FUNCTION
#############################################################################

GSAbot_main

#############################################################################
# END
#############################################################################
