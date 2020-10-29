" Make your Vim/Neovim as smart as VSCode.
" Doc: https://github.com/neoclide/coc.nvim
" Langserver: https://github.com/neoclide/coc.nvim/wiki/Language-servers
" FAQ: https://github.com/neoclide/coc.nvim/wiki/F.A.Q
Plug 'neoclide/coc.nvim', {'do': 'yarn install --frozen-lockfile'}

" Doc: https://github.com/neoclide/coc-css
Plug 'neoclide/coc-css', {'do': 'yarn install --frozen-lockfile'}

" Doc: https://github.com/neoclide/coc-emmet
Plug 'neoclide/coc-emmet', {'do': 'yarn install --frozen-lockfile'}

" Doc: https://github.com/neoclide/coc-git
Plug 'neoclide/coc-git', {'do': 'yarn install --frozen-lockfile'}

" Doc: https://github.com/neoclide/coc-highlight
Plug 'neoclide/coc-highlight', {'do': 'yarn install --frozen-lockfile'}

" Doc: https://github.com/neoclide/coc-html
Plug 'neoclide/coc-html', {'do': 'yarn install --frozen-lockfile'}

" Doc: https://github.com/jberglinds/coc-jira-complete
Plug 'jberglinds/coc-jira-complete', {'do': 'yarn install --frozen-lockfile'}

" Doc: https://github.com/neoclide/coc-json
Plug 'neoclide/coc-json', {'do': 'yarn install --frozen-lockfile'}

" Doc: https://github.com/fannheyward/coc-markdownlint
Plug 'fannheyward/coc-markdownlint', {'do': 'yarn install --frozen-lockfile'}

" Doc: https://github.com/neoclide/coc-pairs
Plug 'neoclide/coc-pairs', {'do': 'yarn install --frozen-lockfile'}

" Doc: https://github.com/marlonfan/coc-phpls
Plug 'marlonfan/coc-phpls', {'do': 'yarn install --frozen-lockfile'}

" Doc: https://github.com/josa42/coc-sh
Plug 'josa42/coc-sh', {'do': 'yarn install --frozen-lockfile'}

" Doc: https://github.com/neoclide/coc-snippets
Plug 'neoclide/coc-snippets', {'do': 'yarn install --frozen-lockfile'}

" Doc: https://github.com/iamcco/coc-svg
Plug 'iamcco/coc-svg', {'do': 'yarn install --frozen-lockfile'}

" Doc: https://github.com/neoclide/coc-tabnine
" Plug 'neoclide/coc-tabnine', {'do': 'yarn install --frozen-lockfile'}

" Doc: https://github.com/neoclide/coc-tsserver
Plug 'neoclide/coc-tsserver', {'do': 'yarn install --frozen-lockfile'}

" Doc: https://github.com/neoclide/coc-vetur
Plug 'neoclide/coc-vetur', {'do': 'yarn install --frozen-lockfile'}

" Doc: https://github.com/neoclide/coc-yaml
Plug 'neoclide/coc-yaml', {'do': 'yarn install --frozen-lockfile'}

" Doc: https://github.com/neoclide/coc-snippets
Plug 'neoclide/coc-yank', {'do': 'yarn install --frozen-lockfile'}

" Doc:https://github.com/weirongxu/coc-explorer
Plug 'weirongxu/coc-explorer', {'do': 'yarn install --frozen-lockfile'}

:nmap <leader>e :CocCommand explorer<CR>

let g:coc_node_path = "$NVM_DIR/latest"

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin'before putting this into your config.
" inoremap <silent><expr> <TAB>
"       \ pumvisible() ? "\<C-n>" :
"       \ <SID>check_back_space() ? "\<TAB>" :
"       \ coc#refresh()
" inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
"
" function! s:check_back_space() abort
"   let col = col('.') - 1
"   return !col || getline('.')[col - 1]  =~# '\s'
" endfunction

" Use <c-space> to trigger completion.
" if has('nvim')
"   inoremap <silent><expr> <c-space> coc#refresh()
" else
"   inoremap <silent><expr> <c-@> coc#refresh()
" endif

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current
" position. Coc only does snippet and additional edit on confirm.
" <cr> could be remapped by other vim plugin, try `:verbose imap <CR>`.
" if exists('*complete_info')
"   inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"
" else
"   inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
" endif

inoremap <expr> <C-j> pumvisible() ? "\<C-n>" : "\<C-j>"
inoremap <expr> <C-k> pumvisible() ? "\<C-p>" : "\<C-k>"
" inoremap <expr> <tab> pumvisible() ? "\<C-y>" : "\<tab>"

inoremap <silent><expr> <TAB>
      \ pumvisible() ? coc#_select_confirm() :
      \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

let g:coc_snippet_next = '<tab>'

" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Formatting selected code.
" xmap <leader>f  <Plug>(coc-format-selected)
" nmap <leader>f  <Plug>(coc-format-selected)

" augroup mygroup
"   autocmd!
"   " Setup formatexpr specified filetype(s).
"   autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
"   " Update signature help on jump placeholder.
"   autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
" augroup end

" Applying codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
" xmap <leader>a  <Plug>(coc-codeaction-selected)
" nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap keys for applying codeAction to the current buffer.
" nmap <leader>ac  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
" nmap <leader>qf  <Plug>(coc-fix-current)

" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of LS, ex: coc-tsserver
" nmap <silent> <C-s> <Plug>(coc-range-select)
" xmap <silent> <C-s> <Plug>(coc-range-select)

" Add `:Format` command to format current buffer.
" command! -nargs=0 Format :call CocAction('format')

" Add `:Fold` command to fold current buffer.
" command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
" command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

" Add (Neo)Vim's native statusline support.
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline.
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" " Mappings for CoCList
" " Show all diagnostics.
" nnoremap <silent><nowait> <space>a  :<C-u>CocList diagnostics<cr>
" " Manage extensions.
" nnoremap <silent><nowait> <space>e  :<C-u>CocList extensions<cr>
" " Show commands.
" nnoremap <silent><nowait> <space>c  :<C-u>CocList commands<cr>
" " Find symbol of current document.
" nnoremap <silent><nowait> <space>o  :<C-u>CocList outline<cr>
" " Search workspace symbols.
" nnoremap <silent><nowait> <space>s  :<C-u>CocList -I symbols<cr>
" " Do default action for next item.
" nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>
" " Do default action for previous item.
" nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>
" " Resume latest coc list.
" nnoremap <silent><nowait> <space>p  :<C-u>CocListResume<CR>
"
" nmap <expr> <silent> <C-v> <SID>select_current_word()
" function! s:select_current_word()
"   if !get(g:, 'coc_cursors_activated', 0)
"     return "\<Plug>(coc-cursors-word)"
"   endif
"   return "*\<Plug>(coc-cursors-word):nohlsearch\<CR>"
" endfunc

" Add yank extension
" Doc: https://github.com/neoclide/coc-yank

" Toggle yank list
nnoremap <silent> <space>y  :<C-u>CocList -A --normal yank<cr>

let g:coc_user_config = {}

" Jira
" Doc: https://github.com/jberglinds/coc-jira-complete
call extend(g:coc_user_config, {
\    'jira.workspaceUrl': $JIRA_WORKSPACE ,
\    'jira.user.email': $JIRA_USER_EMAIL,
\    'jira.user.apiKey': $JIRA_API_KEY,
\ })
