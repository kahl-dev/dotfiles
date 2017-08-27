#!/bin/bash

# put all global packages in npm-nvm/default-packages to install in each nvm version

if [ "$(uname)" = "Darwin" ]; then

  packages="generator-alfred alfred-coolors alfred-fkill alfred-messages alfred-notifier alfred-updater alfred-emoj"

  # Alfred development
  npm install $packages --global

fi
