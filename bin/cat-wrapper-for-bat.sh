#!/bin/bash

# Check if stdin (0) is attached to a terminal
if [ -t 0 ]; then
	# Check if bat is installed by trying to locate its command.
	# If not found, proceed with cat as usual.
	if command -v bat &>/dev/null; then
		# Prompt the user if they want to use bat instead.
		echo -n "Do you want to use bat instead of cat? (y/n) "
		read -n 1 -r
		echo # Move to a new line.

		if [[ $REPLY =~ ^[Yy]$ ]]; then
			bat "$@"
			exit
		fi
	fi
fi

# Fallback to using cat.
cat "$@"
