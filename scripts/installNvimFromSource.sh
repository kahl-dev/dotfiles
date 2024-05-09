[ ! -d "$DOTFILES/build" ] && mkdir -p "$DOTFILES/build"

rm -f ~/.local/state/nvim/log
rm -f ~/.local/state/nvim/*.log

git clone git@github.com:neovim/neovim.git "$DOTFILES/build/neovim"
cd "$DOTFILES/build/neovim"
# git checkout stable

rm -rf "$DOTFILES/bin/nvim"
make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX="$DOTFILES/bin/nvim"

cd $DOTFILES/build/neovim
make install

cd $DOTFILES
rm -rf "$DOTFILES/build/neovim"
