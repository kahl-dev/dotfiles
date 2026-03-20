# Remote Bridge Integration
# Provides SSH tunnel configuration and utilities

# Compute per-user bridge port from a username
# Deterministic: same username always produces the same port (POSIX cksum)
# Range: 49152–65534 (dynamic/private ports, avoids well-known services)
_remote_bridge_user_port() {
    local username="$1"
    echo $(( 49152 + $(printf '%s' "$username" | cksum | cut -d' ' -f1) % 16383 ))
}

# Export port for CLI tools
# Remote SSH sessions: unique port per user (prevents cross-talk on shared servers)
# Local machine: fixed port 8377 (where the bridge service listens)
if [[ -n "${SSH_CLIENT:-}" ]]; then
    export REMOTE_BRIDGE_PORT=$(_remote_bridge_user_port "$USER")
else
    export REMOTE_BRIDGE_PORT=8377
fi

# Add Remote Bridge CLI tools to PATH
if [[ -d "$DOTFILES/remote-bridge/bin" ]]; then
    export PATH="$DOTFILES/remote-bridge/bin:$PATH"
fi

# Helper function to check if Remote Bridge is available
remote-bridge-check() {
    # Fast timeout to not block shell startup
    curl -sf --connect-timeout 0.5 --max-time 1 "http://localhost:${REMOTE_BRIDGE_PORT}/health" >/dev/null 2>&1
}

# Status function for Remote Bridge
remote-bridge-status() {
    echo "=== Remote Bridge Status ==="
    
    if remote-bridge-check; then
        echo "✅ Remote Bridge is accessible on port $REMOTE_BRIDGE_PORT"
        
        # Get health info
        local health=$(curl -s "http://localhost:${REMOTE_BRIDGE_PORT}/health")
        if [[ -n "$health" ]]; then
            echo "$health" | jq -r '"Version: \(.version)\nStatus: \(.status)\nUptime: \(.uptime)s"' 2>/dev/null || echo "Service is responding"
        fi
    else
        echo "❌ Remote Bridge is not accessible on port $REMOTE_BRIDGE_PORT"
        echo
        echo "Possible causes:"
        echo "1. Service not running on local machine"
        echo "2. SSH tunnel not configured (add 'RemoteForward $REMOTE_BRIDGE_PORT localhost:8377' to SSH config)"
        echo "3. Connected without tunnel forwarding"
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
        echo "❌ Remote Bridge not available"
        return 1
    fi
    
    echo "✅ Service is accessible"
    
    # Test clipboard
    echo -n "Testing clipboard... "
    if echo "Remote Bridge test at $(date)" | rclip >/dev/null 2>&1; then
        echo "✅"
    else
        echo "❌"
    fi
    
    # Test notification
    echo -n "Testing notifications... "
    if rnotify "Remote Bridge test notification" --type test >/dev/null 2>&1; then
        echo "✅"
    else
        echo "❌"
    fi
    
    echo
    echo "To test URL opening, run: ropen 'https://github.com'"
}

# SSH config helper — outputs RemoteForward line with per-user port
# Usage: remote-bridge-ssh-config [hostname]
#   With hostname: resolves remote username from ssh -G
#   Without: uses $USER
remote-bridge-ssh-config() {
    local remote_user remote_port host="$1"

    if [[ -n "$host" ]]; then
        remote_user=$(ssh -G "$host" 2>/dev/null | awk '/^user /{print $2}')
        if [[ -z "$remote_user" ]]; then
            echo "remote-bridge-ssh-config: could not resolve user for ${host}" >&2
            return 1
        fi
    else
        remote_user="$USER"
    fi

    remote_port=$(_remote_bridge_user_port "$remote_user")

    echo "# Remote Bridge SSH config"
    echo "# Remote user: ${remote_user}"
    echo "# Bridge port: ${remote_port} (derived from username)"
    echo "#"
    if [[ -n "$host" ]]; then
        echo "# Add to your SSH config for host ${host}:"
        echo ""
        echo "Host ${host}"
        echo "    RemoteForward ${remote_port} localhost:8377"
    else
        echo "# Add to your SSH config per host:"
        echo ""
        echo "RemoteForward ${remote_port} localhost:8377"
    fi
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
            echo "💡 Remote Bridge not detected. Add tunnel to SSH config: remote-bridge-ssh-config"
        fi
    fi
fi