#!/bin/bash
#NAME: Search URLs (FZF)

# Function to extract URLs from given text
extract_urls() {
	echo "$1" | grep -o 'http\(s\)\?://[^ ]*'
}

# Initialize an empty variable to store all pane content
all_content=""

# Use process substitution to avoid the subshell issue
while read -r pane_id; do
	# Capture content of the pane
	pane_content=$(tmux capture-pane -J -p -t "$pane_id" -S -10000)

	# If neovim is running in the pane, get content of the neovim buffer
	if tmux list-panes -F '#{pane_current_command}' -t "$pane_id" | grep -q "nvim"; then
		nvim_content=$(tmux send-keys -t "$pane_id" ":w !cat" Enter)
		pane_content="$pane_content"$'\n'"$nvim_content"
	fi

	all_content="$all_content"$'\n'"$pane_content"
done < <(tmux list-panes -s -F '#{pane_id}')

# Extract URLs from all the captured content
all_urls=$(extract_urls "$all_content")

# Use fzf to select a URL
selected_url=$(echo "$all_urls" | tac | awk '!visited[$0]++' | fzf)

# @TODO: Send url to local clipboard or better open in browser
echo "$selected_url"
