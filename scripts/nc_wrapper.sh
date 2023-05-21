#!/bin/sh

nc -lk ${NC_LISTENER_HOST_PORT:-20502} | /Users/pk/.dotfiles/scripts/nc_listener.sh
