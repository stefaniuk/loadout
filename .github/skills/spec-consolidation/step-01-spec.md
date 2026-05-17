# Step 01 — Consolidated Specification

**Output:** `specs/product/spec.md`
**Dependencies:** none.

Produce a single intent-driven product specification by merging every
`specs/NNN-*/spec.md` and reconciling against the shipped code.

Use the selected baseline for every code citation. Default to the current
working tree at `HEAD`. Only switch to the default branch when the user asks
for a shipped-only view.

## Discovery

1. List every `specs/NNN-*/spec.md` on disk.
2. If the repo is medium or large, run one read-only exploration pass to
   identify overlapping capability groups, likely evidence modules, and obvious
   source drift before detailed reading.
3. For each, extract: purpose, scope (in/out), terminology, requirements
   (functional and non-functional), clarifications, and acceptance criteria.
4. Record every source requirement identifier in a coverage ledger before
   merging. Any source requirement that is consolidated, deliberately
   excluded, or superseded by observed code drift must be marked explicitly
   rather than disappearing during merge.
5. Do not mine `tasks.md` for behaviour.
6. If the spec and code leave a design boundary unclear, inspect the matching
   `plan.md` section narrowly for technical context only.
7. Walk the selected baseline's implementation and validation artefacts to
   build a behaviour inventory keyed by capability or owning component.
8. Read ratified architecture, governance, and equivalent decision records
   where present.

## Authoring

1. Group requirements by capability, not by historical feature number.
2. Resolve duplicates: keep the wording that most closely matches the
   intent evidenced in the source specs and the behaviour evidenced in the
   selected baseline implementation. Discard alternatives, recording the chosen
   source in an appendix.
3. If one capability is described partly in a feature `spec.md` and partly in
   quickstarts, contracts, or tests, keep the behaviour in `spec.md` and send
   stale execution detail to `research.md` drift rather than inflating the
   product spec.
4. Assign new product-level identifiers `REQ-PRD-001`, `REQ-PRD-002`, …
   Preserve the original IDs in the appendix table:
   `REQ-PRD-001 ← 001/<source-id-1>, 002/<source-id-2>`.
5. Treat Appendix A as a completeness ledger, not a sample map: account for
   every source requirement identifier by mapping it to a product
   requirement or by pointing to the exclusion or drift note that explains
   why it is not merged.
6. Normalise ubiquitous language across modules; if a term is used with two
   meanings, pick the one matching the code and rename the other.
7. Strip every reference to: phases, sprints, branches, work packages,
   feature numbers, "MVP", task IDs, "Phase 1/2", or implementation order.
8. Cite each requirement with at least one source spec section **and** one
   implementation, validation, or contract path from the selected baseline.

## Template (skeleton)

```markdown
# Product Specification: <product name>

**Status:** Consolidated
**Sources:** 001-..., 002-..., 003-...
**Last reconciled with code:** <commit sha>

## Purpose

## Problem Context

## Scope (In / Out)

## Ubiquitous Language

## Functional Requirements

### Capability: <capability name>

- **REQ-PRD-001** …

### Capability: <capability name>

- **REQ-PRD-NNN** …

## Non-Functional Requirements

## Operational Behaviour

## Acceptance Criteria (capability-level)

## Appendix A — Identifier Mapping

## Appendix B — Source Reconciliation Notes (pointer to research.md)
```

## Definition of Done

- Exactly one `spec.md` exists under `specs/product/`.
- Every requirement carries a `REQ-PRD-NNN` ID and at least one code citation.
- No scheduling, planning, or task language remains.
- Appendix A maps every product ID back to its per-feature origin IDs and
  accounts for any source requirement IDs that were excluded or routed to
  drift.
- Drift between consolidated intent and code is logged for step 03.
