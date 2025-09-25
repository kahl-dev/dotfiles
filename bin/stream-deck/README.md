# iPad Management Scripts for Stream Deck

These scripts provide one-touch iPad display mode control via Stream Deck buttons.

## Available Scripts

1. **`ipad-sidecar-toggle`** - Toggle Sidecar (display extension)
2. **`ipad-universal-control`** - Enable Universal Control mode
3. **`ipad-smart-toggle`** - Smart mode switching
4. **`ipad-status`** - Show current status (great for display text)

## Stream Deck Setup

### For System Commands:
1. Add "System -> Open" action to your Stream Deck
2. Set the path to one of these scripts:
   - `~/.dotfiles/bin/stream-deck/ipad-sidecar-toggle`
   - `~/.dotfiles/bin/stream-deck/ipad-universal-control`
   - `~/.dotfiles/bin/stream-deck/ipad-smart-toggle`

### For Status Display:
1. Add "System -> Text File Contents" action
2. Set path to: `~/.dotfiles/bin/stream-deck/ipad-status`
3. Set refresh interval (e.g., 2 seconds)

### Alternative Setup (Advanced):
1. Use "System -> Website" action
2. Create shortcuts that call these scripts
3. Use the shortcuts as web URLs

## Button Suggestions

### Smart Toggle Button:
- **Icon**: iPad or display icon
- **Text**: "iPad Mode"
- **Action**: `ipad-smart-toggle`

### Dedicated Buttons:
- **Sidecar Button**:
  - Icon: Monitor/display
  - Text: "Sidecar"
  - Action: `ipad-sidecar-toggle`

- **Universal Control Button**:
  - Icon: Mouse/trackpad
  - Text: "UC Mode"
  - Action: `ipad-universal-control`

### Status Display:
- **Status Button**:
  - Action: Text display from `ipad-status`
  - Refresh: Every 2-3 seconds
  - Shows: 🖥️ Sidecar ON, 📱 UC Mode, or 📱 iPad Ready

## Feedback Icons

The scripts return different emoji icons for visual feedback:
- 🖥️ - Sidecar mode active
- 📱 - Universal Control mode
- 🔄 - Smart toggle in progress
- ❌ - Error or Hammerspoon not running
- ❓ - Unknown status

## Requirements

- Elgato Stream Deck software
- Hammerspoon running in background
- iPad signed in with same Apple ID
- Same WiFi network for both devices