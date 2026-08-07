# Step 06 - Consolidated Checklists

**Output:** `specs/product/checklists/` (optional)
**Dependencies:** steps 01–05 plus source feature checklists.

Merge review checklists from every `specs/NNN-*/checklists/`, deduplicating
items and aligning each checklist against the consolidated artefacts.

This step is conditional. In Spec Kit, checklists are optional outputs of
`/speckit.checklist`, not guaranteed feature artefacts.

## Discovery

1. Enumerate every file under every `specs/NNN-*/checklists/`.
   If none exist, stop and report that step 06 is skipped.
2. Classify by checklist purpose: spec review, code review, test review,
   release readiness, security, accessibility, performance, etc.
3. Map each item to the consolidated requirement (`REQ-PRD-NNN`),
   entity (`ENT-PRD-NNN`), or contract it validates.

## Authoring

1. One checklist file per purpose: `spec-review.md`, `code-review.md`,
   `test-review.md`, `release-readiness.md`, …
2. Deduplicate items. Where two items overlap partially, keep the more
   specific wording.
3. Treat consolidated checklists as review instruments, not historical status
   snapshots. Do not mechanically copy `[x]` state from source feature
   checklists; leave items unchecked unless the current consolidation run
   explicitly validated them.
4. For each item, add the identifier(s) it traces to. Items that trace to
   nothing must either be removed or trigger a new requirement in
   `specs/product/spec.md` (route via `research.md` drift).
5. Add an index document under `specs/product/checklists/` listing every
   checklist and when it should be executed (e.g. pre-merge, pre-release).

## Definition of Done

- If source checklists exist, each checklist purpose has exactly one file under
  `specs/product/checklists/`.
- Every checklist item traces to a consolidated identifier.
- An index document lists every checklist with its trigger point.
- No duplicate items remain across files.
