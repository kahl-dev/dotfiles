# Add fzf fuzzy finder to zsh
# https://github.com/junegunn/fzf

# Install and configure fzf plugin
# zinit lucid as=program pick="$ZPFX/bin/{fzf,fzf-tmux}" \
#     atclone="cp shell/completion.zsh _fzf_completion" \
#     make="PREFIX=$ZPFX install" \
#     for junegunn/fzf
# export PATH="$ZINIT_ROOT/plugins/junegunn---fzf/bin:$PATH"

if command_exists fzf && command_exists fzf-tmux; then

  eval "$(fzf --zsh)"

  # https://github.com/Aloxaf/fzf-tab
  zinit light Aloxaf/fzf-tab
  zstyle ':completion:*' menu no
  if command_exists zoxide; then
    zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
  fi

  # preview directory's content with eza when completing cd
  if command_exists eza; then
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
  else
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
  fi

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

  _tm() {
    [[ -n "$TMUX" ]] && change="switch-client" || change="attach-session"

    session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf -e --print-query --preview "tmux list-windows -t {}")

    echo $session

    if [ -n "$session" ]; then
      selected_session=$(echo "$session" | tail -n 1)

      tmux $change -t "$selected_session" 2>/dev/null || (tmux new-session -d -s "$selected_session" && tmux $change -t "$selected_session")
    else
      echo "No sessions found."
    fi
  }

  if ! is_ssh_client; then
    # SSH into a host using fzf to select from your SSH config
    # runs the original ssh command if arguments are provided
    _s() {
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

else
  echo "fzf or fzf-tmux not found"
fi
