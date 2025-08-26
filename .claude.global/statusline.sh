#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Parse JSON using jq if available, otherwise use basic parsing
if command -v jq >/dev/null 2>&1; then
    model=$(echo "$input" | jq -r '.model.display_name // .model.id // "unknown"')
    cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
else
    # Basic parsing fallback
    model=$(echo "$input" | sed -n 's/.*"display_name": *"\([^"]*\)".*/\1/p')
    if [ -z "$model" ]; then
        model=$(echo "$input" | sed -n 's/.*"id": *"\([^"]*\)".*/\1/p')
    fi
    cost=$(echo "$input" | sed -n 's/.*"total_cost_usd": *\([0-9.]*\).*/\1/p')
    model=${model:-"unknown"}
    cost=${cost:-"0"}
fi

# Format cost to 2 decimal places
cost=$(printf "%.2f" "$cost")

# Format output with colors - shorter format
printf '\033[36m%s\033[0m@\033[33m%s\033[0m:\033[32m%s\033[0m | \033[35m%s\033[0m | \033[31m$%s\033[0m $ ' \
    "$(whoami)" "$(hostname -s)" "$(basename "$(pwd)")" "$model" "$cost"
