# # Add fzf fuzzy finder to zsh
# # Doc: https://github.com/junegunn/fzf

if [ ! -d "$DOTFILES/bin/fzf" ]; then
  git clone --depth=1 https://github.com/junegunn/fzf.git ${DOTFILES}/bin/fzf
  $DOTFILES/bin/fzf/install --no-completion --no-key-bindings --no-update-rc
fi

if [ -d "$DOTFILES/bin/fzf" ]; then
  export FZF_BASE="$DOTFILES/bin/fzf"
  export FZF_INIT_OPTS='--border --cycle --reverse --no-height'
  export FZF_DEFAULT_OPTS="$FZF_INIT_OPTS"
  export FZF_DEFAULT_COMMAND='rg --files'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_VIM='~/.fzf'

  plugins+=(fzf)

  alias falias='alias | fzf'

  # This tool is designed to help you use git more efficiently. It's lightweight and easy to use.
  # Doc: https://github.com/wfxr/forgit
  if [ ! -d "$ZSH_CUSTOM/plugins/forgit" ]; then
    git clone https://github.com/wfxr/forgit.git $ZSH_CUSTOM/plugins/forgit
  fi
  plugins+=(forgit)
fi
