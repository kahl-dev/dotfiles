if which rg &> /dev/null; then
  plugins=(ripgrep)
  alias rg='rg --no-ignore --hidden --follow --glob "!{.git,node_modules,.nuxt,**/node_modules,typo3,typo3_src,typo3temp}/*" --glob "!*.min.{css,js}"'
fi
