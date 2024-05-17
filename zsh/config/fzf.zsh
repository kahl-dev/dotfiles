# # Add fzf fuzzy finder to zsh
# # Doc: https://github.com/junegunn/fzf

if [ ! -d "$HOME/.fzf" ]; then
  git clone --depth=1 https://github.com/junegunn/fzf.git $HOME/.fzf
  $HOME/.fzf/install --completion --key-bindings --no-update-rc --no-bash --no-fish
fi

if [ -d "$HOME/.fzf" ]; then
  # Add catppuchino theme
  # https://github.com/catppuccin/fzf
  export FZF_DEFAULT_OPTS=" \
  --border --cycle --reverse --no-height --padding=1 --margin=1 \
  --color=bg+:#313244,spinner:#f5e0dc,hl:#f38ba8 \
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
  --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

  export FZF_DEFAULT_COMMAND='rg --files'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
  export FZF_TMUX_OPTS="-p80%,60%"
  export FZF_TMUX=1

  fzf-custom-tmux() {
    fzf-tmux ${FZF_TMUX_OPTS} "$@"
  }

  alias falias='alias | fzf'

  tm() {
    [[ -n "$TMUX" ]] && change="switch-client" || change="attach-session"
    if [ $1 ]; then
      tmux $change -t "$1" 2>/dev/null || (tmux new-session -d -s $1 && tmux $change -t "$1"); return
    fi
    session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0) &&  tmux $change -t "$session" || echo "No sessions found."
  }

  # SSH into a host using fzf to select from your SSH config
  # runs the original ssh command if arguments are provided
  s() {
    # If arguments are provided, use the original ssh command
    if [ $# -gt 0 ]; then
        # 'command' bypasses shell aliases and functions, calling the binary directly
        command ssh "$@"
        return
    fi

    local ssh_config_file
    if [[ -f ~/.dotfiles-local/ssh-config ]]; then
        ssh_config_file=~/.dotfiles-local/ssh-config
    else
        ssh_config_file=~/.ssh/config
    fi

    local host
    # Get a list of aliases, ensuring each alias is on a new line
    host=$(awk '/^Host / { for (i=2; i<=NF; i++) print $i }' "$ssh_config_file" | fzf --height 40% --reverse)
    
    if [[ -n $host ]]; then
        # Use 'command' to call the original ssh binary with the selected host
        command ssh "$host"
    fi
  }
fi
