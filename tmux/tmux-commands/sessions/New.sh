#!/bin/bash

# Prompt for session name
read -p "Enter new session name: " session_name

# If no session name is provided, set a default name (e.g., "new-session")
if [ -z "$session_name" ]; then
	session_name="new-session"
fi

# Create a new detached tmux session with the provided name
tmux new-session -d -s "$session_name"

# Switch to the new session
tmux switch-client -t "$session_name"
