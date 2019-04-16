# Add fzf fuzzy finder to zsh
# https://github.com/junegunn/fzf
if which fzf &> /dev/null; then

  export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow --glob "!{.git,node_modules}/*"'


  initFzf() {
    [ ! -f ~/.fzf.zsh ] && $(brew --prefix)/opt/fzf/install
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

    # ftpane - switch pane (@george-b)
    ftpane() {
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

    f_log() {
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
    f_br() {
      local branches branch
      branches=$(git for-each-ref --count=30 --sort=-committerdate refs/heads/ --format="%(refname:short)") &&
      branch=$(echo "$branches" |
               fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
      git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
    }

    # fco_preview - checkout git branch/tag, with a preview showing the commits between the tag/branch and HEAD
    f_co() {
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
    f_stash() {
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

    f() {
      local cmd=$1
      "f_$cmd"
    }
  }

  after_init+=(initFzf)

  # Add interactive cd for fzf
  # https://github.com/changyuheng/zsh-interactive-cd
  plugins+=(zsh-interactive-cd)

  # Add enhanced
  # https://github.com/b4b4r07/enhancd
  initEnhanced() {
    export ENHANCD_HYPHEN_ARG=--
    source $ZSH_CUSTOM/plugins/enhancd/init.sh
  }

  after_init+=(initEnhanced)
fi
