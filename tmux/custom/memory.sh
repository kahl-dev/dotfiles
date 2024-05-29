# If this module depends on an external Tmux plugin, say so in a comment.
# E.g.: Requires https://github.com/aaronpowell/tmux-weather

show_memory() { # This function name must match the module name!
  local index icon color text module

  status_r_ram="#{ram_fg_color}#{ram_percentage}"

  # This variable is used internally by the module loader in order to know the position of this module
  index=$1

  icon="$(get_tmux_option "@catppuccin_memory_icon" "#{ram_icon}")"
  color="$(get_tmux_option "@catppuccin_memory_color" "$thm_orange")"
  text="$(get_tmux_option "@catppuccin_memory_text" "$status_r_ram")"

  module=$(build_status_module "$index" "$icon" "$color" "$text")

  echo "$module"
}
