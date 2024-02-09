#!/bin/bash

# Check if stdin (0) is attached to a terminal
if [ -t 0 ]; then
	# Check if tldr is installed by trying to locate its command.
	# If not found, proceed with man as usual.
	if command -v tldr &>/dev/null; then
		# Check if a tldr page exists for the command.
		# This attempts to get the tldr page without outputting it to check for existence.
		if tldr "$1" >/dev/null 2>&1; then
			# Prompt the user if they want to use tldr instead.
			echo -n "A tldr page exists for $1. Would you like to view it instead of the man page? (y/n) "
			read -n 1 -r
			echo # Move to a new line.

			if [[ $REPLY =~ ^[Yy]$ ]]; then
				tldr "$@"
				exit
			fi
		fi
	fi
fi

# Fallback to using man.
man "$@"
