export EDITOR="vim"
export VISUAL="vim"

# alias vi='vim'

if _exists nvim; then
  export EDITOR="vim"
  export VISUAL="vim"

  if [ ! -d "$HOME/.config/nvim" ]; then
    ln -s "$DOTFILES/nvim" "$HOME/.config/nvim"
  fi

  # alias vim='nvm use default && nvim'
  # alias vim='fnm exec --using=v16 nvim'

  function vim() {
    command fnm exec --using=v16 nvim "$@"
  }


fi

plugins+=(vi-mode)
