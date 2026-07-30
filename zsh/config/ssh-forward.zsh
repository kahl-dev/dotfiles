#!/usr/bin/env zsh
# sshl — SSH with local port forwards for OAuth/login callbacks
#
# CLI login flows (gcloud, gh, az, vault, ...) open a callback listener on a
# random port on the remote host. Forwarding that port makes the browser on
# this Mac reach the remote listener.
#
# Commands:
#   sshl <host> <port> [port...]  — ssh to host, forward each port 1:1
#   t3l <port> [port...]          — same, host fixed to t3
#
# Tip: inside a running ssh session you can add a forward without a second
# connection — press Enter, then `~C`, then `-L 1455:localhost:1455`.

_sshl_validate_port() {
    local port="$1"
    [[ "$port" == <-> ]] && (( port >= 1 && port <= 65535 ))
}

sshl() {
    if (( $# < 2 )); then
        echo "usage: sshl <host> <port> [port...]" >&2
        return 2
    fi

    local host="$1"
    shift

    local -a forward_arguments
    local port
    for port in "$@"; do
        if ! _sshl_validate_port "$port"; then
            echo "sshl: invalid port '$port' (expected 1-65535)" >&2
            return 2
        fi
        forward_arguments+=(-L "${port}:localhost:${port}")
    done

    echo "sshl: ${host} — forwarding ${(j:, :)@}" >&2
    ssh "${forward_arguments[@]}" "$host"
}

t3l() {
    if (( $# < 1 )); then
        echo "usage: t3l <port> [port...]" >&2
        return 2
    fi
    sshl t3 "$@"
}

compdef _hosts sshl
