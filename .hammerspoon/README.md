# Hammerspoon Device & Display Manager

A clean, efficient Hammerspoon configuration that automatically manages Elgato devices and external display setups with smart power control.

## ✨ Features

### Device Management
- **Automatic app management** - Apps launch when devices connect, quit when disconnected
- **Hidden launch** - Apps start in the background without disrupting your workflow
- **Smart audio switching** - Automatically switches to Wave microphone when connected
- **User intent respect** - Won't relaunch apps you manually quit

### Display Management 🆕
- **Smart desk power control** - Automatically controls Eve smart plugs based on display state
- **Lock/unlock awareness** - Powers down desk setup when MacBook is locked
- **Instant response** - Event-driven, no polling delays
- **Home Assistant integration** - Direct API calls for reliable control

## 🚀 Quick Start

### Essential Hotkeys
1. **Reload configuration**: `Cmd+Alt+R`
2. **Toggle app visibility**: `Cmd+Alt+V`
3. **Display debug info**: `Cmd+Alt+D` (shows current display state)

### Setup Display Management
1. **Create private configuration**: Copy the template below to `~/.hammerspoon/config/private.json`
2. **Get Home Assistant token**: Follow the "Home Assistant Setup" section below
3. **Configure your display UUID**: Use `Cmd+Alt+D` to find your display UUID
4. **Reload Hammerspoon**: Press `Cmd+Alt+R`

Your setup will now automatically manage itself!

## ⚙️ Configuration

Edit `~/.hammerspoon/config/devices.json` to customize behavior:

### Device Configuration
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

### Display Configuration 🆕
```json
{
  "displays": {
    "desk_setup": {
      "display_uuid": "F7C9EE9C-B4E6-4D31-9218-BE5DB1C1BF99",
      "display_name": "External Display",
      "eve_plug": {
        "enabled": true,
        "home_assistant_url": "http://homeassistant.local:8123",
        "entity_id": "switch.eve_schreibtisch",
        "token": "YOUR_LONG_LIVED_TOKEN"
      },
      "power_on_triggers": ["display_connected", "unlock_with_display"],
      "power_off_triggers": ["display_disconnected", "lock_with_display"],
      "delays": {
        "power_on": 0.5,
        "power_off": 3.0,
        "lock_threshold": 5.0
      }
    }
  },
  "macbook_display_uuid": "37D8832A-2D66-02CA-B9F7-8F30A301B230"
}
```

### Private Configuration (Required for Display Management) 🔒
Create `~/.hammerspoon/config/private.json` with your real Home Assistant credentials:

```json
{
  "homeassistant": {
    "url": "https://your-nabu-casa-url.ui.nabu.casa",
    "token": "your_long_lived_access_token"
  }
}
```

**Note**: This file is automatically ignored by git to keep your credentials safe.

## 🏠 Home Assistant Setup

### Getting Your Nabu Casa URL
1. Log into your Home Assistant
2. Go to **Settings** → **System** → **Network**
3. Find your **Remote URL** (e.g., `https://abc123.ui.nabu.casa`)

### Creating a Long-Lived Access Token
1. In Home Assistant, click your **profile** (bottom left corner)
2. Scroll down to **"Long-lived access tokens"**
3. Click **"Create Token"**
4. Give it a name like "Hammerspoon Display Control"
5. **Copy the token immediately** (you can't see it again!)
6. Paste it into your `private.json` file

### Finding Your Smart Plug Entity ID
1. Go to **Settings** → **Devices & Services**
2. Find your Eve smart plug device
3. Click on it to see entities
4. Copy the entity ID (e.g., `switch.arbeitszimmer_1og_schreibtisch_2`)
5. This goes in the main `devices.json` file (it's not sensitive)

### Finding Your Display UUID
1. Connect your external display
2. Press **`Cmd+Alt+D`** in Hammerspoon
3. Look for the display UUID in the debug output
4. Update the `display_uuid` in `devices.json`

## 📁 File Structure

```
.hammerspoon/
├── init.lua                     # Main entry point
├── modules/
│   ├── usb-device-manager.lua  # USB detection & app management
│   ├── audio-manager.lua       # Audio device switching
│   ├── display-manager.lua     # Display & power management 🆕
│   └── config.lua              # Configuration loader
└── config/
    ├── devices.json            # Public settings (safe for git)
    └── private.json            # Private credentials (git ignored) 🔒
```

## 🔧 How It Works

### Device Management
1. **USB monitoring** - Detects when Elgato devices connect/disconnect
2. **App lifecycle** - Launches apps hidden, tracks user interactions
3. **Audio coordination** - Switches to Wave microphone when available
4. **State tracking** - Remembers if you manually quit or showed apps

### Display Management 🆕
1. **Display detection** - Monitors screen connect/disconnect via `hs.screen.watcher`
2. **Lock/unlock monitoring** - Tracks MacBook state via `hs.caffeinate.watcher`
3. **Smart logic** - Powers on when display connects or unlocks, powers off when disconnects or locks
4. **Home Assistant API** - Direct HTTP calls to control Eve smart plug
5. **Intelligent delays** - Prevents rapid on/off cycles with configurable timings

## 💡 Tips

### Device Management
- Apps launch hidden by default - use `Cmd+Alt+V` to show them
- If you quit an app manually, it won't relaunch until you reconnect the device
- Wave Link takes 3 seconds to hide (needs time to initialize)
- Stream Deck hides after 2 seconds

### Display Management 🆕
- Use `Cmd+Alt+D` to check current display status and debug issues
- The system respects your Home Assistant automations - disable the old ones first
- Lock threshold prevents accidental power-offs from brief screen locks
- Configure delays to match your devices' power-on/off characteristics

## 🐛 Troubleshooting

### Device Issues
**Apps not hiding?**
- Wave Link may have a splash screen that can't be hidden initially
- Use `Cmd+Alt+V` to toggle visibility manually

**Apps not launching?**
- Check if device is connected (unplug/replug to test)
- Reload Hammerspoon with `Cmd+Alt+R`

**Wrong microphone selected?**
- Edit `elgatoInputName` in devices.json if your Wave device has a different name

### Display Issues 🆕
**Eve plug not responding?**
- Check that `~/.hammerspoon/config/private.json` exists with valid credentials
- Verify your Home Assistant URL and token are correct
- Use `Cmd+Alt+D` to see debug info and verify display detection
- Check Hammerspoon console for API errors

**Display UUID not detected?**
- Connect your external display and press `Cmd+Alt+D`
- Copy the UUID from the debug output to `devices.json`
- Make sure you're using the external display UUID, not MacBook's

**Private config not working?**
- Ensure `private.json` exists in `~/.hammerspoon/config/`
- Check JSON syntax is valid (use a JSON validator)
- Reload Hammerspoon completely (Quit → Restart)

**API Authentication errors (401)?**
- Create a fresh long-lived token in Home Assistant
- Double-check the token in `private.json` (no extra spaces/characters)
- Verify your Nabu Casa URL is correct

## 🎯 Design Philosophy

This configuration follows the principle of **minimal intervention**:
- Only two hotkeys (reload and visibility toggle)
- No status bars or unnecessary UI
- No complex profiles or context detection
- Clean, maintainable code (~500 lines total vs 2000+ before)

The system just works, quietly in the background, exactly as it should.