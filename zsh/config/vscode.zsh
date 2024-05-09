# Choose between one [code, code-insiders or codium]
# The following line will make the plugin to open VS Code Insiders
# Invalid entries will be ignored, no aliases will be added

if [ ! -n "$SSH_CLIENT" ] || [ ! -n "$SSH_TTY" ]; then
  VSCODE=code
fi
