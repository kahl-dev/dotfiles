╔═══════════════════════════════════════════════════════════════╗
║                    TMUX CHEATSHEET                           ║
║                   Prefix: Ctrl+s                             ║
╚═══════════════════════════════════════════════════════════════╝

SESSIONS
  <prefix> C-c    Create new session
  <prefix> Q      Kill session
  <prefix> o      Switch session

WINDOWS  
  <prefix> c      Create new window
  <prefix> X      Kill window
  C-S-Left/Right  Move window left/right

PANES
  <prefix> |      Split horizontal
  <prefix> -      Split vertical  
  <prefix> x      Kill pane
  <prefix> z      Zoom/unzoom

NAVIGATION
  C-h/j/k/l       Move between panes (vim-aware)
  C-\             Last pane

RESIZE
  <prefix> Left/Down/Up/Right    Resize panes
  <prefix> C-h/j/k/l             Alternative resize

COPY MODE
  <prefix> Enter  Enter copy mode
  M-Enter         Enter copy mode
  v               Start selection
  C-v             Rectangle select
  y               Yank/copy

TOOLS
  <prefix> \      Help menu
  <prefix> j      Command palette
  <prefix> k      This cheatsheet
  <prefix> u      URL finder
  <prefix> r      Reload config

PLUGINS (TPM)
  M-i             Install plugins
  M-u             Update plugins
  M-x             Clean plugins

NESTED SESSIONS
  C-]             Toggle nested mode

MOUSE
  Click           Select panes/windows
  Drag            Resize panes
  Right-click     Context menu