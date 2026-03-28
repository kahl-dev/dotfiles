-- AeroSpace Keybinding Cheatsheet
-- Catppuccin Mocha themed overlay triggered from AeroSpace via hs CLI

local M = {}

local colors = require("modules.catppuccin")

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Binding Definitions                                         ║
-- ╚══════════════════════════════════════════════════════════════╝

local leftColumn = {
  {
    title = "Focus",
    color = colors.blue,
    bindings = {
      { key = "alt h/j/k/l", desc = "Focus left/down/up/right" },
      { key = "alt ;",        desc = "Back and forth" },
    }
  },
  {
    title = "Move Window",
    color = colors.lavender,
    bindings = {
      { key = "alt shift h/j/k/l", desc = "Move left/down/up/right" },
    }
  },
  {
    title = "Swap Position",
    color = colors.mauve,
    bindings = {
      { key = "alt ctrl h/j/k/l", desc = "Swap left/down/up/right" },
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

local rightColumn = {
  {
    title = "Workspace",
    color = colors.blue,
    bindings = {
      { key = "alt 1..9", desc = "Switch to workspace" },
      { key = "alt shift 1..9", desc = "Move window to workspace" },
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
      { key = "hyper tab",     desc = "Move workspace to monitor" },
    }
  },
  {
    title = "Modes",
    color = colors.mauve,
    bindings = {
      { key = "hyper ;", desc = "Service mode" },
      { key = "hyper a", desc = "Apps mode" },
      { key = "alt ?",   desc = "This cheatsheet" },
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
-- ║  Rendering                                                   ║
-- ╚══════════════════════════════════════════════════════════════╝

local state = {
  overlay = nil,
  eventTap = nil,
  visible = false,
}

local config = {
  font = "Menlo",
  titleSize = 14,
  bindingSize = 13,
  keyWidth = 180,
  descWidth = 200,
  columnGap = 40,
  groupGap = 16,
  padding = 24,
  cornerRadius = 12,
  lineHeight = 20,
  titleLineHeight = 28,
}

local function buildStyledColumn(groups, startY)
  local elements = {}
  local currentY = startY

  for groupIndex, group in ipairs(groups) do
    -- Group title
    local titleText = hs.styledtext.new(group.title, {
      font = { name = config.font, size = config.titleSize },
      color = group.color,
    })
    table.insert(elements, { text = titleText, y = currentY })
    currentY = currentY + config.titleLineHeight

    -- Bindings
    for _, binding in ipairs(group.bindings) do
      local keyText = hs.styledtext.new(binding.key, {
        font = { name = config.font, size = config.bindingSize },
        color = colors.lavender,
      })
      local descText = hs.styledtext.new(binding.desc, {
        font = { name = config.font, size = config.bindingSize },
        color = colors.text,
      })
      table.insert(elements, { text = keyText, y = currentY, isKey = true })
      table.insert(elements, { text = descText, y = currentY, isDesc = true })
      currentY = currentY + config.lineHeight
    end

    -- Gap between groups
    if groupIndex < #groups then
      currentY = currentY + config.groupGap
    end
  end

  return elements, currentY
end

local function calculateColumnHeight(groups)
  local height = 0
  for groupIndex, group in ipairs(groups) do
    height = height + config.titleLineHeight
    height = height + (#group.bindings * config.lineHeight)
    if groupIndex < #groups then
      height = height + config.groupGap
    end
  end
  return height
end

function M.show()
  if state.visible then return end

  local screen = hs.screen.mainScreen()
  local screenFrame = screen:frame()

  -- Calculate dimensions
  local leftHeight = calculateColumnHeight(leftColumn)
  local rightHeight = calculateColumnHeight(rightColumn)

  local contentHeight = math.max(leftHeight, rightHeight)

  -- Title bar height
  local titleBarHeight = 40

  -- Total overlay dimensions
  local footerHeight = 44
  local columnWidth = config.keyWidth + config.descWidth
  local overlayWidth = (columnWidth * 2) + config.columnGap + (config.padding * 2)
  local overlayHeight = contentHeight + titleBarHeight + footerHeight + (config.padding * 2)

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
    roundedRectRadii = { xRadius = config.cornerRadius, yRadius = config.cornerRadius },
  }

  -- Subtle border
  canvas[2] = {
    type = "rectangle",
    strokeColor = colors.surface0,
    fillColor = { alpha = 0 },
    strokeWidth = 1,
    roundedRectRadii = { xRadius = config.cornerRadius, yRadius = config.cornerRadius },
  }

  local elementIndex = 3

  -- Title
  local titleText = hs.styledtext.new("AeroSpace Keybindings", {
    font = { name = config.font, size = 16 },
    color = colors.text,
  })
  canvas[elementIndex] = {
    type = "text",
    text = titleText,
    textAlignment = "center",
    frame = { x = 0, y = config.padding, w = overlayWidth, h = 24 },
  }
  elementIndex = elementIndex + 1

  -- Separator line
  canvas[elementIndex] = {
    type = "rectangle",
    fillColor = colors.surface0,
    frame = {
      x = config.padding,
      y = config.padding + 30,
      w = overlayWidth - (config.padding * 2),
      h = 1,
    },
  }
  elementIndex = elementIndex + 1

  local contentStartY = titleBarHeight + config.padding

  -- Build left column
  local leftElements = buildStyledColumn(leftColumn, 0)
  local leftX = config.padding

  for _, element in ipairs(leftElements) do
    if element.isDesc then
      canvas[elementIndex] = {
        type = "text",
        text = element.text,
        textAlignment = "left",
        frame = {
          x = leftX + config.keyWidth,
          y = contentStartY + element.y,
          w = config.descWidth,
          h = config.lineHeight,
        },
      }
    else
      canvas[elementIndex] = {
        type = "text",
        text = element.text,
        textAlignment = "left",
        frame = {
          x = leftX,
          y = contentStartY + element.y,
          w = element.isKey and config.keyWidth or columnWidth,
          h = element.isKey and config.lineHeight or config.titleLineHeight,
        },
      }
    end
    elementIndex = elementIndex + 1
  end

  -- Build right column (main bindings + modes)
  local rightX = config.padding + columnWidth + config.columnGap
  local rightElements = buildStyledColumn(rightColumn, 0)

  for _, element in ipairs(rightElements) do
    if element.isDesc then
      canvas[elementIndex] = {
        type = "text",
        text = element.text,
        textAlignment = "left",
        frame = {
          x = rightX + config.keyWidth,
          y = contentStartY + element.y,
          w = config.descWidth,
          h = config.lineHeight,
        },
      }
    else
      canvas[elementIndex] = {
        type = "text",
        text = element.text,
        textAlignment = "left",
        frame = {
          x = rightX,
          y = contentStartY + element.y,
          w = element.isKey and config.keyWidth or columnWidth,
          h = element.isKey and config.lineHeight or config.titleLineHeight,
        },
      }
    end
    elementIndex = elementIndex + 1
  end

  -- Footer separator line
  canvas[elementIndex] = {
    type = "rectangle",
    fillColor = colors.surface0,
    frame = {
      x = config.padding,
      y = overlayHeight - config.padding - footerHeight,
      w = overlayWidth - (config.padding * 2),
      h = 1,
    },
  }
  elementIndex = elementIndex + 1

  -- Footer line 1: dismiss hint
  local footerLine1 = hs.styledtext.new("Press any key to dismiss", {
    font = { name = config.font, size = 11 },
    color = colors.overlay0,
  })
  canvas[elementIndex] = {
    type = "text",
    text = footerLine1,
    textAlignment = "center",
    frame = {
      x = config.padding,
      y = overlayHeight - config.padding - footerHeight + 10,
      w = overlayWidth - (config.padding * 2),
      h = 16,
    },
  }
  elementIndex = elementIndex + 1

  -- Footer line 2: cross-tool references
  local footerLine2 = hs.styledtext.new("hammerspoon: hyper .  ·  tmux: prefix ?", {
    font = { name = config.font, size = 11 },
    color = colors.overlay0,
  })
  canvas[elementIndex] = {
    type = "text",
    text = footerLine2,
    textAlignment = "center",
    frame = {
      x = config.padding,
      y = overlayHeight - config.padding - footerHeight + 26,
      w = overlayWidth - (config.padding * 2),
      h = 16,
    },
  }

  -- Show overlay
  canvas:level(hs.canvas.windowLevels.overlay)
  canvas:show()
  state.overlay = canvas
  state.visible = true

  -- Dismiss on any keypress
  state.eventTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function()
    M.hide()
    return true -- consume the key event
  end)
  state.eventTap:start()
end

function M.hide()
  if not state.visible then return end

  if state.overlay then
    state.overlay:hide()
    state.overlay:delete()
    state.overlay = nil
  end

  if state.eventTap then
    state.eventTap:stop()
    state.eventTap = nil
  end

  state.visible = false
end

function M.toggle()
  if state.visible then
    M.hide()
  else
    M.show()
  end
end

return M
