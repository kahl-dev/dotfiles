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
# Commands:
#   hr                         — local herdr session
#   hr [herdr-options] <host>  — remote attach with server-side keybindings

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
    herdr --remote "$@" --remote-keybindings server
}
