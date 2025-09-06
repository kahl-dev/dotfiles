╔═══════════════════════════════════════════════════════════════╗
║                    TMUX CHEATSHEET                           ║
║                   Prefix: Ctrl+s                             ║
╚═══════════════════════════════════════════════════════════════╝

SESSIONS
  <prefix> C-c    Create new session
  <prefix> o      SessionX (enhanced session switcher)

WINDOWS  
  <prefix> c      Create new window
  C-S-Left/Right  Move window left/right

PANES
  <prefix> |      Split horizontal
  <prefix> -      Split vertical
  <prefix> _      Split vertical (full height)
  <prefix> z      Zoom/unzoom
  <prefix> B      Break pane to new window
  <prefix> E      Join pane from another window

KILL/DELETE
  <prefix> x      Kill current pane
  <prefix> X      Kill current window  
  <prefix> Q      Kill session (with confirmation)

NAVIGATION
  C-h/j/k/l       Move between panes (vim-aware)
  C-\             Last pane

RESIZE
  <prefix> Left/Down/Up/Right    Resize panes
  <prefix> C-h/j/k/l             Alternative resize

COPY MODE
  <prefix> Enter  Enter copy mode
  C-[             Enter copy mode
  v               Start selection
  C-v             Rectangle select
  y               Yank/copy (via rclip)

TOOLS
  <prefix> ?      This cheatsheet
  <prefix> u      URL finder
  <prefix> r      Reload config
  <prefix> g      LazyGit
  <prefix> b      Btop (system monitor)
  <prefix> m      Glow (markdown viewer)

PLUGINS (TPM)
  M-i             Install plugins
  M-u             Update plugins
  M-x             Clean plugins

NESTED SESSIONS
  C-]             Toggle nested mode

MOUSE
  Click           Select panes/windows
  Drag            Resize panes
  Right-click     Context menu (tmux-menus)
  
ADVANCED
  <prefix> <      Window menu (swap, rename, etc.)
  <prefix> >      Pane menu (split, swap, kill, etc.)
  
CLIPBOARD (Remote Bridge)
  All copy operations use rclip for remote/local sync
  Works automatically across SSH sessions