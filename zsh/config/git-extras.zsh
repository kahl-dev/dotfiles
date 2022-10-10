if _exec_exists brew; then
	if [ -f "$(brew --prefix)/opt/git-extras/share/git-extras/git-extras-completion.zsh" ]; then
	    source $(brew --prefix)/opt/git-extras/share/git-extras/git-extras-completion.zsh
	fi
fi

