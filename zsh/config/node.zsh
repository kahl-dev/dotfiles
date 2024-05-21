# npm aliases and options

# Prevent intelephense from crashing
export NODE_OPTIONS=--max_old_space_size=8192

# install default packages from $DOTFILES/config/default-packages 
_npm_install_global_default() {
  cat $DOTFILES/config/default-packages | xargs npm install -g
}

# npm list without dependencies
alias npmLs="npm ls --depth=0 "$@" 2>/dev/null"
alias npmLsg="npm ls -g --depth=0 "$@" 2>/dev/null"
alias npmid=_npm_install_global_default

alias ya="yarn add"
alias y="yarn"
alias yb="yarn build"
alias yd="yarn dev"
alias yi="yarn"
alias yin="yarn install"

# Fast and simple Node.js version manager, built in Rust
# https://github.com/Schniz/fnm

if command_exists fnm; then
  eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"

  _fnm_install_latest() {
    fnm install --lts
    fnm use lts-latest
    fnm default lts-latest
    npmid

    export NODE_PATH=$FNM_DIR/aliases/lts-latest
    [[ -f "$NODE_PATH/lib/node_modules/yarn-completions/node_modules/tabtab/.completions/yarn.zsh" ]] && . "$NODE_PATH/lib/node_modules/yarn-completions/node_modules/tabtab/.completions/yarn.zsh"
  }

  _fnm_uninstall_all() {
    echo "Uninstalling all installed Node versions..."
    # Parsing 'fnm list' output to accurately extract version numbers
    for version in $(fnm list | grep -o 'v[0-9]*\.[0-9]*\.[0-9]*'); do
        echo "Uninstalling Node version $version"
        fnm uninstall "$version"
    done
  }

  if [ ! -L "$FNM_DIR/aliases/lts-latest" ]; then
    _fnm_install_latest
  fi

  alias fnm_uninstall_all=_fnm_uninstall_all
  alias fnm_install_latest=_fnm_install_latest
fi

# PNPM

export PNPM_HOME="$HOME/.local/share/pnpm"

case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# tabtab source for pnpm package
# uninstall by removing these lines
[[ -f ~/.config/tabtab/zsh/__tabtab.zsh ]] && . ~/.config/tabtab/zsh/__tabtab.zsh || true

if [ "$(pnpm config get store-dir)" != "$PNPM_HOME" ]; then
  echo "pnpm store not set to \$PNPM_HOME, setting now..."
  echo "pnpm config set store-dir \"$PNPM_HOME\""

  # Create path if it doesn't exist
  if [ ! -d "$PNPM_HOME" ]; then
    echo "Creating pnpm store directory at $PNPM_HOME"
    mkdir -p "$PNPM_HOME"
  fi

  pnpm config set store-dir "$PNPM_HOME"
fi
