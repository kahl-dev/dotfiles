#!/bin/bash
# Update JankyBorders active color based on focused window layout
# Triggered by AeroSpace on-focus-changed callback

layout=$(aerospace list-windows --focused --format '%{window-layout}' 2>/dev/null)

if [ "$layout" = "floating" ]; then
  borders active_color=0xfffab387  # Catppuccin Peach — floating
else
  borders active_color=0xff89b4fa  # Catppuccin Blue — tiling
fi
