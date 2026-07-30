#!/usr/bin/env bash
# Pseudo-Key-Table fuer herdr: Nachbau des tmux Apps-Layers (Prefix+a -> Taste).
# herdr kennt keine Key-Tables; dieses Popup liest genau ein Zeichen und startet
# die App im selben Popup (type = "popup" erhaelt allen Input bis zum Exit).
# Tasten g/y/b/m/h identisch zum tmux-Layer (tmux.conf:136-141); dessen
# 'c'-Picker fuer Claude-Agents (tmux.conf:148) ist hier bewusst nicht
# nachgebaut. Esc/q bricht ab.

if ! cd "${HERDR_ACTIVE_PANE_CWD:-$HOME}"; then
  printf 'apps-menu.sh: Verzeichnis nicht gefunden: %s\n' "${HERDR_ACTIVE_PANE_CWD:-$HOME}" >&2
  if [[ -t 0 ]]; then
    printf '\nTaste druecken zum Schliessen...\n' >&2
    read -rsn1 -t 30 || true
  fi
  exit 1
fi

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
