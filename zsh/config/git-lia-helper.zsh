export GIT_LIA_COMMIT_MESSAGE_METHOD="editor"

# look if git-lia is available, if not look if the binary is in 
# $DOTFILES/bin/git-lia/git-lia and source that
if ! command -v git-lia &> /dev/null; then
  if [ -f "$DOTFILES/bin/git-lia/git-lia" ]; then
    export PATH=$PATH:$DOTFILES/bin/git-lia
  fi
fi

alias gl="git lia"
alias gls="git lia start"
alias glp="git lia preview"
alias glpp="git lia preview -p"
alias glf="git lia finish"
alias glfp="git lia finish -p"

alias glc="git lia commit"
alias gfeat="git lia feat"
alias gfix="git lia fix"
alias gchore="git lia chore"
alias gdocs="git lia docs"
alias gstyle="git lia style"
alias gref="git lia refactor"
alias gperf="git lia perf"
alias gtest="git lia test"

gfeats() { if [ "$#" -eq 1 ]; then git-lia commit -t "feat" -m "$1"; else git-lia commit -t "feat" -s "$1" -m "$2"; fi; }
gfixs() { if [ "$#" -eq 1 ]; then git-lia commit -t "fix" -m "$1"; else git-lia commit -t "fix" -s "$1" -m "$2"; fi; }
gchores() { if [ "$#" -eq 1 ]; then git-lia commit -t "chore" -m "$1"; else git-lia commit -t "chore" -s "$1" -m "$2"; fi; }
gdocss() { if [ "$#" -eq 1 ]; then git-lia commit -t "docs" -m "$1"; else git-lia commit -t "docs" -s "$1" -m "$2"; fi; }
gstyles() { if [ "$#" -eq 1 ]; then git-lia commit -t "style" -m "$1"; else git-lia commit -t "style" -s "$1" -m "$2"; fi; }
grefs() { if [ "$#" -eq 1 ]; then git-lia commit -t "refactor" -m "$1"; else git-lia commit -t "refactor" -s "$1" -m "$2"; fi; }
gperfs() { if [ "$#" -eq 1 ]; then git-lia commit -t "perf" -m "$1"; else git-lia commit -t "perf" -s "$1" -m "$2"; fi; }
gtests() { if [ "$#" -eq 1 ]; then git-lia commit -t "test" -m "$1"; else git-lia commit -t "test" -s "$1" -m "$2"; fi; }

get_ticket_id_from_toggl() {
    # Get the Toggl API token from the environment variable
    local TOGGL_API_TOKEN="${T}"

    if [[ -z "${TOGGL_API_TOKEN}" ]]; then
        echo "Error: Toggl API token is not set in the T environment variable." >&2
        return 1
    fi

    # Execute the curl command
    local RESPONSE=$(curl -s "https://api.track.toggl.com/api/v9/me/time_entries/current" \
                           -H "Content-Type: application/json" \
                           -u "${TOGGL_API_TOKEN}:api_token")

    # Extract the ticket ID
    local TICKET_ID=$(echo "${RESPONSE}" | grep -oE "[A-Z]+-[0-9]+")

    if [[ -z "$TICKET_ID" ]]; then
        echo "Error: Could not fetch Toggl ticket ID. Aborting." >&2
        return 1
    fi


    echo "${TICKET_ID}"
}
VALID_TYPES=("feat" "fix" "docs" "style" "refactor" "perf" "test" "chore")

glct() {
    if [[ $# -lt 1 || $# -gt 2 ]]; then
        echo "Usage: glct <type> [message]"
        return 1
    fi

    local TYPE="$1"
    local MESSAGE="$2"

    if [[ ! " ${VALID_TYPES[@]} " =~ " ${TYPE} " ]]; then
        echo "Error: Invalid type. Must be one of: ${VALID_TYPES[*]}"
        return 1
    fi

    local SCOPE=$(get_ticket_id_from_toggl)
    if [[ $? -ne 0 ]]; then # Check the exit status of the function
        return 1
    fi

    if [[ -z "$SCOPE" ]]; then
        echo "Error: No Toggl ticket ID found. Aborting commit." >&2
        return 1
    fi

    if [[ -z "$MESSAGE" ]]; then
        git-lia commit -t "$TYPE" -s "$SCOPE"
    else
        git-lia commit -t "$TYPE" -s "$SCOPE" -m "$MESSAGE"
    fi
}

_glct_completions() {
    local -a commands
    local cur_context="$curcontext" state line

    typeset -A opt_args

    if (( CURRENT == 2 )); then
        commands=('feat' 'fix' 'docs' 'style' 'refactor' 'perf' 'test' 'chore')
        _describe -t commands "glct type" commands
    fi

    return 1
}

compdef _glct_completions glct
