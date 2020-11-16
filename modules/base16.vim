" Doc: https://github.com/chriskempson/base16-vim
Plug 'chriskempson/base16-vim'

" let &t_8f="\<Esc>[38;2;%lu;%lu;%lum"
" let &t_8b="\<Esc>[48;2;%lu;%lu;%lum"
" set termguicolors


autocmd vimenter * call SetTransparentBackground()
function SetTransparentBackground()

  " Enable italics, Make sure this is immediately after colorscheme
  " https://stackoverflow.com/questions/3494435/vimrc-make-comments-italic
  hi Comment cterm=italic gui=italic

  hi Normal guibg=NONE ctermbg=NONE
  hi LineNr guibg=NONE ctermbg=NONE
  hi StatusLineTerm guibg=NONE ctermbg=NONE
  hi ColorColumn guibg=NONE ctermbg=NONE
  hi Normal guibg=NONE ctermbg=NONE
  hi SignColumn guibg=NONE ctermbg=NONE

endfunction
