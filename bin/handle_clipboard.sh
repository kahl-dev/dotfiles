#!/usr/bin/env bash

input="$1"

# Check if it's a URL
if [[ "$input" =~ ^http ]]; then
	# Handle URL on local machine
	if [ "$(uname)" = 'Darwin' ]; then
		open "$input"
	else
		# Fallback to using OSC 52 sequence
		echo -ne "\033]52;c;$(echo -n "$input" | base64)\007"
	fi
else
	# Handle non-URL string
	if [ "$(uname)" = 'Darwin' ]; then
		echo -n "$input" | pbcopy
	else
		# Fallback to using OSC 52 sequence
		echo -ne "\033]52;c;$(echo -n "$input" | base64)\007"
	fi
fi
