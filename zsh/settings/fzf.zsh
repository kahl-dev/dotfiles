# Add fzf fuzzy finder to zsh
# https://github.com/junegunn/fzf
fzfInit() {
  [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
}

after_init+=(fzfInit)
