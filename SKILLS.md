# SKILLS

## Build The Image

Use the root `Dockerfile`. It expects the local `./penpot` git submodule from the upstream `mcp-prod` branch, copies `penpot/mcp` into the build context, runs `./scripts/setup`, runs the upstream build commands, and invokes `pnpm run bootstrap` during image build.

## Run The Container

Use `compose.yaml` for the default local setup.

Key environment variables:

- `PENPOT_MCP_SERVER_LISTEN_ADDRESS` and `PENPOT_MCP_SERVER_PORT` control the MCP HTTP listener.
- `PENPOT_MCP_WEBSOCKET_PORT` controls the Penpot plugin WebSocket listener.
- `PENPOT_MCP_REPL_PORT` controls the REPL listener.
- `PENPOT_MCP_PLUGIN_PORT` controls the static plugin server.
- `PENPOT_MCP_PLUGIN_WEBSOCKET_URL` controls the WebSocket URL embedded into the plugin UI at startup.
- `PENPOT_MCP_SERVER_ADDRESS` is the default host used to compute the WebSocket URL when no explicit WebSocket URL is provided.
- `PENPOT_MCP_REMOTE_MODE` should usually be `true` for container deployments.

## Verify Changes

Minimum verification:

1. `docker build -t penpot-mcp:test .`
2. `docker run --rm -p 4400:4400 -p 4401:4401 -p 4402:4402 -p 4403:4403 penpot-mcp:test`
3. Confirm `http://localhost:4400/manifest.json` is reachable.
4. Confirm `http://localhost:4400/plugin.js` is reachable.
5. Confirm ports `4401`, `4402`, and `4403` accept TCP connections.

## Release Flow

GitHub Actions provides:

- `ci.yml` for build and smoke validation.
- `docker-publish.yml` for publishing multi-arch images to GHCR on `main` and version tags.