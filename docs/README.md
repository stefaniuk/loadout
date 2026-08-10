# Documentation

This page is the entrypoint for the repository's supporting documentation. Start here when the root [README](../README.md) is no longer detailed enough for the task in front of you.

## How to use this documentation set

The root [README](../README.md) explains what the repository is, why it exists, and how to get to a first successful run. The documents under `docs/` carry the current-state detail behind that landing page.

Use the links below to pick the right level of detail. Generated files stay generated, and evidence-only reports stay out of the canonical guidance path. Feature-scoped spec history lives under `specs/` only when a repository is using the spec-kit workflow. This repository does not currently ship a `specs/` tree.

## Documentation by type

- [onboarding.md](onboarding.md) explains setup paths, first-run validation, selective installs, and contributor flow.
- [architecture.md](architecture.md) explains the customisation model, lifecycle, governance gates, and hook boundaries.
- [conventions.md](conventions.md) defines naming, placement, frontmatter, and ADR rules.
- [mcp.md](mcp.md) documents the optional MCP example pack, trust model, and secret-handling rules.
- `docs/adr/` stores long-lived architecture and tooling decisions, including the [Tech Radar](adr/Tech_Radar.md).

The wider documentation system also reserves canonical homes for `docs/reference/`, `docs/how-to/`, `docs/tutorials/`, `docs/explanation/`, `docs/operations/`, `docs/developers/`, and `docs/users/`. Create those areas only when the repository ships matching surfaces or evidence-backed content.

## Documentation by audience

- Contributors starting work should begin with [onboarding.md](onboarding.md), [conventions.md](conventions.md), and [../.github/contributing.md](../.github/contributing.md).
- Maintainers changing architecture or tooling should read [architecture.md](architecture.md), `docs/adr/`, and the [Tech Radar](adr/Tech_Radar.md).
- Teams evaluating optional MCP servers should read [mcp.md](mcp.md) before copying the example configuration.
- Readers browsing the shipped asset surface should use the root [README](../README.md).

## Generated inventories and reports

- `docs/prompt-reports/` is evidence-only. Keep normative guidance in canonical docs instead.
- Update this page when the documentation set gains a new canonical area or audience index.
