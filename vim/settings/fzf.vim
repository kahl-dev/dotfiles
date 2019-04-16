if executable('fzf')
" FZF {{{

if has("mac")
  set rtp+=/usr/local/opt/fzf
elseif has("unix")
  execute 'set rtp+='.fnamemodify(systemlist('greadlink -f $(which fzf)')[0], ':h:h')
endif

nnoremap <silent> <C-f>f :FZF -m<cr>
nnoremap <silent> <C-f>g :GFiles<cr>
nnoremap <silent> <C-f>s :GFiles?<cr>
nnoremap <silent> <C-f>b :Buffers<cr>
nnoremap <silent> <leader>bb :Buffers<cr>
nnoremap <silent> <C-f>l :FZFLines<cr>
nnoremap <silent> <C-f>h :History<cr>
nnoremap <silent> <C-f>u :Snippets<cr>
nnoremap <silent> <C-f>c :Commands<cr>
nnoremap <silent> <C-f>h :Helptags<cr>

" Search lines in all open vim buffers {{{
function! s:line_handler(l)
  let keys = split(a:l, ':\t')
  exec 'buf' keys[0]
  exec keys[1]
  normal! ^zz
endfunction

function! s:buffer_lines()
  let res = []
  for b in filter(range(1, bufnr('$')), 'buflisted(v:val)')
    call extend(res, map(getbufline(b,0,"$"), 'b . ":\t" . (v:key + 1) . ":\t" . v:val '))
  endfor
  return res
endfunction

command! FZFLines call fzf#run({
\   'source':  <sid>buffer_lines(),
\   'sink':    function('<sid>line_handler'),
\   'options': '--extended --nth=3..',
\   'down':    '60%'
\})
" }}}

" Augmenting Ag command using fzf#vim#with_preview function
" :Ag  - Start fzf with hidden preview window that can be enabled with '?' key
" :Ag! - Start fzf in fullscreen and display the preview window above"
command! -bang -nargs=* Ag
  \ call fzf#vim#ag(<q-args>,
  \                 <bang>0 ? fzf#vim#with_preview('up:60%')
  \                         : fzf#vim#with_preview('right:50%:hidden', '?'),
  \                 <bang>0)

" }}}
endif
