#! /bin/zsh

if 'test -n "$SSH_CLIENT"'
then

iterm="${HOME}/.iterm2_shell_integration.zsh"

if test -e $iterm \
  curl -L https://iterm2.com/shell_integration/zsh -o $iterm

source $iterm

fi
