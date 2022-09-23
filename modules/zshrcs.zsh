# Allow work customizations in the ~/.zshrc-work
if [ -f $ZDOTDIR/.zshrc-local ]; then
    source $ZDOTDIR/.zshrc-local
fi
