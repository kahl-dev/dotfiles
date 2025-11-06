# -----------------------------------------------------------------------------
# Claude Config - AI utility scripts and tools
# -----------------------------------------------------------------------------
# Adds claude-config scripts directory to PATH for easy access to:
# - ai-fetch-jira: Fetch Jira ticket data
# - ai-fetch-screenshots: Retrieve recent screenshots
#
# These scripts are primarily used by Claude Code but can be run manually
# -----------------------------------------------------------------------------

if path_exists "$HOME/repos/claude-config/scripts"; then
  export PATH="$HOME/repos/claude-config/scripts:$PATH"
fi
