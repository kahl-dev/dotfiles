# Add fzf fuzzy finder to zsh
# https://github.com/junegunn/fzf

if which fd &> /dev/null; then

  # Setting fd as the default source for fzf
  export FZF_DEFAULT_COMMAND='fd --type f'

fi

fzfInit() {
  [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
}

after_init+=(fzfInit)
