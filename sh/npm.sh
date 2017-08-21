#!/bin/bash

npm i -g --quiet prettier

if [ "$(uname)" = "Darwin" ]; then

  packages="generator-alfred alfred-coolors alfred-fkill alfred-messages alfred-notifier alfred-updater alfred-emoj"

  # Alfred development
  npm install $packages --global --quiet

fi
