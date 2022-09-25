# # Add fzf fuzzy finder to zsh
# # Doc: https://github.com/junegunn/fzf

if [ ! -d "$HOME/.fzf" ]; then
  git clone --depth=1 https://github.com/junegunn/fzf.git $HOME/.fzf
  $HOME/.fzf/install --completion --key-bindings --no-update-rc --no-bash --no-fish
fi

if [ -d "$HOME/.fzf" ]; then
  export FZF_INIT_OPTS='--border --cycle --reverse --no-height'
  export FZF_DEFAULT_OPTS="$FZF_INIT_OPTS"
  export FZF_DEFAULT_COMMAND='rg --files'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_VIM="$HOME/.fzf"

  plugins+=(fzf)

  alias falias='alias | fzf'

  # This tool is designed to help you use git more efficiently. It's lightweight and easy to use.
  # Doc: https://github.com/wfxr/forgit
  # export FORGIT_NO_ALIASES=false


  zsh_add_plugin "wfxr/forgit"
  # if [ ! -d "$ZSH_CUSTOM/plugins/forgit" ]; then
  #   git clone https://github.com/wfxr/forgit.git $ZSH_CUSTOM/plugins/forgit
  # fi

  export forgit_log=fglog
  export forgit_diff=fgd
  export forgit_add=fgaa
  export forgit_reset_head=fgrh
  export forgit_ignore=fgi
  export forgit_checkout_file=fgcf
  export forgit_checkout_branch=fgcb
  export forgit_branch_delet=fgbd
  export forgit_checkout_tag=fgct
  export forgit_checkout_commit=fgco
  export forgit_revert_commit=fgrc
  export forgit_clean=fgclean
  export forgit_stash_show=fgss
  export forgit_cherry_pick=fgcp
  export forgit_rebase=fgrb
  export forgit_fixup=fgfu

  plugins+=(forgit)


fi
