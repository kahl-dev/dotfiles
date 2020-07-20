" Hardtime helps you break that annoying habit vimmers have of scrolling up 
" and down the page using jjjjj and kkkkk but without compromising the rest 
" of our vim experience.
" Doc: https://github.com/takac/vim-hardtime 

if &loadplugins
  if has('packages')

    packadd! vim-hardtime

  endif
endif

let g:hardtime_default_on = 1
let g:hardtime_showmsg = 1
let g:hardtime_maxcount = 2
let g:hardtime_ignore_quickfix = 1
