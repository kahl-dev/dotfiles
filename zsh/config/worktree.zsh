#!/usr/bin/env zsh

# 🌳 Git Worktree Helpers
# Project-agnostic worktree management with auto-detection.
# No configuration required — paths and config files are derived automatically.

# Portable file size checks (works on Linux + macOS)
zmodload zsh/stat 2>/dev/null

# ── Helper Functions ─────────────────────────────────────────────────────────

# Print styled error to stderr
_gwt_error() { print -P "%F{red}✘ $1%f" >&2; return 1; }

# Require git repository
_gwt_require_git_repo() {
  git rev-parse --git-dir &>/dev/null || _gwt_error "Not in a git repository"
}

# Get main worktree path via git-common-dir (stable from any worktree)
_gwt_main_path() {
  local common_dir
  common_dir="$(git rev-parse --git-common-dir 2>/dev/null)" || {
    _gwt_error "Cannot determine git common directory (bare repo?)"
    return 1
  }
  # Resolve to absolute path, strip trailing /.git
  common_dir="${common_dir:A}"
  echo "${common_dir%/.git}"
}

# Get default base directory (parent of main worktree)
_gwt_default_base() {
  local main_path
  main_path="$(_gwt_main_path)" || return 1
  echo "${main_path:h}"
}

# Auto-detect gitignored config files worth copying to new worktrees
# Execution order: skip junk dirs -> check file exists -> filter size -> match config patterns
_gwt_detect_local_configs() {
  local source_dir="$1"
  local file size

  git -C "$source_dir" ls-files -z --others --ignored --exclude-standard 2>/dev/null \
    | while IFS= read -r -d '' file; do
        # 1. Skip known junk directories
        case "$file" in
          vendor/*|node_modules/*|var/*|.cache/*|.git/*) continue ;;
          public/fileadmin/*|public/uploads/*|public/typo3temp/*|public/_assets/*) continue ;;
        esac

        # 2. Must be a regular file
        [[ -f "$source_dir/$file" ]] || continue

        # 3. Size filter: < 100KB
        size=$(zstat -L +size "$source_dir/$file" 2>/dev/null) || continue
        (( size > 102400 )) && continue

        # 4. Match config-like patterns
        case "$file" in
          # "local" in name — strongest signal
          *.local*|*local_*|*local.*) echo "$file" ;;
          # Environment files
          *.env|*.env.*|.env*) echo "$file" ;;
          # Config-named files only (not ALL .php/.yaml)
          config*.php|*config*.yaml|*config*.yml|*config*.toml) echo "$file" ;;
          # Explicit config basenames
          *.conf|*.ini|*.secrets*) echo "$file" ;;
        esac
      done
}

# ── Core Commands ────────────────────────────────────────────────────────────

# Add new worktree with automatic config file detection
_gwta() {
  _gwt_require_git_repo || return 1

  local branch_name="$1"
  if [[ -z "$branch_name" ]]; then
    _gwt_error "Usage: gwta <branch> [path]"
    return 1
  fi

  local base main_path worktree_path
  base="$(_gwt_default_base)" || return 1
  main_path="$(_gwt_main_path)" || return 1
  worktree_path="${2:-$base/$branch_name}"

  # Create worktree (git handles existing vs new branch)
  if git show-ref --verify --quiet "refs/heads/$branch_name"; then
    print -P "%F{blue}📂 Checking out existing branch '$branch_name'...%f"
    git worktree add "$worktree_path" "$branch_name" || return 1
  else
    print -P "%F{blue}📂 Creating new branch '$branch_name'...%f"
    git worktree add -b "$branch_name" "$worktree_path" || return 1
  fi

  print -P "%F{green}✔ Worktree created at: $worktree_path%f"

  # Auto-detect local configs from main worktree
  local -a config_files
  config_files=( ${(f)"$(_gwt_detect_local_configs "$main_path")"} )
  # Remove empty entries
  config_files=( ${config_files:#} )

  if (( ${#config_files} > 0 )); then
    echo ""
    print -P "%F{yellow}📄 Found ${#config_files} local config file(s) in main worktree:%f"
    local file
    for file in "${config_files[@]}"; do
      echo "   $file"
    done
    echo ""

    local reply
    read -q "reply?Copy these config files to new worktree? [Y/n] " || true
    echo ""

    if [[ "$reply" != "n" ]]; then
      local copy_success=0
      local copy_total=${#config_files}
      for file in "${config_files[@]}"; do
        if mkdir -p "$worktree_path/${file:h}" && cp "$main_path/$file" "$worktree_path/$file"; then
          (( copy_success++ ))
        else
          print -P "%F{red}✘ Failed to copy: $file%f" >&2
        fi
      done
      if (( copy_success == copy_total )); then
        print -P "%F{green}✔ Copied ${copy_success} config file(s)%f"
      elif (( copy_success > 0 )); then
        print -P "%F{yellow}⚠ Copied ${copy_success}/${copy_total} config file(s)%f"
      else
        print -P "%F{red}✘ Failed to copy any config files%f" >&2
      fi
    fi
  fi

  # Switch to new worktree
  builtin cd "$worktree_path" || return 1
  command_exists zoxide && zoxide add "$(pwd)"
  print -P "%F{green}✔ Now in: $(pwd)%f"
}

# Switch between worktrees (interactive with fzf or by pattern)
_gwts() {
  _gwt_require_git_repo || return 1

  if [[ -z "$1" ]]; then
    # Interactive selection via fzf
    if ! command_exists fzf; then
      _gwt_error "fzf is required for interactive selection. Pass a pattern instead."
      return 1
    fi

    local selected
    selected=$(git worktree list --porcelain | \
      awk '
        /^worktree / { wt = substr($0, 10) }
        /^HEAD / { head = $2 }
        /^branch / { branch = substr($0, 8); gsub(/^refs\/heads\//, "", branch);
                     printf "%-50s %-30s %s\n", wt, branch, head }
        /^$/ { if (wt && !branch) printf "%-50s %-30s %s\n", wt, "(detached)", head; wt=""; branch=""; head="" }
      ' | \
      fzf --prompt="Select worktree: " \
          --height=60% \
          --reverse \
          --preview 'echo "📁 Path: {1}"; echo "🌿 Branch: {2}"; echo "📝 Last commit:"; git -C {1} log -1 --oneline 2>/dev/null; echo; echo "📊 Status:"; git -C {1} status -s 2>/dev/null' \
          --preview-window=right:50%)

    if [[ -n "$selected" ]]; then
      local path
      path=$(echo "$selected" | awk '{print $1}')
      builtin cd "$path" || return 1
      command_exists zoxide && zoxide add "$(pwd)"
    fi
    return
  fi

  # Pattern matching — use literal string matching (not regex)
  local path
  path=$(git worktree list --porcelain | awk -v pattern="$1" '
    /^worktree / {
      wt = substr($0, 10)
      if (index(wt, pattern) > 0) { print wt; exit }
    }')

  if [[ -n "$path" ]]; then
    builtin cd "$path" || return 1
    command_exists zoxide && zoxide add "$(pwd)"
  else
    _gwt_error "Worktree not found: $1"
    git worktree list
    return 1
  fi
}

# List worktrees with formatted output
_gwtl() {
  _gwt_require_git_repo || return 1

  echo "🌳 Git Worktrees:"
  echo "=================="

  local current_path
  current_path=$(git rev-parse --show-toplevel 2>/dev/null)

  git worktree list --porcelain | \
  awk -v current="$current_path" '
    /^worktree / {
      if (path) {
        if (path == current) {
          printf "→ %-50s %-30s %s\n", path, branch, substr(head, 1, 8)
        } else {
          printf "  %-50s %-30s %s\n", path, branch, substr(head, 1, 8)
        }
      }
      path = substr($0, 10)
      branch = "(detached)"
      head = ""
    }
    /^HEAD / { head = $2 }
    /^branch / { branch = substr($0, 8); gsub(/^refs\/heads\//, "", branch) }
    END {
      if (path) {
        if (path == current) {
          printf "→ %-50s %-30s %s\n", path, branch, substr(head, 1, 8)
        } else {
          printf "  %-50s %-30s %s\n", path, branch, substr(head, 1, 8)
        }
      }
    }'
}

# Remove worktree with safety checks
_gwtr() {
  _gwt_require_git_repo || return 1

  local worktree_path="$1"
  local main_path
  main_path="$(_gwt_main_path)" || return 1

  if [[ -z "$worktree_path" ]]; then
    # Interactive selection via fzf
    if ! command_exists fzf; then
      _gwt_error "fzf is required for interactive selection. Pass a worktree path instead."
      return 1
    fi

    local selected
    selected=$(git worktree list --porcelain | \
      awk -v main="$main_path" '
        /^worktree / {
          if (wt && wt != main) {
            printf "%-50s %s\n", wt, branch
          }
          wt = substr($0, 10)
          branch = "(detached)"
        }
        /^branch / { branch = substr($0, 8); gsub(/^refs\/heads\//, "", branch) }
        END {
          if (wt && wt != main) {
            printf "%-50s %s\n", wt, branch
          }
        }' | \
      fzf --prompt="Select worktree to remove: " \
          --height=60% \
          --reverse \
          --preview 'echo "⚠️  Will remove worktree: {1}"; echo "🌿 Branch: {2}"; echo; echo "📊 Status:"; git -C {1} status -s 2>/dev/null; echo; echo "📤 Unpushed commits:"; git -C {1} log --oneline @{u}..HEAD 2>/dev/null || echo "No upstream branch"')

    if [[ -n "$selected" ]]; then
      worktree_path=$(echo "$selected" | awk '{print $1}')
    else
      return
    fi
  fi

  # Validate: must not be the main worktree
  if [[ "${worktree_path:A}" == "${main_path:A}" ]]; then
    _gwt_error "Cannot remove the main worktree"
    return 1
  fi

  # Get branch name
  local branch_name
  branch_name=$(git -C "$worktree_path" branch --show-current 2>/dev/null)

  # Check for uncommitted changes
  if ! git -C "$worktree_path" diff --quiet 2>/dev/null || ! git -C "$worktree_path" diff --staged --quiet 2>/dev/null; then
    _gwt_error "Worktree has uncommitted changes"
    echo "   Path: $worktree_path"
    echo "   Branch: ${branch_name:-(detached)}"
    echo ""
    echo "Options:"
    echo "  1. Commit your changes: cd $worktree_path && git commit"
    echo "  2. Stash your changes: cd $worktree_path && git stash"
    echo "  3. Force remove: git worktree remove --force $worktree_path"
    return 1
  fi

  # Check for unpushed commits (warn on local-only branches instead of treating as 0)
  local unpushed_count
  unpushed_count=$(git -C "$worktree_path" rev-list --count @{u}..HEAD 2>/dev/null)
  if [[ $? -ne 0 ]]; then
    # No upstream — warn but don't block
    print -P "%F{yellow}⚠ Branch '${branch_name:-(detached)}' has no upstream — commits may be local-only%f"
  elif (( unpushed_count > 0 )); then
    _gwt_error "Worktree has $unpushed_count unpushed commit(s)"
    echo "   Path: $worktree_path"
    echo "   Branch: ${branch_name:-(detached)}"
    echo ""
    echo "Unpushed commits:"
    git -C "$worktree_path" log --oneline @{u}..HEAD
    echo ""
    echo "Options:"
    echo "  1. Push your commits: cd $worktree_path && git push"
    echo "  2. Force remove: git worktree remove --force $worktree_path"
    return 1
  fi

  # If we're currently inside the worktree being removed, cd to main first
  local current_toplevel
  current_toplevel=$(git rev-parse --show-toplevel 2>/dev/null)
  if [[ "${current_toplevel:A}" == "${worktree_path:A}" ]]; then
    print -P "%F{yellow}📍 Moving to main worktree first...%f"
    builtin cd "$main_path" || return 1
  fi

  echo "✅ Removing worktree: $worktree_path"
  echo "   Branch '${branch_name:-(detached)}' will be preserved"
  git worktree remove "$worktree_path" || return 1
  echo "✅ Worktree removed successfully"
}

# Prune stale worktree entries
_gwtp() {
  _gwt_require_git_repo || return 1
  git worktree prune
  echo "✅ Pruned stale worktrees"
}

# Jump to main worktree
_gwtmain() {
  _gwt_require_git_repo || return 1
  builtin cd "$(_gwt_main_path)" || return 1
  command_exists zoxide && zoxide add "$(pwd)"
}

# Show help
_gwth() {
  echo "🌳 Git Worktree Helper Commands"
  echo "================================"
  echo ""
  echo "📚 Commands:"
  echo "  gwta <branch> [path]  - Add new worktree (auto-detects config files to copy)"
  echo "  gwts [pattern]        - Switch between worktrees (interactive fzf or by pattern)"
  echo "  gwtl                  - List all worktrees with branch info"
  echo "  gwtr [path]           - Remove worktree with safety checks"
  echo "  gwtp                  - Prune stale worktree entries"
  echo "  gwtmain               - Jump to main worktree"
  echo "  gwth                  - Show this help message"
  echo ""
  echo "✨ Features:"
  echo "  - Zero configuration — auto-detects paths from git-common-dir"
  echo "  - Auto-detects gitignored config files (.env, *.local*, config*.php, etc.)"
  echo "  - Prompts before copying config files to new worktrees"
  echo "  - Interactive fzf selection with preview (branch, status, last commit)"
  echo "  - Safety checks: uncommitted changes, unpushed commits, main worktree protection"
  echo "  - Automatically updates zoxide for quick navigation"
  echo ""
  echo "💡 Examples:"
  echo "  gwta feature/new-ui              # Create worktree next to main worktree"
  echo "  gwta hotfix-123 ~/custom/path    # Create at custom absolute path"
  echo "  gwts                             # Interactive worktree switcher"
  echo "  gwts feature                     # Switch to first worktree matching 'feature'"
  echo "  gwtl                             # Show all worktrees"
  echo "  gwtr                             # Interactive worktree removal"
  echo "  gwtp                             # Prune stale entries"
  echo "  gwtmain                          # Jump to main worktree"
}

# ── Aliases ──────────────────────────────────────────────────────────────────

alias gwta='_gwta'
alias gwts='_gwts'
alias gwtl='_gwtl'
alias gwtr='_gwtr'
alias gwth='_gwth'
alias gwtp='_gwtp'
alias gwtmain='_gwtmain'

# ── Completions ──────────────────────────────────────────────────────────────

# Branch completion for gwta (reuses git-checkout's branch completer)
compdef _git gwta=git-checkout

# Worktree path completion for gwts/gwtr
_gwt_complete_worktrees() {
  local -a worktrees
  worktrees=( ${(f)"$(git worktree list --porcelain 2>/dev/null | awk '/^worktree /{print substr($0, 10)}')"} )
  _describe 'worktree' worktrees
}
compdef _gwt_complete_worktrees gwts gwtr
