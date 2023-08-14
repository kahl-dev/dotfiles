width=${2:-80%}
height=${2:-80%}
if [ "$(tmux display-message -p -F "#{session_name}")" = "glow" ]; then
	tmux detach-client
else
	tmux popup -d '#{pane_current_path}' -xC -yC -w$width -h$height -E "tmux attach -t glow || tmux new -s glow -c '#{pane_current_path}' 'bash -i -c \"glow --all .\"'"
fi
