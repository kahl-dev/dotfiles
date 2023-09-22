if _exec_exists nvim; then
  export EDITOR="nvim"
  export VISUAL="nvim"

  function v() {
    if _exec_exists fnm; then
      command fnm exec --using=lts-latest nvim "$@"
    else
      nvim "$@"
    fi
  }

  alias nvim='v'
  alias vim='v'
  alias vimdiff='nvim -d'
fi

