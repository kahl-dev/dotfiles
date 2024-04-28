if _is_path_exists "$DOTFILES/bin/nvim/bin/"; then
  export PATH="$DOTFILES/bin/nvim/bin:$PATH"
fi

if _exec_exists nvim; then
  export EDITOR="nvim"
  export VISUAL="nvim"

  function v() {
    if _exec_exists fnm; then
      command fnm exec --using=lts-latest nvim "$@"
    else
      nvim "$@"
    fi
  }

  alias nvim='v'
  alias vim='v'
  alias vimdiff='nvim -d'
fi

# check if file /home/kahl/.local/state/nvim/log is greater that 1GB and if so echo a warning
if [ -f /home/kahl/.local/state/nvim/log ]; then
  if [ $(stat -c %s /home/kahl/.local/state/nvim/log) -gt 1073741824 ]; then # 1GB
    echo "nvim log file is greater than 1GB"
  fi
fi
