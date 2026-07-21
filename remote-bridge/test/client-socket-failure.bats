#!/usr/bin/env bats

# Failure-mode coverage shared by all five bridge clients: with
# REMOTE_BRIDGE_SOCKET pointed at a path that does not exist, every client
# must fail fast (non-zero exit, no hang) and name the expected socket path
# in its error — never hang, never silently succeed. Runs on this suite's
# actual host OS (non-Darwin), so no uname shim is needed: the missing-socket
# check only applies on non-Darwin in the first place.

BIN_DIR="$BATS_TEST_DIRNAME/../bin"
MISSING_SOCKET="/nonexistent/remote-bridge-test/remote-bridge.sock"

setup() {
  export REMOTE_BRIDGE_SOCKET="$MISSING_SOCKET"
  export REMOTE_BRIDGE_TOKEN="test-token-does-not-matter-socket-check-runs-first"
}

teardown() {
  if [ -n "${STALE_SOCKET_PID:-}" ]; then
    kill "$STALE_SOCKET_PID" 2>/dev/null || true
  fi
  if [ -n "${STALE_SOCKET_DIR:-}" ]; then
    rm -rf "$STALE_SOCKET_DIR"
  fi
}

make_stale_socket() {
  STALE_SOCKET_DIR="$(mktemp -d)"
  STALE_SOCKET_PATH="$STALE_SOCKET_DIR/remote-bridge.sock"
  node -e 'require("net").createServer().listen(process.argv[1]); setInterval(() => {}, 1000)' "$STALE_SOCKET_PATH" >/dev/null 2>&1 &
  STALE_SOCKET_PID=$!

  for _ in 1 2 3 4 5 6 7 8 9 10; do
    [ -S "$STALE_SOCKET_PATH" ] && break
    sleep 0.1
  done
  [ -S "$STALE_SOCKET_PATH" ]

  kill -9 "$STALE_SOCKET_PID"
  wait "$STALE_SOCKET_PID" 2>/dev/null || true
  unset STALE_SOCKET_PID
}

@test "rclip: fails fast with the missing socket path when the socket is absent" {
  run "$BIN_DIR/rclip" "hello"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "$MISSING_SOCKET" ]]
}

@test "rclip keeps the interactive OSC52 fallback when the socket is absent" {
  command -v script >/dev/null 2>&1 || skip "script is required for a pseudo-terminal"

  run env TMUX= REMOTE_BRIDGE_SOCKET="$MISSING_SOCKET" REMOTE_BRIDGE_TOKEN="$REMOTE_BRIDGE_TOKEN" \
    script -qec "$BIN_DIR/rclip hello" /dev/null

  [ "$status" -eq 0 ]
  [[ "$output" =~ "sent via OSC52" ]]
}

@test "ropen: fails fast with the missing socket path when the socket is absent" {
  run "$BIN_DIR/ropen" "https://example.com"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "$MISSING_SOCKET" ]]
}

@test "ropen: help works without a tunnel" {
  run "$BIN_DIR/ropen" --help

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage" ]]
}

@test "rnotify: fails fast with the missing socket path when the socket is absent" {
  run "$BIN_DIR/rnotify" "test message"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "$MISSING_SOCKET" ]]
}

@test "rnotify: help works without a tunnel" {
  run "$BIN_DIR/rnotify" --help

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage" ]]
}

@test "rtime: fails fast with the missing socket path when the socket is absent" {
  run "$BIN_DIR/rtime" fetch --today
  [ "$status" -ne 0 ]
  [[ "$output" =~ "$MISSING_SOCKET" ]]
}

@test "rtime: help works without a tunnel" {
  run "$BIN_DIR/rtime" --help

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage" ]]
}

@test "robsidian: fails fast with the missing socket path when the socket is absent" {
  run "$BIN_DIR/robsidian" vault
  [ "$status" -ne 0 ]
  [[ "$output" =~ "$MISSING_SOCKET" ]]
}

@test "rclip: names an unresponsive socket without hanging" {
  make_stale_socket

  run timeout 4 env REMOTE_BRIDGE_SOCKET="$STALE_SOCKET_PATH" "$BIN_DIR/rclip" "hello"

  [ "$status" -ne 0 ]
  [ "$status" -ne 124 ]
  [[ "$output" =~ "$STALE_SOCKET_PATH" ]]
  [[ "$output" =~ "not responding" ]]
}

@test "ropen: names an unresponsive socket without hanging" {
  make_stale_socket

  run timeout 4 env REMOTE_BRIDGE_SOCKET="$STALE_SOCKET_PATH" "$BIN_DIR/ropen" "https://example.com"

  [ "$status" -ne 0 ]
  [ "$status" -ne 124 ]
  [[ "$output" =~ "$STALE_SOCKET_PATH" ]]
  [[ "$output" =~ "not responding" ]]
}

@test "rnotify: names an unresponsive socket without hanging" {
  make_stale_socket

  run timeout 4 env REMOTE_BRIDGE_SOCKET="$STALE_SOCKET_PATH" "$BIN_DIR/rnotify" "hello"

  [ "$status" -ne 0 ]
  [ "$status" -ne 124 ]
  [[ "$output" =~ "$STALE_SOCKET_PATH" ]]
  [[ "$output" =~ "not responding" ]]
}

@test "rtime: names an unresponsive socket without hanging" {
  make_stale_socket

  run timeout 4 env REMOTE_BRIDGE_SOCKET="$STALE_SOCKET_PATH" "$BIN_DIR/rtime" fetch --today

  [ "$status" -ne 0 ]
  [ "$status" -ne 124 ]
  [[ "$output" =~ "$STALE_SOCKET_PATH" ]]
  [[ "$output" =~ "not responding" ]]
}

@test "robsidian: names an unresponsive socket without hanging" {
  make_stale_socket

  run timeout 4 env REMOTE_BRIDGE_SOCKET="$STALE_SOCKET_PATH" "$BIN_DIR/robsidian" vault

  [ "$status" -ne 0 ]
  [ "$status" -ne 124 ]
  [[ "$output" =~ "$STALE_SOCKET_PATH" ]]
  [[ "$output" =~ "not responding" ]]
}
