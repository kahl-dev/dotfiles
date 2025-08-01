# shellcheck shell=bash
# Tmuxinator aliases and functions

# Tmuxinator shortcut alias
alias mux='tmuxinator'

# Start simple Claude session (current folder name)
alias muxc='tmuxinator start -p claude'

# Start Claude TYPO3 development session (current folder name)  
alias muxct='tmuxinator start -p claude-typo3'

# Interactive session manager for existing sessions
_muxs() {
  local session
  session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --prompt="Select tmux session: " --height=40% --reverse)
  
  if [ -n "$session" ]; then
    tmux attach-session -t "$session"
  fi
}

alias muxs='_muxs'