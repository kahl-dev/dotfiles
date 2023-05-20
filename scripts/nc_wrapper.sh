#!/bin/sh

nc -lk ${NC_LISTENER_HOST_PORT:-22222} | /Users/pk/.dotfiles/scripts/nc_listener.sh
