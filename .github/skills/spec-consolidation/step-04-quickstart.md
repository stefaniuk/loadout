# Step 04 — Consolidated Quickstart

**Output:** `specs/product/quickstart.md`
**Dependencies:** steps 01–02.

Produce a single operator on-ramp covering every shipped CLI and library
entry point, derived from every `specs/NNN-*/quickstart.md` and confirmed
against the repository's current entry-point declarations and selected
baseline implementation.

Default to the current working tree at `HEAD` for command validation. Only use
the default branch when the user explicitly asks for a shipped-only baseline.

## Discovery

1. Read every `specs/NNN-*/quickstart.md`.
2. Read the current repository bootstrap and operator guidance surface:
   onboarding docs, automation guidance, entry-point declarations, runtime or
   packaging metadata, and equivalent sources of install and invocation truth.
3. Read the repository's entry-point declarations to enumerate the actual
   CLI, service, or library entry points.
4. For each entry point, confirm the implementing component in the selected
   baseline.
5. Walk relevant validation artefacts to confirm example invocations still
   produce the documented outcome.

## Authoring

1. Single page with a `Prerequisites` section, then one section per entry
   point (`<entry-point-a>`, `<entry-point-b>`, …).
2. Prefer the current repository bootstrap and operator guidance surface when
   source quickstarts disagree with current onboarding, automation, or
   entry-point declarations. Record the stale source quickstart details in
   `research.md` drift.
3. Separate local-development install from published-package install when the
   repo supports both. Do not present an aspirational package-install flow as
   the only path if the repo's current verified workflow is local bootstrap.
4. For each entry point: install or access path, minimal invocation, common
   options or flags, end-to-end flow example when relevant, troubleshooting.
5. Examples MUST be copy-pasteable and use realistic but small inputs.
6. Cite the implementing component for each entry point.
7. Drop any commands or options that no longer exist in the selected baseline;
   log them under
   research.md drift if they appeared in source quickstarts.

## Template (skeleton)

```markdown
# Product Quickstart

## Prerequisites

## Install for Local Development

## Optional Published Install

## Entry Point: <name>

### Synopsis

### Minimal example

### Common options

### Output format (link to data-model)

## Entry Point: <name>

…

## End-to-end flow

## Troubleshooting
```

## Definition of Done

- Exactly one `quickstart.md` exists under `specs/product/`.
- Every documented entry point, command, option, or flag exists in the
  selected baseline.
- Every example runs against the selected baseline.
- No content references obsolete or planned-but-unshipped commands.
