# zsh-syntax-highlighting
# highlight syntax in zsh
# https://github.com/zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-syntax-highlighting

# zsh-completions
# additional completion definitions
# https://github.com/zsh-users/zsh-completions
zinit light zsh-users/zsh-completions

# zsh-autosuggestions
# Fish-like autosuggestions for zsh.
# https://github.com/zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-autosuggestions
ZSH_AUTOSUGGEST_USE_ASYNC=true

# zsh-autopair
# Auto-pairing for zsh
# https://github.com/hlissner/zsh-autopair
zinit light hlissner/zsh-autopair

# zoxide
# easily jump to directories
# https://github.com/ajeetdsouza/zoxide
if command_exists zoxide; then
  eval "$(zoxide init --cmd cd zsh)"
  # Guard: silently skip when zoxide is unreachable (PATH issues)
  __zoxide_hook() { (( $+commands[zoxide] )) && \command zoxide add -- "$(__zoxide_pwd)"; }
fi

# zinit ice as"command" from"gh-r" bpick"atuin-*.tar.gz" mv"atuin*/atuin -> atuin" \
#   atclone"./atuin init zsh > init.zsh; ./atuin gen-completions --shell zsh > _atuin" \
#   atpull"%atclone" src"init.zsh"
# zinit light atuinsh/atuin

# zinit light ajeetdsouza/zoxide

# zinit ice wait"2" as"command" from"gh-r" lucid \
#   mv"zoxide*/zoxide -> zoxide" \
#   atclone"./zoxide init zsh > init.zsh" \
#   atpull"%atclone" src"init.zsh" nocompile'!'
# zinit light ajeetdsouza/zoxide

# Alias tips
# Show helpful alias suggestions when you mistype them
# https://github.com/djui/alias-tips
zinit light "djui/alias-tips"
export ZSH_PLUGINS_ALIAS_TIPS_TEXT="Alias tip: "
export ZSH_PLUGINS_ALIAS_TIPS_FORCE=0

# the fuck
# correct mistyped command
# https://github.com/nvbn/thefuck
if command_exists thefuck; then
  unsetopt correct_all
  eval $(thefuck --alias fuck)
fi

# ripgrep
# fast search as replacement for grep
# Doc: https://github.com/BurntSushi/ripgrep/

# zinit for from'gh-r' sbin'**/rg -> rg' BurntSushi/ripgrep

# Add in snippets
# TODO; make notes for all usefull osx commands

# not possible because of https://github.com/zdharma-continuum/zinit/issues/504
# if is_macos; then
#   zi ice svn
#   zi snippet OMZP::macos
# fi
