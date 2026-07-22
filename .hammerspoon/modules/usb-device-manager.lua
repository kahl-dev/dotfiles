-- USB Device Manager Module
-- Watches USB devices and starts/stops the audio-manager with the Wave:3.

local M = {}

-- Module state
M.state = {
    deviceStates = {}
}

-- Configuration (loaded from config module)
M.config = {
    devices = {},
    settings = {
        debounce_delay = 2.0
    }
}

-- Check if a USB device is connected
function M.isDeviceConnected(deviceConfig)
    local devices = hs.usb.attachedDevices()

    for _, device in ipairs(devices) do
        if device.vendorID == deviceConfig.vendor_id then
            for _, pid in ipairs(deviceConfig.product_ids) do
                if device.productID == pid then
                    return true
                end
            end
        end
    end

    return false
end

-- Handle device connection
function M.handleDeviceConnection(deviceKey, deviceConfig)
    M.state.deviceStates[deviceKey] = true

    if deviceConfig.coordinate_audio then
        local audioManager = package.loaded["modules.audio-manager"]
        if audioManager then
            audioManager.init()
        end
    end
end

-- Handle device disconnection
function M.handleDeviceDisconnection(deviceKey, deviceConfig)
    M.state.deviceStates[deviceKey] = false

    if deviceConfig.coordinate_audio then
        local audioManager = package.loaded["modules.audio-manager"]
        if audioManager then
            audioManager.stop()
        end
    end
end

-- Check all devices
local pendingCheck = nil
function M.checkAllDevices()
    for deviceKey, deviceConfig in pairs(M.config.devices) do
        local wasConnected = M.state.deviceStates[deviceKey] or false
        local isConnected = M.isDeviceConnected(deviceConfig)

        if isConnected and not wasConnected then
            M.handleDeviceConnection(deviceKey, deviceConfig)
        elseif not isConnected and wasConnected then
            M.handleDeviceDisconnection(deviceKey, deviceConfig)
        end
    end
end

-- USB watcher callback with debouncing
function M.usbCallback(_)
    if pendingCheck then
        pendingCheck:stop()
        pendingCheck = nil
    end

    pendingCheck = hs.timer.doAfter(M.config.settings.debounce_delay, function()
        M.checkAllDevices()
        pendingCheck = nil
    end)
end

-- Initialize module
function M.init()
    -- Load configuration
    local configModule = package.loaded["modules.config"]
    if configModule then
        M.config = configModule.usb or M.config
    end

    -- Initial device check
    M.checkAllDevices()

    -- Start USB watcher
    M.usbWatcher = hs.usb.watcher.new(M.usbCallback)
    M.usbWatcher:start()
end

return M
