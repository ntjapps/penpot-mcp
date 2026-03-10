# AGENTS

## Scope

This repository is a packaging layer for Penpot MCP. It does not vendor the upstream Penpot source tree. The Docker build clones `penpot/penpot` from the configured branch, builds the MCP server and plugin, and assembles a runtime image around those artifacts.

## Critical Paths

- `Dockerfile`: multi-stage build that clones and compiles the upstream `mcp` subtree.
- `docker/entrypoint.sh`: maps environment variables into the runtime layout, renders `manifest.json`, patches the plugin WebSocket URL, and starts both processes.
- `docker/plugin-server.mjs`: static server for the browser-loaded Penpot plugin.
- `.github/workflows/ci.yml`: builds the image and verifies that the plugin manifest and service ports are reachable.
- `.github/workflows/docker-publish.yml`: publishes the image to GHCR.

## Runtime Contract

The image exposes four ports:

- `4400`: plugin static assets and `manifest.json` for Penpot.
- `4401`: MCP HTTP and SSE endpoints.
- `4402`: plugin WebSocket endpoint.
- `4403`: Penpot REPL.

The runtime supports the upstream environment variables documented in `penpot/mcp/README.md`, plus these packaging-specific values:

- `PENPOT_MCP_PLUGIN_PORT`
- `PENPOT_MCP_PLUGIN_PUBLIC_URL`
- `PENPOT_MCP_PLUGIN_WEBSOCKET_URL`
- `PENPOT_MCP_MULTI_USER_MODE`
- `PENPOT_MCP_WEBSOCKET_PROTOCOL`

## Change Rules

- Keep the image self-contained at runtime. Avoid adding package installs during container startup.
- Preserve compatibility with upstream `develop` unless the change explicitly targets another branch.
- If you change the plugin build, keep the runtime WebSocket URL patching behavior or replace it with an equivalent dynamic mechanism.
- Validate changes with `docker build` and a smoke run that checks `http://localhost:4400/manifest.json` plus TCP reachability on `4401`, `4402`, and `4403`.