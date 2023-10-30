if _exec_exists colorls; then
	if ! _is_path_exists $HOME/.config/colorls/dark_colors.yaml; then
    mkdir -p $HOME/.config/colorls
    cp $DOTFILES/config/dark_colors.yaml $HOME/.config/colorls/dark_colors.yaml
  fi
fi
