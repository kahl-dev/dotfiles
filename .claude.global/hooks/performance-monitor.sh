#!/usr/bin/env bash

#!/usr/bin/env bash

HOOK_NAME="$(basename "$0")"
START_TIME=$(date +%s.%N)
PERFORMANCE_LOG="$HOME/.claude/logs/hook_performance.log"

INITIAL_MEMORY=$(free -m | awk 'NR==2{printf "%.1f", $3*100/$2}' 2>/dev/null || echo "0")
INITIAL_CPU=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$3+$4+$5)} END {print usage}' 2>/dev/null || echo "0")

log_performance() {
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $START_TIME" | bc 2>/dev/null || echo "unknown")
    local timestamp=$(date -Iseconds)
    
    local final_memory=$(free -m | awk 'NR==2{printf "%.1f", $3*100/$2}' 2>/dev/null || echo "0")
    local final_cpu=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$3+$4+$5)} END {print usage}' 2>/dev/null || echo "0")
    
    local perf_entry
    perf_entry=$(jq -n \
        --arg timestamp "$timestamp" \
        --arg hook "$HOOK_NAME" \
        --arg duration "$duration" \
        --arg files "${CLAUDE_MODIFIED_FILES:-none}" \
        --arg session "${CLAUDE_SESSION_ID:-unknown}" \
        --arg memory_start "$INITIAL_MEMORY" \
        --arg memory_end "$final_memory" \
        --arg cpu_start "$INITIAL_CPU" \
        --arg cpu_end "$final_cpu" \
        '{
            timestamp: $timestamp,
            hook: $hook,
            duration_seconds: ($duration | tonumber),
            modified_files_count: (if $files == "none" then 0 else ($files | split("\n") | length) end),
            session_id: $session,
            memory_usage: {
                start_percent: ($memory_start | tonumber),
                end_percent: ($memory_end | tonumber)
            },
            cpu_usage: {
                start_percent: ($cpu_start | tonumber),
                end_percent: ($cpu_end | tonumber)
            }
        }')
    
    if [[ -f "$PERFORMANCE_LOG" ]]; then
        local existing_data=$(cat "$PERFORMANCE_LOG" 2>/dev/null || echo "[]")
        local updated_data=$(echo "$existing_data" | jq ". + [$perf_entry] | .[-100:]")
        echo "$updated_data" > "$PERFORMANCE_LOG"
    else
        echo "[$perf_entry]" > "$PERFORMANCE_LOG"
    fi
    
    if (( $(echo "$duration > 2.0" | bc -l 2>/dev/null || echo 0) )); then
        echo "⚠️ Slow hook detected: $HOOK_NAME took ${duration}s"
    fi
}

trap log_performance EXIT


echo "🔍 Performance monitoring active for $HOOK_NAME"