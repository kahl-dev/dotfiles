# Bat supports syntax highlighting for a large number of programming and markup languages
# https://github.com/sharkdp/bat
# List of themes: bat --list-themes

if command_exists bat; then
  export FZF_PREVIEW_OPTS="bat {} || cat {} || tree -C {}"
  export FZF_CTRL_T_OPTS="--min-height 30 --preview-window down:60% --preview-window noborder --preview '($FZF_PREVIEW_OPTS) 2> /dev/null'"

  export BAT_CONFIG_PATH="$DOTFILES/config/bat.conf"
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"

  # https://github.com/catppuccin/bat
  BAT_THEME="$(bat --config-dir)/themes"
  if ! path_exists $BAT_THEME; then
    echo "Installing bat catppuccin themes..."
    mkdit -p ~/temp_dir/
    git clone https://github.com/catppuccin/bat.git ~/temp_dir/catppuccino-bat
    mkdir -p $BAT_THEME
    cp * ~/temp_dir/catppuccino-bat/*.tmTheme $BAT_THEME
    bat cache --build
    rm -Rf ~/temp_dir/catppuccino-bat
  fi

  # alias cat='bat';
fi
