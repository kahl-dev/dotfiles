#!/bin/bash

# Specify the log file path
log_file="$HOME/Library/Logs/com.kahl_dev.nc_listener"

# A simple regex to check for a URL-like string.
# This is not fully accurate, but should work for most common URLs.
url_regex='^https?://[-A-Za-z0-9+&@#/%?=~_|!:,.;]*[-A-Za-z0-9+&@#/%=~_|]$'

while IFS= read -r line; do
	# Decode the Base64 input
	block=$(echo "$line" | base64 --decode)
	echo "$block" | pbcopy
	echo "$(date) - Received: $block - Copied to clipboard" >>$log_file
	if [[ $block =~ $url_regex ]]; then
		open "$block"
		echo "$(date) - Opened in browser: $block" >>$log_file
	fi
done
