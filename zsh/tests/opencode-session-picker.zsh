#!/usr/bin/env zsh

set -eu

script_directory="${0:A:h}"
dotfiles_directory="${script_directory:h:h}"
temporary_directory="$(mktemp -d)"
fake_binary_directory="${temporary_directory}/bin"
command_log="${temporary_directory}/commands.log"
fzf_input_file="${temporary_directory}/fzf-input.log"
session_directory="${temporary_directory}/project directory"
mkdir -p "$fake_binary_directory" "$session_directory"

cleanup() {
  rm -rf "$temporary_directory"
}
trap cleanup EXIT

cat > "${fake_binary_directory}/opencode" <<'EOF'
#!/usr/bin/env zsh
if [[ "$1" == "session" && "$2" == "list" && "$3" == "--format" && "$4" == "json" ]]; then
  print -r -- 'command=session-list' >> "$COMMAND_LOG"
  print -r -- "$FAKE_SESSION_JSON"
  exit "${FAKE_SESSION_LIST_STATUS:-0}"
fi

print -r -- 'command=launch' >> "$COMMAND_LOG"
print -r -- "working-directory=${PWD}" >> "$COMMAND_LOG"
print -r -- "argument-count=$#" >> "$COMMAND_LOG"
for argument in "$@"; do
  print -r -- "argument=${argument}" >> "$COMMAND_LOG"
done
exit "${FAKE_LAUNCH_STATUS:-0}"
EOF

cat > "${fake_binary_directory}/fzf" <<'EOF'
#!/usr/bin/env zsh
cat > "$FZF_INPUT_FILE"
print -r -- 'command=fzf' >> "$COMMAND_LOG"
for argument in "$@"; do
  print -r -- "fzf-argument=${argument}" >> "$COMMAND_LOG"
done
print -rn -- "${FAKE_FZF_OUTPUT:-}"
exit "${FAKE_FZF_STATUS:-0}"
EOF

chmod +x "${fake_binary_directory}/opencode" "${fake_binary_directory}/fzf"

export PATH="${fake_binary_directory}:${PATH}"
export COMMAND_LOG="$command_log"
export FZF_INPUT_FILE="$fzf_input_file"

source "${dotfiles_directory}/zsh/config/opencode.zsh"

fail() {
  print -u2 -- "FAIL: $1"
  exit 1
}

assert_equals() {
  [[ "$1" == "$2" ]] || fail "expected ${(qqq)1}, received ${(qqq)2}"
}

assert_contains() {
  grep -Fqx -- "$2" "$1" || fail "missing '$2' in $1"
}

assert_absent() {
  if grep -Fqx -- "$2" "$1"; then
    fail "unexpected '$2' in $1"
  fi
}

assert_occurrences() {
  local actual_count
  actual_count="$(grep -Fxc -- "$2" "$1" || true)"
  assert_equals "$3" "$actual_count"
}

reset_fake_state() {
  : > "$command_log"
  : > "$fzf_input_file"
  export FAKE_SESSION_LIST_STATUS=0
  export FAKE_LAUNCH_STATUS=0
  export FAKE_FZF_STATUS=0
  export FAKE_SESSION_JSON="[{\"id\":\"session-one\",\"title\":\"Door session\",\"directory\":\"${session_directory}\"}]"
  export FAKE_FZF_OUTPUT=$'enter\nsession-one\tDoor session\t'"${session_directory}"$'\n'
}

case_normal_resume() {
  reset_fake_state
  local caller_directory="$PWD"
  ocs || fail 'normal resume returned non-zero'
  assert_equals "$caller_directory" "$PWD"
  assert_occurrences "$command_log" 'command=session-list' '1'
  assert_contains "$command_log" 'command=launch'
  assert_contains "$command_log" "working-directory=${session_directory}"
  assert_contains "$command_log" 'argument-count=2'
  assert_contains "$command_log" 'argument=--session'
  assert_contains "$command_log" 'argument=session-one'
  assert_absent "$command_log" 'argument=--fork'
}

case_fork_resume() {
  reset_fake_state
  export FAKE_FZF_OUTPUT=$'ctrl-f\nsession-one\tDoor session\t'"${session_directory}"$'\n'
  ocs || fail 'fork resume returned non-zero'
  assert_contains "$command_log" 'argument-count=3'
  assert_contains "$command_log" 'argument=--session'
  assert_contains "$command_log" 'argument=session-one'
  assert_contains "$command_log" 'argument=--fork'
}

case_escape_cancels() {
  reset_fake_state
  export FAKE_FZF_STATUS=130
  ocs || fail 'escape should return zero'
  assert_absent "$command_log" 'command=launch'
}

case_no_match_cancels() {
  reset_fake_state
  export FAKE_FZF_OUTPUT=''
  ocs || fail 'no match should return zero'
  assert_absent "$command_log" 'command=launch'
}

case_unicode_title_is_preserved() {
  reset_fake_state
  export FAKE_SESSION_JSON="[{\"id\":\"session-one\",\"title\":\"Tür 🚪 Session\",\"directory\":\"${session_directory}\"}]"
  export FAKE_FZF_OUTPUT=$'enter\nsession-one\tTür 🚪 Session\t'"${session_directory}"$'\n'
  ocs || fail 'unicode title selection returned non-zero'
  grep -Fq $'session-one\tTür 🚪 Session\t' "$fzf_input_file" || fail 'unicode title was not presented to fzf'
}

case_missing_dependency_fails() {
  reset_fake_state
  local original_path="$PATH"
  local dependency_directory="${temporary_directory}/dependency-bin"
  mkdir "$dependency_directory"
  ln -s "${fake_binary_directory}/opencode" "${dependency_directory}/opencode"
  export PATH="$dependency_directory"
  if ocs 2>"${temporary_directory}/error.log"; then
    fail 'missing jq should fail'
  fi
  export PATH="$original_path"
  grep -Fq 'ocs requires jq on PATH' "${temporary_directory}/error.log" || fail 'missing jq error was not actionable'
}

case_empty_list_is_quiet() {
  reset_fake_state
  export FAKE_SESSION_JSON='[]'
  ocs >"${temporary_directory}/output.log" || fail 'empty list should return zero'
  grep -Fq 'No OpenCode sessions found.' "${temporary_directory}/output.log" || fail 'empty list message missing'
}

case_session_listing_failure_surfaces() {
  reset_fake_state
  export FAKE_SESSION_LIST_STATUS=17
  if ocs 2>"${temporary_directory}/error.log"; then
    fail 'session listing failure should fail'
  else
    assert_equals '17' "$?"
  fi
  grep -Fq 'ocs could not list OpenCode sessions.' "${temporary_directory}/error.log" || fail 'session listing error missing'
}

case_backslash_values_round_trip() {
  reset_fake_state
  local backslash_session_id='session\one'
  local backslash_title='Door \ Session'
  export FAKE_SESSION_JSON="[{\"id\":\"session\\\\one\",\"title\":\"Door \\\\ Session\",\"directory\":\"${session_directory}\"}]"
  export FAKE_FZF_OUTPUT=$'enter\n'"${backslash_session_id}"$'\t'"${backslash_title}"$'\t'"${session_directory}"$'\n'
  ocs || fail 'backslash values should resume normally'
  assert_contains "$command_log" "argument=${backslash_session_id}"
  grep -Fq $'session\\one\tDoor \\ Session\t' "$fzf_input_file" || fail 'backslash values were not presented to fzf'
}

case_malformed_json_fails() {
  reset_fake_state
  export FAKE_SESSION_JSON='{'
  if ocs 2>"${temporary_directory}/error.log"; then
    fail 'malformed JSON should fail'
  fi
  grep -Fq 'session list returned invalid JSON' "${temporary_directory}/error.log" || fail 'malformed JSON error missing'
}

case_wrong_schema_fails() {
  reset_fake_state
  export FAKE_SESSION_JSON='[{"id":"session-one","title":"Door session"}]'
  if ocs 2>"${temporary_directory}/error.log"; then
    fail 'wrong schema should fail'
  fi
  grep -Fq 'session list returned invalid JSON' "${temporary_directory}/error.log" || fail 'wrong schema error missing'
}

case_tsv_unsafe_fields_fail() {
  reset_fake_state
  export FAKE_SESSION_JSON="[{\"id\":\"session\\tone\",\"title\":\"Door session\",\"directory\":\"${session_directory}\"}]"
  if ocs 2>"${temporary_directory}/error.log"; then
    fail 'TSV-unsafe session ID should fail'
  fi
  grep -Fq 'session list returned invalid JSON' "${temporary_directory}/error.log" || fail 'TSV safety error missing'
}

case_jq_status_propagates() {
  reset_fake_state
  local wrapper_directory="${temporary_directory}/jq-wrapper"
  local original_path="$PATH"
  local real_jq
  real_jq="$(command -v jq)"
  mkdir "$wrapper_directory"
  cat > "${wrapper_directory}/jq" <<EOF
#!/usr/bin/env zsh
if [[ "\$1" == "-e" ]]; then
  exit 29
fi
exec "${real_jq}" "\$@"
EOF
  chmod +x "${wrapper_directory}/jq"
  export PATH="${wrapper_directory}:${PATH}"
  if ocs 2>"${temporary_directory}/error.log"; then
    fail 'jq boundary failure should fail'
  else
    assert_equals '29' "$?"
  fi
  export PATH="$original_path"
  grep -Fq 'session list returned invalid JSON' "${temporary_directory}/error.log" || fail 'jq boundary error missing'
}

case_missing_directory_fails() {
  reset_fake_state
  local missing_directory="${temporary_directory}/missing directory"
  export FAKE_SESSION_JSON="[{\"id\":\"session-one\",\"title\":\"Door session\",\"directory\":\"${missing_directory}\"}]"
  export FAKE_FZF_OUTPUT=$'enter\nsession-one\tDoor session\t'"${missing_directory}"$'\n'
  if ocs 2>"${temporary_directory}/error.log"; then
    fail 'missing directory should fail'
  fi
  grep -Fq 'session directory does not exist' "${temporary_directory}/error.log" || fail 'missing directory error missing'
}

case_picker_failure_surfaces() {
  reset_fake_state
  export FAKE_FZF_STATUS=7
  if ocs 2>"${temporary_directory}/error.log"; then
    fail 'picker failure should fail'
  else
    assert_equals '7' "$?"
  fi
  grep -Fq 'ocs picker failed with exit status 7.' "${temporary_directory}/error.log" || fail 'picker error missing'
}

case_launch_status_propagates() {
  reset_fake_state
  export FAKE_LAUNCH_STATUS=23
  if ocs; then
    fail 'launch failure should fail'
  else
    assert_equals '23' "$?"
  fi
}

case_unexpected_arguments_fail() {
  reset_fake_state
  if ocs unexpected 2>"${temporary_directory}/error.log"; then
    fail 'unexpected arguments should fail'
  fi
  grep -Fq 'usage: ocs' "${temporary_directory}/error.log" || fail 'usage message missing'
}

case_normal_resume
case_fork_resume
case_escape_cancels
case_no_match_cancels
case_unicode_title_is_preserved
case_missing_dependency_fails
case_empty_list_is_quiet
case_session_listing_failure_surfaces
case_backslash_values_round_trip
case_malformed_json_fails
case_wrong_schema_fails
case_tsv_unsafe_fields_fail
case_jq_status_propagates
case_missing_directory_fails
case_picker_failure_surfaces
case_launch_status_propagates
case_unexpected_arguments_fail

print -- 'OpenCode session picker behavior passed.'
