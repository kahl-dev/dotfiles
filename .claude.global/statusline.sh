#!/bin/bash
# Custom Claude Code statusline - Enhanced version with last user input
# Features: directory, git, model, version, lines_changed, and LAST USER INPUT

input=$(cat)

# ---- Color helpers (force colors for Claude Code) ----
use_color=1
[ -n "$NO_COLOR" ] && use_color=0

RST() { if [ "$use_color" -eq 1 ]; then printf '\033[0m'; fi; }

# ---- Modern sleek colors ----
dir_color() { if [ "$use_color" -eq 1 ]; then printf '\033[38;5;117m'; fi; }    # sky blue
model_color() { if [ "$use_color" -eq 1 ]; then printf '\033[38;5;147m'; fi; }  # light purple
git_color() { if [ "$use_color" -eq 1 ]; then printf '\033[38;5;150m'; fi; }    # soft green
prompt_color() { if [ "$use_color" -eq 1 ]; then printf '\033[38;5;229m'; fi; } # soft yellow
icon_color() { if [ "$use_color" -eq 1 ]; then printf '\033[38;5;213m'; fi; }   # pink for icons
prev_color() { if [ "$use_color" -eq 1 ]; then printf '\033[38;5;180m'; fi; }   # more visible beige
arrow_color() { if [ "$use_color" -eq 1 ]; then printf '\033[38;5;208m'; fi; }  # orange arrow

# ---- Function to select icon based on prompt content ----
get_prompt_icon() {
  local prompt="$1"
  local prompt_lower
  prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')

  # Check for keywords and return appropriate icon
  case "$prompt_lower" in
    *fix*|*bug*|*error*|*issue*)
      echo "🐛"  # Bug fixing
      ;;
    *write*|*create*|*add*|*implement*)
      echo "✍️"  # Writing/creating
      ;;
    *test*|*verify*)
      echo "🧪"  # Testing
      ;;
    *build*|*compile*|*run*)
      echo "🔨"  # Building
      ;;
    *refactor*|*improve*)
      echo "♻️"  # Refactoring
      ;;
    *deploy*|*release*|*publish*)
      echo "🚀"  # Deployment
      ;;
    *search*|*find*|*look*)
      echo "🔍"  # Searching
      ;;
    *help*|*explain*|*what*|*how*)
      echo "❓"  # Questions
      ;;
    *update*|*upgrade*|*modify*)
      echo "🔄"  # Updates
      ;;
    *delete*|*remove*|*clean*)
      echo "🗑️"  # Deletion
      ;;
    *config*|*setup*|*install*)
      echo "⚙️"  # Configuration
      ;;
    *analyze*|*review*|*check*)
      echo "🔎"  # Analysis
      ;;
    *git*|*commit*|*merge*|*branch*)
      echo "🌳"  # Git operations
      ;;
    *docker*|*container*)
      echo "🐳"  # Docker
      ;;
    *database*|*sql*|*query*)
      echo "🗃️"  # Database
      ;;
    *api*|*endpoint*|*request*)
      echo "🔌"  # API
      ;;
    *security*|*auth*|*permission*)
      echo "🔒"  # Security
      ;;
    *optimize*|*performance*)
      echo "⚡"  # Performance
      ;;
    *)
      echo "💬"  # Default chat icon
      ;;
  esac
}

# ---- Function to truncate prompt intelligently ----
truncate_prompt() {
  local prompt="$1"
  local max_length=80

  # Remove excessive whitespace
  prompt=$(echo "$prompt" | tr -s ' ' | sed 's/^ *//;s/ *$//')

  if [ ${#prompt} -le $max_length ]; then
    echo "$prompt"
  else
    # Truncate and add ellipsis
    echo "${prompt:0:$((max_length-3))}..."
  fi
}

# ---- Function to truncate previous prompt compactly ----
truncate_prev_prompt() {
  local prompt="$1"
  local max_length=30

  # Remove excessive whitespace
  prompt=$(echo "$prompt" | tr -s ' ' | sed 's/^ *//;s/ *$//')

  if [ ${#prompt} -le $max_length ]; then
    echo "$prompt"
  else
    # Truncate and add ellipsis
    echo "${prompt:0:$((max_length-3))}..."
  fi
}

# ---- Extract data from input ----
if command -v jq >/dev/null 2>&1; then
  # Single jq call for better performance
  eval "$(echo "$input" | jq -r --arg home "$HOME" '
    "current_dir=" + ((.workspace.current_dir // .cwd // "unknown") | gsub("^" + $home; "~") | @sh) + ";" +
    "model_name=" + ((.model.display_name // "Claude") | @sh) + ";" +
    "model_version=" + ((.model.version // "") | @sh) + ";" +
    "cc_version=" + ((.version // "") | @sh) + ";" +
    "lines_added=" + ((.cost.total_lines_added // .lines_added // 0) | tostring) + ";" +
    "lines_removed=" + ((.cost.total_lines_removed // .lines_removed // 0) | tostring) + ";" +
    "session_id=" + ((.session_id // "") | @sh)
  ' 2>/dev/null)"
else
  current_dir="unknown"
  model_name="Claude"
  model_version=""
  cc_version=""
  lines_added="0"
  lines_removed="0"
  session_id=""
fi

# ---- Git status ----
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

# ---- Get last and previous user prompts from session file ----
last_prompt=""
prev_prompt=""
if [ -n "$session_id" ] && [ "$session_id" != "null" ]; then
  session_file="$HOME/.claude/data/sessions/${session_id}.json"

  if [ -f "$session_file" ] && command -v jq >/dev/null 2>&1; then
    # Get the last prompt from the prompts array
    last_prompt=$(jq -r '.prompts[-1] // ""' "$session_file" 2>/dev/null)

    # Get the second-to-last prompt (previous)
    prev_prompt=$(jq -r '.prompts[-2] // ""' "$session_file" 2>/dev/null)

    # Clean up if they're null or empty
    if [ "$last_prompt" = "null" ] || [ -z "$last_prompt" ]; then
      last_prompt=""
    fi
    if [ "$prev_prompt" = "null" ] || [ -z "$prev_prompt" ]; then
      prev_prompt=""
    fi
  fi
fi

# ---- Process prompts ----
if [ -n "$last_prompt" ]; then
  prompt_icon=$(get_prompt_icon "$last_prompt")
  truncated_prompt=$(truncate_prompt "$last_prompt")
fi

if [ -n "$prev_prompt" ]; then
  truncated_prev_prompt=$(truncate_prev_prompt "$prev_prompt")
fi

# ---- Render statusline ----
# Directory
printf '📁 %s%s%s' "$(dir_color)" "$current_dir" "$(RST)"

# Git info
if [ -n "$git_branch" ]; then
  printf '  🌿 %s%s%s%s' "$(git_color)" "$git_branch" "$git_status" "$(RST)"
fi

# Model info
printf '  🤖 %s%s%s' "$(model_color)" "$model_name" "$(RST)"

# Version info (optional, more compact)
if [ -n "$model_version" ] && [ "$model_version" != "null" ]; then
  printf ' %sv%s%s' "$(model_color)" "$model_version" "$(RST)"
fi

# Claude Code CLI version
if [ -n "$cc_version" ] && [ "$cc_version" != "null" ]; then
  printf '  📟 %sv%s%s' "$(model_color)" "$cc_version" "$(RST)"
fi

# Lines changed (if any)
if [ "$lines_added" != "0" ] || [ "$lines_removed" != "0" ]; then
  printf '  📊 %s+%s/-%s%s' "$(model_color)" "$lines_added" "$lines_removed" "$(RST)"
fi

# Last user prompts with conversation flow (latest first)
if [ -n "$truncated_prompt" ]; then
  printf '\n'

  # Show current prompt with icon FIRST
  printf '%s%s%s %s"%s"%s' "$(icon_color)" "$prompt_icon" "$(RST)" "$(prompt_color)" "$truncated_prompt" "$(RST)"

  # Show previous prompt if it exists (after arrow)
  if [ -n "$truncated_prev_prompt" ]; then
    printf ' %s←%s %s💭 "%s"%s' "$(arrow_color)" "$(RST)" "$(prev_color)" "$truncated_prev_prompt" "$(RST)"
  fi
fi