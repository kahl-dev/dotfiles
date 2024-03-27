if [ -z "$TMUX" ]
then

   # if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
   #    cd ~ && tmux attach -t REMOTE || tmux new -s REMOTE
   # # else
   # #    cd ~ && tmux attach -t LOCAL || tmux new -s LOCAL
   # fi

fi

alias tmux-clear-resurrect='rm -rf ~/.tmux/resurrect/* && echo "Cleared all tmux-resurrect entries!"'

