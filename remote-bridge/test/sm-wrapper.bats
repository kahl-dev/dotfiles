#!/usr/bin/env bats

WRAPPER="$BATS_TEST_DIRNAME/../../bin/sm-ssh-wrapper"

setup() {
  SHIM_DIR="$(mktemp -d)"
  SSH_LOG="$SHIM_DIR/ssh.log"

  cat > "$SHIM_DIR/ssh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$SSH_LOG"
if [[ "${FAIL_CLEANUP:-0}" = "1" && "$*" == *"ClearAllForwardings=yes"* ]]; then
  exit 42
fi
exit 0
EOF
  chmod +x "$SHIM_DIR/ssh"
}

teardown() {
  rm -rf "$SHIM_DIR"
}

@test "cleanup failure prevents the main SSH attempt" {
  run env PATH="$SHIM_DIR:$PATH" SSH_LOG="$SSH_LOG" FAIL_CLEANUP=1 \
    SM_CLEANUP_HOST=example \
    SM_REMOTE_SOCKETS=".ssh/remote-bridge.sock .ssh/agent-tunnel.sock" \
    bash "$WRAPPER" -T example

  [ "$status" -eq 42 ]
  [ "$(wc -l < "$SSH_LOG")" -eq 1 ]
  [[ "$(< "$SSH_LOG")" == *"ClearAllForwardings=yes"* ]]
}

@test "successful cleanup is followed by the original SSH arguments" {
  run env PATH="$SHIM_DIR:$PATH" SSH_LOG="$SSH_LOG" \
    SM_CLEANUP_HOST=example \
    SM_REMOTE_SOCKETS=".ssh/remote-bridge.sock .ssh/agent-tunnel.sock" \
    bash "$WRAPPER" -T example "heartbeat command"

  [ "$status" -eq 0 ]
  [ "$(wc -l < "$SSH_LOG")" -eq 2 ]
  [[ "$(sed -n '1p' "$SSH_LOG")" == *"ClearAllForwardings=yes"* ]]
  [ "$(sed -n '2p' "$SSH_LOG")" = "-T example heartbeat command" ]
}
