#!/bin/bash
# mem_check.sh

mem_kb=$(ps -u $USER -o rss | awk '{sum+=$1} END {print sum}')

# Thresholds in kilobytes
medium_thresh="20971520" # 20 * 1024 * 1024
high_thresh="41943040"   # 40 * 1024 * 1024

if [ "$mem_kb" -lt "$medium_thresh" ]; then
    echo "low"
elif [ "$mem_kb" -lt "$high_thresh" ]; then
    echo "medium"
else
    echo "high"
fi

