#!/bin/bash

# Update npm
# npm i -g npm

# npm i -g prettier
# npm i -g prettier-eslint-cli

if [ "$(uname)" = "Darwin" ]; then

  # Alfred development
  npm i -g generator-alfred

  # Alfred workflows
  npm i -g alfred-coolors
  npm i -g alfred-fkill

  # npm i -g alfred-notifier
  # npm i -g alfred-updater
  # npm i -g alfy

fi
