# shellcheck shell=bash
# fzf-lib.sh — shared Catppuccin Mocha colors for tmux fzf-tmux pickers.
#
# Reads TMUX_* env vars set by tmux/custom-status.conf (single source of
# truth per tmux/CLAUDE.md) with hex fallbacks for standalone testing.
#
# Note: hl / header / hl+ use TMUX_RED. In the Catppuccin palette this
# hex (#f38ba8) is canonically "Pink"; the project exports it as TMUX_RED.

FZF_CATPPUCCIN_COLORS="\
bg+:${TMUX_SURFACE:-#313244},\
bg:${TMUX_BG:-#1e1e2e},\
spinner:${TMUX_ROSEWATER:-#f5e0dc},\
hl:${TMUX_RED:-#f38ba8},\
fg:${TMUX_TEXT:-#cdd6f4},\
header:${TMUX_RED:-#f38ba8},\
info:${TMUX_LAVENDER:-#cba6f7},\
pointer:${TMUX_ROSEWATER:-#f5e0dc},\
marker:${TMUX_ROSEWATER:-#f5e0dc},\
fg+:${TMUX_TEXT:-#cdd6f4},\
prompt:${TMUX_LAVENDER:-#cba6f7},\
hl+:${TMUX_RED:-#f38ba8}"
export FZF_CATPPUCCIN_COLORS
