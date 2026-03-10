#!/usr/bin/env bash

set -euo pipefail

escape_sed_replacement() {
    printf '%s' "$1" | sed -e 's/[|&]/\\&/g'
}

export PENPOT_MCP_SERVER_HOST="${PENPOT_MCP_SERVER_HOST:-${PENPOT_MCP_SERVER_LISTEN_ADDRESS:-0.0.0.0}}"
export PENPOT_MCP_SERVER_PORT="${PENPOT_MCP_SERVER_PORT:-4401}"
export PENPOT_MCP_WEBSOCKET_PORT="${PENPOT_MCP_WEBSOCKET_PORT:-4402}"
export PENPOT_MCP_REPL_PORT="${PENPOT_MCP_REPL_PORT:-4403}"
export PENPOT_MCP_PLUGIN_PORT="${PENPOT_MCP_PLUGIN_PORT:-4400}"
export PENPOT_MCP_PLUGIN_SERVER_LISTEN_ADDRESS="${PENPOT_MCP_PLUGIN_SERVER_LISTEN_ADDRESS:-0.0.0.0}"
export PENPOT_MCP_SERVER_ADDRESS="${PENPOT_MCP_SERVER_ADDRESS:-localhost}"
export PENPOT_MCP_WEBSOCKET_PROTOCOL="${PENPOT_MCP_WEBSOCKET_PROTOCOL:-ws}"
export PENPOT_MCP_MULTI_USER_MODE="${PENPOT_MCP_MULTI_USER_MODE:-true}"
export PENPOT_MCP_LOG_DIR="${PENPOT_MCP_LOG_DIR:-/opt/penpot-mcp/logs}"

plugin_bind_address="${PENPOT_MCP_PLUGIN_SERVER_LISTEN_ADDRESS%%,*}"

if [[ -z "${PENPOT_MCP_PLUGIN_PUBLIC_URL:-}" ]]; then
    export PENPOT_MCP_PLUGIN_PUBLIC_URL="http://localhost:${PENPOT_MCP_PLUGIN_PORT}"
fi

if [[ -z "${PENPOT_MCP_PLUGIN_WEBSOCKET_URL:-}" ]]; then
    export PENPOT_MCP_PLUGIN_WEBSOCKET_URL="${PENPOT_MCP_WEBSOCKET_PROTOCOL}://${PENPOT_MCP_SERVER_ADDRESS}:${PENPOT_MCP_WEBSOCKET_PORT}"
fi

mkdir -p "$PENPOT_MCP_LOG_DIR"
rm -rf /opt/penpot-mcp/plugin
cp -R /opt/penpot-mcp/plugin-template /opt/penpot-mcp/plugin

escaped_ws_url="$(escape_sed_replacement "$PENPOT_MCP_PLUGIN_WEBSOCKET_URL")"
find /opt/penpot-mcp/plugin -type f -name '*.js' -exec sed -i "s|__PENPOT_MCP_WEBSOCKET_URL__|${escaped_ws_url}|g" {} +

cat > /opt/penpot-mcp/plugin/manifest.json <<EOF
{
    "version": 2,
  "name": "Penpot MCP Plugin",
  "pluginId": "penpot-mcp-plugin",
  "description": "Plugin for connecting Penpot to the Penpot MCP server running in Docker.",
  "host": "${PENPOT_MCP_PLUGIN_PUBLIC_URL}",
  "code": "/plugin.js",
  "permissions": [
    "content:read",
    "content:write",
    "library:read",
    "library:write",
    "user:read",
    "comment:read",
    "comment:write",
    "allow:downloads"
  ]
}
EOF

terminate() {
    local exit_code=0

    if [[ -n "${plugin_pid:-}" ]]; then
        kill "$plugin_pid" 2>/dev/null || true
    fi

    if [[ -n "${mcp_pid:-}" ]]; then
        kill "$mcp_pid" 2>/dev/null || true
    fi

    wait "$plugin_pid" 2>/dev/null || exit_code=$?
    wait "$mcp_pid" 2>/dev/null || exit_code=$?

    exit "$exit_code"
}

trap terminate SIGINT SIGTERM

node /opt/penpot-mcp/plugin-server.mjs \
    /opt/penpot-mcp/plugin \
    "$plugin_bind_address" \
    "$PENPOT_MCP_PLUGIN_PORT" &
plugin_pid=$!

pushd /opt/penpot-mcp/server >/dev/null

server_args=()
if [[ "$PENPOT_MCP_MULTI_USER_MODE" == "true" ]]; then
    server_args+=(--multi-user)
fi

node index.js "${server_args[@]}" &
mcp_pid=$!

popd >/dev/null

wait -n "$plugin_pid" "$mcp_pid"
terminate