# -----------------------------------------------------------------------------
# This file is sourced for login shell sessions.
# Place your login-specific environment variables and commands here.
# It is sourced after ~/.zshenv but before ~/.zshrc.
# -----------------------------------------------------------------------------

source $DOTFILES/zsh/utils.zsh

if is_macos && path_exists "/opt/homebrew/bin/brew"; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi

if path_exists "/home/linuxbrew/.linuxbrew/bin"; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  export PATH="$(brew --prefix)/opt/python/libexec/bin:${PATH}"
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi



# if command_exists rbenv; then
#   eval "$(rbenv init - zsh)"
#   FPATH=~/.rbenv/completions:"$FPATH"
#   export PATH="$HOME/.rbenv/bin:$PATH"
# fi

if path_exists "$HOME/.local/bin"; then
  export PATH="$PATH:$HOME/.local/bin"
fi

if path_exists "$HOME/go/bin"; then
  export PATH="$PATH:$HOME/go/bin"
fi

if path_exists "$HOME/.dotfiles/bin/ai-utils"; then
  export PATH="$HOME/.dotfiles/bin/ai-utils:$PATH"
fi

# Remove git-up and git-sync binaries from PATH by creating shadow directory
_setup_git_shadow() {
  local shadow_dir="$HOME/.local/bin/git-shadow"
  mkdir -p "$shadow_dir"
  
  # Create shadow scripts that use our git aliases instead
  cat > "$shadow_dir/git-up" << 'EOF'
#!/bin/bash
exec git pull --rebase --autostash "$@"
EOF
  
  cat > "$shadow_dir/git-sync" << 'EOF'
#!/bin/bash
exec git pull --rebase --autostash "$@"
EOF
  
  chmod +x "$shadow_dir/git-up" "$shadow_dir/git-sync"
  
  # Add shadow directory to beginning of PATH
  export PATH="$shadow_dir:$PATH"
}

# Setup git binary shadowing
_setup_git_shadow

# Source local zshrc in login shells
if [ -f "$HOME/.dotfiles-local/zshrc" ]; then
  source "$HOME/.dotfiles-local/zshrc"
elif [ -f "$HOME/.zshrc-local" ]; then
  source "$HOME/.zshrc-local"
fi
