# ripgrep is a line-oriented search tool that recursively searches your current directory for a regex pattern.
# Doc: https://github.com/BurntSushi/ripgrep/

if _exec_exists rg; then
  export RIPGREP_CONFIG_PATH=$DOTFILES/config/ripgreprc
fi
