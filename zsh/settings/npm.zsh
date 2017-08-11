# -----------------------------------------------------------------------------
# npm || Set global npm settings
# -----------------------------------------------------------------------------
NODE_MODULES="${HOME}/.node_modules"
PATH="$PATH:$NODE_MODULES/bin"
# Unset manpath so we can inherit from /etc/manpath via the `manpath` command
unset MANPATH
export MANPATH="$NODE_MODULES/share/man:$(manpath)"

Plugins+=(npm);
