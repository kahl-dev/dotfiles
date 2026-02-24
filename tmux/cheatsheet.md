# ⚡ TMUX CHEATSHEET ⚡
**Prefix Key:** `Ctrl+s`

---

## 🚀 Sessions

| Keybinding | Description |
|------------|-------------|
| `<prefix> o` | Session manager (switch, create, rename, move pane/window) |

## 🖼️ Windows

| Keybinding | Description |
|------------|-------------|
| `<prefix> c` | Create new window |
| `C-S-Left/Right` | Move window left/right |

## 📦 Panes

| Keybinding | Description |
|------------|-------------|
| `<prefix> \|` | Split horizontal |
| `<prefix> -` | Split vertical |
| `<prefix> _` | Split vertical (full height) |
| `<prefix> z` | Zoom/unzoom pane |
| `<prefix> B` | Break pane to new window |
| `<prefix> E` | Join pane from another window |

## 🗑️ Kill/Delete

| Keybinding | Description |
|------------|-------------|
| `<prefix> x` | Kill current pane |
| `<prefix> X` | Kill current window |
| `<prefix> Q` | Kill session (with confirmation) |

## 🧭 Navigation

| Keybinding | Description |
|------------|-------------|
| `C-h/j/k/l` | Move between panes (vim-aware) |
| `C-\` | Jump to last pane |

## 📏 Resize Panes

| Keybinding | Description |
|------------|-------------|
| `<prefix> ←/↓/↑/→` | Resize panes with arrow keys |
| `<prefix> C-h/j/k/l` | Alternative vim-style resize |

## 📝 Copy Mode

| Keybinding | Description |
|------------|-------------|
| `<prefix> Enter` | Enter copy mode |
| `C-[` | Enter copy mode (alternative) |
| `v` | Start selection |
| `C-v` | Rectangle select |
| `y` | Yank/copy (via rclip) |

## 🛠️ Tools

| Keybinding | Description |
|------------|-------------|
| `<prefix> ?` | This cheatsheet (beautiful glow rendering) |
| `<prefix> Space` | **Which-key menu** (all bindings, nested submenus) |
| `<prefix> u` | URL finder (tmux-fzf-url) |
| `<prefix> r` | Reload tmux config |
| `<prefix> D` | Update status detail popup |

## 🚀 Apps (prefix + a, then...)

Press `<prefix> a` to enter apps mode, then:

| Key | Window | Popup | App |
|-----|--------|-------|-----|
| `g` / `G` | new window | overlay | LazyGit |
| `y` / `Y` | new window | overlay | Yazi (file manager) |
| `b` / `B` | new window | overlay | Btop (system monitor) |
| `m` / `M` | new window | overlay | Glow (markdown viewer) |
| `Escape` | - | - | Cancel |

**Example:** `<prefix> a G` opens LazyGit as popup overlay

## 🔌 Plugins (TPM)

| Keybinding | Description |
|------------|-------------|
| `<prefix> t` | **Enter TPM layer** |
| `i` | Install plugins |
| `u` | Update plugins |
| `x` | Clean unused plugins |
| `Escape` | Cancel |

## 🪆 Nested Sessions

| Keybinding | Description |
|------------|-------------|
| `C-]` | Toggle nested mode (disable outer tmux) |

## 🖱️ Mouse Support

| Action | Description |
|--------|-------------|
| Click | Select panes/windows |
| Drag | Resize panes |
| Right-click | Context menu |
| Double-click | Select word and copy |
| Triple-click | Select line and copy |

## ⚙️ Advanced

| Keybinding | Description |
|------------|-------------|
| `<prefix> <` | Window menu (swap, rename, etc.) |
| `<prefix> >` | Pane menu (split, swap, kill, etc.) |
| `<prefix> R` | Reload status configuration |

## 📋 Clipboard (Remote Bridge)

All copy operations automatically use `rclip` for seamless local/remote synchronization.
- Works transparently across SSH sessions and nested tmux environments
- Supports OSC52 fallback when Remote Bridge tunnel is unavailable

## 📡 Session Manager (`<prefix> o`)

| Key | Action |
|-----|--------|
| `Enter` | Switch to selected session |
| `Enter` (on `[+ New Session]`) | Create session via zoxide or typed path (`~/...`) |
| `ctrl-r` | Rename selected session |
| `ctrl-d` | Delete selected session (with confirmation) |
| `ctrl-f` | Browse filesystem to create session |
| `ctrl-s` | Move current pane to selected session |
| `ctrl-w` | Move current window to selected session |

## 💡 Pro Tips

- **Which-Key**: Use `<prefix> Space` to discover all available keybindings
- **Focus Mode**: `<prefix> z` quickly zooms/unzooms panes for focused work  
- **Vim Integration**: `C-h/j/k/l` navigation works seamlessly with vim splits
- **Smart Clipboard**: Mouse selection automatically copies to system clipboard via rclip
- **Context Menus**: Right-click for context menus in panes and status bar
- **Remote Control**: Nested mode (`C-]`) lets you control inner tmux when SSH'd into remote hosts
