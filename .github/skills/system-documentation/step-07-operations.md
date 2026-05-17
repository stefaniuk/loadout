# Step 07 - Operations

**Outputs:** `docs/operations/README.md` and `docs/operations/runbooks/**`
**Dependencies:** step 01 (`README.md`, `docs/README.md`,
`docs/conventions.md`, `docs/onboarding.md`) and step 03 (`docs/reference/**`).

This step maintains operational guidance for support, release, incident, or
maintenance procedures where correctness and safety matter.

## Artefact contracts

| Artefact                                  | Canonical role                   | Required content                                                                                | Must not contain                                           |
| ----------------------------------------- | -------------------------------- | ----------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| `docs/operations/README.md`               | Operations index                 | operational domains, runbook map, ownership or escalation hints                                 | general contributor onboarding, conceptual essays          |
| `docs/operations/runbooks/<procedure>.md` | Repeatable operational procedure | trigger, impact, prerequisites, exact steps, verification, rollback, escalation, evidence paths | vague narrative, tutorial framing, stale command summaries |

## Discovery

1. Inventory operational automation, maintenance flows, release steps,
   recovery procedures, and safety-sensitive tasks.
2. Confirm triggers, guardrails, verification, and rollback paths from code,
   automation, or current operator practice.
3. Distinguish operator runbooks from ordinary contributor how-to guides.

## Mode-specific workflow

### `establish`

1. Create `docs/operations/README.md` and `docs/operations/runbooks/` when the
   repository needs an operational layer.
2. Create runbooks only for procedures that are repeatable and supported.

### `sync`

1. Update runbooks when operational automation, release flow, rollback steps,
   or support procedures changed.
2. Prefer exact commands, checks, and escalation paths over prose summaries.

### `audit` and `pre-pr-review`

1. Detect safety-sensitive or release-related changes without runbook updates.
2. Flag runbooks lacking verification, rollback, or escalation detail.

## Standardised expectations

Every runbook should, when practical, include:

1. Trigger or scenario
2. Impact and scope
3. Preconditions and access needs
4. Exact steps
5. Verification
6. Rollback or recovery
7. Escalation path
8. Evidence, logs, or artefact locations

### Relationship to upgrade guides

Safety-sensitive upgrade procedures (breaking releases, data migrations,
required operator action) belong under `docs/operations/runbooks/` and must
be linked from `CHANGELOG.md`. Version-agnostic upgrade recipes for end users
belong under `docs/how-to/`. The governance step coordinates both — see
[step-09-governance-lifecycle.md](step-09-governance-lifecycle.md).

## Definition of Done

- Operational procedures are documented in runbooks, not buried in general
  guides.
- Safety-sensitive workflows include verification and rollback.
- Operators can follow the document without inferring missing steps.
