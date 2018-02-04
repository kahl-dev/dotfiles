#!/bin/bash

# put all global packages in npm-nvm/default-packages to install in each nvm version

if [ "$(uname)" = "Darwin" ]; then

  // alfred-vimawesome alfred-youtube 
  packages="generator-alfred alfred-fkill alfred-messages alfred-notifier alfred-updater alfred-tyme alfred-bitly prettier eslint-config-airbnb eslint-plugin-jsx-a11y@5 eslint-plugin-react eslint-plugin-import eslint-plugin-html eslint-config-prettier eslint"

  # Alfred development
  npm install $packages --global

fi
