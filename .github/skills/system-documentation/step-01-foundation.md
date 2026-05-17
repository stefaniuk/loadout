# Step 01 - Foundation

**Outputs:** `README.md`, `docs/README.md`, `docs/conventions.md`,
`docs/onboarding.md`, and baseline directories under `docs/`
**Dependencies:** none.

This step establishes the documentation entrypoints and the minimum
repository-wide structure that later steps rely on.

## Artefact contracts

| Artefact                                                                                      | Canonical role             | Required content                                                                                          | Must not contain                                            |
| --------------------------------------------------------------------------------------------- | -------------------------- | --------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------- |
| `README.md`                                                                                   | Repository landing page    | purpose, value, quick start, primary workflows, links to deeper docs                                      | deep reference tables, ADR debates, runbooks                |
| `docs/README.md`                                                                              | Documentation landing page | doc map by type and audience, entrypoints, generated-inventory note                                       | feature history, duplicated reference details               |
| `docs/conventions.md`                                                                         | Repository conventions     | naming rules, documentation placement rules, generated-file policy, contribution expectations             | installation walkthroughs, exhaustive command reference     |
| `docs/onboarding.md`                                                                          | Contributor on-ramp        | prerequisites, setup, first successful validation path, common newcomer tasks                             | long rationale, duplicate reference tables                  |
| `docs/{tutorials,how-to,reference,explanation,operations/runbooks,developers,users,prompts}/` | Baseline structure         | location exists when the model is established; add a short index page where direct navigation is expected | empty placeholder prose presented as authoritative guidance |

`docs/catalogue.md` is generated and is not part of this step's authored
outputs.

## Discovery

1. Read the current `README.md` and top-level docs entrypoints.
2. Inventory contributor setup, validation, and navigation flows from current
   scripts, automation, and docs.
3. Confirm which docs directories already exist and which are missing.
4. Identify generated files so they are not hand-edited.

## Mode-specific workflow

### `establish`

1. Create any missing baseline directories required by the documentation
   system.
2. Create or update the four foundation entrypoints with concise, canonical
   scope.
3. Add short index pages only where direct navigation is needed; do not invent
   deep content for later steps.

### `sync`

1. Update the entrypoints when repository purpose, setup, navigation, or
   documentation placement rules changed.
2. Keep the edit local; do not expand foundation docs into reference or
   operational material.

### `audit` and `pre-pr-review`

1. Check that each foundation artefact exists and matches its role.
2. Flag misplaced deep content in foundation docs.
3. Report navigation gaps that block readers from finding canonical content.

## Standardised expectations

### `README.md`

Prefer these sections when the file is being standardised:

1. Purpose
2. What the repository contains
3. Quick start
4. Key workflows
5. Documentation map

### `docs/README.md`

Prefer these sections:

1. How to use this documentation set
2. Documentation by type
3. Documentation by audience
4. Generated inventories and reports

### `docs/conventions.md`

Prefer these sections:

1. Writing and naming conventions
2. Canonical placement rules
3. Generated-content rules
4. Update expectations when code changes

### `docs/onboarding.md`

Prefer these sections:

1. Prerequisites
2. Local setup
3. First successful validation
4. Common first tasks
5. Where to go next

## Definition of Done

- The foundation entrypoints exist and have clearly separated roles.
- Required baseline directories exist for later documentation steps.
- No deep reference, tutorial, or runbook content is stored in foundation
  pages.
- Readers can navigate from the repository root to the correct canonical
  documentation area.
