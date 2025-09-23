-- Display Manager Module
-- Automatically manages desk setup power based on display connections and lock/unlock state

local M = {}

-- Module state
M.state = {
    displayStates = {},
    macbookLocked = false,
    pendingActions = {},
    currentDesktopUUID = nil,
    debugMode = false,
    callActive = false,
    microphoneInUse = false
}

-- Configuration (loaded from config module)
M.config = {
    displays = {},
    macbook_display_uuid = nil,
    settings = {
        debug_notifications = false,
        retry_attempts = 3,
        retry_delay = 2.0
    }
}

-- Debug logging
function M.log(message, level)
    level = level or "info"
    local timestamp = os.date("%H:%M:%S")
    local logMessage = string.format("[%s] Display Manager: %s", timestamp, message)

    print(logMessage)

    if M.config.settings.debug_notifications and M.state.debugMode then
        hs.alert.show(message, 2)
    end
end

-- Get current connected displays with UUIDs
function M.getCurrentDisplays()
    local displays = {}
    local screens = hs.screen.allScreens()

    for _, screen in ipairs(screens) do
        local uuid = screen:getUUID()
        local name = screen:name() or "Unknown"
        displays[uuid] = {
            screen = screen,
            name = name,
            frame = screen:frame()
        }
    end

    return displays
end

-- Check if MacBook is using internal display only
function M.isOnInternalDisplayOnly()
    local displays = M.getCurrentDisplays()
    local displayCount = 0
    local hasInternalDisplay = false

    for uuid, _ in pairs(displays) do
        displayCount = displayCount + 1
        if uuid == M.config.macbook_display_uuid then
            hasInternalDisplay = true
        end
    end

    return displayCount == 1 and hasInternalDisplay
end

-- Check if specific display is connected
function M.isDisplayConnected(displayUUID)
    local displays = M.getCurrentDisplays()
    return displays[displayUUID] ~= nil
end

-- Home Assistant API call
function M.callHomeAssistantAPI(entity_id, action, token, url)
    if not entity_id or not action or not token or not url then
        M.log("Missing required parameters for Home Assistant API call", "error")
        M.log(string.format("Debug: entity_id=%s, action=%s, token=%s, url=%s",
            entity_id or "nil", action or "nil",
            token and "SET" or "nil", url or "nil"))
        return false
    end

    local apiUrl = url .. "/api/services/switch/" .. action
    local headers = {
        ["Authorization"] = "Bearer " .. token,
        ["Content-Type"] = "application/json"
    }

    local body = hs.json.encode({
        entity_id = entity_id
    })

    M.log(string.format("Calling Home Assistant API: %s %s", action, entity_id))
    M.log(string.format("Debug: URL=%s, Token length=%d", url, string.len(token)))

    hs.http.asyncPost(apiUrl, body, headers, function(status, responseBody, responseHeaders)
        if status == 200 then
            M.log(string.format("Successfully %s %s", action == "turn_on" and "turned on" or "turned off", entity_id))
        else
            M.log(string.format("Home Assistant API call failed: %d - %s", status, responseBody or "Unknown error"), "error")
        end
    end)

    return true
end

-- Control Eve smart plug
function M.controlEvePlug(displayConfig, turnOn)
    local eveConfig = displayConfig.eve_plug
    if not eveConfig or not eveConfig.enabled then
        return false
    end

    local action = turnOn and "turn_on" or "turn_off"
    local actionText = turnOn and "ON" or "OFF"

    M.log(string.format("Turning %s Eve plug for %s", actionText, displayConfig.display_name or "display"))

    return M.callHomeAssistantAPI(
        eveConfig.entity_id,
        action,
        eveConfig.token,
        eveConfig.home_assistant_url
    )
end

-- Control call light
function M.controlCallLight(turnOn, privateConfig)
    if not privateConfig or not privateConfig.call_light then
        return false
    end

    local lightConfig = privateConfig.call_light
    local action = turnOn and "turn_on" or "turn_off"
    local actionText = turnOn and "ON" or "OFF"

    M.log(string.format("Turning %s call light", actionText))

    local apiUrl = privateConfig.homeassistant.url .. "/api/services/light/" .. action
    local headers = {
        ["Authorization"] = "Bearer " .. privateConfig.homeassistant.token,
        ["Content-Type"] = "application/json"
    }

    local body = {
        entity_id = lightConfig.entity_id
    }

    -- Temporarily disabled RGB color to test if it's causing the issue
    -- Add RGB color when turning on (only if the light supports it)
    -- if turnOn and lightConfig.rgb_color then
    --     -- Try different color formats that different lights might support
    --     body.rgb_color = lightConfig.rgb_color
    --     -- Some lights use this format instead:
    --     -- body.color = {r = lightConfig.rgb_color[1], g = lightConfig.rgb_color[2], b = lightConfig.rgb_color[3]}
    -- end

    local jsonBody = hs.json.encode(body)

    -- Debug logging
    M.log(string.format("API URL: %s", apiUrl))
    M.log(string.format("Request body: %s", jsonBody))

    hs.http.asyncPost(apiUrl, jsonBody, headers, function(status, responseBody, responseHeaders)
        if status == 200 then
            M.log(string.format("Successfully %s call light", actionText))
            M.log(string.format("Response: %s", responseBody or "No response body"))
        else
            M.log(string.format("Call light API call failed: %d - %s", status, responseBody or "Unknown error"), "error")
            M.log(string.format("Response headers: %s", hs.inspect(responseHeaders or {})))
        end
    end)

    return true
end

-- Cancel pending action
function M.cancelPendingAction(actionKey)
    if M.state.pendingActions[actionKey] then
        M.state.pendingActions[actionKey]:stop()
        M.state.pendingActions[actionKey] = nil
        M.log(string.format("Cancelled pending action: %s", actionKey))
    end
end

-- Schedule delayed action with cancellation
function M.scheduleAction(actionKey, delay, callback)
    -- Cancel existing action
    M.cancelPendingAction(actionKey)

    if delay <= 0 then
        -- Execute immediately
        callback()
        return
    end

    M.log(string.format("Scheduling action '%s' in %.1f seconds", actionKey, delay))

    M.state.pendingActions[actionKey] = hs.timer.doAfter(delay, function()
        M.state.pendingActions[actionKey] = nil
        callback()
    end)
end

-- Handle display connection
function M.handleDisplayConnection(displayUUID, displayConfig)
    M.log(string.format("Display connected: %s", displayConfig.display_name or displayUUID))
    M.state.displayStates[displayUUID] = true

    -- Check if power on is enabled for display connection
    local triggers = displayConfig.power_on_triggers or {}
    for _, trigger in ipairs(triggers) do
        if trigger == "display_connected" then
            local delay = displayConfig.delays and displayConfig.delays.power_on or 0.5
            M.scheduleAction("power_on_" .. displayUUID, delay, function()
                M.controlEvePlug(displayConfig, true)
            end)
            break
        end
    end
end

-- Handle display disconnection
function M.handleDisplayDisconnection(displayUUID, displayConfig)
    M.log(string.format("Display disconnected: %s", displayConfig.display_name or displayUUID))
    M.state.displayStates[displayUUID] = false

    -- Cancel any pending power on actions
    M.cancelPendingAction("power_on_" .. displayUUID)

    -- Check if power off is enabled for display disconnection
    local triggers = displayConfig.power_off_triggers or {}
    for _, trigger in ipairs(triggers) do
        if trigger == "display_disconnected" then
            local delay = displayConfig.delays and displayConfig.delays.power_off or 3.0
            M.scheduleAction("power_off_" .. displayUUID, delay, function()
                M.controlEvePlug(displayConfig, false)
            end)
            break
        end
    end
end

-- Handle MacBook lock event
function M.handleMacBookLock()
    M.log("MacBook locked")
    M.state.macbookLocked = true

    -- Check for displays that should power off when locked
    for displayUUID, displayConfig in pairs(M.config.displays) do
        if M.state.displayStates[displayUUID] then
            local triggers = displayConfig.power_off_triggers or {}
            for _, trigger in ipairs(triggers) do
                if trigger == "lock_with_display" then
                    local delay = displayConfig.delays and displayConfig.delays.lock_threshold or 5.0
                    M.scheduleAction("lock_power_off_" .. displayUUID, delay, function()
                        -- Double-check we're still locked and display is connected
                        if M.state.macbookLocked and M.isDisplayConnected(displayUUID) then
                            M.controlEvePlug(displayConfig, false)
                        end
                    end)
                    break
                end
            end
        end
    end
end

-- Handle MacBook unlock event
function M.handleMacBookUnlock()
    M.log("MacBook unlocked")
    M.state.macbookLocked = false

    -- Cancel any pending lock power-off actions
    for displayUUID, _ in pairs(M.config.displays) do
        M.cancelPendingAction("lock_power_off_" .. displayUUID)
    end

    -- Check for displays that should power on when unlocked
    for displayUUID, displayConfig in pairs(M.config.displays) do
        if M.state.displayStates[displayUUID] then
            local triggers = displayConfig.power_on_triggers or {}
            for _, trigger in ipairs(triggers) do
                if trigger == "unlock_with_display" then
                    local delay = displayConfig.delays and displayConfig.delays.power_on or 0.5
                    M.scheduleAction("unlock_power_on_" .. displayUUID, delay, function()
                        M.controlEvePlug(displayConfig, true)
                    end)
                    break
                end
            end
        end
    end
end

-- Screen watcher callback
function M.screenCallback()
    local currentDisplays = M.getCurrentDisplays()

    -- Check for new connections
    for uuid, displayInfo in pairs(currentDisplays) do
        local wasConnected = M.state.displayStates[uuid] or false
        if not wasConnected then
            -- New display connected
            local displayConfig = M.config.displays[uuid]
            if displayConfig then
                M.handleDisplayConnection(uuid, displayConfig)
            else
                M.log(string.format("Unknown display connected: %s (%s)", displayInfo.name, uuid))
            end
        end
    end

    -- Check for disconnections
    for uuid, displayConfig in pairs(M.config.displays) do
        local wasConnected = M.state.displayStates[uuid] or false
        local isConnected = currentDisplays[uuid] ~= nil

        if wasConnected and not isConnected then
            -- Display disconnected
            M.handleDisplayDisconnection(uuid, displayConfig)
        end
    end
end

-- Caffeinate watcher callback
function M.caffeineCallback(event)
    if event == hs.caffeinate.watcher.screensDidLock then
        M.handleMacBookLock()
    elseif event == hs.caffeinate.watcher.screensDidUnlock then
        M.handleMacBookUnlock()
    end
end

-- Check if microphone is actively being used for communication
function M.checkMicrophoneUsage()
    local defaultInput = hs.audiodevice.defaultInputDevice()
    if not defaultInput then return false end

    -- Check if mic is not muted
    local isMuted = defaultInput:inputMuted()
    if isMuted then return false end

    -- Check for actual input level (indicates active communication)
    local inputLevel = defaultInput:inputLevel()
    -- Only consider it "in use" if there's sustained input (not just TTS output feedback)
    return inputLevel and inputLevel > 0.1
end

-- Check if camera is in use using Hammerspoon's native camera API
function M.checkCameraUsage()
    -- Use Hammerspoon's built-in camera module (much more reliable)
    local cameras = hs.camera.allCameras()
    for _, camera in pairs(cameras) do
        if camera:isInUse() then
            return true
        end
    end
    return false
end

-- Setup camera watcher for real-time detection
function M.setupCameraWatcher()
    local function configureCameraPropertyWatchers()
        local allCameras = hs.camera.allCameras()
        M.log(string.format("Setting up camera watchers for %d cameras", #allCameras))

        for _, camera in pairs(allCameras) do
            if camera:isPropertyWatcherRunning() then
                camera:stopPropertyWatcher()
            end
            camera:setPropertyWatcherCallback(function(camera, property, scope, element)
                M.log(string.format("Camera property changed: %s, in use: %s", camera:name(), camera:isInUse()))
                -- Trigger immediate call status check
                M.monitorCallStatus()
            end)
            camera:startPropertyWatcher()
        end
    end

    -- Set up the camera watcher
    hs.camera.setWatcherCallback(configureCameraPropertyWatchers)
    hs.camera.startWatcher()
    configureCameraPropertyWatchers() -- Initial setup
end

-- Detect call applications
function M.detectCallApplications()
    local callApps = {
        "Microsoft Teams",
        "Zoom",
        "zoom.us",
        "Skype",
        "Discord",
        "Slack",
        "Google Chrome", -- For web-based calls
        "Safari",        -- For web-based calls
        "FaceTime"
    }

    for _, appName in ipairs(callApps) do
        local app = hs.application.get(appName)
        if app and app:isRunning() then
            local windows = app:visibleWindows()
            if #windows > 0 then
                M.log(string.format("Detected call app: %s (visible windows: %d)", appName, #windows))
                -- For browsers, we can't easily detect if they're in a call
                -- But we can detect if they have camera/mic access
                if appName == "Google Chrome" or appName == "Safari" then
                    -- Return true if mic is in use (indicating possible call)
                    return M.checkMicrophoneUsage()
                else
                    -- For dedicated call apps, assume they're in a call if running
                    return true
                end
            end
        end
    end

    return false
end

-- Handle call state change
function M.handleCallStateChange(callActive, privateConfig)
    if M.state.callActive == callActive then
        return -- No change
    end

    local prevState = M.state.callActive
    M.state.callActive = callActive
    local action = callActive and "started" or "ended"
    M.log(string.format("Call state changed: %s -> %s (%s)",
        prevState and "ACTIVE" or "INACTIVE",
        callActive and "ACTIVE" or "INACTIVE",
        action))

    -- Control call light
    M.controlCallLight(callActive, privateConfig)
end

-- Monitor call status
function M.monitorCallStatus()
    local configModule = package.loaded["modules.config"]
    local privateConfig = configModule and configModule.loadPrivateConfig and configModule.loadPrivateConfig()

    if not privateConfig or not privateConfig.call_light then
        return -- Call monitoring disabled
    end

    -- Simple camera-only detection (no app detection needed for Raycast camera usage)
    local cameraInUse = M.checkCameraUsage()

    -- Debug logging
    M.log(string.format("Call monitoring: Camera=%s", cameraInUse and "YES" or "NO"))

    -- Only camera detection matters
    local callDetected = cameraInUse

    M.log(string.format("Final call detection: %s", callDetected and "ACTIVE" or "INACTIVE"))

    M.handleCallStateChange(callDetected, privateConfig)
end

-- Check for sustained microphone usage (more reliable than single check)
function M.checkSustainedMicrophoneUsage()
    -- Store mic usage history to detect sustained usage
    if not M.state.micUsageHistory then
        M.state.micUsageHistory = {}
    end

    local currentUsage = M.checkMicrophoneUsage()
    table.insert(M.state.micUsageHistory, currentUsage)

    -- Keep only last 3 checks (15 seconds worth)
    if #M.state.micUsageHistory > 3 then
        table.remove(M.state.micUsageHistory, 1)
    end

    -- Require at least 2 out of 3 recent checks to show mic usage
    local usageCount = 0
    for _, usage in ipairs(M.state.micUsageHistory) do
        if usage then usageCount = usageCount + 1 end
    end

    return usageCount >= 2
end

-- Get current status for debugging
function M.getStatus()
    local displays = M.getCurrentDisplays()
    local status = {
        displays = {},
        state = M.state,
        config_displays = {}
    }

    for uuid, info in pairs(displays) do
        status.displays[uuid] = {
            name = info.name,
            connected = true,
            configured = M.config.displays[uuid] ~= nil
        }
    end

    for uuid, config in pairs(M.config.displays) do
        status.config_displays[uuid] = {
            name = config.display_name,
            eve_plug_enabled = config.eve_plug and config.eve_plug.enabled or false
        }
    end

    return status
end

-- Toggle debug mode
function M.toggleDebugMode()
    M.state.debugMode = not M.state.debugMode
    local message = M.state.debugMode and "Debug mode enabled" or "Debug mode disabled"
    M.log(message)
    hs.alert.show(message, 2)
end

-- Manual control functions for testing
function M.manualControlEvePlug(displayUUID, turnOn)
    local displayConfig = M.config.displays[displayUUID]
    if displayConfig then
        M.controlEvePlug(displayConfig, turnOn)
    else
        M.log("Display not found in configuration: " .. displayUUID, "error")
    end
end

-- Initialize display states
function M.initializeDisplayStates()
    local currentDisplays = M.getCurrentDisplays()

    for uuid, _ in pairs(currentDisplays) do
        M.state.displayStates[uuid] = true
    end

    -- Initialize lock state
    local displayIdle = hs.caffeinate.get("displayIdle")
    M.state.macbookLocked = (type(displayIdle) == "number" and displayIdle > 0) or false

    M.log(string.format("Initialized with %d displays, locked: %s",
        hs.fnutils.reduce(M.state.displayStates, function(count, _) return count + 1 end, 0),
        M.state.macbookLocked and "yes" or "no"))
end

-- Initialize module
function M.init()
    -- Load configuration
    local configModule = package.loaded["modules.config"]
    if configModule then
        M.config = hs.fnutils.copy(configModule.displays or M.config)

        -- Debug: Log configuration details
        if M.config and M.config.displays then
            for uuid, displayConfig in pairs(M.config.displays) do
                M.log(string.format("Debug: Loaded config for display %s", uuid))
                if displayConfig.eve_plug then
                    M.log(string.format("Debug: URL=%s", displayConfig.eve_plug.home_assistant_url or "nil"))
                    M.log(string.format("Debug: Token=%s", displayConfig.eve_plug.token and "SET" or "nil"))
                    M.log(string.format("Debug: Entity=%s", displayConfig.eve_plug.entity_id or "nil"))
                end
            end
        else
            M.log("Debug: No display configuration found")
        end
    end

    -- Initialize display states
    M.initializeDisplayStates()

    -- Set up watchers
    M.screenWatcher = hs.screen.watcher.new(M.screenCallback)
    M.screenWatcher:start()

    M.caffeineWatcher = hs.caffeinate.watcher.new(M.caffeineCallback)
    M.caffeineWatcher:start()

    -- Set up camera watcher for real-time detection
    M.setupCameraWatcher()

    -- Self-healing timer disabled - relying on camera property watchers only
    -- Set up call monitoring timer (check every 5 seconds as backup)
    -- M.callMonitorTimer = hs.timer.doEvery(5, M.monitorCallStatus)
    -- M.callMonitorTimer:start()

    -- Debug hotkey
    hs.hotkey.bind({ "cmd", "alt" }, "D", function()
        local status = M.getStatus()
        print("Display Manager Status:")
        print(hs.inspect(status))

        -- Test environment variables
        M.log("Environment Variables Check:")
        M.log("HOMEASSISTANT_URL: " .. (os.getenv("HOMEASSISTANT_URL") or "NOT SET"))
        M.log("HOMEASSISTANT_TOKEN: " .. (os.getenv("HOMEASSISTANT_TOKEN") and "SET" or "NOT SET"))

        -- Show call status
        M.log("Call Status: " .. (M.state.callActive and "ACTIVE" or "INACTIVE"))

        -- Test camera detection using native Hammerspoon API
        M.log("=== Camera Detection Debug (Native API) ===")

        local cameras = hs.camera.allCameras()
        M.log("Total cameras found: " .. #cameras)

        for i, camera in ipairs(cameras) do
            local inUse = camera:isInUse()
            M.log(string.format("Camera %d: %s - In use: %s", i, camera:name(), inUse and "YES" or "NO"))
        end

        -- Overall status
        M.log("Camera in use: " .. (M.checkCameraUsage() and "YES" or "NO"))

        M.toggleDebugMode()
    end)

    -- Manual call toggle hotkey
    hs.hotkey.bind({ "cmd", "alt", "shift" }, "C", function()
        local configModule = package.loaded["modules.config"]
        local privateConfig = configModule and configModule.loadPrivateConfig and configModule.loadPrivateConfig()

        if privateConfig and privateConfig.call_light then
            M.state.callActive = not M.state.callActive
            local action = M.state.callActive and "started" or "ended"
            M.log(string.format("Manually %s call", action))
            M.controlCallLight(M.state.callActive, privateConfig)

            hs.alert.show("Call " .. (M.state.callActive and "Started" or "Ended"), 2)
        else
            hs.alert.show("Call light not configured", 2)
        end
    end)

    -- Test API call hotkey
    hs.hotkey.bind({ "cmd", "alt", "shift" }, "T", function()
        M.log("Test hotkey pressed!")
        hs.alert.show("Test hotkey activated", 1)

        local configModule = package.loaded["modules.config"]
        local privateConfig = configModule and configModule.loadPrivateConfig and configModule.loadPrivateConfig()

        M.log("Private config loaded: " .. (privateConfig and "YES" or "NO"))

        if privateConfig and privateConfig.call_light then
            M.log("Call light config found")
            -- Test with basic turn_on call (no RGB)
            local apiUrl = privateConfig.homeassistant.url .. "/api/services/light/turn_on"
            local headers = {
                ["Authorization"] = "Bearer " .. privateConfig.homeassistant.token,
                ["Content-Type"] = "application/json"
            }
            local body = hs.json.encode({entity_id = privateConfig.call_light.entity_id})

            M.log("Testing basic light control...")
            M.log("API URL: " .. apiUrl)
            M.log("Entity: " .. privateConfig.call_light.entity_id)
            M.log("Request body: " .. body)

            hs.http.asyncPost(apiUrl, body, headers, function(status, responseBody, responseHeaders)
                M.log(string.format("Test result: %d - %s", status, responseBody or "No response"))
                if status ~= 200 then
                    M.log("Headers: " .. hs.inspect(responseHeaders))
                end
            end)

            hs.alert.show("Testing light API call", 2)
        else
            M.log("Call light not configured or private config missing")
            hs.alert.show("Call light not configured", 2)
        end
    end)

    M.log("Display Manager initialized")
end

-- Stop module
function M.stop()
    if M.screenWatcher then
        M.screenWatcher:stop()
        M.screenWatcher = nil
    end

    if M.caffeineWatcher then
        M.caffeineWatcher:stop()
        M.caffeineWatcher = nil
    end

    if M.callMonitorTimer then
        M.callMonitorTimer:stop()
        M.callMonitorTimer = nil
    end

    -- Stop camera watchers
    local cameras = hs.camera.allCameras()
    for _, camera in pairs(cameras) do
        if camera:isPropertyWatcherRunning() then
            camera:stopPropertyWatcher()
        end
    end
    hs.camera.stopWatcher()

    -- Cancel all pending actions
    for actionKey, timer in pairs(M.state.pendingActions) do
        timer:stop()
    end
    M.state.pendingActions = {}

    M.log("Display Manager stopped")
end

return M