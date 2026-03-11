#!/usr/bin/env bash

set -euo pipefail

export PENPOT_MCP_SERVER_HOST="${PENPOT_MCP_SERVER_HOST:-${PENPOT_MCP_SERVER_LISTEN_ADDRESS:-0.0.0.0}}"
export PENPOT_MCP_SERVER_PORT="${PENPOT_MCP_SERVER_PORT:-4401}"
export PENPOT_MCP_WEBSOCKET_PORT="${PENPOT_MCP_WEBSOCKET_PORT:-4402}"
export PENPOT_MCP_REPL_PORT="${PENPOT_MCP_REPL_PORT:-4403}"
export PENPOT_MCP_PLUGIN_PORT="${PENPOT_MCP_PLUGIN_PORT:-4400}"
export PENPOT_MCP_PLUGIN_SERVER_LISTEN_ADDRESS="${PENPOT_MCP_PLUGIN_SERVER_LISTEN_ADDRESS:-0.0.0.0}"
export PENPOT_MCP_SERVER_ADDRESS="${PENPOT_MCP_SERVER_ADDRESS:-localhost}"
export PENPOT_MCP_PLUGIN_PUBLIC_URL="${PENPOT_MCP_PLUGIN_PUBLIC_URL:-}"
export PENPOT_MCP_PLUGIN_WEBSOCKET_PATH="${PENPOT_MCP_PLUGIN_WEBSOCKET_PATH:-}"
export PENPOT_MCP_PLUGIN_ALLOWED_HOSTS="${PENPOT_MCP_PLUGIN_ALLOWED_HOSTS:-${PENPOT_MCP_SERVER_ADDRESS}}"
export PENPOT_MCP_REMOTE_MODE="${PENPOT_MCP_REMOTE_MODE:-false}"
export PENPOT_MCP_MULTI_USER_MODE="${PENPOT_MCP_MULTI_USER_MODE:-true}"
export PENPOT_MCP_LOG_DIR="${PENPOT_MCP_LOG_DIR:-/opt/penpot/mcp/logs}"

if [[ -z "${PENPOT_MCP_PLUGIN_WEBSOCKET_URL:-}" ]]; then
    websocket_scheme="ws"
    websocket_host="${PENPOT_MCP_SERVER_ADDRESS}"
    websocket_port=":${PENPOT_MCP_WEBSOCKET_PORT}"

    if [[ -n "$PENPOT_MCP_PLUGIN_PUBLIC_URL" ]]; then
        public_location=""

        case "$PENPOT_MCP_PLUGIN_PUBLIC_URL" in
            https://*)
                websocket_scheme="wss"
                public_location="${PENPOT_MCP_PLUGIN_PUBLIC_URL#https://}"
                ;;
            http://*)
                websocket_scheme="ws"
                public_location="${PENPOT_MCP_PLUGIN_PUBLIC_URL#http://}"
                ;;
        esac

        if [[ -n "$public_location" ]]; then
            websocket_host="${public_location%%/*}"
            websocket_port=""
        fi
    elif [[ "$PENPOT_MCP_REMOTE_MODE" == "true" ]]; then
        websocket_scheme="wss"
        websocket_port=""
    fi

    export PENPOT_MCP_PLUGIN_WEBSOCKET_URL="${websocket_scheme}://${websocket_host}${websocket_port}${PENPOT_MCP_PLUGIN_WEBSOCKET_PATH}"
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