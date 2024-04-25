#!/bin/bash
ps -u $USER -o rss= | awk '{sum+=$1} END {printf "%.3f GB", sum/1024/1024}'
