if command_exists nvim; then
  export EDITOR="nvim"
  export VISUAL="nvim"

  if command_exists mise; then
    # Use global mise node (not project-local) so Neovim/LSP always has a modern Node
    export NEOVIM_NODE_HOST="$(mise where node@lts 2>/dev/null)/bin/node"
  elif command_exists fnm; then
    export NEOVIM_NODE_HOST=$(fnm exec --using lts-latest -- which node)
  fi

  alias vimdiff='nvim -d'
fi

# ⚠️ Warn if nvim log file exceeds 1GB
if [[ -f "$HOME/.local/state/nvim/log" ]]; then
  zmodload zsh/stat 2>/dev/null
  nvim_log_size=0
  nvim_log_size=$(zstat -L +size "$HOME/.local/state/nvim/log" 2>/dev/null) || true
  if (( nvim_log_size > 1073741824 )); then
    echo "⚠️  nvim log file is greater than 1GB"
  fi
fi
