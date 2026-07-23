alias oc='opencode'
alias occ='opencode --continue'
alias ocu='opencode stats'

ocs() {
  if (( $# != 0 )); then
    print -u2 -- 'usage: ocs'
    return 1
  fi

  local required_command
  for required_command in opencode jq fzf; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
      print -u2 -- "ocs requires ${required_command} on PATH. Install it and retry."
      return 1
    fi
  done

  (
    local sessions_json session_rows session_id session_directory
    local session_list_status jq_status picker_output picker_status selection_key selected_session_line
    local -a picker_lines

    if sessions_json="$(opencode session list --format json)"; then
      :
    else
      session_list_status=$?
      print -u2 -- 'ocs could not list OpenCode sessions.'
      return "$session_list_status"
    fi

    if print -r -- "$sessions_json" | jq -e '
      def valid_tsv_string:
        type == "string" and
        length > 0 and
        (test("[\u0000-\u001F\u007F]") | not);

      type == "array" and
      all(.[];
        type == "object" and
        (.id | valid_tsv_string) and
        (.title | valid_tsv_string) and
        (.directory | valid_tsv_string)
      ) and
      ([.[].id] | unique | length) == length
    ' >/dev/null; then
      :
    else
      jq_status=$?
      print -u2 -- 'ocs session list returned invalid JSON or an unsupported session schema.'
      return "$jq_status"
    fi

    if session_rows="$(print -r -- "$sessions_json" | jq -r '.[] | [.id, .title, .directory] | join("\t")')"; then
      :
    else
      jq_status=$?
      print -u2 -- 'ocs could not prepare OpenCode sessions for selection.'
      return "$jq_status"
    fi

    if [[ -z "$session_rows" ]]; then
      print -- 'No OpenCode sessions found.'
      return 0
    fi

    if picker_output="$(print -r -- "$session_rows" | fzf \
      --expect=ctrl-f,enter \
      --exit-0 \
      --delimiter='\t' \
      --with-nth=2,3 \
      --header='Enter resumes normally, Ctrl+F starts a fork, Esc cancels')"; then
      picker_lines=("${(@f)picker_output}")
    else
      picker_status=$?
      if (( picker_status == 130 )); then
        return 0
      fi
      print -u2 -- "ocs picker failed with exit status ${picker_status}."
      return "$picker_status"
    fi

    selection_key="${picker_lines[1]:-}"
    selected_session_line="${picker_lines[2]:-}"
    if [[ -z "$selected_session_line" ]]; then
      return 0
    fi

    if [[ "$selection_key" != 'enter' && "$selection_key" != 'ctrl-f' ]]; then
      print -u2 -- 'ocs picker returned an invalid selection key.'
      return 1
    fi

    if [[ "$selected_session_line" != *$'\t'* ]]; then
      print -u2 -- 'ocs picker returned an invalid session selection.'
      return 1
    fi
    session_id="${selected_session_line%%$'\t'*}"

    if session_directory="$(print -r -- "$sessions_json" | jq -er --arg session_id "$session_id" '.[] | select(.id == $session_id) | .directory')"; then
      :
    else
      jq_status=$?
      print -u2 -- 'ocs could not resolve the selected session directory.'
      return "$jq_status"
    fi

    if [[ ! -d "$session_directory" ]]; then
      print -u2 -- "ocs session directory does not exist: ${session_directory}"
      return 1
    fi

    builtin cd -- "$session_directory" || return 1
    if [[ "$selection_key" == 'ctrl-f' ]]; then
      opencode --session "$session_id" --fork
    else
      opencode --session "$session_id"
    fi
  )
}
