# Universal Clipboard System

A seamless clipboard solution that works across local, remote, and arbitrarily nested tmux sessions.

## Features

✅ **Any nesting level**: Local tmux → SSH → Remote tmux → SSH → Another remote tmux  
✅ **Same hotkeys everywhere**: `y` always works, regardless of context  
✅ **Automatic detection**: No manual configuration needed  
✅ **OSC 52 integration**: Works through SSH and terminal emulators  
✅ **Fallback layers**: Multiple clipboard methods for maximum compatibility  

## How It Works

```
Neovim yank → universal-clipboard → OSC 52 → Your local clipboard
tmux copy  → universal-clipboard → OSC 52 → Your local clipboard
```

The system detects:
- SSH session depth
- tmux nesting level  
- Available clipboard tools
- Terminal OSC 52 support

## Key Bindings

### tmux Copy Mode
- `y` - Copy selection to universal clipboard
- `Y` - Copy entire line to universal clipboard  
- `Enter` - Copy selection to universal clipboard
- `C-y` - Copy selection (works in nested sessions)

### Neovim
- `y` - Standard yank, goes to universal clipboard
- `"+y` / `"*y` - Explicit system clipboard yank
- `p` / `P` - Paste from universal clipboard

### Nested Session Management
- `Ctrl+]` - Toggle nested session mode
  - **ON**: Disables outer tmux, status bar turns blue
  - **OFF**: Re-enables outer tmux, normal status bar

## Testing the System

### Local Test
```bash
# In local tmux
echo "local test" | universal-clipboard
# Should appear in your system clipboard
```

### Remote Test  
```bash
# SSH to remote server with tmux
echo "remote test" | universal-clipboard
# Should appear in your local system clipboard via OSC 52
```

### Nested Test
```bash
# Local tmux → SSH → Remote tmux
echo "nested test" | universal-clipboard
# Should appear in your local system clipboard
```

### Neovim Test
1. Open neovim in any environment
2. Type some text and yank with `y`
3. Switch to local terminal and paste with `Cmd+V`
4. Text should appear

## Debug Mode

Enable debugging to see what's happening:

```bash
export CLIPBOARD_DEBUG=1
echo "debug test" | universal-clipboard
```

This will show:
- Detected context (SSH hops, tmux level)
- Which clipboard methods are being used
- Success/failure of each method

## Troubleshooting

### Clipboard not working in terminal
- Ensure your terminal supports OSC 52 (iTerm2, Terminal.app, most modern terminals)
- Check `echo $TERM` - should be `xterm-256color` or similar

### Not working in nested SSH
- Verify SSH agent forwarding: `echo $SSH_AUTH_SOCK`
- Check if terminal is receiving OSC 52: `printf '\033]52;c;dGVzdA==\007'`

### tmux copy not reaching local clipboard
- Reload tmux config: `<prefix> r`  
- Check if `universal-clipboard` is in PATH: `which universal-clipboard`

### Neovim clipboard issues
- Restart neovim to reload clipboard config
- Test with `:echo has('clipboard')` (should return 1)
- Manual test: `:let @+ = 'test'` then paste locally

## Components

- **`bin/universal-clipboard`** - Main clipboard handler script
- **`tmux/tmux.conf`** - Enhanced copy bindings with OSC 52
- **`.config/nvim/lua/config/options.lua`** - Universal neovim clipboard config
- **Enhanced nested session handling** - Visual feedback and smart routing

## Compatibility

- **Local**: macOS (pbcopy/pbpaste), Linux (xclip/xsel)
- **Remote**: Any SSH session with terminal OSC 52 support
- **Nested**: Unlimited nesting depth
- **Terminals**: iTerm2, Terminal.app, Alacritty, Kitty, etc.