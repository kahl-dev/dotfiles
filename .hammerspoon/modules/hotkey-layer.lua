-- Hotkey Layer Module
-- Creates a unified hotkey system with visual menu overlay

local M = {}

-- Module state
M.state = {
    layerActive = false,
    overlay = nil,
    hotkeys = {},
    layerHotkeys = {}
}

-- Configuration
M.config = {
    trigger = { "shift", "cmd", "ctrl", "alt" }, -- Super key for layer activation
    key = "M",          -- Key to activate layer (M for Menu)
    timeout = 5,        -- Auto-hide timeout in seconds
    overlay = {
        textFont = "Menlo",
        textSize = 16,
        backgroundColor = { red = 0, green = 0, blue = 0, alpha = 0.8 },
        textColor = { red = 1, green = 1, blue = 1, alpha = 1 },
        cornerRadius = 10,
        padding = 20
    }
}

-- Registered hotkey command groups
M.commandGroups = {
    {
        title = "📱 iPad Controls",
        commands = {
            { key = "S", desc = "Sidecar Extended Display", action = function()
                require("modules.ipad-manager").connectSidecarExtended()
            end },
            { key = "U", desc = "Universal Control", action = function()
                require("modules.ipad-manager").connectUniversalControl()
            end }
        }
    },
    {
        title = "🔊 Audio/Call",
        commands = {
            { key = "C", desc = "Toggle call light", action = function()
                local displayManager = require("modules.display-manager")
                local configModule = package.loaded["modules.config"]
                local privateConfig = configModule and configModule.loadPrivateConfig and configModule.loadPrivateConfig()

                if privateConfig and privateConfig.call_light then
                    displayManager.state.callActive = not displayManager.state.callActive
                    displayManager.controlCallLight(displayManager.state.callActive, privateConfig)
                    hs.alert.show("Call " .. (displayManager.state.callActive and "Started" or "Ended"), 2)
                else
                    hs.alert.show("Call light not configured", 2)
                end
            end }
        }
    },
    {
        title = "⚙️ System",
        commands = {
            { key = "R", desc = "Reload Hammerspoon", action = function()
                hs.reload()
            end },
            { key = "D", desc = "Toggle all debug modes", action = function()
                -- Toggle debug for all modules
                local displayManager = require("modules.display-manager")
                local ipadManager = require("modules.ipad-manager")

                -- Toggle display manager debug
                displayManager.toggleDebugMode()

                -- Toggle iPad manager debug
                ipadManager.state.debugMode = not ipadManager.state.debugMode

                local debugState = displayManager.state.debugMode and "ON" or "OFF"
                hs.alert.show("Debug modes: " .. debugState, 2)

                -- Print status for logging
                print("=== Debug Mode Toggled: " .. debugState .. " ===")
                print("Display Manager Status:")
                print(hs.inspect(displayManager.getStatus()))
            end }
        }
    }
}

-- Keep a flat list for backward compatibility and easy access
M.commands = {}
for _, group in ipairs(M.commandGroups) do
    for _, cmd in ipairs(group.commands) do
        table.insert(M.commands, cmd)
    end
end

-- Create overlay window
function M.createOverlay()
    local screen = hs.screen.mainScreen()
    local screenFrame = screen:frame()

    -- Build content with groups
    local content = ""

    for groupIdx, group in ipairs(M.commandGroups) do
        -- Add group header
        content = content .. group.title .. "\n"

        -- Add commands in this group
        for _, cmd in ipairs(group.commands) do
            local keyDisplay = cmd.key == "escape" and "ESC" or string.upper(cmd.key)
            content = content .. string.format("  %s   %s\n", keyDisplay, cmd.desc)
        end

        -- Add spacing between groups (except after last group)
        if groupIdx < #M.commandGroups then
            content = content .. "\n"
        end
    end

    -- Add footer
    content = content .. "\n[ESC to close]"

    -- Create styled text
    local styledText = hs.styledtext.new(content, {
        font = { name = M.config.overlay.textFont, size = M.config.overlay.textSize },
        color = M.config.overlay.textColor,
        paragraphStyle = { alignment = "left", lineSpacing = 4 }
    })

    -- Calculate overlay size (simplified approach)
    local lines = {}
    for line in content:gmatch("[^\n]+") do
        table.insert(lines, line)
    end

    -- Estimate size based on content
    local maxLineLength = 0
    for _, line in ipairs(lines) do
        if #line > maxLineLength then
            maxLineLength = #line
        end
    end

    local estimatedWidth = maxLineLength * 10 + (M.config.overlay.padding * 2)
    local estimatedHeight = #lines * 24 + (M.config.overlay.padding * 2)

    local overlayWidth = math.max(estimatedWidth, 350)  -- Minimum width
    local overlayHeight = math.max(estimatedHeight, 200)  -- Minimum height

    -- Position overlay (center of screen)
    local overlayFrame = {
        x = screenFrame.x + (screenFrame.w - overlayWidth) / 2,
        y = screenFrame.y + (screenFrame.h - overlayHeight) / 2,
        w = overlayWidth,
        h = overlayHeight
    }

    -- Create canvas
    M.state.overlay = hs.canvas.new(overlayFrame)

    -- Background
    M.state.overlay[1] = {
        type = "rectangle",
        fillColor = M.config.overlay.backgroundColor,
        roundedRectRadii = { xRadius = M.config.overlay.cornerRadius, yRadius = M.config.overlay.cornerRadius }
    }

    -- Text
    M.state.overlay[2] = {
        type = "text",
        text = styledText,
        textAlignment = "left",
        frame = {
            x = M.config.overlay.padding,
            y = M.config.overlay.padding,
            w = overlayWidth - (M.config.overlay.padding * 2),
            h = overlayHeight - (M.config.overlay.padding * 2)
        }
    }

    return M.state.overlay
end

-- Show the hotkey layer
function M.showLayer()
    if M.state.layerActive then
        return -- Already active
    end

    M.state.layerActive = true

    -- Create and show overlay
    M.createOverlay()
    M.state.overlay:show()

    -- Register temporary hotkeys
    M.state.layerHotkeys = {}

    -- Register escape key separately
    local escapeHotkey = hs.hotkey.bind({}, "escape", function()
        M.hideLayer()
    end)
    table.insert(M.state.layerHotkeys, escapeHotkey)

    -- Register all command hotkeys
    for _, cmd in ipairs(M.commands) do
        if cmd.key ~= "escape" then  -- Skip escape, already handled
            local hotkey = hs.hotkey.bind({}, cmd.key:lower(), function()
                M.hideLayer()
                if cmd.action then
                    -- Small delay to ensure overlay is hidden first
                    hs.timer.doAfter(0.1, cmd.action)
                end
            end)
            table.insert(M.state.layerHotkeys, hotkey)
        end
    end

    -- Auto-hide timer
    if M.config.timeout > 0 then
        M.state.hideTimer = hs.timer.doAfter(M.config.timeout, function()
            M.hideLayer()
        end)
    end

    hs.alert.show("🔧 Hotkey layer active", 1)
end

-- Hide the hotkey layer
function M.hideLayer()
    if not M.state.layerActive then
        return -- Already inactive
    end

    M.state.layerActive = false

    -- Hide overlay
    if M.state.overlay then
        M.state.overlay:hide()
        M.state.overlay = nil
    end

    -- Disable temporary hotkeys
    for _, hotkey in ipairs(M.state.layerHotkeys) do
        hotkey:disable()
    end
    M.state.layerHotkeys = {}

    -- Cancel auto-hide timer
    if M.state.hideTimer then
        M.state.hideTimer:stop()
        M.state.hideTimer = nil
    end
end

-- Toggle layer visibility
function M.toggleLayer()
    if M.state.layerActive then
        M.hideLayer()
    else
        M.showLayer()
    end
end

-- Add a command to the layer (for backward compatibility)
function M.addCommand(key, description, actionFunction, groupTitle)
    groupTitle = groupTitle or "⚙️ System"  -- Default to System group

    -- Find the group
    local targetGroup = nil
    for _, group in ipairs(M.commandGroups) do
        if group.title == groupTitle then
            targetGroup = group
            break
        end
    end

    -- If group doesn't exist, create it
    if not targetGroup then
        targetGroup = {
            title = groupTitle,
            commands = {}
        }
        table.insert(M.commandGroups, targetGroup)
    end

    -- Add command to group
    local newCommand = {
        key = key,
        desc = description,
        action = actionFunction
    }
    table.insert(targetGroup.commands, newCommand)

    -- Also add to flat list
    table.insert(M.commands, newCommand)
end

-- Initialize module
function M.init()
    -- Register main trigger hotkey
    M.state.triggerHotkey = hs.hotkey.bind(M.config.trigger, M.config.key, function()
        M.toggleLayer()
    end)

    print("Hotkey Layer initialized - Press ctrl+alt+shift+cmd+M to activate")
end

-- Stop module
function M.stop()
    M.hideLayer()

    if M.state.triggerHotkey then
        M.state.triggerHotkey:disable()
        M.state.triggerHotkey = nil
    end

    print("Hotkey Layer stopped")
end

return M