:command! SortCSS :g#\({\n\)\@<=#.,/}/sort
:command! SortSCSS :g#\({\n\)\@<=#.,/\.*[{}]\@=/-1 sort
:command! SortVueSCSS :/<style.*>/,/<\/style>/:g#\({\n\)\@<=#.,/\.*[{}]\@=/-1 sort
