# ripgrep is a line-oriented search tool that recursively searches your current directory for a regex pattern.
# Doc: https://github.com/BurntSushi/ripgrep/

function initRipgrep() {
  export RIPGREP_CONFIG_PATH=$DOTFILES/config/ripgreprc
}

if _not_exists rg; then
  zinit ice atload="initRipgrep" as"command" from"gh-r" mv"ripgrep* -> rg" pick"rg/rg"
  zinit light BurntSushi/ripgrep
else
  zinit wait'1' lucid atinit'initRipgrep' nocd for /dev/null
fi
