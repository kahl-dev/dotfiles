#!/usr/bin/env bash

echo "$(date): Notification handler triggered" >> /tmp/claude-hook-debug.log

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

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

get_context_info() {
    local hostname=$(hostname -s 2>/dev/null || echo "unknown")
    local session_info=""
    
    if [ -n "$TMUX" ]; then
        local tmux_session=$(tmux display-message -p '#S' 2>/dev/null || echo "")
        if [ -n "$tmux_session" ]; then
            session_info=" [$tmux_session]"
        fi
    fi
    
    if [ -n "$SSH_CONNECTION" ]; then
        session_info="$session_info [SSH]"
    fi
    
    echo "$hostname$session_info"
}

handle_notification() {
    local project_info=$(get_project_info)
    local context_info=$(get_context_info)
    local notification_type=""
    local notification_sound="default"
    local message=""
    
    local project_prefix=""
    if [ -n "$project_info" ]; then
        project_prefix="$project_info - "
    fi
    
    if echo "$*" | grep -q "BLOCKED"; then
        if echo "$*" | grep -q "dangerous"; then
            notification_type="claude-blocked-danger"
            notification_sound="critical"
            message="${project_prefix}🚫 Claude blocked dangerous command on $context_info"
        elif echo "$*" | grep -q "long-running"; then
            notification_type="claude-blocked-longrun"
            notification_sound="warning"
            message="${project_prefix}⏰ Claude blocked long-running command on $context_info"
        else
            notification_type="claude-blocked"
            notification_sound="warning"
            message="${project_prefix}🚫 Claude blocked command on $context_info"
        fi
    elif echo "$*" | grep -q -E "(ESLint|TypeScript|linting)"; then
        notification_type="claude-lint-error"
        notification_sound="warning"
        message="${project_prefix}🔍 Claude found code issues on $context_info"
    else
        notification_type="claude-notification"
        notification_sound="default"
        message="${project_prefix}🤖 Claude notification on $context_info"
        
        if [ $# -gt 0 ]; then
            local content="$*"
            if [ ${#content} -gt 60 ]; then
                content="${content:0:60}..."
            fi
            message="$message: $content"
        fi
    fi
    
    echo -e "${BLUE}📬 Sending notification: $message${NC}"
    rnotify "$message" --type "$notification_type" --sound "$notification_sound"
    
    echo "$(date): Notification sent - Type: $notification_type, Message: $message" >> /tmp/claude-hook-debug.log
}

echo -e "${GREEN}🔔 Notification handler processing...${NC}"

# Update session status to show permission request
track_session_path="$HOME/.claude.global/hooks/track-session.sh"
if [[ -x "$track_session_path" ]]; then
    "$track_session_path" permission
fi

handle_notification "$@"

echo -e "${GREEN}✅ Notification handler completed${NC}"
exit 0