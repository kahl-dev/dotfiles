# Fish-like fast/unobtrusive autosuggestions for zsh.
# Doc: https://github.com/zsh-users/zsh-autosuggestions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
fi

if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    plugins+=(zsh-autosuggestions)

    ZSH_AUTOSUGGEST_USE_ASYNC=true


    bindkey '^z' autosuggest-toggle # ctrl + z; Toggles between enabled/disabled suggestions.
    bindkey '^f' autosuggest-accept # accept suggestions
fi
