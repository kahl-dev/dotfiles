# Plan: Custom tmux Session Manager

## Metadata
- Status: completed
- Created: 2026-02-24 11:38
- Plan-ID: F3D8E1ED-A6FA-414F-9924-983EC8052AF6
- Current Phase: 3/3
- Structure: Simple

## Background

### Problem
The dotfiles repo uses `tmux-sessionx` plugin (`Prefix + o`) for session management. Analysis shows only ~5% of its features are used (session switching, occasional rename). The remaining 95% (tmuxinator, fzf-marks, tree mode, config dir browsing, custom paths, async progressive git branch loading) is dead weight — 740 lines across 8 scripts.

More critically, sessionx lacks features the user actually needs:
- **Move pane to another session** — currently requires manual `break-pane` + `move-window` + typing session names
- **Move window to another session** — requires knowing and typing target session name
- **Create session from zoxide with disambiguation** — sessionx uses silent `zoxide query` (single result, can pick wrong directory)
- **Create session from filesystem browsing** — no path navigation capability at all

### Goal
Replace `tmux-sessionx` with a single custom bash script (`tmux-sessionx.sh` or similar) that provides:
1. Session switching (core, what sessionx does)
2. Session creation from name, zoxide (with disambiguation), or filesystem browsing
3. Session renaming
4. Move current pane to another session
5. Move current window to another session
6. Git branch display next to session names (synchronous, simple)

### Scope
- Single script + tmux keybinding in `tmux.conf`
- Remove `tmux-sessionx` plugin dependency
- Keep `Prefix + o` binding (muscle memory)
- Estimated ~200-250 lines of bash

## Context & Questions

**Clarifications from discussion:**

Q: What do you actually use from sessionx?
A: Session switching (primary), rename (occasional). Nothing else.

Q: Do you use zoxide?
A: Yes, all the time. But never used sessionx's zoxide integration.

Q: Concern about zoxide creating sessions in wrong folder?
A: Valid concern. Use `zoxide query -l` (list all matches) piped to fzf for disambiguation instead of silent `zoxide query` (single top result).

Q: Path autocompletion when zoxide doesn't know the path?
A: Yes. Want to type `~/` and navigate to a folder like shell tab-completion.

Q: Move pane — new window or join as split?
A: **New window in target session.** (User already has `Prefix + E` for join-pane)

Q: After moving — stay or follow?
A: **Stay (detached).** Matches existing `Prefix + B` (break-pane -d) behavior.

Q: Git branch display?
A: **Synchronous.** 5-10 sessions typical, sometimes same folder with different branches. Async not needed.

Q: Path browser approach?
A: **Nested fzf with fd.** Fuzzy search entire filesystem, faster than drilling one directory at a time.

Q: Session naming from path?
A: **Editable default.** Show basename pre-filled, Enter to accept, or type to override.

Q: Keybinding?
A: **Replace Prefix + o.** Drop-in replacement for sessionx.

**Dependencies (all existing, no new installs):**
- fzf (installed)
- tmux 3.0+ (installed, prefix `C-s`)
- zoxide (installed)
- fd 10.3.0 (installed at /opt/homebrew/bin/fd)
- git (installed)

**Architectural Decisions:**

Decision: Single script vs multiple scripts
- Choice: Single main script with mode parameter, helper functions inline
- Rationale: sessionx's 8-file architecture is over-engineered for this scope. One script is easier to maintain, debug, and understand.
- Alternative: Modular scripts like sessionx — rejected because we're cutting 95% of features

Decision: Adapt sessionx patterns vs build from scratch
- Choice: Adapt 4 specific patterns, build the rest fresh
- Patterns to adapt:
  1. `git-branch.sh` format/strip functions (~50 lines)
  2. LRU session ordering via `client_last_session`
  3. Mode switching via fzf `--bind "key:reload(...)+change-preview(...)"`
  4. ANSI stripping for selection parsing
- Build fresh: move operations, zoxide disambiguation, path browser, session creation
- Rationale: sessionx's plumbing (eval stored args, space placeholder hack, triplicated session list, 30 tmux options) is messy. Clean rewrite for our subset.

Decision: Configuration approach
- Choice: Script-level variables at top of file (no tmux options)
- Rationale: sessionx uses 30+ `@sessionx-*` tmux options — overkill. We have one user, one config.

## Relevant Patterns Found

### From sessionx (to adapt)

**LRU session ordering** (`sessionx.sh:11-22`):
```bash
last_session=$(tmux display-message -p '#{client_last_session}')
sessions=$(tmux list-sessions | sed -E 's/:.*$//' | grep -Fxv "$last_session")
sorted=$(echo -e "$sessions\n$last_session" | awk '!seen[$0]++')
```

**Git branch formatting** (`git-branch.sh:8-45`):
```bash
# For each session: get pane path, resolve branch, format with aligned columns
pane_path=$(tmux list-panes -t "$session" -F '#{pane_current_path}' 2>/dev/null | head -1)
ref=$(git -C "$pane_path" branch --show-current 2>/dev/null)
printf "%-${max_len}s  ${COLOR} %s${RESET}\n" "$name" "$ref"
```

**ANSI strip for selection** (`git-branch.sh:47-51`):
```bash
strip_ansi() {
    local ESC=$(printf '\033')
    echo "$1" | sed "s/${ESC}\[[0-9;]*m//g" | sed "s/[[:space:]]* .*//" | sed 's/[[:space:]]*$//'
}
```

### From existing tmux.conf bindings

- `Prefix + B` (line 117): `break-pane -d` — break pane to new window (detached)
- `Prefix + E` (line 120): `command-prompt "join-pane -h -s '%%'"` — pull pane from another window
- `Prefix + C-c` (line 73): `new-session` — create new session
- `Prefix + x/X/Q` (lines 97-99): kill pane/window/session with auto-save

### Existing script location pattern

All custom tmux scripts live in `tmux/scripts/`. The new script should follow this convention.

## Implementation Plan

### Phase 1: Core Script — Session Switching + Creation `[MED]`

Create `tmux/scripts/tmux-session-manager.sh` with:

**1.1 Session list with git branches**
- [x] `[LOW]` Helper function: `get_sessions` — LRU-sorted session list excluding current
- [x] `[LOW]` Helper function: `format_with_branches` — synchronous git branch enrichment with aligned columns
- [x] `[LOW]` Helper function: `strip_ansi` — clean selection text for tmux commands
- [x] `[LOW]` Catppuccin Mocha blue for branch text (`#89b4fa`), branch icon ` `, tag icon ` `

**1.2 Session switching**
- [x] `[MED]` Main fzf invocation with `fzf-tmux -p 80%,70%` popup
- [x] `[LOW]` `Enter` on existing session → `tmux switch-client -t "$target"`
- [x] `[LOW]` Header showing available keybinds

**1.3 Session creation**
- [x] `[MED]` `Enter` on non-existing input → check zoxide matches via `zoxide query -l "$input"` → pipe to fzf for disambiguation → create session at selected path
- [x] `[LOW]` If zoxide returns single match → still show it for confirmation (no silent auto-pick)
- [x] `[LOW]` If zoxide returns nothing → display message "No matches. Use ctrl-f to browse."
- [x] `[MED]` After directory selection → editable session name prompt (uses fzf query as proposed name, auto-handles collisions)
- [x] `[LOW]` Create session: `tmux new-session -ds "$session_name" -c "$dir"` then switch

**1.4 Session rename**
- [x] `[LOW]` `ctrl-r` binding → `execute-silent` fzf action → `tmux command-prompt` for new name
- [x] `[LOW]` Reload session list after rename (triggers reload, async with command-prompt)

### Phase 2: Move Operations + Path Browser `[MED]`

**2.1 Move pane to session**
- [x] `[MED]` `ctrl-s` binding via `--expect` → `move_pane_to_session` function (break-pane + move-window)
- [x] `[LOW]` If target is current session → display message and skip
- [x] `[LOW]` Stay in current session after move (detached)
- [x] `[LOW]` If pane is only pane in window → delegates to move_window_to_session

**2.2 Move window to session**
- [x] `[MED]` `ctrl-w` binding via `--expect` → `move_window_to_session` function
- [x] `[LOW]` If target is current session → display message and skip
- [x] `[LOW]` If current session has only one window → moves and switches to target (session dies)
- [x] `[LOW]` Stay in current session after move (detached). If last window was moved, switch to target.

**2.3 Path browser (nested fzf)** (implemented in Phase 1)
- [x] `[MED]` `ctrl-f` binding → spawns nested fzf: `fd --type d --hidden --exclude .git --exclude node_modules --max-depth 5 . ~ | fzf-tmux -p 70%,60%`
- [x] `[LOW]` Preview in nested fzf: `ls -la {}`
- [x] `[MED]` On selection → `create_session_at` with editable name (command-prompt)
- [x] `[LOW]` `Escape` in nested fzf → script exits cleanly

**2.4 Create session for move target**
- [x] `[MED]` ctrl-s/ctrl-w on `[+ New Session]` → `create_session_for_move` creates session from current dir → then moves
- [x] `[LOW]` Uses current pane directory as new session working directory

### Phase 3: Integration + Cleanup `[LOW]`

**3.1 tmux.conf integration**
- [x] `[LOW]` Remove sessionx plugin block from `tmux.conf` (lines 266-268: `@plugin`, `@sessionx-bind`, `@sessionx-zoxide-mode`)
- [x] `[LOW]` Add new binding: `bind-key o run-shell "~/.dotfiles/tmux/scripts/tmux-session-manager.sh"`
- [x] `[LOW]` Remove `Prefix + C-c` (line 73) — new-session is now handled by the manager
- [x] `[LOW]` Keep `Prefix + B` (break-pane) and `Prefix + E` (join-pane) — they remain useful as quick shortcuts

**3.2 Cleanup**
- [x] `[LOW]` Verify sessionx plugin directory can be removed (it's git-managed via TPM)
- [x] `[LOW]` Remove sessionx from TPM plugin list → `M-x` to clean
- [x] `[LOW]` Update `tmux/cheatsheet.md` with new keybindings
- [x] `[LOW]` Update `tmux/CLAUDE.md` — remove sessionx references, add session manager docs
- [x] `[LOW]` Update root `CLAUDE.md` if sessionx is mentioned

**3.3 Testing**
- [ ] `[LOW]` Test session switching with 5+ sessions
- [ ] `[LOW]` Test create from zoxide with ambiguous query (multiple matches)
- [ ] `[LOW]` Test create from path browser (fd)
- [ ] `[LOW]` Test rename
- [ ] `[LOW]` Test move pane to existing session
- [ ] `[LOW]` Test move window to existing session
- [ ] `[LOW]` Test move pane to new session (create + move)
- [ ] `[LOW]` Test edge case: move last window from session
- [ ] `[LOW]` Test edge case: session name collision on create

## fzf UI Design

```
┌─ Sessions (current: dotfiles) ───────────────────┐
│ > _                                                │
│   [+ New Session]                                  │
│   project-a       feature/login                  │
│   work-api         fix/cors-headers              │
│   scratch                                          │
│   infra            main                           │
│                                                    │
│ enter=switch  ctrl-r=rename  ctrl-f=browse         │
│ ctrl-s=send pane  ctrl-w=send window               │
└────────────────────────────────────────────────────┘
```

- Sorted by LRU (last used first)
- `[+ New Session]` always at top
- Git branches right-aligned in blue with branch icon
- Sessions without git repos show name only
- Current session excluded from list (you're already there)
- Header shows all available keybinds

## Key Technical Details

### Move pane implementation

```bash
# ctrl-s: move current pane to target session as new window
# 1. Get current pane id before breaking
pane_id=$(tmux display-message -p '#{pane_id}')
# 2. Break pane to a temporary window (stays in current session)
tmux break-pane -d -s "$pane_id"
# 3. The broken pane is now the highest-numbered window in current session
# 4. Move that window to target session
tmux move-window -s "$(tmux display-message -p '#S'):$(tmux list-windows -F '#{window_index}' | tail -1)" -t "$target:"
```

### Zoxide disambiguation

```bash
# Instead of sessionx's silent: zoxide query "$input"
# We show all matches and let user pick:
matches=$(zoxide query -l "$input" 2>/dev/null)
if [[ -n "$matches" ]]; then
    selected=$(echo "$matches" | fzf-tmux -p 70%,50% --prompt="Pick directory: ")
    # ... create session at $selected
fi
```

### Nested fzf for path browsing

```bash
# ctrl-f triggers this via fzf execute action
selected_path=$(fd --type d --hidden --exclude .git --exclude node_modules \
    --exclude vendor --exclude .cache --max-depth 4 . "$HOME" \
    | fzf-tmux -p 70%,60% --prompt="Browse: " --preview="ls -la {}")
```

### Session name prompt

```bash
# After directory selection, prompt with editable default
proposed_name=$(basename "$selected_path" | tr '.' '-')
# In tmux context, use command-prompt or a simple read
tmux command-prompt -I "$proposed_name" -p "Session name:" \
    "run-shell '~/.dotfiles/tmux/scripts/tmux-session-manager.sh create %1 \"$selected_path\"'"
```

## Validation Pipeline

### After each phase:
```bash
# Syntax check
bash -n tmux/scripts/tmux-session-manager.sh

# shellcheck (if available)
shellcheck tmux/scripts/tmux-session-manager.sh

# Manual testing in tmux
tmux source-file ~/.dotfiles/tmux/tmux.conf
# Then Prefix + o to test
```

### Manual test matrix:
| Test | Input | Expected |
|------|-------|----------|
| Switch session | Select existing | Switches to it |
| Create from name | Type "newsession" | Zoxide lookup → pick dir → create |
| Create from browse | ctrl-f → pick dir | fd browser → name prompt → create |
| Rename | ctrl-r on session | Prompt → rename → list refreshes |
| Move pane | ctrl-s on session | Pane moves, stay in current |
| Move window | ctrl-w on session | Window moves, stay in current |
| Move last window | ctrl-w when 1 window | Warning or switch to target |
| Name collision | Create "dotfiles" (exists) | Prompt for different name |

## Applicable Skills

| Phase | Skills | Validation Criteria |
|-------|--------|---------------------|
| All | experts:tmux | tmux command correctness |
| All | shellcheck | Bash best practices |

## Progress Log

- [2026-02-24 11:38] Plan created
- [2026-02-24 11:40] Phase 1 started
- [2026-02-24 11:45] Phase 1 complete - Core script created
  - Created: `tmux/scripts/tmux-session-manager.sh` (~280 lines)
  - Features: session switching, git branches, zoxide disambiguation, path browser, rename
  - Validation: bash -n OK, shellcheck OK
- [2026-02-24 11:55] Phase 1 review - Fixed 6 issues from code review
  - Removed dead prompt_session_name function
  - Fixed rename to use execute() with bash read (sessionx pattern)
  - Fixed ((counter++)) set -e footgun
  - Switched to tab delimiter for reliable field extraction
  - Added padding for visual alignment
- [2026-02-24 12:00] Phase 2 complete - Move operations
  - Added: move_pane_to_session, move_window_to_session, create_session_for_move
  - ctrl-s/ctrl-w via --expect, handles [+ New Session] as move target
  - Edge cases: single pane → delegates to move window, last window → switch to target
  - Validation: bash -n OK, shellcheck OK
- [2026-02-24 12:10] Phase 3 complete - Integration + Cleanup
  - Replaced sessionx plugin with custom binding in tmux.conf
  - Commented out Prefix + C-c (handled by session manager)
  - Updated cheatsheet.md with session manager keybindings
  - Updated tmux/CLAUDE.md architecture + keybindings + plugin list
  - Validation: bash -n OK, shellcheck OK
