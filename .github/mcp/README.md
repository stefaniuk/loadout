# MCP Server Stubs

This directory hosts opt-in [Model Context Protocol](https://modelcontextprotocol.io) server examples that workspaces may copy in alongside the Copilot customisation pack. The stubs are **workspace-level only** - they are deliberately _not_ registered through [`plugin.json`](/plugin.json) so VS Code triggers an explicit trust prompt the first time each server starts.

Read [`docs/mcp.md`](/docs/mcp.md) for the trust model, secret-handling rules, and the workspace install workflow (`make apply dest=… subset=mcp`).

## Available stubs

| Server               | Path                                                               | Purpose                                                                 |
| -------------------- | ------------------------------------------------------------------ | ----------------------------------------------------------------------- |
| GitHub               | [`github/README.md`](github/README.md)                             | Repos, issues, PRs, and user lookups via the hosted GitHub MCP service. |
| Linear               | [`linear/README.md`](linear/README.md)                             | Linear issue + project orchestration via the OAuth `mcp-remote` bridge. |
| Atlassian Confluence | [`atlassian-confluence/README.md`](atlassian-confluence/README.md) | Confluence + Jira read/write via the hosted Atlassian Rovo MCP server.  |

## Quick selection guidance

- Start with the smallest set of servers that supports the workflow at hand. Each enabled server expands the agent's tool surface and audit footprint.
- Prefer hosted (`type: http`) endpoints with managed OAuth over locally bridged stdio servers when both are available - fewer secrets, easier rotation.
- Always copy the per-server example block from [`.vscode/mcp.json.example`](/.vscode/mcp.json.example) into a real `.vscode/mcp.json`; never inline secrets into the file.
- Review the per-server README for least-privilege scope guidance before approving a server in a new workspace.

## Security note

MCP servers extend the agent's capabilities to your accounts and data. Before approving any server, read the trust checklist in [`docs/mcp.md`](/docs/mcp.md) and verify the endpoint, headers, and required scopes against the per-server README.
