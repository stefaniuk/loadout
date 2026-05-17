# Step 08 - Audience Indexes

**Outputs:** `docs/developers/README.md` and `docs/users/README.md`
**Dependencies:** step 01 (`README.md`, `docs/README.md`,
`docs/conventions.md`, `docs/onboarding.md`).

This step creates and maintains audience-specific navigation pages that route
readers to canonical documentation without duplicating it.

## Artefact contracts

| Artefact                    | Canonical role                   | Required content                                                                                       | Must not contain                               |
| --------------------------- | -------------------------------- | ------------------------------------------------------------------------------------------------------ | ---------------------------------------------- |
| `docs/developers/README.md` | Developer navigation page        | top developer tasks, links to onboarding, reference, how-to, explanation, operations, relevant prompts | copied command tables, duplicated policy prose |
| `docs/users/README.md`      | User or operator navigation page | top user or operator tasks, links to tutorials, how-to, reference, operations, relevant explanation    | copied reference sections, ADR rationale       |

## Discovery

1. Identify the main reader groups the repository serves.
2. Map their common entry tasks to canonical documentation.
3. Confirm that the linked docs already exist or note gaps precisely.

## Mode-specific workflow

### `establish`

1. Create the audience index pages.
2. Seed them with concise task-oriented link maps, not duplicated content.

### `sync`

1. Update audience indexes when the information architecture or common task
   paths changed.
2. Keep the pages short and link-heavy.

### `audit` and `pre-pr-review`

1. Detect missing audience routes to canonical docs.
2. Flag audience pages that have become shadow copies of other files.

## Standardised expectations

Each audience index should, when practical, include:

1. Who this page is for
2. Most common tasks
3. Canonical links by task
4. Pointers to deeper reference, explanation, and operational material

## Definition of Done

- Audience pages help readers find the right canonical doc quickly.
- No canonical fact exists only in an audience page.
- The audience routing matches the current documentation set.
