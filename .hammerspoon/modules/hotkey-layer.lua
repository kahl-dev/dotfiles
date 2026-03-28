-- Hotkey Layer Module
-- Unified hotkey system with Catppuccin Mocha visual overlay
-- Trigger: hyper+. (ctrl+alt+shift+cmd+period)

local M = {}

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Module State                                                 ║
-- ╚══════════════════════════════════════════════════════════════╝

M.state = {
    layerActive = false,
    overlay = nil,
    layerHotkeys = {},
    hideTimer = nil,
    triggerHotkey = nil,
}

local colors = require("modules.catppuccin")

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Configuration                                                ║
-- ╚══════════════════════════════════════════════════════════════╝

M.config = {
    trigger = { "shift", "cmd", "ctrl", "alt" },
    key = ".",           -- hyper+. (period avoids macOS Cmd+Shift+/ Help Menu interception)
    timeout = 5,         -- Auto-hide timeout in seconds
    font = "Menlo",
    titleSize = 14,
    bindingSize = 13,
    keyWidth = 50,
    descWidth = 220,
    groupGap = 16,
    padding = 24,
    cornerRadius = 12,
    lineHeight = 20,
    titleLineHeight = 28,
}

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Command Groups                                               ║
-- ╚══════════════════════════════════════════════════════════════╝

M.commandGroups = {
    {
        title = "iPad Controls",
        color = colors.blue,
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
        title = "Audio/Call",
        color = colors.peach,
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
        title = "System",
        color = colors.green,
        commands = {
            { key = "R", desc = "Reload Hammerspoon", action = function()
                hs.reload()
            end },
            { key = "D", desc = "Toggle all debug modes", action = function()
                local displayManager = require("modules.display-manager")
                local ipadManager = require("modules.ipad-manager")

                displayManager.toggleDebugMode()
                ipadManager.state.debugMode = not ipadManager.state.debugMode

                local debugState = displayManager.state.debugMode and "ON" or "OFF"
                hs.alert.show("Debug modes: " .. debugState, 2)

                print("=== Debug Mode Toggled: " .. debugState .. " ===")
                print("Display Manager Status:")
                print(hs.inspect(displayManager.getStatus()))
            end }
        }
    }
}

-- Flat list for easy access during hotkey registration
M.commands = {}
for _, group in ipairs(M.commandGroups) do
    for _, cmd in ipairs(group.commands) do
        table.insert(M.commands, cmd)
    end
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Overlay Rendering                                            ║
-- ╚══════════════════════════════════════════════════════════════╝

local function calculateContentHeight(groups)
    local height = 0
    for groupIndex, group in ipairs(groups) do
        height = height + M.config.titleLineHeight
        height = height + (#group.commands * M.config.lineHeight)
        if groupIndex < #groups then
            height = height + M.config.groupGap
        end
    end
    return height
end

function M.createOverlay()
    local screen = hs.screen.mainScreen()
    local screenFrame = screen:frame()

    -- Calculate dimensions
    local contentHeight = calculateContentHeight(M.commandGroups)
    local titleBarHeight = 40
    local footerHeight = 44 -- two lines: action hint + cross-tool references
    local columnWidth = M.config.keyWidth + M.config.descWidth
    local overlayWidth = columnWidth + (M.config.padding * 2)
    local overlayHeight = contentHeight + titleBarHeight + footerHeight + (M.config.padding * 2)

    -- Center on screen
    local overlayFrame = {
        x = screenFrame.x + (screenFrame.w - overlayWidth) / 2,
        y = screenFrame.y + (screenFrame.h - overlayHeight) / 2,
        w = overlayWidth,
        h = overlayHeight,
    }

    local canvas = hs.canvas.new(overlayFrame)

    -- Background
    canvas[1] = {
        type = "rectangle",
        fillColor = colors.base,
        roundedRectRadii = { xRadius = M.config.cornerRadius, yRadius = M.config.cornerRadius },
    }

    -- Subtle border
    canvas[2] = {
        type = "rectangle",
        strokeColor = colors.surface0,
        fillColor = { alpha = 0 },
        strokeWidth = 1,
        roundedRectRadii = { xRadius = M.config.cornerRadius, yRadius = M.config.cornerRadius },
    }

    local elementIndex = 3

    -- Title
    local titleText = hs.styledtext.new("Hammerspoon Hotkeys", {
        font = { name = M.config.font, size = 16 },
        color = colors.text,
    })
    canvas[elementIndex] = {
        type = "text",
        text = titleText,
        textAlignment = "center",
        frame = { x = 0, y = M.config.padding, w = overlayWidth, h = 24 },
    }
    elementIndex = elementIndex + 1

    -- Separator line
    canvas[elementIndex] = {
        type = "rectangle",
        fillColor = colors.surface0,
        frame = {
            x = M.config.padding,
            y = M.config.padding + 30,
            w = overlayWidth - (M.config.padding * 2),
            h = 1,
        },
    }
    elementIndex = elementIndex + 1

    -- Content
    local contentStartY = titleBarHeight + M.config.padding
    local currentY = contentStartY

    for groupIndex, group in ipairs(M.commandGroups) do
        -- Group title
        local groupTitle = hs.styledtext.new(group.title, {
            font = { name = M.config.font, size = M.config.titleSize },
            color = group.color,
        })
        canvas[elementIndex] = {
            type = "text",
            text = groupTitle,
            textAlignment = "left",
            frame = {
                x = M.config.padding,
                y = currentY,
                w = columnWidth,
                h = M.config.titleLineHeight,
            },
        }
        elementIndex = elementIndex + 1
        currentY = currentY + M.config.titleLineHeight

        -- Bindings
        for _, cmd in ipairs(group.commands) do
            local keyDisplay = cmd.key == "escape" and "ESC" or string.upper(cmd.key)

            -- Key
            local keyText = hs.styledtext.new(keyDisplay, {
                font = { name = M.config.font, size = M.config.bindingSize },
                color = colors.lavender,
            })
            canvas[elementIndex] = {
                type = "text",
                text = keyText,
                textAlignment = "left",
                frame = {
                    x = M.config.padding,
                    y = currentY,
                    w = M.config.keyWidth,
                    h = M.config.lineHeight,
                },
            }
            elementIndex = elementIndex + 1

            -- Description
            local descText = hs.styledtext.new(cmd.desc, {
                font = { name = M.config.font, size = M.config.bindingSize },
                color = colors.text,
            })
            canvas[elementIndex] = {
                type = "text",
                text = descText,
                textAlignment = "left",
                frame = {
                    x = M.config.padding + M.config.keyWidth,
                    y = currentY,
                    w = M.config.descWidth,
                    h = M.config.lineHeight,
                },
            }
            elementIndex = elementIndex + 1
            currentY = currentY + M.config.lineHeight
        end

        -- Gap between groups
        if groupIndex < #M.commandGroups then
            currentY = currentY + M.config.groupGap
        end
    end

    -- Footer separator line
    canvas[elementIndex] = {
        type = "rectangle",
        fillColor = colors.surface0,
        frame = {
            x = M.config.padding,
            y = overlayHeight - M.config.padding - footerHeight,
            w = overlayWidth - (M.config.padding * 2),
            h = 1,
        },
    }
    elementIndex = elementIndex + 1

    -- Footer line 1: action hint
    local footerLine1 = hs.styledtext.new("ESC close  ·  press key to execute", {
        font = { name = M.config.font, size = 11 },
        color = colors.overlay0,
    })
    canvas[elementIndex] = {
        type = "text",
        text = footerLine1,
        textAlignment = "center",
        frame = {
            x = M.config.padding,
            y = overlayHeight - M.config.padding - footerHeight + 10,
            w = overlayWidth - (M.config.padding * 2),
            h = 16,
        },
    }
    elementIndex = elementIndex + 1

    -- Footer line 2: cross-tool references
    local footerLine2 = hs.styledtext.new("aerospace: alt ?  ·  tmux: prefix ?", {
        font = { name = M.config.font, size = 11 },
        color = colors.overlay0,
    })
    canvas[elementIndex] = {
        type = "text",
        text = footerLine2,
        textAlignment = "center",
        frame = {
            x = M.config.padding,
            y = overlayHeight - M.config.padding - footerHeight + 26,
            w = overlayWidth - (M.config.padding * 2),
            h = 16,
        },
    }

    -- Show overlay
    canvas:level(hs.canvas.windowLevels.overlay)
    M.state.overlay = canvas

    return canvas
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Layer Control                                                ║
-- ╚══════════════════════════════════════════════════════════════╝

function M.showLayer()
    if M.state.layerActive then
        return
    end

    M.state.layerActive = true

    -- Create and show overlay
    M.createOverlay()
    M.state.overlay:show()

    -- Register temporary hotkeys
    M.state.layerHotkeys = {}

    -- Register escape key
    local escapeHotkey = hs.hotkey.bind({}, "escape", function()
        M.hideLayer()
    end)
    table.insert(M.state.layerHotkeys, escapeHotkey)

    -- Register all command hotkeys
    for _, cmd in ipairs(M.commands) do
        if cmd.key ~= "escape" then
            local hotkey = hs.hotkey.bind({}, cmd.key:lower(), function()
                M.hideLayer()
                if cmd.action then
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
end

function M.hideLayer()
    if not M.state.layerActive then
        return
    end

    M.state.layerActive = false

    -- Delete overlay (free native window resource)
    if M.state.overlay then
        M.state.overlay:hide()
        M.state.overlay:delete()
        M.state.overlay = nil
    end

    -- Delete ephemeral hotkeys (not just disable — avoids registry leak)
    for _, hotkey in ipairs(M.state.layerHotkeys) do
        hotkey:delete()
    end
    M.state.layerHotkeys = {}

    -- Cancel auto-hide timer
    if M.state.hideTimer then
        M.state.hideTimer:stop()
        M.state.hideTimer = nil
    end
end

function M.toggleLayer()
    if M.state.layerActive then
        M.hideLayer()
    else
        M.showLayer()
    end
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Dynamic Command API                                          ║
-- ╚══════════════════════════════════════════════════════════════╝

function M.addCommand(key, description, actionFunction, groupTitle)
    groupTitle = groupTitle or "System"

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
            color = colors.mauve,
            commands = {}
        }
        table.insert(M.commandGroups, targetGroup)
    end

    local newCommand = {
        key = key,
        desc = description,
        action = actionFunction
    }
    table.insert(targetGroup.commands, newCommand)
    table.insert(M.commands, newCommand)
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Lifecycle                                                    ║
-- ╚══════════════════════════════════════════════════════════════╝

function M.init()
    M.state.triggerHotkey = hs.hotkey.bind(M.config.trigger, M.config.key, function()
        M.toggleLayer()
    end)

    print("Hotkey Layer initialized - Press hyper+. (ctrl+alt+shift+cmd+period)")
end

function M.stop()
    M.hideLayer()

    if M.state.triggerHotkey then
        M.state.triggerHotkey:delete()
        M.state.triggerHotkey = nil
    end

    print("Hotkey Layer stopped")
end

return M
