# Remote Bridge Integration
# Provides SSH tunnel configuration and utilities

# Shared endpoint resolution (also sourced by the bash clients: rclip, ropen,
# rnotify, rtime, robsidian). Sets BRIDGE_BASE_URL (and
# BRIDGE_SOCKET_PATH on non-Darwin) — see lib/bridge-endpoint.sh for the
# contract. A constant socket path needs no tmux environment propagation.
[[ -f "$DOTFILES/remote-bridge/lib/bridge-endpoint.sh" ]] && source "$DOTFILES/remote-bridge/lib/bridge-endpoint.sh"

resolve_bridge_endpoint

# Helper function to check if Remote Bridge is available.
remote-bridge-check() {
    # Fast timeout to not block shell startup
    bridge_curl -sf --connect-timeout 0.5 --max-time 1 "${BRIDGE_BASE_URL}/health" >/dev/null 2>&1
}

# Probes the agent-tunnel Unix socket independently of the bridge socket:
# responsive (agent answers), unresponsive (socket file present but nothing
# listening — a stale tunnel), or absent (socket file does not exist at all).
remote-bridge-agent-status() {
    local agent_socket="$HOME/.ssh/agent-tunnel.sock"

    if [[ ! -S "$agent_socket" ]]; then
        echo "absent"
        return 0
    fi

    if SSH_AUTH_SOCK="$agent_socket" timeout 1 ssh-add -l >/dev/null 2>&1; then
        echo "responsive"
    else
        local exit_code=$?
        case $exit_code in
            1) echo "responsive" ;;
            *) echo "unresponsive" ;;
        esac
    fi
}

# Status function for Remote Bridge
remote-bridge-status() {
    echo "=== Remote Bridge Status ==="
    if [[ -n "${BRIDGE_SOCKET_PATH:-}" ]]; then
        echo "Socket path: $BRIDGE_SOCKET_PATH"
    fi

    if remote-bridge-check; then
        echo "[ok] Remote Bridge is accessible"

        # Get health info
        local health
        health=$(bridge_curl -s "${BRIDGE_BASE_URL}/health")
        if [[ -n "$health" ]]; then
            echo "$health" | jq -r '"Version: \(.version)\nStatus: \(.status)\nUptime: \(.uptime)s"' 2>/dev/null || echo "Service is responding"
        fi
    else
        echo "[error] Remote Bridge is not accessible"
        echo
        if [[ -n "${BRIDGE_SOCKET_PATH:-}" && ! -S "$BRIDGE_SOCKET_PATH" ]]; then
            echo "Socket file does not exist."
        fi
        echo "Possible causes:"
        echo "1. Service not running on local machine"
        echo "2. Tunnel not active — start it from the Mac: sm <host>"
        echo "3. Host not opted in — add 'Tag remote-bridge' to its SSH config"
    fi

    if [[ "$BRIDGE_ON_DARWIN" != "1" ]]; then
        echo
        echo "=== Agent Tunnel Status ==="
        case "$(remote-bridge-agent-status)" in
            responsive)
                echo "[ok] Agent socket is responsive ($HOME/.ssh/agent-tunnel.sock)"
                ;;
            unresponsive)
                echo "[warning] Agent socket exists but is unresponsive: $HOME/.ssh/agent-tunnel.sock"
                ;;
            absent)
                echo "[error] Agent socket not present: $HOME/.ssh/agent-tunnel.sock"
                ;;
        esac
    fi

    # Check if we're in SSH session
    if [[ -n "${SSH_CLIENT:-}" ]]; then
        echo
        echo "SSH Session Info:"
        echo "- Client: $SSH_CLIENT"
        echo "- Connection: ${SSH_CONNECTION:-}"
    fi
}

# Alias for convenience
alias rb-status='remote-bridge-status'

# Function to test all Remote Bridge features
remote-bridge-test() {
    echo "=== Testing Remote Bridge Features ==="
    
    if ! remote-bridge-check; then
        echo "[error] Remote Bridge not available"
        return 1
    fi

    echo "[ok] Service is accessible"
    
    # Test clipboard
    echo -n "Testing clipboard... "
    if echo "Remote Bridge test at $(date)" | rclip >/dev/null 2>&1; then
        echo "ok"
    else
        echo "failed"
    fi
    
    # Test notification
    echo -n "Testing notifications... "
    if rnotify "Remote Bridge test notification" --type test >/dev/null 2>&1; then
        echo "ok"
    else
        echo "failed"
    fi
    
    echo
    echo "To test URL opening, run: ropen 'https://github.com'"
}

# Info message for interactive sessions
if [[ -o interactive ]] && [[ -n "${SSH_CLIENT:-}" ]]; then
    # Check if Remote Bridge is available
    if remote-bridge-check; then
        # Silent - Remote Bridge is working
        :
    else
        # Only show message if tools exist
        if command -v rclip >/dev/null 2>&1; then
            echo "Remote Bridge not detected. Start the tunnel from the Mac: sm <host>"
        fi
    fi
fi
