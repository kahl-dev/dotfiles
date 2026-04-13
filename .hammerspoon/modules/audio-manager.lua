-- Audio Device Manager Module
-- Direct macOS output switching (no Wave Link in signal path)
-- Input always guarded on Wave:3 when docked
-- Only active when Wave:3 is USB-connected (managed by usb-device-manager)
-- Priority list read from ~/.config/audio-manager/config.json (shared with Raycast)

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
    lastExplicitOutput = nil,
    pendingDeviceCheck = nil,
    edifierDroppedAt = nil,
}

-- Find an output device by name (plain string match, not Lua pattern)
function M.findOutputDevice(name)
    for _, device in ipairs(hs.audiodevice.allOutputDevices()) do
        if string.find(device:name(), name, 1, true) then
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

-- Ensure input is always Wave:3
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

-- Select highest priority available output device
function M.selectHighestPriorityOutput()
    for _, entry in ipairs(M.config.outputPriority) do
        local device = M.findOutputDevice(entry.pattern)
        if device then
            return device, entry.label
        end
    end
    -- Implicit last fallback: MacBook Speakers
    return M.findOutputDevice(M.config.macbookPattern)
        or M.findOutputDevice(M.config.builtInPattern),
        "MacBook Speakers"
end

-- Check if a device name matches a Bluetooth pattern
function M.isBluetoothDevice(deviceName)
    return string.find(deviceName, M.config.sonyPattern)
        or string.find(deviceName, M.config.airpodsPattern)
end

-- Switch to a specific device by pattern (called by Stream Deck / hotkeys)
function M.switchToDevice(pattern)
    if not M.state.active then return false end
    local device = M.findOutputDevice(pattern)
    if device then
        local success = device:setDefaultOutputDevice()
        if success then
            M.state.lastExplicitOutput = device:name()
            M.guardInput()
            M.showFeedback(device:name())
            return true
        end
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

-- Evaluate current output state and fix if needed
function M.evaluateOutputState()
    if not M.state.active then return end
    M.guardInput()

    local currentOutput = hs.audiodevice.defaultOutputDevice()
    if not currentOutput then
        -- No output at all — emergency fallback
        local fallback, label = M.selectHighestPriorityOutput()
        if fallback then
            fallback:setDefaultOutputDevice()
            M.state.lastExplicitOutput = fallback:name()
            M.showFeedback(label .. " (fallback)")
        end
        return
    end

    local currentName = currentOutput:name()

    -- AirPods hijack detection: macOS auto-switched to AirPods on connect
    -- but user didn't explicitly choose them
    if string.find(currentName, M.config.airpodsPattern)
       and M.state.lastExplicitOutput
       and not string.find(M.state.lastExplicitOutput, M.config.airpodsPattern) then
        local restore = M.findOutputDevice(M.state.lastExplicitOutput)
        if restore then
            restore:setDefaultOutputDevice()
            M.showFeedback(restore:name() .. " (auto-restored)")
            return
        end
    end

    -- macOS fell back to Built-in Speakers but better device available
    -- Only promote if user didn't explicitly choose MacBook
    local explicitlyChoseMacBook = M.state.lastExplicitOutput
        and (string.find(M.state.lastExplicitOutput, M.config.macbookPattern)
             or string.find(M.state.lastExplicitOutput, M.config.builtInPattern))

    if not explicitlyChoseMacBook
       and (string.find(currentName, M.config.macbookPattern)
            or string.find(currentName, M.config.builtInPattern)) then
        local better, label = M.selectHighestPriorityOutput()
        if better and better:name() ~= currentName then
            better:setDefaultOutputDevice()
            M.state.lastExplicitOutput = better:name()
            M.showFeedback(label .. " (promoted)")
            return
        end
    end

    -- Check if current output device still exists in device list
    local stillExists = false
    for _, device in ipairs(hs.audiodevice.allOutputDevices()) do
        if device:uid() == currentOutput:uid() then
            stillExists = true
            break
        end
    end

    if not stillExists then
        -- Device disappeared — use fallback chain
        local fallback, label = M.selectHighestPriorityOutput()
        if fallback then
            fallback:setDefaultOutputDevice()
            M.state.lastExplicitOutput = fallback:name()
            M.showFeedback(label .. " (fallback)")
        end
    end
end

-- Debounced audio device change handler
function M.handleAudioDeviceChange(event)
    if not M.state.active then return end

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

    -- Merge Hammerspoon-local config overrides (if any)
    local configModule = package.loaded["modules.config"]
    if configModule and configModule.audio then
        for key, value in pairs(configModule.audio) do
            M.config[key] = value
        end
    end

    -- Guard input immediately
    M.guardInput()

    -- Record current output as explicit choice
    local currentOutput = hs.audiodevice.defaultOutputDevice()
    if currentOutput then
        M.state.lastExplicitOutput = currentOutput:name()
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
end

return M
