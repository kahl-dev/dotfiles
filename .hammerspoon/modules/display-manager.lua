-- Display Manager Module
-- Automatically manages desk setup power based on display connections and lock/unlock state

local M = {}

-- Module state
M.state = {
    displayStates = {},
    macbookLocked = false,
    pendingActions = {},
    currentDesktopUUID = nil,
    debugMode = false
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

    -- Debug hotkey
    hs.hotkey.bind({ "cmd", "alt" }, "D", function()
        local status = M.getStatus()
        print("Display Manager Status:")
        print(hs.inspect(status))

        -- Test environment variables
        M.log("Environment Variables Check:")
        M.log("HOMEASSISTANT_URL: " .. (os.getenv("HOMEASSISTANT_URL") or "NOT SET"))
        M.log("HOMEASSISTANT_TOKEN: " .. (os.getenv("HOMEASSISTANT_TOKEN") and "SET" or "NOT SET"))

        M.toggleDebugMode()
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

    -- Cancel all pending actions
    for actionKey, timer in pairs(M.state.pendingActions) do
        timer:stop()
    end
    M.state.pendingActions = {}

    M.log("Display Manager stopped")
end

return M