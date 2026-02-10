# -----------------------------------------------------------------------------
# Node.js version management and npm aliases
#
# fnm is the FALLBACK version manager — only initialized when mise is absent.
# mise is preferred and handles .nvmrc auto-switching via its chpwd hook.
#
# fnm is still needed because LIA/TYPO3 projects use handleNode.sh
# (in lia-package/.tools/) which runs inside Makefile subshells.
# These non-interactive subshells don't trigger mise's chpwd hook,
# so handleNode.sh falls back to fnm/nvm for version switching.
#
# --version-file-strategy=recursive: search parent directories for .nvmrc
# NOTE: --use-on-cd intentionally omitted — we define a guarded chpwd hook
# instead, to avoid "command not found: fnm" when PATH is transiently broken
#
# On Raspberry Pi, .zshrc adds /home/pi/.local/share/fnm to PATH before
# this file is sourced, so command_exists fnm succeeds here.
# -----------------------------------------------------------------------------

# Skip fnm initialization if mise is handling runtime versions
if ! command_exists mise && command_exists fnm; then
  # Fast and simple Node.js version manager, built in Rust
  # https://github.com/Schniz/fnm
  # Init WITHOUT --use-on-cd; we define our own guarded chpwd hook below
  # to avoid "command not found: fnm" when PATH is transiently broken
  eval "$(fnm env --version-file-strategy=recursive)"

  # Safe chpwd hook — silently skips when fnm is unreachable
  _fnm_autoload_hook() { (( $+commands[fnm] )) && fnm use --silent-if-unchanged; }
  autoload -Uz add-zsh-hook
  add-zsh-hook chpwd _fnm_autoload_hook

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
fi

# PNPM

# export PNPM_HOME="$HOME/.local/share/pnpm"
#
# case ":$PATH:" in
#   *":$PNPM_HOME:"*) ;;
#   *) export PATH="$PNPM_HOME:$PATH" ;;
# esac
#
# # tabtab source for pnpm package
# # uninstall by removing these lines
# [[ -f ~/.config/tabtab/zsh/__tabtab.zsh ]] && . ~/.config/tabtab/zsh/__tabtab.zsh || true
#
# if [ "$(pnpm config get store-dir)" != "$PNPM_HOME" ]; then
#   echo "pnpm store not set to \$PNPM_HOME, setting now..."
#   echo "pnpm config set store-dir \"$PNPM_HOME\""
#
#   # Create path if it doesn't exist
#   if [ ! -d "$PNPM_HOME" ]; then
#     echo "Creating pnpm store directory at $PNPM_HOME"
#     mkdir -p "$PNPM_HOME"
#   fi
#
#   pnpm config set store-dir "$PNPM_HOME"
# fi
