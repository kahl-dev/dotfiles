#!/usr/bin/env bash
# Responsive tmux status line generator
# Usage: status-line-main.sh [client_width]
# Tiers: ≥120 full │ 90-119 no env │ <90 no env+disk

set -euo pipefail

# Terminal width (default: wide)
width="${1:-200}"
[[ "$width" =~ ^[0-9]+$ ]] || width=200

# Catppuccin Mocha colors (from TMUX_* env vars with fallbacks)
readonly BG="${TMUX_BG:-#1e1e2e}"
readonly TEXT="${TMUX_TEXT:-#cdd6f4}"
readonly BLUE="${TMUX_BLUE:-#89b4fa}"
readonly GREEN="${TMUX_GREEN:-#a6e3a1}"
readonly YELLOW="${TMUX_YELLOW:-#f9e2af}"
readonly RED="${TMUX_RED:-#f38ba8}"
readonly PEACH="${TMUX_PEACH:-#fab387}"
readonly DIM="${TMUX_DIM:-#6c7086}"
readonly SURFACE="${TMUX_SURFACE:-#313244}"

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

# Separator
sep="#[fg=$DIM] │ #[fg=$TEXT]"

# Block 1: Machine resources (CPU/RAM + optional Disk)
cpu_val=$(~/.dotfiles/tmux/scripts/cpu-simple.sh 2>/dev/null || echo "0")
mem_val=$(~/.dotfiles/tmux/scripts/mem-simple.sh 2>/dev/null || echo "0")
resources="#[fg=$YELLOW]󰻠${cpu_val}%#[fg=$DIM]/#[fg=$GREEN]󰘚${mem_val}%"

if [[ $width -ge 90 ]]; then
  disk_val=$(~/.dotfiles/tmux/scripts/disk-simple.sh 2>/dev/null || echo "0")
  resources+="#[fg=$DIM]/#[fg=$BLUE]󰋊${disk_val}%"
fi
resources+="#[fg=$TEXT]"

# Block 2: Environment meta (uptime, sessions) — only on wide terminals
env_meta=""
if [[ $width -ge 120 ]]; then
  uptime_val=$(~/.dotfiles/tmux/scripts/uptime-simple.sh 2>/dev/null || echo "")
  session_count=$(tmux list-sessions 2>/dev/null | wc -l | tr -d ' ')
  if [[ -n "$uptime_val" ]]; then
    env_meta+="#[fg=$DIM]󰅐${uptime_val}"
  fi
  if [[ "$session_count" =~ ^[0-9]+$ ]] && [[ $session_count -gt 1 ]]; then
    [[ -n "$env_meta" ]] && env_meta+=" "
    env_meta+="#[fg=$DIM]󰘔${session_count}"
  fi
  [[ -n "$env_meta" ]] && env_meta+="#[fg=$TEXT]"
fi

# Block 3: Claude usage (silent on failure)
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

    if [[ $width -ge 90 ]]; then
      # Full: 󰚩 󰥔55%/󰃭43% ▲12%/d
      claude_segment="${sep}#[fg=$DIM]󰚩 "
      claude_segment+="#[fg=$five_hour_color]󰥔${five_hour}%"
      claude_segment+="#[fg=$DIM]/"
      claude_segment+="#[fg=$seven_day_color]󰃭${seven_day}%"
      claude_segment+=" #[fg=$pace_color]${pace_arrow}${daily_budget}%/d"
      claude_segment+="#[fg=$TEXT]"
    else
      # Compact: 󰥔6%/󰃭44%
      claude_segment="${sep}#[fg=$five_hour_color]󰥔${five_hour}%"
      claude_segment+="#[fg=$DIM]/"
      claude_segment+="#[fg=$seven_day_color]󰃭${seven_day}%"
      claude_segment+="#[fg=$TEXT]"
    fi
  fi
fi

# Get hostname display
hostname_display="$(~/.dotfiles/tmux/scripts/hostname-display.sh)"

# Build status line: resources [│ env] [│ claude] [│ hostname]
status_line="${resources}"
[[ -n "$env_meta" ]] && status_line+="${sep}${env_meta}"
status_line+="${claude_segment}"
if [[ -n "$hostname_display" ]] && [[ $width -ge 100 ]]; then
  status_line+="${sep}#[fg=$DIM]${hostname_display}#[fg=$TEXT]"
fi
status_line+=" "

echo "$status_line"
