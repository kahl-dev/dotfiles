if _exec_exists nvim; then
  export EDITOR="nvim"
  export VISUAL="nvim"

  # alias vim='nvm use default && nvim'
  # alias vim='fnm exec --using=v16 nvim'

  function v() {
    command fnm exec --using=v16 nvim "$@"
  }

  alias vi='v'
  alias vim='v'
fi
