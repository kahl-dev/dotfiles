if executable('fzf')

  if &loadplugins
    if has('packages')

      packadd! tern_for_vim

      silent! let hasPip3 = system('command -v pip3')
      if hasPip3 !~ '\w\+'
        packadd! tabnine-vim
      else
        " DOKU: https://github.com/Shougo/deoplete.nvim
        packadd! deoplete.nvim
        packadd! nvim-yarp
        packadd! vim-hug-neovim-rpc

        " DOKU: https://github.com/carlitux/deoplete-ternjs
        packadd! deoplete-ternjs
        " TODO: Find other solution to npm install if not exists; Huge start
        " up
        " call system('npm list -g tern || npm install -g tern')

        " DOKU: https://github.com/fszymanski/deoplete-emoji
        packadd! deoplete-emoji

        " DOKU: https://github.com/tbodt/deoplete-tabnine
        " Need to install.sh
        packadd! deoplete-tabnine
      endif

    endif
  endif

endif
