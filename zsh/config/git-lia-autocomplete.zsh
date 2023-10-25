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
          if [[ ${line[(I)-s]} -gt 0 && ${line[(I)-n]} -gt 0 ]]; then
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

