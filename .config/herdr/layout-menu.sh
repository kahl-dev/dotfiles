#!/usr/bin/env bash
set -euo pipefail

# Pseudo-Key-Table fuer herdr: Nachbau der tmux Panes-Layer-Layout-Tasten
# (Prefix+v -> 1/2/3/t, siehe tmux.conf:158-200 / docs Panes Key Table).
# herdr kennt keine Key-Tables; dieses Popup liest genau ein Zeichen und ruft
# grid-layout.sh im selben Popup auf (type = "popup" erhaelt allen Input bis
# zum Exit). Nur die Grid-Layouts sind uebernommen - die restlichen tmux
# Panes-Aktionen (Splits, Swap, Break, ...) sind herdr-Defaults auf anderen
# Tasten und hier bewusst nicht nachgebaut. Esc/q bricht ab.

workspace_id="${HERDR_ACTIVE_WORKSPACE_ID:?HERDR_ACTIVE_WORKSPACE_ID fehlt - Script laeuft nur in einem herdr-Popup/Kontext}"
tab_id="${HERDR_ACTIVE_TAB_ID:?HERDR_ACTIVE_TAB_ID fehlt}"

pane_count=$(herdr pane list --workspace "$workspace_id" \
  | jq -r --arg tab "$tab_id" '[.result.panes[] | select(.tab_id == $tab)] | length')

printf '\n  layout — %s Panes\n\n' "$pane_count"
printf '   1  Grid, max 1 Zeile\n'
printf '   2  Grid, max 2 Zeilen\n'
printf '   3  Grid, max 3 Zeilen\n'
printf '   t  Tiled (Auto-Grid)\n'
printf '\n   q/Esc  abbrechen\n'

read -rsn1 key
case "$key" in
  1|2|3|t) exec bash "$HOME/.config/herdr/grid-layout.sh" "$key" ;;
  *) exit 0 ;;
esac
