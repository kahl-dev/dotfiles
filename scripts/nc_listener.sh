#!/bin/bash

# Specify the log file path
log_file="$HOME/Library/Logs/com.kahl_dev.nc_listener"

# A simple regex to check for a URL-like string.
# This is not fully accurate, but should work for most common URLs.
url_regex='^https?://'

while read line; do
	echo "$line" | pbcopy
	echo "$(date) - Received: $line - Copied to clipboard" >>$log_file
	if [[ $line =~ $url_regex ]]; then
		open "$line"
		echo "$(date) - Opened in browser: $line" >>$log_file
	fi
done
