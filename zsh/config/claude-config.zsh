# -----------------------------------------------------------------------------
# Claude Config - AI utility scripts and tools
# -----------------------------------------------------------------------------
# bin/  - User-facing CLI tools (lit-ai-context)
# scripts/ - Supporting scripts used by Claude Code skills
# -----------------------------------------------------------------------------

if path_exists "$HOME/repos/claude-config/bin"; then
  export PATH="$HOME/repos/claude-config/bin:$PATH"
fi

if path_exists "$HOME/repos/claude-config/scripts"; then
  export PATH="$HOME/repos/claude-config/scripts:$PATH"
fi

# -----------------------------------------------------------------------------
# Default model
# -----------------------------------------------------------------------------
# Set here rather than as "model" in settings.json on purpose. Claude Code's
# quota and safety fallbacks persist the substituted model as the new default,
# but only when a model key already exists in user settings — and they bail out
# entirely when ANTHROPIC_MODEL is set. Keeping the default here means a
# mid-session model switch stays session-local instead of rewriting the config.
# Per-session overrides still win over this (claude --model, so the cf/co/cs
# aliases behave as expected).
# -----------------------------------------------------------------------------

export ANTHROPIC_MODEL='claude-fable-5[1m]'
