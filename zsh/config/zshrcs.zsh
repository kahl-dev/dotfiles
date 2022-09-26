# Allow local customizations in the ~/.zshrc-local
if [ -f $HOME/.zshrc-local ]; then
    source $HOME/.zshrc-local
fi
