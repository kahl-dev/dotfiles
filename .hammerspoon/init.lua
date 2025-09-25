-- Hammerspoon Configuration
-- Manages Elgato devices automatically

-- Manual reload hotkey moved to hotkey layer
-- hs.hotkey.bind({ "cmd", "alt" }, "R", function()
--     hs.reload()
-- end)

-- Auto-reload on config file changes
local function reloadConfig(files)
    local doReload = false
    for _, file in pairs(files) do
        if file:sub(-4) == ".lua" or file:sub(-5) == ".json" then
            doReload = true
        end
    end
    if doReload then
        hs.reload()
    end
end

hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
hs.alert.show("Hammerspoon loaded")

-- Load modules
local config = require("modules.config")
local audioManager = require("modules.audio-manager")
local usbManager = require("modules.usb-device-manager")
local displayManager = require("modules.display-manager")
local ipadManager = require("modules.ipad-manager")
local hotkeyLayer = require("modules.hotkey-layer")

-- Initialize configuration
config.init()

-- Initialize modules
audioManager.init()
usbManager.init()
displayManager.init()
-- ipadManager.init() -- Disabled to avoid duplicate hotkeys
hotkeyLayer.init() -- Unified hotkey system