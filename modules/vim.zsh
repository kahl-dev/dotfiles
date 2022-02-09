export EDITOR="vim"
export VISUAL="vim"

alias vi='vim'

if _exists nvim; then
  export EDITOR="vim"
  export VISUAL="vim"

  # alias vim='nvm use default && nvim'
  alias vim='fnm exec --using=v16 nvim'

  mkdir -p ~/.config/nvim
  ln -sf ~/.vim/nvimrc ~/.config/nvim/init.vim
fi

plugins+=(vi-mode)
