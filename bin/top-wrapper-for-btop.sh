#!/bin/bash

echo -n "Do you want to use btop instead of top? (y/n) "
read -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
	btop
	exit
fi
