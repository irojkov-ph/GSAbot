# GSAbot
This project aims to create a Telegram bot which will run on your Linux server 24/7 and check [arXiv](https://arxiv.org/) and [Google Scholar](https://scholar.google.com/) for new publication which relates to your favourite keywords/keyphrases. For the arXiv, it uses the python API made by the arXiv's team, whereas for the GScholar, it uses [Scale SERP](https://scaleserp.com/) services. You must then create an account on this website and get your Scale SERP token.

## Installation

To install it first download the [latest version](https://github.com/irojkov-ph/GSAbot/releases/latest) of the project manually or clone it using git
```
git clone https://github.com/irojkov-ph/GSAbot.git
```
Then open the terminal at the location of this project and execute the following command (you will need the admin rights)
```
./GSAbot.sh --install
```
This will install the project files on your server, i.e. `./src/` files will be now located in the new `/etc/GSAbot/` folder, the `./lib/GSAbot.conf` file will be in a hidden folder in your home directory `$HOME/.GSAbot/` and lastly the `GSAbot.sh` file will be globaly installed in `/usr/bin/` folder. During the installation, the script will ask you for configuring tokens that the bot needs, namely the Telegram bot token and the Scale SERP token.

Execute the help command (`--help` or `-h`) to check what `GSAbot` can do:
```
GSAbot --help
```
## Usage
Whenever the bot has started on the server side, you can use the Telegram chat where the bot is install to control it. Here are some examples of few messages you can send to it.
![Start](https://raw.githubusercontent.com/irojkov-ph/GSAbot/main/img/bot_start_cmd.png?raw=true)
![Status](https://raw.githubusercontent.com/irojkov-ph/GSAbot/main/img/bot_status_cmd.png)
![List/Add/Remove](https://raw.githubusercontent.com/irojkov-ph/GSAbot/main/img/bot_list_add_remove_cmds.png)

## Remove
To uninstall the bot you can lanch the following terminal command on the server side:
```
GSAbot --uninstall
```
This will stop the bot and remove all the files that were previously created.

## Contributing
This is a personnal project which emerged from the need of being up to date wrt. new publication in my fields of interest. I decided to put it in a GNU GPL v3 to let the possibility to everyone to use it and expand it. The code is not ideal and there are certainly some errors so please let me know by opening an issue and I will see what I can do.

## Next features
Here are some ideas that I haven't implemented yet but which could be in the next weeks/months.
 - Ability to choose only arxiv and not gscholar as updates.
 - Add other publication streams (journals/other arxiv/...)
 - (If you have an idea, create an issue and I'll add it to this list)

## License
Copyright 2020, I. Rojkov.
Licensed under [GNU General Public License version 3](https://opensource.org/licenses/GPL-3.0).