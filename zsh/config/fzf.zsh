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
  --border --cycle --reverse --no-height \
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
  --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

  export FZF_DEFAULT_COMMAND='rg --files'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_VIM="$HOME/.fzf"

  plugins+=(fzf)

  alias falias='alias | fzf'

  # This tool is designed to help you use git more efficiently. It's lightweight and easy to use.
  # Doc: https://github.com/wfxr/forgit
  # export FORGIT_NO_ALIASES=false


  zsh_add_plugin "wfxr/forgit"
  # if [ ! -d "$ZSH_CUSTOM/plugins/forgit" ]; then
  #   git clone https://github.com/wfxr/forgit.git $ZSH_CUSTOM/plugins/forgit
  # fi

  export forgit_log=fglog
  export forgit_diff=fgd
  export forgit_add=fgaa
  export forgit_reset_head=fgrh
  export forgit_ignore=fgi
  export forgit_checkout_file=fgcf
  export forgit_checkout_branch=fgcb
  export forgit_branch_delet=fgbd
  export forgit_checkout_tag=fgct
  export forgit_checkout_commit=fgco
  export forgit_revert_commit=fgrc
  export forgit_clean=fgclean
  export forgit_stash_show=fgss
  export forgit_cherry_pick=fgcp
  export forgit_rebase=fgrb
  export forgit_fixup=fgfu

  plugins+=(forgit)

  tm() {
    [[ -n "$TMUX" ]] && change="switch-client" || change="attach-session"
    if [ $1 ]; then
      tmux $change -t "$1" 2>/dev/null || (tmux new-session -d -s $1 && tmux $change -t "$1"); return
    fi
    session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0) &&  tmux $change -t "$session" || echo "No sessions found."
  }



# Fuzzy find urls in last prompt
# ffu() {
#   local pane_id="$1"
#
#   # Check if inside a tmux session
#   if [ -z "$TMUX" ]; then
#     echo "Warning: Not inside a tmux session."
#     return 1
#   fi
#
#   # Extract URLs
#   extract_urls() {
#     grep -oP '(http|https)://\S+'
#   }
#
#   # Capture the entire history of the specified pane's contents or the current pane if none is specified
#   tmux_output=$(tmux capture-pane -p -S -10000 -t "${pane_id:-}")
#
#   # List URLs in fzf and capture the selected URL
#   selected_url=$(echo "$tmux_output" | extract_urls | fzf)
#
#   # If a URL was selected, open it with nc_open
#   if [ -n "$selected_url" ]; then
#     nc_open "$selected_url"
#   fi
#
#   # Exit the shell session
#   exit
# }

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
