width=${2:-80%}
height=${2:-80%}

originating_pane=$(tmux display-message -p "#{pane_id}")

if [ "$(tmux display-message -p -F "#{session_name}")" = "ffu" ]; then
	tmux detach-client
else
	tmux popup -d '#{pane_current_path}' -xC -yC -w$width -h$height -E "tmux attach -t ffu || tmux new -s ffu -c '#{pane_current_path}' 'zsh -i -c \"ffu $originating_pane\"'"
fi
