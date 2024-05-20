# Define constants for GitHub CLI setup
TIMESTAMP_FILE_GH="$HOME/.config/dot/.zsh_check_gh"
INTERVAL_GH=2630016  # Approximately one week

# Function to check if it's time to run the setup
function should_run_check() {
  local timestamp_file=$1
  local interval=$2
  local current_time=$(date +%s)
  local last_modified=$(stat -c %Y "$timestamp_file" 2>/dev/null || echo 0)
  (( current_time - last_modified > interval ))
}

# Lazy load function for GitHub CLI 'gh'
function lazy_gh_setup() {
  if should_run_check "$TIMESTAMP_FILE_GH" "$INTERVAL_GH"; then
    # Initialize or reinitialize 'gh' here
    if ! gh auth status > /dev/null 2>&1; then
      echo "You are not logged into any GitHub hosts. Initiating login..."
      gh auth login --web -h github.com
    fi

    # Ensure Copilot is installed
    if ! gh copilot > /dev/null 2>&1; then
      echo "gh copilot is not available, installing..."
      gh extension install github/gh-copilot --force
    fi

    # Set or refresh environment variables, aliases, etc.
    eval "$(gh copilot alias -- zsh)"

    # Update the timestamp to mark this setup
    touch "$TIMESTAMP_FILE_GH"
  fi

  # Define functions
  function gh_copilot_shell_suggest {
      gh copilot suggest -t shell "$*"
  }
  function gh_copilot_gh_suggest {
      gh copilot suggest -t gh "$*"
  }
  function gh_copilot_git_suggest {
      gh copilot suggest -t git "$*"
  }

  # Set aliases
  alias '??'=gh_copilot_shell_suggest
  alias 'gh?'=gh_copilot_gh_suggest
  alias 'git?'=gh_copilot_git_suggest
}

# Add lazy_gh_setup to precmd functions to ensure it runs when needed
autoload -Uz add-zsh-hook
add-zsh-hook precmd lazy_gh_setup
