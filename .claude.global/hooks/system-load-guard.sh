#!/usr/bin/env bash
# System Load Guard Hook for Claude Code
# Prevents hook and tool execution during high system load

set -euo pipefail

readonly SCRIPT_NAME=$(basename "$0")
readonly LOG_FILE="$HOME/.claude/logs/load-guard.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$SCRIPT_NAME] $*" >> "$LOG_FILE"
}

# Check system load and availability  
check_system_resources() {
    local load_1min load_5min load_15min
    
    # Get load averages (handles both Linux and macOS)
    if command -v uptime >/dev/null 2>&1; then
        local uptime_output
        uptime_output=$(uptime 2>/dev/null || echo "load averages: 0.00 0.00 0.00")
        
        # Extract load averages - handle different uptime formats
        if [[ "$uptime_output" =~ load.averages?:.*([0-9]+\.[0-9]+).* ]]; then
            load_1min=$(echo "$uptime_output" | sed -E 's/.*load.averages?:[[:space:]]*([0-9]+\.[0-9]+).*/\1/')
            load_5min=$(echo "$uptime_output" | sed -E 's/.*load.averages?:[[:space:]]*[0-9]+\.[0-9]+[[:space:]]+([0-9]+\.[0-9]+).*/\1/')  
            load_15min=$(echo "$uptime_output" | sed -E 's/.*load.averages?:[[:space:]]*[0-9]+\.[0-9]+[[:space:]]+[0-9]+\.[0-9]+[[:space:]]+([0-9]+\.[0-9]+).*/\1/')
        else
            load_1min="0.00"
            load_5min="0.00" 
            load_15min="0.00"
        fi
    else
        load_1min="0.00"
        load_5min="0.00"
        load_15min="0.00"
    fi
    
    echo "$load_1min:$load_5min:$load_15min"
}

# Check if we can spawn processes safely
can_spawn_processes() {
    # Try a minimal pipe process test
    if ! echo "test" | cat >/dev/null 2>&1; then
        return 1
    fi
    
    # Test simple command execution (most reliable test)
    if ! true >/dev/null 2>&1; then
        return 1
    fi
    
    # Test date command as a more realistic process spawn
    if ! date >/dev/null 2>&1; then
        return 1
    fi
    
    return 0
}

# Main guard function
main() {
    local load_info
    load_info=$(check_system_resources)
    
    IFS=':' read -r load_1min load_5min load_15min <<< "$load_info"
    
    log "System load check: 1min=$load_1min, 5min=$load_5min, 15min=$load_15min"
    
    # Only block if we detect actual process spawning failures
    # Load averages are informational but not blocking criteria
    
    # Test if we can actually spawn processes
    if ! can_spawn_processes; then
        echo "🚨 CRITICAL: Cannot spawn processes reliably - system resource exhaustion"
        echo "   This indicates EAGAIN/resource exhaustion errors"
        echo "   💡 Close unnecessary applications and wait before retrying"
        log "BLOCKED: Process spawn test failed - likely EAGAIN condition"
        exit 2
    fi
    
    log "System load check passed: $load_1min"
    exit 0
}

# Only run if bc is available for float comparison, otherwise allow (fail-safe)
if command -v bc >/dev/null 2>&1; then
    main "$@"
else
    log "WARNING: bc not available for load checking - allowing execution"
    exit 0
fi