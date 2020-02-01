#! /bin/zsh

# Only do on ssh
if test -n $SSH_CLIENT; then

  iterm="${HOME}/.iterm2_shell_integration.zsh"

  # Load script if not exists
  if ! test -e $iterm; then
    curl -L https://iterm2.com/shell_integration/zsh -o $iterm
  fi

  # Load script
  source $iterm

fi
