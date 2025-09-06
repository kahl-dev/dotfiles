# ⚡ TMUX CHEATSHEET ⚡
**Prefix Key:** `Ctrl+s`

---

## 🚀 Sessions

| Keybinding | Description |
|------------|-------------|
| `<prefix> C-c` | Create new session |
| `<prefix> o` | SessionX (enhanced session switcher) |

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
| `<prefix> /` | Search keybindings (interactive fzf) |
| `<prefix> u` | URL finder (tmux-fzf-url) |
| `<prefix> r` | Reload tmux config |
| `<prefix> g` | LazyGit |
| `<prefix> b` | Btop (system monitor) |
| `<prefix> m` | Glow (markdown viewer) |

## 🔌 Plugins (TPM)

| Keybinding | Description |
|------------|-------------|
| `M-i` | Install plugins |
| `M-u` | Update plugins |
| `M-x` | Clean unused plugins |

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
| `<prefix> S` | Toggle Claude status line visibility |
| `<prefix> R` | Reload status configuration |
| `<prefix> I` | Show status info (debugging) |

## 📋 Clipboard (Remote Bridge)

All copy operations automatically use `rclip` for seamless local/remote synchronization.
- Works transparently across SSH sessions and nested tmux environments
- Supports OSC52 fallback when Remote Bridge tunnel is unavailable

## 💡 Pro Tips

- **Quick Search**: Use `<prefix> /` to instantly search for specific keybindings
- **Focus Mode**: `<prefix> z` quickly zooms/unzooms panes for focused work  
- **Vim Integration**: `C-h/j/k/l` navigation works seamlessly with vim splits
- **Smart Clipboard**: Mouse selection automatically copies to system clipboard via rclip
- **Context Menus**: Right-click for context menus in panes and status bar
- **Remote Control**: Nested mode (`C-]`) lets you control inner tmux when SSH'd into remote hosts