# Step 02 - Consolidated Data Model

**Output:** `specs/product/data-model.md`
**Dependencies:** step 01 (`specs/product/spec.md`).

Unify the domain model across every `specs/NNN-*/data-model.md` and reconcile
against the actual types defined in the selected baseline implementation.

## Discovery

1. Read `specs/product/spec.md` to anchor consolidated terminology.
2. Read every `specs/NNN-*/data-model.md`.
3. Enumerate concrete types in the implementation tree: dataclasses, models,
   typed dictionaries, enums, schemas under `contracts/`, or equivalent.
   Distinguish code-backed domain types from contract-only payloads,
   workflow records, benchmark observations, and helper abstractions that are
   documented but not implemented as first-class types.
4. For each entity, capture: name, attributes, types, invariants, lifecycle,
   relationships, and the owning implementation component.
5. If entity ownership or boundaries are still unclear, inspect the matching
   `plan.md` section narrowly for technical context only.

## Authoring

1. Promote only code-backed domain types to entity sections. If a source
   `data-model.md` includes contract-only payloads, workflow records,
   benchmark observations, CLI invocation logs, or helper abstractions that
   are not first-class implementation types in the selected baseline, keep
   them in `contracts/` or `research.md` instead of forcing them into the
   consolidated data model.
2. One entity per section. Use the name that appears in code (rename in the
   spec if the code is more canonical and reflects current intent).
3. Assign product-level identifiers `ENT-PRD-NNN`. Preserve original IDs in
   an appendix mapping table.
4. Where two features defined overlapping entities, merge them into one with a
   clear note on which implementation component owns the canonical definition
   and which components consume it.
5. Cite the implementing source file and line range for every attribute that
   exists in the selected baseline.
6. Flag attributes documented in old specs but absent in code as
   `Unknown from code - confirm intent` and route them to `research.md`.

## Template (skeleton)

```markdown
# Product Data Model

## Conventions

## Entity: <canonical entity name> (ENT-PRD-001)

- Owning component: <implementation path>
- Attributes:
  | Field | Type | Required | Invariant | Evidence |
- Lifecycle:
- Relationships:

## Entity: <canonical entity name> (ENT-PRD-002)

…

## Shared Enumerations

## Schema Contracts (link to specs/product/contracts/)

## Appendix - Identifier Mapping
```

## Definition of Done

- Exactly one `data-model.md` exists under `specs/product/`.
- Every entity has a code-evidenced owner module in the selected baseline.
- No entity, field, or invariant is defined in more than one place.
- Contract-only or operational concepts documented in source data models are
  either linked from `contracts/` or recorded in `research.md`, not duplicated
  as product entities.
- Appendix maps every product entity ID to its per-feature origin IDs.
