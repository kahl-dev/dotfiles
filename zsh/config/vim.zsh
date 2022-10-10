if _exec_exists nvim; then
  export EDITOR="nvim"
  export VISUAL="nvim"

  # alias vim='nvm use default && nvim'
  # alias vim='fnm exec --using=v16 nvim'


  function v() {
    if _exec_exists fnm; then
      command fnm exec --using=v16 nvim "$@"
    else
      nvim "$@"
    fi
  }

  alias vim='v'
fi
