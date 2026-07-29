#!/usr/bin/env bash
# Pseudo-Key-Table fuer herdr: Nachbau des tmux Apps-Layers (Prefix+a -> Taste).
# herdr kennt keine Key-Tables; dieses Popup liest genau ein Zeichen und startet
# die App im selben Popup (type = "popup" erhaelt allen Input bis zum Exit).
# Tasten identisch zum tmux-Layer (tmux.conf:136-152). Esc/q bricht ab.

cd "${HERDR_ACTIVE_PANE_CWD:-$HOME}" || exit 1

printf '\n  apps — %s\n\n' "$PWD"
printf '   g  lazygit\n'
printf '   y  yazi\n'
printf '   b  btop\n'
printf '   m  glow\n'
printf '   h  hunk diff\n'
printf '\n   q/Esc  abbrechen\n'

read -rsn1 key
case "$key" in
  g) exec lazygit ;;
  y) exec yazi ;;
  b) exec btop ;;
  m) exec glow ;;
  h) exec mise exec -- hunk diff ;;
  *) exit 0 ;;
esac
