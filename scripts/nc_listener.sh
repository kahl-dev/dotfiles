#!/bin/bash

# Specify the log file path
log_file="$HOME/Library/Logs/com.kahl_dev.nc_listener"

echo "$(date) - Starting nc_listener" >>$log_file

# A simple regex to check for a URL-like string.
# This is not fully accurate, but should work for most common URLs.
url_regex='^https?://[-A-Za-z0-9+&@#/%?=~_|!:,.;]*[-A-Za-z0-9+&@#/%=~_|]$'

while IFS= read -r line; do
	echo "$(date) - Received: $line" >>$log_file

	# Extract the command and block from the decoded string
	command=${line%%::*}
	block=${line#*::}

	decoded_block=$(echo "$block" | base64 --decode)

	echo "$(date) - command: $command" >>$log_file
	echo "$(date) - content: $decoded_block" >>$log_file

	case $command in
	yank)
		echo "$decoded_block" | pbcopy
		echo "$(date) - Copied to clipboard: $decoded_block" >>$log_file
		;;
	open)
		if [[ $decoded_block =~ $url_regex ]]; then
			open "$decoded_block"
			echo "$(date) - Opened in browser: $decoded_block" >>$log_file
		fi
		;;
	*)
		echo "$(date) - Unknown command: $command" >>$log_file
		;;
	esac
done

echo "$(date) - End of nc_listener" >>$log_file
