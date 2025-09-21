-- Audio Device Manager Module
-- Automatically switches to Elgato microphone when needed

local M = {}

-- Configuration
M.config = {
    elgatoInputName = "Wave:3",
    airpodsPattern = "AirPods",
    switchDelay = 0.5
}

-- Find and set Elgato as input device
function M.setElgatoAsInput()
    local elgatoDevice = nil

    -- Find Elgato device
    for _, device in ipairs(hs.audiodevice.allInputDevices()) do
        if string.find(device:name(), M.config.elgatoInputName) then
            elgatoDevice = device
            break
        end
    end

    -- Set Elgato as default input if found
    if elgatoDevice then
        elgatoDevice:setDefaultInputDevice()
        return true
    end

    return false
end

-- Check if AirPods connected and handle input switching
function M.handleAudioDeviceChange()
    local currentInput = hs.audiodevice.defaultInputDevice()

    if currentInput then
        -- Check if current input is AirPods
        if string.find(currentInput:name(), M.config.airpodsPattern) then
            -- Switch back to Elgato after a short delay
            hs.timer.doAfter(M.config.switchDelay, function()
                M.setElgatoAsInput()
            end)
        end
    end
end

-- Handle Wave device connection
function M.onWaveDeviceConnected()
    -- Wait for Wave Link to initialize
    hs.timer.doAfter(2.0, function()
        M.setElgatoAsInput()
    end)
end

-- Initialize the module
function M.init()
    -- Load configuration if available
    local configModule = package.loaded["modules.config"]
    if configModule and configModule.audio then
        for key, value in pairs(configModule.audio) do
            M.config[key] = value
        end
    end

    -- Set up audio device watcher
    hs.audiodevice.watcher.setCallback(function(event)
        if event == "dIn " then  -- Default input device changed
            M.handleAudioDeviceChange()
        elseif event == "dev#" then  -- Number of devices changed
            hs.timer.doAfter(1.0, function()
                M.handleAudioDeviceChange()
            end)
        end
    end)

    -- Start the watcher
    hs.audiodevice.watcher.start()
end

-- Stop the module
function M.stop()
    hs.audiodevice.watcher.stop()
end

return M