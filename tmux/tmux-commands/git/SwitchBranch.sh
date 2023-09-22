#!/bin/bash
#NAME: Switch Branches

# Function to get branch details
get_branch_details() {
	branch="$1"
	# Using '||' as a delimiter between different pieces of information
	git log -1 --format="%aI || %an" "$branch"
}

# Step 1: Check if we are in a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	echo "Not in a git repository."
	exit 1
fi

# Step 2: Fetch updates
git fetch

# Step 3: Get local and remote branches
local_branches=$(git for-each-ref --format '%(refname:short)' refs/heads | sort)
remote_branches=$(git for-each-ref --format '%(refname:short)' refs/remotes | grep -v '/HEAD ' | sort)

# Step 4: Merge and filter branches
# Remove remote branches that have a corresponding local branch
unique_branches=$(comm -23 <(echo "$remote_branches") <(echo "$local_branches" | sed 's/^/origin\//'))

# Merge with local branches
all_branches=$(echo -e "$local_branches\n$unique_branches" | sort -u)

# Step 5: Get branch details and sort by date
sorted_branches=$(for branch in $all_branches; do
	details=$(get_branch_details "$branch")
	[ "$details" ] && echo "$details || $branch"
done | sort -r)

# Check which branches are fully merged into master/main
merged_into_master=""
merged_into_main=""
if git show-ref --verify --quiet refs/heads/master; then
	merged_into_master=$(git branch --merged master)
fi
if git show-ref --verify --quiet refs/heads/main; then
	merged_into_main=$(git branch --merged main)
fi

# Check which branches are fully merged into production
merged_into_production=""
if git show-ref --verify --quiet refs/heads/production; then
	merged_into_production=$(git branch --merged production)
fi

# Step 6: Prepare the data for fzf
fzf_input=$(while IFS="||" read -r line; do
	timestamp=$(echo "$line" | cut -d '|' -f 1 | xargs)
	author=$(echo "$line" | cut -d '|' -f 3 | xargs)
	branch=$(echo "$line" | cut -d '|' -f 5 | xargs)

	# Detect the operating system and format date accordingly
	if [[ "$OSTYPE" == "darwin"* ]]; then
		# macOS
		formatted_date=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "${date_time//:/}" "+%Y-%m-%d %H:%M")
	elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
		# Linux
		formatted_date=$(date -d "$date_time" '+%Y-%m-%d %H:%M')
	else
		# Unknown
		formatted_date="$date_time"
	fi

	# Flags for merged status, avoid tagging master, main, or production
	merged_flag=""
	if [[ $branch != "master" && $branch != "main" ]]; then
		[[ $merged_into_master =~ $branch ]] || [[ $merged_into_main =~ $branch ]] && merged_flag="M"
	fi
	if [[ $branch != "production" ]]; then
		[[ $merged_into_production =~ $branch ]] && merged_flag="${merged_flag}P"
	fi

	# Combine flags if any
	[ -n "$merged_flag" ] && merged_flag="[$merged_flag]"

	# If merged_flag is not empty, echo it followed by a space
	if [ ! -z "$merged_flag" ]; then
		# Echo the rest of the string
		echo "$merged_flag $branch - ($author - $formatted_date)"
	else
		echo "$branch - ($author - $formatted_date)"
	fi
done <<<"$sorted_branches")

# Step 7: Use fzf to select a branch
selected=$(echo "$fzf_input" | fzf --prompt="Switch to: ")
echo "$selected"

# Step 8: Check out the selected branch
if [ "$selected" ]; then
	branch=$(echo "$selected" | awk 'match($0, /([a-zA-Z0-9\/_-]+) - /) {print substr($0, RSTART, RLENGTH-3)}')
	# Check if this is a remote branch
	if [[ "$branch" == origin/* ]]; then
		local_branch_name=$(echo "$branch" | sed 's#origin/##') # Remove 'origin/' prefix
		# Create and checkout new local branch tracking the remote branch
		git switch --create "$local_branch_name" --track "$branch"
	else
		# For a local branch, just switch to it
		git switch "$branch"
	fi
else
	echo "No branch selected, no action taken."
fi
