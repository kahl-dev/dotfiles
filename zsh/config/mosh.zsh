# sm — mosh with auto Remote Bridge tunnel via autossh
# Detects `Tag remote-bridge` in SSH config and manages tunnel lifecycle.
# Tunnel starts before mosh, cleaned up when last session exits.
#
# Commands:
#   sm [mosh-options] [user@]host  — mosh with auto tunnel
#   sm-status                      — list active tunnels
#   sm-kill [host]                 — force-kill tunnel(s)

# --- Internal helpers ---

# Detect the side-effect-free Remote Bridge opt-in from ssh -G output.
_sm_host_has_remote_bridge_tag() {
    local ssh_config="$1"
    printf '%s\n' "$ssh_config" | awk '
        /^tag / {
            for (field = 2; field <= NF; field++) {
                if ($field == "remote-bridge") found = 1
            }
        }
        END { exit !found }
    '
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
            --ssh=*|--predict=*|--server=*|--port=*|--bind-server=*|--family=*|--experimental-remote-ip=*|--client=*)
                ;;
            --ssh|--predict|--server|-p|--port|--bind-server|--family|--experimental-remote-ip|--client)
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

# Confirm a PID actually belongs to an autossh process, not just some
# process that happens to be alive at that number (e.g. a PID recycled by
# an unrelated process after a reboot where /tmp survived — kill -0 alone
# can't tell the difference). Uses the bare command name (`comm`), not the
# full argv (`command`), so a process whose *arguments* happen to contain
# the substring "autossh" can't produce a false positive.
_sm_is_autossh() {
    local pid="$1"
    [[ -n "$pid" ]] || return 1
    ps -p "$pid" -o comm= 2>/dev/null | grep -q autossh
}

# Check if tunnel process is alive AND is actually autossh
_sm_tunnel_alive() {
    local pid_file="$1"
    [[ -f "$pid_file" ]] || return 1
    local pid
    pid=$(cat "$pid_file")
    [[ -n "$pid" ]] || return 1
    kill -0 "$pid" 2>/dev/null && _sm_is_autossh "$pid"
}

# End-to-end health check: process aliveness alone can't tell a working
# tunnel from one whose forwards silently died server-side (stale sshd,
# roamed network). Runs the health probe over a forwarding-free exec
# connection so it never depends on the tunnel it's checking. $HOME must
# expand REMOTELY, hence the single-quoted remote command.
_sm_tunnel_healthy() {
    local host_argument="$1"
    ssh -o ClearAllForwardings=yes -o BatchMode=yes -o ConnectTimeout=5 \
        "$host_argument" 'curl -sf -m 2 --unix-socket "$HOME/.ssh/remote-bridge.sock" http://localhost/health' \
        >/dev/null 2>&1
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

# Detect whether this zsh build supports `zsystem flock` (part of zsh/system;
# present on effectively every modern zsh but not guaranteed on every
# platform/build). Cached after the first call.
_sm_flock_available() {
    if [[ -z "$_sm_flock_available_cache" ]]; then
        zmodload -F zsh/system b:zsystem 2>/dev/null
        if zsystem supports flock 2>/dev/null; then
            _sm_flock_available_cache=yes
        else
            _sm_flock_available_cache=no
        fi
    fi
    [[ "$_sm_flock_available_cache" == yes ]]
}

# Run a callback (function name + args) with exclusive per-host access, with a
# bounded wait so a wedged lock can never hang `sm` forever. Returns the
# callback's exit status, or 3 if the lock couldn't be acquired in time (the
# callback does not run then). Uses zsystem flock: the fcntl lock is held via
# the subshell's own file descriptor and released by the kernel the instant
# that process ends — normal exit, signal, or kill -9 — so it's never leaked,
# even on Ctrl-C. If zsystem flock is unavailable it degrades to unserialized
# (see body).
_sm_with_host_lock() {
    local host="$1"
    shift
    local lock_file="/tmp/sm-${host}.lock"

    if _sm_flock_available; then
        (
            : >| "$lock_file" 2>/dev/null
            if ! zsystem flock -t 10 "$lock_file" 2>/dev/null; then
                echo "sm: lock timeout for ${host}" >&2
                exit 3
            fi
            "$@"
        )
        return $?
    fi

    # zsystem flock is part of zsh/system, present on every build the dotfiles
    # target (macOS + mainstream Linux both ship it). On an exotic build
    # without it, don't wedge or hard-fail — run the callback unserialized (as
    # sm did before tunnel locking existed) after warning once, so sm still
    # works; only the rare same-host concurrent-transition race is unguarded.
    if [[ -z "$_sm_no_flock_warned" ]]; then
        echo "sm: zsystem flock unavailable — tunnel operations are not serialized" >&2
        _sm_no_flock_warned=1
    fi
    "$@"
}

# Reuse the existing tunnel if it's alive, otherwise start a new one.
# Must run under _sm_with_host_lock: the alive-check and the start have to
# be atomic with respect to a concurrent session's teardown (see
# _sm_teardown_if_last), otherwise a tunnel could be killed the instant
# after this function decides it's usable.
_sm_start_or_reuse_tunnel() {
    local host="$1"
    local pid_file="$2"
    local host_argument="$3"
    local session_pid="$4"
    local state_directory="/tmp/sm-${host}"

    if [[ ! -S "${SSH_AUTH_SOCK:-}" ]]; then
        echo "sm: a valid local SSH_AUTH_SOCK is required for tagged host ${host}" >&2
        return 1
    fi

    # Claim this session's marker as the FIRST locked action, so the marker
    # write and a concurrent teardown's count (also under this host's lock)
    # are mutually exclusive — that mutual exclusion is what actually closes
    # the "teardown kills a tunnel a starting session needs" race.
    mkdir -p "$state_directory"
    touch "${state_directory}/${session_pid}"

    _sm_prune_stale_markers "$state_directory"

    if _sm_tunnel_alive "$pid_file"; then
        if _sm_tunnel_healthy "$host_argument"; then
            echo "tunnel: reusing (Unix sockets)" >&2
            return 0
        fi
        echo "tunnel: alive but unhealthy for ${host}, restarting" >&2
        _sm_stop_tunnel_process "$host"
    fi

    rm -f "$pid_file"

    # Pre-flight over a forwarding-free exec connection: capture the remote
    # $HOME needed to build absolute -R socket paths below. Stale-socket
    # cleanup does NOT happen here — sm-ssh-wrapper already removes the
    # sockets before every autossh attempt, including this first one, so a
    # second rm here would just be a duplicate remote roundtrip.
    local remote_home
    if ! remote_home=$(ssh -o ClearAllForwardings=yes -o BatchMode=yes -o ConnectTimeout=10 \
        "$host_argument" 'printf %s "$HOME"'); then
        echo "sm: pre-flight \$HOME lookup for ${host} failed" >&2
        _sm_teardown_if_last "$host" "$session_pid"
        return 1
    fi

    # ExitOnForwardFailure prevents a tunnel from running without both socket
    # forwards. The wrapper removes stale socket files before every retry.
    #
    # Remote command is a 30s heartbeat instead of `tail -f /dev/null`:
    # server-originated traffic makes a half-dead TCP connection hit the
    # retransmission timeout (tcp_retries2) so the stale sshd
    # self-destructs, where `tail -f /dev/null` sends nothing and lives
    # forever. Heartbeat output is discarded client-side.
    #
    # AUTOSSH_PATH points autossh at sm-ssh-wrapper, which repeats the
    # pre-flight cleanup before every retry so reconnects self-heal.
    AUTOSSH_PIDFILE="$pid_file" \
    AUTOSSH_PATH="$DOTFILES/bin/sm-ssh-wrapper" \
    SM_CLEANUP_HOST="$host_argument" \
    SM_REMOTE_SOCKETS=".ssh/remote-bridge.sock .ssh/agent-tunnel.sock" \
        autossh -M 0 -f -T \
        -o "ServerAliveInterval=10" \
        -o "ServerAliveCountMax=2" \
        -o "ExitOnForwardFailure=yes" \
        -R "${remote_home}/.ssh/remote-bridge.sock:localhost:8377" \
        -R "${remote_home}/.ssh/agent-tunnel.sock:${SSH_AUTH_SOCK}" \
        "$host_argument" "while :; do echo heartbeat; sleep 30; done" \
        >/dev/null

    # autossh -f backgrounds immediately (GATETIME=0), so its own exit status
    # cannot prove that either remote forward is usable.
    local attempt
    for attempt in 1 2 3 4 5; do
        sleep 1
        if _sm_tunnel_alive "$pid_file" && _sm_tunnel_healthy "$host_argument"; then
            echo "tunnel: started (Unix sockets)" >&2
            return 0
        fi
    done

    echo "sm: tunnel for ${host} did not become healthy" >&2
    _sm_stop_tunnel_process "$host"
    _sm_teardown_if_last "$host" "$session_pid"
    return 1
}

# Remove this session's marker and, if it was the last one, tear down the
# tunnel. Must run under _sm_with_host_lock: the remaining-session count and
# the cleanup decision have to be atomic with respect to a concurrently
# starting session claiming the tunnel (see _sm_start_or_reuse_tunnel).
_sm_teardown_if_last() {
    local host="$1"
    local session_pid="$2"
    local state_directory="/tmp/sm-${host}"

    rm -f "${state_directory}/${session_pid}"
    _sm_prune_stale_markers "$state_directory"

    local remaining
    remaining=$(_sm_session_count "$state_directory")
    if (( remaining == 0 )); then
        _sm_cleanup_tunnel "$host"
    fi
}

# Stop the tunnel without changing session ownership state.
_sm_stop_tunnel_process() {
    local host="$1"
    local pid_file="/tmp/sm-${host}.pid"

    if _sm_tunnel_alive "$pid_file"; then
        kill "$(cat "$pid_file")" 2>/dev/null
    fi
    rm -f "$pid_file"
}

# Kill tunnel and remove all state for a host
_sm_cleanup_tunnel() {
    local host="$1"
    local state_directory="/tmp/sm-${host}"

    _sm_stop_tunnel_process "$host"
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

    local host_argument
    host_argument=$(_sm_extract_host_argument "$@")
    if [[ -z "$host_argument" ]]; then
        echo "sm: could not determine host from arguments" >&2
        return 1
    fi

    local host="${host_argument#*@}"

    # Resolve SSH config once for the side-effect-free host opt-in.
    local ssh_config
    ssh_config=$(ssh -G "$host" 2>/dev/null)

    local tunneled=false

    if _sm_host_has_remote_bridge_tag "$ssh_config"; then
        if ! command_exists autossh; then
            echo "sm: autossh not found (brew install autossh)" >&2
            return 1
        fi
        local pid_file="/tmp/sm-${host}.pid"

        # The session marker is created inside _sm_start_or_reuse_tunnel, as
        # its first action under the per-host lock, so the marker write and a
        # concurrent teardown's count are mutually exclusive. tunneled=true
        # just records that this invocation owns a session to tear down on exit.
        tunneled=true

        if ! _sm_with_host_lock "$host" _sm_start_or_reuse_tunnel "$host" "$pid_file" "$host_argument" "$$"; then
            return 1
        fi
    fi

    # Keep the mosh bootstrap connection forwarding-free. autossh owns both
    # Unix socket forwards for the lifetime of the mosh session.
    if $tunneled; then
        mosh --ssh="ssh -o ClearAllForwardings=yes" "$@"
    else
        mosh "$@"
    fi
    local mosh_exit=$?

    if $tunneled; then
        if ! _sm_with_host_lock "$host" _sm_teardown_if_last "$host" "$$"; then
            # Lock unavailable (timeout) — don't guess at teardown. Leave
            # the tunnel and this session's marker for the next sm /
            # sm-status / sm-kill invocation to reconcile, rather than risk
            # killing a tunnel a concurrent session might depend on.
            echo "sm: could not acquire lock for ${host}; leaving tunnel state as-is" >&2
        fi
    fi

    return $mosh_exit
}

sm-status() {
    local pid_file
    local found=false

    # Read-only: report live tunnels, never mutate. Cleanup of dead pid files
    # and stale markers is owned by _sm_start_or_reuse_tunnel / _sm_teardown_if_last
    # / sm-kill (all under the per-host lock) — a status command must not rm
    # state a concurrent session is mid-writing, which could delete another
    # session's markers and later strand its tunnel.
    for pid_file in /tmp/sm-*.pid(N); do
        local host="${${pid_file:t}%.pid}"
        host="${host#sm-}"

        if _sm_tunnel_alive "$pid_file"; then
            found=true
            local tunnel_pid=$(cat "$pid_file")
            local session_count=$(_sm_session_count "/tmp/sm-${host}")
            echo "${host}: pid=${tunnel_pid} transport=unix-sockets sessions=${session_count}"
        fi
    done

    if ! $found; then
        echo "no active tunnels"
    fi
}

sm-kill() {
    local target_host="$1"

    if [[ -n "$target_host" ]] && ! [[ "$target_host" =~ '^[a-zA-Z0-9._-]+$' ]]; then
        echo "sm-kill: invalid hostname: ${target_host}" >&2
        return 1
    fi

    if [[ -z "$target_host" ]]; then
        local pid_file
        local -a kill_hosts
        local total_sessions=0

        for pid_file in /tmp/sm-*.pid(N); do
            local host="${${pid_file:t}%.pid}"
            host="${host#sm-}"
            kill_hosts+=("$host")
            _sm_prune_stale_markers "/tmp/sm-${host}"
            (( total_sessions += $(_sm_session_count "/tmp/sm-${host}") ))
        done

        if (( ${#kill_hosts} == 0 )); then
            echo "no active tunnels"
            return
        fi

        # Bare sm-kill is a big hammer (every host at once). Confirm when any
        # tunnel still has a live session, so an accidental invocation — or a
        # script globbing /tmp/sm-*.pid — can't silently tear down a tunnel
        # another window depends on.
        if (( total_sessions > 0 )); then
            echo "sm-kill: about to kill ${#kill_hosts} tunnel(s) [${kill_hosts}] with ${total_sessions} active session(s)" >&2
            local confirm
            if ! read -q "confirm?Kill ALL? [y/N] "; then
                echo >&2
                echo "sm-kill: aborted" >&2
                return 1
            fi
            echo >&2
        fi

        local host
        for host in $kill_hosts; do
            echo "killed: ${host}"
            _sm_with_host_lock "$host" _sm_cleanup_tunnel "$host"
        done
        return
    fi

    if [[ -f "/tmp/sm-${target_host}.pid" ]]; then
        _sm_prune_stale_markers "/tmp/sm-${target_host}"
        local session_count
        session_count=$(_sm_session_count "/tmp/sm-${target_host}")

        if (( session_count > 0 )); then
            echo "sm-kill: ${target_host} has ${session_count} active session(s)" >&2
            local confirm
            if ! read -q "confirm?Kill anyway? [y/N] "; then
                echo >&2
                echo "sm-kill: aborted" >&2
                return 1
            fi
            echo >&2
        fi

        _sm_with_host_lock "$target_host" _sm_cleanup_tunnel "$target_host"
        echo "killed: ${target_host}"
    else
        echo "sm-kill: no tunnel for ${target_host}" >&2
        return 1
    fi
}

compdef sm=ssh
