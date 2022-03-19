
[BACK](../README.md)

# SSH

This Dotfiles contains some ssh features. 

## VIM Markdown Viewer

To enable VIM markdown viewer add ssh port forwarding and add your server url to
the local zsh config

```config
~/.ssh/config

LocalForward 8080 localhost:8080
```

```zsh
~/.zshrc-local

export MARKDOWN_PREV_URL='12.34.56.78'
```
