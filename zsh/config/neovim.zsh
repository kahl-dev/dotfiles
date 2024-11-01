if command_exists nvim; then
  export EDITOR="nvim"
  export VISUAL="nvim"

  if command_exists fnm; then
    export NEOVIM_NODE_HOST=$(fnm exec --using lts-latest  -- which node)
  fi

  alias vimdiff='nvim -d'
fi

# check if file /home/kahl/.local/state/nvim/log is greater that 1GB and if so echo a warning
if [ -f /home/kahl/.local/state/nvim/log ]; then
  if [ $(stat -c %s /home/kahl/.local/state/nvim/log) -gt 1073741824 ]; then # 1GB
    echo "nvim log file is greater than 1GB"
  fi
fi
