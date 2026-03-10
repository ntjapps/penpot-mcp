#!/usr/bin/env bash

set -euo pipefail

export PENPOT_MCP_SERVER_HOST="${PENPOT_MCP_SERVER_HOST:-${PENPOT_MCP_SERVER_LISTEN_ADDRESS:-0.0.0.0}}"
export PENPOT_MCP_SERVER_PORT="${PENPOT_MCP_SERVER_PORT:-4401}"
export PENPOT_MCP_WEBSOCKET_PORT="${PENPOT_MCP_WEBSOCKET_PORT:-4402}"
export PENPOT_MCP_REPL_PORT="${PENPOT_MCP_REPL_PORT:-4403}"
export PENPOT_MCP_PLUGIN_PORT="${PENPOT_MCP_PLUGIN_PORT:-4400}"
export PENPOT_MCP_PLUGIN_SERVER_LISTEN_ADDRESS="${PENPOT_MCP_PLUGIN_SERVER_LISTEN_ADDRESS:-0.0.0.0}"
export PENPOT_MCP_SERVER_ADDRESS="${PENPOT_MCP_SERVER_ADDRESS:-localhost}"
export PENPOT_MCP_MULTI_USER_MODE="${PENPOT_MCP_MULTI_USER_MODE:-true}"
export PENPOT_MCP_LOG_DIR="${PENPOT_MCP_LOG_DIR:-/opt/penpot/mcp/logs}"

if [[ -z "${PENPOT_MCP_PLUGIN_WEBSOCKET_URL:-}" ]]; then
    export PENPOT_MCP_PLUGIN_WEBSOCKET_URL="ws://${PENPOT_MCP_SERVER_ADDRESS}:${PENPOT_MCP_WEBSOCKET_PORT}"
fi

export WS_URI="$PENPOT_MCP_PLUGIN_WEBSOCKET_URL"
export MULTI_USER_MODE="$PENPOT_MCP_MULTI_USER_MODE"

mkdir -p "$PENPOT_MCP_LOG_DIR"

cd /opt/penpot/mcp

terminate() {
    local exit_code=0

    for pid in ${bootstrap_pids:-}; do
        kill "$pid" 2>/dev/null || true
    done

    for pid in ${bootstrap_pids:-}; do
        wait "$pid" 2>/dev/null || exit_code=$?
    done

    exit "$exit_code"
}

trap terminate SIGINT SIGTERM

if [[ "$PENPOT_MCP_MULTI_USER_MODE" == "true" ]]; then
    pnpm run start:multi-user &
    bootstrap_pids="$!"
else
    pnpm run start &
    bootstrap_pids="$!"
fi

wait -n ${bootstrap_pids}
terminate