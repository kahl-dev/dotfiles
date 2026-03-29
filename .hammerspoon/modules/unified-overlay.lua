-- Unified Keybinding Overlay
-- Three-column reference (AeroSpace + tmux) + interactive Hammerspoon strip
-- Trigger: alt+? via AeroSpace exec-and-forget → hs -c IPC

local M = {}

local colors = require("modules.catppuccin")

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  AeroSpace Binding Data                                      ║
-- ╚══════════════════════════════════════════════════════════════╝

local asLeftColumn = {
  {
    title = "Focus",
    color = colors.blue,
    bindings = {
      { key = "alt h/j/k/l", desc = "Focus direction" },
      { key = "alt ;",        desc = "Back and forth" },
    }
  },
  {
    title = "Move Window",
    color = colors.lavender,
    bindings = {
      { key = "alt shift h/j/k/l", desc = "Move direction" },
    }
  },
  {
    title = "Swap Position",
    color = colors.mauve,
    bindings = {
      { key = "alt ctrl h/j/k/l", desc = "Swap direction" },
    }
  },
  {
    title = "Resize",
    color = colors.peach,
    bindings = {
      { key = "alt -",  desc = "Shrink" },
      { key = "alt =",  desc = "Grow" },
    }
  },
  {
    title = "Layout",
    color = colors.yellow,
    bindings = {
      { key = "alt /", desc = "Toggle tiles h/v" },
      { key = "alt ,", desc = "Toggle accordion h/v" },
    }
  },
  {
    title = "Service Mode",
    color = colors.yellow,
    bindings = {
      { key = "esc",             desc = "Reload config & exit" },
      { key = "r",               desc = "Reset layout (flatten)" },
      { key = "x",               desc = "Toggle fullscreen" },
      { key = "f",               desc = "Toggle floating/tiling" },
      { key = "b",               desc = "Balance window sizes" },
      { key = "e",               desc = "Enable/disable AeroSpace" },
      { key = "backspace",       desc = "Close all but current" },
      { key = "alt shift h/j/k/l", desc = "Join with neighbor" },
    }
  },
}

local asRightColumn = {
  {
    title = "Workspace",
    color = colors.blue,
    bindings = {
      { key = "alt 1..9", desc = "Switch to workspace" },
      { key = "alt shift 1..9", desc = "Move window to ws" },
      { key = "alt n/p",  desc = "Next/prev workspace" },
      { key = "alt tab",  desc = "Back and forth" },
    }
  },
  {
    title = "Window",
    color = colors.green,
    bindings = {
      { key = "alt q", desc = "Close (quit if last)" },
      { key = "alt f", desc = "Fullscreen (tiling)" },
      { key = "alt e", desc = "Fullscreen (native)" },
    }
  },
  {
    title = "Monitor",
    color = colors.peach,
    bindings = {
      { key = "hyper h/j/k/l", desc = "Move node to monitor" },
      { key = "hyper tab",     desc = "Move ws to monitor" },
    }
  },
  {
    title = "Modes",
    color = colors.mauve,
    bindings = {
      { key = "hyper ;", desc = "Service mode" },
      { key = "hyper a", desc = "Apps mode" },
      { key = "alt ?",   desc = "This overlay" },
    }
  },
  {
    title = "Apps Mode",
    color = colors.green,
    bindings = {
      { key = "t", desc = "Ghostty" },
      { key = "b", desc = "Arc" },
      { key = "g", desc = "ChatGPT" },
      { key = "m", desc = "Teams" },
      { key = "esc", desc = "Exit" },
    }
  },
}

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  tmux Binding Data (prefix = Ctrl+S)                        ║
-- ╚══════════════════════════════════════════════════════════════╝

local tmuxLeftColumn = {
  {
    title = "Sessions",
    color = colors.blue,
    bindings = {
      { key = "o", desc = "Session manager" },
      { key = "Q", desc = "Kill session" },
      { key = "L", desc = "Last session" },
      { key = "d", desc = "Detach" },
    }
  },
  {
    title = "Windows",
    color = colors.green,
    bindings = {
      { key = "c", desc = "New window" },
      { key = "X", desc = "Kill window" },
      { key = "l", desc = "Last window" },
      { key = ",", desc = "Rename window" },
    }
  },
  {
    title = "Panes",
    color = colors.peach,
    bindings = {
      { key = "|", desc = "Split horizontal" },
      { key = "-", desc = "Split vertical" },
      { key = "_", desc = "Full-width split" },
      { key = "z", desc = "Zoom toggle" },
      { key = "x", desc = "Kill pane" },
      { key = "B", desc = "Break pane out" },
      { key = "E", desc = "Join pane from..." },
    }
  },
  {
    title = "Tools",
    color = colors.yellow,
    bindings = {
      { key = "u",     desc = "URLs in pane" },
      { key = "Tab",   desc = "Extract text (fzf)" },
      { key = "F",     desc = "Thumbs (hint copy)" },
      { key = "/",     desc = "Search scrollback" },
      { key = "*",     desc = "Kill process" },
      { key = "Enter", desc = "Copy mode" },
      { key = "r",     desc = "Reload config" },
      { key = "?",     desc = "Which-key menu" },
    }
  },
}

local tmuxRightColumn = {
  {
    title = "Apps Layer  (prefix a)",
    color = colors.mauve,
    bindings = {
      { key = "g/G", desc = "Lazygit win/popup" },
      { key = "y/Y", desc = "Yazi win/popup" },
      { key = "b/B", desc = "btop win/popup" },
      { key = "m/M", desc = "glow win/popup" },
    }
  },
  {
    title = "Panes Layer  (prefix v)",
    color = colors.mauve,
    bindings = {
      { key = "=",   desc = "Balance equally" },
      { key = "t",   desc = "Tiled (auto grid)" },
      { key = "m/M", desc = "Main vert/horiz" },
      { key = "1/2/3", desc = "Grid max rows" },
      { key = "h/l", desc = "Swap prev/next" },
      { key = "s",   desc = "Swap by number" },
      { key = "j",   desc = "Join pane (tree)" },
      { key = "g/G", desc = "Grab pane h/v" },
      { key = "r",   desc = "Rotate" },
    }
  },
  {
    title = "TPM  (prefix t)",
    color = colors.mauve,
    bindings = {
      { key = "i", desc = "Install plugins" },
      { key = "u", desc = "Update plugins" },
      { key = "x", desc = "Clean plugins" },
    }
  },
}

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Hammerspoon Command Data                                    ║
-- ╚══════════════════════════════════════════════════════════════╝

local hsGroups = {
  {
    title = "iPad Controls",
    color = colors.blue,
    commands = {
      { key = "S", desc = "Sidecar Extended Display", action = function()
        require("modules.ipad-manager").connectSidecarExtended()
      end },
      { key = "U", desc = "Universal Control", action = function()
        require("modules.ipad-manager").connectUniversalControl()
      end },
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
      end },
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
      end },
    }
  },
}

-- Flat command list for hotkey registration
local hsFlat = {}
for _, group in ipairs(hsGroups) do
  for _, cmd in ipairs(group.commands) do
    table.insert(hsFlat, cmd)
  end
end

-- Build lookup of bound keys for eventtap filtering
local boundKeys = { escape = true }
for _, cmd in ipairs(hsFlat) do
  boundKeys[cmd.key:lower()] = true
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Configuration                                               ║
-- ╚══════════════════════════════════════════════════════════════╝

local cfg = {
  font           = "Menlo",
  titleSize      = 14,
  bindingSize    = 13,
  sectionSize    = 12,
  colKeyWidth    = 120,
  colDescWidth   = 180,
  hsKeyWidth     = 40,
  hsDescWidth    = 200,
  columnGap      = 32,
  hsGroupGap     = 20,
  groupGap       = 16,
  padding        = 28,
  cornerRadius   = 12,
  lineHeight     = 20,
  titleLineHeight = 28,
  footerHeight   = 30,
  titleBarHeight = 40,
}

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Rendering Helpers                                           ║
-- ╚══════════════════════════════════════════════════════════════╝

local function calculateColumnHeight(groups)
  local height = 0
  for groupIndex, group in ipairs(groups) do
    height = height + cfg.titleLineHeight
    height = height + (#group.bindings * cfg.lineHeight)
    if groupIndex < #groups then
      height = height + cfg.groupGap
    end
  end
  return height
end

local function buildStyledColumn(groups, startY)
  local elements = {}
  local currentY = startY

  for groupIndex, group in ipairs(groups) do
    local titleText = hs.styledtext.new(group.title, {
      font = { name = cfg.font, size = cfg.titleSize },
      color = group.color,
    })
    table.insert(elements, { text = titleText, y = currentY })
    currentY = currentY + cfg.titleLineHeight

    for _, binding in ipairs(group.bindings) do
      local keyText = hs.styledtext.new(binding.key, {
        font = { name = cfg.font, size = cfg.bindingSize },
        color = colors.lavender,
      })
      local descText = hs.styledtext.new(binding.desc, {
        font = { name = cfg.font, size = cfg.bindingSize },
        color = colors.text,
      })
      table.insert(elements, { text = keyText, y = currentY, isKey = true })
      table.insert(elements, { text = descText, y = currentY, isDesc = true })
      currentY = currentY + cfg.lineHeight
    end

    if groupIndex < #groups then
      currentY = currentY + cfg.groupGap
    end
  end

  return elements, currentY
end

local function calculateHSStripHeight()
  local maxRows = 0
  for _, group in ipairs(hsGroups) do
    local rows = #group.commands
    if rows > maxRows then maxRows = rows end
  end
  return cfg.titleLineHeight + (maxRows * cfg.lineHeight)
end

local function renderColumn(canvas, elementIndex, elements, columnX, contentStartY, keyWidth, descWidth, columnWidth)
  for _, element in ipairs(elements) do
    if element.isDesc then
      canvas[elementIndex] = {
        type = "text",
        text = element.text,
        textAlignment = "left",
        frame = {
          x = columnX + keyWidth,
          y = contentStartY + element.y,
          w = descWidth,
          h = cfg.lineHeight,
        },
      }
    else
      canvas[elementIndex] = {
        type = "text",
        text = element.text,
        textAlignment = "left",
        frame = {
          x = columnX,
          y = contentStartY + element.y,
          w = element.isKey and keyWidth or columnWidth,
          h = element.isKey and cfg.lineHeight or cfg.titleLineHeight,
        },
      }
    end
    elementIndex = elementIndex + 1
  end
  return elementIndex
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  State                                                       ║
-- ╚══════════════════════════════════════════════════════════════╝

local state = {
  visible   = false,
  overlay   = nil,
  hotkeys   = {},
  eventTap  = nil,
}

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Overlay Control                                             ║
-- ╚══════════════════════════════════════════════════════════════╝

function M.hide()
  if not state.visible then return end

  state.visible = false

  if state.overlay then
    state.overlay:hide()
    state.overlay:delete()
    state.overlay = nil
  end

  for _, hotkey in ipairs(state.hotkeys) do
    hotkey:delete()
  end
  state.hotkeys = {}

  if state.eventTap then
    state.eventTap:stop()
    state.eventTap = nil
  end
end

function M.show()
  if state.visible then return end

  local screen = hs.screen.mainScreen()
  local screenFrame = screen:frame()

  -- Calculate column heights (4 columns)
  local colWidth = cfg.colKeyWidth + cfg.colDescWidth
  local leftHeight = calculateColumnHeight(asLeftColumn)
  local rightHeight = calculateColumnHeight(asRightColumn)
  local tmuxLeftHeight = calculateColumnHeight(tmuxLeftColumn)
  local tmuxRightHeight = calculateColumnHeight(tmuxRightColumn)
  local columnsHeight = math.max(leftHeight, rightHeight, tmuxLeftHeight, tmuxRightHeight)

  -- Hammerspoon strip dimensions
  local hsSeparatorGap = 16
  local hsSectionLabelHeight = 20
  local hsStripHeight = calculateHSStripHeight()
  local hsBlockHeight = hsSeparatorGap + 1 + 8 + hsSectionLabelHeight + 4 + hsStripHeight

  -- Total overlay dimensions (4 columns)
  local overlayWidth = (colWidth * 4) + (cfg.columnGap * 3) + (cfg.padding * 2)
  local overlayHeight = cfg.titleBarHeight + cfg.padding + columnsHeight + hsBlockHeight + cfg.footerHeight + cfg.padding

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
    roundedRectRadii = { xRadius = cfg.cornerRadius, yRadius = cfg.cornerRadius },
  }

  -- Border
  canvas[2] = {
    type = "rectangle",
    strokeColor = colors.surface0,
    fillColor = { alpha = 0 },
    strokeWidth = 1,
    roundedRectRadii = { xRadius = cfg.cornerRadius, yRadius = cfg.cornerRadius },
  }

  local elementIndex = 3

  -- Title
  canvas[elementIndex] = {
    type = "text",
    text = hs.styledtext.new("Keybindings  (alt+?)", {
      font = { name = cfg.font, size = 16 },
      color = colors.text,
    }),
    textAlignment = "center",
    frame = { x = 0, y = cfg.padding, w = overlayWidth, h = 24 },
  }
  elementIndex = elementIndex + 1

  -- Title separator
  canvas[elementIndex] = {
    type = "rectangle",
    fillColor = colors.surface0,
    frame = {
      x = cfg.padding,
      y = cfg.padding + 30,
      w = overlayWidth - (cfg.padding * 2),
      h = 1,
    },
  }
  elementIndex = elementIndex + 1

  -- ── Column section labels ──────────────────────────────────

  local contentStartY = cfg.titleBarHeight + cfg.padding
  local col1X = cfg.padding
  local col2X = cfg.padding + colWidth + cfg.columnGap
  local col3X = cfg.padding + (colWidth + cfg.columnGap) * 2
  local col4X = cfg.padding + (colWidth + cfg.columnGap) * 3

  -- AeroSpace label (spans columns 1-2)
  canvas[elementIndex] = {
    type = "text",
    text = hs.styledtext.new("AeroSpace — global hotkeys", {
      font = { name = cfg.font, size = cfg.sectionSize },
      color = colors.overlay0,
    }),
    textAlignment = "left",
    frame = { x = col1X, y = contentStartY, w = colWidth * 2, h = 18 },
  }
  elementIndex = elementIndex + 1

  -- tmux label (spans columns 3-4)
  canvas[elementIndex] = {
    type = "text",
    text = hs.styledtext.new("tmux — Ctrl+S then key", {
      font = { name = cfg.font, size = cfg.sectionSize },
      color = colors.overlay0,
    }),
    textAlignment = "left",
    frame = { x = col3X, y = contentStartY, w = colWidth * 2, h = 18 },
  }
  elementIndex = elementIndex + 1

  local groupStartY = contentStartY + 24

  -- ── AeroSpace left column ──────────────────────────────────

  local leftElements = buildStyledColumn(asLeftColumn, 0)
  elementIndex = renderColumn(canvas, elementIndex, leftElements, col1X, groupStartY, cfg.colKeyWidth, cfg.colDescWidth, colWidth)

  -- ── AeroSpace right column ─────────────────────────────────

  local rightElements = buildStyledColumn(asRightColumn, 0)
  elementIndex = renderColumn(canvas, elementIndex, rightElements, col2X, groupStartY, cfg.colKeyWidth, cfg.colDescWidth, colWidth)

  -- ── tmux left column ────────────────────────────────────────

  local tmuxLeftElements = buildStyledColumn(tmuxLeftColumn, 0)
  elementIndex = renderColumn(canvas, elementIndex, tmuxLeftElements, col3X, groupStartY, cfg.colKeyWidth, cfg.colDescWidth, colWidth)

  -- ── tmux right column ───────────────────────────────────────

  local tmuxRightElements = buildStyledColumn(tmuxRightColumn, 0)
  elementIndex = renderColumn(canvas, elementIndex, tmuxRightElements, col4X, groupStartY, cfg.colKeyWidth, cfg.colDescWidth, colWidth)

  -- ── Hammerspoon strip ──────────────────────────────────────

  local hsBaseY = groupStartY + columnsHeight + hsSeparatorGap

  -- HS separator line
  canvas[elementIndex] = {
    type = "rectangle",
    fillColor = colors.surface0,
    frame = {
      x = cfg.padding,
      y = hsBaseY,
      w = overlayWidth - (cfg.padding * 2),
      h = 1,
    },
  }
  elementIndex = elementIndex + 1

  -- HS section label with trigger info
  canvas[elementIndex] = {
    type = "text",
    text = hs.styledtext.new("Hammerspoon — press key now to execute", {
      font = { name = cfg.font, size = cfg.sectionSize },
      color = colors.overlay0,
    }),
    textAlignment = "left",
    frame = {
      x = cfg.padding,
      y = hsBaseY + 8,
      w = overlayWidth - (cfg.padding * 2),
      h = hsSectionLabelHeight,
    },
  }
  elementIndex = elementIndex + 1

  -- HS command groups (horizontal layout)
  local hsGroupWidth = cfg.hsKeyWidth + cfg.hsDescWidth
  local hsContentY = hsBaseY + 8 + hsSectionLabelHeight + 4
  local groupX = cfg.padding

  for _, group in ipairs(hsGroups) do
    canvas[elementIndex] = {
      type = "text",
      text = hs.styledtext.new(group.title, {
        font = { name = cfg.font, size = cfg.titleSize },
        color = group.color,
      }),
      textAlignment = "left",
      frame = {
        x = groupX,
        y = hsContentY,
        w = hsGroupWidth,
        h = cfg.titleLineHeight,
      },
    }
    elementIndex = elementIndex + 1

    local cmdY = hsContentY + cfg.titleLineHeight
    for _, cmd in ipairs(group.commands) do
      canvas[elementIndex] = {
        type = "text",
        text = hs.styledtext.new(cmd.key, {
          font = { name = cfg.font, size = cfg.bindingSize },
          color = colors.lavender,
        }),
        textAlignment = "left",
        frame = {
          x = groupX,
          y = cmdY,
          w = cfg.hsKeyWidth,
          h = cfg.lineHeight,
        },
      }
      elementIndex = elementIndex + 1

      canvas[elementIndex] = {
        type = "text",
        text = hs.styledtext.new(cmd.desc, {
          font = { name = cfg.font, size = cfg.bindingSize },
          color = colors.text,
        }),
        textAlignment = "left",
        frame = {
          x = groupX + cfg.hsKeyWidth,
          y = cmdY,
          w = cfg.hsDescWidth,
          h = cfg.lineHeight,
        },
      }
      elementIndex = elementIndex + 1

      cmdY = cmdY + cfg.lineHeight
    end

    groupX = groupX + hsGroupWidth + cfg.hsGroupGap
  end

  -- ── Footer ─────────────────────────────────────────────────

  canvas[elementIndex] = {
    type = "rectangle",
    fillColor = colors.surface0,
    frame = {
      x = cfg.padding,
      y = overlayHeight - cfg.padding - cfg.footerHeight,
      w = overlayWidth - (cfg.padding * 2),
      h = 1,
    },
  }
  elementIndex = elementIndex + 1

  canvas[elementIndex] = {
    type = "text",
    text = hs.styledtext.new("ESC close", {
      font = { name = cfg.font, size = 11 },
      color = colors.overlay0,
    }),
    textAlignment = "center",
    frame = {
      x = cfg.padding,
      y = overlayHeight - cfg.padding - cfg.footerHeight + 8,
      w = overlayWidth - (cfg.padding * 2),
      h = 16,
    },
  }

  -- Show canvas
  canvas:level(hs.canvas.windowLevels.overlay)
  canvas:show()
  state.overlay = canvas
  state.visible = true

  -- Register ephemeral hotkeys for Hammerspoon commands
  state.hotkeys = {}

  table.insert(state.hotkeys, hs.hotkey.bind({}, "escape", function()
    M.hide()
  end))

  for _, cmd in ipairs(hsFlat) do
    table.insert(state.hotkeys, hs.hotkey.bind({}, cmd.key:lower(), function()
      M.hide()
      if cmd.action then
        hs.timer.doAfter(0.1, cmd.action)
      end
    end))
  end

  -- Eventtap: block non-bound keys while overlay is visible
  state.eventTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    local keyCode = event:getKeyCode()
    local char = hs.keycodes.map[keyCode]
    if char and boundKeys[char] then
      return false
    end
    return true
  end)
  state.eventTap:start()
end

function M.toggle()
  if state.visible then
    M.hide()
  else
    M.show()
  end
end

return M
