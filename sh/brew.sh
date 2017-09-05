#!/usr/bin/env bash

iPkg() {
  handler=$1
  shift
  array=($@)
  for pkg in ${array[@]}; do
    if [ "$handler" = brew ]; then
      if ! (brew list -1 | grep -q "^${pkg}\$"); then
        brew install $pkg
      fi
    elif [ "$handler" = cask ]; then
      if brew cask list -1 | grep "^${pkg}\$" &> /dev/null; then
        brew cask outdated | xargs brew cask reinstall --force
      else
        brew cask install $pkg
      fi
    fi
  done
}

allbrew=(z git vim tmux the_silver_searcher fzy cmake)
osxbrew=(wget macvim reattach-to-user-namespace mongodb sshfs mas tree)
linuxbrew=(gcc)
osxcask=(font-droidsansmono-nerd-font alfred slack mongodb-compass osxfuse hyper skype quitter sublime-text google-chrome 1password near-lock skype-for-business skitch spillo istat-menus iterm2 firefox appcleaner marked daisydisk vlc steam tunnelblick dropbox bartender little-snitch opera sizeup tuck)

# Execute if not osx
if [ "$(uname)" = "Darwin" ]; then

  # Install or update brew
  if (brew --version > /dev/null); then
    brew update
    brew upgrade

    # Install packages
    pkgs=("${allbrew[@]}" "${osxbrew[@]}")
    iPkg brew ${pkgs[@]}

    # Cask
    if (brew cask --version > /dev/null); then
      iPkg cask ${osxcask[@]}
    fi

    brew cleanup
  fi

  sh $DOTFILES/sh/mas.sh

fi

# Execute if not linux
if [ "$(uname)" = "Linux" ]; then

  if (brew --version > /dev/null); then
    brew update
    brew upgrade

    # Install packages
    pkgs=("${allbrew[@]}" "${linuxbrew[@]}")
    iPkg brew ${pkgs[@]}
  fi

fi
