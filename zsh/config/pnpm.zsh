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
