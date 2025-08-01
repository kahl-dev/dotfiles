# Keybindings

# Emacs keybindings
# bindkey -e # emacs keybindings

# Vi keybindings
bindkey -v
bindkey 'jk' vi-cmd-mode
export KEYTIMEOUT=0.5

# Use vim keys in tab complete menu:
bindkey -M menuselect '^h' vi-backward-char
bindkey -M menuselect '^k' vi-up-line-or-history
bindkey -M menuselect '^l' vi-forward-char
bindkey -M menuselect '^j' vi-down-line-or-history
bindkey -M menuselect '^[[Z' vi-up-line-or-history
bindkey -v '^?' backward-delete-char

# Change cursor shape for different vi modes.
function zle-keymap-select () {
    case $KEYMAP in
        vicmd) echo -ne '\e[1 q';;      # block
        viins|main) echo -ne '\e[5 q';; # beam
    esac
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[5 q"
}
zle -N zle-line-init
echo -ne '\e[5 q' # Use beam shape cursor on startup.
preexec() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.

# History search
bindkey '^K' history-search-backward
bindkey '^J' history-search-forward

# zsh-autosuggestions
# Fish-like autosuggestions for zsh.
# https://github.com/zsh-users/zsh-autosuggestions
bindkey '^Z' autosuggest-toggle # toggle suggestions
bindkey '^F' autosuggest-accept # accept suggestions

# Edit line in vim with ctrl-e:
autoload edit-command-line; zle -N edit-command-line
bindkey '^E' edit-command-line

bindkey -s '^U' 'tm^M'
bindkey -s '^N' 'nvim $(fzf)^M'

# Bind atuin to Ctrl+R in both insert and command modes
bindkey -M viins '^R' atuin-search
bindkey -M vicmd '^R' atuin-search
