# GSAbot
This project aims to create a Telegram bot which will run on your Linux server 24/7 and check [arXiv](https://arxiv.org/) and [Google Scholar](https://scholar.google.com/) for new publication which relates to your favorite keywords/keyphrases. For the arXiv, it uses the python API made by the arXiv's team, whereas for the GScholar, it uses [Scale SERP](https://scaleserp.com/) services. You must then create an account on this website and get your Scale SERP token.

## Start using the bot
I have created this bot for my personal usage. Its first versions (v1 and v2) were restricted to only one chat whose id had to be specified at the initialization of the bot. With the new version, GSAbot can now be used for multiple chats without any interference between their keywords or alerts. If you want to use this bot, simply follow [this link](https://telegram.me/gscholar_alert_bot).

It runs on a personal server with limited computational capacity. If the demand for it increases it might be transferred to a cloud computing platform such as Heroku, Google Cloud Functions, Netlify, etc. So if you like it do not hesitate to give me a tip via [PayPal](https://www.paypal.com/donate/?business=A4Q7DQH8NB5HL&no_recurring=0&currency_code=CHF) which will go into the maintenance of this service.

## Usage
Here are some examples of few messages you can send to it. To see the whole list of messages that the bot understands, send the command `/help`.
![Bot_main_commands](https://raw.githubusercontent.com/irojkov-ph/GSAbot/main/img/bot_main_commands.png)

## Installation on a server
To install it first download the [latest version](https://github.com/irojkov-ph/GSAbot/releases/latest) of the project manually or clone it using git
```
git clone https://github.com/irojkov-ph/GSAbot.git
```
Then open the terminal at the location of this project and execute the following command (you will need the admin rights)
```
./GSAbot.sh --install
```
This will install the project files on your server, i.e. `./src/` files will be now located in the new `/etc/GSAbot/` folder, the `./lib/GSAbot.conf` file will be in a hidden folder in your home directory `$HOME/.GSAbot/` and lastly the `GSAbot.sh` file will be globally installed in `/usr/bin/` folder. During the installation, the script will ask you for configuring tokens that the bot needs, namely the Telegram bot token and the Scale SERP token.

Execute the help command (`--help` or `-h`) to check what `GSAbot` can do:
```
GSAbot --help
```
Whenever the bot has started on the server side, you can use the Telegram chat where the bot is install to control it. 

## Remove
To uninstall the bot from the server you can run the following terminal command on the server side:
```
GSAbot --uninstall
```
This will stop the bot and remove all files that were previously created.

## Contributing
This is a personal project which emerged from the need of being up to date wrt. new publication in my fields of research. I decided to put it in a GNU GPL v3 to let the possibility for everyone to use it and expand it. The code is not ideal and there are certainly some errors so please let me know about them by opening a Github issue and I will see what I can do. Alternatively, you can also contribute to the project by creating pull requests that will be reviewed and merged in the main code.

## Next features
Here are some ideas that I haven't implemented yet but which could be in the next weeks/months.
 - Add other publication streams (journals/other archives/...)
 - (If you have an idea, create an issue and I'll add it to this list)

## License
Copyright 2020, I. Rojkov.

Licensed under [GNU General Public License version 3](https://opensource.org/licenses/GPL-3.0).