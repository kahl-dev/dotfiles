# Tmux Configuration

This directory contains the tmux configuration that ships with these dotfiles. It focuses on a fast, single-line status bar, responsive key bindings, and a minimal plugin stack.

## Files
- `tmux.conf` – primary configuration loaded by tmux
- `tmux.remote.conf` – overrides for SSH / remote sessions
- `custom-status.conf` – shared status-line styling and theme variables
- `scripts/` – helper scripts that power the status bar and popups
- `cheatsheet.md` – quick reference surfaced via `<prefix> ?`

## Daily Tasks
- Reload configuration: `prefix` + `r`
- Toggle zoom: `prefix` + `z`
- Open cheatsheet: `prefix` + `?`

Full documentation, including color palette, plugin notes, and troubleshooting, lives in `docs/tmux.md`.
