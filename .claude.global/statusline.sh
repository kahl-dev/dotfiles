#!/bin/bash
# Custom Claude Code statusline - Optimized version
# Features: directory, git, model, version, output_style, lines_changed

input=$(cat)

# ---- color helpers (force colors for Claude Code) ----
use_color=1
[ -n "$NO_COLOR" ] && use_color=0

RST() { if [ "$use_color" -eq 1 ]; then printf '\033[0m'; fi; }

# ---- modern sleek colors ----
dir_color() { if [ "$use_color" -eq 1 ]; then printf '\033[38;5;117m'; fi; }    # sky blue
model_color() { if [ "$use_color" -eq 1 ]; then printf '\033[38;5;147m'; fi; }  # light purple

# ---- basics ----
if command -v jq >/dev/null 2>&1; then
  # Single jq call for better performance
  eval "$(echo "$input" | jq -r --arg home "$HOME" '
    "current_dir=" + ((.workspace.current_dir // .cwd // "unknown") | gsub("^" + $home; "~") | @sh) + ";" +
    "model_name=" + ((.model.display_name // "Claude") | @sh) + ";" +
    "model_version=" + ((.model.version // "") | @sh) + ";" +
    "cc_version=" + ((.version // "") | @sh) + ";" +
    "output_style=" + ((.output_style.name // "") | @sh) + ";" +
    "lines_added=" + ((.lines_added // 0) | tostring) + ";" +
    "lines_removed=" + ((.lines_removed // 0) | tostring)
  ' 2>/dev/null)"
else
  current_dir="unknown"
  model_name="Claude"
  model_version=""
  cc_version=""
  output_style=""
  lines_added="0"
  lines_removed="0"
fi

# ---- git colors ----
git_color() { if [ "$use_color" -eq 1 ]; then printf '\033[38;5;150m'; fi; }  # soft green

# ---- git ----
git_branch=""
git_status=""
if timeout 0.1s git rev-parse --git-dir >/dev/null 2>&1; then
  git_branch=$(git branch --show-current 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  # Check for git status indicators
  if [ -n "$(git diff --name-only 2>/dev/null)" ]; then
    git_status="${git_status}*"  # modified files
  fi
  if [ -n "$(git diff --staged --name-only 2>/dev/null)" ]; then
    git_status="${git_status}+"  # staged files
  fi
  if [ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]; then
    git_status="${git_status}?"  # untracked files
  fi
fi

# ---- render statusline ----
printf '📁 %s%s%s' "$(dir_color)" "$current_dir" "$(RST)"
if [ -n "$git_branch" ]; then
  printf '  🌿 %s%s%s%s' "$(git_color)" "$git_branch" "$git_status" "$(RST)"
fi
printf '  🤖 %s%s%s' "$(model_color)" "$model_name" "$(RST)"
if [ -n "$model_version" ] && [ "$model_version" != "null" ]; then
  printf '  🏷️ %s%s%s' "$(model_color)" "$model_version" "$(RST)"
fi
if [ -n "$cc_version" ] && [ "$cc_version" != "null" ]; then
  printf '  📟 %sv%s%s' "$(model_color)" "$cc_version" "$(RST)"
fi
if [ -n "$output_style" ] && [ "$output_style" != "null" ]; then
  printf '  🎨 %s%s%s' "$(model_color)" "$output_style" "$(RST)"
fi
if [ "$lines_added" != "0" ] || [ "$lines_removed" != "0" ]; then
  printf '  📊 %s+%s -%s%s' "$(model_color)" "$lines_added" "$lines_removed" "$(RST)"
fi
