# SSH Agent utilities for remote sessions
# Only loads when SSH_CLIENT is set (remote sessions)

# Exit if not in SSH session
[[ -z "${SSH_CLIENT:-}" ]] && return

# SSH Agent Keeper management
ssh-agent-start() {
    if [[ -f "$HOME/.ssh/ssh-agent-keeper.pid" ]]; then
        local pid=$(cat "$HOME/.ssh/ssh-agent-keeper.pid")
        if kill -0 "$pid" 2>/dev/null; then
            echo "SSH agent keeper already running (PID: $pid)"
            return 0
        fi
    fi
    
    if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
        echo "Cannot start SSH agent keeper: SSH_AUTH_SOCK not set"
        return 1
    fi
    
    echo "Starting SSH agent keeper..."
    nohup "$HOME/.dotfiles/bin/ssh-agent-keeper" >/dev/null 2>&1 &
    disown
    
    # Wait a moment to check if it started successfully
    sleep 1
    if [[ -f "$HOME/.ssh/ssh-agent-keeper.pid" ]]; then
        local pid=$(cat "$HOME/.ssh/ssh-agent-keeper.pid")
        if kill -0 "$pid" 2>/dev/null; then
            echo "SSH agent keeper started (PID: $pid)"
        else
            echo "SSH agent keeper failed to start"
            return 1
        fi
    else
        echo "SSH agent keeper failed to start"
        return 1
    fi
}

ssh-agent-stop() {
    if [[ -f "$HOME/.ssh/ssh-agent-keeper.pid" ]]; then
        local pid=$(cat "$HOME/.ssh/ssh-agent-keeper.pid")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            echo "SSH agent keeper stopped"
        else
            echo "SSH agent keeper not running"
        fi
        rm -f "$HOME/.ssh/ssh-agent-keeper.pid"
    else
        echo "SSH agent keeper not running"
    fi
}

ssh-agent-status() {
    echo "=== SSH Agent Status ==="
    
    # Check if keeper is running
    if [[ -f "$HOME/.ssh/ssh-agent-keeper.pid" ]]; then
        local pid=$(cat "$HOME/.ssh/ssh-agent-keeper.pid")
        if kill -0 "$pid" 2>/dev/null; then
            echo "SSH agent keeper: RUNNING (PID: $pid)"
        else
            echo "SSH agent keeper: STOPPED (stale PID file)"
        fi
    else
        echo "SSH agent keeper: STOPPED"
    fi
    
    # Check SSH_AUTH_SOCK
    echo "SSH_AUTH_SOCK: ${SSH_AUTH_SOCK:-<not set>}"
    
    # Check symlink
    if [[ -L "$HOME/.ssh/ssh_auth_sock" ]]; then
        local target=$(readlink "$HOME/.ssh/ssh_auth_sock")
        echo "Symlink target: $target"
        if [[ -S "$target" ]]; then
            echo "Symlink status: VALID"
        else
            echo "Symlink status: BROKEN"
        fi
    else
        echo "Symlink: NOT FOUND"
    fi
    
    # Test SSH agent
    if [[ -n "${SSH_AUTH_SOCK:-}" ]]; then
        if ssh-add -l >/dev/null 2>&1; then
            echo "SSH agent test: SUCCESS"
            echo "Loaded keys:"
            ssh-add -l
        else
            echo "SSH agent test: FAILED"
        fi
    else
        echo "SSH agent test: SKIPPED (no SSH_AUTH_SOCK)"
    fi
}

ssh-agent-debug() {
    echo "=== SSH Agent Debug Info ==="
    echo "SSH_CLIENT: ${SSH_CLIENT:-<not set>}"
    echo "SSH_CONNECTION: ${SSH_CONNECTION:-<not set>}"
    echo "SSH_TTY: ${SSH_TTY:-<not set>}"
    echo "TMUX: ${TMUX:-<not set>}"
    echo
    
    ssh-agent-status
    
    echo
    echo "=== Recent logs ==="
    if [[ -f "$HOME/.ssh/ssh-agent-keeper.log" ]]; then
        tail -20 "$HOME/.ssh/ssh-agent-keeper.log"
    else
        echo "No log file found"
    fi
}

ssh-agent-logs() {
    if [[ -f "$HOME/.ssh/ssh-agent-keeper.log" ]]; then
        if [[ "$1" == "-f" ]]; then
            tail -f "$HOME/.ssh/ssh-agent-keeper.log"
        else
            cat "$HOME/.ssh/ssh-agent-keeper.log"
        fi
    else
        echo "No log file found"
    fi
}

# Aliases for convenience (using ssha- prefix to avoid conflicts with standard ssh- commands)
alias ssha-status='ssh-agent-status'
alias ssha-debug='ssh-agent-debug'
alias ssha-logs='ssh-agent-logs'

# Auto-start SSH agent keeper on login (only once per SSH session)
if [[ -o interactive ]]; then
    # Only start if not already running and we have a valid SSH_AUTH_SOCK
    if [[ -n "${SSH_AUTH_SOCK:-}" ]]; then
        if [[ ! -f "$HOME/.ssh/ssh-agent-keeper.pid" ]] || ! kill -0 "$(cat "$HOME/.ssh/ssh-agent-keeper.pid" 2>/dev/null)" 2>/dev/null; then
            # Start silently
            nohup "$HOME/.dotfiles/bin/ssh-agent-keeper" >/dev/null 2>&1 &
            disown
        fi
    fi
fi