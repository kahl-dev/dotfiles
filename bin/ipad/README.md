# iPad Management Scripts for Raycast

These scripts allow you to control iPad display modes through Raycast commands.

## Available Scripts

1. **`toggle-sidecar`** - Toggle Sidecar (iPad as display extension)
2. **`toggle-universal-control`** - Enable Universal Control mode (iPad standalone)
3. **`smart-toggle`** - Intelligently switch between modes
4. **`status`** - Show current iPad connection status

## Setup in Raycast

1. Open Raycast preferences (`cmd + ,`)
2. Go to **Extensions** > **Script Commands** > **Add Script Directory**
3. Add this directory: `~/.dotfiles/bin/ipad`
4. The commands will appear as:
   - "Toggle Sidecar"
   - "Toggle Universal Control"
   - "Smart Toggle iPad Mode"
   - "iPad Status"

## Usage

- **Sidecar Mode**: Use iPad as a second monitor extending your Mac's display
- **Universal Control Mode**: Use iPad as standalone device with its own mouse/keyboard
- **Smart Toggle**: Automatically switches between modes based on current state

## Hotkeys (if Hammerspoon is running)

- `cmd + alt + shift + S` - Toggle Sidecar
- `cmd + alt + shift + U` - Universal Control mode
- `cmd + alt + shift + I` - Smart toggle
- `cmd + alt + shift + P` - Show status + toggle debug

## Requirements

- Hammerspoon must be running
- iPad must be signed in with same Apple ID
- iPad and Mac must be on same WiFi network
- Handoff enabled on both devices