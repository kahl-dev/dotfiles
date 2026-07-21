#!/usr/bin/env bats

# Exercises lib/bridge-endpoint.sh's resolve_bridge_endpoint() and
# require_bridge_socket() in isolation. `uname` is faked via a PATH shim
# directory so the Darwin/non-Darwin branches are deterministic regardless of
# which OS actually runs this suite.

BRIDGE_ENDPOINT="$BATS_TEST_DIRNAME/../lib/bridge-endpoint.sh"

setup() {
  UNAME_SHIM_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$UNAME_SHIM_DIR"
  if [ -n "${AGENT_SOCKET_PID:-}" ]; then
    kill "$AGENT_SOCKET_PID" 2>/dev/null || true
  fi
}

make_uname_shim() {
  local reported_os="$1"
  cat > "$UNAME_SHIM_DIR/uname" <<EOF
#!/bin/sh
echo "$reported_os"
EOF
  chmod +x "$UNAME_SHIM_DIR/uname"
}

@test "resolve_bridge_endpoint: Darwin uses TCP localhost:8377" {
  make_uname_shim "Darwin"
  run env PATH="$UNAME_SHIM_DIR:$PATH" REMOTE_BRIDGE_PORT= REMOTE_BRIDGE_SOCKET= bash -c "
    source '$BRIDGE_ENDPOINT'
    resolve_bridge_endpoint
    echo \"URL=\$BRIDGE_BASE_URL\"
  "
  [ "$status" -eq 0 ]
  [[ "$output" =~ "URL=http://localhost:8377" ]]
}

@test "resolve_bridge_endpoint: Darwin ignores the removed port override" {
  make_uname_shim "Darwin"
  run env PATH="$UNAME_SHIM_DIR:$PATH" REMOTE_BRIDGE_PORT=1234 bash -c "
    source '$BRIDGE_ENDPOINT'
    resolve_bridge_endpoint
    echo \"URL=\$BRIDGE_BASE_URL\"
  "
  [ "$status" -eq 0 ]
  [[ "$output" =~ "URL=http://localhost:8377" ]]
}

@test "resolve_bridge_endpoint: non-Darwin defaults to \$HOME/.ssh/remote-bridge.sock" {
  make_uname_shim "Linux"
  run env PATH="$UNAME_SHIM_DIR:$PATH" HOME=/fake/home REMOTE_BRIDGE_SOCKET= bash -c "
    source '$BRIDGE_ENDPOINT'
    resolve_bridge_endpoint
    echo \"URL=\$BRIDGE_BASE_URL\"
    echo \"SOCKET=\$BRIDGE_SOCKET_PATH\"
  "
  [ "$status" -eq 0 ]
  [[ "$output" =~ "URL=http://localhost" ]]
  [[ "$output" =~ "SOCKET=/fake/home/.ssh/remote-bridge.sock" ]]
}

@test "resolve_bridge_endpoint: non-Darwin honors REMOTE_BRIDGE_SOCKET override" {
  make_uname_shim "Linux"
  run env PATH="$UNAME_SHIM_DIR:$PATH" REMOTE_BRIDGE_SOCKET=/custom/path.sock bash -c "
    source '$BRIDGE_ENDPOINT'
    resolve_bridge_endpoint
    echo \"SOCKET=\$BRIDGE_SOCKET_PATH\"
  "
  [ "$status" -eq 0 ]
  [[ "$output" =~ "SOCKET=/custom/path.sock" ]]
}

@test "require_bridge_socket: Darwin is a no-op regardless of socket presence" {
  make_uname_shim "Darwin"
  run env PATH="$UNAME_SHIM_DIR:$PATH" bash -c "
    source '$BRIDGE_ENDPOINT'
    resolve_bridge_endpoint
    require_bridge_socket
  "
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "require_bridge_socket: non-Darwin fails fast naming the missing socket path and the fix" {
  make_uname_shim "Linux"
  run env PATH="$UNAME_SHIM_DIR:$PATH" REMOTE_BRIDGE_SOCKET=/nonexistent/remote-bridge.sock bash -c "
    source '$BRIDGE_ENDPOINT'
    resolve_bridge_endpoint
    require_bridge_socket
  "
  [ "$status" -ne 0 ]
  [[ "$output" =~ "/nonexistent/remote-bridge.sock" ]]
  [[ "$output" =~ "sm <host>" ]]
}

@test "require_bridge_socket: non-Darwin succeeds when the socket file exists" {
  make_uname_shim "Linux"
  local socket_dir socket_path
  socket_dir="$(mktemp -d)"
  socket_path="${socket_dir}/bridge.sock"

  # A real listening Unix socket (not just an empty file) — require_bridge_socket
  # checks `-S` (socket type), which an ordinary touch'd file does not satisfy.
  node -e "require('net').createServer().listen(process.argv[1])" "$socket_path" &
  AGENT_SOCKET_PID=$!
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    [ -S "$socket_path" ] && break
    sleep 0.1
  done

  run env PATH="$UNAME_SHIM_DIR:$PATH" REMOTE_BRIDGE_SOCKET="$socket_path" bash -c "
    source '$BRIDGE_ENDPOINT'
    resolve_bridge_endpoint
    require_bridge_socket
  "

  kill "$AGENT_SOCKET_PID" 2>/dev/null
  unset AGENT_SOCKET_PID
  rm -rf "$socket_dir"

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
