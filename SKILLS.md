# SKILLS

## Build The Image

Use the root `Dockerfile`. It clones the upstream Penpot repository, builds the MCP server bundle, installs production dependencies into the bundled server directory, and builds the plugin with a placeholder WebSocket URL that is patched at runtime.

## Run The Container

Use `compose.yaml` for the default local setup.

Key environment variables:

- `PENPOT_MCP_SERVER_LISTEN_ADDRESS` and `PENPOT_MCP_SERVER_PORT` control the MCP HTTP listener.
- `PENPOT_MCP_WEBSOCKET_PORT` controls the Penpot plugin WebSocket listener.
- `PENPOT_MCP_REPL_PORT` controls the REPL listener.
- `PENPOT_MCP_PLUGIN_PORT` controls the static plugin server.
- `PENPOT_MCP_PLUGIN_PUBLIC_URL` controls the manifest host Penpot uses to load the plugin.
- `PENPOT_MCP_PLUGIN_WEBSOCKET_URL` controls the WebSocket URL embedded into the plugin UI at startup.
- `PENPOT_MCP_SERVER_ADDRESS` is the default host used to compute the WebSocket URL when no explicit WebSocket URL is provided.
- `PENPOT_MCP_REMOTE_MODE` should usually be `true` for container deployments.

## Verify Changes

Minimum verification:

1. `docker build -t penpot-mcp:test .`
2. `docker run --rm -p 4400:4400 -p 4401:4401 -p 4402:4402 -p 4403:4403 penpot-mcp:test`
3. Confirm `http://localhost:4400/manifest.json` is reachable.
4. Confirm ports `4401`, `4402`, and `4403` accept TCP connections.

## Release Flow

GitHub Actions provides:

- `ci.yml` for build and smoke validation.
- `docker-publish.yml` for publishing multi-arch images to GHCR on `main` and version tags.