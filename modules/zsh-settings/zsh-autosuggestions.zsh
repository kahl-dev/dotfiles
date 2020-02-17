# DOCS: https://github.com/zsh-users/zsh-autosuggestions

# Suggestion Highlight Style
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE=4

# Disabling suggestion for large buffers
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# Enable Asynchronous Mode
ZSH_AUTOSUGGEST_USE_ASYNC=true

bindkey '^ ' autosuggest-accept
bindkey '^z' autosuggest-toggle