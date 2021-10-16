# Add fzf fuzzy finder to zsh
# Doc: https://github.com/junegunn/fzf
# Doc: https://github.com/Zsh-Packages/fzf

initFzf() {
  if [ ! -d "$HOME/.fzf" ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install
  fi

  [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
  source ~/.fzf/shell/completion.zsh
  source ~/.fzf/shell/key-bindings.zsh

  bindkey "ç" fzf-cd-widget

  export FZF_INIT_OPTS='--border --cycle --reverse --no-height'
  export FZF_DEFAULT_OPTS="$FZF_INIT_OPTS"
  export FZF_DEFAULT_COMMAND='rg --files'
  # export FZF_CTRL_T_OPTS="--preview '(highlight -O ansi -l {} 2> /dev/null || cat {} || tree -C {}) 2> /dev/null | head -200'"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_VIM='~/.fzf'

  alias falias='alias | fzf'
}
# zinit wait lucid as=program pick="bin/(fzf|fzf-tmux)" \
#     atload"initFzf" \
#     atclone="cp shell/completion.zsh _fzf_completion;" \
#     src'shell/key-bindings.zsh' \
#     make="!PREFIX=$ZPFX install" for \
#         junegunn/fzf

zinit wait'1' lucid atinit'initFzf' nocd for /dev/null

zinit ice lucid
zinit light fnune/base16-fzf

# This tool is designed to help you use git more efficiently. It's lightweight and easy to use.
# Doc: https://github.com/wfxr/forgit
zinit ice wait lucid
zinit light wfxr/forgit
