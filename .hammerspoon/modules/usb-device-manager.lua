-- USB Device Manager Module
-- Automatically manages applications based on USB device connections

local M = {}

-- Module state
M.state = {
    managedApps = {},
    deviceStates = {},
    manuallyQuit = {},
    userShowedApp = {},
    appWatchers = {}
}

-- Configuration (loaded from config module)
M.config = {
    devices = {},
    settings = {
        launch_delay = 2.0,
        hide_delay = 2.0,
        notifications = false,
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

-- Hide an app reliably
function M.hideApp(app)
    if not app then return end

    -- Try standard hide
    app:hide()

    -- Minimize windows as backup
    local windows = app:allWindows()
    for _, window in ipairs(windows) do
        window:minimize()
    end

    -- Special handling for stubborn apps
    local bundleId = app:bundleID()
    if bundleId == "com.elgato.WaveLink" then
        hs.osascript.applescript([[
            tell application "System Events"
                set visible of process "WaveLink" to false
            end tell
        ]])
    end
end

-- Launch an application
function M.launchApp(bundleId, appName, deviceConfig)
    -- Check if already running
    local app = hs.application.get(bundleId)
    if app and app:isRunning() then
        if deviceConfig.launch_hidden and not M.state.userShowedApp[bundleId] then
            M.hideApp(app)
        end
        return true
    end

    -- Check if user manually quit
    if M.state.manuallyQuit[bundleId] then
        return false
    end

    -- Launch the app
    local success = hs.application.launchOrFocusByBundleID(bundleId)

    if success then
        M.state.managedApps[bundleId] = true

        -- Hide if configured
        if deviceConfig.launch_hidden then
            local hideDelay = bundleId == "com.elgato.WaveLink" and 3.0 or M.config.settings.hide_delay

            hs.timer.doAfter(hideDelay, function()
                local launchedApp = hs.application.get(bundleId)
                if launchedApp and not M.state.userShowedApp[bundleId] then
                    M.hideApp(launchedApp)

                    -- One more attempt for Wave Link
                    if bundleId == "com.elgato.WaveLink" then
                        hs.timer.doAfter(2.0, function()
                            local waveApp = hs.application.get(bundleId)
                            if waveApp and not M.state.userShowedApp[bundleId] then
                                M.hideApp(waveApp)
                            end
                        end)
                    end
                end
            end)
        end

        -- Monitor for manual quits
        M.setupAppWatcher(bundleId, appName)
    end

    return success
end

-- Quit an application
function M.quitApp(bundleId, appName)
    local app = hs.application.get(bundleId)

    if not app or not app:isRunning() then
        return true
    end

    -- Only quit if we're managing it
    if not M.state.managedApps[bundleId] then
        return false
    end

    app:kill()
    M.state.managedApps[bundleId] = nil
    M.state.manuallyQuit[bundleId] = nil

    return true
end

-- Monitor app for manual quits
function M.setupAppWatcher(bundleId, appName)
    -- Reuse existing watcher when rebuilding state
    if M.state.appWatchers[bundleId] then
        M.state.appWatchers[bundleId]:stop()
        M.state.appWatchers[bundleId] = nil
    end

    local watcher = hs.application.watcher.new(function(name, event, app)
        local matchesManagedApp = false

        if app and app:bundleID() == bundleId then
            matchesManagedApp = true
        elseif not app and appName and name == appName then
            matchesManagedApp = true
        end

        if matchesManagedApp then
            if event == hs.application.watcher.terminated then
                -- Check if device is still connected
                for deviceKey, deviceConfig in pairs(M.config.devices) do
                    if deviceConfig.app_bundle_id == bundleId then
                        if M.isDeviceConnected(deviceConfig) and M.state.managedApps[bundleId] then
                            -- User manually quit while device connected
                            M.state.manuallyQuit[bundleId] = true
                            M.state.managedApps[bundleId] = nil
                        end
                        break
                    end
                end
            end
        end
    end)

    watcher:start()
    M.state.appWatchers[bundleId] = watcher
end

-- Handle device connection
function M.handleDeviceConnection(deviceKey, deviceConfig)
    M.state.deviceStates[deviceKey] = true
    M.state.manuallyQuit[deviceConfig.app_bundle_id] = nil

    -- Special handling for Wave Link audio
    if deviceKey == "wave_link" and deviceConfig.coordinate_audio then
        local audioManager = package.loaded["modules.audio-manager"]
        if audioManager and audioManager.onWaveDeviceConnected then
            audioManager.onWaveDeviceConnected()
        end
    end

    -- Launch app after delay
    hs.timer.doAfter(M.config.settings.launch_delay, function()
        if M.isDeviceConnected(deviceConfig) then
            M.launchApp(deviceConfig.app_bundle_id, deviceConfig.app_name, deviceConfig)
        end
    end)
end

-- Handle device disconnection
function M.handleDeviceDisconnection(deviceKey, deviceConfig)
    M.state.deviceStates[deviceKey] = false

    -- Quit app after short delay
    hs.timer.doAfter(1.0, function()
        if not M.isDeviceConnected(deviceConfig) then
            M.quitApp(deviceConfig.app_bundle_id, deviceConfig.app_name)
        end
    end)
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
function M.usbCallback(device)
    -- Cancel pending check
    if pendingCheck then
        pendingCheck:stop()
        pendingCheck = nil
    end

    -- Schedule new check after debounce delay
    pendingCheck = hs.timer.doAfter(M.config.settings.debounce_delay, function()
        M.checkAllDevices()
        pendingCheck = nil
    end)
end

-- Toggle visibility of managed apps
function M.toggleManagedApps()
    for bundleId, _ in pairs(M.state.managedApps) do
        local app = hs.application.get(bundleId)
        if app then
            local windows = app:visibleWindows()
            if #windows == 0 then
                -- Show the app
                app:unhide()
                app:activate()
                M.state.userShowedApp[bundleId] = true
            else
                -- Hide the app
                M.hideApp(app)
                M.state.userShowedApp[bundleId] = nil
            end
        end
    end
end

-- Check for orphaned apps (running without USB device connected)
function M.checkForOrphanedApps()
    for deviceKey, deviceConfig in pairs(M.config.devices) do
        local app = hs.application.get(deviceConfig.app_bundle_id)

        if app and app:isRunning() then
            -- App is running, check if device is connected
            if not M.isDeviceConnected(deviceConfig) then
                -- App is running but device not connected - force quit it
                app:kill()
                M.state.manuallyQuit[deviceConfig.app_bundle_id] = true
                M.state.managedApps[deviceConfig.app_bundle_id] = nil
            end
        end
    end
end

-- Initialize module
function M.init()
    -- Load configuration
    local configModule = package.loaded["modules.config"]
    if configModule then
        M.config = configModule.usb or M.config
    end

    -- Check for orphaned apps first (before device check)
    M.checkForOrphanedApps()

    -- Initial device check
    M.checkAllDevices()

    -- Start USB watcher
    M.usbWatcher = hs.usb.watcher.new(M.usbCallback)
    M.usbWatcher:start()

    -- Single essential hotkey for visibility toggle
    hs.hotkey.bind({ "cmd", "alt" }, "V", function()
        M.toggleManagedApps()
    end)
end

-- Stop module
function M.stop()
    if M.usbWatcher then
        M.usbWatcher:stop()
        M.usbWatcher = nil
    end

    for bundleId, watcher in pairs(M.state.appWatchers) do
        watcher:stop()
        M.state.appWatchers[bundleId] = nil
    end
end

return M
