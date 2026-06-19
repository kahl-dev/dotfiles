-- Audio Device Manager Module
-- Direct macOS output switching (no Wave Link in signal path)
-- Output = two-state machine: AUTO follows priority; a user pick (Raycast/Stream Deck) is sacred.
-- Input still guarded on Wave:3 when docked (reworked in Phase 2).
-- Only active when Wave:3 is USB-connected (managed by usb-device-manager)
-- Priority list read from ~/.config/audio-manager/config.json (shared with Raycast)
--
-- Intent channel: Raycast switches CoreAudio directly, then pushes the choice here via
-- `hs -c "require('modules.audio-manager').noteExplicit('output', '<name>')"`. That lets the
-- daemon tell a deliberate pick apart from a macOS auto-hijack instead of reverting the user.

local M = {}

local SHARED_CONFIG_PATH = os.getenv("HOME") .. "/.config/audio-manager/config.json"

-- Default configuration (used when shared config is missing or invalid)
M.config = {
    wave3Name = "Wave:3",
    edifierName = "EDIFIER M60",
    airpodsPattern = "AirPods",
    sonyPattern = "WH%-1000XM6",
    macbookPattern = "MacBook",
    builtInPattern = "Built%-in",
    outputPriority = {
        { pattern = "WH%-1000XM6", label = "Sony XM6" },
        { pattern = "AirPods",     label = "AirPods" },
        { pattern = "EDIFIER M60", label = "Edifier M60" },
        { pattern = "Wave:3",      label = "Wave:3 Kopfhörer" },
    },
    debounceDelay = 0.5,
    bluetoothGracePeriod = 3.0,
    edifierReconnectCooldown = 5.0,
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

    -- Build priority list from config devices (sorted by priority)
    local devices = {}
    for _, device in ipairs(config.devices) do
        if not device.hidden then
            table.insert(devices, {
                pattern = device.name,
                label = device.label or device.name,
                priority = device.priority or 999,
            })
        end
    end

    table.sort(devices, function(a, b) return a.priority < b.priority end)

    local priorityList = {}
    for _, device in ipairs(devices) do
        -- Skip MacBook (implicit last fallback)
        if not string.find(device.pattern, "MacBook", 1, true) then
            table.insert(priorityList, { pattern = device.pattern, label = device.label })
        end
    end

    if #priorityList > 0 then
        M.config.outputPriority = priorityList
    end

    -- Read inputGuard
    if config.inputGuard then
        M.config.wave3Name = config.inputGuard
    end

    return true
end

-- State
M.state = {
    active = false,
    -- Device NAME the user explicitly chose (Raycast/Stream Deck). nil = AUTO state.
    userExplicitOutput = nil,
    -- Reserved for Phase 2 (input intent).
    userExplicitInput = nil,
    -- True while the daemon performs its own switch, to ignore the resulting watcher event.
    switchInProgress = false,
    -- Set on a "dev#" (device add/remove) event, consumed at the next evaluation. Coarse by
    -- design: it says *something* changed in the burst, not which device — overlapping events in
    -- one debounce window collapse into this single flag. A transition-capture event model
    -- (old -> new default per event) would be more robust; tracked for a later phase.
    pendingHardwareChange = false,
    pendingDeviceCheck = nil,
    edifierDroppedAt = nil,
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

-- Ensure input is always Wave:3 (Phase 2 makes this intent-aware)
function M.guardInput()
    local waveInput = M.findWaveInput()
    if not waveInput then return end
    local current = hs.audiodevice.defaultInputDevice()
    if not current or not string.find(current:name(), M.config.wave3Name, 1, true) then
        waveInput:setDefaultInputDevice()
    end
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

-- Check if a device name matches a Bluetooth pattern (Phase 5 makes this config-driven)
function M.isBluetoothDevice(deviceName)
    return string.find(deviceName, M.config.sonyPattern)
        or string.find(deviceName, M.config.airpodsPattern)
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

-- Switch to a specific device by pattern (Stream Deck / hotkeys / .app bundles).
-- This is an explicit user action, so it sets userExplicitOutput.
function M.switchToDevice(pattern)
    if not M.state.active then return false end
    local device = M.findOutputDevice(pattern)
    if device then
        M.noteExplicit("output", device:name())
        local ok = M.setOutput(device, device:name())
        M.guardInput()
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
    M.guardInput()

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

    -- A device add/remove is never our own switch's self-event (our switch fires a default-change
    -- "dOut", not "dev#"). Always record it so a hijack arriving inside the self-suppression
    -- window still flags the next evaluation as a hardware change.
    if event == "dev#" then
        M.state.pendingHardwareChange = true
    end

    -- Suppress only the default-change self-event our own switch triggers — never a real dev#.
    if M.state.switchInProgress and event ~= "dev#" then return end

    -- Always guard input immediately (no debounce needed)
    M.guardInput()

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

    -- Load shared config (Raycast audio-manager config.json)
    M.loadSharedConfig()

    -- Merge Hammerspoon-local config overrides (if any).
    -- NOTE: this currently clobbers inputGuard from the shared config — fixed in Phase 3.
    local configModule = package.loaded["modules.config"]
    if configModule and configModule.audio then
        for key, value in pairs(configModule.audio) do
            M.config[key] = value
        end
    end

    -- Fresh dock = AUTO state, no explicit pick yet.
    M.state.userExplicitOutput = nil
    M.state.pendingHardwareChange = false
    M.state.switchInProgress = false

    -- Guard input immediately
    M.guardInput()

    -- On dock, settle output onto the best available device (AUTO state).
    local best, label = M.selectHighestPriorityOutput()
    local currentOutput = hs.audiodevice.defaultOutputDevice()
    if best and (not currentOutput or best:name() ~= currentOutput:name()) then
        M.setOutput(best, label)
    end

    -- Start audio device watcher
    hs.audiodevice.watcher.setCallback(function(event)
        M.handleAudioDeviceChange(event)
    end)
    hs.audiodevice.watcher.start()
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

    M.state.pendingHardwareChange = false
    M.state.switchInProgress = false
end

return M
