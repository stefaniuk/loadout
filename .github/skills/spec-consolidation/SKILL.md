---
name: spec-consolidation
description: Consolidate per-feature Spec Kit artefacts under specs/ into a product-facing specification set aligned to a selected baseline, excluding plan.md and tasks.md from the final output.
argument-hint: "Specify step: spec, data-model, research, quickstart, contracts, checklists, or all. Optional baseline: working-tree, HEAD, or default-branch"
license: MIT
version: 1.2.0
allowed-tools: []
---

# Spec Consolidation Skill

This skill derives a product-facing view from the multi-feature Spec Kit
layout (`specs/001-*/`, `specs/002-*/`, `specs/003-*/`, …) into a single
**intent-driven** specification set under `specs/product/`.

Spec Kit is branch-first: each `specs/NNN-*` directory is a durable record of
one change. This skill does **not** replace that history. It produces a
derived product read-model for teams that need one consolidated intent view
across shipped or in-flight behaviour.

It is **non-destructive**: per-feature directories remain on disk as the
canonical feature history unless the operator makes a separate archival
decision later.

## Why this exists

The repository follows spec-driven development
(`spec` → `clarify` → `plan` → `tasks` → `implement`). After several features
ship, the `specs/` tree accumulates:

- Multiple `spec.md` files describing slices of the same product.
- Stale `plan.md` and `tasks.md` files reflecting how work was scheduled, not
  what the system now does.
- Duplicated `data-model.md`, `research.md`, and `quickstart.md` content with
  partial overlaps and contradictions.

This skill produces a single, code-true, intent-only spec set. The discarded
artefact types (`plan.md`, `tasks.md`) do not belong in the final product set.
In Spec Kit, `plan.md` is still a technical design artefact, so it may be
consulted narrowly during reconciliation when that context is missing from
`research.md`, `data-model.md`, `quickstart.md`, or `contracts/`.

## Output Layout

```text
specs/product/
├── spec.md            # Single product specification (intent only)
├── data-model.md      # Consolidated domain model
├── research.md        # Consolidated decisions and trade-offs (links ADRs)
├── quickstart.md      # Unified operator quickstart
├── contracts/         # Merged or derived contract files (CLI, API, schemas, …)
└── checklists/        # Optional merged review checklists (deduplicated)
```

The numeric per-feature directories under `specs/NNN-*/` are **left in place**.
The skill writes an index document under `specs/product/` pointing to the
consolidated set, the baseline used, and the source feature directories that
fed each artefact.

## Step Resolution

Resolve the step from the user's input (`$ARGUMENTS`).

| Step | Slug        | Output path                   | Dependencies                 |
| ---- | ----------- | ----------------------------- | ---------------------------- |
| 01   | spec        | `specs/product/spec.md`       | None                         |
| 02   | data-model  | `specs/product/data-model.md` | Step 01                      |
| 03   | research    | `specs/product/research.md`   | Step 01                      |
| 04   | quickstart  | `specs/product/quickstart.md` | Steps 01-02                  |
| 05   | contracts   | `specs/product/contracts/`    | Steps 01-02                  |
| 06   | checklists  | `specs/product/checklists/`   | Steps 01-05 + source present |
| all  | (all steps) | All applicable outputs        | None                         |

Apply the following independent rules in order; stop at the first match.

1. **Baseline first.** Before any step runs, resolve the consolidation
   baseline as described in Mandatory Preparation step 6.
2. **`all` selected.** Run steps 01 → 02 → 03 → 04 → 05 in order. Then run
   step 06 if and only if at least one source `specs/NNN-*/checklists/`
   directory exists; otherwise skip it and say so.
3. **Single step selected.** Check that every dependency output listed for
   that step already exists under `specs/product/`. If any is missing, stop
   and instruct the user to run the prerequisite steps first.
4. **Step 06 selected with no source checklists.** Stop and report that
   there is nothing to consolidate.
5. **Otherwise.** Execute the selected step.

## Mandatory Preparation

Before starting any step:

1. Read the [constitution](../../../.specify/memory/constitution.md) - highest
   authority.
2. Read the [root AGENTS.md](../../../AGENTS.md) and
   [.github/copilot-instructions.md](../../copilot-instructions.md).
3. Enumerate every `specs/NNN-*/` directory and record which artefact types
   each one carries, including whether `checklists/` exists at all.
4. If the repo is medium or large, use one read-only exploration-agent pass up
   front to produce: the feature artefact matrix, overlapping capability
   groups, likely code owners, and obvious drift candidates.
5. Read any existing architecture decision records, technology guidance, and
   equivalent governance material that already shape the repository.
6. Resolve the baseline to consolidate against and state it in the output.
   The default baseline is always the current working tree at `HEAD`. Switch
   to the default branch (or another commit) only when the user input in
   `$ARGUMENTS` explicitly names that alternative baseline.
7. Build an inventory of the selected baseline implementation modules,
   shipped public surfaces, contracts, and validation artefacts using
   repository-appropriate discovery commands.

## Performance Guidance

- Use the exploration-agent output as the first inventory instead of manually
  rediscovering the full `specs/` set, implementation tree, and validation
  artefacts in every step.
- After the initial inventory, keep reads local to the same artefact type, one
  owning abstraction, and the smallest number of enforcing tests needed to
  confirm behaviour.
- If the user asks for before/after analysis, prefer a second read-only
  comparison-agent pass after consolidation instead of manually re-reading the
  whole spec tree.

## Operating Principles

1. **Intent only.** The consolidated `spec.md` MUST describe _what the system
   does and why_, never _how it was scheduled to be built_. Strip every
   reference to sprints, phases, branches, tasks, or implementation order.
2. **Feature history stays canonical.** The per-feature `specs/NNN-*`
   directories remain the change history. `specs/product/` is a derived
   product view, not a replacement.
3. **Code is the tiebreaker.** When per-feature specs disagree, prefer the
   behaviour evidenced in the selected baseline implementation and validation
   artefacts.
   Record any spec/code drift in `specs/product/research.md` under a
   `Reconciliation Notes` section.
4. **Plan-aware, output-clean.** In Spec Kit, `plan.md` is a technical design
   artefact, not just schedule. You may inspect it narrowly for architecture
   boundaries, technical rationale, and trace links when that context is
   missing elsewhere. Never emit phases, work packages, task IDs, or
   implementation order into the consolidated outputs.
5. **Drop execution artefacts from the output.** Do not read, copy, or
   summarise `tasks.md` files. Their content is implementation scaffolding and
   out of scope for product intent.
6. **Single source of truth per concept.** Each domain term, requirement, and
   contract MUST live in exactly one place. Replace duplicates with links.
7. **Code-backed data model only.** The consolidated `data-model.md` is for
   code-backed domain types in the selected baseline. If a source
   `data-model.md` also documents contract-only payloads, workflow records,
   benchmark observations, or helper abstractions that are not first-class
   implementation types, keep them in `contracts/` or `research.md` rather
   than promoting them to product entities.
8. **Evidence-first.** Every requirement in `spec.md` cites the source feature
   section and the implementing evidence path from the selected baseline.
9. **Account for source coverage explicitly.** Every source requirement,
   entity, contract, and checklist item must end in exactly one documented
   state: merged into a consolidated artefact, explicitly excluded with
   rationale, or recorded in `research.md` as drift or out-of-product scope.
   Silent omission is not allowed.
10. **Start contracts from shipped surfaces.** Build contract coverage from
    the selected baseline's shipped public surfaces as well as source
    contract files. Every shipped CLI, API, schema, or equivalent exposed
    surface must have exactly one product-facing contract or an explicit
    rationale for why no separate contract is needed.
11. **Defer forward links cleanly.** If an earlier step should reference an
    output produced by a later step, either defer that link until the target
    exists or add it only when a final whole-tree validation pass will run
    after the last requested step. Do not leave knowingly broken internal links
    behind as a temporary state.
12. **Mark unknowns.** Where intent cannot be recovered from specs or the
    selected baseline,
    write `Unknown from code - {suggested action}` rather than guessing.
13. **Non-destructive.** Never delete or rewrite the source `specs/NNN-*/`
    directories. Archival is an operator decision documented in the final
    summary message.
14. **British English, ASCII-only**, in line with [AGENTS.md](../../../AGENTS.md).

## Workflow Per Step

### Discovery

For every step:

1. Read the outputs of all prior steps in `specs/product/` (if present) to
   build cumulative context.
2. Re-read the source artefacts of the **same type** across every feature
   directory (e.g. step `data-model` re-reads every
   `specs/NNN-*/data-model.md`).
3. Reuse the initial overlap map and candidate evidence modules rather than
   remapping the whole repo from scratch.
4. If a feature lacks the same-type artefact, record that absence rather than
   inventing it.
5. Walk relevant implementation and validation artefacts in the selected
   baseline to confirm behaviour.
6. If an architectural ambiguity remains after reading same-type artefacts and
   code, inspect the corresponding `plan.md` section narrowly and record that
   it was used only for technical context, not behavioural authority.

### Step-Specific Workflow

Each step has a dedicated companion document with detailed instructions, a
template, and a Definition of Done. Follow the companion for the step being
executed.

- **Step 01 - Spec.** See [step-01-spec.md](step-01-spec.md). Produces the
  single `specs/product/spec.md` by merging every `spec.md`, deduplicating
  requirements, assigning stable identifiers (`REQ-PRD-NNN`), and aligning
  ubiquitous language across modules.
- **Step 02 - Data Model.** See [step-02-data-model.md](step-02-data-model.md).
  Produces `specs/product/data-model.md` by unifying entities, schemas, and
  invariants across features.
- **Step 03 - Research.** See [step-03-research.md](step-03-research.md).
  Produces `specs/product/research.md` containing decisions, alternatives, and
  trade-offs. Cross-links to ADRs; surfaces spec/code drift discovered during
  consolidation.
- **Step 04 - Quickstart.** See [step-04-quickstart.md](step-04-quickstart.md).
  Produces `specs/product/quickstart.md` as a single operator on-ramp covering
  every shipped CLI and library entry point.
- **Step 05 - Contracts.** See [step-05-contracts.md](step-05-contracts.md).
  Produces `specs/product/contracts/` by merging schema files, CLI contracts,
  API contracts, and inline normative contract sections where standalone
  source contract files are missing or incomplete.
- **Step 06 - Checklists.** See [step-06-checklists.md](step-06-checklists.md).
  Produces `specs/product/checklists/` by deduplicating review checklists.

### Common Closing Steps

After producing the output for any step:

1. Validate every link that targets an artefact that already exists. If a step
   should cross-link to a later-step output, defer that link until the target
   exists or ensure a final whole-tree validation pass will run after the last
   requested step.
2. Confirm no schedule or task content from `plan.md` or `tasks.md` has leaked
   into the output.
3. Run focused, non-mutating validation on `specs/product/**` first: Markdown
   structure, links, JSON validity for schemas, and path existence for
   referenced implementation or validation artefacts.
4. If broader repository gates such as `make lint` or `make test` exist, run
   them after focused validation. If they fail for unrelated pre-existing
   issues, report that separately from any new consolidation failures.
5. When multiple requested steps were run, rerun focused validation across the
   full `specs/product/**` tree after the final requested step to catch
   deferred cross-links and whole-set consistency issues.
6. Run one cross-artefact completeness pass across the requested outputs:
   reconcile consolidated capabilities, quickstart entry points, contract
   index entries, checklist traces, and the source-coverage ledger so that no
   shipped public surface or source identifier is silently omitted.
7. Update the index document under `specs/product/` with an entry for the
   artefact, the
   baseline used, and the source feature directories consumed. If a step is
   skipped because no source artefacts exist, say so explicitly.
8. In the final assistant message, include a concise before/after analysis:
   fragmentation before consolidation, strongest improvements after
   consolidation, remaining risks, and confidence that the product set matches
   the selected baseline.
9. In the final assistant message, list any duplicate derived artefacts that
   now have a product-facing counterpart and could be archived after human
   review. Do not recommend deleting the `specs/NNN-*` feature histories.

## Definition of Done (whole skill)

- `specs/product/` contains one consolidated file or directory for each
  requested artefact type that exists in the source set. `checklists/` exists
  only when source feature checklists exist and step 06 is run.
- No schedule or task content from any `plan.md` or `tasks.md` appears
  anywhere in the output.
- Every requirement, entity, contract, and checklist item appears in exactly
  one consolidated location.
- Every source requirement, entity, contract, and checklist item is accounted
  for: merged, explicitly excluded with rationale, or recorded as drift or
  out-of-product scope.
- The consolidated data model includes only code-backed domain entities in the
  selected baseline; contract-only or operational concepts remain in
  `contracts/` or `research.md`.
- Every claim cites evidence in the source specs and/or selected baseline
  code.
- All consolidated requirements are traceable to the selected baseline; drift
  is logged in `specs/product/research.md`.
- Every shipped public surface in the selected baseline has exactly one
  consolidated contract or an explicit rationale for why no separate
  product-facing contract is needed.
- Focused validation passes on the new `specs/product/**` artefacts.
- When multiple steps are requested, a final focused validation pass succeeds
  across the whole `specs/product/**` tree after the last step is written.
- A cross-artefact completeness pass succeeds across the requested outputs:
  consolidated capabilities, quickstart entry points, contract index entries,
  checklist traces, and source-coverage accounting are mutually consistent.
- If repo-wide quality gates such as `make lint` or `make test` exist, they
  are run and any unrelated pre-existing failures are explicitly separated from
  new consolidation failures.
- The source feature directories remain untouched and continue to provide the
  feature/change history.

## Out of Scope

- Editing or deleting any `specs/NNN-*/` directory.
- Generating new ADRs (use the standard ADR workflow if needed).
- Producing a new plan or tasks file - these are intentionally excluded from
  the final product set.
