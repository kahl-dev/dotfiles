#!/usr/bin/env bash

# Wrapper script to run lit-info urls from tmux
# Gets the current pane's path and extracts URLs directly to avoid fzf-tmux conflict

# Get the current pane's working directory
current_dir="${1:-$(pwd)}"

# Find git root from input directory
_find_git_root() {
    local dir="$1"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.git" ]] || [[ -f "$dir/.git" ]]; then
            echo "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    return 1
}

# Find git root
project_dir=$(_find_git_root "$current_dir")

if [[ -z "$project_dir" ]]; then
    echo "❌ Not inside a git repository"
    read -n 1 -s -r -p "Press any key to exit..."
    exit 1
fi

# Check if it's a TYPO3 project
if [[ ! -f "$project_dir/bootstrap.conf" ]] && [[ ! -f "$project_dir/Makefile" ]]; then
    echo "❌ Not a TYPO3 project (no bootstrap.conf or Makefile found)"
    read -n 1 -s -r -p "Press any key to exit..."
    exit 1
fi

echo "🔗 Fetching project URLs from $project_dir..."

cd "$project_dir" 2>/dev/null || {
    echo "❌ Cannot access project directory"
    read -n 1 -s -r -p "Press any key to exit..."
    exit 1
}

# Extract URLs from make sitebase, fallback to sitebase.sh directly
urls=""
if [[ -f "Makefile" ]] && grep -q "sitebase:" Makefile 2>/dev/null; then
    urls=$(make sitebase 2>/dev/null | grep "Site base:" | sed -E 's/Site base: \x1b\[[0-9;]*m//g' | sed -E 's/\x1b\[[0-9;]*m//g' | sed 's/^Site base: *//')
elif [[ -f "tools/sitebase.sh" ]]; then
    urls=$(./tools/sitebase.sh 2>/dev/null | grep "Site base:" | sed -E 's/Site base: \x1b\[[0-9;]*m//g' | sed -E 's/\x1b\[[0-9;]*m//g' | sed 's/^Site base: *//')
else
    echo "❌ No sitebase command or script found"
    read -n 1 -s -r -p "Press any key to exit..."
    exit 1
fi

if [[ -z "$urls" ]]; then
    echo "❌ No URLs found. You might need to run 'make install' first."
    read -n 1 -s -r -p "Press any key to exit..."
    exit 1
fi

# Use regular fzf (not fzf-tmux) since we're already in a tmux popup
selected_url=""
if command -v fzf >/dev/null 2>&1; then
    selected_url=$(echo "$urls" | fzf --prompt="Select URL to open: " --reverse --border)
else
    echo "⚠️  fzf not found, using first URL"
    selected_url=$(echo "$urls" | head -1)
fi

if [[ -z "$selected_url" ]]; then
    echo "No URL selected"
    read -n 1 -s -r -p "Press any key to exit..."
    exit 0
fi

echo "🌐 Opening: $selected_url"

# Try different browser commands in order of preference
if command -v ropen >/dev/null 2>&1; then
    ropen "$selected_url"
elif command -v open >/dev/null 2>&1; then
    open "$selected_url"
elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$selected_url"
elif command -v sensible-browser >/dev/null 2>&1; then
    sensible-browser "$selected_url"
else
    echo "❌ No browser command found. Please install ropen, open, xdg-open, or sensible-browser"
    echo "URL: $selected_url"
    read -n 1 -s -r -p "Press any key to exit..."
    exit 1
fi