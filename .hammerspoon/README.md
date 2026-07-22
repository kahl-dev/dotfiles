# Hammerspoon Device & Display Manager

Background automation for audio, displays and presence. Event-driven, no hotkeys,
no menu bar UI. Everything reacts to USB, display and camera events, or to Raycast
scripts calling in over `hs -c`.

## Table of Contents

- [Features](#features)
- [Install](#install)
- [Usage](#usage)
- [Configuration](#configuration)
- [File Structure](#file-structure)
- [How It Works](#how-it-works)
- [Troubleshooting](#troubleshooting)
- [Design Philosophy](#design-philosophy)

## Features

### Audio
- **Wave:3 input guard** — the Wave:3 stays the default input; a stray macOS switch
  is reverted. Only a deliberate Raycast pick overrides it.
- **Output priority** — follows a priority list from `~/.config/audio-manager/config.json`
  (shared with Raycast), unless you picked a device yourself.
- **No Elgato software** — CoreAudio is driven directly, Wave Link is not in the signal path.
- Runs only while the Wave:3 is connected, started and stopped by the USB watcher.

### Display
- **Desk power control** — switches an Eve smart plug via Home Assistant based on
  external display state.
- **Lock/unlock awareness** — powers the desk down when the MacBook locks.
- **Call light** — camera, microphone and call-app detection drive a second plug
  automatically. There is no manual toggle; the watchers own the state.

### Presence
- **Idle prevention** — pulses F15 so Teams and Slack do not go idle-yellow.
  Auto-enables while video plays, toggleable from Raycast.

## Install

Hammerspoon itself comes from the Brewfile. The configuration is symlinked by
dotbot, so there is no separate install step:

```bash
./install-standalone macos_general   # links ~/.hammerspoon -> ./.hammerspoon/
./install-standalone private-macos   # links the two config/*.json from dotfiles-private
```

Both ingredients are part of the `macos` recipe, so a full
`./install-profile macos` covers them.

Grant Hammerspoon the Accessibility permission on first launch — `presence-keeper`
synthesizes an F15 keypress through `hs.eventtap`, which macOS refuses without it.
The USB, audio, display and camera watchers work without additional permissions.

## Usage

There are no keyboard shortcuts. The configuration reloads itself whenever a `.lua`
or `.json` file below `~/.hammerspoon/` changes (`hs.pathwatcher` in `init.lua`).

Manual control goes through the `hs` CLI, which is how the Raycast scripts drive it:

```bash
hs -c 'require("modules.presence-keeper").toggle()'
hs -c 'require("modules.audio-manager").noteExplicit("output", "<device name>")'
```

`require("hs.ipc")` in `init.lua` is what makes this work — do not remove it.

## Configuration

Both config files are git-ignored and live in `dotfiles-private`, symlinked into
`~/.hammerspoon/config/`.

### `devices.json`

```json
{
  "devices": {
    "wave3_audio": {
      "vendor_id": 4057,
      "product_ids": [102, 103, 112, 113],
      "coordinate_audio": true
    }
  },
  "settings": {
    "debounce_delay": 2.0
  }
}
```

`coordinate_audio` is the only device behaviour left: it starts `audio-manager` on
connect and stops it on disconnect. Application launching was removed along with the
Stream Deck.

### Display configuration

```json
{
  "displays": {
    "desk_setup": {
      "display_uuid": "YOUR-EXTERNAL-DISPLAY-UUID",
      "display_name": "External Display",
      "eve_plug": {
        "enabled": true,
        "home_assistant_url": "YOUR-HOME-ASSISTANT-URL",
        "entity_id": "switch.my_desk_plug",
        "token": "YOUR_LONG_LIVED_TOKEN"
      },
      "power_on_triggers": ["display_connected", "unlock_with_display"],
      "power_off_triggers": ["display_disconnected", "lock_with_display"],
      "delays": { "power_on": 0.5, "power_off": 3.0, "lock_threshold": 5.0 }
    }
  },
  "macbook_display_uuid": "YOUR-BUILTIN-DISPLAY-UUID"
}
```

### Finding your display UUID

```bash
hs -c 'for _,s in ipairs(hs.screen.allScreens()) do print(s:name(), s:getUUID()) end'
```

Use the external display's UUID for `display_uuid` and the built-in one for
`macbook_display_uuid`.

## File Structure

```text
.hammerspoon/
├── init.lua                     # Entry point: pathwatcher, IPC, module init
├── modules/
│   ├── config.lua               # Configuration loader (defaults + JSON merge)
│   ├── usb-device-manager.lua   # USB watcher → starts/stops audio-manager
│   ├── audio-manager.lua        # CoreAudio input guard & output priority
│   ├── display-manager.lua      # Display power, lock state, call light
│   └── presence-keeper.lua      # F15 pulse against idle status
└── config/
    ├── devices.json             # Device/display config — git-ignored, dotfiles-private
    └── private.json             # Home Assistant credentials — git-ignored, dotfiles-private
```

## How It Works

### Audio
1. `usb-device-manager` watches USB events, debounced by `debounce_delay`
2. Wave:3 connects → `audio-manager.init()`; disconnects → `audio-manager.stop()`
3. While active, input is pinned to the Wave:3 and output follows the priority list
4. Raycast reports deliberate picks via `noteExplicit`, so a user choice is not reverted

### Display and call light
1. `hs.screen.watcher` tracks display connect/disconnect
2. `hs.caffeinate.watcher` tracks lock/unlock
3. `hs.camera` property watchers plus microphone and call-app detection drive
   `handleCallStateChange` → `controlCallLight`
4. Both plugs are switched over the Home Assistant HTTP API

## Troubleshooting

**Audio not switching?**
- Confirm the Wave:3 is seen: `hs -c 'local u=require("modules.usb-device-manager") return hs.inspect(u.state.deviceStates)'`
- Confirm the manager is live: `hs -c 'return tostring(require("modules.audio-manager").state.active)'`
- Check the priority list in `~/.config/audio-manager/config.json`

**Call light not reacting?**
- It follows the camera automatically; there is no manual switch
- Verify `call_light` exists in `private.json`
- Check the Hammerspoon console for Home Assistant API errors

**Eve plug not responding?**
- Verify `private.json` exists with a valid URL and token
- Re-create the long-lived token in Home Assistant on a 401

**Nothing reloads?**
- The pathwatcher only reacts to `.lua` and `.json` below `~/.hammerspoon/`
- Force it with `hs -c 'hs.reload()'`

## Design Philosophy

Minimal intervention:
- No hotkeys — every trigger is an event or an explicit Raycast call
- No status bars or extra UI
- Manual overrides only where automation cannot decide (audio device choice)

The system runs quietly in the background, which is the point.
