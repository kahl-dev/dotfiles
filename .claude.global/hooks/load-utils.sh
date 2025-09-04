#!/usr/bin/env bash
# Shared load checking utilities for Claude Code hooks

# Robust load comparison that handles edge cases
compare_load() {
    local current_load="$1"
    local threshold="$2"
    
    # Try bc first (most accurate)
    if command -v bc >/dev/null 2>&1; then
        local result
        result=$(echo "$current_load > $threshold" | bc 2>/dev/null)
        if [[ "$result" == "1" ]]; then
            return 0  # Load exceeds threshold
        elif [[ "$result" == "0" ]]; then
            return 1  # Load is acceptable
        fi
        # Fall through to backup method if bc fails
    fi
    
    # Backup: Integer comparison (less precise but reliable)
    local current_int="${current_load%%.*}"
    local threshold_int="${threshold%%.*}"
    
    if [[ "$current_int" -gt "$threshold_int" ]]; then
        return 0  # Load likely exceeds threshold
    else
        return 1  # Load likely acceptable
    fi
}

# Export for use in other scripts
export -f compare_load