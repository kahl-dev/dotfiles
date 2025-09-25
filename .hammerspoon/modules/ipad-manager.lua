-- iPad Manager Module
-- Manages iPad display modes: Sidecar (display extension) and Universal Control (standalone)

local M = {}

-- Module state (simplified)
M.state = {
    debugMode = false
}

-- Configuration
M.config = {
    iPad = {
        name = "iPad Pro",  -- Update this to match your iPad name
        hotkeys = {
            toggle_sidecar = { "cmd", "alt", "shift", "S" },
            toggle_universal_control = { "cmd", "alt", "shift", "U" },
            toggle_mode = { "cmd", "alt", "shift", "I" }  -- Smart toggle between modes
        }
    },
    settings = {
        debug_notifications = true,
        sidecar_timeout = 5.0  -- Timeout for Sidecar operations
    }
}

-- Debug logging
function M.log(message, level)
    level = level or "info"
    local timestamp = os.date("%H:%M:%S")
    local logMessage = string.format("[%s] iPad Manager: %s", timestamp, message)

    print(logMessage)

    if M.config.settings.debug_notifications and M.state.debugMode then
        hs.alert.show(message, 2)
    end
end

-- Check if Sidecar is currently active
function M.isSidecarActive()
    -- Check if iPad is listed as a connected screen
    local screens = hs.screen.allScreens()
    for _, screen in ipairs(screens) do
        local name = screen:name()
        if name and (string.find(name:lower(), "ipad") or string.find(name:lower(), "airplay")) then
            M.log(string.format("Found Sidecar screen: %s", name))
            return true
        end
    end
    return false
end

-- Check if Universal Control is active
function M.isUniversalControlActive()
    -- No reliable way to detect Universal Control programmatically
    -- Always return false since we removed state tracking
    return false
end

-- Connect iPad as extended display (Sidecar)
function M.connectSidecarExtended()
    M.log("Connecting iPad as extended display...")

    local centralScript = os.getenv("HOME") .. "/.dotfiles/bin/ipad-control"

    hs.task.new(centralScript, function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
            M.log("Sidecar extended connection completed")
            -- State tracking removed - using centralized script
            hs.alert.show("iPad connected as extended display", 2)
        else
            M.log("Sidecar extended connection failed: " .. (stdErr or "Unknown error"))
            hs.alert.show("Connection failed", 2)
        end
    end, {"sidecar"}):start()
end


-- Connect iPad via Universal Control
function M.connectUniversalControl()
    M.log("Connecting iPad via Universal Control...")

    local centralScript = os.getenv("HOME") .. "/.dotfiles/bin/ipad-control"

    hs.task.new(centralScript, function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
            M.log("Universal Control connection completed")
            -- State tracking removed - using centralized script
            hs.alert.show("iPad connected via Universal Control", 2)
        else
            M.log("Universal Control connection failed: " .. (stdErr or "Unknown error"))
            hs.alert.show("Connection failed", 2)
        end
    end, {"universal"}):start()
end





-- Enable Universal Control mode (alias for backward compatibility)
function M.enableUniversalControl()
    M.connectUniversalControl()
end


-- Setup hotkeys (disabled - using hotkey layer instead)
function M.setupHotkeys()
    -- Hotkeys moved to hotkey-layer module
    M.log("iPad hotkeys now managed by hotkey layer (cmd+H)")
end

-- Initialize module
function M.init()
    M.log("Initializing iPad Manager...")

    -- Setup hotkeys
    M.setupHotkeys()

    M.log("iPad Manager initialized (using centralized ipad-control script)")
end

-- Stop module
function M.stop()
    M.log("iPad Manager stopped")
end

return M