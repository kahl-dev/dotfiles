# Function to update the timestamp
update_timestamp() {
	local timestamp_file=$1
	date +%s >"$timestamp_file"
}

# Function to check if it's time to run the script and update the timestamp
# Arguments:
# $1 - Path to the timestamp file
# $2 - Interval in seconds
should_run_check() {
	local timestamp_file=$1
	local interval=${2:-86400} # Default to 24 hours if not specified

	if [[ ! -f "$timestamp_file" ]]; then
		update_timestamp "$timestamp_file"
		return 0 # file doesn't exist, should run
	fi

	local last_run=$(cat "$timestamp_file")
	local current_time=$(date +%s)
	if ((current_time - last_run > interval)); then
		update_timestamp "$timestamp_file"
		return 0 # interval exceeded, should run
	fi

	return 1 # should not run
}
