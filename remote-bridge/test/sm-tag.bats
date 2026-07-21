#!/usr/bin/env bats

DOTFILES_ROOT="$BATS_TEST_DIRNAME/../.."
MOSH_CONFIG="$DOTFILES_ROOT/zsh/config/mosh.zsh"
ZSH_CONFIG="$DOTFILES_ROOT/zsh/.zshrc"

teardown() {
  if [ -n "${AGENT_SOCKET_PID:-}" ]; then
    kill "$AGENT_SOCKET_PID" 2>/dev/null || true
  fi
  if [ -n "${AGENT_SOCKET_DIR:-}" ]; then
    rm -rf "$AGENT_SOCKET_DIR"
  fi
  if [ -n "${TEST_HOST:-}" ]; then
    rm -rf "/tmp/sm-${TEST_HOST}" "/tmp/sm-${TEST_HOST}.pid"
  fi
}

@test "zsh startup does not source the removed SSH agent config" {
  run grep -F 'config/ssh-agent.zsh' "$ZSH_CONFIG"

  [ "$status" -ne 0 ]
}

make_agent_socket() {
  AGENT_SOCKET_DIR="$(mktemp -d)"
  AGENT_SOCKET="$AGENT_SOCKET_DIR/agent.sock"
  node -e 'require("net").createServer().listen(process.argv[1]); setInterval(() => {}, 1000)' "$AGENT_SOCKET" >/dev/null 2>&1 &
  AGENT_SOCKET_PID=$!
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    [ -S "$AGENT_SOCKET" ] && break
    sleep 0.1
  done
  [ -S "$AGENT_SOCKET" ]
}

@test "sm starts the socket tunnel for a tagged host" {
  run env MOSH_CONFIG="$MOSH_CONFIG" zsh -c '
    compdef() { :; }
    source "$MOSH_CONFIG"

    command_exists() { return 0; }
    ssh() {
      if [[ "$1" == "-G" ]]; then
        print -r -- "hostname example"
        print -r -- "tag remote-bridge"
        return 0
      fi
      return 1
    }
    _sm_with_host_lock() {
      shift
      "$@"
    }
    _sm_start_or_reuse_tunnel() {
      print -r -- "tunnel-started"
    }
    _sm_teardown_if_last() { :; }
    mosh() {
      print -r -- "mosh:$*"
    }

    sm example
  '

  [ "$status" -eq 0 ]
  [[ "$output" == *"tunnel-started"* ]]
  [[ "$output" == *"ClearAllForwardings=yes"* ]]
}

@test "sm runs plain mosh for an untagged host" {
  run env MOSH_CONFIG="$MOSH_CONFIG" zsh -c '
    compdef() { :; }
    source "$MOSH_CONFIG"

    command_exists() { return 0; }
    ssh() {
      if [[ "$1" == "-G" ]]; then
        print -r -- "hostname example"
        print -r -- "tag unrelated"
        return 0
      fi
      return 1
    }
    _sm_start_or_reuse_tunnel() {
      print -r -- "unexpected-tunnel"
      return 1
    }
    mosh() {
      print -r -- "mosh:$*"
    }

    sm example
  '

  [ "$status" -eq 0 ]
  [[ "$output" == "mosh:example" ]]
}

@test "tagged host fails before autossh when the local agent socket is missing" {
  run env MOSH_CONFIG="$MOSH_CONFIG" zsh -c '
    compdef() { :; }
    source "$MOSH_CONFIG"

    autossh() {
      print -r -- "unexpected-autossh"
    }

    host="bats-agent-missing-$$"
    SSH_AUTH_SOCK="/nonexistent/agent.sock"
    _sm_start_or_reuse_tunnel "$host" "/tmp/sm-${host}.pid" example "$$"
    result=$?
    rm -rf "/tmp/sm-${host}" "/tmp/sm-${host}.pid"
    exit $result
  '

  [ "$status" -ne 0 ]
  [[ "$output" == *"valid local SSH_AUTH_SOCK is required"* ]]
  [[ "$output" != *"unexpected-autossh"* ]]
}

@test "failed preflight removes the new session marker" {
  make_agent_socket
  TEST_HOST="bats-preflight-${BATS_TEST_NUMBER}-$$"

  run env MOSH_CONFIG="$MOSH_CONFIG" SSH_AUTH_SOCK="$AGENT_SOCKET" TEST_HOST="$TEST_HOST" zsh -c '
    compdef() { :; }
    source "$MOSH_CONFIG"
    _sm_tunnel_alive() { return 1; }
    ssh() { return 1; }

    _sm_start_or_reuse_tunnel "$TEST_HOST" "/tmp/sm-${TEST_HOST}.pid" example "$$"
  '

  [ "$status" -ne 0 ]
  [ ! -d "/tmp/sm-${TEST_HOST}" ]
}

@test "socket tunnel passes both forwards and retry cleanup to autossh" {
  make_agent_socket
  TEST_HOST="bats-forwards-${BATS_TEST_NUMBER}-$$"
  AUTOSSH_LOG="$AGENT_SOCKET_DIR/autossh.log"
  AUTOSSH_CALLED="$AGENT_SOCKET_DIR/autossh.called"

  run env MOSH_CONFIG="$MOSH_CONFIG" DOTFILES="$DOTFILES_ROOT" SSH_AUTH_SOCK="$AGENT_SOCKET" \
    TEST_HOST="$TEST_HOST" AUTOSSH_LOG="$AUTOSSH_LOG" AUTOSSH_CALLED="$AUTOSSH_CALLED" zsh -c '
    compdef() { :; }
    source "$MOSH_CONFIG"
    _sm_tunnel_alive() { [[ -f "$AUTOSSH_CALLED" ]]; }
    _sm_tunnel_healthy() { return 0; }
    ssh() { print -r -- "/remote/home"; }
    sleep() { :; }
    autossh() {
      print -r -- "AUTOSSH_PATH=$AUTOSSH_PATH" >> "$AUTOSSH_LOG"
      print -r -- "SM_CLEANUP_HOST=$SM_CLEANUP_HOST" >> "$AUTOSSH_LOG"
      print -r -- "SM_REMOTE_SOCKETS=$SM_REMOTE_SOCKETS" >> "$AUTOSSH_LOG"
      print -r -- "ARGS:$*" >> "$AUTOSSH_LOG"
      touch "$AUTOSSH_CALLED"
    }

    _sm_start_or_reuse_tunnel "$TEST_HOST" "/tmp/sm-${TEST_HOST}.pid" example "$$"
  '

  [ "$status" -eq 0 ]
  [[ "$(< "$AUTOSSH_LOG")" == *"AUTOSSH_PATH=$DOTFILES_ROOT/bin/sm-ssh-wrapper"* ]]
  [[ "$(< "$AUTOSSH_LOG")" == *"SM_CLEANUP_HOST=example"* ]]
  [[ "$(< "$AUTOSSH_LOG")" == *"SM_REMOTE_SOCKETS=.ssh/remote-bridge.sock .ssh/agent-tunnel.sock"* ]]
  [[ "$(< "$AUTOSSH_LOG")" == *"-R /remote/home/.ssh/remote-bridge.sock:localhost:8377"* ]]
  [[ "$(< "$AUTOSSH_LOG")" == *"-R /remote/home/.ssh/agent-tunnel.sock:$AGENT_SOCKET"* ]]
  [[ "$(< "$AUTOSSH_LOG")" == *"while :; do echo heartbeat; sleep 30; done"* ]]
}

@test "socket tunnel start fails when autossh is alive but health stays down" {
  make_agent_socket
  TEST_HOST="bats-unhealthy-${BATS_TEST_NUMBER}-$$"

  run env MOSH_CONFIG="$MOSH_CONFIG" DOTFILES="$DOTFILES_ROOT" SSH_AUTH_SOCK="$AGENT_SOCKET" \
    TEST_HOST="$TEST_HOST" zsh -c '
    compdef() { :; }
    source "$MOSH_CONFIG"
    started=false
    _sm_tunnel_alive() { $started; }
    _sm_tunnel_healthy() { return 1; }
    _sm_cleanup_tunnel() {
      rm -f "/tmp/sm-${TEST_HOST}.pid"
      rm -rf "/tmp/sm-${TEST_HOST}"
    }
    _sm_stop_tunnel_process() { :; }
    ssh() { print -r -- "/remote/home"; }
    sleep() { :; }
    autossh() { started=true; }

    _sm_start_or_reuse_tunnel "$TEST_HOST" "/tmp/sm-${TEST_HOST}.pid" example "$$"
  '

  [ "$status" -ne 0 ]
  [[ "$output" == *"did not become healthy"* ]]
  [ ! -d "/tmp/sm-${TEST_HOST}" ]
}

@test "unhealthy tunnel restart preserves other active session markers" {
  make_agent_socket
  TEST_HOST="bats-restart-markers-${BATS_TEST_NUMBER}-$$"
  OTHER_SESSION_PID="$$"

  run env MOSH_CONFIG="$MOSH_CONFIG" DOTFILES="$DOTFILES_ROOT" SSH_AUTH_SOCK="$AGENT_SOCKET" \
    TEST_HOST="$TEST_HOST" OTHER_SESSION_PID="$OTHER_SESSION_PID" zsh -c '
    compdef() { :; }
    source "$MOSH_CONFIG"

    state_directory="/tmp/sm-${TEST_HOST}"
    mkdir -p "$state_directory"
    touch "${state_directory}/${OTHER_SESSION_PID}"

    tunnel_state=existing
    _sm_tunnel_alive() { [[ "$tunnel_state" != stopped ]]; }
    _sm_tunnel_healthy() { [[ "$tunnel_state" == started ]]; }
    _sm_cleanup_tunnel() {
      tunnel_state=stopped
      rm -rf "$state_directory"
    }
    _sm_stop_tunnel_process() { tunnel_state=stopped; }
    ssh() { print -r -- "/remote/home"; }
    sleep() { :; }
    autossh() { tunnel_state=started; }

    _sm_start_or_reuse_tunnel "$TEST_HOST" "/tmp/sm-${TEST_HOST}.pid" example "$$"
  '

  [ "$status" -eq 0 ]
  [ -f "/tmp/sm-${TEST_HOST}/${OTHER_SESSION_PID}" ]
}
