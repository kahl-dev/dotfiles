# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a comprehensive macOS dotfiles repository that uses **dotbot** for configuration management and a unified `dot` CLI for day-to-day operations. A bootstrap-only Makefile exists for fresh clones (before ZSH is configured). The repository follows a modular architecture with "ingredients" (individual configuration modules) and "recipes" (combined installation profiles).

### Claude Code Configuration

Global Claude Code instructions and configuration are managed in a **private repository** (`~/repos/claude-config`) and automatically installed via the `claude` dotbot ingredient:

- **Repository**: `github.com:kahl-dev/claude-config` (private)
- **Location**: `~/repos/claude-config/`
- **Runtime**: Symlinked to `~/.claude/` during installation
- **Installation**: Automatic via `./install-standalone claude` or `./install-profile <profile>`

The configuration includes:
- Global instructions (`GLOBAL.CLAUDE.md`)
- Custom skills (LIA framework, Jira, productivity tools)
- Slash commands (experts, productivity, analysis)
- Automation hooks (smart-lint, notifications)
- MCP server configurations

This separation keeps agency-specific intellectual property private while allowing the public dotfiles to remain shareable.

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

Two completion systems coexist:

1. **`dot` CLI** (native ZSH): `compdef _dot dot` in `zsh/config/dot.zsh`
   - `dot install profile <TAB>` — completes from `meta/recipes/`
   - `dot install standalone <TAB>` — completes from `meta/ingredients/*.yaml` (sans extension)
   - `dot update <TAB>` — completes `--yes` / `-y`
   - Top-level commands complete with descriptions

2. **Direct scripts** (bash compat): `completion/dotfiles-completion.bash`
   - Loaded from `zsh/config/aliases.zsh` after completion init
   - `./install-profile <TAB>` and `./install-standalone <TAB>`
   - Dynamically discovers options by scanning the filesystem

## Common Commands

### dot CLI (unified dotfiles command)

The `dot` command consolidates all dotfiles operations into a single interface with fzf-powered interactive menu and tab completion.

```bash
# Interactive menu (fzf)
dot

# Installation
dot install profile macos       # Install a dotbot profile
dot install standalone tmux     # Install a standalone ingredient

# Homebrew
dot brew update                 # Update, upgrade & cleanup
dot brew dump                   # Export to Brewfile

# Shell
dot shell reload                # Reload ZSH configuration
dot shell reset                 # Reset zinit plugins and reload
dot shell clean                 # Remove stray ZSH files from HOME

# Neovim
dot nvim reset                  # Reset lazy.nvim packages

# Remote Bridge
dot rb start|stop|restart|status|logs

# Maintenance
dot update                      # Interactive update wizard (LazyVim, Homebrew, App Store, macOS)
dot update --yes                # Skip confirmations
dot edit                        # Open dotfiles in $EDITOR
dot color-test                  # Terminal color test
dot help                        # Show all commands
```

Backward-compatible aliases still work: `brewup`, `brewdump`, `zsh-reload`, `dotedit`.

### Future `dot` CLI Enhancements

Deferred from v1 (reviewed by multi-agent debate):

| Command | Purpose | Complexity |
|---------|---------|------------|
| `dot doctor` | Diagnose broken symlinks, missing deps, stale caches | Medium |
| `dot uninstall` | Unified uninstall replacing scripts/uninstall.sh | Low |
| `dot status` | Dotfiles health — last update, dirty git state, outdated packages | Medium |
| `dot sync` | Pull latest dotfiles + re-run install-profile | Low |

### Bootstrap (Makefile)

For fresh clones before ZSH is configured:
```bash
make install                    # Run ./install-profile macos
make uninstall                  # Remove all symlinks
make help                       # Show available targets
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
- `atuin.zsh` - Atuin shell history integration (auto-installs if missing)
- `check_git_cleanup.zsh` - Git branch cleanup reminders
- `claude-config.zsh` - Claude Code scripts PATH setup (`~/repos/claude-config/scripts`)
- `fzf.zsh` - Fuzzy finder integration
- `history.zsh` - ZSH history configuration
- `keybindings.zsh` - Custom key mappings
- `mise.zsh` - mise runtime version manager activation
- `neovim.zsh` - Neovim configuration
- `ngrok.zsh` - Ngrok tunnel integration
- `node.zsh` - Node.js version management (fnm fallback) and npm aliases
- `plugins.zsh` - Plugin management via zinit
- `prompt.zsh` - Starship prompt configuration
- `remote-bridge.zsh` - Remote Bridge clipboard/URL/notification integration
- `ssh-agent.zsh` - SSH agent management
- `tmuxinator.zsh` - Tmuxinator session management
- `zinit.zsh` - Zinit plugin manager initialization
- `dot.zsh` - Unified `dot` CLI with fzf menu, update wizard, and tab completion
- `worktree.zsh` - Git worktree helpers with git-native signatures (`gwta`, `gwts`, `gwtl`, `gwtr`, `gwtp`, `gwtmain`, `gwth`)

#### Node.js Runtime Management

**mise** is the preferred polyglot runtime version manager, replacing fnm for interactive shell use. fnm is kept as a fallback for non-interactive contexts (e.g., Makefile subshells in LIA/TYPO3 projects).

**Architecture:**
- `mise.zsh` - Activates mise shell hooks (`chpwd`) for auto-switching on `cd`
- `node.zsh` - Initializes fnm with `--use-on-cd` only when mise is NOT available
- mise reads `.nvmrc`, `.node-version`, `.tool-versions`, and `.mise.toml` files natively (`legacy_version_file = true` in `~/.config/mise/config.toml`)

**Why both mise and fnm:**
LIA/TYPO3 projects use a shared `handleNode.sh` script (in `lia-package/.tools/`) that runs inside Makefile subshells. These non-interactive subshells don't trigger mise's `chpwd` hook, so `handleNode.sh` falls back to fnm/nvm for version switching. mise handles the interactive shell; fnm handles scripted version switches in team tooling.

**Load order in `.zshrc` (order matters):**
1. Pi fnm PATH setup (adds `/home/pi/.local/share/fnm` to PATH if present, skipped when mise exists)
2. `mise.zsh` - activates mise
3. `node.zsh` - initializes fnm only if mise is absent

**Raspberry Pi specifics:**
fnm is installed at a non-standard path (`/home/pi/.local/share/fnm`) on Pi. The PATH addition happens before `node.zsh` so that `command_exists fnm` succeeds and fnm initializes with `--use-on-cd` (not a bare `fnm env` which lacks auto-switching).

#### ZSH Helper Functions (`zsh/utils.zsh`)

**Always use these helpers instead of raw shell commands** for consistency:

| Function | Purpose |
|----------|---------|
| `command_exists <cmd>` | Check if command is available |
| `file_exists <path>` | Check if file exists |
| `folder_exists <path>` | Check if directory exists |
| `path_exists <path>` | Check if path exists (file or directory) |
| `is_macos` / `is_linux` | Platform detection |
| `is_raspberry_pi` | Detect Raspberry Pi |
| `is_ssh_client` | Detect SSH environment |
| `open_command <path/url>` | Cross-platform open |
| `prompt_user <q> <yes> <no>` | Interactive prompt |

**Convention:** Use `command_exists` over `which`, `path_exists` over `[ -d ]`.

#### Git Worktree Helpers (`zsh/config/worktree.zsh`)

Project-agnostic worktree management with zero configuration. Auto-detects paths from `git rev-parse --git-common-dir` and discovers gitignored config files to copy.

| Command | Purpose |
|---------|---------|
| `gwta [-b <branch>] <name-or-path> [commit-ish]` | Add worktree with git-native branch semantics |
| `gwts [pattern]` | Switch worktrees (fzf interactive or pattern match on path/branch) |
| `gwtl` | List worktrees with current marker, branch, and short SHA |
| `gwtr [path]` | Remove worktree with safety checks (uncommitted changes, unpushed commits) |
| `gwtp` | Prune stale worktree entries |
| `gwtmain` | Jump to main worktree |
| `gwth` | Show help |

**`gwta` branch logic (mirrors `git worktree add`):**
- `gwta <name>` — try checkout first (local + remote DWIM), fall back to create from HEAD
- `gwta <path>` — git derives branch from basename (`/`, `./`, `../` prefixed = path)
- `gwta <name> <ref>` — checkout existing ref (branch, tag, commit) into specified folder
- `gwta -b <branch> <name-or-path>` — create new branch from HEAD with custom folder name
- `gwta -b <branch> <name-or-path> <ref>` — create new branch from ref with custom folder name

**Path detection:** bare names → `<parent-of-main-worktree>/<name>`, `./`/`../`/`/` prefixed → resolved as path (git derives branch from basename)

**Key design decisions:**
- Config detection uses `git ls-files -z --others --ignored` with size filter (<100KB), matching against **basename only**
- Matches: `*.local*`, `*.env*`, `config*.php`, `*config*.yaml`, `*.conf`, `*.ini`, `*.secrets*`
- Skips: `*node_modules/*`, `*vendor/*`, `var/`, `.cache/`, `public/fileadmin/` (nested dirs too)
- Uses `zstat` (via `zmodload zsh/stat`) for portable file size checks
- Tab completion: `gwta` completes `-b` flag + branches/refs, `gwts`/`gwtr` complete worktree paths
- `gwts` pattern matching searches both worktree path and branch name

## Key Tools & Their Configs

### Terminal & Shell
- **tmux**: Advanced configuration in `tmux/` with responsive status bar, remote-friendly defaults, and curated plugin setup
- **zsh**: Modular config in `zsh/config/` with automatic sourcing
- **starship**: Prompt config in `.config/starship.toml`

### Development Tools
- **atuin**: Shell history sync/search in `zsh/config/atuin.zsh` (auto-installs if missing)
- **mise**: Polyglot runtime manager in `zsh/config/mise.zsh`, config in `~/.config/mise/config.toml`
- **fnm**: Node.js version manager fallback in `zsh/config/node.zsh` (used when mise is absent)
- **neovim**: Full configuration in `.config/nvim/`
- **git**: Configuration in `git/` directory
- **bat**: Syntax highlighting themes in `.config/bat/`

### macOS-Specific
- **Homebrew**: Package definitions in `brew/osx/.Brewfile`
- **macOS defaults**: System settings via `scripts/setup_defaults_write.sh`
- **Window management**: AeroSpace, Hammerspoon, Karabiner configs

## Remote Bridge System

@.claude/instructions/remote-bridge.md

## Documentation Maintenance

This repo has three documentation layers (see global CLAUDE.md for general policy):

- **`README.md`** (root) — Human-facing: features, installation, screenshots
- **`CLAUDE.md`** (root) — AI-facing: architecture, file paths, commands
- **Topic READMEs** (`tmux/`, `remote-bridge/`, `meta/`, `.hammerspoon/`) — Component-specific
- **`docs/`** — Long-form guides (`tmux.md`, `universal-clipboard.md`)

Update all affected layers in the same commit when changing documented functionality.

## Troubleshooting

### Common Issues
- **Broken symlinks**: Run `make uninstall` then reinstall
- **Package conflicts**: Check Homebrew with `brew doctor`
- **Neovim issues**: Reset with `dot nvim reset`
- **Shell not updating**: Run `dot shell reload` or restart terminal

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
