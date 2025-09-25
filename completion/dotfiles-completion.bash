#!/usr/bin/env bash

# Bash completion for dotfiles install-profile and install-standalone scripts

# Cache the detected dotfiles root so we only resolve it once per shell.
_DOTFILES_COMPLETION_ROOT=""

_dotfiles_completion_root() {
    if [[ -n "${_DOTFILES_COMPLETION_ROOT}" ]]; then
        printf '%s\n' "${_DOTFILES_COMPLETION_ROOT}"
        return 0
    fi

    if [[ -n "${DOTFILES:-}" && -d "${DOTFILES}/meta" ]]; then
        _DOTFILES_COMPLETION_ROOT="${DOTFILES}"
        printf '%s\n' "${_DOTFILES_COMPLETION_ROOT}"
        return 0
    fi

    local source_path="${BASH_SOURCE[0]:-}"
    if [[ -z "${source_path}" ]]; then
        return 1
    fi

    local completion_dir
    completion_dir="$(cd "$(dirname "${source_path}")" 2>/dev/null && pwd)"
    if [[ -z "${completion_dir}" ]]; then
        return 1
    fi

    local resolved_root
    resolved_root="$(cd "${completion_dir}/.." 2>/dev/null && pwd)"
    if [[ -z "${resolved_root}" ]]; then
        return 1
    fi

    _DOTFILES_COMPLETION_ROOT="${resolved_root}"
    printf '%s\n' "${_DOTFILES_COMPLETION_ROOT}"
    return 0
}

_dotfiles_list_files() {
    local search_dir="$1"
    shift
    local -a find_args=("$@")

    if [[ -d "${search_dir}" ]]; then
        find "${search_dir}" "${find_args[@]}" 2>/dev/null |
            LC_COLLATE=C sort
    fi
}

_dotfiles_install_profile() {
    local cur dotfiles_dir
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"

    dotfiles_dir="$(_dotfiles_completion_root)" || return 0

    local recipes
    recipes="$( _dotfiles_list_files "${dotfiles_dir}/meta/recipes" -type f -exec basename {} \; )"

    # shellcheck disable=SC2207
    COMPREPLY=($(compgen -W "${recipes}" -- "${cur}"))
    return 0
}

_dotfiles_install_standalone() {
    local cur dotfiles_dir
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"

    dotfiles_dir="$(_dotfiles_completion_root)" || return 0

    local ingredients
    ingredients="$( _dotfiles_list_files "${dotfiles_dir}/meta/ingredients" -type f -name '*.yaml' -exec basename {} .yaml \; )"

    # shellcheck disable=SC2207
    COMPREPLY=($(compgen -W "${ingredients}" -- "${cur}"))
    return 0
}

# Register completion functions
complete -F _dotfiles_install_profile install-profile
complete -F _dotfiles_install_standalone install-standalone

# Also handle when scripts are called with full path
complete -F _dotfiles_install_profile ./install-profile
complete -F _dotfiles_install_standalone ./install-standalone
