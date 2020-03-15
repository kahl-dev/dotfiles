# Git pull dotfiles repo recursive
(git -C $HOME/.dotfiles pull &) &> /dev/null
(git -C $HOME/.dotfiles submodule update --remote --merge --init &) &> /dev/null

gde() {
  git diff -- . ':(exclude)*.min.js' ':(exclude)*.min.css'
}
