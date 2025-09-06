# Tmuxinator aliases and functions

# Check for required commands
_check_tmux_deps() {
  local missing_deps=()
  
  if ! command -v tmuxinator >/dev/null 2>&1; then
    missing_deps+=("tmuxinator")
  fi
  
  if ! command -v fzf >/dev/null 2>&1; then
    missing_deps+=("fzf")
  fi
  
  if ! command -v zoxide >/dev/null 2>&1; then
    missing_deps+=("zoxide")
  fi
  
  if [ ${#missing_deps[@]} -gt 0 ]; then
    echo "❌ Missing required dependencies: ${missing_deps[*]}"
    echo "   Install with: brew install ${missing_deps[*]}"
    return 1
  fi
  
  return 0
}

# Tmuxinator shortcut alias
alias mux='tmuxinator'

# (Removed) muxc/muxct aliases per user request

# Interactive tmuxinator project starter
_muxs() {
  if ! command -v tmuxinator >/dev/null 2>&1; then
    echo "❌ tmuxinator is not installed. Install with: gem install tmuxinator"
    return 1
  fi
  
  if ! command -v fzf >/dev/null 2>&1; then
    echo "❌ fzf is not installed. Install with: brew install fzf"
    return 1
  fi
  
  local project
  project=$(tmuxinator list | tail -n +2 | tr ' ' '\n' | grep -v '^$' | fzf --prompt="Select tmuxinator project to start: " --height=40% --reverse)
  
  if [ -n "$project" ]; then
    tmuxinator start "$project"
  fi
}

# Interactive zoxide + tmuxinator combo
# Navigate to any project directory using zoxide's interactive selection,
# then start a tmuxinator session there
_zmuxs() {
  # Check dependencies
  if ! _check_tmux_deps; then
    return 1
  fi
  
  # Get all directories from zoxide database and let user select one
  local selected_dir
  selected_dir=$(zoxide query -l 2>/dev/null | fzf \
    --prompt="Select project directory: " \
    --height=60% \
    --reverse \
    --preview 'ls -la {} 2>/dev/null || echo "Cannot preview directory"' \
    --preview-window=right:50% \
    --header="Select a directory to navigate to")
  
  if [ -n "$selected_dir" ]; then
    echo "→ Navigating to: $selected_dir"
    if ! cd "$selected_dir" 2>/dev/null; then
      echo "❌ Failed to navigate to: $selected_dir"
      echo "   Directory may no longer exist or you lack permissions"
      return 1
    fi
    
    # Get list of available tmuxinator templates dynamically
    local templates
    templates=$(tmuxinator list 2>/dev/null | tail -n +2 | tr ' ' '\n' | grep -v '^$')
    
    if [ -z "$templates" ]; then
      echo "⚠️  No tmuxinator templates found"
      echo "   Create one with: tmuxinator new <name>"
      return 1
    fi
    
    # Let user select a template
    local selected_template
    selected_template=$(echo "$templates" | fzf \
      --prompt="Select tmuxinator template: " \
      --height=40% \
      --reverse \
      --header="Directory: $(basename "$selected_dir")")
    
    if [ -n "$selected_template" ]; then
      echo "→ Starting tmuxinator template: $selected_template"
      tmuxinator start "$selected_template"
    else
      # Default to claude if no selection
      echo "→ Starting default claude session"
      if echo "$templates" | grep -q "^claude$"; then
        tmuxinator start claude
      else
        echo "⚠️  No claude template found, starting without template"
        tmux new-session -s "$(basename "$selected_dir")"
      fi
    fi
  fi
}

# Alternative: Use fzf with zoxide database for more control
_muxz() {
  # Check dependencies
  if ! _check_tmux_deps; then
    return 1
  fi
  
  # Get all directories from zoxide database sorted by frecency
  local selected_dir
  selected_dir=$(zoxide query -l 2>/dev/null | fzf \
    --prompt="Select project directory: " \
    --height=60% \
    --reverse \
    --preview 'ls -la {} 2>/dev/null || echo "Cannot preview directory"' \
    --preview-window=right:50% \
    --header="Select a directory to start tmuxinator session")
  
  if [ -n "$selected_dir" ]; then
    echo "→ Navigating to: $selected_dir"
    if ! cd "$selected_dir" 2>/dev/null; then
      echo "❌ Failed to navigate to: $selected_dir"
      echo "   Directory may no longer exist or you lack permissions"
      return 1
    fi
    
    # Get templates dynamically and add special options
    local templates
    local template_list
    templates=$(tmuxinator list 2>/dev/null | tail -n +2 | tr ' ' '\n' | grep -v '^$')
    
    if [ -z "$templates" ]; then
      echo "⚠️  No tmuxinator templates found"
      echo "   Create one with: tmuxinator new <name>"
      echo "   Starting basic tmux session instead..."
      tmux new-session -s "$(basename "$selected_dir")"
      return
    fi
    
    # Add special option to use directory name
    template_list=$(echo -e "$templates\n[use-directory-name]")
    
    # Show available tmuxinator templates and let user choose
    local template
    template=$(echo "$template_list" | \
      fzf --prompt="Select tmuxinator template: " \
          --height=40% \
          --reverse \
          --header="Project: $(basename "$selected_dir")")
    
    if [ "$template" = "[use-directory-name]" ]; then
      # Try to use directory name as template, fallback to claude
      local dir_name
      dir_name=$(basename "$selected_dir")
      if echo "$templates" | grep -q "^$dir_name$"; then
        echo "→ Starting project-specific template: $dir_name"
        tmuxinator start "$dir_name"
      elif echo "$templates" | grep -q "^claude$"; then
        echo "→ Starting claude session for: $dir_name"
        tmuxinator start claude
      else
        echo "→ Starting basic tmux session: $dir_name"
        tmux new-session -s "$dir_name"
      fi
    elif [ -n "$template" ]; then
      echo "→ Starting template: $template"
      tmuxinator start "$template"
    fi
  fi
}

alias muxs='_muxs'
alias zmuxs='_zmuxs'
alias muxz='_muxz'