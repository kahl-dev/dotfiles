-- Audio Device Manager Module
-- Input always stays on Wave:3 (desk mic)
-- Prevents AirPods from auto-hijacking output on connect
-- Primary audio switching via Wave Link Stream Deck plugin (Row 1)
-- Emergency fallback switching via Hammerspoon .app bundles (Row 2)
-- Volume key interception: only when Wave Link active (macOS output = Wave:3),
--   auto-detects which monitor device is receiving audio

local M = {}

-- Configuration
M.config = {
    elgatoDeviceName = "Wave:3",
    edifierName = "EDIFIER M60",
    airpodsPattern = "AirPods",
    switchDelay = 0.5,
    volumeStep = 6.25, -- 16 steps from 0-100 (matches macOS 16-segment OSD)
}

-- State
M.volumeTap = nil

-- Find an output device by name pattern
function M.findOutputDevice(pattern)
    for _, device in ipairs(hs.audiodevice.allOutputDevices()) do
        if string.find(device:name(), pattern) then
            return device
        end
    end
    return nil
end

-- Find Wave:3 input device
function M.findWaveInput()
    for _, device in ipairs(hs.audiodevice.allInputDevices()) do
        if string.find(device:name(), M.config.elgatoDeviceName) then
            return device
        end
    end
    return nil
end

-- Ensure input is always Wave:3
function M.guardInput()
    local waveInput = M.findWaveInput()
    if waveInput then
        local current = hs.audiodevice.defaultInputDevice()
        if not current or not string.find(current:name(), M.config.elgatoDeviceName) then
            waveInput:setDefaultInputDevice()
        end
    end
end

-- Show audio switch feedback on screen
function M.showFeedback(label)
    hs.alert.closeAll()
    hs.alert.show(label, 1.5)
end

-- Show volume bar feedback
function M.showVolumeFeedback(vol, deviceName)
    hs.alert.closeAll()
    local bars = math.floor(vol / 6.25)
    local display = string.rep("█", bars) .. string.rep("░", 16 - bars)
    hs.alert.show(string.format("🔊 %s\n%s %d%%", deviceName, display, math.floor(vol)), 1)
end

-- Detect which external device is currently receiving audio from Wave Link
-- Checks inUse() on physical output devices (USB, Bluetooth)
-- Excludes: Wave:3, built-in speakers, virtual devices, DisplayPort monitors
function M.detectActiveMonitorDevice()
    local validTransport = { USB = true, Bluetooth = true }
    for _, device in ipairs(hs.audiodevice.allOutputDevices()) do
        local name = device:name()
        local transport = device:transportType()
        if validTransport[transport]
           and not string.find(name, M.config.elgatoDeviceName)
           and device:inUse() then
            return device
        end
    end
    -- No external monitor device found — fall back to Wave:3 output
    -- (headphones plugged into Wave:3 headphone jack)
    return M.findOutputDevice(M.config.elgatoDeviceName)
end

-- === Volume Control ===

function M.volumeUp()
    local device = M.detectActiveMonitorDevice()
    if not device then
        M.showFeedback("No active monitor device")
        return false
    end
    local vol = device:volume()
    if vol == nil then
        M.showFeedback("Volume not supported: " .. device:name())
        return false
    end
    local newVol = math.min(100, vol + M.config.volumeStep)
    device:setVolume(newVol)
    M.showVolumeFeedback(newVol, device:name())
    return true
end

function M.volumeDown()
    local device = M.detectActiveMonitorDevice()
    if not device then
        M.showFeedback("No active monitor device")
        return false
    end
    local vol = device:volume()
    if vol == nil then
        M.showFeedback("Volume not supported: " .. device:name())
        return false
    end
    local newVol = math.max(0, vol - M.config.volumeStep)
    device:setVolume(newVol)
    M.showVolumeFeedback(newVol, device:name())
    return true
end

function M.volumeToggleMute()
    local device = M.detectActiveMonitorDevice()
    if not device then return false end
    local muted = device:muted()
    if muted == nil then return false end
    device:setMuted(not muted)
    if not muted then
        M.showFeedback("🔇 Muted: " .. device:name())
    else
        M.showFeedback("🔊 Unmuted: " .. device:name())
    end
    return true
end

-- === Emergency Fallback Switches (Row 2) ===

function M.switchToEdifier()
    local device = M.findOutputDevice(M.config.edifierName)
    if device then
        device:setDefaultOutputDevice()
        M.guardInput()
        M.showFeedback("Edifier M60")
        return true
    end
    M.showFeedback("Edifier not found")
    return false
end

function M.switchToAirPods()
    local device = M.findOutputDevice(M.config.airpodsPattern)
    if device then
        device:setDefaultOutputDevice()
        M.guardInput()
        M.showFeedback("AirPods Pro")
        return true
    end
    M.showFeedback("AirPods not found")
    return false
end

function M.switchToWaveLink()
    local device = M.findOutputDevice(M.config.elgatoDeviceName)
    if device then
        device:setDefaultOutputDevice()
        M.guardInput()
        M.showFeedback("Wave Link")
        return true
    end
    M.showFeedback("Wave:3 not found")
    return false
end

-- === Volume Key Interception ===

function M.setupVolumeInterceptor()
    M.volumeTap = hs.eventtap.new({hs.eventtap.event.types.systemDefined}, function(event)
        local data = event:systemKey()
        if not data then return false end
        if not data.down then return false end

        local key = data.key
        if key ~= "SOUND_UP" and key ~= "SOUND_DOWN" and key ~= "MUTE" then
            return false
        end

        -- Only intercept when Wave:3 is macOS system output (= Wave Link is active)
        -- When output is AirPods, Edifier, or anything else: let macOS handle natively
        local currentOutput = hs.audiodevice.defaultOutputDevice()
        if not currentOutput then return false end
        if not string.find(currentOutput:name(), M.config.elgatoDeviceName) then
            return false
        end

        -- Wave:3 is system output → Wave Link is routing audio
        -- Detect which external device is actually receiving audio
        if key == "SOUND_UP" then
            M.volumeUp()
        elseif key == "SOUND_DOWN" then
            M.volumeDown()
        elseif key == "MUTE" then
            M.volumeToggleMute()
        end

        return true
    end)
    M.volumeTap:start()
end

-- === Audio Device Change Handler ===

-- "dOut"/"dIn " = output/input changed -> only guard input
-- "dev#" = device count changed (connected/disconnected) -> prevent hijack + fallback on disconnect
function M.handleAudioDeviceChange(event)
    M.guardInput()

    if event == "dev#" then
        hs.timer.doAfter(1.0, function()
            local currentOutput = hs.audiodevice.defaultOutputDevice()
            if not currentOutput then return end

            -- Case 1: AirPods connected and hijacked macOS output → restore to Wave:3
            if string.find(currentOutput:name(), M.config.airpodsPattern) then
                local wave = M.findOutputDevice(M.config.elgatoDeviceName)
                if wave then
                    wave:setDefaultOutputDevice()
                    M.showFeedback("Wave:3 (auto-restored)")
                end
                return
            end

            -- Case 2: In Wave Link mode but monitor device disconnected
            -- (e.g. AirPods put in case, Edifier USB dropout)
            -- Bypass Wave Link entirely — set macOS output directly to fallback device
            if string.find(currentOutput:name(), M.config.elgatoDeviceName) then
                local monitor = M.detectActiveMonitorDevice()
                if not monitor then
                    local fallback = M.findOutputDevice(M.config.edifierName)
                        or M.findOutputDevice(M.config.airpodsPattern)
                    if fallback then
                        -- Set macOS output to fallback directly (bypasses Wave Link)
                        fallback:setDefaultOutputDevice()
                        M.guardInput()
                        M.showFeedback("🔊 " .. fallback:name() .. " (direct — monitor lost)")
                    end
                end
            end
        end)
    end
end

-- === Lifecycle ===

function M.init()
    local configModule = package.loaded["modules.config"]
    if configModule and configModule.audio then
        for key, value in pairs(configModule.audio) do
            M.config[key] = value
        end
    end

    hs.audiodevice.watcher.setCallback(function(event)
        M.handleAudioDeviceChange(event)
    end)
    hs.audiodevice.watcher.start()

    M.setupVolumeInterceptor()

    M.guardInput()
end

function M.stop()
    hs.audiodevice.watcher.stop()
    if M.volumeTap then
        M.volumeTap:stop()
        M.volumeTap = nil
    end
end

return M
