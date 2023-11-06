# Path to the history file.
HISTFILE="$ZDOTDIR/custom/.zsh_history"

# The maximum number of events to keep in the internal history.
HISTSIZE=10000

# The maximum number of events to save in the history file.
SAVEHIST=10000

# History Options
setopt APPEND_HISTORY             # Append history list to the history file
setopt EXTENDED_HISTORY           # Save each command's timestamp and duration
setopt HIST_EXPIRE_DUPS_FIRST     # Expire duplicate entries first when trimming history
setopt HIST_FIND_NO_DUPS          # Ignore duplicates when searching history

# setopt HIST_IGNORE_ALL_DUPS       # Remove old duplicate entries from history list
# setopt HIST_IGNORE_DUPS           # Ignore consecutive duplicate entries

setopt HIST_IGNORE_SPACE          # Ignore commands starting with space
# setopt HIST_NO_FUNCTIONS          # Do not save functions in history list
setopt HIST_REDUCE_BLANKS         # Remove superfluous blanks from history items
# setopt HIST_SAVE_NO_DUPS          # Omit older duplicates when writing history file
setopt HIST_VERIFY                # Don’t execute command immediately on history expansion
# setopt INC_APPEND_HISTORY         # Add commands to history as they are typed
setopt INC_APPEND_HISTORY_TIME    # Add timestamp to history entries (if EXTENDED_HISTORY is on)
setopt SHARE_HISTORY              # Share history between all zsh sessions
