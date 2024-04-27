#!/bin/bash

if [ -t 0 ]; then
	echo -n "Do you want to use bat instead of cat? (y/n) "
	read -n 1 -r
	echo

	if [[ $REPLY =~ ^[Yy]$ ]]; then
		bat "$@"
		exit
	fi
fi
