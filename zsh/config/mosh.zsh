# sm — mosh with auto Remote Bridge tunnel via autossh
# Detects RemoteForward in SSH config and manages tunnel lifecycle automatically.
# Tunnel starts before mosh, cleaned up when last session exits.
#
# Commands:
#   sm [mosh-options] [user@]host  — mosh with auto tunnel
#   sm-status                      — list active tunnels
#   sm-kill [host]                 — force-kill tunnel(s)

# --- Internal helpers ---

# Detect if host has RemoteForward for bridge port in SSH config
# Outputs the detected port on success
_sm_detect_bridge_port() {
    local host="$1"
    local bridge_port="${REMOTE_BRIDGE_PORT:-8377}"

    if ssh -G "$host" 2>/dev/null | grep -qi "^remoteforward.*${bridge_port}"; then
        echo "$bridge_port"
        return 0
    fi
    return 1
}

# Extract host argument from mosh-style arguments (preserves user@ prefix)
_sm_extract_host_argument() {
    local after_separator=false
    local skip_next=false
    local argument

    for argument in "$@"; do
        if $skip_next; then
            skip_next=false
            continue
        fi

        if $after_separator; then
            echo "$argument"
            return 0
        fi

        case "$argument" in
            --)
                after_separator=true ;;
            --ssh=*|--predict=*|--server=*|--port=*|--bind-server=*|--family=*|--experimental-remote-ip=*)
                ;;
            --ssh|--predict|--server|-p|--port|--bind-server|--family|--experimental-remote-ip)
                skip_next=true ;;
            --*|-a|-n|-4|-6)
                ;;
            *)
                echo "$argument"
                return 0 ;;
        esac
    done
    return 1
}

# Check if tunnel process is alive
_sm_tunnel_alive() {
    local pid_file="$1"
    [[ -f "$pid_file" ]] && kill -0 "$(cat "$pid_file")" 2>/dev/null
}

# Remove stale session markers (dead PIDs)
_sm_prune_stale_markers() {
    local state_directory="$1"
    [[ -d "$state_directory" ]] || return 0

    local marker
    for marker in "$state_directory"/*(N); do
        [[ -f "$marker" ]] || continue
        local marker_pid="${marker:t}"
        if ! kill -0 "$marker_pid" 2>/dev/null; then
            rm -f "$marker"
        fi
    done
}

# Count active session markers
_sm_session_count() {
    local state_directory="$1"
    [[ -d "$state_directory" ]] || { echo 0; return; }

    local count=0
    local marker
    for marker in "$state_directory"/*(N); do
        [[ -f "$marker" ]] && (( count++ ))
    done
    echo "$count"
}

# Kill tunnel and remove all state for a host
_sm_cleanup_tunnel() {
    local host="$1"
    local pid_file="/tmp/sm-${host}.pid"
    local state_directory="/tmp/sm-${host}"

    if _sm_tunnel_alive "$pid_file"; then
        kill "$(cat "$pid_file")" 2>/dev/null
    fi
    rm -f "$pid_file"
    rm -rf "$state_directory"
}

# --- Public commands ---

sm() {
    if ! command_exists mosh; then
        echo "sm: mosh not found" >&2
        return 1
    fi

    if [[ $# -eq 0 ]]; then
        echo "Usage: sm [mosh-options] [user@]host [command]" >&2
        return 1
    fi

    if ! command_exists autossh; then
        echo "sm: autossh not found (brew install autossh)" >&2
        return 1
    fi

    local host_argument
    host_argument=$(_sm_extract_host_argument "$@")
    if [[ -z "$host_argument" ]]; then
        echo "sm: could not determine host from arguments" >&2
        return 1
    fi

    local host="${host_argument#*@}"
    local bridge_port
    bridge_port=$(_sm_detect_bridge_port "$host")
    local tunneled=false

    if [[ -n "$bridge_port" ]]; then
        local pid_file="/tmp/sm-${host}.pid"
        local state_directory="/tmp/sm-${host}"

        _sm_prune_stale_markers "$state_directory"

        if ! _sm_tunnel_alive "$pid_file"; then
            rm -f "$pid_file"

            AUTOSSH_PIDFILE="$pid_file" autossh -M 0 -f -N \
                -o "ServerAliveInterval=10" \
                -o "ServerAliveCountMax=2" \
                -o "ExitOnForwardFailure=yes" \
                "$host_argument"

            if [[ $? -ne 0 ]]; then
                echo "sm: failed to start tunnel to ${host}" >&2
                rm -f "$pid_file"
                return 1
            fi

            echo "tunnel: started (${bridge_port})" >&2
        else
            echo "tunnel: reusing (${bridge_port})" >&2
        fi

        mkdir -p "$state_directory"
        touch "${state_directory}/$$"
        tunneled=true
    fi

    mosh "$@"
    local mosh_exit=$?

    if $tunneled; then
        rm -f "/tmp/sm-${host}/$$"
        _sm_prune_stale_markers "/tmp/sm-${host}"

        local remaining
        remaining=$(_sm_session_count "/tmp/sm-${host}")
        if (( remaining == 0 )); then
            _sm_cleanup_tunnel "$host"
        fi
    fi

    return $mosh_exit
}

sm-status() {
    local pid_file
    local found=false

    for pid_file in /tmp/sm-*.pid(N); do
        local host="${${pid_file:t}%.pid}"
        host="${host#sm-}"
        local state_directory="/tmp/sm-${host}"

        _sm_prune_stale_markers "$state_directory"

        if _sm_tunnel_alive "$pid_file"; then
            found=true
            local tunnel_pid=$(cat "$pid_file")
            local session_count=$(_sm_session_count "$state_directory")
            local bridge_port
            bridge_port=$(_sm_detect_bridge_port "$host")
            echo "${host}: pid=${tunnel_pid} port=${bridge_port:-?} sessions=${session_count}"
        else
            rm -f "$pid_file"
            rm -rf "$state_directory"
        fi
    done

    if ! $found; then
        echo "no active tunnels"
    fi
}

sm-kill() {
    local target_host="$1"

    if [[ -z "$target_host" ]]; then
        local pid_file
        local found=false

        for pid_file in /tmp/sm-*.pid(N); do
            found=true
            local host="${${pid_file:t}%.pid}"
            host="${host#sm-}"
            _sm_cleanup_tunnel "$host"
            echo "killed: ${host}"
        done

        if ! $found; then
            echo "no active tunnels"
        fi
        return
    fi

    if [[ -f "/tmp/sm-${target_host}.pid" ]]; then
        _sm_cleanup_tunnel "$target_host"
        echo "killed: ${target_host}"
    else
        echo "sm-kill: no tunnel for ${target_host}" >&2
        return 1
    fi
}

compdef sm=ssh
