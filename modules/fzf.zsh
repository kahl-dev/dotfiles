# Add fzf fuzzy finder to zsh
# https://github.com/junegunn/fzf

initFzf() {
  if binaryExists bat; then
    export FZF_CTRL_T_OPTS="$FZF_COMPLETION_OPTS"
    export FZF_COMPLETION_OPTS="--preview '(bat --theme=\"base16\" --color=always --style=\"numbers,changes,header\" {} || cat {} || tree -C {}) 2> /dev/null | head -200'"
  fi

  export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*" --glob "!node_modules/*"'
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

  fzf_git_log() {
    git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
      fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --bind "ctrl-m:execute:
          (grep -o '[a-f0-9]\{7\}' | head -1 |
            xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                      {}
                      FZF-EOF"
  }

  # fbr - checkout git branch (including remote branches), sorted by most recent commit, limit 30 last branches
  fzf_git_branch() {
    local branches branch
    branches=$(git for-each-ref --count=30 --sort=-committerdate refs/heads/ --format="%(refname:short)") &&
    branch=$(echo "$branches" |
    fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
    git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
  }

  # fco_preview - checkout git branch/tag, with a preview showing the commits between the tag/branch and HEAD
  fzf_git_checkout() {
    local tags branches target
    tags=$(
    git tag | awk '{print "\x1b[31;1mtag\x1b[m\t" $1}') || return
    branches=$(
    git branch --all | grep -v HEAD |
      sed "s/.* //" | sed "s#remotes/[^/]*/##" |
      sort -u | awk '{print "\x1b[34;1mbranch\x1b[m\t" $1}') || return
            target=$(
            (echo "$tags"; echo "$branches") |
              fzf --no-hscroll --no-multi --delimiter="\t" -n 2 \
              --ansi --preview="git log -200 --pretty=format:%s $(echo {+2..} |  sed 's/$/../' )" ) || return
                            git checkout $(echo "$target" | awk '{print $2}')
  }

  # fstash - easier way to deal with stashes
  # type fstash to get a list of your stashes
  # enter shows you the contents of the stash
  # ctrl-d shows a diff of the stash against your current HEAD
  # ctrl-b checks the stash out as a branch, for easier merging
  fzf_git_stash() {
    local out q k sha
    while out=$(
      git stash list --pretty="%C(yellow)%h %>(14)%Cgreen%cr %C(blue)%gs" |
        fzf --ansi --no-sort --query="$q" --print-query \
        --expect=ctrl-d,ctrl-b);
              do
                mapfile -t out <<< "$out"
                q="${out[0]}"
                k="${out[1]}"
                sha="${out[-1]}"
                sha="${sha%% *}"
                [[ -z "$sha" ]] && continue
                if [[ "$k" == 'ctrl-d' ]]; then
                  git diff $sha
                elif [[ "$k" == 'ctrl-b' ]]; then
                  git stash branch "stash-$sha" $sha
                  break;
                else
                  git stash show -p $sha
                fi
              done
  }

  fzf_git_add() {
    git ls-files -m -o --exclude-standard | fzf -m --print0 | xargs -0 -o -t git add
  }

  alias falias='alias | fzf'

  # fzf tmux
  alias ft="fzf_tmux"
  alias ftp="fzf_tmux_pane"

  # fzf git
  alias fgl='fzf_git_log'
  alias fgbr='fzf_git_branch'
  alias fgco='fzf_git_checkout'
  alias fgst='fzf_git_stash'
  alias fga='fzf_git_add'
}

zinit ice from"gh-r" as"program" atload"initFzf"
zinit light junegunn/fzf-bin
