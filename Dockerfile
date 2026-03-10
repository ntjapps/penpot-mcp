# syntax=docker/dockerfile:1.7

FROM node:22-bookworm-slim AS build

WORKDIR /opt/penpot/mcp

RUN apt-get update \
    && apt-get install -y --no-install-recommends bash ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY penpot/mcp /opt/penpot/mcp

RUN test -f package.json && test -x scripts/setup

RUN corepack enable

RUN ./scripts/setup

RUN pnpm run build:multi-user

RUN bash -lc 'set -euo pipefail; timeout 20s pnpm run bootstrap || status=$?; if [[ ${status:-0} -ne 0 && ${status:-0} -ne 124 ]]; then exit ${status}; fi'

FROM node:22-bookworm-slim AS runtime

WORKDIR /opt/penpot/mcp

ENV NODE_ENV=production \
    PENPOT_MCP_SERVER_LISTEN_ADDRESS=0.0.0.0 \
    PENPOT_MCP_SERVER_PORT=4401 \
    PENPOT_MCP_WEBSOCKET_PORT=4402 \
    PENPOT_MCP_REPL_PORT=4403 \
    PENPOT_MCP_PLUGIN_SERVER_LISTEN_ADDRESS=0.0.0.0 \
    PENPOT_MCP_PLUGIN_PORT=4400 \
    PENPOT_MCP_SERVER_ADDRESS=localhost \
    PENPOT_MCP_REMOTE_MODE=false \
    PENPOT_MCP_MULTI_USER_MODE=true \
    PENPOT_MCP_LOG_LEVEL=info \
    PENPOT_MCP_LOG_DIR=/opt/penpot/mcp/logs

RUN apt-get update \
    && apt-get install -y --no-install-recommends bash ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /opt/penpot/mcp /opt/penpot/mcp
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh \
    && mkdir -p /opt/penpot/mcp/logs

EXPOSE 4400 4401 4402 4403

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]