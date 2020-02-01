if executable('fzf')

  if &loadplugins
    if has('packages')
      packadd! fzf.vim
    endif
  endif

endif
