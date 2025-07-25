#!/usr/bin/env bash

echo "$(date): Enhanced rnotify notification hook triggered" >> /tmp/claude-hook-debug.log

get_project_info() {
    local project_info=""
    
    if [ -d ".git" ]; then
        local remote_url=$(git config --get remote.origin.url 2>/dev/null)
        if [ -n "$remote_url" ]; then
            local project_name=""
            
            if [[ "$remote_url" =~ git@([^:]+):([^/]+/[^/]+) ]]; then
                project_name="${BASH_REMATCH[2]%.git}"
            elif [[ "$remote_url" =~ https?://[^/]+/([^/]+/[^/]+) ]]; then
                project_name="${BASH_REMATCH[1]%.git}"
            elif [[ "$remote_url" =~ ([^/:]+/[^/]+)\.git$ ]]; then
                project_name="${BASH_REMATCH[1]}"
            else
                project_name=$(basename "$remote_url" .git)
            fi
            
            if [ -n "$project_name" ]; then
                project_info="📂 $project_name"
                
                local branch=$(git branch --show-current 2>/dev/null)
                if [ -n "$branch" ] && [ "$branch" != "main" ] && [ "$branch" != "master" ]; then
                    project_info="$project_info [$branch]"
                fi
                
                local status=$(git status --porcelain 2>/dev/null | wc -l)
                if [ "$status" -gt 0 ]; then
                    project_info="$project_info ($status changes)"
                fi
            fi
        fi
    fi
    
    if [ -z "$project_info" ] && [ -n "$PWD" ]; then
        local folder_name=$(basename "$PWD")
        if [ "$folder_name" != "home" ] && [ "$folder_name" != "tmp" ] && [ "$folder_name" != "Downloads" ]; then
            project_info="📁 $folder_name"
        fi
    fi
    
    echo "$project_info"
}

get_context() {
    local hostname=$(hostname -s 2>/dev/null || echo "unknown")
    local timestamp=$(date '+%H:%M:%S')
    local session_info=""
    local project_info=$(get_project_info)
    
    if [ -n "$TMUX" ]; then
        local tmux_session=$(tmux display-message -p '#S' 2>/dev/null || echo "")
        local tmux_window=$(tmux display-message -p '#W' 2>/dev/null || echo "")
        if [ -n "$tmux_session" ]; then
            session_info=" [tmux: $tmux_session:$tmux_window]"
        fi
    fi
    
    if [ -n "$SSH_CONNECTION" ]; then
        session_info="$session_info [SSH]"
    fi
    
    local duration_info=""
    if [ -n "$CLAUDE_SESSION_ID" ]; then
        local session_start=$(ps -o lstart= -p $$ 2>/dev/null | awk '{print $4}' || echo "")
        if [ -n "$session_start" ]; then
            duration_info=" - Session: $session_start"
        fi
    fi
    
    local message=""
    if [ -n "$project_info" ]; then
        message="$project_info - "
    fi
    message="${message}Claude ready for input on $hostname$session_info at $timestamp$duration_info"
    
    echo "$message"
}

MESSAGE=$(get_context)

rnotify "$MESSAGE" --type "claude-ready" --sound "intermission"

echo "$(date): rnotify sent: $MESSAGE" >> /tmp/claude-hook-debug.log

exit 0