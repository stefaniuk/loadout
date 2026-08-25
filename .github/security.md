# Security Policy

## Supported versions

This repository follows semantic versioning. Only the latest minor release receives security fixes.

| Version | Supported |
| ------- | --------- |
| 1.x     | ✅        |
| < 1.0   | ❌        |

## Reporting a vulnerability

If you believe you have found a security vulnerability in this repository - for example a prompt or agent definition that could be abused, or a script that could exfiltrate data - please **do not** open a public issue.

Instead, use GitHub's private vulnerability reporting:

1. Go to the [Security tab](https://github.com/stefaniuk/loadout/security) of this repository.
2. Click **Report a vulnerability**.
3. Provide a clear description, reproduction steps, and any suggested mitigation.

You should receive an acknowledgement within 7 calendar days. We aim to triage and respond with a remediation plan within 30 days.

## Scope

In scope:

- Prompts, agents, skills, and hooks shipped from this repository.
- The `make apply` distribution scripts (`scripts/apply.sh`, `scripts/import.sh`).
- Build and CI configuration that runs against this repository.

Out of scope:

- Issues in downstream consumer repositories caused by misconfiguration.
- Issues in GitHub Copilot or VS Code themselves (report to the upstream vendor).

## Responsible disclosure

We follow coordinated disclosure. Please give us a reasonable window to fix and release before publishing details.
