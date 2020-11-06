" vim-stay adds automated view session creation and restoration whenever
" editing a buffer, across Vim sessions and window life cycles. It also
" alleviates Vim's tendency to lose view state when cycling through buffers
" (via argdo, bufdo et al.). It is smart about which buffers should be persisted
" and which should not, making the procedure painless and invisible.
" Doc: https://github.com/zhimsel/vim-stay
Plug 'zhimsel/vim-stay'

set viewoptions=cursor,folds,slash,unix
