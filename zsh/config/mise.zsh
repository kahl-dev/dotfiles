# -----------------------------------------------------------------------------
# mise - polyglot runtime version manager (preferred over fnm/nvm)
# https://mise.jdx.dev/
#
# mise replaces fnm for interactive Node.js version management.
# It reads .nvmrc, .node-version, .tool-versions, and .mise.toml files
# natively (requires legacy_version_file = true in ~/.config/mise/config.toml).
#
# The chpwd hook auto-switches versions when entering project directories.
# This only works in interactive shells — Makefile subshells still need
# fnm/nvm (see node.zsh for the fallback setup).
#
# Must be sourced BEFORE node.zsh so that `command_exists mise` is true
# when node.zsh decides whether to initialize fnm.
# -----------------------------------------------------------------------------

if command_exists mise; then
  eval "$(mise activate zsh)"
fi
