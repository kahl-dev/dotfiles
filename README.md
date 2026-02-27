# 🏠 Personal Dotfiles

> **Comprehensive macOS development environment with Claude Code integration**

A sophisticated, modular dotfiles system built with **dotbot** featuring advanced tmux integration, performance-optimized shell environment, and seamless Remote Bridge clipboard system.

## ✨ Key Features

- **🤖 Claude Code Integration** - Optimized shell environment and automation tailored for Claude Code sessions
- **🌉 Remote Bridge System** - Universal clipboard and URL handling across local/SSH sessions
- **⚡ Performance Optimized** - 100x faster tools (ripgrep, fd, sd) for Claude Code shell
- **🧩 Modular Architecture** - Ingredients and recipes system with tab completion
- **📱 Complete Setup** - From terminal to GUI applications with sensible defaults

## 🚀 Quick Installation

Clone the repository and install the dotfiles:

```zsh
git clone https://github.com/kahl-dev/dotfiles.git ~/.dotfiles && cd ~/.dotfiles && ./install
```

## Post-Installation

If everything is up and running change the dotfiles remote URL to SSH:

```zsh
cd ~/.dotfiles && git remote set-url origin git@github.com:kahl-dev/dotfiles.git
```

## 📁 Directory Structure

```
.dotfiles/
├── 🏗️  meta/                    # Dotbot configuration system
│   ├── ingredients/             # Individual configuration modules  
│   └── recipes/                 # Installation profiles (macos, liadev, pi)
├── 🐚 zsh/                      # Shell configuration and utilities
│   └── config/                  # Modular zsh configuration files
├── 🖥️  tmux/                    # Terminal multiplexer configuration
│   ├── scripts/                 # Status bar and helper scripts
├── 🍺 brew/                     # Homebrew package management
│   ├── osx/                     # macOS packages and casks
│   └── linux/                   # Linux-specific packages
├── 🌉 remote-bridge/            # Universal clipboard/URL system
├── ⚙️  .config/                 # XDG-compliant application configs
├── 🔧 scripts/                  # Installation and maintenance scripts
└── 📚 docs/                     # Additional documentation
```

## 🎯 Notable Configurations

### Terminal Experience
- **tmux** - Advanced configuration with responsive status bar
- **zsh** - Performance-optimized with modular configuration  
- **starship** - Beautiful, fast prompt with git integration
- **Remote Bridge** - Seamless clipboard across local/SSH sessions

### Development Tools  
- **neovim** - Full IDE-like configuration in `.config/nvim/`
- **git** - Enhanced with custom aliases and commit templates
- **bat** - Syntax highlighting with Catppuccin theme
- **fzf** - Fuzzy finder integration throughout the system

### macOS Integration
- **Homebrew** - Comprehensive package management via Brewfiles
- **Karabiner-Elements** - Custom keyboard remapping
- **AeroSpace** - Tiling window manager configuration  
- **System defaults** - Sensible macOS system settings

## 🔧 Advanced Usage

### Modular Installation
```bash
# Install specific components only
./install-standalone tmux
./install-standalone neovim_build

# Install by profile
./install-profile liadev    # Development setup
./install-profile macos     # Complete macOS setup
```

#### 📝 Tab Completion
The dotfiles system includes intelligent tab completion for both installation scripts:

- `./install-profile <TAB>` - Shows available recipes: `liadev`, `macos`, `pi`
- `./install-standalone <TAB>` - Shows available ingredients: `tmux`, `neovim_build`, `claude`, etc.

Completion is automatically available after sourcing your zsh configuration and can be enabled for Bash by sourcing `completion/dotfiles-completion.bash`.

### Maintenance Commands
```bash
make help                   # Show all available commands
make updateShell           # Reload shell configuration
brewup                     # Update all brew packages and cleanup
brewdump                   # Export current packages to Brewfile
```

## ✅ Post-Installation Checklist

Manual steps after running `./install-profile macos`:

### System Settings
- [ ] iCloud → Drive → enable Desktop & Documents sync
- [ ] Accessibility → Pointer Control → Trackpad Options → enable 3-finger drag
- [ ] Keyboard → Modifier Keys → verify Caps Lock → Control (Karabiner handles this, but verify)

### Accounts & Auth
- [ ] Sign into 1Password + enable SSH Agent
- [ ] Add SSH keys to `~/.dotfiles-local/ssh-config` (work servers, home lab, etc.)
- [ ] Create `~/.dotfiles-local/.zshenv` for machine-specific env vars
- [ ] Create `~/.dotfiles-local/zshrc` for machine-specific shell config
- [ ] Add shared iCloud accounts for Contacts sync (if needed)

### App Configuration
- [ ] Bartender — configure menu bar items
- [ ] Stream Deck — set up profiles and actions
- [ ] Raycast — sign in for settings sync
- [ ] Alfred — set sync folder to restore preferences (if using Alfred over Raycast)

### Verify
- [ ] `brewup` — update all packages
- [ ] `mackup restore` — restore app settings from backup
- [ ] SSH connections work (`ssh <host>` for each configured host)
- [ ] Remote Bridge clipboard works (`echo "test" | pbcopy` over SSH)

## 🆘 Troubleshooting

**Broken symlinks**  
Simply rerun your profile installation: `./install-profile macos`

**Shell configuration not loading**  
Run `make updateShell` or restart your terminal

**Homebrew package conflicts**  
Check system health with `brew doctor` and resolve any issues

**System Requirements:**
- macOS with Homebrew installed
- Git for submodule management  
- Node.js for Remote Bridge system

## 💡 What Makes This Special

This dotfiles setup goes beyond basic configuration:

- **Rich tmux environment**: Responsive status bar, plugin workflow, and polished UX
- **Remote Bridge**: Universal clipboard that works everywhere (local, SSH, nested tmux)
- **Performance First**: Optimized tools (100x faster grep/find) tuned for everyday workflows
- **Modular Design**: Mix and match components with ingredients/recipes system
- **Battle-Tested**: Daily-driven configuration with extensive documentation

Perfect for developers who work across local and remote environments and want a consistent, powerful terminal experience.

---

**See `CLAUDE.md` for technical implementation details.**

## 🎯 Project Management

This project uses **GitHub Issues** for tracking enhancements, bugs, and future improvements. 

**[View all open issues →](https://github.com/kahl-dev/dotfiles/issues)**

To contribute or suggest improvements, please create a GitHub issue with detailed description and implementation ideas.
