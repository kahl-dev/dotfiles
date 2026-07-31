#!/usr/bin/env zsh

# hr — herdr remote attach with server-side keybinding resolution
#
# `herdr --remote` defaults to `--remote-keybindings local`, where the local
# client resolves the prefix keys. In that mode the [[keys.command]] popups
# (prefix+a apps layer, prefix+v layout layer) are recognised — they appear in
# the prefix+? help panel — but the action never crosses to the server: no
# pane.spawn is logged and no popup opens. Popups are panes, and panes belong
# to the server, so the layers stay dead. Resolving server-side fixes it; both
# machines get their config from these dotfiles, so the bindings are identical
# either way. Verified against herdr 0.7.5 — drop the wrapper once the
# client-side path forwards custom commands.
#
# Like `sm`, `hr` owns the Remote Bridge / SSH agent tunnel for the duration of
# the attach. herdr's own SSH connection carries no forwards, so without this
# the remote panes fall back to whatever socket files happen to exist at
# ~/.ssh/agent-tunnel.sock — possibly orphans from a dead tunnel, which makes
# git fail with "Permission denied (publickey)" while the socket looks present.
# Plain `ssh -A` is not an alternative: it creates a per-connection socket path
# that vanishes with the connection, which is the problem the fixed paths solve.
#
# Commands:
#   hr                    — local herdr session
#   hr [user@]host [...]  — remote attach with tunnel + server-side keybindings

hr() {
    if ! command_exists herdr; then
        echo "hr: herdr not found" >&2
        return 1
    fi

    if (( $# == 0 )); then
        herdr
        return
    fi

    # Host first: herdr reads the token right after --remote as the SSH target.
    local host_argument="$1"
    local tunneled=false

    # A leading option was already broken before the tunnel existed (herdr would
    # take the flag as the SSH target), but silently it would now ALSO skip the
    # tunnel: `ssh -G --flag` fails, and a failed tag lookup is indistinguishable
    # from an untagged host. Fail loudly instead of attaching without an agent.
    if [[ "$host_argument" == -* ]]; then
        echo "hr: host must come first, before any herdr options" >&2
        return 1
    fi

    _remote_tunnel_ensure "$host_argument"
    case $? in
        0) tunneled=true ;;
        1) ;;
        *) return 1 ;;
    esac

    # always-block, not a plain call: session markers are keyed by this shell's
    # PID, which survives a SIGINT or a closed terminal, so a release that gets
    # skipped strands the tunnel until the next sm-kill.
    local herdr_exit=0
    {
        herdr --remote "$@" --remote-keybindings server
        herdr_exit=$?
    } always {
        if $tunneled; then
            _remote_tunnel_release "$host_argument"
        fi
    }

    return $herdr_exit
}
