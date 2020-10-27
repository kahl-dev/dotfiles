# Add fzf fuzzy finder to zsh
# Doc: https://github.com/junegunn/fzf
# Doc: https://github.com/Zsh-Packages/fzf

initFzf() {
  bindkey "ç" fzf-cd-widget

  export FZF_INIT_OPTS='--border --cycle --reverse --no-height'
  export FZF_DEFAULT_OPTS="$FZF_INIT_OPTS"
  export FZF_DEFAULT_COMMAND='rg --files'
  # export FZF_CTRL_T_OPTS="--preview '(highlight -O ansi -l {} 2> /dev/null || cat {} || tree -C {}) 2> /dev/null | head -200'"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"


  # tm - create new tmux session, or switch to existing one. Works from within tmux too. (@bag-man)
  # `tm` will allow you to select your tmux session via fzf.
  # `tm irc` will attach to the irc session (if it exists), else it will create it.
  fzf_tmux() {
    [[ -n "$TMUX" ]] && change="switch-client" || change="attach-session"
    if [ $1 ]; then
      tmux $change -t "$1" 2>/dev/null || (tmux new-session -d -s $1 && tmux $change -t "$1"); return
    fi
    session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0) &&  tmux $change -t "$session" || echo "No sessions found."
  }

  # ftpane - switch pane (@george-b)
  fzf_tmux_pane() {
    local panes current_window current_pane target target_window target_pane
    panes=$(tmux list-panes -s -F '#I:#P - #{pane_current_path} #{pane_current_command}')
    current_pane=$(tmux display-message -p '#I:#P')
    current_window=$(tmux display-message -p '#I')

    target=$(echo "$panes" | grep -v "$current_pane" | fzf +m --reverse) || return

    target_window=$(echo $target | awk 'BEGIN{FS=":|-"} {print$1}')
    target_pane=$(echo $target | awk 'BEGIN{FS=":|-"} {print$2}' | cut -c 1)

    if [[ $current_window -eq $target_window ]]; then
      tmux select-pane -t ${target_window}.${target_pane}
    else
      tmux select-pane -t ${target_window}.${target_pane} &&
        tmux select-window -t $target_window
    fi
  }

  # fbr - checkout git branch (including remote branches), sorted by most recent commit, limit 30 last branches
  fzf_git_branch() {
    local branches branch
    branches=$(git for-each-ref --count=30 --sort=-committerdate refs/heads/ --format="%(refname:short)") &&
    branch=$(echo "$branches" |
    fzf -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
    git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
  }

  alias falias='alias | fzf'

  # fzf tmux
  alias ft="fzf_tmux"
  alias ftp="fzf_tmux_pane"

  # fzf git
  alias fgbr='fzf_git_branch'
}

# zinit atload"initFzf" pack"default" for fzf
zinit lucid as=program pick="$ZPFX/bin/(fzf|fzf-tmux)" \
    atload"initFzf" \
    atclone="cp shell/completion.zsh _fzf_completion; \
      cp bin/(fzf|fzf-tmux) $ZPFX/bin" \
    src'shell/key-bindings.zsh' \
    make="!PREFIX=$ZPFX install" for \
        junegunn/fzf

zinit ice wait"4" lucid atload"fzfUpdate"
zinit light fnune/base16-fzf

export BASE16_SHELL_HOOKS=$DOTFILES/base16_hooks
export BASE16_FZF=${ZINIT[PLUGINS_DIR]}/fnune---base16-fzf/bash/

function fzfUpdate {
  export FZF_DEFAULT_OPTS="$FZF_INIT_OPTS"
  source $ZINIT[PLUGINS_DIR]/fnune---base16-fzf/bash/base16-$BASE16_THEME.config
}

# This tool is designed to help you use git more efficiently. It's lightweight and easy to use.
# Doc: https://github.com/wfxr/forgit
zinit light wfxr/forgit
