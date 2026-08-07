# Quality Gates Baseline ✅

Use this shared baseline for quality gate execution expectations. Domain-specific instruction sets should list their canonical commands and reference these rules for how to run them.

**Identifier scheme.** Every normative rule carries a unique tag in the form `[QG-BASE-<prefix>-NNN]`, where the prefix maps to the containing section (for example `RUN` for Running, `DEF` for Defects, `SRC` for Sources). Use these identifiers when referencing, planning, or validating requirements.

---

## 1. Running rules 🏃

- [QG-BASE-RUN-001] Use repository-provided targets or scripts; avoid ad-hoc commands unless the spec requires it.
- [QG-BASE-RUN-002] If canonical targets do not exist, discover and run the project-approved equivalents.

## 2. Defect handling 🐛

- [QG-BASE-DEF-001] Iterate until all checks complete with **no errors or warnings**.
- [QG-BASE-DEF-002] Treat warnings as defects unless explicitly waived in an ADR (with rationale and expiry).

## 3. Mechanism selection 🎯

When a specification or architecture decision imposes a constraint (e.g. "package X must not import package Y", "banned dependency Z"), choose the lightest enforcement mechanism that provides full confidence:

- [QG-BASE-MECH-001] **Linter configuration first.** If the constraint can be expressed as a linter rule (import restrictions, module bans, naming conventions), implement it as linter config. Linter rules run automatically on every `make lint`, produce clear error messages, and need no custom test maintenance.
- [QG-BASE-MECH-002] **Architecture tests second.** Use custom test code (AST scanning, dependency graph analysis) only for constraints that linter rules cannot express: call-order verification, banned function-call patterns within a package, interface signature checks, or cross-file structural invariants.
- [QG-BASE-MECH-003] **Integration/behavioural tests for product behaviour.** Use integration tests for constraints that require running the compiled artefact: CLI exit codes, output formats, error recovery, performance thresholds.
- [QG-BASE-MECH-004] **Do not double up.** If a constraint is enforced by linter config, do not also write a Go test for the same constraint. One mechanism per constraint.
