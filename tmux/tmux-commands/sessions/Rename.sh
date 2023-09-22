#!/bin/bash

read -p "Enter new session name: " session_name
tmux rename-session -t $TMUX_PANE "$session_name"
