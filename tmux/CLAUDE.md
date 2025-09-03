# Tmux Claude Code Integration

This directory contains a sophisticated tmux status bar system that integrates directly with Claude Code sessions, providing real-time visual feedback about your Claude workflow.

## System Overview

The tmux integration creates an adaptive status bar that:
- **Switches automatically** between 1-line and 2-line modes based on Claude session activity
- **Tracks multiple Claude sessions** across different projects simultaneously  
- **Shows real-time status** with emoji indicators (🚀 starting, 🧠 working, 🤔 asking, ⏳ waiting, 💤 idle)
- **Groups sessions by project** to handle tmux session renames intelligently
- **Provides system monitoring** with CPU and memory usage

## Architecture

```
Claude Code → Hooks → track-session.sh → status.json → status-line-claude.sh → Tmux Display
```

### Key Components

**Configuration Files:**
- `custom-status.conf` - Main tmux configuration with adaptive 2-line status
- `tmux.conf` - Sources the custom status configuration

**Status Scripts:**
- `scripts/status-line-main.sh` - Line 1: System info (CPU, memory, hostname)
- `scripts/status-line-claude.sh` - Line 2: Claude session tracking (conditional)
- `scripts/cpu-simple.sh` - Cached CPU monitoring
- `scripts/mem-simple.sh` - Cached memory monitoring  
- `scripts/host-icon.sh` - System icon detection
- `scripts/hostname-display.sh` - Smart hostname formatting

**Hook Integration:**
- Connects to `~/.claude.global/hooks/track-session.sh` (session state management)
- Connects to `~/.claude.global/hooks/notification-handler.sh` (permission requests)
- Uses `~/.claude/sessions/status.json` as central state store

## How It Works

### Claude Code Hook Integration

The system leverages Claude Code's hook system defined in `~/.claude.global/settings.json`:

```json
{
  "hooks": {
    "SessionStart": "track-session.sh start → status: starting 🚀",
    "PostToolUse": "track-session.sh activity → status: working 🧠", 
    "Notification": "notification-handler.sh → track-session.sh permission → status: asking 🤔",
    "Stop": "track-session.sh stop → status: waiting ⏳",
    "SessionEnd": "track-session.sh end → status: idle 💤"
  }
}
```

### Session State Flow

1. **Start Claude** → `SessionStart` hook → JSON updated → Status shows 🚀 → Tmux switches to 2-line mode
2. **Send command** → `PostToolUse` hook → JSON updated → Status shows 🧠 
3. **Claude needs permission** → `Notification` hook → JSON updated → Status shows 🤔
4. **Task completes** → `Stop` hook → JSON updated → Status shows ⏳
5. **End session** → `SessionEnd` hook → JSON updated → Status shows 💤 → Eventually switches to 1-line mode

### Status File Format

Central state stored in `~/.claude/sessions/status.json`:

```json
{
  "sessions": [
    {
      "tmux_session": "dotfiles",
      "tmux_window": 1,
      "tmux_pane": 0,
      "project_dir": "/Users/user/.dotfiles",
      "status": "working",
      "last_activity": "2024-09-02T21:30:00Z",
      "claude_session_id": "session-123",
      "created_at": "2024-09-02T21:25:00Z"
    }
  ]
}
```

### Smart Session Grouping

Sessions are grouped by `project_dir` rather than tmux session name:
- Handles tmux session renames gracefully
- Shows current tmux session name but maintains Claude session continuity
- Prevents duplicate entries when switching tmux session names
- Highlights current session in blue, others in gray

## Key Files & Their Purpose

### `custom-status.conf`
Main configuration that sets up the adaptive status bar:
- Defines 2-line status with conditional display
- Configures window status formatting with zoom indicators
- Sets up automatic refresh hooks
- Provides toggle bindings (`Prefix + S`, `Prefix + R`)

### `scripts/status-line-claude.sh`
Critical script that determines whether to show Claude line:
- Returns empty output when no active sessions → triggers 1-line mode  
- Returns formatted session info when sessions exist → triggers 2-line mode
- Groups sessions by project directory
- Handles session status prioritization (asking > working > waiting > idle)
- Shows active session count

### `scripts/status-line-main.sh`
System information display for line 1:
- CPU usage via optimized `cpu-simple.sh`
- Memory usage via optimized `mem-simple.sh`  
- Hostname display for context
- Uses Catppuccin Mocha color scheme

### Performance Scripts
All monitoring scripts use cached values to prevent performance impact:
- **CPU**: 3-second cache, cross-platform (macOS/Linux)
- **Memory**: 5-second cache, intelligent fallbacks
- **Host Icon**: 1-hour cache, expensive `system_profiler` operations
- **Hostname**: 5-minute cache, smart detection

## Troubleshooting

### Status Bar Not Updating
```bash
# Check if Claude sessions are being tracked
cat ~/.claude/sessions/status.json | jq '.'

# Test status line scripts individually
~/.dotfiles/tmux/scripts/status-line-claude.sh
~/.dotfiles/tmux/scripts/status-line-main.sh

# Verify tmux configuration
tmux show-options -g status
tmux show-options -g status-format
```

### Claude Sessions Not Showing
```bash
# Verify hook permissions
ls -la ~/.claude.global/hooks/
chmod +x ~/.claude.global/hooks/*.sh

# Test session tracking manually
~/.claude.global/hooks/track-session.sh start
~/.claude.global/hooks/track-session.sh activity
~/.claude.global/hooks/track-session.sh end

# Check hook logs
tail -f ~/.claude/sessions/tracker.log
```

### Performance Issues
```bash
# Check cache files
ls -la ~/.cache/tmux-*

# Test script performance
time ~/.dotfiles/tmux/scripts/cpu-simple.sh
time ~/.dotfiles/tmux/scripts/mem-simple.sh

# Verify dependencies
command -v jq && echo "jq: OK"
command -v tmux && echo "tmux: OK"
```

## Manual Controls

**Toggle Claude Status Line:**
- `Prefix + S` - Hide/show Claude sessions line regardless of activity

**Reload Configuration:**  
- `Prefix + R` - Reload tmux status configuration

**Debug Information:**
- `Prefix + I` - Show status debug info (line count, session data)

## Maintenance

### Cache Management
Cache files are stored in `~/.cache/` with appropriate TTLs:
- CPU: 3 seconds (`tmux-cpu`)
- Memory: 5 seconds (`tmux-mem`)  
- Host icon: 1 hour (`tmux-host-icon`)
- Hostname: 5 minutes (`tmux-hostname`)

### Session Cleanup
- Sessions older than 24 hours are automatically cleaned up
- Sessions with no activity for 5+ minutes switch to "idle" status
- Idle sessions don't trigger 2-line mode

### Dependencies
- **tmux 3.0+** (3.3+ recommended for advanced formatting)
- **jq** (JSON processing for session tracking)
- **bash 4.0+** (advanced regex, associative arrays)

## Status Icons Reference

| Icon | Status | Meaning |
|------|--------|---------|
| 🚀 | starting | Claude session initializing |
| 🧠 | working | Active Claude processing |
| 🤔 | asking | Awaiting user permission |
| ⏳ | waiting | Ready for next command |
| 💤 | idle | No recent activity |
| 🔍 | - | Window zoomed indicator |

## Color Scheme (Catppuccin Mocha)

- **Blue (#89b4fa)**: Active elements, current session
- **Green (#a6e3a1)**: Memory info
- **Yellow (#f9e2af)**: CPU info  
- **Dim (#6c7086)**: Inactive elements
- **Text (#cdd6f4)**: Primary text
- **Surface (#313244)**: Separators

---

This integration provides seamless real-time feedback about your Claude Code workflow directly in your tmux status bar, helping you stay aware of session states and system performance.