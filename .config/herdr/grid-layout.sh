#!/usr/bin/env bash
set -euo pipefail

# Rearrangiert alle Panes des AKTIVEN Tabs zu einem gleichmaessigen Grid mit
# maximal N Zeilen. Nachbau von tmux-grid-layout.sh (tmux/scripts/) fuer herdr;
# Spalten-/Zeilen-Verteilung (ceil(N/max_rows) Spalten, danach Basis-Split
# base=pane_count/cols Zeilen pro Spalte, die ersten pane_count-mod-cols
# Spalten bekommen eine Zeile mehr als der Rest) ist 1:1 von dort uebernommen.
#
# Usage: grid-layout.sh <max_rows|t>
#   1/2/3/...  fixe Obergrenze fuer Zeilen pro Spalte
#   t          Tiled-Naeherung: rows = floor(sqrt(pane_count)), wie tmux tiled
#
# Ungueltiges Argument (alles ausser "t" oder einer positiven Ganzzahl, siehe
# Validierung unten) bricht sofort mit exit 1 ab, VOR jeder herdr-Mutation -
# das schliesst einen destruktiven Pfad: ein negativer/nicht-numerischer Wert
# liess frueher cols<=0 zu, ueberspraeng dadurch alle Peel-Schleifen, parkte
# aber trotzdem alle Nicht-Anchor-Panes im Scratch-Tab und zerstoerte sie dann
# per `tab close`.
#
# Ratio-Semantik (empirisch verifiziert am 2026-07-29 in einer Wegwerf-Session
# via `pane split --ratio 0.3` + `pane edges`): das Ziel-Pane (--target-pane,
# bzw. --pane bei `pane split`) behaelt den Anteil `ratio` und bleibt "erstes"
# Kind (links bei --split right, oben bei --split down); das bewegte/neue Pane
# bekommt den Rest (1-ratio) als "zweites" Kind. Gleiche Semantik bei
# `pane move --ratio`, empirisch mit ratio 0.25 bestaetigt.
#
# Algorithmus (drei Phasen, alle ueber `herdr pane move`):
#   0. Parken: alle Panes ausser dem Anchor (erstes Pane in `pane list`-
#      Reihenfolge) werden zuerst in ein Scratch-Tab verschoben. Grund: ein
#      direkter In-Tab-Move eines Panes, das noch Nachfahre der Zielstruktur
#      ist, endet bei `pane move` beobachtbar als stiller No-Op
#      (move_result.changed == false, kein Fehler) statt mit einer Fehlermeldung
#      - reproduziert beim Versuch, ein Pane direkt neben seinen eigenen
#      Vorfahren zu haengen. Der Scratch-Tab-Umweg macht jeden Rueck-Move zu
#      einem sauberen Cross-Tab-Move auf ein bislang unbeteiligtes Blatt-Pane,
#      was zuverlaessig funktioniert.
#   1. Spalten-Peel: das Grid waechst von der letzten Spalte rueckwarts. Der
#      Anchor repraesentiert zu Beginn "alle Spalten" und wird bei jedem Peel-
#      Schritt (Spalte c, absteigend) per --split right um ratio=c/(c+1)
#      verkleinert; das hereingeholte Pane wird neue Spalte c. Diese Formel
#      liefert exakt gleich breite Spalten unabhaengig von N (Standardtrick
#      fuer N-faches Teilen durch sequentielle Binaer-Splits).
#   2. Zeilen-Peel: dieselbe Formel je Spalte, mit --split down, auf Basis des
#      Spalten-Anchors (oberstes Pane der Spalte).
#
# Nur Rearrange fuer User-Panes: die Netto-Anzahl der User-Panes aendert sich
# durch einen Lauf nie. Dass das Scratch-Tab dabei eine eigene Root-Pane
# erzeugt (bei `tab create`) und beim Schliessen wieder zerstoert (`tab
# close`), ist ein mechanischer Nebeneffekt der Scratch-Tab-Mechanik selbst,
# betrifft aber keine User-Pane.
#
# Verworfene Alternative: die Socket-API bietet layout.apply, aber die CLI hat
# keinen Passthrough fuer beliebige Socket-Methoden und das Wire-Protokoll ist
# intern und versioniert (Protokoll 17) - ein selbstgebauter JSON-RPC-Client
# waere ein Wartungsrisiko, daher nur dokumentierte CLI-Oberflaeche (`pane move`).

# Liefert das Split-Verhaeltnis fuer den n-ten Peel-Schritt (n / (n+1)) -
# Standardtrick fuer exakt gleich grosse N-fache Teilung durch sequentielle
# Binaer-Splits, siehe Phase 1/2 im Algorithmus oben.
ratio_for() { awk -v n="$1" 'BEGIN{printf "%.6f", n/(n+1)}'; }

# Ummantelt jeden `herdr pane move`-Aufruf und prueft explizit auf den oben
# dokumentierten stillen No-Op (empirisch verifiziert: bei einem No-Op liefert
# die Antwort .result.move_result.changed == false plus .result.move_result.reason,
# z.B. "same_tab" - exit 0, keine Fehlermeldung). Diese Luecke war bislang
# ungeprueft, obwohl das Skript den Fehlermodus selbst dokumentiert.
move_pane() {
  local pane_id="$1"
  shift
  local response
  response=$(herdr pane move "$pane_id" "$@")
  local changed
  changed=$(printf '%s' "$response" | jq -r '.result.move_result.changed')
  if [[ "$changed" != "true" ]]; then
    printf 'move_pane: stiller No-Op erkannt - pane=%s args=%s\n' "$pane_id" "$*" >&2
    printf '%s\n' "$response" >&2
    exit 1
  fi
}

mode="${1:-2}"

# Validierung VOR jeder herdr-Mutation (siehe Header) - nur "t" oder eine
# positive Ganzzahl sind gueltige max_rows-Werte.
if [[ "$mode" != "t" && ! "$mode" =~ ^[1-9][0-9]*$ ]]; then
  printf 'grid-layout.sh: ungueltiges Argument %q - erwartet "t" oder eine positive Ganzzahl (max_rows), z.B. 1, 2, 3.\n' "$mode" >&2
  exit 1
fi

# Werden von Phase 0 gesetzt, sobald das Scratch-Tab existiert. cleanup_on_exit
# prueft scratch_tab_id, um einen sauberen exit-0-Lauf (Scratch-Tab bereits
# geschlossen) von einem Abbruch mit noch offenem Scratch-Tab zu unterscheiden.
# Leerstring vorbelegt (statt unbound unter set -u), falls Phase 0 selbst
# mittendrin abbricht (z.B. `tab create`-Antwort ohne root_pane).
scratch_tab_id=""
scratch_root=""

# Rettungsnetz: laeuft bei JEDEM Skript-Ende (trap ... EXIT). Bei Erfolg ($? ==
# 0) ist das Scratch-Tab bereits regulaer geschlossen - nichts zu tun. Bei
# einem Abbruch nach Phase 0 waeren sonst alle geparkten Panes im Scratch-Tab
# gefangen und wuerden mit ihm verschwinden, sobald jemand es manuell schliesst.
# Statt die urspruengliche Grid-Position zu rekonstruieren (das wuerde den
# fehlgeschlagenen Schritt wiederholen), werden alle noch im Scratch-Tab
# verbliebenen Panes nur nach unten auf den Anchor im Ziel-Tab gestapelt -
# haesslich, aber die Panes ueberleben.
cleanup_on_exit() {
  local exit_code=$?
  (( exit_code == 0 )) && return 0
  [[ -z "$scratch_tab_id" ]] && return 0

  printf 'grid-layout.sh: Abbruch (exit %d) - berge Panes aus Scratch-Tab %s...\n' "$exit_code" "$scratch_tab_id" >&2

  local stranded_json
  stranded_json=$(herdr pane list --workspace "$workspace_id" 2>/dev/null) || stranded_json=""
  if [[ -n "$stranded_json" ]]; then
    local stranded_ids pane_id
    # scratch_root selbst ausschliessen: das ist die mechanische Wegwerf-Pane
    # des Scratch-Tabs (siehe Header), keine User-Pane - sie soll mit dem Tab
    # sterben, nicht in den Ziel-Tab "gerettet" werden.
    mapfile -t stranded_ids < <(printf '%s' "$stranded_json" | jq -r --arg tab "$scratch_tab_id" --arg root "$scratch_root" '.result.panes[]? | select(.tab_id == $tab and .pane_id != $root) | .pane_id' 2>/dev/null)
    for pane_id in "${stranded_ids[@]}"; do
      [[ -z "$pane_id" ]] && continue
      if herdr pane move "$pane_id" --tab "$tab_id" --target-pane "$anchor" --split down --ratio 0.5 --no-focus >/dev/null 2>&1; then
        printf '  geborgen: %s -> Ziel-Tab %s\n' "$pane_id" "$tab_id" >&2
      else
        printf '  FEHLER: konnte %s nicht bergen - siehe herdr-server.log\n' "$pane_id" >&2
      fi
    done
  else
    printf '  WARNUNG: konnte Pane-Liste nicht lesen, ueberspringe Bergung.\n' >&2
  fi

  if herdr tab close "$scratch_tab_id" >/dev/null 2>&1; then
    printf '  Scratch-Tab %s geschlossen.\n' "$scratch_tab_id" >&2
  else
    printf '  FEHLER: konnte Scratch-Tab %s nicht schliessen.\n' "$scratch_tab_id" >&2
  fi

  # Popup schliesst beim Exit und schluckt stderr - Nachricht erst anzeigen
  # lassen, wenn stdin ein TTY ist (interaktiver Aufruf).
  if [[ -t 0 ]]; then
    printf '\nFehler in grid-layout.sh (siehe oben) - Taste druecken zum Schliessen...\n' >&2
    read -rsn1 -t 30 || true
  fi
}
trap cleanup_on_exit EXIT

workspace_id="${HERDR_ACTIVE_WORKSPACE_ID:?HERDR_ACTIVE_WORKSPACE_ID fehlt - Script laeuft nur in einem herdr-Popup/Kontext}"
tab_id="${HERDR_ACTIVE_TAB_ID:?HERDR_ACTIVE_TAB_ID fehlt}"

panes_json=$(herdr pane list --workspace "$workspace_id")
if ! printf '%s' "$panes_json" | jq -e '.result.panes' >/dev/null 2>&1; then
  printf 'grid-layout.sh: herdr pane list lieferte keine gueltige Pane-Liste:\n' >&2
  printf '%s\n' "$panes_json" >&2
  exit 1
fi
mapfile -t pane_ids < <(printf '%s' "$panes_json" | jq -r --arg tab "$tab_id" '.result.panes[] | select(.tab_id == $tab) | .pane_id')

pane_count=${#pane_ids[@]}

# Ein oder null Panes: nichts zu tun.
if (( pane_count <= 1 )); then
  exit 0
fi

if [[ "$mode" == "t" ]]; then
  max_rows=$(awk -v n="$pane_count" 'BEGIN { r = int(sqrt(n)); print (r < 1 ? 1 : r) }')
else
  max_rows="$mode"
fi

# Sonderfall wie im tmux-Original: passt eine einzelne Spalte, reicht ein
# reiner Zeilen-Peel ohne Spalten-Phase.
if (( pane_count <= max_rows )); then
  cols=1
else
  cols=$(( (pane_count + max_rows - 1) / max_rows ))
fi
# Basis-Split: base Zeilen pro Spalte, die ersten `remainder` Spalten
# bekommen eine Zeile mehr. Deckt auch cols==1 korrekt ab (remainder==0,
# die einzige Spalte bekommt base==pane_count Zeilen), macht den frueheren
# cols==1-Sonderfall in der Schleife unten ueberfluessig.
base=$(( pane_count / cols ))
remainder=$(( pane_count % cols ))

# Panes spaltenweise (column-major) den Slots zuteilen, wie im tmux-Original.
declare -a col_rows
declare -A slot # slot[c,r] = pane_id
pane_idx=0
for (( c = 0; c < cols; c++ )); do
  if (( c < remainder )); then
    rows_here=$(( base + 1 ))
  else
    rows_here=$base
  fi
  col_rows[c]=$rows_here
  for (( r = 0; r < rows_here; r++ )); do
    slot[$c,$r]="${pane_ids[$pane_idx]}"
    pane_idx=$(( pane_idx + 1 ))
  done
done

anchor="${pane_ids[0]}"

# Phase 0: alles ausser dem Anchor in ein frisches Scratch-Tab parken.
scratch_json=$(herdr tab create --workspace "$workspace_id" --no-focus)
{ read -r scratch_tab_id; read -r scratch_root; } < <(printf '%s' "$scratch_json" | jq -r '.result.tab.tab_id, .result.root_pane.pane_id')

for pane_id in "${pane_ids[@]}"; do
  [[ "$pane_id" == "$anchor" ]] && continue
  move_pane "$pane_id" --tab "$scratch_tab_id" --target-pane "$scratch_root" --split down --ratio 0.5 --no-focus
done

# Phase 1: Spalten von hinten nach vorn ins Ziel-Tab zurueckholen.
for (( c = cols - 1; c >= 1; c-- )); do
  mover="${slot[$c,0]}"
  ratio=$(ratio_for "$c")
  move_pane "$mover" --tab "$tab_id" --target-pane "$anchor" --split right --ratio "$ratio" --no-focus
done

# Phase 2: innerhalb jeder Spalte die Zeilen von hinten nach vorn einfuegen.
for (( c = 0; c < cols; c++ )); do
  rows_here=${col_rows[$c]}
  (( rows_here <= 1 )) && continue
  col_anchor="${slot[$c,0]}"
  for (( r = rows_here - 1; r >= 1; r-- )); do
    mover="${slot[$c,$r]}"
    ratio=$(ratio_for "$r")
    move_pane "$mover" --tab "$tab_id" --target-pane "$col_anchor" --split down --ratio "$ratio" --no-focus
  done
done

# Scratch-Tab ist jetzt leer bis auf sein eigenes Wegwerf-Root-Pane.
herdr tab close "$scratch_tab_id" >/dev/null
