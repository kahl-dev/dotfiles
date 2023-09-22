#!/bin/bash
#NAME: Switch tmux session

# List sessions using fzf
session_to_switch=$(tmux list-sessions -F "#{session_name}" | fzf --prompt="Select a session: ")

# Switch to the selected session, if one is chosen
if [ -n "$session_to_switch" ]; then
	tmux switch-client -t "$session_to_switch"
fi
