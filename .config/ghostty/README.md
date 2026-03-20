# Ghostty Terminal Configuration

## Theme
Uses **Catppuccin Mocha** for consistency with other tools.

## Key Features

- **Transparency**: 85% opacity with blur
- **Bloom shader**: Subtle glow effect (`bloom025.glsl`)
- **tmux-friendly**: Default keybinds disabled, Ghostty-native management via `Ctrl+G` leader key
- **Quick terminal**: `Ctrl+Opt+Shift+Cmd+O` toggles dropdown terminal
- **Command notifications**: Desktop notification when commands >5s finish while unfocused
- **Auto-scroll**: Scrolls to bottom on any output

## macOS Option Key & Umlauts

### The Problem

On macOS, the Option key has two mutually exclusive behaviors:

| Mode | Option+T | Option+U |
|------|----------|----------|
| **Character mode** (default) | `†` (dagger) | Dead key `¨` → type `a` → `ä` |
| **Alt/Meta mode** | `ESC+t` (escape sequence) | `ESC+u` (escape sequence) |

Terminal apps like Claude Code need **Alt/Meta mode** for hotkeys (e.g., `Alt+T` for thinking toggle).
German keyboard users need **Character mode** for umlauts (ä, ö, ü via `Option+U`).

**You can't have both simultaneously** because the terminal receives different input.

### Solutions

#### Option A: Split Left/Right Option (if your keyboard has both)
```
macos-option-as-alt = right
```
- Left Option → umlauts (character mode)
- Right Option → Alt hotkeys (meta mode)

#### Option B: Remap via Ghostty keybind (current solution)

For keyboards without right Option key (e.g., compact Keychron):

```
macos-option-as-alt = false
keybind = ctrl+t=esc:t
```

This keeps Option in character mode for umlauts, and maps `Ctrl+T` to send the `ESC+t` escape sequence that Claude Code interprets as `Alt+T`.

### Current Keybind Remappings

| Keys | Action | Why |
|------|--------|-----|
| `Ctrl+T` | Send `Alt+T` (thinking toggle) | Option needed for umlauts |
| `Ctrl+G` → key | Ghostty leader key (key table) | Native window mgmt without tmux conflicts |

### Ghostty Leader Key (`Ctrl+G`)

Press `Ctrl+G` to enter Ghostty mode, then:

| Key | Action |
|-----|--------|
| `d` | Split right |
| `Shift+D` | Split down |
| `Enter` | Toggle split zoom |
| `←↑↓→` | Navigate splits |
| `=` | Equalize splits |
| `w` | Close surface |
| `f` | Toggle fullscreen |
| `Escape` | Cancel |

Note: No tab keybinds — AeroSpace conflicts with Ghostty native tabs. Use tmux for multiplexing.

## Shaders

Shaders from [ghostty-shaders](https://github.com/hackr-sh/ghostty-shaders). Currently using `bloom025.glsl` for subtle glow.

To try others, uncomment in config:
```
# custom-shader = shaders/crt.glsl
# custom-shader = shaders/starfield.glsl
```
