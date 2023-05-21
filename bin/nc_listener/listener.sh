#!/usr/bin/env bash

# Specify the log file path
log_file="$HOME/log.txt"

# Function to log a message, if logging is enabled
function log_message() {
	if [ "$logging_enabled" = "true" ]; then
		echo "$(date) - $1" >>$log_file
	fi
}

# Function to encode and prefix
function encode_and_prefix() {
	local input="$1"
	local prefix="$2"

	echo "input: $input"
	# Check if the input starts with "base64::"
	if [[ "$input" == base64::* ]]; then
		# The input is base64 encoded, so remove the "base64::" prefix
		encoded=${input#base64::}
	else
		# The input is not base64 encoded, so encode it
		encoded=$(echo -n "$input" | base64 -w0)
	fi

	full_encoded=$(echo -n "${prefix}::${encoded}")

	log_message "Encoded: $full_encoded"

	echo "$full_encoded"
}
