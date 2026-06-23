-- Audio Device Manager Module
-- Direct macOS switching, intent-aware (no Wave Link in signal path).
-- Output = two-state machine: AUTO follows priority; a user pick (Raycast/Stream Deck) is sacred.
-- Input = strict guard: the default is the inputGuard device (Wave:3); only a Raycast input pick
--   (userExplicitInput) overrides it, and any other change is reverted back to Wave:3.
-- Only active when Wave:3 is USB-connected (managed by usb-device-manager).
-- Priority list read from ~/.config/audio-manager/config.json (shared with Raycast).
--
-- Intent channel: Raycast switches CoreAudio directly, then pushes the choice here via
-- `hs -c "require('modules.audio-manager').noteExplicit('output'|'input', '<name>')"`. That lets
-- the daemon tell a deliberate pick apart from a macOS auto-hijack instead of reverting the user.

local M = {}

local SHARED_CONFIG_PATH = os.getenv("HOME") .. "/.config/audio-manager/config.json"

-- Default configuration (used when shared config is missing or invalid)
M.config = {
    wave3Name = "Wave:3",
    edifierName = "EDIFIER M60",
    airpodsPattern = "AirPods",
    sonyPattern = "WH-1000XM6",
    macbookPattern = "MacBook",
    builtInPattern = "Built-in",
    outputPriority = {
        { pattern = "WH-1000XM6", label = "Sony XM6" },
        { pattern = "AirPods",     label = "AirPods" },
        { pattern = "EDIFIER M60", label = "Edifier M60" },
        { pattern = "Wave:3",      label = "Wave:3 Kopfhörer" },
    },
    debounceDelay = 0.5,
    inputDebounce = 0.4,
    -- Coalesces a burst of config-file writes (editor temp-file+rename, Raycast saves) into one
    -- reload. Separate from the audio-event debounce — unrelated timescales.
    configReloadDebounce = 0.5,
    -- Bluetooth output names, rebuilt from the shared config's `bluetooth` field on load
    -- (loadSharedConfig). This literal is the bootstrap fallback for a missing/unparseable
    -- config.json, mirroring the BT devices in the default outputPriority above so the 3 s reconnect
    -- grace still applies before the shared config loads. config.json is the source once it loads.
    bluetoothNames = { "WH-1000XM6", "AirPods" },
    bluetoothGracePeriod = 3.0,
    -- How long to ignore the watcher event our own switch triggers. hs.audiodevice exposes no
    -- "this change was programmatic" signal, so we suppress by time window — must outlast the
    -- self-event latency without swallowing a real user change mid-window.
    selfEventSuppression = 0.4,
}

-- Load shared config and build priority list from it
function M.loadSharedConfig()
    local file = io.open(SHARED_CONFIG_PATH, "r")
    if not file then
        return false
    end

    local content = file:read("*a")
    file:close()

    local success, config = pcall(hs.json.decode, content)
    if not success or not config or not config.devices then
        return false
    end

    -- Build the auto-selection priority list from devices the daemon MAY auto-pick (autoEligible,
    -- default true) — the single source of eligibility truth, decoupled from `hidden` (UI-only).
    -- A device can be manually selectable in Raycast yet excluded from auto/fallback: the Wave:3
    -- mic's headphone output (autoEligible:false) must never receive system audio automatically.
    -- MacBook stays in via autoEligible:true and sorts last (lowest priority) as the natural
    -- fallback; selectHighestPriorityOutput keeps a hardcoded final safety on top of that.
    local priorityList = {}
    for _, device in ipairs(config.devices) do
        if device.autoEligible ~= false then
            table.insert(priorityList, {
                pattern = device.name,
                label = device.label or device.name,
                priority = device.priority or 999,
            })
        end
    end
    table.sort(priorityList, function(a, b) return a.priority < b.priority end)
    -- Assign unconditionally (config parsed OK above), so an all-ineligible config yields an empty
    -- list instead of silently retaining a stale one on hot-reload.
    M.config.outputPriority = priorityList

    -- Build the Bluetooth-device set from the `bluetooth` field: a device with a bluetooth entry is
    -- wireless and gets the longer reconnect grace (profile-switch settle). Assigned unconditionally
    -- so removing the last BT device clears the set on hot-reload instead of retaining a stale one.
    local bluetoothNames = {}
    for _, device in ipairs(config.devices) do
        if device.bluetooth then
            table.insert(bluetoothNames, device.name)
        end
    end
    M.config.bluetoothNames = bluetoothNames

    -- Read inputGuard
    if config.inputGuard then
        M.config.wave3Name = config.inputGuard
    end

    return true
end

-- Resolve the (possibly symlinked) shared-config path to the real directory containing it, so the
-- file watcher sees edits made through the symlink (Raycast writes the real file in dotfiles-private,
-- and FSEvents fires on the real path). hs.fs.pathToAbsolute resolves symlinks in-process — no
-- subprocess, no shell-quoting, consistent with the module's other hs.* I/O.
function M.resolveConfigDir()
    -- nil when the path can't be resolved — the caller then skips the watcher rather than watching
    -- the symlink's own directory, where FSEvents would never fire for writes to the real file.
    local resolved = hs.fs.pathToAbsolute(SHARED_CONFIG_PATH)
    if not resolved then return nil end
    return resolved:match("^(.*/)")
end

-- React to a shared-config edit: reload the priority list / inputGuard in place. Debounced, and
-- deliberately does NOT force an immediate switch — new priorities apply on the next device event.
-- Intentionally NOT gated by `paused`: a config reload is data-only (no switch), so it stays live.
function M.handleConfigChange()
    if M.state.pendingConfigReload then M.state.pendingConfigReload:stop() end
    M.state.pendingConfigReload = hs.timer.doAfter(M.config.configReloadDebounce, function()
        M.state.pendingConfigReload = nil
        M.loadSharedConfig()
    end)
end

-- State
M.state = {
    active = false,
    -- All automatic arbitration paused (Raycast toggle). Module-scope and NOT reset by init(), so
    -- it survives undock/redock; clears only on a Hammerspoon reload or Mac restart.
    paused = false,
    -- Device NAME the user explicitly chose (Raycast/Stream Deck). nil = AUTO state.
    userExplicitOutput = nil,
    -- Device NAME the user explicitly chose as INPUT (Raycast). nil = strict Wave:3 default.
    userExplicitInput = nil,
    -- True while the daemon performs its own output/input switch, to ignore the resulting event.
    switchInProgress = false,
    inputSwitchInProgress = false,
    -- Last Wave:3 input gain before muting, so unmute restores it instead of blasting to 100.
    preMuteInputVolume = nil,
    -- Set on a "dev#" (device add/remove) event, consumed at the next evaluation. Coarse by
    -- design: it says *something* changed in the burst, not which device — overlapping events in
    -- one debounce window collapse into this single flag. A transition-capture event model
    -- (old -> new default per event) would be more robust; tracked for a later phase.
    pendingHardwareChange = false,
    pendingDeviceCheck = nil,
    pendingInputCheck = nil,
    -- Watches the shared config dir for live edits; pendingConfigReload debounces the reload.
    configWatcher = nil,
    pendingConfigReload = nil,
}

-- Find an output device by name (plain substring match — used for config patterns)
function M.findOutputDevice(name)
    for _, device in ipairs(hs.audiodevice.allOutputDevices()) do
        if string.find(device:name(), name, 1, true) then
            return device
        end
    end
    return nil
end

-- Find an output device by EXACT name — used for the user's explicit pick, which is a full
-- device name. Substring matching here would let a superset name ("EDIFIER M60 Pro") satisfy a
-- pick of "EDIFIER M60" and strand the user on the wrong device.
function M.findOutputDeviceExact(name)
    for _, device in ipairs(hs.audiodevice.allOutputDevices()) do
        if device:name() == name then
            return device
        end
    end
    return nil
end

-- Find Wave:3 input device
function M.findWaveInput()
    for _, device in ipairs(hs.audiodevice.allInputDevices()) do
        if string.find(device:name(), M.config.wave3Name, 1, true) then
            return device
        end
    end
    return nil
end

-- Perform a daemon-initiated input switch, suppressing the watcher event it triggers.
function M.setInput(device)
    if not device then return false end
    M.state.inputSwitchInProgress = true
    local ok = device:setDefaultInputDevice()
    hs.timer.doAfter(M.config.selfEventSuppression, function() M.state.inputSwitchInProgress = false end)
    return ok
end

-- Enforce the strict input policy: the default input is Wave:3 unless the user explicitly picked
-- another mic via Raycast (userExplicitInput). Any other change (System Settings, an app, a
-- Bluetooth connect grabbing the mic) is reverted to Wave:3. A disappeared pick falls back to
-- Wave:3 but keeps the intent so it restores when the mic returns.
function M.evaluateInputState()
    if not M.state.active then return end
    if M.state.paused then return end
    if M.state.inputSwitchInProgress then return end

    local current = hs.audiodevice.defaultInputDevice()
    local currentName = current and current:name() or nil

    -- Common case: the explicit pick is already active -> nothing to do, no enumeration needed.
    if M.state.userExplicitInput and currentName == M.state.userExplicitInput then
        return
    end

    -- Otherwise locate both the explicit pick and the Wave:3 input in a single enumeration.
    local pickDevice, waveInput
    for _, device in ipairs(hs.audiodevice.allInputDevices()) do
        local name = device:name()
        if M.state.userExplicitInput and name == M.state.userExplicitInput then
            pickDevice = device
        end
        if not waveInput and string.find(name, M.config.wave3Name, 1, true) then
            waveInput = device
        end
    end

    -- Explicit pick is connected but input drifted away from it (app/macOS hijack) -> restore it.
    if pickDevice then
        M.setInput(pickDevice)
        return
    end

    -- No pick, or the pick disappeared -> force Wave:3 if present and not already active.
    if waveInput and currentName ~= waveInput:name() then
        M.setInput(waveInput)
    end
end

-- Debounced input evaluation (coalesces rapid changes; avoids a tug-of-war with apps).
function M.scheduleInputCheck()
    if M.state.pendingInputCheck then
        M.state.pendingInputCheck:stop()
    end
    M.state.pendingInputCheck = hs.timer.doAfter(M.config.inputDebounce, function()
        M.state.pendingInputCheck = nil
        M.evaluateInputState()
    end)
end

-- Toggle mute on the CURRENT default input device by its per-device volume — so it mutes the mic
-- actually capturing (Wave:3 under the strict guard, or an explicit Raycast pick), never a device
-- the user isn't on. Muted state is inferred from the gain (0 = muted); the pre-mute gain is
-- remembered so unmute restores it instead of blasting to full. ("MUTED" | "ON" | "NODEV" | "NOVOL").
function M.toggleInputMute()
    local dev = hs.audiodevice.defaultInputDevice()
    if not dev then return "NODEV" end
    local volume = dev:inputVolume()
    if volume == nil then return "NOVOL" end
    if volume > 0 then
        M.state.preMuteInputVolume = volume
        dev:setInputVolume(0)
        return "MUTED"
    end
    dev:setInputVolume(M.state.preMuteInputVolume or 100)
    return "ON"
end

-- Pause / resume all automatic audio arbitration (Raycast "Toggle Audio Automation"). While paused
-- the daemon makes no output/input switches of its own, but manual switches (Raycast, Control
-- Center, System Settings) still apply and stay. Paused state survives undock/redock (see M.state).
function M.pause()
    M.state.paused = true
end

function M.resume()
    M.state.paused = false
    -- Adopt whatever the user landed on during the pause as the new baseline, so resuming neither
    -- yanks the output nor reverts the input on the next device event.
    local currentOutput = hs.audiodevice.defaultOutputDevice()
    if currentOutput then M.state.userExplicitOutput = currentOutput:name() end
    -- Input is a strict guard (nil = enforced Wave:3), not a two-state machine. Only record a pick
    -- if Wave:3 is PRESENT and the user landed on a different mic; on Wave:3 — or while Wave:3 is
    -- absent (undocked) — keep the guard's strict nil state rather than pinning a stale device.
    local currentInput = hs.audiodevice.defaultInputDevice()
    local waveInput = M.findWaveInput()
    if waveInput and currentInput and currentInput:name() ~= waveInput:name() then
        M.state.userExplicitInput = currentInput:name()
    else
        M.state.userExplicitInput = nil
    end
end

function M.togglePause()
    if M.state.paused then
        M.resume()
        return "ACTIVE"
    end
    M.pause()
    return "PAUSED"
end

function M.isPaused()
    return M.state.paused
end

-- Show audio switch feedback on screen
function M.showFeedback(label)
    hs.alert.closeAll()
    hs.alert.show(label, 1.5)
end

-- Perform a daemon-initiated output switch, suppressing the watcher event it triggers.
function M.setOutput(device, label)
    if not device then return false end
    M.state.switchInProgress = true
    local ok = device:setDefaultOutputDevice()
    -- Release suppression after the self-triggered watcher event has passed.
    hs.timer.doAfter(M.config.selfEventSuppression, function() M.state.switchInProgress = false end)
    -- Only claim the switch on screen when CoreAudio actually accepted it; a false success
    -- alert would tell the user the output was corrected when it was not.
    if ok and label then M.showFeedback(label) end
    return ok
end

-- Select highest priority available output device (Phase 3 adds autoEligible filtering)
function M.selectHighestPriorityOutput()
    -- Enumerate CoreAudio outputs once; the set cannot change within this synchronous pass.
    local outputs = hs.audiodevice.allOutputDevices()
    local function findIn(pattern)
        for _, device in ipairs(outputs) do
            if string.find(device:name(), pattern, 1, true) then
                return device
            end
        end
        return nil
    end

    for _, entry in ipairs(M.config.outputPriority) do
        local device = findIn(entry.pattern)
        if device then
            return device, entry.label
        end
    end
    -- Implicit last fallback: MacBook Speakers
    return findIn(M.config.macbookPattern) or findIn(M.config.builtInPattern), "MacBook Speakers"
end

-- True if the device name matches a configured Bluetooth output (M.config.bluetoothNames, built
-- from the shared config's `bluetooth` field). Plain substring match, consistent with the rest of
-- the module's name matching.
function M.isBluetoothDevice(deviceName)
    for _, name in ipairs(M.config.bluetoothNames) do
        if string.find(deviceName, name, 1, true) then
            return true
        end
    end
    return false
end

-- Record an explicit user choice pushed from Raycast (via hs -c).
-- name is the actual macOS device name, matched plainly elsewhere.
function M.noteExplicit(kind, name)
    -- Trust boundary: name arrives from Raycast via hs -c. An empty name would make the
    -- MANUAL "pick is active" check trivially true and freeze the daemon on a phantom pick.
    if not name or name == "" then return end
    if kind == "output" then
        M.state.userExplicitOutput = name
    elseif kind == "input" then
        M.state.userExplicitInput = name
    end
end

-- Clear a recorded explicit pick (e.g. when the Raycast switch it was recorded for failed).
function M.clearExplicit(kind)
    if kind == "output" then
        M.state.userExplicitOutput = nil
    elseif kind == "input" then
        M.state.userExplicitInput = nil
    end
end

-- Switch to a specific device by pattern (Stream Deck / hotkeys / .app bundles).
-- This is an explicit user action, so it sets userExplicitOutput.
function M.switchToDevice(pattern)
    if not M.state.active then return false end
    local device = M.findOutputDevice(pattern)
    if device then
        M.noteExplicit("output", device:name())
        local ok = M.setOutput(device, device:name())
        return ok
    end
    M.showFeedback("Device not found: " .. pattern)
    return false
end

-- Convenience switch functions (for Hammerspoon CLI / .app bundles)
function M.switchToSony()
    return M.switchToDevice(M.config.sonyPattern)
end

function M.switchToAirPods()
    return M.switchToDevice(M.config.airpodsPattern)
end

function M.switchToEdifier()
    return M.switchToDevice(M.config.edifierName)
end

function M.switchToWave3()
    return M.switchToDevice(M.config.wave3Name)
end

function M.switchToMacBook()
    return M.switchToDevice(M.config.macbookPattern)
        or M.switchToDevice(M.config.builtInPattern)
end

-- Evaluate current output state and correct it according to the two-state model.
function M.evaluateOutputState()
    if not M.state.active then return end
    if M.state.paused then return end
    if M.state.switchInProgress then
        -- A switch is mid-flight; re-check after suppression clears instead of dropping the work
        -- (otherwise a hardware change that lands during the window is silently lost).
        if M.state.pendingDeviceCheck then M.state.pendingDeviceCheck:stop() end
        M.state.pendingDeviceCheck = hs.timer.doAfter(M.config.selfEventSuppression, function()
            M.state.pendingDeviceCheck = nil
            M.evaluateOutputState()
        end)
        return
    end

    local currentOutput = hs.audiodevice.defaultOutputDevice()
    if not currentOutput then
        -- No output at all -> emergency fallback
        local fallback, label = M.selectHighestPriorityOutput()
        if fallback then
            M.setOutput(fallback, label .. " (fallback)")
        end
        return
    end

    local currentName = currentOutput:name()
    -- Was this evaluation triggered by a device add/remove (hardware) burst?
    local hardwareChange = M.state.pendingHardwareChange
    M.state.pendingHardwareChange = false

    -- MANUAL state: a deliberate user pick is active and must be honored.
    if M.state.userExplicitOutput then
        local pick = M.state.userExplicitOutput
        if currentName == pick then
            return -- your pick is active, nothing to do
        end

        local pickDevice = M.findOutputDeviceExact(pick)
        if pickDevice then
            -- Your pick is connected but output moved away from it.
            if hardwareChange then
                -- macOS hijacked output on a fresh connect -> restore your pick.
                M.setOutput(pickDevice, pickDevice:name() .. " (restored)")
            else
                -- Deliberate Control Center change -> accept it as the new pick.
                M.state.userExplicitOutput = currentName
            end
        else
            -- Your pick disappeared -> ride the best fallback, keep intent so it
            -- restores automatically when your device returns.
            local best, label = M.selectHighestPriorityOutput()
            if best and best:name() ~= currentName then
                M.setOutput(best, label .. " (fallback)")
            end
        end
        return
    end

    -- AUTO state: follow priority.
    local best, label = M.selectHighestPriorityOutput()
    if not best or best:name() == currentName then
        return -- already on the best available device
    end

    if hardwareChange then
        -- A device connected/disconnected -> follow priority.
        M.setOutput(best, label)
    else
        -- Deliberate Control Center change with no hardware event -> respect it.
        M.state.userExplicitOutput = currentName
    end
end

-- Debounced audio device change handler
function M.handleAudioDeviceChange(event)
    if not M.state.active then return end
    if M.state.paused then return end

    -- A device add/remove is never our own switch's self-event (our switch fires a default-change
    -- "dOut", not "dev#"). Always record it so a hijack arriving inside the self-suppression
    -- window still flags the next evaluation as a hardware change.
    if event == "dev#" then
        M.state.pendingHardwareChange = true
    end

    -- Input handling is independent of output-switch suppression; skip only our own input switch.
    if not M.state.inputSwitchInProgress then
        M.scheduleInputCheck()
    end

    -- Suppress only the default-change self-event our own OUTPUT switch triggers — never a dev#.
    if M.state.switchInProgress and event ~= "dev#" then return end

    -- Debounce the output evaluation
    if M.state.pendingDeviceCheck then
        M.state.pendingDeviceCheck:stop()
    end

    local delay = M.config.debounceDelay
    -- Longer grace period for Bluetooth disconnects (profile switching)
    if event == "dev#" then
        local currentOutput = hs.audiodevice.defaultOutputDevice()
        if currentOutput and M.isBluetoothDevice(currentOutput:name()) then
            delay = M.config.bluetoothGracePeriod
        end
    end

    M.state.pendingDeviceCheck = hs.timer.doAfter(delay, function()
        M.state.pendingDeviceCheck = nil
        M.evaluateOutputState()
    end)
end

-- Lifecycle: called by usb-device-manager when Wave:3 connects
function M.init()
    if M.state.active then return end
    M.state.active = true

    -- Config layering: literal defaults (above) -> Hammerspoon-local overrides -> shared JSON.
    -- The shared config is loaded LAST so it owns the keys it defines (inputGuard, outputPriority)
    -- and a local override can no longer silently clobber the guarded-input device.
    local configModule = package.loaded["modules.config"]
    if configModule and configModule.audio then
        for key, value in pairs(configModule.audio) do
            M.config[key] = value
        end
    end

    -- Load shared config (Raycast audio-manager config.json) last so inputGuard wins.
    M.loadSharedConfig()

    -- Transient flags always reset on (re)init.
    M.state.pendingHardwareChange = false
    M.state.switchInProgress = false
    M.state.inputSwitchInProgress = false

    -- Arbitration only when NOT paused: a redock must not switch anything if the user paused the
    -- daemon (paused survives redock by design). While paused we leave the current output/input and
    -- the existing picks untouched; resume() re-establishes the baseline from whatever is current.
    if not M.state.paused then
        -- Fresh dock = AUTO output, strict Wave:3 input, no explicit picks yet.
        M.state.userExplicitOutput = nil
        M.state.userExplicitInput = nil
        -- Settle input onto Wave:3 immediately.
        M.evaluateInputState()
        -- Settle output onto the best available device (AUTO state).
        local best, label = M.selectHighestPriorityOutput()
        local currentOutput = hs.audiodevice.defaultOutputDevice()
        if best and (not currentOutput or best:name() ~= currentOutput:name()) then
            M.setOutput(best, label)
        end
    end

    -- Capture the current input gain as the mute-restore baseline (data only; safe while paused).
    local inputDevice = hs.audiodevice.defaultInputDevice()
    if inputDevice then
        local gain = inputDevice:inputVolume()
        if gain and gain > 0 then
            M.state.preMuteInputVolume = gain
        end
    end

    -- Start audio device watcher
    hs.audiodevice.watcher.setCallback(function(event)
        M.handleAudioDeviceChange(event)
    end)
    hs.audiodevice.watcher.start()

    -- Watch the shared config for live edits so Raycast priority/inputGuard changes take effect
    -- without a redock. Watch the resolved real directory (writes via the symlink land there).
    local configDir = M.resolveConfigDir()
    if configDir then
        -- React to any change in the config directory (debounced). A per-file path filter was
        -- considered but FSEvents can coalesce a burst into a directory-granularity event with no
        -- per-file path, which a filter would silently drop (stale config); a redundant reload on an
        -- unrelated write (e.g. an editor's temp file) is cheap by comparison.
        M.state.configWatcher = hs.pathwatcher.new(configDir, function()
            M.handleConfigChange()
        end)
        M.state.configWatcher:start()
    end
end

-- Lifecycle: called by usb-device-manager when Wave:3 disconnects
function M.stop()
    if not M.state.active then return end
    M.state.active = false

    hs.audiodevice.watcher.stop()

    if M.state.pendingDeviceCheck then
        M.state.pendingDeviceCheck:stop()
        M.state.pendingDeviceCheck = nil
    end
    if M.state.pendingInputCheck then
        M.state.pendingInputCheck:stop()
        M.state.pendingInputCheck = nil
    end
    if M.state.pendingConfigReload then
        M.state.pendingConfigReload:stop()
        M.state.pendingConfigReload = nil
    end
    if M.state.configWatcher then
        M.state.configWatcher:stop()
        M.state.configWatcher = nil
    end

    M.state.pendingHardwareChange = false
    M.state.switchInProgress = false
    M.state.inputSwitchInProgress = false
end

return M
