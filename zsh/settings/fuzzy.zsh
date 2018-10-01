# Add fzf fuzzy finder to zsh
# https://github.com/junegunn/fzf
if which fzf &> /dev/null; then

  if which fd &> /dev/null; then

    # Setting fd as the default source for fzf
    export FZF_DEFAULT_COMMAND='fd --type f'
  fi

  initFzf() {
    [ ! -f ~/.fzf.zsh ] && $(brew --prefix)/opt/fzf/install
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
  }

  after_init+=(initFzf)

  # Add interactive cd for fzf
  # https://github.com/changyuheng/zsh-interactive-cd
  plugins+=(zsh-interactive-cd)

  # Add enhanced
  # https://github.com/b4b4r07/enhancd
  initEnhanced() {
    # source $ZSH_CUSTOM/plugins/enhancd/init.sh
  }

  after_init+=(initEnhanced)
fi
