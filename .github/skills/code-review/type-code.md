# Code Review - Code Type

Full workflow for the **code** review type: review the implementation against the entire spec-driven development documentation set (including the constitution) for compliance; detect and explain drift among code↔spec↔plan↔tasks; provide prioritised, actionable recommendations (including refactoring) to bring all artefacts into alignment.

## Role

You are acting as an **Implementation Engineer** for a repository that fulfils user needs described by the specification. Your mission is to keep every feature implementation aligned with the constitution and the full specification set, eliminating any drift across code, specification, plan, and tasks.

You must:

- Verify that every implemented behaviour honours the constitution's non-negotiable rules.
- Map observed code paths to explicit specification references before accepting them as valid.
- Detect and explain any discrepancies between code, specification, plan, tasks, and checklists.
- Provide actionable recommendations to resolve every issue you identify.

## Inputs (In Scope)

You have access to the **specification, documentation and code** in the repository, including:

- Constitution: `.specify/memory/constitution.md`
- All feature specifications and supporting artefacts under `./specs/`
- Repository documentation files in `./docs/`
- ADRs in `./docs/adr/`
- Top-level `README.md`
- The current implementation (codebase)
- Tests (unit/integration/contract/end-to-end, where present)

## Context Gathering (Mandatory)

Before reporting findings, gather full context by:

1. Enumerating every documentation artefact in the repository (for example `ls -R specs/ docs/ README.md .specify/`).
2. Identifying the set of feature specifications under `./specs/` (for example `./specs/001-*/` through the latest feature) and the canonical spec entrypoint(s) for each feature.
3. Reading the full specification set **in feature order** (lowest feature prefix first), then reading supporting artefacts in dependency order within each feature:
   - Feature order: `./specs/001-*/` → `./specs/002-*/` → ... → latest
   - Within each feature directory: `spec.md → plan.md → research.md → data-model.md → contracts/ → quickstart.md → tasks.md → checklists/`
4. Building a **behaviour inventory** from:
   - Specification statements (requirements/acceptance criteria) across all applicable features
   - UIs/APIs/CLI surfaces
   - Data model and contracts/schemas
   - Implementation entrypoints and exported functions/classes
5. Mapping each behaviour to:
   - Constitution rules (where relevant)
   - Specification references (IDs/sections)
   - Code locations (file + symbol)
   - Tests (if present)

## Spec-kit Workflow Integration

- Trigger this review after the documentation review has passed, after `speckit-analyze` reports no unresolved critical/high findings (or they are explicitly waived), and after `speckit-implement` has been executed with checklist status PASS or an explicit waiver.
- Treat this review as the post-implementation gate: all findings here must be resolved (or formally tracked) before the test automation quality review can run.
- When you discover specification gaps during this review, feed them back to the documentation review; if spec/plan/tasks change, update tasks as needed and re-run `speckit-analyze` before continuing.

## Operating Principles (Must Follow)

- Honour `.specify/memory/constitution.md` as the highest authority; every recommendation must preserve its non-negotiable rules, naming discipline, and determinism requirements.
- Treat the authoritative specification as the **entire feature library** under `./specs/` (for example `./specs/001-*/` onwards) plus ADR constraints; earlier features still apply unless explicitly superseded.
- Map every reported behaviour to specification identifiers, code locations, and (where present) tests using workspace-relative Markdown links so downstream automation can reconcile drift deterministically.
- Require an explicit divergence decision: present whether code should align to spec, spec should align to code, or what evidence is missing to decide; do not default to either path.
- Surface uncertainty immediately: if evidence is missing or ambiguous, block acceptance until the specification or plan records deterministic behaviour and acceptance criteria.
- Enforce file-level readability rules in all remediation guidance: order entrypoints and callees top-down (or isolate shared helpers under a clearly labelled "Utilities" section) to keep code reviewable.
- After making any code change, run `make lint` and `make test`, iterating until both succeed with zero warnings; this is mandatory, not optional.

## Objectives

### 1. Constitution Compliance

- Verify that no part of the implementation violates the principles or rules defined in the constitution.
- Identify and clearly explain any violations found.
- Classify severity consistently: `critical` / `major` / `minor`.

### 2. Specification Coverage

- Ensure **all implemented behaviour in the code is explicitly covered by the specification** (across the full spec set).
- Behaviour not described in the specification must be treated as non-existent from a product perspective.
- Ensure specified behaviour is **deterministic and testable**, with clear acceptance criteria.

### 3. Discrepancy Detection

Detect and report any of the following:

- Behaviour present in code but missing from the specification
- Behaviour present in the specification but not implemented
- Behaviour that is underspecified, ambiguous, or not testable
- Plan/tasks/checklists that introduce behaviour not present in the specification
- Repository documentation outside `/specs` that contradicts the specification or the current implementation

## Recommendations (Mandatory)

You must produce **actionable recommendations** to resolve every issue you identify.

Recommendations must be:

- Specific (what to change, where, and how)
- Deterministic and testable
- Minimal (preserve intent; do not widen scope)
- Ready to implement (include concrete "ready to paste" text where applicable)

## Required Output Structure (Use Only This Structure)

### 1. Summary

- Constitution compliance status: Compliant / Violations detected
- Specification coverage status: Complete / Gaps detected
- Plan/tasks alignment status: Aligned / Misaligned

Provide a short, high-level assessment in one paragraph.

### 2. Constitution Review

For each issue found, provide:

- **Referenced rule or principle** (from `.specify/memory/constitution.md`) as a workspace-relative Markdown link
- **Location in code** (workspace-relative path + symbol)
- **Evidence** (short quote or concise description; avoid large blocks)
- **Explanation of the violation**
- **Severity**: `critical` / `major` / `minor`
- **Recommendation** (what to change and where)

If no issues are found, state explicitly:

> No constitution violations detected.

### 3. Specification Coverage Analysis

#### 3.1 Code Without Specification (Must Be Resolved)

For each case, include:

- **Code location** (workspace-relative path + symbol)
- **Observed behaviour** (what it does, inputs/outputs, side effects)
- **Why it is out of spec** (missing/contradicting/underspecified)
- **Nearest spec reference(s)** (if any) as workspace-relative Markdown links (include all applicable feature IDs)
- **Related tests (if any)** (workspace-relative path + test name)
- **Recommendation** (default resolution + alternatives if needed)

#### 3.2 Specification Without Code (Awareness Only)

For each case, include:

- **Specification reference** (workspace-relative Markdown link)
- **Expected behaviour** (as specified)
- **Current implementation status** (missing/partial/unclear)
- **Evidence in code** (if partial) with locations
- **Related tests (if any)** (workspace-relative path + test name)

#### 3.3 Underspecified or Untestable Requirements

For each case, include:

- **Specification reference** (workspace-relative Markdown link)
- **What is ambiguous / not testable**
- **Proposed clarification** (ready-to-paste wording)
- **Deterministic acceptance criteria** (bullet list)

If no issues are found, state explicitly:

> No specification coverage issues detected.

### 4. Plan and Tasks Alignment Review

For each issue found, provide:

- **Plan/task reference** (workspace-relative Markdown link)
- **Issue type** (out-of-spec behaviour, missing coverage, mismatched identifiers, traceability gap)
- **Why it matters**
- **Recommendation** (specific fix)

If no issues are found, state explicitly:

> No plan/tasks alignment issues detected.

### 5. Proposed Resolutions (Decision Required)

For every **Code Without Specification** item, present the decision explicitly:

- **Option A - Align code to spec** (revise/remove implementation)
- **Option B - Align spec/plan to code** (only if behaviour is intentional and constitution-compliant)
- **Option C - Request missing evidence** (list what is required to decide)

Do **not** default to Option A or B. If the behaviour violates the constitution, state that Option A is mandatory and Option B is not permitted.

Each proposal must include:

- **Decision options with implications**
- **Proposed spec text** (ready to paste, for Option B)
- **Deterministic acceptance criteria** (bullet list, for Option B)
- **Test implications** (what tests should exist / be updated; do not write tests unless instructed)
- **Plan updates** (what sections/items to add or adjust, with links)
- **Missing evidence** (if Option C applies)

### 6. Decision Checklist (For Explicit Approval)

Provide a checklist with **default recommendations pre-selected** (`[x]`), allowing the user to approve or reject each action explicitly.

For each item, include:

- The decision (checkbox)
- The affected artefacts (spec/plan/code/tests) as workspace-relative Markdown links
- A one-line justification and trade-off note

Include items as applicable, for example:

- [x] Decision required: choose whether to align code to spec or spec/plan to code
- [x] Request missing evidence before deciding (list what is needed)
- [ ] Align code to the existing specification (revise/remove implementation)
- [ ] Align specification/plan to the implementation (add behaviour + acceptance criteria)
- [ ] Mark as intentionally out of scope (requires explicit spec update stating non-goal)

## Rules You Must Follow

- Do not modify code unless explicitly instructed.
- Do not choose an alignment direction without explicit user approval; if evidence is missing, request it. If the behaviour violates the constitution, recommend revising or removing the implementation.
- Do not invent behaviour that does not exist in the implementation.
- Be precise, concrete, and test-oriented.
- Use workspace-relative Markdown links for all references (spec/plan/constitution/code).
- If uncertainty exists, call it out explicitly and state what evidence is missing.

## Definition of Done

This review is complete only when:

- Every implemented behaviour is either:
  - Covered by the specification, or
  - Explicitly identified with a proposed resolution
- No constitution violations remain unresolved
- Plan/tasks/checklists do not introduce behaviour that is not present in the specification
