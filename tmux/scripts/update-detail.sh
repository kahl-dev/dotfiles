#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/cache-lib.sh"
DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
UPDATE_CACHE="$CACHE_DIR/tmux-update-check"

human_age() {
  local seconds="$1"
  if (( seconds < 3600 )); then
    echo "$((seconds / 60))m ago"
  elif (( seconds < 86400 )); then
    echo "$((seconds / 3600))h ago"
  else
    echo "$((seconds / 86400))d ago"
  fi
}

_touch() {
  touch "$CACHE_DIR/dot-last-${1}"
  rm -f "$UPDATE_CACHE"
}

now=$(date +%s)
categories=("brew|7|dot-last-brew-update" "mise|7|dot-last-mise-update"
            "tpm|30|dot-last-tpm-update" "repos|3|dot-last-repos-sync")

echo "Update Status"
echo "──────────────────────────────────────"
idx=1
for entry in "${categories[@]}"; do
  IFS='|' read -r name threshold_days cache_name <<< "$entry"
  threshold=$((threshold_days * 86400))
  mtime=$(file_mtime "$CACHE_DIR/$cache_name")
  age=$((now - mtime))
  age_str=$(human_age "$age")
  if (( age > threshold )); then
    printf "  %d) %-8s %-12s OVERDUE\n" "$idx" "$name" "$age_str"
  else
    remaining=$(( (threshold - age) / 86400 ))
    printf "  %d) %-8s %-12s (next in %dd)\n" "$idx" "$name" "$age_str" "$remaining"
  fi
  idx=$((idx + 1))
done

echo "──────────────────────────────────────"
echo "  a) Update all tools (brew+mise+tpm)"
echo "  r) Sync all repos"
echo "  q) Close"
echo ""
read -rsn1 choice

case "$choice" in
  1)
    echo ""
    echo "Updating Homebrew..."
    brew update && brew upgrade && { brew cleanup -s; _touch "brew-update"; }
    echo ""
    echo "Done. Press any key to close."
    read -rsn1
    ;;
  2)
    echo ""
    echo "Upgrading mise tools..."
    mise upgrade && _touch "mise-update"
    echo ""
    echo "Done. Press any key to close."
    read -rsn1
    ;;
  3)
    echo ""
    echo "Updating tmux plugins..."
    "$DOTFILES/tmux/plugins/tpm/bin/update_plugins" all && _touch "tpm-update"
    echo ""
    echo "Done. Press any key to close."
    read -rsn1
    ;;
  4|r)
    echo ""
    echo "Syncing repos..."
    for repo_dir in "$HOME/.dotfiles" "$HOME/repos/claude-config" "$HOME/repos/louis-claude-marketplace"; do
      [[ -d "$repo_dir/.git" ]] || continue
      name=$(basename "$repo_dir")
      echo "  $name: fetching..."
      timeout 15 git -C "$repo_dir" fetch --quiet 2>/dev/null || { echo "  $name: fetch timed out"; continue; }
      dirty=$(git -C "$repo_dir" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
      if (( dirty > 0 )); then
        echo "  $name: $dirty uncommitted changes, skipping pull"
      else
        git -C "$repo_dir" pull --rebase --autostash 2>&1 | sed "s/^/  $name: /"
      fi
      ahead=$(git -C "$repo_dir" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
      if [[ "$ahead" =~ ^[0-9]+$ ]] && (( ahead > 0 )); then
        git -C "$repo_dir" push 2>&1 | sed "s/^/  $name: /"
      fi
    done
    _touch "repos-sync"
    echo ""
    echo "Done. Press any key to close."
    read -rsn1
    ;;
  a)
    echo ""
    echo "Updating all tools..."
    echo "--- Homebrew ---"
    brew update && brew upgrade && { brew cleanup -s; _touch "brew-update"; }
    echo "--- mise ---"
    mise upgrade && _touch "mise-update"
    echo "--- tmux plugins ---"
    "$DOTFILES/tmux/plugins/tpm/bin/update_plugins" all && _touch "tpm-update"
    echo ""
    echo "Done. Press any key to close."
    read -rsn1
    ;;
  q|*) ;;
esac
