# Step 04 - Explanation

**Outputs:** `docs/explanation/**`
**Dependencies:** step 02 (`docs/architecture.md`, `docs/adr/*.md`) and step 03
(`docs/reference/**`).

This step maintains conceptual documentation: terminology, mental models,
trade-offs, boundaries, and why the repository works the way it does.

## Artefact contracts

| Artefact                      | Canonical role            | Required content                                                                   | Must not contain                                               |
| ----------------------------- | ------------------------- | ---------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| `docs/explanation/README.md`  | Explanation index         | topic map, relationship to reference and ADRs, entrypoints for core concepts       | procedures, exhaustive tables                                  |
| `docs/explanation/<topic>.md` | Concept or rationale page | question or concept, mental model, boundaries, trade-offs, related canonical links | operational checklists, step-by-step setup, command catalogues |

## Discovery

1. Read relevant reference pages, architecture docs, ADRs, and tests.
2. Identify concepts readers need to understand before using the reference or
   following procedures.
3. Separate conceptual gaps from procedural gaps.
4. Confirm that the topic really needs explanation instead of reference or
   how-to treatment.

## Mode-specific workflow

### `establish`

1. Create `docs/explanation/README.md` when the repository is formalising the
   explanation layer.
2. Create concept pages only for stable, repeated concepts already evidenced
   in the repo.

### `sync`

1. Update explanation pages when terminology, architecture rationale,
   component boundaries, or trade-offs changed.
2. Link to reference and ADRs instead of restating their full content.

### `audit` and `pre-pr-review`

1. Flag concepts with no explanation page when that absence makes other docs
   hard to understand.
2. Flag explanation pages that have turned into procedures or reference
   tables.

## Standardised expectations

Every explanation page should, when practical, cover:

1. The concept or question
2. The mental model
3. Boundaries and non-goals
4. Trade-offs and consequences
5. Links to canonical reference, how-to, tutorial, and ADR material

### FAQ pages

When recurring questions accumulate, prefer a single `docs/explanation/faq.md`
over scattering Q&A across other pages. Each entry should answer one question
concisely and link to canonical reference, how-to, or ADR material rather than
restating it.

## Definition of Done

- Explanation pages clarify concepts without turning into procedures or
  reference dumps.
- Conceptual gaps that block correct use of the repo are addressed or reported.
- Explanation content is traceable to architecture, ADRs, or stable code
  structure.
