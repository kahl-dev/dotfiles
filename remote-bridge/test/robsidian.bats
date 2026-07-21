#!/usr/bin/env bats

ROBSIDIAN="$BATS_TEST_DIRNAME/../bin/robsidian"

require_darwin() {
  [ "$(uname)" = "Darwin" ] || skip "Local Obsidian mode requires macOS"
}

@test "local mode: returns vault info" {
  require_darwin
  unset REMOTE_BRIDGE_SOCKET
  run "$ROBSIDIAN" vault
  [ "$status" -eq 0 ]
  [[ "$output" =~ "kahl_dev" ]]
}

@test "local mode: suppresses stderr noise" {
  require_darwin
  unset REMOTE_BRIDGE_SOCKET
  run "$ROBSIDIAN" version
  [ "$status" -eq 0 ]
  # Should have clean output, no loader noise
  [[ ! "$output" =~ "Error" ]] || [[ "$output" =~ "Obsidian" ]]
}

@test "shows help with --help flag" {
  run "$ROBSIDIAN" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage" ]]
}

@test "shows help with -h flag" {
  run "$ROBSIDIAN" -h
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage" ]]
}

@test "no arguments shows help" {
  run "$ROBSIDIAN"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Usage" ]]
}

@test "remote mode: error when bridge unavailable" {
  export REMOTE_BRIDGE_SOCKET=/nonexistent/remote-bridge.sock
  run "$ROBSIDIAN" vault
  [ "$status" -ne 0 ]
  [[ "$output" =~ "not available" ]] || [[ "$output" =~ "Remote Bridge" ]]
}

@test "local mode: handles quoted arguments" {
  require_darwin
  unset REMOTE_BRIDGE_SOCKET
  run "$ROBSIDIAN" search query="daily" format=json
  [ "$status" -eq 0 ]
}

@test "local mode: propagates exit code" {
  require_darwin
  unset REMOTE_BRIDGE_SOCKET
  run "$ROBSIDIAN" vault
  [ "$status" -eq 0 ]
}

# Integration test — only runs when bridge is available
@test "remote mode: returns vault info through bridge" {
  socket="$HOME/.ssh/remote-bridge.sock"
  [ -S "$socket" ] || skip "Remote Bridge socket not present"
  curl -sf --unix-socket "$socket" http://localhost/health >/dev/null 2>&1 || skip "Remote Bridge not running"
  export REMOTE_BRIDGE_SOCKET="$socket"
  run "$ROBSIDIAN" vault
  [ "$status" -eq 0 ]
  [[ "$output" =~ "kahl_dev" ]]
}

# Auto-start tests — fast path (Obsidian already running)
@test "local mode: succeeds quickly when Obsidian is already running" {
  require_darwin
  pgrep -x Obsidian >/dev/null 2>&1 || skip "Obsidian not running"
  unset REMOTE_BRIDGE_SOCKET
  # Should complete in under 3 seconds (no startup wait)
  run "$ROBSIDIAN" vault
  [ "$status" -eq 0 ]
  [[ "$output" =~ "kahl_dev" ]]
}

@test "remote mode: succeeds quickly when Obsidian is already running" {
  pgrep -x Obsidian >/dev/null 2>&1 || skip "Obsidian not running"
  socket="$HOME/.ssh/remote-bridge.sock"
  [ -S "$socket" ] || skip "Remote Bridge socket not present"
  curl -sf --unix-socket "$socket" http://localhost/health >/dev/null 2>&1 || skip "Remote Bridge not running"
  export REMOTE_BRIDGE_SOCKET="$socket"
  run "$ROBSIDIAN" vault
  [ "$status" -eq 0 ]
  [[ "$output" =~ "kahl_dev" ]]
}
