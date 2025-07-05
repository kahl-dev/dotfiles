# Claude Storage System - Directory-based File Management
# This enables automatic file management when changing directories

# Read config settings
_claude_store_get_config() {
  local key="$1"
  local config_file="$HOME/.claude.store/config.json"
  
  if [[ -f "$config_file" ]] && command -v jq &>/dev/null; then
    jq -r ".$key // false" "$config_file" 2>/dev/null
  else
    echo "false"
  fi
}

# Debug logging function
_claude_store_log() {
  local message="$1"
  local show_operations=$(_claude_store_get_config "show_file_operations")
  local debug_mode=$(_claude_store_get_config "debug_mode")
  
  if [[ "$show_operations" == "true" ]] || [[ "$debug_mode" == "true" ]]; then
    echo "$message" >&2
  fi
}

# Store the real Claude binary path to avoid recursion
CLAUDE_REAL_BINARY="/run/user/$(id -u)/fnm_multishells/*/bin/claude"
if ! [ -x "$CLAUDE_REAL_BINARY" ]; then
  CLAUDE_REAL_BINARY="$(command -v claude 2>/dev/null)"
fi

# Track the last project for efficient directory changes
CLAUDE_STORE_LAST_PROJECT_FILE="$HOME/.claude-store-last-project"

# Get project ID for a directory (reuse existing wrapper logic)
_claude_store_get_project_id() {
  local dir="${1:-$PWD}"
  local project_id=""
  
  if [[ -d "$dir/.git" ]] || git -C "$dir" rev-parse --git-dir &>/dev/null; then
    # Git repository - use remote URL hash
    local remote_url=$(git -C "$dir" remote get-url origin 2>/dev/null || echo "")
    if [[ -n "$remote_url" ]]; then
      local normalized_url=$(echo "$remote_url" | sed 's|https://||; s|git@||; s|\.git$||; s|[:/]|_|g')
      local url_hash=$(echo "$remote_url" | sha256sum | cut -c1-32)
      project_id="git_${normalized_url}_${url_hash}"
    else
      # Git repo without remote
      local repo_path=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || echo "$dir")
      local path_hash=$(echo "$repo_path" | sha256sum | cut -c1-32)
      project_id="git_local_$(basename "$repo_path")_${path_hash}"
    fi
  else
    # Non-git directory - use hostname + path hash
    local hostname=$(hostname)
    local path_hash=$(echo "$dir" | sha256sum | cut -c1-32)
    project_id="folder_${hostname}_$(basename "$dir")_${path_hash}"
  fi
  
  echo "$project_id"
}

# Reference counting for multi-session safety
_claude_store_add_session_ref() {
  local project_id="$1"
  local session_id="$$"
  local ref_file="$HOME/.claude-store-refs-$project_id"
  
  # Add current session to reference file
  echo "$session_id" >> "$ref_file" 2>/dev/null
}

_claude_store_remove_session_ref() {
  local project_id="$1"
  local session_id="$$"
  local ref_file="$HOME/.claude-store-refs-$project_id"
  
  [[ -f "$ref_file" ]] || return 1
  
  # Remove current session from reference file
  grep -v "^$session_id$" "$ref_file" > "${ref_file}.tmp" 2>/dev/null
  mv "${ref_file}.tmp" "$ref_file" 2>/dev/null
  
  # Clean up empty reference file
  if [[ ! -s "$ref_file" ]]; then
    rm -f "$ref_file" 2>/dev/null
  fi
}

_claude_store_count_active_sessions() {
  local project_id="$1"
  local ref_file="$HOME/.claude-store-refs-$project_id"
  
  [[ -f "$ref_file" ]] || return 1
  
  # Get list of PIDs from reference file
  local pids=$(cat "$ref_file" 2>/dev/null)
  [[ -n "$pids" ]] || return 1
  
  # Count how many are still active processes
  local active_count=0
  local temp_file="${ref_file}.clean"
  > "$temp_file"
  
  while IFS= read -r pid; do
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      echo "$pid" >> "$temp_file"
      ((active_count++))
    fi
  done <<< "$pids"
  
  # Update reference file with only active PIDs
  if [[ $active_count -gt 0 ]]; then
    mv "$temp_file" "$ref_file"
    echo $active_count
  else
    rm -f "$temp_file" "$ref_file" 2>/dev/null
    echo 0
  fi
}

_claude_store_safe_cleanup() {
  local project_id="$1"
  
  # Remove current session from reference count
  _claude_store_remove_session_ref "$project_id"
  
  # Count remaining active sessions
  local active_sessions=$(_claude_store_count_active_sessions "$project_id")
  
  # Only cleanup if no active sessions remain
  if [[ $active_sessions -eq 0 ]]; then
    # Safe to store/remove files - no other sessions in this project
    _claude_store_log "📦 Storing Claude files for project..."
    "$HOME/.claude.store/bin/claude-wrapper" store-files-background "$project_id" </dev/null &>/dev/null &
    return 0
  else
    # Other sessions still active - just backup without removing
    _claude_store_log "💾 Backing up Claude files (${active_sessions} sessions active)..."
    "$HOME/.claude.store/bin/claude-wrapper" store-files-backup-only "$project_id" </dev/null &>/dev/null &
    return 1
  fi
}

# Main directory sync function with reference counting
_claude_store_sync_directory() {
  # Check if auto sync is enabled
  local auto_sync_enabled=$(_claude_store_get_config "auto_sync_enabled")
  if [[ "$auto_sync_enabled" != "true" ]]; then
    return 0
  fi
  
  # Run with timeout and error handling to prevent shell hanging
  {
    local current_dir="$PWD"
    local current_project=$(_claude_store_get_project_id "$current_dir" 2>/dev/null)
    local last_project=$(cat "$CLAUDE_STORE_LAST_PROJECT_FILE" 2>/dev/null || echo "")
    
    # Only sync if project actually changed
    if [[ "$current_project" != "$last_project" ]]; then
      
      # Handle leaving previous project (in background to avoid blocking)
      if [[ -n "$last_project" && "$last_project" != "none" ]]; then
        _claude_store_safe_cleanup "$last_project" </dev/null &>/dev/null &
      fi
      
      # Handle entering current project
      if [[ -n "$current_project" && "$current_project" != "none" ]]; then
        # Add current session to reference count
        _claude_store_add_session_ref "$current_project" 2>/dev/null
        
        # Restore files for current project (in background to avoid blocking)
        _claude_store_log "📁 Restoring Claude files for project..."
        timeout 2 "$HOME/.claude.store/bin/claude-wrapper" restore-files-for-project "$current_project" </dev/null &>/dev/null &
      fi
      
      # Update tracking
      echo "${current_project:-none}" > "$CLAUDE_STORE_LAST_PROJECT_FILE" 2>/dev/null
    elif [[ -n "$current_project" && "$current_project" != "none" ]]; then
      # Same project, but ensure we're in the reference count (handles new sessions)
      _claude_store_add_session_ref "$current_project" 2>/dev/null
    fi
  } 2>/dev/null || true  # Suppress all errors to prevent shell hanging
}

# Cleanup function for when shell exits
_claude_store_exit_cleanup() {
  local current_project=$(_claude_store_get_project_id "$PWD" 2>/dev/null)
  if [[ -n "$current_project" && "$current_project" != "none" ]]; then
    _claude_store_safe_cleanup "$current_project" &>/dev/null &
  fi
}

# Add to ZSH hook functions array instead of overriding
chpwd_functions+=(_claude_store_sync_directory)

# ZSH hook that triggers on shell exit  
zshexit_functions+=(_claude_store_exit_cleanup)

# Also handle terminal close/kill via trap
trap '_claude_store_exit_cleanup' EXIT

# Initialize on shell startup with SSH detection
_claude_store_safe_init() {
  # Skip initialization during SSH login to prevent hanging
  if [[ -n "$SSH_CONNECTION" || -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
    return 0
  fi
  
  # Use timeout to prevent hanging during local shell startup
  timeout 3 _claude_store_sync_directory 2>/dev/null || {
    echo "Warning: Claude store initialization timed out - skipping" >&2
    return 1
  }
}

# Initialize on shell startup
_claude_store_safe_init