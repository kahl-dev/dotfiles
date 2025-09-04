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
    # Try a minimal process spawn test
    if ! echo "test" | cat >/dev/null 2>&1; then
        return 1
    fi
    
    # Check if pgrep works (critical for Claude Code background tasks)  
    if ! pgrep $$ >/dev/null 2>&1; then
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
    
    # Define thresholds based on typical system capacity
    # Adjust these based on your system specs
    local CRITICAL_LOAD="10.0"
    local HIGH_LOAD="5.0" 
    local MEDIUM_LOAD="3.0"
    
    # Check if load is critical
    if (( $(echo "$load_1min > $CRITICAL_LOAD" | bc 2>/dev/null || echo 0) )); then
        echo "🚨 CRITICAL: System load too high ($load_1min) - blocking to prevent system instability"
        echo "   Current load: $load_1min (critical threshold: $CRITICAL_LOAD)"
        echo "   💡 Wait for system load to decrease before running Claude Code tools"
        echo "   Check with: uptime"
        log "BLOCKED: Critical system load $load_1min > $CRITICAL_LOAD"
        exit 2
    fi
    
    # Check if load is high and we're running background tasks
    if (( $(echo "$load_1min > $HIGH_LOAD" | bc 2>/dev/null || echo 0) )); then
        # Check if this is a background task request
        if [[ "${CLAUDE_TOOL_NAME:-}" == "Bash" ]] && echo "$*" | grep -q "run_in_background"; then
            echo "⚠️  HIGH LOAD WARNING: System load is high ($load_1min)"
            echo "   Background tasks may be unreliable at this load level"
            echo "   Consider waiting or running the command directly in a terminal"
            log "WARNING: High load $load_1min during background task request"
        fi
    fi
    
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