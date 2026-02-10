# Initialize variables to store the last checked directory and last reminder time
LAST_CLEANUP_DIR=""
LAST_REMINDER_TIME=0

# Load zsh/datetime for $EPOCHSECONDS (no external 'date' dependency)
zmodload zsh/datetime 2>/dev/null

function check_git_cleanup() {
  # Only run in interactive shells
  [[ $- == *i* ]] || return

  # Check if we're in a Git repository
  if [[ -d .git ]]; then
    local repo_path cleanup_log current_time two_weeks
    repo_path=$(git rev-parse --show-toplevel 2>/dev/null) || return
    cleanup_log="$HOME/.local/share/git-cleanup/cleanup-log"
    current_time=$EPOCHSECONDS
    two_weeks=$((14 * 24 * 60 * 60))

    # Check if we've moved to a new directory or if two weeks have passed since the last reminder
    if [[ "$repo_path" != "$LAST_CLEANUP_DIR" ]] || (( current_time - LAST_REMINDER_TIME >= two_weeks )); then
      LAST_CLEANUP_DIR="$repo_path"
      LAST_REMINDER_TIME=$current_time

      # Check if the repository has a cleanup record
      [[ -f "$cleanup_log" ]] || {
        echo "⚠️  No cleanup record found for this repository. Consider running 'git-cleanup' for initial cleanup."
        return
      }

      local -a cleanup_matches
      local last_cleanup_line last_cleanup_date last_cleanup_epoch diff_days
      cleanup_matches=( "${(M@)${(f)"$(<$cleanup_log)"}:#${repo_path} *}" )
      # Take last entry if multiple exist for same repo
      last_cleanup_line="${cleanup_matches[-1]}"

      if [[ -n "$last_cleanup_line" ]]; then
        # Extract date portion (everything after repo path + space)
        last_cleanup_date="${last_cleanup_line#${repo_path} }"

        # Parse date to epoch using strftime -r (ZSH builtin, no external 'date -d')
        strftime -r -s last_cleanup_epoch "%Y-%m-%d %H:%M:%S" "$last_cleanup_date" 2>/dev/null || {
          # Fallback: try without time component
          strftime -r -s last_cleanup_epoch "%Y-%m-%d" "$last_cleanup_date" 2>/dev/null || return
        }

        diff_days=$(( (current_time - last_cleanup_epoch) / (60 * 60 * 24) ))

        if (( diff_days >= 14 )); then
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
add-zsh-hook chpwd check_git_cleanup
add-zsh-hook precmd check_git_cleanup
