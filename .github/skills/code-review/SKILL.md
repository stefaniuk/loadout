---
name: code-review
description: Run a structured Spec Kit review focused on code compliance, documentation quality, or test coverage, positioned within the spec-driven development pipeline.
argument-hint: "Specify review type: code, documentation, or test"
---

# Code Review Skill

This skill runs a structured review within the Spec Kit pipeline. It supports three review types, each with a distinct focus and output format.

## Review Type Resolution

Resolve the review type from the user's input (`$ARGUMENTS`). Match against the table below.

| Type          | Role                    | Focus                                                                                        | Position in pipeline                     |
| ------------- | ----------------------- | -------------------------------------------------------------------------------------------- | ---------------------------------------- |
| documentation | Product Owner           | Spec integrity, traceability, language, structure, redundancy, cross-document alignment      | After spec + plan, before implementation |
| code          | Implementation Engineer | Constitution compliance, specification coverage, discrepancy detection, plan/tasks alignment | After implementation, before test review |
| test          | Implementation Engineer | Test pyramid health, unit test quality, high-value gaps, spec alignment, test refactoring    | After code review                        |

If the review type is not in this table, inform the user and list the supported types.

## Mandatory Context Gathering

For all review types:

1. Read the [constitution](../../../.specify/memory/constitution.md) — it has the highest authority.
2. Enumerate available artefacts in the `specs/` directory of the current feature.
3. Read the spec set in feature order: `spec.md` → `plan.md` → `tasks.md`.
4. Read any relevant ADRs in `docs/adr/`.

### Additional Context by Type

**documentation**: Also read `docs/` directory contents and `README.md` for cross-document alignment checks.

**code**: Build a behaviour inventory mapping constitution rules → spec requirements → implementation code → test coverage. Identify any gaps.

**test**: Execute `make test` and review the output. Analyse the test pyramid (unit, integration, end-to-end) and identify coverage gaps.

## Spec Kit Workflow Integration

This review is positioned within the spec-driven development pipeline:

- `speckit.specify` → `speckit.clarify` → `speckit.plan` → `speckit.tasks` → **review** → `speckit.implement`
- Documentation review should run before code review.
- Code review should run before test review.

## Operating Principles

1. Honour the constitution as the highest authority.
2. Base all findings on evidence from the codebase and spec artefacts.
3. Do not guess — use **Unknown from code — {action}** for missing information.
4. Keep recommendations specific, deterministic, minimal, and ready to implement.

## Objectives by Type

Each review type has a dedicated companion document with the full role, operating principles, objectives, Required Output Structure, Decision Checklist, rules, and Definition of Done. Follow the companion document for the review type being executed.

### Documentation Review

See [type-documentation.md](type-documentation.md) for the full workflow, including the seven-section objectives (Integrity & Traceability, Ubiquitous Language, Definition Ownership, Structural Consistency, Redundancy, Cross-Document Alignment, Completeness) and the seven-part Required Output Structure with the Decision Checklist.

Headline objectives:

1. **Integrity and Traceability**: Every spec requirement traces to a plan item and task via unique identifiers.
2. **Ubiquitous Language**: Consistent terminology across all documents.
3. **Definition Ownership**: Each concept has exactly one authoritative location.
4. **Structural Consistency**: Documents follow the expected spec-kit structure.
5. **Redundancy**: No duplicated requirements across documents.
6. **Cross-Document Alignment**: README, ADRs, and specs are mutually consistent.
7. **Completeness**: Mandatory ADRs and LikeC4 diagrams exist; data flow diagrams where material.

### Code Review

See [type-code.md](type-code.md) for the full workflow, including the three objectives (Constitution Compliance, Specification Coverage, Discrepancy Detection), the six-part Required Output Structure (with Proposed Resolutions covering Options A/B/C), and the Decision Checklist.

Headline objectives:

1. **Constitution Compliance**: All code respects non-negotiable rules; severity `critical`/`major`/`minor`.
2. **Specification Coverage**: Every implemented behaviour is explicitly covered by the spec set.
3. **Discrepancy Detection**: Identify code without spec, spec without code, underspecified requirements, and plan/tasks drift.
4. **Plan/Tasks Alignment**: Implementation matches the planned approach.

### Test Review

See [type-test.md](type-test.md) for the full workflow, including the five objectives, the **Test Quality Rules** (Behaviour and Scope, Structure and Style, Determinism and Isolation, Assertions, Errors and Edge Cases, Mocking and Fixtures, Maintainability), the eight-part Required Output Structure, and the Decision Checklist.

Headline objectives:

1. **Test Pyramid Health**: Appropriate distribution of unit, integration, and end-to-end tests.
2. **Unit Test Quality**: Tests are focused, deterministic, well-named, and tied to requirement identifiers.
3. **High-Value Gaps**: Missing happy paths, unhappy paths, edge cases, and branches.
4. **Spec Alignment**: Tests validate spec requirements (no orphan tests; no orphan behaviours).
5. **Test Refactoring**: Identify opportunities to improve clarity, determinism, and speed.

## Output Requirements

- Produce a structured report matching the review type's objectives.
- Use concrete evidence links for every finding.
- Reference constitution rules and spec requirements by identifier.
- Keep recommendations actionable — each should be implementable without further clarification.
- Prioritise findings by severity: blockers first, then warnings, then suggestions.
