# syntax=docker/dockerfile:1.7

FROM node:24-bookworm-slim AS build

WORKDIR /opt/penpot/mcp

RUN apt-get update \
    && apt-get install -y --no-install-recommends bash ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

# pnpm 12 no longer runs through corepack (corepack is also gone from Node 25+), so install the
# standalone binary with the same version and SHA-256 pins as upstream docker/images/Dockerfile.mcp.
ARG PNPM_VERSION=12.15.0
RUN set -eux; \
    ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in \
       arm64) PNPM_ARCH='arm64'; PNPM_SHA256='d7ce93a2c7d847d3a34bd3f559b60c14f578b1320c17cc352a2c5c5fdf956117' ;; \
       amd64) PNPM_ARCH='x64'; PNPM_SHA256='55b5ed0092bd11176c1669598e231ae52e7cedac59de6efd0d415730f37d0598' ;; \
       *) echo "Unsupported arch: ${ARCH}"; exit 1 ;; \
    esac; \
    curl -LfsSo /tmp/pnpm.tar.gz "https://github.com/pnpm/pnpm/releases/download/v${PNPM_VERSION}/pnpm-linux-${PNPM_ARCH}.tar.gz"; \
    echo "${PNPM_SHA256} */tmp/pnpm.tar.gz" | sha256sum -c -; \
    tar -xzf /tmp/pnpm.tar.gz -C /usr/local/bin pnpm; \
    chmod 755 /usr/local/bin/pnpm; \
    rm -f /tmp/pnpm.tar.gz; \
    pnpm --version

COPY penpot/mcp /opt/penpot/mcp
# packages/plugin links @penpot/plugin-types from ../../../plugins/libs/plugin-types (outside mcp/).
COPY penpot/plugins/libs/plugin-types /opt/penpot/plugins/libs/plugin-types

RUN test -f package.json && test -x scripts/setup

RUN ./scripts/setup

RUN pnpm run build

RUN bash -lc 'set -euo pipefail; timeout 20s pnpm run bootstrap || status=$?; if [[ ${status:-0} -ne 0 && ${status:-0} -ne 124 ]]; then exit ${status}; fi'

FROM node:24-bookworm-slim AS runtime

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
    PENPOT_MCP_MULTI_USER_MODE=false \
    PENPOT_MCP_LOG_LEVEL=info \
    PENPOT_MCP_LOG_DIR=/opt/penpot/mcp/logs

RUN apt-get update \
    && apt-get install -y --no-install-recommends bash ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/local/bin/pnpm /usr/local/bin/pnpm
COPY --from=build /opt/penpot/plugins/libs/plugin-types /opt/penpot/plugins/libs/plugin-types
COPY --from=build /opt/penpot/mcp /opt/penpot/mcp
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh \
    && mkdir -p /opt/penpot/mcp/logs

EXPOSE 4400 4401 4402 4403

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]