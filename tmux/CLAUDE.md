# 🖥️ Tmux Configuration

Custom adaptive tmux setup with responsive status bar, Catppuccin Mocha theme, cross-platform support (macOS + Linux), and clipboard portability via rclip.

**Prefix key**: `Ctrl+S` (not default `Ctrl+B`)
**Minimum tmux version**: 3.0+ (recommended 3.3+ for `#{E:...}`, `#{T;...}`, `#[align=...]`)

## 📐 Architecture

```
tmux/
├── tmux.conf              # Main config (keybindings, plugins, pane nav, clipboard)
├── custom-status.conf     # Status bar layout, colors, toggles
├── tmux.remote.conf       # SSH-specific overrides (auto-loaded via if-shell)
├── .tmux.reset.conf       # ⚠️ AUTO-GENERATED — never hand-edit
├── createTmuxReset.sh     # Generates .tmux.reset.conf from tmux defaults
├── tmux.popup.sh          # Floating popup session helper
├── cheatsheet.md          # Keybinding reference (rendered by Prefix+?)
├── plugins/               # TPM-managed plugins
├── resurrect/             # Session save files (tmux-resurrect)
└── scripts/
    ├── tmux-session-manager.sh    # 🔑 Session manager (switch, create, rename, move pane/window)
    ├── cache-lib.sh               # 🔧 Shared cache utilities (sourced by all metric scripts)
    ├── status-line-main.sh        # 🔑 Main renderer — assembles all segments
    ├── cpu-simple.sh              # CPU usage % (bare integer)
    ├── mem-simple.sh              # RAM usage % (bare integer)
    ├── disk-simple.sh             # Disk usage % (bare integer)
    ├── uptime-simple.sh           # Compact uptime (18d0h, 5h32m, 12m)
    ├── claude-usage.sh            # Claude Code OAuth quota (5h|7d|budget|pace)
    ├── host-icon.sh               # OS-specific Nerd Font icon
    ├── hostname-display.sh        # Machine name (empty on primary Mac)
    ├── lit-info-urls.sh           # TYPO3 project URL opener (Prefix+U)
    ├── tmux-cheatsheet.sh         # Renders cheatsheet.md via glow
    ├── tmux-cheatsheet-search.sh  # fzf keybinding search
    ├── update-check.sh            # Staleness count for status bar (brew/mise/tpm/repos)
    └── update-detail.sh           # Interactive update popup (Prefix+D)
```

## 🎨 Visual Conventions

### Nerd Font Icons ONLY — No Emoji

**CRITICAL**: Never use emoji (💻🔍⚡) in the tmux status bar. Always use Nerd Font icons.

| Segment | Icon | Nerd Font Name | Color |
|---------|------|----------------|-------|
| CPU | 󰻠 | nf-md-cpu | `$YELLOW` |
| RAM | 󰘚 | nf-md-ram | `$GREEN` |
| Disk | 󰋊 | nf-md-harddisk | `$BLUE` |
| Uptime | 󰅐 | nf-md-clock-outline | `$DIM` |
| Sessions | 󰘔 | nf-md-monitor-multiple | `$DIM` |
| Claude | 󰚩 | nf-md-robot | `$DIM` |
| Update | 󰚰 | nf-md-update | per-count color |
| 5h window | 󰥔 | nf-md-clock-fast | per-value color |
| 7d window | 󰃭 | nf-md-calendar-week | per-value color |
| Zoom | 󰍉 | nf-md-magnify | — |
| macOS |  | nf-fa-apple | `$BLUE` |
| Linux | (distro-specific) | nf-linux-* | `$BLUE` |

### Catppuccin Mocha Color Palette

```bash
BG="#1e1e2e"       TEXT="#cdd6f4"     BLUE="#89b4fa"
GREEN="#a6e3a1"    YELLOW="#f9e2af"   RED="#f38ba8"
PEACH="#fab387"    DIM="#6c7086"      SURFACE="#313244"
```

Colors are exported as `TMUX_*` environment variables in `custom-status.conf`. Scripts read these via `${TMUX_*:-fallback}` — env vars are the single source of truth inside tmux, fallbacks enable standalone testing.

### Color Thresholds

Used for CPU, RAM, Disk, and Claude usage percentages:

| Value | Color | Meaning |
|-------|-------|---------|
| <50% | `$BLUE` | Normal |
| 50-79% | `$PEACH` | Warning |
| ≥80% | `$RED` | Critical |

### Pane Borders

Invisible — styled `fg=black,bg=black` to blend with terminal background.

### Window Naming

`automatic-rename-format '#{b:pane_current_path}'` — windows show directory basename, not program name.

## 📏 Responsive Width Tiers

`status-line-main.sh` receives `#{client_width}` from tmux and adapts:

| Width | Resources | Environment | Claude | Update | Hostname |
|-------|-----------|-------------|--------|--------|----------|
| **≥120** (wide) | CPU/RAM/Disk | Uptime + Sessions | Full (with pace) | If stale | Yes |
| **90-119** (medium) | CPU/RAM/Disk | Hidden | Full (with pace) | If stale | If ≥100 |
| **<90** (narrow) | CPU/RAM only | Hidden | Compact (% only) | If stale | Hidden |

**Full Claude**: `󰚩 󰥔6%/󰃭44% ▲28%/d`
**Compact Claude**: `󰥔6%/󰃭44%`

Config passes width: `#(~/.dotfiles/tmux/scripts/status-line-main.sh #{client_width})`

**Status bar layout** (single line, position top):
```
[host-icon] session_name [windows...]          ...right-aligned: [resources │ env │ claude │ update │ hostname]
```

## 🔑 Keybindings

### Status & Config

| Key | Action |
|-----|--------|
| `Prefix + R` | Reload status configuration |
| `Prefix + C` | Toggle Claude usage display on/off |
| `Prefix + D` | Update status detail popup (brew/mise/tpm/repos staleness) |
| `Prefix + ?` | Show cheatsheet (glow popup, fallback: less) |
| `Prefix + /` | fzf keybinding search (copies selection via rclip) |

### Apps Key Table (`Prefix + a`)

Enters a custom key table with app launchers. **Convention**: lowercase = new window, UPPERCASE = floating popup.

| Key | Window | Popup | App |
|-----|--------|-------|-----|
| `g` / `G` | lazygit | lazygit popup | Git client |
| `y` / `Y` | yazi | yazi popup | File manager |
| `b` / `B` | btop | btop popup | System monitor |
| `m` / `M` | glow | glow popup | Markdown viewer |
| `Escape` | — | — | Exit apps table |

All apps inherit current pane's working directory. Status bar shows `󰀻 APPS` in yellow when in this table.

### Navigation

| Key | Action |
|-----|--------|
| `C-h/j/k/l` | Smart pane navigation (vim/nvim/fzf-aware via `if-shell`) |
| `C-\` | Jump to last pane (vim-aware) |
| `C-Shift-Left/Right` | Swap window AND auto-select the swapped position |
| `Prefix + o` | Session manager (switch, create, rename, move pane/window) |
| `Prefix + u` | Extract and open URLs from pane (tmux-fzf-url → ropen) |
| `Prefix + U` | Open TYPO3 project URLs (lit-info, conditional on `~/repos/li-tools`) |

### Kill Operations (Auto-Save)

All kill commands trigger `tmux-resurrect` save first to prevent ghost sessions on restore:

| Key | Action |
|-----|--------|
| `Prefix + x` | Kill pane (saves session state) |
| `Prefix + X` | Kill window (saves session state) |
| `Prefix + Q` | Kill session (saves session state) |

### Nested Sessions

| Key | Action |
|-----|--------|
| `Ctrl+]` | Toggle outer tmux off/on (sets `key-table off`) |

Status bar background changes to `colour24` when nested mode is active (outer tmux disabled).

## 📋 Clipboard: rclip Everywhere

**Global clipboard command**: `rclip` — NOT pbcopy/xclip. Works across local, SSH, and nested sessions.

- `set -s set-clipboard off` + `set -s copy-command 'rclip'`
- OSC52 fallback when Remote Bridge unavailable
- All copy-mode bindings (vi AND emacs) route through rclip:
  - `v` = begin-selection, `y` = copy, `Y` = copy line, `Enter` = copy
  - Double-click = select word + auto-copy, Triple-click = select line + auto-copy
  - Mouse drag stays in copy mode on release

## 🔌 Plugins (7 total, TPM-managed)

| Plugin | Purpose | Key Config |
|--------|---------|------------|
| **tpm** | Plugin manager | `M-i` install, `M-u` update, `M-x` clean |
| **tmux-resurrect** | Save/restore sessions | Saves ssh, vi, vim, nvim, man, tail, top, htop |
| **tmux-continuum** | Auto-save every 15min | `@continuum-restore 'on'` for auto-restore on start |
| **tmux-floax** | Floating window management | — |
| **tmux-fzf-url** | URL extraction from pane | `Prefix + u`, opens via `ropen`, 2000 URL history |
| **tmux-prefix-highlight** | Shows prefix active state | Integrated in status-right |

**Removed plugins** (replaced by custom scripts): catppuccin/tmux, tmux-cpu, tmux-loadavg, vim-tmux-navigator, tmux-sessionx.

**Session-closed hook**: Fires resurrect save on session close to prevent ghost sessions on restore.

## 🌐 Remote Session Support

Auto-detected via `if-shell 'test -n "$SSH_CLIENT"'` → loads `tmux.remote.conf`:

- Status bar moves to **bottom** (top on local)
- OSC52 clipboard enabled (`set -s set-clipboard on`)
- SSH agent socket managed via symlink: `~/.ssh/ssh_auth_sock` → actual socket
- Hooks refresh SSH agent on: session-created, client-attached
- Fallback: finds working socket in `/tmp/ssh-*/agent.*`
- Update check disabled (`@show-update-check "off"`) — tools like brew/mise not installed on remote

## 🔧 Script Pattern

All status scripts source `cache-lib.sh` for shared cache utilities:

```bash
#!/usr/bin/env bash
set -euo pipefail

# 1. Source shared cache library
source "$(dirname "$0")/cache-lib.sh"
CACHE_FILE="$CACHE_DIR/tmux-<name>"
check_cache "$CACHE_FILE" <TTL> && exit 0

# 2. Platform-specific data collection
# 3. Integer validation before arithmetic
[[ "$value" =~ ^[0-9]+$ ]] || value=0

# 4. Cache and output bare value (caller formats)
write_cache "$CACHE_FILE" "$result"
```

`cache-lib.sh` provides: `CACHE_DIR` setup, `file_mtime FILE` (epoch mtime or 0), `check_cache FILE TTL` (returns 0 on hit), `write_cache FILE VALUE`.

**Rules:**
- Output bare integers — `status-line-main.sh` adds `%`, icons, colors
- Cross-platform: cache-lib handles `stat` branching on `uname`
- Silent failure: any error → `exit 0` or fallback to `"0"` (segment vanishes gracefully)
- Validate ALL values as integers before arithmetic (`[[ "$var" =~ ^[0-9]+$ ]]`)
- Cache at `${XDG_CACHE_HOME:-$HOME/.cache}/tmux-<name>`

### Cache Durations

| Script | TTL | Reason |
|--------|-----|--------|
| cpu-simple.sh | 3s | Changes rapidly |
| mem-simple.sh | 5s | Changes rapidly |
| disk-simple.sh | 30s | Changes slowly |
| uptime-simple.sh | 60s | Changes slowly |
| claude-usage.sh | 60s | API rate limiting |
| host-icon.sh | 3600s | Never changes at runtime |
| hostname-display.sh | 300s | Never changes at runtime |
| update-check.sh | 60s | Checks timestamp ages only |

## 🤖 Claude Usage Segment

Uses Anthropic OAuth API — no Python, no browser cookies, no Cloudflare bypass.

**Credential sources:**
- macOS: Keychain → `security find-generic-password -s "Claude Code-credentials" -w` → `.claudeAiOauth.accessToken`
- Linux: `~/.claude/.credentials.json` → same jq path

**API**: `curl` to `api.anthropic.com/api/oauth/usage` with header `anthropic-beta: oauth-2025-04-20`

**Output format**: `5h_pct|7d_pct|daily_budget|days_left|workdays_left|pace`

**Pace calculation**: `daily_budget = remaining% / days_left`, compared to ideal 14%/day (100/7). Under = `▲` green, over = `▼` peach/red (red if budget < 8%).

**Token expiry**: 401 → jq fails → silent exit → segment vanishes. Refreshes automatically when Claude Code runs next.

**Toggle**: `Prefix + C` flips `@show-claude-usage` on/off.

## 󰚰 Update Staleness Indicator

Tracks when tools were last updated via timestamp files in `$CACHE_DIR`. Zero-cost in tmux — only `stat` calls, no network or git.

**Timestamp files** (in `${XDG_CACHE_HOME:-$HOME/.cache}/`):

| File | Written by |
|------|------------|
| `dot-last-brew-update` | `dot brew update`, `dot update` (brew step) |
| `dot-last-mise-update` | `dot mise upgrade`, `dot update` (mise step) |
| `dot-last-tpm-update` | `dot update` (tpm step) |
| `dot-last-repos-sync` | `dot repos pull`, `dot repos sync` |

**Staleness thresholds**: brew 7d, mise 7d, tpm 30d, repos 3d.

**Color thresholds**: 1 stale = `$BLUE`, 2 = `$PEACH`, 3+ = `$RED`.

**Missing timestamp = stale** (never updated triggers indicator immediately).

**Cache invalidation**: `_dot_touch_update()` in `dot.zsh` touches the timestamp and deletes `tmux-update-check` cache to force tmux refresh.

**Toggle**: `@show-update-check` on/off (disabled in `tmux.remote.conf`).

**Detail popup**: `Prefix + D` opens `update-detail.sh` — shows ages, allows updating individual categories or all at once.

## ⚠️ Platform Gotchas

- **macOS APFS disk**: Use `/System/Volumes/Data` not `/` — root shows read-only system volume (~30% instead of real ~91%)
- **macOS `stat`**: Uses `-f %m`, Linux uses `-c %Y` — never chain with `||`, always branch on `uname`
- **macOS ISO 8601**: `date -j -f` doesn't handle `Z` suffix or fractional seconds — strip before parsing
- **`tmux display -p ""`**: Outputs empty line to stdout — always redirect to `/dev/null`
- **`run-shell` multi-line**: tmux parses newlines poorly — use one-liners for keybindings
- **macOS `memory_pressure`**: Primary source for RAM %, `vm_stat` as fallback (page counts need integer validation)
- **`df -P`**: Forces POSIX output format — consistent across platforms
- **`C-\` in if-shell**: Needs double-escaped backslash (`C-\\`) for vim-aware pane nav

## 🏗️ Adding New Segments

1. Create `scripts/<name>-simple.sh` following the script pattern above
2. Output bare value (integer or short string)
3. Add cache with appropriate TTL
4. In `status-line-main.sh`:
   - Call script in appropriate block
   - Use Nerd Font icon (find at nerdfonts.com/cheat-sheet)
   - Apply `color_by_threshold` for percentage values
   - Respect width tiers — add to narrow only if essential
5. Test all three width tiers: `bash status-line-main.sh 200`, `100`, `80`
6. Update this CLAUDE.md with the new segment
