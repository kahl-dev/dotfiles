#!/bin/bash

./scripts/stopServices.sh
launchctl load ~/Library/LaunchAgents/com.kahl_dev.nc_listener.plist
