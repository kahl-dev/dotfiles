#!/bin/bash

session_to_kill=$(tmux list-sessions -F "#{session_name}" | fzf --prompt="Select a session to kill: ")
[ -n "$session_to_kill" ] && tmux kill-session -t "$session_to_kill"
