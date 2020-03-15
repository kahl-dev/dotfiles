if which rg &> /dev/null; then
  export RIPGREP_CONFIG_PATH=$HOME/.ripgreprc
  plugins=(ripgrep)
fi
