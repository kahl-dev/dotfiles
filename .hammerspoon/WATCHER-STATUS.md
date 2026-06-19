# Hammerspoon Watcher Status - macOS 26 Compatibility

This document tracks the status of all event watchers after upgrading to macOS 26.

## Summary

| Watcher Type | Status | Notes |
|--------------|--------|-------|
| Caffeinate (Sleep/Wake) | ✅ **FIXED** | Added `systemDidWake` and `systemWillSleep` handlers |
| Screen (Display) | ✅ Working | No changes needed |
| USB Device | ✅ Working | No changes needed |
| Audio Device | ✅ **Verified** | FourCC codes (`dIn `/`dOut`/`dev#`) confirmed firing; daemon reworked intent-aware (output two-state, strict input guard, mute) |
| Config File | ✅ Working | `hs.pathwatcher` on the shared config dir → live reload of device priority / inputGuard |
| Camera | ✅ Working | Using modern `hs.camera` API |
| Application | ✅ Working | No changes needed |

## Detailed Status

### ✅ Caffeinate Watcher (FIXED)
**File:** `modules/display-manager.lua:334-360`

**Issue:** macOS 26 changed which caffeinate events fire for sleep/wake cycles.
- **Old events:** `screensDidLock`, `screensDidUnlock`
- **New events:** `systemDidWake`, `systemWillSleep`

**Fix Applied:** Added handlers for both old and new events for backward compatibility.

```lua
-- Now handles both old and new macOS event types
elseif event == hs.caffeinate.watcher.systemDidWake then
    eventName = "systemDidWake"
    M.log("System woke from sleep - treating as unlock")
    M.handleMacBookUnlock()
elseif event == hs.caffeinate.watcher.systemWillSleep then
    eventName = "systemWillSleep"
    M.log("System going to sleep - treating as lock")
    M.handleMacBookLock()
```

### ✅ Audio Device Watcher (VERIFIED)
**File:** `modules/audio-manager.lua`

**Status:** Verified working. The legacy CoreAudio FourCC codes still fire:
- `"dIn "` - Default input device changed
- `"dOut"` - Default output device changed
- `"dev#"` - Device list changed

The module was reworked into an intent-aware daemon (output two-state machine, strict Wave:3 input
guard, per-device mute with gain memory) plus a shared-config `hs.pathwatcher` that live-reloads
device priority / inputGuard from `~/.config/audio-manager/config.json`. All paths were live-verified.

**If audio switching ever regresses:** re-check the FourCC codes via `test-audio-events.lua`, or fall
back to polling-based device monitoring.

### ✅ Other Watchers
All other watchers use modern, stable APIs and should work fine:
- **Screen watcher** - Simple callback on configuration changes
- **USB watcher** - Standard USB device detection
- **Camera watcher** - Uses newer `hs.camera` API (already modern)
- **Application watcher** - Standard app lifecycle events

## Testing Instructions

### Quick Test (Current Setup)
Your system should now work normally. Test by:
1. **Lock/unlock your Mac** - Monitor should power on/off ✓
2. **Connect/disconnect USB devices** - Apps should launch/quit
3. **Change audio devices** - Should switch to Elgato mic
4. **Connect external display** - Should detect and manage power

### Comprehensive Test (Optional)
To verify ALL watchers work correctly:

1. Uncomment this line in `~/.hammerspoon/init.lua`:
   ```lua
   require("test-all-watchers")
   ```

2. Reload Hammerspoon

3. Perform test actions (you'll see alerts for each event detected)

4. Press **Ctrl+Cmd+Shift+Alt+T** to stop tests and view results

### Audio-Specific Test (If Issues)
If audio device switching stops working:

1. Add to `init.lua`:
   ```lua
   require("test-audio-events")
   ```

2. Change audio devices and observe which event codes fire

3. Press **Ctrl+Cmd+Shift+Alt+A** to stop

## Maintenance

When upgrading macOS in the future:
1. Check Hammerspoon console for any deprecation warnings
2. Test all functionality after OS updates
3. Refer to this document to identify which watchers may need updates
4. Keep test scripts for quick verification

## Cleanup

Test scripts to remove after verification:
- `test-all-watchers.lua`
- `test-audio-events.lua`
- Remove commented test lines from `init.lua`

---
Last Updated: 2025-10-12 (macOS 26.0.1)
