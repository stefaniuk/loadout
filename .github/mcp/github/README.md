# GitHub MCP Server

Hosted MCP endpoint exposing GitHub repos, issues, pull requests, and users to Copilot agents.

- **Endpoint**: `https://api.githubcopilot.com/mcp/`
- **Upstream**: <https://github.com/github/github-mcp-server>

## Authentication

- **OAuth (preferred)** — default for interactive developers. VS Code negotiates the token on first use, no secret material ever lands in `mcp.json`, and it respects organisation SSO policies and automatic rotation.
- **PAT (fallback)** — only for headless / CI-style scenarios where OAuth is not viable. Use a **fine-grained** Personal Access Token with the narrowest possible repo selection and minimal scopes. Supply it via an `inputs` entry with `password: true`; never inline.

## Least privilege

Three independent controls combine to keep the tool surface minimal:

1. **Read-only baseline** — `X-MCP-Readonly: true` blocks any mutating tool regardless of toolset selection.
2. **Toolset filtering** — `X-MCP-Toolsets` whitelists only the toolsets actually required by the workflow (e.g. `repos,issues,pull_requests,users`).
3. **Individual tool exclusion** — `X-MCP-Exclude-Tools` strips named tools from an otherwise-allowed toolset for fine-grained denial.

## Example

```jsonc
{
  "servers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "X-MCP-Toolsets": "repos,issues,pull_requests,users",
        "X-MCP-Readonly": "true",
      },
    },
  },
}
```

When OAuth is unavailable, add the input prompt and attach it as a bearer header:

```jsonc
{
  "inputs": [
    {
      "type": "promptString",
      "id": "github_mcp_pat",
      "description": "GitHub fine-grained Personal Access Token (only if OAuth unavailable)",
      "password": true,
    },
  ],
  "servers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "Authorization": "Bearer ${input:github_mcp_pat}",
        "X-MCP-Toolsets": "repos,issues,pull_requests,users",
        "X-MCP-Readonly": "true",
      },
    },
  },
}
```

## Security caveats

- Always use **fine-grained** PATs, never classic tokens. Restrict to specific repositories and the minimum required permissions (typically `Contents: read`, `Pull requests: read`, `Issues: read`).
- Set the shortest practical expiry and rotate aggressively; revoke immediately if a workspace handoff occurs.
- Treat the workspace `mcp.json` as sensitive even with `inputs` — review headers and URL on every approval prompt.
