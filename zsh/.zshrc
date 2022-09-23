export DOTFILES=$HOME/.dotfiles
export ZSH="$DOTFILES/zsh/ohmyzsh"
export ZSH_CUSTOM=$DOTFILES/zsh/custom
ZSH_DISABLE_COMPFIX=true

if [ ! -d "$ZSH" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --keep-zshrc
    cd $HOME
fi


# https://stackoverflow.com/questions/592620/how-can-i-check-if-a-program-exists-from-a-bash-script
_exists() {
  command -v "$1" >/dev/null 2>&1
}

_raspberry() {
  _exists raspi-config
}

# Add modules
for file in $(find $HOME/.dotfiles/modules -type f -name "pre*.zsh" ! -name "_*.zsh" | sort -n); do
  source "$file";
done

# update automatically without asking
zstyle ':omz:update' mode auto

# Uncomment the following line to change how often to auto-update (in days).
zstyle ':omz:update' frequency 13

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

plugins=(git git-extras yarn)

for file in $(find $DOTFILES/modules -type f -name "*.zsh" ! -name "pre*.zsh" ! -name "_*.zsh" | sort -n); do
  source "$file";
done

source $ZSH/oh-my-zsh.sh

# Add modules
for file in $(find $HOME/.dotfiles/modules -type f -name "post*.zsh" ! -name "_*.zsh" | sort -n); do
  source "$file";
done

xdg-open() {
  open $@
}