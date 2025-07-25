#!/usr/bin/env bash

# Pushover notification script for Claude Code
# Sends notifications when Claude needs user interaction

# Debug logging
echo "$(date): Notification hook triggered" >> /tmp/claude-hook-debug.log
echo "$(date): Environment check - USER_KEY: ${PUSHOVER_USER_KEY:+set} TOKEN: ${PUSHOVER_APP_TOKEN:+set}" >> /tmp/claude-hook-debug.log

# Load Pushover credentials from environment or config file
# Environment variables take precedence
if [ -z "$PUSHOVER_USER_KEY" ] || [ -z "$PUSHOVER_APP_TOKEN" ]; then
    # Only load config file if env vars are not set
    if [ -f "$HOME/.pushover" ]; then
        source "$HOME/.pushover"
    fi
fi

# Check if credentials are available
if [ -z "$PUSHOVER_USER_KEY" ] || [ -z "$PUSHOVER_APP_TOKEN" ]; then
    echo "Error: Pushover credentials not found" >&2
    echo "Please set PUSHOVER_USER_KEY and PUSHOVER_APP_TOKEN as environment variables" >&2
    echo "or create ~/.pushover with these values" >&2
    exit 1
fi

# Get context information
HOSTNAME=$(hostname -s 2>/dev/null || echo "unknown")
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
SESSION_INFO=""

# Check if we're in tmux
if [ -n "$TMUX" ]; then
    TMUX_SESSION=$(tmux display-message -p '#S' 2>/dev/null || echo "")
    TMUX_WINDOW=$(tmux display-message -p '#W' 2>/dev/null || echo "")
    if [ -n "$TMUX_SESSION" ]; then
        SESSION_INFO=" [tmux: $TMUX_SESSION:$TMUX_WINDOW]"
    fi
fi

# Check if we're in SSH
if [ -n "$SSH_CONNECTION" ]; then
    SESSION_INFO="$SESSION_INFO [SSH]"
fi

# Build notification message
TITLE="Claude Code - Attention Required"
MESSAGE="Claude needs your input on $HOSTNAME$SESSION_INFO at $TIMESTAMP"

# Optional: Add working directory info
if [ -n "$PWD" ]; then
    WORK_DIR=$(basename "$PWD")
    MESSAGE="$MESSAGE (in $WORK_DIR)"
fi

# Send notification via Pushover API
response=$(curl -s \
    --form-string "token=$PUSHOVER_APP_TOKEN" \
    --form-string "user=$PUSHOVER_USER_KEY" \
    --form-string "title=$TITLE" \
    --form-string "message=$MESSAGE" \
    --form-string "priority=1" \
    --form-string "sound=intermission" \
    https://api.pushover.net/1/messages.json)

# Check if notification was sent successfully
if echo "$response" | grep -q '"status":1'; then
    echo "Pushover notification sent successfully"
else
    echo "Failed to send Pushover notification: $response" >&2
    # Fallback to terminal bell
    echo -e "\a"
fi