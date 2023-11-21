# linux only
if ! _is_raspberry; then
  if _is_linux; then
    if [ -d "/home/linuxbrew/.linuxbrew/bin" ]; then
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
      export PATH="$(brew --prefix)/opt/python/libexec/bin:${PATH}"
    fi

    if [ -d "/home/.linuxbrew/bin" ]; then
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
  fi

  # https://docs.brew.sh/Shell-Completion
  # Brew auto completion
  if _is_osx; then
    # export PATH="$(brew --prefix)/opt/python3@/bin:$PATH"
    # export PATH="$(brew --prefix)/sbin:$PATH"
    # export LDFLAGS="-L$(brew --prefix)/opt/python3@/lib"
    # export PKG_CONFIG_PATH="$(brew --prefix)/opt/python3@/lib/pkgconfig"
  fi

  if type brew &>/dev/null; then
    FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

    autoload -Uz compinit
    compinit
  fi

  # Check if Ruby is installed via brew
  if type brew &>/dev/null && brew list ruby &>/dev/null; then
      RUBY_PATH="$(brew --prefix ruby)/bin"
      export PATH="$RUBY_PATH:$PATH"

      # Check if bashly is installed, install if not
      if ! gem list -i bashly &>/dev/null; then
          echo "bashly is not installed. Installing now..."
          gem install bashly
      fi
  else
      echo "Ruby not installed via Homebrew or not found."
  fi

fi
