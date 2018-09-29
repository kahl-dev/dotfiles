# Easy remove submodules
deinitSubmodule() {
  git submodule deinit "$@"
  git rm -r "$@"
  rm -Rf .git/modules/"$@"
  rm -Rf "$@"
}
