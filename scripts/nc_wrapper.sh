#!/bin/sh

nc -lk ${NC_LISTENER_HOST_PORT:-20502} | $HOME/.dotfiles/scripts/nc_listener.sh
