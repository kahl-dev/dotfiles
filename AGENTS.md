# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a comprehensive macOS dotfiles repository that uses **dotbot** for configuration management and **Makefile** for installation orchestration. The repository follows a modular architecture with "ingredients" (individual configuration modules) and "recipes" (combined installation profiles).

### Claude Code Configuration

Global Claude Code instructions and configuration are stored in `.claude.global/` and symlinked to `~/.claude/` for version control:

- **`.claude.global/GLOBAL.CLAUDE.md`** - Main global instructions file with imports
- **`.claude.global/instructions/`** - Modular instruction files  
- **`.claude.global/commands/`** - Custom slash commands
- **`.claude.global/hooks/`** - Hook scripts for tool execution events
- **`.claude.global/settings.json`** - Global Claude Code settings

These provide consistent Claude behavior across all projects and machines.

## Architecture & Structure

### Core Components

- **`meta/`** - Contains dotbot configuration system
  - `base.yaml` - Base dotbot configuration with shell defaults
  - `ingredients/` - Individual configuration modules (e.g., `bat.yaml`, `neovim_build.yaml`, `tmux.yaml`)
  - `recipes/` - Installation profiles combining multiple ingredients (`liadev`, `macos`, `pi`)
- **`scripts/`** - Shell scripts for installation, setup, and maintenance
- **Configuration directories** organized by tool:
  - `zsh/` - Shell configuration and utilities
  - `.config/` - XDG-compliant application configurations
  - `tmux/` - Terminal multiplexer configuration
  - `brew/` - Homebrew package management (separate for macOS/Linux)

### Installation System

The repository uses a two-tiered installation approach:
1. **Profile-based**: `./install-profile <recipe>` (e.g., `./install-profile macos`)
2. **Standalone modules**: `./install-standalone <ingredient>` (e.g., `./install-standalone neovim_build`)

Both scripts use dotbot to process the appropriate YAML configurations, combining base settings with specific ingredients.

### Tab Completion System

The repository includes bash-compatible completion for the installation scripts:
- **Location**: `completion/dotfiles-completion.bash`
- **Integration**: Loaded automatically from `zsh/config/aliases.zsh` after completion init
- **Functionality**:
  - `install-profile` completes with available recipes from `meta/recipes/`
  - `install-standalone` completes with available ingredients from `meta/ingredients/` (without .yaml extension)

The completion script dynamically discovers available options by scanning the filesystem, ensuring it stays current as new recipes and ingredients are added.

## Common Commands

### Installation & Setup
```bash
# Install complete macOS profile
./install-profile macos

# Install standalone components
./install-standalone neovim_build
./install-standalone tmux

# Full installation via Makefile
make install

# Install Homebrew packages
make installBrewOsxPackages
brew bundle --file brew/osx/.Brewfile
```

### Maintenance
```bash
# Show all available make targets
make help

# Update shell configuration
make updateShell

# Reset Neovim packages (when troubleshooting)
make nvimResetPackages

# Uninstall all symlinks and configurations
make uninstall
```

### Package Management
```bash
# Update all Homebrew packages and cleanup
brewup

# Export current packages to Brewfile
brewdump

# Add new packages to Brewfile and install
echo 'brew "package-name"' >> brew/osx/.Brewfile
brewup
```

## Development Workflow

### Adding New Configurations

1. **Create ingredient file** in `meta/ingredients/` (e.g., `newapp.yaml`)
2. **Add configuration files** in appropriate directories (`.config/`, `zsh/config/`, etc.)
3. **Update recipe file** in `meta/recipes/` to include the new ingredient
4. **Test with standalone installation**: `./install-standalone newapp`

### Modifying Existing Configs

- **Application configs**: Edit files in `.config/` or tool-specific directories
- **Shell configs**: Modify files in `zsh/config/` (sourced automatically)
- **Homebrew packages**: Update `brew/osx/.Brewfile` then run `brew bundle`

### Shell Configuration

The zsh setup uses modular configuration files in `zsh/config/`:
- `aliases.zsh` - Command aliases and shortcuts
- `fzf.zsh` - Fuzzy finder integration
- `keybindings.zsh` - Custom key mappings
- `plugins.zsh` - Plugin management via zinit
- `prompt.zsh` - Starship prompt configuration

#### ZSH Helper Functions

The repository includes a comprehensive set of helper functions in `zsh/utils.zsh` for common operations. **Always use these helpers instead of raw shell commands** for consistency and better error handling.

##### System Detection
```bash
# Check if commands/tools exist before using them
if command_exists nvim; then
  # Use neovim
fi

# Platform detection
if is_macos; then
  # macOS-specific code
elif is_linux; then
  # Linux-specific code
fi

# Environment detection
if is_raspberry_pi; then
  # Raspberry Pi specific setup
fi

if is_ssh_client; then
  # SSH-specific configuration
fi
```

##### File System Checks
```bash
# Always check existence before operations
if file_exists "$HOME/.config/app/config.json"; then
  # Process config file
fi

if folder_exists "$HOME/.local/share/app"; then
  # Work with directory
fi

if path_exists "$HOME/.tool-versions"; then
  # Path exists (file or directory)
fi
```

##### Cross-Platform Operations
```bash
# Open files/URLs cross-platform
open_command "https://example.com"
open_command "/path/to/file.pdf"

# Interactive user prompts
prompt_user "Install development tools?" \
  "echo 'Installing tools...'" \
  "echo 'Skipping installation'"
```

##### Usage Examples in Dotfiles
```bash
# ✅ Good - using helpers
if command_exists fzf; then
  alias preview='fzf --preview "cat {}"'
fi

# ❌ Bad - raw commands
if which fzf >/dev/null 2>&1; then
  alias preview='fzf --preview "cat {}"'
fi

# ✅ Good - consistent path checking
path_exists "$DOTFILES/bin" && export PATH="$DOTFILES/bin:$PATH"

# ❌ Bad - inconsistent checking
[ -d "$DOTFILES/bin" ] && export PATH="$DOTFILES/bin:$PATH"
```

##### Available Helper Functions
- `command_exists <cmd>` - Check if command is available
- `file_exists <path>` - Check if file exists
- `folder_exists <path>` - Check if directory exists  
- `path_exists <path>` - Check if path exists (file or directory)
- `is_macos` - Detect macOS system
- `is_linux` - Detect Linux system
- `is_raspberry_pi` - Detect Raspberry Pi
- `is_ssh_client` - Detect SSH environment
- `open_command <path/url>` - Cross-platform open command
- `prompt_user <question> <yes_action> <no_action>` - Interactive prompts
- `ensure_uname` - Internal helper for uname availability

## Key Tools & Their Configs

### Terminal & Shell
- **tmux**: Advanced configuration in `tmux/` with responsive status bar, remote-friendly defaults, and curated plugin setup
- **zsh**: Modular config in `zsh/config/` with automatic sourcing
- **starship**: Prompt config in `.config/starship.toml`

### Development Tools
- **neovim**: Full configuration in `.config/nvim/`
- **git**: Configuration in `git/` directory
- **bat**: Syntax highlighting themes in `.config/bat/`

### macOS-Specific
- **Homebrew**: Package definitions in `brew/osx/.Brewfile`
- **macOS defaults**: System settings via `scripts/setup_defaults_write.sh`
- **Window management**: AeroSpace, Hammerspoon, Karabiner configs

## Remote Bridge System

@.claude/instructions/remote-bridge.md

## 📚 Documentation Maintenance

### Automatic Documentation Updates

**When Claude makes changes that affect documented features, it MUST:**

- **Update README.md** if user-facing behavior changes (new features, installation steps, key commands)
- **Update CLAUDE.md** if technical implementation changes (architecture, file paths, integration details)
- **Update topic READMEs** in specific directories when their configurations change
- **Keep all examples and commands current** - test that documented commands actually work
- **Add screenshots** when visual changes are made (tmux appearance, terminal output)
- **Maintain consistency** between related documentation files

### Documentation Structure Standards

**README.md (Human-focused):**
- Feature overview with visual examples and screenshots
- Clear installation and setup instructions  
- Key keybindings and commands for daily use
- Troubleshooting section for common issues
- Directory structure overview
- Notable configuration highlights

**CLAUDE.md (AI-focused):**
- Technical architecture and implementation details
- Exact file paths and dependencies
- Integration details, hooks, and system interactions
- Maintenance procedures and troubleshooting
- System requirements and compatibility notes

**Topic READMEs (Directory-specific):**
- Quick reference for that component
- Configuration highlights and customizations
- Integration with other system components
- Maintenance and debugging specific to that area

### Self-Documenting Principle

Every significant change must include documentation updates in the same commit. This ensures:
- Documentation never becomes stale
- Future maintenance is possible
- New users (including future you) can understand the system
- Claude sessions have complete context

**Examples of changes requiring documentation:**
- Adding new keybindings → Update README.md and relevant CLAUDE.md sections
- Modifying tmux status bar → Update docs/tmux.md and add screenshot to README.md  
- Creating new scripts → Update bin/README.md or relevant documentation
- Changing installation process → Update main README.md installation section

## Troubleshooting

### Common Issues
- **Broken symlinks**: Run `make uninstall` then reinstall
- **Package conflicts**: Check Homebrew with `brew doctor`
- **Neovim issues**: Reset with `make nvimResetPackages`
- **Shell not updating**: Run `make updateShell` or restart terminal

### System Dependencies
- Requires macOS with Homebrew installed
- Git must be available for submodule management
- Some configurations require specific versions (e.g., PostgreSQL@15)

## 🎯 Project Management

This project uses **GitHub Issues** for tracking enhancements, bugs, and future improvements. 

**[View all open issues →](https://github.com/kahl-dev/dotfiles/issues)**

To contribute or suggest improvements, please create a GitHub issue with detailed description and implementation ideas.

## 🎨 Theme Consistency Guidelines

### Catppuccin Theme Implementation
All applications use **Catppuccin Mocha** flavor for consistent dark theme experience:

**✅ Fully Themed Applications:**
- **tmux**: Catppuccin Mocha via plugin (`tmux/tmux.conf`)
- **bat**: Catppuccin Mocha syntax highlighting (`~/.config/bat/config`)
- **btop**: Catppuccin Mocha theme (`~/.config/btop/btop.conf`)
- **Neovim**: Catppuccin with transparent background (`~/.config/nvim/lua/plugins/catppuccin.lua`)
- **Ghostty**: Catppuccin Mocha terminal theme (`~/.config/ghostty/config`)
- **WezTerm**: Catppuccin Mocha color scheme (`~/.config/wezterm/wezterm.lua`)
- **Starship**: Catppuccin Macchiato palette (`~/.config/starship.toml`)
- **fzf**: Catppuccin Mocha colors (`zsh/config/fzf.zsh`)
- **lazygit**: Catppuccin Mocha theme (`~/.config/lazygit/config.yml`)
- **Zed**: Catppuccin Mocha with extension auto-install (`~/.config/zed/settings.json`)

**Color Palette (Mocha):**
- Background: `#1e1e2e`
- Surface: `#313244`
- Text: `#cdd6f4`
- Blue: `#89b4fa`
- Pink: `#f38ba8`
- Lavender: `#cba6f7`
- Yellow: `#f9e2af`
- Rosewater: `#f5e0dc`

**Theme Maintenance:**
- All terminal applications should use transparent backgrounds where possible
- Maintain consistency with Catppuccin's official color values
- Reference official Catppuccin repositories for updates
- Test theme changes across all configured applications

## Notes

- The repository uses git submodules for tmux plugins and dotbot
- Configuration files use XDG Base Directory specification where possible
- Raycast settings are synced via cloud backup (not stored in dotfiles)
- The system is designed for personal use and includes specific tools/preferences
- **DO NOT commit Zed settings** - these are personal and machine-specific configurations
