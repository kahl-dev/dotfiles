-- Hammerspoon Configuration
-- Manages audio, displays and presence automatically. No hotkeys.

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

-- Enable IPC for hs CLI. Required: Raycast scripts drive audio-manager and
-- presence-keeper via `hs -c "require('modules.<name>')..."`.
require("hs.ipc")

-- Load modules
local config = require("modules.config")
local usbManager = require("modules.usb-device-manager")
local displayManager = require("modules.display-manager")
local presenceKeeper = require("modules.presence-keeper")

-- Required for its side effect only: usb-device-manager reaches the module via
-- package.loaded when the Wave:3 connects, so it must be loaded up front.
require("modules.audio-manager")

-- Initialize configuration
config.init()

-- Initialize modules
-- audioManager is started by usbManager when Wave:3 USB device is detected
usbManager.init()
displayManager.init()
presenceKeeper.init()