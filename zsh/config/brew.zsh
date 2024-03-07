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

  # Example usage for the Ruby check
  TIMESTAMP_FILE_RUBY="$HOME/.config/dot/.zsh_check_ruby"
  INTERVAL_RUBY=2630016  # Approximately one month

  # Define a file to store the Ruby path
  RUBY_PATH_FILE="$HOME/.config/dot/.zsh_ruby_path"


  # Ensure the .config directory exists
  if ! _is_path_exists "$HOME/.config/dot/"; then
    mkdir -p "$HOME/.config/dot/"
  fi

  # Check if Ruby is installed via brew and the path file does not exist
  if [ ! -f "$RUBY_PATH_FILE" ] && type brew &>/dev/null && brew list ruby &>/dev/null; then
    # Store the Ruby path in the file
    brew --prefix ruby > "$RUBY_PATH_FILE"
  fi

  if [ -f "$RUBY_PATH_FILE" ]; then
    # Read the Ruby path from the file
    RUBY_PATH=$(cat "$RUBY_PATH_FILE")/bin
    export PATH="$RUBY_PATH:$PATH"

    if should_run_check "$TIMESTAMP_FILE_RUBY" "$INTERVAL_RUBY"; then
      echo 'Checking for Ruby once a month...'

      # Check if bashly is installed, install if not
      if ! gem list -i bashly &>/dev/null; then
        echo "bashly is not installed. Installing now..."
        gem install bashly
	      gem install colorls
      fi
    fi
  else
    echo "Ruby not installed via Homebrew or not found."
  fi
fi
