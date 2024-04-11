# Fast and simple Node.js version manager, built in Rust
# https://github.com/Schniz/fnm

if _exec_exists fnm; then
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
