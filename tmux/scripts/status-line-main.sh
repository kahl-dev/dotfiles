#!/usr/bin/env bash
# Simple main tmux status line generator

set -euo pipefail

# Catppuccin Mocha colors
readonly BG="#1e1e2e"
readonly TEXT="#cdd6f4"
readonly BLUE="#89b4fa"
readonly GREEN="#a6e3a1"
readonly YELLOW="#f9e2af"
readonly RED="#f38ba8"
readonly PEACH="#fab387"
readonly DIM="#6c7086"
readonly SURFACE="#313244"

# Helper: color by threshold (blue <50, peach 50-79, red 80+)
color_by_threshold() {
  local value=$1
  if [[ $value -ge 80 ]]; then
    echo "$RED"
  elif [[ $value -ge 50 ]]; then
    echo "$PEACH"
  else
    echo "$BLUE"
  fi
}

# System stats: 󰻠38/󰍛34% (CPU/RAM combined)
# System stats: both scripts return bare integers
cpu_val=$(~/.dotfiles/tmux/scripts/cpu-simple.sh 2>/dev/null || echo "0")
mem_val=$(~/.dotfiles/tmux/scripts/mem-simple.sh 2>/dev/null || echo "0")
sys_info="#[fg=$YELLOW]󰻠${cpu_val}%#[fg=$DIM]/#[fg=$GREEN]󰘚${mem_val}%#[fg=$TEXT]"

# Separator
sep="#[fg=$DIM] │ #[fg=$TEXT]"

# Get Claude usage segment (silent on failure)
# Format from script: 5h_pct|7d_pct|daily_budget|days_left|workdays_left|pace
claude_segment=""
claude_raw=$(~/.dotfiles/tmux/scripts/claude-usage.sh 2>/dev/null || true)
if [[ -n "$claude_raw" ]]; then
  IFS='|' read -r five_hour seven_day daily_budget days_left workdays_left pace <<< "$claude_raw"

  # Guard: ensure numeric fields are valid integers
  if [[ "$five_hour" =~ ^[0-9]+$ && "$seven_day" =~ ^[0-9]+$ && "$daily_budget" =~ ^[0-9]+$ ]]; then
    # Color each percentage individually
    five_hour_color=$(color_by_threshold "$five_hour")
    seven_day_color=$(color_by_threshold "$seven_day")

    # Pace arrow and color (budget thresholds for granular feedback)
    if [[ "$pace" == "under" ]]; then
      pace_arrow="▲"
      pace_color="$GREEN"
    else
      pace_arrow="▼"
      if [[ $daily_budget -lt 8 ]]; then
        pace_color="$RED"
      else
        pace_color="$PEACH"
      fi
    fi

    # 󰚩 󰥔55%/󰃭43% ▲12%/d
    claude_segment="${sep}#[fg=$DIM]󰚩 "
    claude_segment+="#[fg=$five_hour_color]󰥔${five_hour}%"
    claude_segment+="#[fg=$DIM]/"
    claude_segment+="#[fg=$seven_day_color]󰃭${seven_day}%"
    claude_segment+=" #[fg=$pace_color]${pace_arrow}${daily_budget}%/d"
    claude_segment+="#[fg=$TEXT]"
  fi
fi

# Get hostname display
hostname_display="$(~/.dotfiles/tmux/scripts/hostname-display.sh)"

# Build simple status line
# Session name is handled by tmux built-in status-left
if [[ -n "$hostname_display" ]]; then
  status_line="${sys_info}${claude_segment}${sep}#[fg=$DIM]${hostname_display}#[fg=$TEXT] "
else
  status_line="${sys_info}${claude_segment} "
fi

echo "$status_line"
