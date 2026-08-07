# Step 03 - Reference

**Outputs:** `docs/reference/**`
**Dependencies:** step 01 (`README.md`, `docs/README.md`,
`docs/conventions.md`, `docs/onboarding.md`).

This step creates or updates code-backed reference documentation for public
surfaces such as commands, scripts, configuration, prompts, skills, agents,
hooks, contracts, and schemas.

## Artefact contracts

| Artefact                                                               | Canonical role                               | Required content                                                                            | Must not contain                                |
| ---------------------------------------------------------------------- | -------------------------------------------- | ------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| `docs/reference/README.md`                                             | Reference index                              | surface families, link map, ownership hints, generated/manual boundary notes                | long procedures, conceptual essays              |
| `docs/reference/<surface>.md`                                          | Canonical lookup page for one surface family | scope, source of truth, interface tables, defaults, invariants, failure modes, related docs | tutorials, design debate, release notes         |
| machine-readable contract files under `docs/reference/` when justified | Published schema or contract mirror          | code-true structure, provenance, version notes if needed                                    | paraphrased narrative that can live in Markdown |

## Discovery

1. Inventory public surfaces from code, configuration, contracts, scripts,
   prompts, skills, agents, hooks, plugin metadata, and tests.
2. Group surfaces into canonical families so one fact appears in one place.
3. Confirm the authoritative source path for each family.
4. Inspect tests or validation artefacts that prove user-visible behaviour.

## Mode-specific workflow

### `establish`

1. Create `docs/reference/README.md`.
2. Create only the reference pages supported by current evidence and active
   public surfaces.
3. Prefer one page per surface family rather than many tiny overlapping files.

### `sync`

1. Update reference docs first when public surfaces changed.
2. Keep tables, flags, defaults, schemas, and examples code-true.
3. When a reference page is missing for a changed surface, create it instead
   of widening `README.md` or a how-to guide.

### `audit` and `pre-pr-review`

1. Detect surface changes without matching reference updates.
2. Flag reference pages that conflict with current code or tests.
3. Flag reference content hidden in non-reference locations.

## Standardised expectations

Every `docs/reference/<surface>.md` should, when practical, include:

1. Scope
2. Source of truth
3. Interface definition or table
4. Defaults, invariants, and edge constraints
5. Failure modes or important caveats
6. Links to related how-to, tutorial, explanation, or ADR material

For this repository, likely surface families include:

- scripts and developer commands
- prompts and prompt conventions
- skills and their step contracts
- agents and hooks
- configuration and plugin metadata
- evaluation fixtures and runner interfaces where user-visible

## Definition of Done

- Every changed public surface has exactly one canonical reference home.
- Reference pages are factual, code-backed, and free from tutorial prose.
- No canonical reference fact is duplicated across multiple files.
