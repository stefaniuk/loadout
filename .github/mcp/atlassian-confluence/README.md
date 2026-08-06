# Atlassian Confluence MCP Server

Hosted Atlassian Rovo MCP server providing Confluence (and Jira) tool access for Copilot agents.

- **Endpoint**: `https://mcp.atlassian.com/v1/mcp/authv2` - note the legacy SSE endpoint (`/sse`) is deprecated; use the `authv2` HTTP endpoint above.
- **Upstream**: <https://support.atlassian.com/atlassian-rovo-mcp-server/>

## Authentication

- **OAuth 2.1 (preferred)** - first connection triggers a browser-based consent flow against the Atlassian identity provider. Tokens never touch the workspace `mcp.json`.
- **API token (fallback)** - only for admin-approved non-interactive scenarios (e.g. service principals). Build the basic credential as `Base64(email:api_token)` and supply it via an `inputs` entry with `password: true`. Treat this as a break-glass path and document the approval in your security review log.

## Least privilege

- Grant the **minimum product scopes** required by the workflow (read-only Confluence space access is usually sufficient for documentation tasks).
- Issue tokens with the **shortest practical lifetime** and rotate on schedule. Disable refresh extension where the Atlassian admin console allows.
- Combine with platform controls: **allowed-domains** restrictions for Atlassian Connect, **IP allowlists** for the MCP-calling host, and **audit log monitoring** for anomalous tool invocations.

## Example

```jsonc
{
  "servers": {
    "atlassianConfluence": {
      "type": "http",
      "url": "https://mcp.atlassian.com/v1/mcp/authv2",
    },
  },
}
```

For the admin-controlled API-token fallback, add an input and an `Authorization` header:

```jsonc
{
  "inputs": [
    {
      "type": "promptString",
      "id": "atlassian_basic_auth",
      "description": "Base64(email:api_token) for Atlassian MCP (admin-controlled fallback)",
      "password": true,
    },
  ],
  "servers": {
    "atlassianConfluence": {
      "type": "http",
      "url": "https://mcp.atlassian.com/v1/mcp/authv2",
      "headers": {
        "Authorization": "Basic ${input:atlassian_basic_auth}",
      },
    },
  },
}
```
