# Example 01 - Code review after implementing a feature spec

## Scenario metadata

- **Skill**: code-review
- **Scenario**: Run a code-type review on a freshly implemented feature to assess constitution compliance, specification coverage, and plan/tasks alignment.
- **Repository context**: A spec-kit feature folder `specs/004-create-order/` exists with `spec.md`, `plan.md`, and `tasks.md`; the feature has just been implemented under `src/app/api/v1/routes/orders.py` and `src/app/services/orders.py`.
- **User goal**: Find any compliance or coverage gaps before moving on to the test review.
- **Invocation**: `Run the code-review skill with type code for feature 004-create-order`

## User prompt

> Please run a `code` review on the `004-create-order` feature. Use the spec, plan, and tasks under `specs/004-create-order/` and produce the full report.

## Argument and intent resolution

- `$ARGUMENTS` resolves to `code`, so the skill takes the Implementation Engineer role.
- Pipeline position confirmed: this run comes after `speckit-implement` and before the `test` review.
- Documentation review for this feature has already been completed (assumed clean).

## Context gathering

- Read `.specify/memory/constitution.md` - highest authority.
- Enumerated `specs/004-create-order/`: `spec.md`, `plan.md`, `tasks.md`, plus `contracts/orders.openapi.yaml`.
- Read `spec.md` → `plan.md` → `tasks.md` in order to build the behaviour inventory.
- Read relevant ADRs: `docs/adr/ADR-001a_Python_Dependency_Management.md`, `ADR-001d_Python_Testing_Tooling.md`.
- Built a behaviour matrix mapping constitution rules → spec requirements (`REQ-001..REQ-007`) → implementation files → existing tests.

## Execution

1. **Constitution compliance pass** - checked TDD discipline, ADR coverage for the new outbound payment client, and the mandatory quality-gate sequence. Severity assigned per rule.
2. **Specification coverage pass** - traced every `REQ-NNN` in `spec.md` to one or more functions or routes; flagged requirements without a corresponding implementation site.
3. **Discrepancy detection** - inverted the trace to find implementation behaviours absent from the spec (e.g. an idempotency header handled in code but never specified).
4. **Plan/tasks alignment** - compared `plan.md` decisions against the actual import graph and module boundaries; checked that every task in `tasks.md` has a Red → Green → Refactor footprint in git history.
5. **Authored the structured report** following the six-part output in `type-code.md`, including Proposed Resolutions A/B/C for each material finding.

## Output artefacts

- `specs/004-create-order/reviews/code-review-report.md` - the structured report containing:
  - Executive summary with finding counts by severity.
  - Constitution compliance section (one `critical`, two `minor` findings).
  - Specification coverage matrix (`REQ-006` partially implemented).
  - Discrepancy register (idempotency handling needs a spec amendment).
  - Plan/tasks alignment notes.
  - Proposed Resolutions with Options A/B/C and a Decision Checklist.

## Validation evidence

- Every finding cites a concrete file and line range (`src/app/services/orders.py#L42-L58`).
- Constitution rules referenced by stable identifier (e.g. `CONST-TDD-01`).
- Spec requirements referenced by `REQ-NNN`.
- No `Unknown from code` items remain - three were initially recorded and resolved by re-reading `contracts/orders.openapi.yaml`.
- `make lint` re-run on the report file to confirm markdownlint cleanliness.

## Final assistant response

> Code review complete. Report written to `specs/004-create-order/reviews/code-review-report.md`. One `critical` finding (missing idempotency requirement in spec), two `minor` findings (logging field naming and a missing timeout on the payment client). `REQ-006` is partially implemented and needs either a code addition or a spec narrowing - Decision Checklist provided. Ready for the `test` review next.

## Notes and follow-ups

- The `test` review should be run next to assess pyramid health and unit-test quality for the new modules.
- The idempotency finding requires a spec amendment via `speckit-specify`; do not silently patch the code.
- Re-run this skill after addressing the `critical` finding to confirm closure before merging.
