# Git pull dotfiles repo recursive
(git -C $HOME/.dotfiles pull --rebase --recurse-submodules &) &> /dev/null
