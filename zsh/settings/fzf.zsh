# Add fzf fuzzy finder to zsh
# https://github.com/junegunn/fzf

# Setting fd as the default source for fzf
export FZF_DEFAULT_COMMAND='fd --type f'

fzfInit() {
  [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
}

after_init+=(fzfInit)
