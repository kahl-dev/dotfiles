#!/usr/bin/env bash
# 📋 Shared tool registry for dot update + tmux dashboard
# Single source of truth: add tools here, both systems pick them up.
#
# Format: name|icon|label|threshold_days|cache_key
# - name: internal identifier (used in dot update <name>)
# - icon: Nerd Font icon for tmux dashboard
# - label: human-readable display name
# - threshold_days: staleness threshold (red after N days)
# - cache_key: suffix for ~/.cache/dot-last-<key> timestamp file

DOT_UPDATE_TOOLS=(
  "brew|󰜁|Homebrew|7|brew-update"
  "mise||Mise|7|mise-update"
  "tpm|󰐱|TPM|30|tpm-update"
  "rtk|🦀|RTK|7|rtk-update"
  "repos|󰊢|Repos|3|repos-sync"
)

# Parse a registry entry into variables: _name, _icon, _label, _threshold, _cache_key
# Usage: _dot_parse_tool "${DOT_UPDATE_TOOLS[0]}"
_dot_parse_tool() {
  local IFS='|'
  read -r _name _icon _label _threshold _cache_key <<< "$1"
}
