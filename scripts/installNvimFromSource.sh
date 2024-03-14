if [ ! -d ~/$DOTFILES/build ]; then
	mkdir ~/$DOTFILES/build
fi

git clone git@github.com:neovim/neovim.git ~/$DOTFILES/build/neovim
cd ~/$DOTFILES/build/neovim
make CMAKE_BUILD_TYPE=Release 
#CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=$DOTFILES/bin/nvim"
rm -Rf $DOTFILES/bin/nvim
make install CMAKE_INSTALL_PREFIX=$DOTFILES/bin/nvim
cd -
rm -rf ~/$DOTFILES/build/neovim
