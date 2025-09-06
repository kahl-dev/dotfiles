# 🖥️ Tmux Configuration

Advanced tmux setup with **Claude Code integration** and adaptive status bar.

## ⚡ Quick Reference

**Prefix Key:** `Ctrl+s`

### Essential Keybindings
- `<prefix> ?` - **Cheatsheet** (beautiful glow rendering)
- `<prefix> /` - **Search keybindings** (interactive fzf)
- `<prefix> o` - **Session switcher** (SessionX with zoxide)
- `<prefix> u` - **URL finder** (tmux-fzf-url)
- `<prefix> g` - **LazyGit**
- `<prefix> z` - **Zoom/unzoom pane**

### Splitting & Navigation
- `<prefix> |` - Split horizontal
- `<prefix> -` - Split vertical  
- `C-h/j/k/l` - Navigate panes (vim-aware)
- `C-\` - Jump to last pane

## 🤖 Claude Code Integration

Real-time status bar that adapts based on Claude session activity:

- **1-line mode**: When no Claude sessions active
- **2-line mode**: Shows Claude session status with emoji indicators
- **Status indicators**: 🚀 starting, 🧠 working, 🤔 asking, ⏳ waiting, 💤 idle

### Manual Controls
- `<prefix> S` - Toggle Claude status line visibility
- `<prefix> R` - Reload status configuration
- `<prefix> I` - Show status debug info

## 🔧 Key Features

### Clipboard Integration
- All copy operations use **rclip** for Remote Bridge integration
- Works seamlessly across local/SSH sessions
- Mouse selection automatically copies to system clipboard

### Performance Optimizations
- **Cached monitoring**: CPU and memory stats with intelligent caching
- **Smart session grouping**: Groups Claude sessions by project directory
- **Efficient updates**: Only refreshes when necessary

### Plugin Ecosystem
- **tmux-sessionx**: Enhanced session management with zoxide
- **tmux-fzf-url**: URL detection and opening
- **tmux-floax**: Floating scratch terminals
- **tmux-resurrect/continuum**: Session persistence

## 📁 File Structure

```
tmux/
├── tmux.conf              # Main configuration
├── custom-status.conf     # Adaptive status bar setup
├── cheatsheet.md         # Beautiful markdown cheatsheet
├── scripts/              # Status bar and utility scripts
│   ├── status-line-*.sh  # Status bar components
│   ├── cpu-simple.sh     # Cached CPU monitoring
│   └── mem-simple.sh     # Cached memory monitoring
└── CLAUDE.md            # Complete Claude integration docs
```

## 🚨 Troubleshooting

- **Status bar not updating**: Check `~/.claude/sessions/status.json`
- **Claude sessions not showing**: Verify hook permissions in `~/.claude.global/hooks/`
- **Performance issues**: Check cache files with `ls -la ~/.cache/tmux-*`

**For complete troubleshooting guide, see `CLAUDE.md`**

## 🎨 Customization

The tmux configuration uses **Catppuccin Mocha** color scheme with:
- Transparent background for terminal integration
- Blue highlights for active elements
- Consistent colors across all components

All colors are defined as environment variables in `custom-status.conf` for easy customization.