#!/usr/bin/env bash
set -euo pipefail

# Which-key style menu for tmux prefix bindings.
# Triggered via Prefix + ? — shows all available keybindings.
# Layers (Apps, TPM) open as nested submenus.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SUBMENU="${1:-root}"

show_root() {
    tmux display-menu -xC -yC -T " 󰌌 Which Key " \
        "" \
        "Sessions" "" "" \
        "  [o] Session manager"        "o" "run-shell -b 'bash $SCRIPT_DIR/tmux-session-manager.sh'" \
        "  [Q] Kill session"           "Q" "confirm-before -p 'kill-session #S? (y/n)' 'kill-session \; run-shell \"~/.dotfiles/tmux/plugins/tmux-resurrect/scripts/save.sh >/dev/null 2>&1 || true\"'" \
        "  [L] Last session"           "L" "switch-client -l" \
        "  [d] Detach"                 "d" "detach-client" \
        "" \
        "Windows" "" "" \
        "  [c] New window"             "c" "new-window -c '#{pane_current_path}'" \
        "  [X] Kill window"            "X" "kill-window \; run-shell '~/.dotfiles/tmux/plugins/tmux-resurrect/scripts/save.sh >/dev/null 2>&1 || true'" \
        "  [l] Last window"            "l" "last-window" \
        "  [,] Rename window"          "," "command-prompt -I '#W' 'rename-window -- \"%%\"'" \
        "" \
        "Panes" "" "" \
        "  [|] Split horizontal  │"    "|" "split-window -h -c '#{pane_current_path}'" \
        "  [-] Split vertical  ─"      "-" "split-window -v -c '#{pane_current_path}'" \
        "  [z] Zoom toggle"            "z" "resize-pane -Z" \
        "  [x] Kill pane"              "x" "kill-pane \; run-shell '~/.dotfiles/tmux/plugins/tmux-resurrect/scripts/save.sh >/dev/null 2>&1 || true'" \
        "  [B] Break pane out"         "B" "break-pane -d" \
        "  [E] Join pane from..."      "E" "command-prompt -p 'join pane from: ' 'join-pane -h -s \"%%\"'" \
        "" \
        "Layers" "" "" \
        "  [a] Apps  󰀻  >"             "a" "run-shell 'bash $SCRIPT_DIR/tmux-which-key.sh apps'" \
        "  [v] Panes    >"             "v" "run-shell 'bash $SCRIPT_DIR/tmux-which-key.sh panes'" \
        "  [t] Plugins (TPM)  >"       "t" "run-shell 'bash $SCRIPT_DIR/tmux-which-key.sh tpm'" \
        "" \
        "Tools" "" "" \
        "  [u] URLs in pane"           "u" "run-shell -b '~/.dotfiles/tmux/plugins/tmux-fzf-url/fzf-url.sh'" \
        "  [Tab] Extract text (fzf)"   "Tab" "run-shell -b '~/.dotfiles/tmux/plugins/extrakto/scripts/open.sh'" \
        "  [F] Thumbs (hint copy)"     "F" "run-shell -b '~/.dotfiles/tmux/plugins/tmux-thumbs/tmux-thumbs.sh'" \
        "  [/] Search scrollback"      "/" "run-shell -b '~/.dotfiles/tmux/plugins/tmux-fuzzback/fuzzback.sh'" \
        "  [*] Kill process"           "*" "run-shell '~/.dotfiles/tmux/plugins/tmux-cowboy/scripts/cowboy.sh'" \
        "  [C] Toggle Claude usage"    "C" "run-shell 'current=\$(tmux show -gqv @show-claude-usage); if [ \"\$current\" = \"on\" ]; then tmux set -g @show-claude-usage \"off\"; tmux display-message \"Claude usage: OFF\"; else tmux set -g @show-claude-usage \"on\"; tmux display-message \"Claude usage: ON\"; fi; tmux refresh-client -S'" \
        "  [D] Update status"          "D" "display-popup -E -xC -yC -w 80% -h 80% '~/.dotfiles/tmux/scripts/update-detail.sh'" \
        "  [Enter] Copy mode"          "Enter" "copy-mode" \
        "  [r] Reload config"          "r" "source-file ~/.dotfiles/tmux/tmux.conf \; display-message 'Config reloaded!'" \
        "  [_] Full-width split"       "_" "split-window -fv" \
        "" \
        "Help" "" "" \
        "  [?] Cheatsheet"             "?" "run-shell -b \"tmux display-popup -d '#{pane_current_path}' -xC -yC -w90% -h90% -E 'bash $SCRIPT_DIR/tmux-cheatsheet.sh'\"" \
        "" \
        "Other Help Keys" "" "" \
        "  unified overlay   alt ?"    "" ""
}

show_apps() {
    tmux display-menu -xC -yC -T " 󰀻 Apps " \
        "" \
        "Window (new window)" "" "" \
        "  [g] Lazygit"                "g" "new-window -n lazygit -c '#{pane_current_path}' 'lazygit'" \
        "  [y] Yazi"                   "y" "new-window -n yazi -c '#{pane_current_path}' 'yazi'" \
        "  [b] btop"                   "b" "new-window -n btop 'btop'" \
        "  [m] glow"                   "m" "new-window -n glow -c '#{pane_current_path}' 'glow'" \
        "" \
        "Popup (floating overlay)" "" "" \
        "  [G] Lazygit"                "G" "display-popup -E -w 90% -h 90% -d '#{pane_current_path}' 'lazygit'" \
        "  [Y] Yazi"                   "Y" "display-popup -E -w 90% -h 90% -d '#{pane_current_path}' 'yazi'" \
        "  [B] btop"                   "B" "display-popup -E -w 90% -h 90% -d '#{pane_current_path}' 'btop'" \
        "  [M] glow"                   "M" "display-popup -E -w 90% -h 90% -d '#{pane_current_path}' 'glow'" \
        "" \
        "" "" "" \
        "  [Esc] Back"                 "Escape" "run-shell 'bash $SCRIPT_DIR/tmux-which-key.sh root'"
}

show_panes() {
    tmux display-menu -xC -yC -T "  Panes " \
        "" \
        "Layouts" "" "" \
        "  [=] Balance equally"          "=" "select-layout -E" \
        "  [t] Tiled (auto grid)"        "t" "select-layout tiled" \
        "  [m] Main vertical  ◧"         "m" "select-layout main-vertical" \
        "  [M] Main horizontal  ⬒"      "M" "select-layout main-horizontal" \
        "  [1] Max 1 row  ─│─│─"         "1" "run-shell 'bash $SCRIPT_DIR/tmux-grid-layout.sh 1'" \
        "  [2] Max 2 rows  ╍╍"           "2" "run-shell 'bash $SCRIPT_DIR/tmux-grid-layout.sh 2'" \
        "  [3] Max 3 rows  ┇┇"           "3" "run-shell 'bash $SCRIPT_DIR/tmux-grid-layout.sh 3'" \
        "" \
        "Split" "" "" \
        "  [|] Horizontal  │"            "|" "split-window -h -c '#{pane_current_path}'" \
        "  [-] Vertical  ─"              "-" "split-window -v -c '#{pane_current_path}'" \
        "  [_] Full-width vertical"      "_" "split-window -fv" \
        "" \
        "Structure" "" "" \
        "  [j] Join pane (tree)"         "j" "choose-tree -Z 'join-pane -h -s \"%%\"'" \
        "  [b] Break pane out"           "b" "break-pane -d" \
        "  [g] Grab pane ─ (fzf)"       "g" "display-popup -E -w 80% -h 60% 'bash ~/.dotfiles/tmux/scripts/tmux-grab-pane.sh h'" \
        "  [G] Grab pane │ (fzf)"       "G" "display-popup -E -w 80% -h 60% 'bash ~/.dotfiles/tmux/scripts/tmux-grab-pane.sh v'" \
        "" \
        "Swap" "" "" \
        "  [h] Swap prev"                "h" "swap-pane -U" \
        "  [l] Swap next"                "l" "swap-pane -D" \
        "  [s] Swap by number"           "s" "display-panes 'swap-pane -t \"%%\"'" \
        "" \
        "Manage" "" "" \
        "  [x] Kill pane"                "x" "kill-pane \; run-shell '~/.dotfiles/tmux/plugins/tmux-resurrect/scripts/save.sh >/dev/null 2>&1 || true'" \
        "  [z] Zoom toggle"              "z" "resize-pane -Z" \
        "  [r] Rotate"                   "r" "rotate-window" \
        "" \
        "" "" "" \
        "  [Esc] Back"                   "Escape" "run-shell 'bash $SCRIPT_DIR/tmux-which-key.sh root'"
}

show_tpm() {
    tmux display-menu -xC -yC -T "  Plugins (TPM) " \
        "" \
        "  [i] Install plugins"        "i" "run-shell '~/.dotfiles/tmux/plugins/tpm/bindings/install_plugins'" \
        "  [u] Update plugins"         "u" "run-shell '~/.dotfiles/tmux/plugins/tpm/bindings/update_plugins'" \
        "  [x] Clean unused plugins"   "x" "run-shell '~/.dotfiles/tmux/plugins/tpm/bindings/clean_plugins'" \
        "" \
        "" "" "" \
        "  [Esc] Back"                 "Escape" "run-shell 'bash $SCRIPT_DIR/tmux-which-key.sh root'"
}

case "$SUBMENU" in
    root)  show_root ;;
    apps)  show_apps ;;
    panes) show_panes ;;
    tpm)   show_tpm ;;
    *)     show_root ;;
esac
