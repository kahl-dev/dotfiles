# shellcheck shell=bash
# Tmuxinator aliases and functions

# Tmuxinator shortcut alias
alias mux='tmuxinator'

# Start simple Claude session (current folder name)
alias muxc='tmuxinator start -p claude'

# Start Claude TYPO3 development session (current folder name)  
alias muxct='tmuxinator start -p claude-typo3'

# Interactive tmuxinator project starter
_muxs() {
  local project
  project=$(tmuxinator list | tail -n +2 | tr ' ' '\n' | grep -v '^$' | fzf --prompt="Select tmuxinator project to start: " --height=40% --reverse)
  
  if [ -n "$project" ]; then
    tmuxinator start "$project"
  fi
}

alias muxs='_muxs'