# Tmux Configuration Documentation

This document covers the complete tmux setup in this dotfiles repository.

## Overview

This tmux configuration provides:
- **Advanced clipboard integration** - Universal clipboard via `rclip` with remote support
- **Smart pane navigation** - Vim-aware navigation and plugin ecosystem
- **Session management** - Auto-save/restore with tmux-resurrect and tmux-continuum
- **Remote session support** - SSH-optimized configuration and nested session handling

## Configuration Structure

```
tmux/
├── tmux.conf              # Main configuration file
├── custom-status.conf     # Single-line status bar configuration
├── tmux.remote.conf      # SSH/remote session optimizations
├── .tmux.reset.conf      # Clean slate configuration reset
├── scripts/              # Status bar scripts and utilities
│   ├── status-line-main.sh      # System monitoring (CPU, memory)
│   ├── cpu-simple.sh            # Cached CPU monitoring
│   ├── mem-simple.sh            # Cached memory monitoring
│   ├── host-icon.sh             # System icon detection
│   ├── hostname-display.sh      # Smart hostname formatting
│   ├── lit-info-urls.sh         # Project URL helper
│   ├── tmux-session-manager.sh   # Session manager (switch, create, rename, move)
│   ├── tmux-which-key.sh         # Which-key menu (nested submenus for apps/tpm)
│   ├── tmux-cheatsheet.sh        # Cheatsheet popup
│   ├── update-check.sh           # Staleness count for status bar
│   └── update-detail.sh          # Interactive update popup
├── plugins/              # TPM plugin directory
└── resurrect/           # Session save data
```

## Key Bindings Reference

### Prefix Key: `Ctrl+S`

#### Session & Window Management
| Key | Action | Description |
|-----|--------|-------------|
| `o` | Session manager | Switch, create, rename, delete, move pane/window |
| `c` | `new-window` | Create new window in current directory |
| `x` | `kill-pane` | Kill current pane |
| `X` | `kill-window` | Kill current window |
| `Q` | `kill-session` | Kill current session (with confirmation) |

#### Panes Layer (`Prefix + v`)

Enter panes mode with `Prefix + v`, then press a key:

**Layouts:**
| Key | Action | Mnemonic |
|-----|--------|----------|
| `=` | Balance all panes equally | equal sign |
| `t` | Tiled auto grid | **t**iled |
| `m` | Main-vertical (big left) | **m**ain |
| `M` | Main-horizontal (big top) | **M**ain |
| `1` | Max 1 row (all side-by-side) | row count |
| `2` | Max 2 rows | row count |
| `3` | Max 3 rows | row count |

**Split / Structure:**
| Key | Action | Mnemonic |
|-----|--------|----------|
| `\|` | Split horizontal | visual |
| `-` | Split vertical | visual |
| `_` | Full-width vertical split | visual |
| `j` | Join pane from another window | **j**oin |
| `b` | Break pane out to new window | **b**reak |

**Swap / Move:**
| Key | Action | Mnemonic |
|-----|--------|----------|
| `h` | Swap with previous pane | vim left |
| `l` | Swap with next pane | vim right |
| `s` | Swap by number (overlay) | **s**wap |
| `r` | Rotate all panes | **r**otate |

**Manage:**
| Key | Action |
|-----|--------|
| `x` | Kill pane |
| `z` | Zoom/unzoom |
| `Escape` | Cancel |

#### Pane Navigation (Vim-aware)
| Key | Action | Description |
|-----|--------|-------------|
| `Ctrl+H` | `select-pane -L` | Move to left pane (or vim split) |
| `Ctrl+J` | `select-pane -D` | Move to pane below (or vim split) |
| `Ctrl+K` | `select-pane -U` | Move to pane above (or vim split) |
| `Ctrl+L` | `select-pane -R` | Move to right pane (or vim split) |

#### Pane Resizing
| Key | Action | Description |
|-----|--------|-------------|
| `Left/Right/Up/Down` | `resize-pane` | Resize pane by 5 units |
| `Ctrl+H/J/K/L` | `resize-pane` | Resize pane by 5 units (vim-style) |

#### Copy Mode & Clipboard
| Key | Action | Description |
|-----|--------|-------------|
| `Enter` | `copy-mode` | Enter copy mode |
| `Ctrl+[` | `copy-mode` | Enter copy mode (alternative) |
| `v` | `begin-selection` | Start selection (in copy mode) |
| `y` | `copy-pipe-and-cancel 'rclip'` | Copy selection to clipboard |
| `Y` | `select-line + copy-pipe` | Copy entire line via rclip |
| `o` | `other-end` | Switch selection ends |

#### Plugin & Tool Shortcuts
| Key | Action | Description |
|-----|--------|-------------|
| `?` | Which-key menu | All bindings with nested submenus (apps, tpm) |
| `o` | Session manager | Switch, create, rename, delete, move pane/window |
| `u` | FZF URL | Open URL finder |
| `Tab` | Extrakto | Fuzzy extract text from pane (paths, hashes, words) |
| `F` | Thumbs | Vimium-style hint copy with letter labels |
| `/` | Fuzzback | Fuzzy search scrollback buffer with preview |
| `*` | Cowboy | Kill hung process in current pane |
| `U` | TYPO3 URLs | Open project URLs via lit-info (conditional) |
| `a` | Apps layer | g/y/b/m = window, G/Y/B/M = popup (lazygit, yazi, btop, glow) |
| `v` | Panes layer | Layouts, splits, swap, structure (see Panes Layer section) |
| `t` | TPM layer | i = install, u = update, x = clean |

#### Remote Session Controls
| Key | Action | Description |
|-----|--------|-------------|
| `Ctrl+]` | Toggle nested mode | Enable/disable outer tmux for nested sessions |
| `r` | Reload config | Source tmux.conf and display message |

#### Window Management
| Key | Action | Description |
|-----|--------|-------------|
| `Ctrl+Shift+Left` | Move window left | Swap window with previous |
| `Ctrl+Shift+Right` | Move window right | Swap window with next |

## Plugin Ecosystem

### Core Plugins

#### TPM (Tmux Plugin Manager)
- **Purpose**: Plugin management system
- **Installation**: Auto-installs on first tmux start
- **Controls**: `Prefix + t` layer: `i` (install), `u` (update), `x` (clean)

### Session Management

#### tmux-resurrect
- **Purpose**: Save and restore tmux sessions, windows, and panes
- **Storage**: `~/.dotfiles/tmux/resurrect/`
- **Processes**: Saves ssh, vi, vim, nvim, man, tail, top, htop states

#### tmux-continuum
- **Purpose**: Automatic session save/restore
- **Settings**: 
  - Auto-restore: Enabled on tmux start
  - Save interval: Every 15 minutes
  - Works seamlessly with resurrect

### Navigation & Search

#### Custom Session Manager (replaces tmux-sessionx)
- **Purpose**: Unified session management with fzf
- **Script**: `tmux/scripts/tmux-session-manager.sh`
- **Binding**: `Prefix + o` (inside tmux) or `tm` shell alias (outside tmux)
- **Context-aware**: Detects `$TMUX` — uses popup inside tmux, plain fzf outside
- **Features**:
  - Session switching/attaching (LRU sorted, git branch display)
  - Session creation (zoxide disambiguation, literal path `~/...`, fd browser)
  - Session rename (`ctrl-r`) and delete (`ctrl-d`)
  - Move pane (`ctrl-s`) or window (`ctrl-w`) to another session (inside tmux only)
  - `ctrl-f` to browse filesystem for new session directory

#### tmux-floax
- **Purpose**: Floating window management
- **Features**: Create popup-style floating panes

#### tmux-fzf-url
- **Purpose**: Quick URL opening from terminal output
- **Binding**: `Prefix + u`
- **Features**: Scan terminal for URLs and open with fzf selection

### Text Extraction & Search

#### extrakto
- **Purpose**: Fuzzy text extraction from pane content (paths, hashes, words, IPs)
- **Binding**: `Prefix + Tab`
- **Features**: `Tab` to copy via rclip, `Enter` to insert at cursor position

#### tmux-thumbs
- **Purpose**: Vimium-style hint copy — highlights patterns with letter labels
- **Binding**: `Prefix + F`
- **Features**: Highlights all recognizable patterns (paths, hashes, IPs, URLs), press letter to copy via rclip
- **Note**: Requires Rust toolchain (compiled automatically by TPM on first install)

#### tmux-fuzzback
- **Purpose**: Fuzzy search through scrollback buffer with fzf preview
- **Binding**: `Prefix + /`
- **Features**: Full scrollback search with context preview, jumps to match in copy mode

### Process Management

#### tmux-cowboy
- **Purpose**: One-key process kill for hung processes
- **Binding**: `Prefix + *`
- **Action**: Sends `kill -9` to the foreground process in current pane

### Visual Enhancements

#### tmux-prefix-highlight
- **Purpose**: Show prefix key activation in status bar
- **Integration**: Works with custom status bar

## Clipboard Integration

### Universal Clipboard via rclip

The configuration uses `rclip` for all clipboard operations, providing seamless clipboard sharing across:
- Local tmux sessions
- Remote SSH sessions  
- Nested tmux sessions
- Different operating systems

**Key features:**
- Automatic fallback to OSC52 when remote bridge unavailable
- All copy operations (`y`, `Y`, mouse selection) use rclip
- Works in both vi and emacs copy modes
- Handles double/triple-click selection

### Copy Mode Bindings

**Vi mode** (default):
- `v`: Start selection
- `Ctrl+V`: Rectangle selection
- `y`: Copy selection and exit copy mode
- `Y`: Copy entire line
- `Enter`: Copy selection and exit

**Mouse operations**:
- Double-click: Select word and copy
- Triple-click: Select line and copy
- Drag selection: Automatically copies on release

## Remote Session Support

### SSH Optimization

When connecting via SSH, `tmux.remote.conf` is automatically loaded:

**Features:**
- OSC52 clipboard integration enabled
- SSH agent socket management
- Dynamic environment updates
- Status position adjustment for remote context

### SSH Agent Management

**Automatic refresh hooks:**
- Session creation, client attachment, pane focus events
- Maintains persistent SSH agent connection
- Uses symlinked socket at `~/.ssh/ssh_auth_sock`

**Manual refresh:**
- `Prefix + R`: Find working SSH agent and refresh connection (remote only)

### Nested Session Handling

**Toggle nested mode:**
- `Ctrl+]`: Disable outer tmux to access inner tmux
- `Ctrl+]` (again): Re-enable outer tmux

**Visual feedback:**
- Status bar changes color when nested mode active
- Clear indication of which tmux layer is active

## System Monitoring

### CPU Monitoring
- **Script**: `scripts/cpu-simple.sh`
- **Cache**: 5-second TTL in `~/.cache/tmux-cpu`
- **Algorithm**: `busy_cpu = 100 - idle_cpu`
- **Platforms**: macOS (via `top`), Linux (via `top` or `iostat`)

### Memory Monitoring  
- **Script**: `scripts/mem-simple.sh`
- **Cache**: 5-second TTL in `~/.cache/tmux-mem`
- **macOS**: `memory_pressure` or `vm_stat` fallback
- **Linux**: `/proc/meminfo` parsing
- **Format**: Bare integer percentage (caller adds `%`)

### Host Information
- **Icon detection**: System-specific icons (MacBook, iMac, Linux)
- **Hostname display**: Smart formatting with SSH context
- **Caching**: Expensive operations cached appropriately

## Performance Optimizations

### Efficient Scripting
- **Aggressive caching**: All monitoring scripts use cached values
- **Cross-platform compatibility**: Handles macOS/Linux differences
- **Minimal dependencies**: Uses built-in tools where possible
- **Error handling**: Graceful degradation when tools unavailable

### Cache Management
```bash
# Cache locations and TTLs
~/.cache/tmux-cpu        # 5 seconds
~/.cache/tmux-mem        # 5 seconds  
~/.cache/tmux-host-icon  # 1 hour
~/.cache/tmux-hostname   # 5 minutes
```

## Color Scheme (Catppuccin Mocha)

| Color | Hex | Usage |
|-------|-----|-------|
| Blue | `#89b4fa` | Active elements, current session |
| Green | `#a6e3a1` | Memory info, success states |
| Yellow | `#f9e2af` | CPU info, warnings |
| Red | `#f38ba8` | Errors, critical status |
| Dim | `#6c7086` | Inactive elements |
| Text | `#cdd6f4` | Primary text |
| Surface | `#313244` | Separators, borders |

## Installation & Setup

### Prerequisites
- **tmux 3.0+** (3.3+ recommended for advanced formatting)
- **rclip** (universal clipboard tool)
- **bash 4.0+** (advanced regex, associative arrays)
- **Rust toolchain** (for tmux-thumbs compilation via TPM)

### Installation Steps

1. **Install via dotbot**:
```bash
./install-standalone tmux
```

2. **Manual plugin installation** (if needed):
```bash
git clone https://github.com/tmux-plugins/tpm ~/.dotfiles/tmux/plugins/tpm
~/.dotfiles/tmux/plugins/tpm/bin/install_plugins
```

3. **Start tmux**:
```bash
tmux
```

Plugins will auto-install on first start.

## Troubleshooting

### Plugin Issues

**Plugins not loading:**
```bash
# Reinstall TPM
rm -rf ~/.dotfiles/tmux/plugins/tpm
git clone https://github.com/tmux-plugins/tpm ~/.dotfiles/tmux/plugins/tpm

# Install plugins
~/.dotfiles/tmux/plugins/tpm/bin/install_plugins
```

### Remote Session Problems

**SSH agent not working:**
```bash
# Manual refresh
tmux send-prefix \; send-keys R

# Check socket
ls -la ~/.ssh/ssh_auth_sock
```

**Clipboard not syncing:**
```bash
# Test rclip
echo "test" | rclip

# Check remote bridge status
remote-bridge status
```

### General Debugging

```bash
# Show current tmux options
tmux show-options -g | grep status

# Test configuration syntax
tmux source-file ~/.dotfiles/tmux/tmux.conf

# Check tmux version
tmux -V
```

## Maintenance

### Regular Tasks
- **Plugin updates**: `Prefix + t`, then `u`
- **Session cleanup**: Automatic via continuum (24-hour retention)
- **Cache cleanup**: Automatic via system (respects TTL)

### Configuration Updates
- **Reload config**: `Prefix + r`
- **Status bar changes**: Automatically picked up every 5 seconds
- **Plugin changes**: Requires tmux restart

---

This tmux configuration provides a refined terminal multiplexer setup focused on productivity, responsive status displays, and seamless multi-environment operation.
