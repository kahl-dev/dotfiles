" Doc: https://github.com/chriskempson/base16-vim
Plug 'chriskempson/base16-vim'

let &t_8f="\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b="\<Esc>[48;2;%lu;%lu;%lum"
set termguicolors

autocmd vimenter * hi Normal guibg=NONE ctermbg=NONE
autocmd vimenter * hi LineNr guibg=NONE ctermbg=NONE
autocmd vimenter * hi StatusLineTerm guibg=NONE ctermbg=NONE
autocmd vimenter * hi ColorColumn guibg=NONE ctermbg=NONE
autocmd vimenter * hi Normal guibg=NONE ctermbg=NONE
autocmd vimenter * hi SignColumn guibg=NONE ctermbg=NONE
