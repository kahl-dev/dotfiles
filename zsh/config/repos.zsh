#!/usr/bin/env zsh
# dot repos — multi-repo fleet management
# Requires _dot_ask, _dot_timeout, _dot_touch_update from dot.zsh/update.zsh

# ── Repo Registry ───────────────────────────────────────────────────────────
typeset -ga DOT_REPOS
DOT_REPOS=(
  "$HOME/.dotfiles"
  "$HOME/repos/claude-config"
  "$HOME/repos/louis-claude-marketplace"
)

# Per-machine additions (not in git)
# Format: one path per line, # comments, tilde expansion supported
# Inline comments NOT supported (e.g., "/path # comment" will break)
local local_file="${XDG_CONFIG_HOME:-$HOME/.config}/dot/repos.local"
if [[ -f "$local_file" ]]; then
  while IFS= read -r line; do
    # Trim leading whitespace, then check for empty/comment
    local trimmed="${line##[[:space:]]#}"
    [[ -z "$trimmed" || "$trimmed" == \#* ]] && continue
    trimmed="${trimmed/#\~/$HOME}"
    [[ -d "$trimmed/.git" ]] && DOT_REPOS+=("$trimmed")
  done < "$local_file"
fi

# ── Helpers ─────────────────────────────────────────────────────────────────

# Iterate repos, calling callback with (repo_path, display_name)
_dot_repos_each() {
  local callback="$1"
  local repo name
  for repo in "${DOT_REPOS[@]}"; do
    name="${repo:t}"
    if [[ ! -d "$repo/.git" ]]; then
      printf "  %s  %-24s %s\n" "-" "$name" "not found"
      continue
    fi
    "$callback" "$repo" "$name"
  done
}

# Collect repo info into local variables (caller must declare them)
_dot_repos_info() {
  local repo="$1"

  # Branch: handle detached HEAD
  _repo_branch=$(git -C "$repo" branch --show-current 2>/dev/null)
  if [[ -z "$_repo_branch" ]]; then
    _repo_branch="($(git -C "$repo" rev-parse --short HEAD 2>/dev/null))"
  fi

  # Dirty count
  _repo_dirty=$(git -C "$repo" status --porcelain 2>/dev/null | wc -l | tr -d ' ')

  # Ahead/behind: requires upstream tracking branch
  _repo_upstream=$(git -C "$repo" rev-parse --abbrev-ref '@{u}' 2>/dev/null)
  if [[ -n "$_repo_upstream" ]]; then
    local counts
    counts=$(git -C "$repo" rev-list --count --left-right '@{u}...HEAD' 2>/dev/null)
    _repo_behind="${counts%%$'\t'*}"
    _repo_ahead="${counts##*$'\t'}"
  else
    _repo_ahead=""
    _repo_behind=""
  fi
}

# ── Status ──────────────────────────────────────────────────────────────────
_dot_repos_status_line() {
  local repo="$1" name="$2"
  _dot_repos_info "$repo"

  local sync_info=""
  if [[ -z "$_repo_upstream" ]]; then
    sync_info="no upstream"
  else
    local parts=()
    [[ "$_repo_ahead" -gt 0 ]] 2>/dev/null && parts+=("${_repo_ahead} ahead")
    [[ "$_repo_behind" -gt 0 ]] 2>/dev/null && parts+=("${_repo_behind} behind")
    if (( ${#parts} > 0 )); then
      sync_info="${(j:, :)parts}"
    else
      sync_info="up to date"
    fi
  fi

  local dirty_info=""
  if [[ "$_repo_dirty" -gt 0 ]] 2>/dev/null; then
    dirty_info="${_repo_dirty} dirty"
  fi

  local status_icon="v"
  if [[ -n "$dirty_info" ]] || [[ "$_repo_ahead" -gt 0 ]] 2>/dev/null || [[ "$_repo_behind" -gt 0 ]] 2>/dev/null; then
    status_icon="*"
  fi

  local detail="${_repo_branch}"
  [[ -n "$dirty_info" ]] && detail+=", $dirty_info"
  detail+=", $sync_info"

  printf "  %s  %-24s %s\n" "$status_icon" "$name" "$detail"
}

# ── List ────────────────────────────────────────────────────────────────────
_dot_repos_list_line() {
  local repo="$1"
  echo "$repo"
}

# ── Pull ────────────────────────────────────────────────────────────────────
_dot_repos_pull_one() {
  local repo="$1" name="$2"

  echo "  $name: fetching..."
  if ! _dot_timeout 15 git -C "$repo" fetch --quiet 2>/dev/null; then
    echo "  $name: fetch timed out or failed"
    return 1
  fi

  local dirty
  dirty=$(git -C "$repo" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$dirty" -gt 0 ]] 2>/dev/null; then
    echo "  $name: $dirty uncommitted changes, skipping pull"
    return 0
  fi

  if ! git -C "$repo" pull --rebase --autostash 2>&1 | sed "s/^/  $name: /"; then
    echo "  $name: pull failed -- resolve with: git -C $repo rebase --abort"
    return 1
  fi
}

# ── Push ────────────────────────────────────────────────────────────────────
_dot_repos_push_one() {
  local repo="$1" name="$2"

  local upstream
  upstream=$(git -C "$repo" rev-parse --abbrev-ref '@{u}' 2>/dev/null)
  if [[ -z "$upstream" ]]; then
    return 0
  fi

  local ahead
  ahead=$(git -C "$repo" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
  if [[ "$ahead" -eq 0 ]] 2>/dev/null; then
    return 0
  fi

  echo "  $name: pushing $ahead commit(s)..."
  git -C "$repo" push 2>&1 | sed "s/^/  $name: /"
}

# ── Dispatcher ──────────────────────────────────────────────────────────────
_dot_repos() {
  local subcommand="${1:-status}"
  [[ -n "$1" ]] && shift

  case "$subcommand" in
    status)
      echo "Repository status:"
      echo ""
      _dot_repos_each _dot_repos_status_line
      echo ""
      ;;
    list)
      local repo
      for repo in "${DOT_REPOS[@]}"; do
        echo "$repo"
      done
      ;;
    pull)
      echo "Pulling repos..."
      echo ""
      _dot_repos_each _dot_repos_pull_one
      echo ""
      _dot_touch_update "repos-sync"
      ;;
    push)
      echo "Pushing repos..."
      echo ""
      _dot_repos_each _dot_repos_push_one
      echo ""
      ;;
    sync)
      echo "Syncing repos (pull + push)..."
      echo ""
      echo "-- Pull --"
      _dot_repos_each _dot_repos_pull_one
      echo ""
      echo "-- Push --"
      _dot_repos_each _dot_repos_push_one
      echo ""
      _dot_touch_update "repos-sync"
      ;;
    *)
      _dot_subcmd_error "repos" "$subcommand" "status|list|pull|push|sync"
      return 1
      ;;
  esac
}
