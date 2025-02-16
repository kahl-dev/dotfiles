#!/bin/bash

sudo cp ./dev.kahl.kanata.plist /Library/LaunchDaemons/
sudo launchctl load /Library/LaunchDaemons/dev.kahl.kanata.plist
sudo launchctl start dev.kahl.kanata
