# AGENTS

## Scope

This repository is a packaging layer for Penpot MCP. It expects the `penpot/` git submodule to be initialized from `penpot/penpot` on the `develop` branch. The Docker build uses that submodule, runs the upstream setup/bootstrap flow inside the image build, and assembles a runtime image around the `penpot/mcp` workspace.

## Critical Paths

- `Dockerfile`: multi-stage build that copies the local `penpot/mcp` submodule content and runs `./scripts/setup` plus `pnpm run bootstrap` during build.
- `docker/entrypoint.sh`: maps container environment variables to the upstream runtime environment and starts the upstream `pnpm` services.
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
- `PENPOT_MCP_PLUGIN_WEBSOCKET_URL`
- `PENPOT_MCP_MULTI_USER_MODE`

## Change Rules

- Keep the image self-contained at runtime. Avoid adding package installs during container startup.
- Preserve compatibility with upstream `develop` unless the change explicitly targets another branch.
- If you change the plugin build or runtime startup, keep the container aligned with the upstream `./scripts/setup`, `pnpm run bootstrap`, and `pnpm run start` workflows.
- Validate changes with `docker build` and a smoke run that checks `http://localhost:4400/manifest.json` plus TCP reachability on `4401`, `4402`, and `4403`.