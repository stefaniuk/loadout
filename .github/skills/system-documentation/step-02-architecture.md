# Step 02 - Architecture

**Outputs:** `docs/architecture.md` and `docs/adr/*.md`
**Dependencies:** step 01 (`README.md`, `docs/README.md`,
`docs/conventions.md`, `docs/onboarding.md`).

This step maintains the current-state architecture view and the ADR trail for
lasting technical decisions.

## Artefact contracts

| Artefact               | Canonical role                | Required content                                                                        | Must not contain                                                         |
| ---------------------- | ----------------------------- | --------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| `docs/architecture.md` | Current architecture overview | system scope, major components, boundaries, flows, external dependencies, ADR links     | decision logs, exhaustive command reference, operational incident steps  |
| `docs/adr/ADR-*.md`    | Architectural decision record | context, at least three options, decision, consequences, status, conversational context | current-state implementation inventory, feature history, task sequencing |

## Discovery

1. Read the current `docs/architecture.md` and relevant ADRs.
2. Inspect the code, contracts, scripts, and tests that define system
   boundaries or major flows.
3. Determine whether the change is architectural, policy-level, or merely a
   local implementation detail.
4. If an ADR is required, use the repository ADR template when creating or
   updating it.

## Mode-specific workflow

### `establish`

1. Create or normalise `docs/architecture.md` as the current-state view.
2. Ensure `docs/adr/` exists and that architecture prose links to ADRs where
   decisions already exist.
3. Do not create speculative ADRs just to fill the directory.

### `sync`

1. Update `docs/architecture.md` whenever system boundaries, control flow,
   integration points, or ownership changed.
2. Create or update an ADR only when a lasting technical decision changed.
3. Link the architecture overview to the relevant ADRs instead of duplicating
   their rationale.

### `audit` and `pre-pr-review`

1. Check for architecture-sensitive code or policy changes without matching
   architecture or ADR updates.
2. Flag architecture docs that describe obsolete components or flows.
3. Flag ADR-only changes where the current-state overview was not updated.

## Standardised expectations

### `docs/architecture.md`

Prefer these sections:

1. System purpose and scope
2. Component map
3. Key flows and boundaries
4. External systems and dependencies
5. Relevant ADRs
6. Known constraints or current limitations

### `docs/adr/ADR-*.md`

Every ADR should capture:

1. Context
2. Options considered
3. Decision
4. Consequences
5. Status and references

## Definition of Done

- `docs/architecture.md` reflects the current system structure rather than
  historical debate.
- ADRs exist only for lasting technical decisions and follow repository ADR
  discipline.
- Architecture-sensitive changes are traceable between code, architecture, and
  ADRs.
