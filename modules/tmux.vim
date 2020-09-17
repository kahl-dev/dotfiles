" When combined with a set of tmux key bindings, the plugin will allow you
" to navigate seamlessly between vim and tmux splits using a consistent set
" of hotkeys.
" Doc: https://github.com/christoomey/vim-tmux-navigator
Plug 'christoomey/vim-tmux-navigator'

let g:tmux_navigator_disable_when_zoomed = 1

" Add posibility to share clipboard for vim inside different tmux windows
" Doc: https://github.com/tmux-plugins/vim-tmux-focus-events
" Ddc: https://github.com/roxma/vim-tmux-clipboard
Plug 'tmux-plugins/vim-tmux-focus-events'
Plug 'roxma/vim-tmux-clipboard'
