# Linear MCP Server

Issue and project orchestration for Linear via the hosted MCP endpoint, bridged through `mcp-remote` so OAuth can run in the local browser.

- **Endpoint**: `https://mcp.linear.app/mcp`
- **Upstream**: <https://linear.app/docs/mcp>

## Authentication

OAuth only. The `mcp-remote` helper opens a browser tab on first connection, performs the OAuth dance against Linear, and caches the refresh token locally. No secrets need to live in `mcp.json`.

## Least privilege

- Request the `read` scope by default - sufficient for triage, status reporting, and "what is assigned to me" workflows.
- Only widen to write scopes (`issues:write`, `comments:write`, etc.) when the workflow genuinely needs to create or update Linear records.
- Re-evaluate scope on every workspace handoff; revoke the OAuth grant from Linear settings when no longer needed.

## Example

```jsonc
{
  "servers": {
    "linear": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://mcp.linear.app/mcp"],
    },
  },
}
```
