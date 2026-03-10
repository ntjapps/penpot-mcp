# syntax=docker/dockerfile:1.7

FROM node:22-bookworm-slim AS builder

ARG PENPOT_REPO=https://github.com/penpot/penpot.git
ARG PENPOT_BRANCH=develop
ARG PENPOT_CLONE_DEPTH=1
ARG PENPOT_PLUGINS_API_DOC_URL=http://localhost:9090

WORKDIR /build

RUN apt-get update \
    && apt-get install -y --no-install-recommends bash ca-certificates git rsync \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --branch "${PENPOT_BRANCH}" --depth "${PENPOT_CLONE_DEPTH}" "${PENPOT_REPO}" penpot

WORKDIR /build/penpot/mcp

RUN corepack enable

RUN bash ./scripts/build "${PENPOT_PLUGINS_API_DOC_URL}"

RUN pnpm --filter "mcp-plugin" install

RUN WS_URI="__PENPOT_MCP_WEBSOCKET_URL__" MULTI_USER_MODE="true" pnpm --filter "mcp-plugin" run build:multi-user

RUN cd dist && bash ./setup


FROM node:22-bookworm-slim AS runtime

WORKDIR /opt/penpot-mcp

ENV NODE_ENV=production \
    PENPOT_MCP_SERVER_LISTEN_ADDRESS=0.0.0.0 \
    PENPOT_MCP_SERVER_PORT=4401 \
    PENPOT_MCP_WEBSOCKET_PORT=4402 \
    PENPOT_MCP_REPL_PORT=4403 \
    PENPOT_MCP_PLUGIN_SERVER_LISTEN_ADDRESS=0.0.0.0 \
    PENPOT_MCP_PLUGIN_PORT=4400 \
    PENPOT_MCP_SERVER_ADDRESS=localhost \
    PENPOT_MCP_WEBSOCKET_PROTOCOL=ws \
    PENPOT_MCP_REMOTE_MODE=false \
    PENPOT_MCP_MULTI_USER_MODE=true \
    PENPOT_MCP_LOG_LEVEL=info \
    PENPOT_MCP_LOG_DIR=/opt/penpot-mcp/logs

RUN apt-get update \
    && apt-get install -y --no-install-recommends bash ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/penpot/mcp/dist/ ./server/
COPY --from=builder /build/penpot/mcp/packages/plugin/dist/ ./plugin-template/
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/plugin-server.mjs /opt/penpot-mcp/plugin-server.mjs

RUN chmod +x /usr/local/bin/entrypoint.sh \
    && mkdir -p /opt/penpot-mcp/plugin /opt/penpot-mcp/logs

EXPOSE 4400 4401 4402 4403

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]