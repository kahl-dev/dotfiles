# Add fzf fuzzy finder to zsh
# https://github.com/junegunn/fzf
if which fzf &> /dev/null; then

  if which fd &> /dev/null; then

    # Use fd (https://github.com/sharkdp/fd) instead of the default find
    # command for listing path candidates.
    # - The first argument to the function ($1) is the base path to start traversal
    # - See the source code (completion.{bash,zsh}) for the details.
      _fzf_compgen_path() {
        fd --hidden --follow --exclude ".git" . "$1"
      }

    # Use fd to generate the list for directory completion
    _fzf_compgen_dir() {
      fd --type d --hidden --follow --exclude ".git" . "$1"
    }
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
    source $ZSH_CUSTOM/plugins/enhancd/init.sh
  }

  after_init+=(initEnhanced)
fi
