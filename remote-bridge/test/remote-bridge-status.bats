#!/usr/bin/env bats

DOTFILES_ROOT="$BATS_TEST_DIRNAME/../.."

setup() {
  TEST_HOME="$(mktemp -d)"
  mkdir -p "$TEST_HOME/.ssh"
  AGENT_SOCKET="$TEST_HOME/.ssh/agent-tunnel.sock"

  node -e 'require("net").createServer().listen(process.argv[1]); setInterval(() => {}, 1000)' "$AGENT_SOCKET" >/dev/null 2>&1 &
  AGENT_SOCKET_PID=$!
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    [ -S "$AGENT_SOCKET" ] && break
    sleep 0.1
  done
  [ -S "$AGENT_SOCKET" ]

  kill -9 "$AGENT_SOCKET_PID"
  wait "$AGENT_SOCKET_PID" 2>/dev/null || true
  unset AGENT_SOCKET_PID
}

teardown() {
  if [ -n "${AGENT_SOCKET_PID:-}" ]; then
    kill "$AGENT_SOCKET_PID" 2>/dev/null || true
  fi
  rm -rf "$TEST_HOME"
}

@test "agent status reports a stale socket as unresponsive" {
  run env HOME="$TEST_HOME" DOTFILES="$DOTFILES_ROOT" zsh -c '
    source "$DOTFILES/zsh/config/remote-bridge.zsh"
    remote-bridge-agent-status
  '

  [ "$status" -eq 0 ]
  [ "$output" = "unresponsive" ]
}

@test "bridge status names the Unix socket when health succeeds" {
  run env HOME="$TEST_HOME" DOTFILES="$DOTFILES_ROOT" zsh -c '
    source "$DOTFILES/zsh/config/remote-bridge.zsh"
    curl() {
      print -r -- "{\"version\":\"example\",\"status\":\"ok\",\"uptime\":1}"
    }
    remote-bridge-agent-status() {
      print -r -- "absent"
    }
    remote-bridge-status
  '

  [ "$status" -eq 0 ]
  [[ "$output" == *"Socket path: $TEST_HOME/.ssh/remote-bridge.sock"* ]]
  [[ "$output" == *"Remote Bridge is accessible"* ]]
}

@test "bridge status explains a missing Unix socket" {
  rm -f "$AGENT_SOCKET"

  run env HOME="$TEST_HOME" DOTFILES="$DOTFILES_ROOT" zsh -c '
    source "$DOTFILES/zsh/config/remote-bridge.zsh"
    remote-bridge-status
  '

  [ "$status" -eq 0 ]
  [[ "$output" == *"Socket path: $TEST_HOME/.ssh/remote-bridge.sock"* ]]
  [[ "$output" == *"Socket file does not exist"* ]]
  [[ "$output" == *"Agent socket not present"* ]]
}

@test "agent status treats an empty but reachable agent as responsive" {
  run env HOME="$TEST_HOME" DOTFILES="$DOTFILES_ROOT" zsh -c '
    source "$DOTFILES/zsh/config/remote-bridge.zsh"
    timeout() { return 1; }
    remote-bridge-agent-status
  '

  [ "$status" -eq 0 ]
  [ "$output" = "responsive" ]
}
