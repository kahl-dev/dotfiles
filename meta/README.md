# 🏗️ Meta Configuration System

Modular **dotbot**-based configuration management with ingredients and recipes architecture.

## 🧩 Architecture

This system uses a two-tier approach for maximum flexibility:

### Ingredients (Individual Modules)
Located in `ingredients/` - each file configures one specific tool or feature:

- `bat.yaml` - Syntax highlighting configuration
- `neovim_build.yaml` - Neovim from source with optimizations
- `tmux.yaml` - Terminal multiplexer setup
- `zsh.yaml` - Shell configuration
- `macos_defaults.yaml` - System preferences
- `homebrew_osx.yaml` - Package installations

### Recipes (Installation Profiles)  
Located in `recipes/` - combine multiple ingredients for different use cases:

- `macos.yaml` - Complete macOS development setup
- `liadev.yaml` - Development server configuration  
- `pi.yaml` - Raspberry Pi minimal setup

## 🚀 Usage

### Full Profile Installation
```bash
# Complete macOS setup (recommended)
./install-profile macos

# Development server setup
./install-profile liadev

# Minimal Pi setup
./install-profile pi
```

### Standalone Component Installation
```bash
# Install just tmux configuration
./install-standalone tmux

# Install just Neovim
./install-standalone neovim_build

# Install shell configuration only
./install-standalone zsh
```

## 📁 File Structure

```
meta/
├── base.yaml              # Base dotbot configuration
├── ingredients/           # Individual configuration modules
│   ├── bat.yaml
│   ├── homebrew_osx.yaml
│   ├── macos_defaults.yaml
│   ├── neovim_build.yaml
│   ├── tmux.yaml
│   └── zsh.yaml
├── recipes/              # Installation profiles
│   ├── liadev.yaml       # Development server
│   ├── macos.yaml        # Complete macOS setup
│   └── pi.yaml           # Raspberry Pi minimal
└── dotbot/               # Dotbot framework (submodule)
```

## 🔧 Adding New Components

### 1. Create an Ingredient
Create `ingredients/newapp.yaml`:
```yaml
- create:
    - ~/.config/newapp

- link:
    ~/.config/newapp/config.yaml: .config/newapp/config.yaml

- shell:
    - description: Configure newapp
      command: newapp --setup
```

### 2. Add to Recipe  
Edit `recipes/macos.yaml`:
```yaml
- import: 
    - ../ingredients/newapp.yaml
```

### 3. Test Installation
```bash
./install-standalone newapp
```

## ⚙️ How It Works

### Base Configuration
`base.yaml` provides common settings:
- Default shell and directory creation
- Common link patterns
- Error handling configuration

### Installation Scripts
- `../install-profile` - Loads recipe + base configuration
- `../install-standalone` - Loads single ingredient + base configuration  
- Both use dotbot's YAML configuration system

### Dotbot Integration
The system leverages dotbot's capabilities:
- **link**: Create symbolic links
- **create**: Create directories  
- **shell**: Run shell commands
- **clean**: Remove broken symlinks
- **import**: Include other configuration files

## 🎯 Best Practices

### Ingredient Design
- **Single responsibility**: One ingredient per tool/feature
- **Idempotent**: Safe to run multiple times
- **Self-contained**: Include all dependencies and setup

### Recipe Composition  
- **Logical grouping**: Group related ingredients
- **Environment-specific**: Different recipes for different environments
- **Minimal overlap**: Avoid duplicate ingredients across recipes

### Testing
- Always test standalone installation first
- Use `make uninstall` to clean up before retesting
- Verify symlinks with `ls -la` after installation

This modular approach allows mixing and matching configurations while keeping individual components maintainable and reusable.