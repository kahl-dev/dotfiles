# Atuin is installed via mise (see .config/mise/config.toml).
# Do not source ~/.atuin/bin/env here: it prepends the legacy curl-installed
# binary to PATH and would shadow the mise shim.
if command_exists atuin; then;
  eval "$(atuin init zsh)"
fi
