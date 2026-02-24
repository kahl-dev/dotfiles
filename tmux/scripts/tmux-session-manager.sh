#!/usr/bin/env bash
# tmux-session-manager.sh — Unified session management with fzf
# Works both inside tmux (popup via Prefix+o) and outside (shell via `tm`)
#
# Features:
#   - Session switching (LRU sorted, git branch display, preview pane)
#   - Session creation (zoxide disambiguation, literal path, path browser)
#   - Session rename and delete
#   - Move pane/window to session (inside tmux only)

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

# Catppuccin Mocha palette (ANSI 24-bit true color)
COLOR_BLUE=$'\033[38;2;137;180;250m'
COLOR_GREEN=$'\033[38;2;166;227;161m'
COLOR_DIM=$'\033[38;2;108;112;134m'
COLOR_TEXT=$'\033[38;2;205;214;244m'
COLOR_BOLD=$'\033[1m'
COLOR_RESET=$'\033[0m'

# Icons (Nerd Font)
ICON_BRANCH=""
ICON_TAG=""
ICON_SESSION="󰆍"
ICON_NEW="${COLOR_GREEN} + New Session${COLOR_RESET}"
ICON_NEW_MATCH="New Session"

# Detect context: inside tmux or standalone shell
INSIDE_TMUX="${TMUX:+1}"

# ============================================================================
# Context-Aware Wrappers
# ============================================================================

# fzf wrapper: popup inside tmux, plain fzf outside
# First arg is popup size (ignored outside tmux), rest passed to fzf
run_fzf() {
    local popup_size="$1"
    shift
    if [[ -n "$INSIDE_TMUX" ]]; then
        fzf-tmux -p "$popup_size" "$@"
    else
        fzf "$@"
    fi
}

# Show notification: tmux message inside, stderr outside
notify() {
    if [[ -n "$INSIDE_TMUX" ]]; then
        tmux display-message "$1"
    else
        echo "$1" >&2
    fi
}

# Switch to or attach to a session
goto_session() {
    local target="$1"
    if [[ -n "$INSIDE_TMUX" ]]; then
        tmux switch-client -t "$target"
    else
        exec tmux attach-session -t "$target"
    fi
}

# ============================================================================
# Helper Functions
# ============================================================================

# Extract clean session name from fzf selection
# fzf output includes ANSI codes (--ansi mode) and icon prefixes
strip_selection() {
    local input="$1"
    local field
    # Take first tab-delimited field
    field=$(echo "$input" | cut -f1)
    # Strip ANSI escape sequences
    field=$(printf '%s' "$field" | sed $'s/\033\\[[0-9;]*m//g')
    # Strip session icon prefix and trailing whitespace
    field=$(printf '%s' "$field" | sed "s/^${ICON_SESSION} //;s/[[:space:]]*$//")
    echo "$field"
}

# Get sessions sorted by LRU (last used first), excluding current
get_sessions() {
    local current="" last_session="" sessions sorted

    if [[ -n "$INSIDE_TMUX" ]]; then
        current=$(tmux display-message -p '#S')
        last_session=$(tmux display-message -p '#{client_last_session}' 2>/dev/null || echo "")
    fi

    # Get all sessions (exclude current if inside tmux)
    sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)

    if [[ -n "$current" && -n "$sessions" ]]; then
        sessions=$(echo "$sessions" | grep -Fxv "$current" || true)
    fi

    if [[ -z "$sessions" ]]; then
        echo ""
        return
    fi

    # Sort: last_session first (if exists and not current), then rest
    if [[ -n "$last_session" && "$last_session" != "$current" ]]; then
        # Remove last_session from list, prepend it
        sessions=$(echo "$sessions" | grep -Fxv "$last_session" || true)
        sorted=$(printf "%s\n%s" "$last_session" "$sessions" | awk 'NF && !seen[$0]++')
    else
        sorted=$(echo "$sessions" | awk 'NF && !seen[$0]++')
    fi

    echo "$sorted"
}

# Format sessions with git branch info and window count
format_with_branches() {
    local sessions="$1"
    local -a session_list=()
    local -a branch_list=()
    local -a icon_list=()
    local -a window_counts=()
    local max_len=0

    # First pass: collect data and find max session name length
    while IFS= read -r session; do
        [[ -z "$session" ]] && continue
        session_list+=("$session")

        # Window count
        local window_count
        window_count=$(tmux list-windows -t "$session" -F '#{window_id}' 2>/dev/null | wc -l | tr -d ' ')
        window_counts+=("$window_count")

        # Get first pane's working directory
        local pane_path
        pane_path=$(tmux list-panes -t "$session" -F '#{pane_current_path}' 2>/dev/null | head -1)

        local ref=""
        local icon="$ICON_BRANCH"

        if [[ -n "$pane_path" && -d "$pane_path" ]]; then
            # Try to get current branch
            ref=$(git -C "$pane_path" branch --show-current 2>/dev/null || true)
            if [[ -z "$ref" ]]; then
                # Maybe detached HEAD on a tag?
                ref=$(git -C "$pane_path" describe --tags --exact-match 2>/dev/null || true)
                [[ -n "$ref" ]] && icon="$ICON_TAG"
            fi
        fi

        branch_list+=("$ref")
        icon_list+=("$icon")

        local len=${#session}
        (( len > max_len )) && max_len=$len
    done <<< "$sessions"

    # Second pass: format output with tab-separated fields
    # Format: "ICON name_padded\tbranch_display window_badge"
    local padding=$((max_len + 2))
    for ((i=0; i<${#session_list[@]}; i++)); do
        local name="${session_list[$i]}"
        local ref="${branch_list[$i]}"
        local icon="${icon_list[$i]}"
        local window_count="${window_counts[$i]}"

        local badge="${COLOR_DIM}${window_count}w${COLOR_RESET}"

        if [[ -n "$ref" ]]; then
            printf "${ICON_SESSION} %-${padding}s\t${COLOR_BLUE}${icon} %s${COLOR_RESET}  ${badge}\n" "$name" "$ref"
        else
            printf "${ICON_SESSION} %-${padding}s\t${badge}\n" "$name"
        fi
    done
}

# Create session at directory with editable name
create_session_at() {
    local dir="$1"
    local proposed_name="${2:-}"

    if [[ -z "$proposed_name" ]]; then
        proposed_name=$(basename "$dir")
    fi

    # Sanitize name: replace dots/spaces with dashes, keep only safe chars
    # No spaces — they cause quoting issues in tmux commands and fzf field parsing
    proposed_name=$(echo "$proposed_name" | tr '. ' '--' | tr -cd '[:alnum:]-_')

    # Handle empty name after sanitization
    if [[ -z "$proposed_name" ]]; then
        proposed_name="session"
    fi

    # Handle collision
    local final_name="$proposed_name"
    local counter=2
    while tmux has-session -t "$final_name" 2>/dev/null; do
        final_name="${proposed_name}-${counter}"
        counter=$((counter + 1))
    done

    if [[ -n "$INSIDE_TMUX" ]]; then
        # Inside tmux: create detached, switch, offer rename
        tmux new-session -ds "$final_name" -c "$dir"
        tmux switch-client -t "$final_name"
        # Async: let user rename if desired (command-prompt runs in tmux, not blocking)
        tmux command-prompt -I "$final_name" -p "Session name:" \
            "rename-session '%%'"
    else
        # Outside tmux: create and attach directly (takes over terminal)
        exec tmux new-session -s "$final_name" -c "$dir"
    fi
}

# Zoxide lookup with disambiguation via fzf
zoxide_lookup() {
    local query="$1"

    # Get all matching directories from zoxide
    local matches
    matches=$(zoxide query -l "$query" 2>/dev/null || true)

    if [[ -z "$matches" ]]; then
        notify "No zoxide matches for '$query'. Use ctrl-f to browse."
        return 1
    fi

    # Count matches
    local count
    count=$(echo "$matches" | wc -l | tr -d ' ')

    local selected
    if [[ "$count" -eq 1 ]]; then
        # Single match — still show for confirmation
        selected=$(echo "$matches" | run_fzf "70%,30%" \
            --prompt="Confirm directory: " \
            --header="Press Enter to confirm, Esc to cancel" \
            --no-multi)
    else
        # Multiple matches — let user pick
        selected=$(echo "$matches" | run_fzf "70%,50%" \
            --prompt="Pick directory: " \
            --header="$count matches found" \
            --no-multi)
    fi

    if [[ -z "$selected" ]]; then
        return 1
    fi

    echo "$selected"
}

# Resolve a query to a directory — literal path or zoxide lookup
# Paths starting with /, ~, ./ or ../ are used directly
resolve_directory() {
    local query="$1"

    # Expand ~ to $HOME
    local expanded="${query/#\~/$HOME}"

    # Check if it looks like a path
    if [[ "$expanded" == /* || "$expanded" == ./* || "$expanded" == ../* ]]; then
        # Literal path — resolve and validate
        local resolved
        resolved=$(cd "$expanded" 2>/dev/null && pwd) || {
            notify "Directory not found: $query"
            return 1
        }
        echo "$resolved"
    else
        # Not a path — use zoxide
        zoxide_lookup "$query"
    fi
}

# Path browser using fd
browse_directories() {
    local start_dir="${1:-$HOME}"

    # Use fd if available, fall back to find
    local selected
    if command -v fd &>/dev/null; then
        selected=$(fd --type d --hidden \
            --exclude .git \
            --exclude node_modules \
            --exclude vendor \
            --exclude .cache \
            --exclude __pycache__ \
            --max-depth 5 \
            . "$start_dir" 2>/dev/null | \
            run_fzf "70%,60%" \
                --prompt="Browse: " \
                --header="Select directory for new session" \
                --preview="ls -la {}" \
                --no-multi)
    else
        selected=$(find "$start_dir" -type d -maxdepth 5 \
            -not -path '*/.git/*' \
            -not -path '*/node_modules/*' \
            -not -path '*/vendor/*' \
            2>/dev/null | \
            run_fzf "70%,60%" \
                --prompt="Browse: " \
                --header="Select directory for new session" \
                --preview="ls -la {}" \
                --no-multi)
    fi

    if [[ -z "$selected" ]]; then
        return 1
    fi

    echo "$selected"
}

# Move current pane to target session as a new window
# If pane is the only one in its window, moves the entire window instead
move_pane_to_session() {
    local target="$1"
    local current_session current_pane pane_count

    current_session=$(tmux display-message -p '#S')
    current_pane=$(tmux display-message -p '#{pane_id}')

    # Cannot move to self
    if [[ "$target" == "$current_session" ]]; then
        notify "Already in session '$target'"
        return 0
    fi

    # Count panes in current window
    pane_count=$(tmux list-panes -F '#{pane_id}' | wc -l | tr -d ' ')

    if [[ "$pane_count" -eq 1 ]]; then
        # Only pane — move the whole window instead
        move_window_to_session "$target"
        return $?
    fi

    # Break pane into its own window (stays in current session, detached)
    tmux break-pane -d -s "$current_pane"

    # The pane now lives in a new window; find it by pane id
    local new_window
    new_window=$(tmux display-message -t "$current_pane" -p '#{window_index}')

    # Move that window to the target session
    tmux move-window -d -s "${current_session}:${new_window}" -t "${target}:"

    notify "Pane moved to session '$target'"
}

# Move current window to target session
move_window_to_session() {
    local target="$1"
    local current_session window_count

    current_session=$(tmux display-message -p '#S')

    # Cannot move to self
    if [[ "$target" == "$current_session" ]]; then
        notify "Already in session '$target'"
        return 0
    fi

    # Check if this is the last window in the session
    window_count=$(tmux list-windows -t "$current_session" -F '#{window_id}' | wc -l | tr -d ' ')

    if [[ "$window_count" -eq 1 ]]; then
        # Last window — moving it kills the session
        # Move window, then switch to target (since current session will die)
        tmux move-window -d -t "${target}:"
        tmux switch-client -t "$target"
        notify "Window moved to '$target' (previous session closed)"
    else
        # Move window, stay in current session
        tmux move-window -d -t "${target}:"
        notify "Window moved to session '$target'"
    fi
}

# Create a new session from current directory (for move targets)
# Returns session name via stdout
create_session_for_move() {
    local current_dir
    current_dir=$(tmux display-message -p '#{pane_current_path}')

    local proposed_name
    proposed_name=$(basename "$current_dir" | tr '. ' '--' | tr -cd '[:alnum:]-_')

    if [[ -z "$proposed_name" ]]; then
        proposed_name="session"
    fi

    # Handle collision
    local final_name="$proposed_name"
    local counter=2
    while tmux has-session -t "$final_name" 2>/dev/null; do
        final_name="${proposed_name}-${counter}"
        counter=$((counter + 1))
    done

    # Create the session (don't switch to it — caller will move pane/window)
    tmux new-session -ds "$final_name" -c "$current_dir"

    echo "$final_name"
}

# Delete a session (with confirmation via fzf)
delete_session() {
    local target="$1"

    if [[ -n "$INSIDE_TMUX" ]]; then
        local current_session
        current_session=$(tmux display-message -p '#S')
        if [[ "$target" == "$current_session" ]]; then
            notify "Cannot delete current session"
            return 0
        fi
    fi

    # Confirm via fzf
    local confirm
    confirm=$(printf "Yes, delete '%s'\nNo, cancel" "$target" | \
        run_fzf "50%,20%" \
            --prompt="Delete session '$target'? " \
            --no-multi \
            --header="This will kill the session and all its windows")

    if [[ "$confirm" == "Yes, delete"* ]]; then
        tmux kill-session -t "$target"
        notify "Session '$target' deleted"
    fi
}

# ============================================================================
# Preview Renderer
# ============================================================================

render_new_session_preview() {
    echo ""
    echo "  ${COLOR_GREEN}${COLOR_BOLD} Create a New Session${COLOR_RESET}"
    echo ""
    echo "  ${COLOR_DIM}────────────────────────────────────${COLOR_RESET}"
    echo ""
    echo "  ${COLOR_TEXT}${COLOR_BOLD}Quick Start${COLOR_RESET}"
    echo "  ${COLOR_DIM}Type a name and press Enter${COLOR_RESET}"
    echo "  ${COLOR_DIM}to look up with zoxide${COLOR_RESET}"
    echo ""
    echo "  ${COLOR_TEXT}${COLOR_BOLD}Path Syntax${COLOR_RESET}"
    echo "  ${COLOR_DIM}~/projects/myapp${COLOR_RESET}  ${COLOR_TEXT}Literal path${COLOR_RESET}"
    echo "  ${COLOR_DIM}./relative${COLOR_RESET}        ${COLOR_TEXT}Relative path${COLOR_RESET}"
    echo "  ${COLOR_DIM}myproject${COLOR_RESET}         ${COLOR_TEXT}Zoxide lookup${COLOR_RESET}"
    echo ""
    echo "  ${COLOR_TEXT}${COLOR_BOLD}Shortcuts${COLOR_RESET}"
    echo "  ${COLOR_DIM}ctrl-f${COLOR_RESET}  ${COLOR_TEXT}Browse directories${COLOR_RESET}"
}

render_session_preview() {
    local session="$1"

    # Verify session exists
    if ! tmux has-session -t "$session" 2>/dev/null; then
        echo "  ${COLOR_DIM}Session not found${COLOR_RESET}"
        return
    fi

    # Session metadata
    local window_count attached_count
    window_count=$(tmux list-windows -t "$session" -F '#{window_id}' 2>/dev/null | wc -l | tr -d ' ')
    attached_count=$(tmux list-clients -t "$session" 2>/dev/null | wc -l | tr -d ' ')

    # Header
    echo ""
    echo "  ${COLOR_BLUE}${COLOR_BOLD}${ICON_SESSION} ${session}${COLOR_RESET}"
    echo ""

    # Meta line
    local meta="  ${COLOR_DIM}${window_count} window"
    [[ "$window_count" -ne 1 ]] && meta+="s"
    meta+="${COLOR_RESET}"
    if [[ "$attached_count" -gt 0 ]]; then
        meta+="  ${COLOR_GREEN} ${attached_count} attached${COLOR_RESET}"
    fi
    echo "$meta"
    echo ""
    echo "  ${COLOR_DIM}────────────────────────────────${COLOR_RESET}"
    echo ""

    # Window list (max 8)
    local max_windows=8
    local shown=0
    local window_data
    window_data=$(tmux list-windows -t "$session" \
        -F '#{window_index}|#{window_name}|#{pane_current_path}|#{window_active}|#{window_panes}' \
        2>/dev/null)

    while IFS='|' read -r window_index window_name pane_path window_active pane_count; do
        [[ -z "$window_index" ]] && continue
        ((shown++))

        if [[ $shown -gt $max_windows ]]; then
            local remaining=$((window_count - max_windows))
            echo "  ${COLOR_DIM}... and ${remaining} more${COLOR_RESET}"
            break
        fi

        # Active window marker
        local marker="   "
        local name_color="$COLOR_TEXT"
        if [[ "$window_active" == "1" ]]; then
            marker="  ${COLOR_GREEN}${COLOR_RESET}"
            name_color="$COLOR_GREEN"
        fi

        # Git branch for this window's path
        local git_info=""
        if [[ -n "$pane_path" && -d "$pane_path" ]]; then
            local branch
            branch=$(git -C "$pane_path" branch --show-current 2>/dev/null || true)
            if [[ -n "$branch" ]]; then
                git_info="  ${COLOR_BLUE} ${branch}${COLOR_RESET}"
            fi
        fi

        # Pane count badge (only if >1 pane)
        local pane_badge=""
        if [[ "$pane_count" -gt 1 ]]; then
            pane_badge="  ${COLOR_DIM}[${pane_count}p]${COLOR_RESET}"
        fi

        # Window line
        echo "${marker} ${name_color}${window_index}:${window_name}${COLOR_RESET}${pane_badge}${git_info}"

        # Path line (dimmed, indented)
        if [[ -n "$pane_path" ]]; then
            local display_path="${pane_path/#$HOME/\~}"
            echo "      ${COLOR_DIM}${display_path}${COLOR_RESET}"
        fi
    done <<< "$window_data"
}

# ============================================================================
# Main Entry Point
# ============================================================================

main() {
    local mode="${1:-}"
    local arg1="${2:-}"
    local arg2="${3:-}"

    # Handle sub-commands (called from fzf bindings)
    case "$mode" in
        create)
            # Called with: create <name> <dir>
            create_session_at "$arg2" "$arg1"
            exit 0
            ;;
        rename)
            # Handled inline via fzf execute binding (not used as subcommand)
            exit 0
            ;;
        move-pane)
            move_pane_to_session "$arg1"
            exit 0
            ;;
        move-window)
            move_window_to_session "$arg1"
            exit 0
            ;;
        preview)
            # Called from fzf --preview: preview <session_name>
            # fzf {1} strips ANSI codes, but may include icon prefix
            local target="$arg1"
            target=$(printf '%s' "$target" | sed "s/^${ICON_SESSION} //;s/^[[:space:]]*//;s/[[:space:]]*$//")
            if [[ "$target" == *"$ICON_NEW_MATCH"* ]]; then
                render_new_session_preview
            else
                render_session_preview "$target"
            fi
            exit 0
            ;;
    esac

    # Main mode: Show session picker
    local current=""
    local border_label

    if [[ -n "$INSIDE_TMUX" ]]; then
        current=$(tmux display-message -p '#S')
        border_label=" 󰆍 Sessions (current: $current) "
    else
        border_label=" 󰆍 Sessions "
    fi

    # Build session list
    local sessions
    sessions=$(get_sessions)

    local formatted_sessions=""
    if [[ -n "$sessions" ]]; then
        formatted_sessions=$(format_with_branches "$sessions")
    fi

    # Add [+ New Session] at top
    local input
    if [[ -n "$formatted_sessions" ]]; then
        input=$(printf "%s\n%s" "$ICON_NEW" "$formatted_sessions")
    else
        input="$ICON_NEW"
    fi

    # Header with ANSI-colored keybinding hints (2 lines inside tmux to avoid cutoff)
    local header expect_keys
    if [[ -n "$INSIDE_TMUX" ]]; then
        local line1="${COLOR_DIM}⏎${COLOR_TEXT} switch  ${COLOR_DIM}^r${COLOR_TEXT} rename  ${COLOR_DIM}^d${COLOR_TEXT} delete  ${COLOR_DIM}^f${COLOR_TEXT} browse"
        local line2="${COLOR_DIM}^s${COLOR_TEXT} move pane  ${COLOR_DIM}^w${COLOR_TEXT} move window"
        header="${line1}${COLOR_RESET}"$'\n'"${line2}${COLOR_RESET}"
        expect_keys="ctrl-f,ctrl-d,ctrl-s,ctrl-w"
    else
        header="${COLOR_DIM}⏎${COLOR_TEXT} attach  ${COLOR_DIM}^r${COLOR_TEXT} rename  ${COLOR_DIM}^d${COLOR_TEXT} delete  ${COLOR_DIM}^f${COLOR_TEXT} browse${COLOR_RESET}"
        expect_keys="ctrl-f,ctrl-d"
    fi

    # Rename binding: strip icon prefix from {1} before passing to tmux
    local script_path
    script_path="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
    local rename_command="bash -c 'target=\$(echo \"\$1\" | sed \"s/^󰆍 //;s/[[:space:]]*\$//\"); printf \"\\r\\033[K  New name: \"; read -r name; [[ -n \"\$name\" ]] && tmux rename-session -t \"\$target\" \"\$name\"' _ {1}"

    # Preview command
    local preview_command="bash '${script_path}' preview {1}"

    # Run fzf (popup inside tmux, plain fzf outside)
    local result
    result=$(echo "$input" | run_fzf "80%,70%" \
        --ansi \
        --delimiter=$'\t' \
        --with-nth=1.. \
        --prompt=" Session: " \
        --header="$header" \
        --border-label="$border_label" \
        --no-multi \
        --print-query \
        --preview="$preview_command" \
        --preview-window="right,45%,border-left,wrap" \
        --bind "ctrl-r:execute($rename_command)+reload($script_path list)" \
        --expect="$expect_keys" \
        --tabstop=4 \
        || true)

    # Parse result: first line is query, second is key pressed, third is selection
    local query key selection
    query=$(echo "$result" | sed -n '1p')
    key=$(echo "$result" | sed -n '2p')
    selection=$(echo "$result" | sed -n '3p')

    # Handle expected keys
    case "$key" in
        ctrl-f)
            local dir
            dir=$(browse_directories "$HOME") || exit 0
            create_session_at "$dir"
            exit 0
            ;;
        ctrl-d)
            # Delete selected session
            if [[ -n "$selection" ]]; then
                local target
                target=$(strip_selection "$selection")
                if [[ -n "$target" && "$target" != *"$ICON_NEW_MATCH"* ]]; then
                    delete_session "$target"
                fi
            fi
            exit 0
            ;;
        ctrl-s|ctrl-w)
            # Move pane or window to selected session (inside tmux only)
            if [[ -z "$INSIDE_TMUX" ]]; then
                exit 0
            fi

            local target=""
            if [[ -n "$selection" ]]; then
                target=$(strip_selection "$selection")
            fi

            # If [+ New Session] selected or no selection, create a new session first
            if [[ -z "$target" || "$target" == *"$ICON_NEW_MATCH"* ]]; then
                target=$(create_session_for_move)
                if [[ -z "$target" ]]; then
                    notify "Session creation cancelled"
                    exit 0
                fi
            fi

            if [[ "$key" == "ctrl-s" ]]; then
                move_pane_to_session "$target"
            else
                move_window_to_session "$target"
            fi
            exit 0
            ;;
    esac

    # Default: handle Enter (switch/attach or create)
    if [[ -n "$selection" ]]; then
        local clean_selection
        clean_selection=$(strip_selection "$selection")

        if [[ "$clean_selection" == *"$ICON_NEW_MATCH"* ]]; then
            # New session requested - check if query has content
            if [[ -n "$query" ]]; then
                local dir
                dir=$(resolve_directory "$query") || exit 0
                create_session_at "$dir" "$query"
            else
                local dir
                dir=$(browse_directories "$HOME") || exit 0
                create_session_at "$dir"
            fi
        else
            # Existing session selected
            goto_session "$clean_selection"
        fi
    elif [[ -n "$query" ]]; then
        # No selection but query entered - try zoxide lookup
        local dir
        dir=$(resolve_directory "$query") || exit 0
        create_session_at "$dir" "$query"
    fi
}

# Special command to output formatted list (for fzf reload)
if [[ "${1:-}" == "list" ]]; then
    sessions=$(get_sessions)
    if [[ -n "$sessions" ]]; then
        formatted=$(format_with_branches "$sessions")
        printf "%s\n%s" "$ICON_NEW" "$formatted"
    else
        echo "$ICON_NEW"
    fi
    exit 0
fi

main "$@"
