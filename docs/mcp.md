# Model Context Protocol (MCP) Servers

This repository ships optional MCP server stubs as **workspace-distributed examples**. They are intentionally not registered as a plugin, so VS Code triggers an explicit trust confirmation the first time each server is started in a workspace. See the upstream documentation: <https://code.visualstudio.com/docs/copilot/customization/mcp-servers>.

## Purpose

- Provide vetted, opinionated starting points for popular MCP servers (GitHub, Linear, Atlassian Confluence) with least-privilege defaults baked in.
- Keep the agent's tool surface minimal by default - every workspace opts in deliberately.
- Document the security posture (auth modes, scopes, rotation) alongside each example so reviewers can approve servers with full context.

## When to use

- **Opt-in per workspace.** Copy the stubs only into workspaces that genuinely need them.
- **Never auto-bundled.** The pack ships under `.example` filenames precisely so that VS Code does not auto-load the configuration. You must rename or copy the file deliberately.
- Prefer the smallest viable set of servers for the task at hand - each enabled server expands the agent's blast radius.

## Trust model

VS Code surfaces an explicit trust confirmation the first time a workspace MCP server starts. Treat that prompt as the **last line of defence**:

> ⚠️ Starting a server directly from the configuration file (for example via "Run Server" code lenses on the JSON) can bypass the standard trust prompt. Always allow VS Code to start the server through normal agent workflows so the consent dialog appears.

### Trust checklist

Before approving an MCP server in a new workspace, confirm:

1. **Origin verified** - the server URL or command matches the upstream documented in this repository's per-server README.
2. **Config reviewed** - read the `url`, `command`, `args`, `headers`, and any `env` entries before clicking _Allow_. Reject anything you cannot explain.
3. **Copied from `.example`** - prefer copying `.vscode/mcp.json.example` to `.vscode/mcp.json` so the canonical least-privilege defaults are preserved.
4. **Secrets via `inputs`** - every credential is sourced from an `inputs` entry with `password: true`; no secret material is inlined.
5. **Trust reset on changes** - when `mcp.json` changes (especially `url`, `command`, or `headers`), reset VS Code's trust for the server so the prompt reappears.
6. **Sandboxing enabled** - for stdio servers, run them under available platform sandboxing (containers, `firejail`, macOS App Sandbox) where feasible.

## Secret handling

- **NEVER** inline secrets in `mcp.json`. Always declare an `inputs` entry with `"password": true` and reference it via `${input:id}`.
- Rotate any credential that appears in plain text in version control history immediately.
- Prefer hosted OAuth (no token in config) over PAT / API-token paths whenever the server supports it.

## Subset install

To copy only the MCP example pack into a target workspace:

```bash
make apply dest=/path/to/target subset=mcp
```

This places `.vscode/mcp.json.example`, `.github/mcp/` (per-server READMEs), and this document at the destination. Nothing under `.github/agents/`, `.github/prompts/`, or `.github/instructions/` is touched.

## Per-server READMEs

- [GitHub](/.github/mcp/github/README.md)
- [Linear](/.github/mcp/linear/README.md)
- [Atlassian Confluence](/.github/mcp/atlassian-confluence/README.md)

## Further reading

- VS Code: [Use MCP servers in Copilot](https://code.visualstudio.com/docs/copilot/customization/mcp-servers)
- Index of stubs: [`.github/mcp/README.md`](/.github/mcp/README.md)
- Example config: [`.vscode/mcp.json.example`](/.vscode/mcp.json.example)
