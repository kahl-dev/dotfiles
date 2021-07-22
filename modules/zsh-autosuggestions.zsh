# Fish-like fast/unobtrusive autosuggestions for zsh.
# Doc: https://github.com/zsh-users/zsh-autosuggestions
zinit wait lucid atload'_zsh_autosuggest_start' light-mode for \
    zsh-users/zsh-autosuggestions

ZSH_AUTOSUGGEST_USE_ASYNC=true


bindkey '^z' autosuggest-toggle # ctrl + z; Toggles between enabled/disabled suggestions.
bindkey '^f' autosuggest-accept # accept suggestions
