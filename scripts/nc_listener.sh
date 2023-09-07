#!/bin/bash

# Specify the log file path
log_file="$HOME/Library/Logs/com.kahl_dev.nc_listener"

echo "$(date) - Starting nc_listener" >>$log_file

# A more comprehensive regex for detecting URLs
url_regex='\b((?:https?|ftp|file)://|www\.)[-A-Z0-9+&@#/%?=~_|!:,.;]*[-A-Z0-9+&@#/%=~_|]'

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
		/usr/local/bin/terminal-notifier -title "NC Listener" -subtitle "Copy to clipboard" -message "$decoded_block" -sound default -group "nc_listener"
		;;
	open)
		if [[ $decoded_block =~ $url_regex ]]; then
			open "$decoded_block"
			echo "$(date) - Opened in browser: $decoded_block" >>$log_file
			/usr/local/bin/terminal-notifier -title "NC Listener" -subtitle "Open in browser" -message "$decoded_block" -sound default -group "nc_listener"
		fi
		;;
	*)
		echo "$(date) - Unknown command: $command" >>$log_file
		;;
	esac
done

echo "$(date) - End of nc_listener" >>$log_file
