# Step 05 - How-to

**Outputs:** `docs/how-to/**`
**Dependencies:** step 01 (`README.md`, `docs/README.md`,
`docs/conventions.md`, `docs/onboarding.md`) and step 03 (`docs/reference/**`).

This step maintains task-oriented guidance for contributors or operators who
already know what they want to do.

## Artefact contracts

| Artefact                | Canonical role          | Required content                                                    | Must not contain                                           |
| ----------------------- | ----------------------- | ------------------------------------------------------------------- | ---------------------------------------------------------- |
| `docs/how-to/README.md` | How-to index            | task map, audience hints, links to reference prerequisites          | architecture essays, long concept primers                  |
| `docs/how-to/<task>.md` | Goal-oriented procedure | goal, when to use, prerequisites, steps, verification, related docs | happy-path teaching narrative, exhaustive interface tables |

## Discovery

1. Identify recurring tasks evidenced by scripts, automation, prompts, skills,
   or contribution workflows.
2. Confirm the task is stable and repeatable.
3. Gather exact commands, inputs, outputs, and verification from code or
   automation.
4. Link the task to the canonical reference pages it depends on.

## Mode-specific workflow

### `establish`

1. Create `docs/how-to/README.md`.
2. Create how-to guides only for supported, repeatable tasks.
3. Keep each guide narrow: one task, one goal.

### `sync`

1. Update how-to guides when task flow changed.
2. Pull factual interface details back into reference docs if a guide starts
   carrying too much lookup content.

### `audit` and `pre-pr-review`

1. Detect changed contributor or operator workflows without matching how-to
   updates.
2. Flag how-to guides that are obsolete, over-broad, or missing verification.

## Standardised expectations

Every `docs/how-to/<task>.md` should, when practical, include:

1. Goal
2. When to use this guide
3. Prerequisites
4. Steps
5. Verification
6. Troubleshooting or rollback when relevant
7. Links to reference and explanation material

### Troubleshooting guides

User-facing or contributor-facing troubleshooting belongs under
`docs/how-to/troubleshooting/` as goal-oriented recovery procedures. Operator
incident response and safety-sensitive recovery belong in
`docs/operations/runbooks/` instead — see
[step-07-operations.md](step-07-operations.md). Version-specific upgrade
procedures belong with the governance/lifecycle artefacts — see
[step-09-governance-lifecycle.md](step-09-governance-lifecycle.md).

## Definition of Done

- Each guide solves one concrete task.
- Procedures are accurate, verified, and linked to canonical reference pages.
- How-to content does not duplicate tutorial framing or deep reference tables.
