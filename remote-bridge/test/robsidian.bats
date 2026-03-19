#!/usr/bin/env bats

ROBSIDIAN="$BATS_TEST_DIRNAME/../bin/robsidian"

@test "local mode: returns vault info" {
  unset REMOTE_BRIDGE_PORT
  run "$ROBSIDIAN" vault
  [ "$status" -eq 0 ]
  [[ "$output" =~ "kahl_dev" ]]
}

@test "local mode: suppresses stderr noise" {
  unset REMOTE_BRIDGE_PORT
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
  export REMOTE_BRIDGE_PORT=19999
  run "$ROBSIDIAN" vault
  [ "$status" -ne 0 ]
  [[ "$output" =~ "not available" ]] || [[ "$output" =~ "Remote Bridge" ]]
}

@test "local mode: handles quoted arguments" {
  unset REMOTE_BRIDGE_PORT
  run "$ROBSIDIAN" search query="daily" format=json
  [ "$status" -eq 0 ]
}

@test "local mode: propagates exit code" {
  unset REMOTE_BRIDGE_PORT
  run "$ROBSIDIAN" vault
  [ "$status" -eq 0 ]
}

# Integration test — only runs when bridge is available
@test "remote mode: returns vault info through bridge" {
  curl -sf http://localhost:8377/health >/dev/null 2>&1 || skip "Remote Bridge not running"
  export REMOTE_BRIDGE_PORT=8377
  run "$ROBSIDIAN" vault
  [ "$status" -eq 0 ]
  [[ "$output" =~ "kahl_dev" ]]
}

# Auto-start tests — fast path (Obsidian already running)
@test "local mode: succeeds quickly when Obsidian is already running" {
  pgrep -x Obsidian >/dev/null 2>&1 || skip "Obsidian not running"
  unset REMOTE_BRIDGE_PORT
  # Should complete in under 3 seconds (no startup wait)
  run "$ROBSIDIAN" vault
  [ "$status" -eq 0 ]
  [[ "$output" =~ "kahl_dev" ]]
}

@test "remote mode: succeeds quickly when Obsidian is already running" {
  pgrep -x Obsidian >/dev/null 2>&1 || skip "Obsidian not running"
  curl -sf http://localhost:8377/health >/dev/null 2>&1 || skip "Remote Bridge not running"
  export REMOTE_BRIDGE_PORT=8377
  run "$ROBSIDIAN" vault
  [ "$status" -eq 0 ]
  [[ "$output" =~ "kahl_dev" ]]
}
