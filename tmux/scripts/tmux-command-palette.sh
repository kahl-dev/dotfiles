#!/bin/bash

COMMAND_DIR="$HOME/.tmux/tmux-commands"

get_custom_name() {
	local file="$1"
	# Look for the #NAME: pattern anywhere in the file and extract the name
	local custom_name=$(awk '/^#NAME:/ {print substr($0, 8); exit}' "$file")
	echo "$custom_name"
}

get_commands() {
	local path="$1"
	local dir_path_rel="${path#$COMMAND_DIR/}" # Get the relative directory path
	local display_path=${dir_path_rel//\// / } # Add spaces around /

	for entry in "$path"/*; do
		if [ -d "$entry" ]; then
			get_commands "$entry" # Recurse into subdirectory
		else
			# Check if file is executable
			if [[ -x "$entry" ]]; then
				local filename=$(basename "$entry")
				local custom_name=$(get_custom_name "$entry")
				local display_name="${custom_name:-$filename}"

				# If we're directly in the COMMAND_DIR, don't show a path
				if [ "$path" == "$COMMAND_DIR" ]; then
					echo "$display_name,$filename"
				else
					# Use custom name if available, otherwise use filename
					local full_filename=${dir_path_rel}/$filename
					echo "${display_path} / $display_name,$full_filename"
				fi

			fi
		fi
	done
}

# List commands and pass to fzf
selected_output=$(get_commands "$COMMAND_DIR" | fzf --prompt='Choose: ' --with-nth=1 --delimiter=',')

# If fzf was exited with Esc, just exit the script gracefully
if [ $? -ne 0 ]; then
	exit 0
fi

# Extract real filename from the selected output
selected_filename=$(echo "$selected_output" | awk -F',' '{print $2}')

# Convert the selected filename back to its filesystem path format for execution
selected_command_path="$COMMAND_DIR/$selected_filename"

# If a command is selected, execute it
[ -n "$selected_command_path" ] && [ -f "$selected_command_path" ] && bash "$selected_command_path"
