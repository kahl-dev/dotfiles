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
