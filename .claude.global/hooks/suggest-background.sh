#!/bin/bash

# Hook to suggest background execution for long-running commands
# This runs as a PreToolUse hook for Bash commands

COMMAND="$1"

# Pattern matching for commands that should run in background
if [[ "$COMMAND" =~ (test:run|test:watch|test|vitest|jest|pytest) ]] || \
   [[ "$COMMAND" =~ (--watch) ]] || \
   [[ "$COMMAND" =~ ^(npm|yarn|pnpm|bun).*(dev|serve|start) ]] || \
   [[ "$COMMAND" =~ ^make.*(dev|test|watch|serve) ]] || \
   [[ "$COMMAND" =~ ^docker(-compose)?.*(up|build) ]] || \
   [[ "$COMMAND" =~ (webpack|vite|parcel|rollup).*(watch|serve) ]]; then
    
    # Check if command already uses background flag
    if [[ ! "$COMMAND" =~ (run_in_background|&$) ]]; then
        echo "⚠️  SUGGESTION: This command may be long-running."
        echo "Consider using 'run_in_background: true' parameter to run it in background."
        echo "You can then monitor output with BashOutput and stop with KillBash."
        echo ""
        echo "Detected pattern: Long-running command (test/dev/watch/docker)"
    fi
fi

# Always allow the command to proceed
exit 0