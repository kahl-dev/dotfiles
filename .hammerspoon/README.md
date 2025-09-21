# Hammerspoon Elgato Device Manager

A clean, efficient Hammerspoon configuration that automatically manages Elgato Stream Deck and Wave Link applications based on USB device connectivity.

## ✨ Features

- **Automatic app management** - Apps launch when devices connect, quit when disconnected
- **Hidden launch** - Apps start in the background without disrupting your workflow
- **Smart audio switching** - Automatically switches to Wave microphone when connected
- **User intent respect** - Won't relaunch apps you manually quit
- **Minimal hotkeys** - Only two essential shortcuts

## 🚀 Quick Start

1. **Reload configuration**: `Cmd+Alt+R`
2. **Toggle app visibility**: `Cmd+Alt+V`

That's it! Your Elgato apps will automatically manage themselves.

## ⚙️ Configuration

Edit `~/.hammerspoon/config/devices.json` to customize behavior:

```json
{
  "devices": {
    "stream_deck": {
      "launch_hidden": true  // Launch in background
    },
    "wave_link": {
      "launch_hidden": true,
      "coordinate_audio": true  // Auto-switch audio
    }
  },
  "settings": {
    "launch_delay": 2.0,      // Seconds before launching
    "hide_delay": 2.0,        // Seconds before hiding
    "notifications": false    // Show/hide notifications
  }
}
```

## 📁 File Structure

```
.hammerspoon/
├── init.lua                     # Main entry point
├── modules/
│   ├── usb-device-manager.lua  # USB detection & app management
│   ├── audio-manager.lua       # Audio device switching
│   └── config.lua              # Configuration loader
└── config/
    └── devices.json            # User settings
```

## 🔧 How It Works

1. **USB monitoring** - Detects when Elgato devices connect/disconnect
2. **App lifecycle** - Launches apps hidden, tracks user interactions
3. **Audio coordination** - Switches to Wave microphone when available
4. **State tracking** - Remembers if you manually quit or showed apps

## 💡 Tips

- Apps launch hidden by default - use `Cmd+Alt+V` to show them
- If you quit an app manually, it won't relaunch until you reconnect the device
- Wave Link takes 3 seconds to hide (needs time to initialize)
- Stream Deck hides after 2 seconds

## 🐛 Troubleshooting

**Apps not hiding?**
- Wave Link may have a splash screen that can't be hidden initially
- Use `Cmd+Alt+V` to toggle visibility manually

**Apps not launching?**
- Check if device is connected (unplug/replug to test)
- Reload Hammerspoon with `Cmd+Alt+R`

**Wrong microphone selected?**
- Edit `elgatoInputName` in devices.json if your Wave device has a different name

## 🎯 Design Philosophy

This configuration follows the principle of **minimal intervention**:
- Only two hotkeys (reload and visibility toggle)
- No status bars or unnecessary UI
- No complex profiles or context detection
- Clean, maintainable code (~500 lines total vs 2000+ before)

The system just works, quietly in the background, exactly as it should.