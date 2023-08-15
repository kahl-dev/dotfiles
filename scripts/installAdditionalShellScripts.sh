#!/bin/bash

source ./scripts/config.sh
source ./scripts/functions.sh

if _exec_exists pip3; then
	pip3 install pynvim
	pip3 install shell--gpt
fi
