-- Configuration Module
-- Simple configuration loader for Hammerspoon device management

local M = {}

-- Configuration paths
M.configPath = os.getenv("HOME") .. "/.hammerspoon/config/devices.json"
M.privatePath = os.getenv("HOME") .. "/.hammerspoon/config/private.json"

-- Default configuration
M.defaults = {
    usb = {
        devices = {
            stream_deck = {
                vendor_id = 4057,
                product_ids = {134, 128, 96, 108, 109, 143, 144},
                app_bundle_id = "com.elgato.StreamDeck",
                app_name = "Elgato Stream Deck",
                launch_hidden = true
            },
            wave3_audio = {
                vendor_id = 4057,
                product_ids = {102, 103, 112, 113},
                coordinate_audio = true
            }
        },
        settings = {
            launch_delay = 2.0,
            hide_delay = 2.0,
            notifications = false,
            debounce_delay = 2.0
        }
    },
    -- Device identity is single-sourced: audio-manager.lua literal defaults (bootstrap) +
    -- ~/.config/audio-manager/config.json (runtime). No device names are duplicated here, so an
    -- escaped vs plain mismatch can't silently override and break the daemon's plain matching.
    audio = {}
}

-- Load configuration from file
function M.loadFromFile()
    local file = io.open(M.configPath, "r")
    if not file then
        return nil
    end

    local content = file:read("*a")
    file:close()

    if content == "" then
        return nil
    end

    local success, config = pcall(hs.json.decode, content)
    if success then
        return config
    end

    return nil
end

-- Load private configuration
function M.loadPrivateConfig()
    local file = io.open(M.privatePath, "r")
    if not file then
        return nil
    end

    local content = file:read("*a")
    file:close()

    if content == "" then
        return nil
    end

    local success, config = pcall(hs.json.decode, content)
    if success then
        return config
    end

    return nil
end

-- Initialize configuration
function M.init()
    -- Start with defaults
    M.usb = M.defaults.usb
    M.audio = M.defaults.audio

    -- Load and merge user configuration
    local userConfig = M.loadFromFile()
    if userConfig then
        -- Merge USB config
        if userConfig.devices then
            for key, device in pairs(userConfig.devices) do
                if M.usb.devices[key] then
                    for k, v in pairs(device) do
                        M.usb.devices[key][k] = v
                    end
                else
                    M.usb.devices[key] = device
                end
            end
        end

        -- Merge settings
        if userConfig.settings then
            for key, value in pairs(userConfig.settings) do
                M.usb.settings[key] = value
            end
        end

        -- Merge audio config
        if userConfig.audio then
            for key, value in pairs(userConfig.audio) do
                M.audio[key] = value
            end
        end

        -- Load display configuration
        if userConfig.displays then
            M.displays = {
                displays = {},
                macbook_display_uuid = userConfig.macbook_display_uuid,
                settings = userConfig.display_settings or {}
            }

            -- Process display configs - the displays key contains individual display configs
            for displayKey, displayConfig in pairs(userConfig.displays) do
                local uuid = displayConfig.display_uuid
                if uuid then
                    -- Clone the config to avoid modifying the original
                    local config = hs.fnutils.copy(displayConfig)

                    -- Override with private config if it exists
                    if config.eve_plug then
                        -- Load private config
                        local privateConfig = M.loadPrivateConfig()
                        if privateConfig and privateConfig.homeassistant then
                            if privateConfig.homeassistant.url then
                                config.eve_plug.home_assistant_url = privateConfig.homeassistant.url
                            end
                            if privateConfig.homeassistant.token then
                                config.eve_plug.token = privateConfig.homeassistant.token
                            end
                        end
                    end

                    M.displays.displays[uuid] = config
                end
            end
        end
    end
end

return M