export GIT_LIA_COMMIT_MESSAGE_METHOD="editor"

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

path_exists "$DOTFILES/bin" && alias glct="git-lia-toggl"

_glct_completions() {
  local -a commands
  local cur_context="$curcontext" state line

  typeset -A opt_args

  if ((CURRENT == 2)); then
    commands=('feat' 'fix' 'docs' 'style' 'refactor' 'perf' 'test' 'chore')
    _describe -t commands "glct type" commands
  fi

  return 1
}

compdef _glct_completions glct

# Git-lia completion for zsh

_git-lia() {
  local -a commands
  commands=(
    'start:Start a new feature branch.'
    'preview:Merge feature branch into a preview or staging branch.'
    'finish:Merge feature branch into the main/target branch.'
    'commit:Commit changes with options to specify type, scope, and indicate breaking changes.'
  )

  local -a commit_types
  commit_types=(
    'feat:Introduces a new feature to the application.'
    'fix:Fixes a bug or issue.'
    'docs:Changes related to documentation.'
    'style:Code style changes (formatting, missing semi colons, etc).'
    'refactor:Code changes that neither fix a bug nor introduce a feature.'
    'perf:Changes that improve performance.'
    'test:Adding or updating tests.'
  )

  local curcontext="$curcontext" state line
  typeset -A opt_args

  _arguments -C \
    '1: :->command' \
    '*:: :->arg'

  case $state in
  command)
    _describe -t commands "git-lia commands" commands
    ;;

  arg)
    case $line[1] in
    commit)
      if [[ ${line[(I) - s]} -gt 0 && ${line[(I) - n]} -gt 0 ]]; then
        # User has tried to use both -s and -n together
        # Display an error message and prevent further completion
        _message "Cannot use -s and -n together"
      else
        _arguments -C \
          "-t[Specify the commit type]:Commit Type:_commit_types" \
          '-s[Specify the commit scope]:Commit Scope:' \
          '-m[Specify the commit message]:Commit Message:' \
          '-b[Indicate a breaking change]' \
          '-n[Commit without specifying a scope]'
      fi
      ;;
    preview)
      _arguments -C '-p[View GitLab pipeline status]'
      ;;
    finish)
      _arguments -C '-p[View GitLab pipeline status]'
      ;;
    esac
    ;;

  esac
}

_commit_types() {
  local -a commit_type_options
  commit_type_options=(
    'feat:Introduces a new feature to the application.'
    'fix:Fixes a bug or issue.'
    'docs:Changes related to documentation.'
    'style:Code style changes (formatting, missing semi colons, etc).'
    'refactor:Code changes that neither fix a bug nor introduce a feature.'
    'perf:Changes that improve performance.'
    'test:Adding or updating tests.'
  )
  _describe -t commit_types "commit types" commit_type_options
}

compdef _git-lia git-lia
