#!/bin/sh

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
      if ! (brew cask list -1 | grep -q "^${pkg}\$"); then
          brew cask install $pkg
      fi
    fi
  done
}

allbrew=(z git vim tmux the_silver_searcher fzy)
osxbrew=(wget macvim reattach-to-user-namespace mongodb sshfs)
linuxbrew=(gcc cmake)
osxcask=(slack mongodb-compass osxfuse hyper)

# Execute if not osx
if [ "$(uname)" = "Darwin" ]; then

  echo Do you want to install/update/upgrade brew and brew cask on os x? y/n
  read var
  if [ $var = "y" ]; then

    # Install or update brew
    if ! (brew --version > /dev/null); then
      /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    else
      brew update
      brew upgrade
    fi

    # Install packages
    pkgs=("${allbrew[@]}" "${osxbrew[@]}")
    iPkg brew ${pkgs[@]}

    # Cask
    if ! (brew cask --version > /dev/null); then
      brew tap caskroom/cask
      brew install brew-cask
    fi

    iPkg cask ${osxcask[@]}

    brew cleanup

  fi

fi

# Execute if not linux
if [ "$(uname)" = "Linux" ]; then

  echo Do you want to install/update/upgrade linuxbrew on linux? y/n
  echo Handle Linux things? y/n
  read var
  if [ $var = "y" ]; then

    if ! (brew --version > /dev/null); then
      git clone https://github.com/Linuxbrew/brew.git ~/.linuxbrew
    else
      brew update
      brew upgrade
    fi

    # Install packages
    pkgs=("${allbrew[@]}" "${linuxbrew[@]}")
    iPkg brew ${pkgs[@]}
  fi

fi
