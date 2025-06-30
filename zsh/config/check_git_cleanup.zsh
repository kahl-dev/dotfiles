# Initialize variables to store the last checked directory and last reminder time
LAST_CLEANUP_DIR=""
LAST_REMINDER_TIME=0

function check_git_cleanup() {
  # Only run in interactive shells
  [[ $- == *i* ]] || return
  
  # Check if we're in a Git repository
  if [ -d .git ]; then
    # Get the top-level path of the current Git repository
    REPO_PATH=$(git rev-parse --show-toplevel 2>/dev/null)
    CLEANUP_LOG="$HOME/.local/share/git-cleanup/cleanup-log"
    CURRENT_TIME=$(date +%s)
    TWO_WEEKS_IN_SECONDS=$((14 * 24 * 60 * 60)) # Two weeks in seconds

    # Check if we've moved to a new directory or if two weeks have passed since the last reminder
    if [ "$REPO_PATH" != "$LAST_CLEANUP_DIR" ] || [ $((CURRENT_TIME - LAST_REMINDER_TIME)) -ge $TWO_WEEKS_IN_SECONDS ]; then
      # Update LAST_CLEANUP_DIR to the current repository path
      LAST_CLEANUP_DIR="$REPO_PATH"
      LAST_REMINDER_TIME=$CURRENT_TIME

      # Check if the repository has a cleanup record
      LAST_CLEANUP=$(grep "^$REPO_PATH" "$CLEANUP_LOG" | awk '{print $2, $3}')

      if [ -n "$LAST_CLEANUP" ]; then
        # Calculate time difference in seconds between LAST_CLEANUP and now
        LAST_CLEANUP_DATE=$(date -d "$LAST_CLEANUP" +%s 2>/dev/null)
        DIFF_DAYS=$(((CURRENT_TIME - LAST_CLEANUP_DATE) / (60 * 60 * 24)))

        if [ "$DIFF_DAYS" -ge 14 ]; then
          echo "⚠️  Reminder: It's been over two weeks since the last cleanup for this repository."
          echo "Run 'git-cleanup' to perform a cleanup."
        fi
      else
        echo "⚠️  No cleanup record found for this repository. Consider running 'git-cleanup' for initial cleanup."
      fi
    fi
  fi
}

# Hook function into Zsh prompt to run on directory change or before each prompt
autoload -Uz add-zsh-hook
add-zsh-hook chpwd check_git_cleanup  # Run check on directory change
add-zsh-hook precmd check_git_cleanup # Run check before each prompt
