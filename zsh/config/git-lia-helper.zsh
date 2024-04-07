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

VALID_TYPES=("feat" "fix" "docs" "style" "refactor" "perf" "test" "chore")

_is_path_exists "$DOTFILES/bin" && alias glct="git-lia-toggl"

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
