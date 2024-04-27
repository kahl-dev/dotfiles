#!/bin/bash

if [ -t 0 ]; then
	if tldr "$1" >/dev/null 2>&1; then
		echo -n "A tldr page exists for $1. Would you like to view it instead of the man page? (y/n) "
		read -n 1 -r
		echo

		if [[ $REPLY =~ ^[Yy]$ ]]; then
			tldr "$@"
			exit
		fi
	fi
fi
