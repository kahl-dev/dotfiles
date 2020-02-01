if executable('fzf')

  if &loadplugins
    if has('packages')
      packadd! fzf.vim
      packadd! ack.vim
    endif
  endif

endif
