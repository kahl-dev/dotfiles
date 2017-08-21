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

allbrew=(z git vim tmux the_silver_searcher fzy)
osxbrew=(wget macvim reattach-to-user-namespace mongodb sshfs mas)
linuxbrew=(gcc cmake)
osxcask=(font-droidsansmono-nerd-font alfred slack mongodb-compass osxfuse hyper moom skype quitter sublime-text google-chrome 1password near-lock skype-for-business skitch spillo default-folder-x istat-menus iterm2 firefox appcleaner marked daisydisk vlc steam tunnelblick dropbox bartender little-snitch opera sizeup)

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
