# ⚡ TMUX CHEATSHEET ⚡
**Prefix Key:** `Ctrl+s`

---

## 🚀 Sessions

| Keybinding | Description |
|------------|-------------|
| `<prefix> o` | Session manager (sesh — switch, create, kill) |
| `<prefix> L` | Last session toggle |

## 🖼️ Windows

| Keybinding | Description |
|------------|-------------|
| `<prefix> c` | Create new window |
| `C-S-Left/Right` | Move window left/right |

## 📦 Panes (`<prefix> v` layer)

Press `<prefix> v` to enter panes mode, then:

### Layouts
| Key | Description | Mnemonic |
|-----|-------------|----------|
| `=` | Balance all panes equally | equal sign |
| `t` | Tiled auto grid | **t**iled |
| `m` | Main pane left, rest stacked right | **m**ain |
| `M` | Main pane top, rest below | **M**ain (shifted) |
| `1` | All panes in single row | max **1** row |
| `2` | Grid with max 2 rows | max **2** rows |
| `3` | Grid with max 3 rows | max **3** rows |

### Split / Structure
| Key | Description | Mnemonic |
|-----|-------------|----------|
| `\|` | Split horizontal | visual |
| `-` | Split vertical | visual |
| `_` | Split full-width vertical | visual (wide) |
| `j` | Join pane (tree picker) | **j**oin |
| `b` | Break pane out to new window | **b**reak |
| `g` | Grab pane horizontal (fzf) | **g**rab |
| `G` | Grab pane vertical (fzf) | **G**rab |
| `w` | Grab window from other session (tree) | **w**indow |

### Swap / Move
| Key | Description | Mnemonic |
|-----|-------------|----------|
| `h` | Swap with previous pane | vim left |
| `l` | Swap with next pane | vim right |
| `s` | Swap by number (shows pane overlay) | **s**wap |
| `r` | Rotate all panes | **r**otate |

### Manage
| Key | Description |
|-----|-------------|
| `x` | Kill pane |
| `z` | Zoom/unzoom pane |
| `Escape` | Cancel |

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
| `o` | Switch selection ends (other-end) |

## 🛠️ Tools

| Keybinding | Description |
|------------|-------------|
| `<prefix> ?` | **Which-key menu** (all bindings, nested submenus) |
| `<prefix> u` | URL finder (tmux-fzf-url) |
| `<prefix> Tab` | Extract text from pane (extrakto — paths, hashes, words) |
| `<prefix> F` | Thumbs hint copy (Vimium-style letter hints) |
| `<prefix> /` | Fuzzy scrollback search (fuzzback) |
| `<prefix> *` | Kill hung process in pane (cowboy) |
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

## 📡 Session Manager — sesh (`<prefix> o` or `tm` in shell)

Powered by [sesh](https://github.com/joshmedeski/sesh). Shows tmux sessions + zoxide directories in one picker.
Works both inside tmux (popup) and outside (plain fzf). Use `tm` from any shell.

| Key | Action |
|-----|--------|
| `Enter` | Switch/attach to selected session (creates if new) |
| `ctrl-a` | Show all (tmux + zoxide + config) |
| `ctrl-t` | Filter: tmux sessions only |
| `ctrl-x` | Filter: zoxide directories only |
| `ctrl-n` | Create new session in same directory |
| `ctrl-d` | Kill selected session |
| `ctrl-f` | Browse filesystem (fd) |

## 💡 Pro Tips

- **Which-Key**: Use `<prefix> ?` to discover all available keybindings
- **Focus Mode**: `<prefix> z` quickly zooms/unzooms panes for focused work  
- **Vim Integration**: `C-h/j/k/l` navigation works seamlessly with vim splits
- **Smart Clipboard**: Mouse selection automatically copies to system clipboard via rclip
- **Context Menus**: Right-click for context menus in panes and status bar
- **Remote Control**: Nested mode (`C-]`) lets you control inner tmux when SSH'd into remote hosts
