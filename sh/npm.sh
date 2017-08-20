#!/bin/bash

npm i -g prettier

if [ "$(uname)" = "Darwin" ]; then

  # Alfred development
  npm i -g generator-alfred

  # Alfred workflows
  npm i -g alfred-coolors
  npm i -g alfred-fkill
  npm i -g alfred-messages
  npm i -g alfred-notifier
  npm i -g alfred-updater
  npm i -g alfred-emoj

fi
