# penpot-mcp

A Docker packaging layer for the [Penpot MCP Server](https://github.com/penpot/penpot/tree/develop/mcp).  
This repository vendors Penpot as the `penpot/` git submodule pinned to the `mcp-prod` branch and builds the upstream MCP workspace inside Docker.

---

## Architecture

```
Browser (Penpot app)
  └─ loads Penpot MCP Plugin ──► :4400  (plugin static assets + manifest.json)
        │
        └─ WebSocket ──────────► :4402  (plugin ↔ MCP server bridge)

AI client (Claude, Cursor, …)
  └─ MCP HTTP / SSE ────────────► :4401  (MCP server)

Developer / debugging
  └─ REPL ──────────────────────► :4403  (Penpot API REPL)
```

The image build runs the upstream `./scripts/setup` and `pnpm run bootstrap` flow inside Docker, and the container entrypoint starts the upstream MCP workspace with `pnpm run start` or `pnpm run start:multi-user`.

---

## Prerequisites

- Docker Engine ≥ 24 (with BuildKit enabled by default)
- Docker Compose v2 (optional, for the compose workflow)

---

## Quick Start

```shell
# Clone this repository
git clone https://github.com/<your-org>/penpot-mcp.git
cd penpot-mcp

# Initialize the upstream Penpot submodule
git submodule update --init --recursive

# Build and start with Docker Compose
docker compose up --build
```

The first build installs dependencies and compiles the upstream Penpot MCP source tree inside the Docker build — this may take several minutes.

Once running, load the plugin in Penpot:

1. Open Penpot in your browser and navigate to a design file.
2. Open **Plugins** → **Plugin manager**.
3. Enter `http://localhost:4400/manifest.json` as the plugin URL.
4. Open the plugin and click **Connect to MCP server**.
5. Connect your AI client — for example:

   ```shell
   # Claude Code
   claude mcp add penpot -t http http://localhost:4401/mcp

   # OR via SSE (legacy)
   # http://localhost:4401/sse
   ```

---

## Configuration

All configuration is done through environment variables. Pass them via `docker run -e ...`, Docker Compose, or a `.env` file.

### Server

| Variable | Description | Default |
|---|---|---|
| `PENPOT_MCP_SERVER_LISTEN_ADDRESS` | Bind address for the MCP HTTP server | `0.0.0.0` |
| `PENPOT_MCP_SERVER_PORT` | MCP HTTP/SSE port | `4401` |
| `PENPOT_MCP_WEBSOCKET_PORT` | Plugin WebSocket port | `4402` |
| `PENPOT_MCP_REPL_PORT` | REPL port | `4403` |
| `PENPOT_MCP_SERVER_ADDRESS` | Hostname used when computing WebSocket URL | `localhost` |
| `PENPOT_MCP_REMOTE_MODE` | Disable local filesystem access (`true`/`false`) | `false` |
| `PENPOT_MCP_MULTI_USER_MODE` | Enable multi-user token-based auth (`true`/`false`) | `true` |

### Plugin server

| Variable | Description | Default |
|---|---|---|
| `PENPOT_MCP_PLUGIN_SERVER_LISTEN_ADDRESS` | Bind address for the plugin HTTP server | `0.0.0.0` |
| `PENPOT_MCP_PLUGIN_PORT` | Plugin static server port | `4400` |
| `PENPOT_MCP_PLUGIN_ALLOWED_HOSTS` | Comma-separated hostnames allowed by the Vite preview server; defaults to `PENPOT_MCP_SERVER_ADDRESS` | same as `PENPOT_MCP_SERVER_ADDRESS` |
| `PENPOT_MCP_PLUGIN_WEBSOCKET_URL` | WebSocket URL embedded in the plugin UI | `ws://localhost:4402` |

### Logging

| Variable | Description | Default |
|---|---|---|
| `PENPOT_MCP_LOG_LEVEL` | Log level (`trace`, `debug`, `info`, `warn`, `error`) | `info` |
| `PENPOT_MCP_LOG_DIR` | Directory for log files | `/opt/penpot/mcp/logs` |

---

## Upstream Source

This packaging repository builds from the `./penpot` git submodule.

Initialize or refresh it with:

```shell
git submodule update --init --recursive
git submodule update --remote penpot
```

GitHub Actions initializes the submodule during checkout.

---

## Remote Deployment

For deployments where the browser is not on the same machine as the container, set:

```shell
PENPOT_MCP_REMOTE_MODE=true
PENPOT_MCP_SERVER_ADDRESS=your-server-hostname-or-ip
PENPOT_MCP_PLUGIN_WEBSOCKET_URL=ws://your-server-hostname-or-ip:4402
```

For TLS-terminated WebSocket traffic, set `PENPOT_MCP_PLUGIN_WEBSOCKET_URL=wss://your-server-hostname-or-ip:4402`.

---

## Exposed Ports

| Port | Service |
|---|---|
| `4400` | Penpot plugin static server (`manifest.json`, `plugin.js`, UI assets) |
| `4401` | MCP HTTP server — `/mcp` (Streamable HTTP) and `/sse` (legacy SSE) |
| `4402` | Plugin WebSocket bridge |
| `4403` | Penpot API REPL |

---

## Volumes

Mount a host directory at `/opt/penpot/mcp/logs` to persist log files:

```yaml
volumes:
  - ./logs:/opt/penpot/mcp/logs
```

---

## Project Layout

```
.
├── Dockerfile                  # Multi-stage image build
├── compose.yaml                # Docker Compose configuration
├── penpot/                     # Git submodule pinned to the upstream mcp-prod branch
├── docker/
│   └── entrypoint.sh           # Runtime startup for the upstream pnpm services
├── .github/
│   └── workflows/
│       ├── ci.yml              # Build + smoke test on pull requests
│       └── docker-publish.yml  # Publish to GHCR on main / version tags
├── AGENTS.md                   # AI agent guidance for this repository
└── SKILLS.md                   # Operational runbook
```

---

## CI / CD

- **`ci.yml`**: checks out the `penpot/` submodule, builds the image, starts the container, and checks that `manifest.json`, `plugin.js`, and the exposed service ports are reachable.
- **`docker-publish.yml`**: publishes multi-arch (`amd64` + `arm64`) images to the GitHub Container Registry (`ghcr.io`) on every push to `main` and on version tags (`v*`).

---

## License

MIT License — Copyright (c) 2026 [NTJ Application Studio](https://github.com/ntj-application-studio)

See [LICENSE](LICENSE) for the full text.

---

## Upstream

This project packages [penpot/penpot](https://github.com/penpot/penpot), which is licensed under the [Mozilla Public License 2.0](https://github.com/penpot/penpot/blob/develop/LICENSE).  
This packaging layer does not modify or sublicense the upstream source code.
