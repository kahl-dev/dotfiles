# Remote Bridge Integration
# Provides SSH tunnel configuration and utilities

# Export port for CLI tools
export REMOTE_BRIDGE_PORT=8377

# Helper function to check if Remote Bridge is available
remote-bridge-check() {
    curl -sf "http://localhost:${REMOTE_BRIDGE_PORT}/health" >/dev/null 2>&1
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
        echo "2. SSH tunnel not configured (add 'RemoteForward $REMOTE_BRIDGE_PORT localhost:$REMOTE_BRIDGE_PORT' to SSH config)"
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

# Add SSH config helper
remote-bridge-ssh-config() {
    cat << 'EOF'
# Add this to your ~/.ssh/config on your LOCAL machine:

Host *
    # Remote Bridge tunnel
    RemoteForward 8377 localhost:8377
    SetEnv REMOTE_BRIDGE_PORT=8377
    
    # Optional: Keep connection alive
    ServerAliveInterval 60
    ServerAliveCountMax 3

# For specific hosts, you can override:
# Host myserver
#     RemoteForward 8377 localhost:8377
#     SetEnv REMOTE_BRIDGE_PORT=8377
EOF
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