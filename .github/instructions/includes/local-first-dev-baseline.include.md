# Local-first Developer Experience Baseline ⚡

Use this shared baseline for local-first developer experience expectations. Domain-specific instruction sets should reference this and add tooling-specific details.

**Identifier scheme.** Every normative rule carries a unique tag in the form `[LCL-BASE-<prefix>-NNN]`, where the prefix maps to the containing section (for example `WF` for Workflow, `OCI` for Containers, `PRC` for Pre-commit). Use these identifiers when referencing, planning, or validating requirements.

---

## 1. Workflow and safety 🔐

- [LCL-BASE-WF-001] Provide a single-command workflow for core tasks (deps, format, lint, typecheck/validate, test, run).
- [LCL-BASE-WF-002] If `make` is not used, provide an equivalent task runner with the same intent and predictable names.
- [LCL-BASE-WF-003] Keep local defaults safe: no real cloud credentials or destructive operations by default.
- [LCL-BASE-WF-004] Source each repository `.gitignore` from the matching templates in <https://github.com/github/gitignore>, merge only the relevant sections, and document any local additions in the spec set.

## 2. Pre-commit and fast feedback ⚡

- [LCL-BASE-PRC-001] Pre-commit hooks (or equivalent) must mirror CI checks and stay fast; heavy checks belong in CI.

## 3. OCI / Dev Container parity 🐳

- [LCL-BASE-OCI-001] OCI/Dev Container support is optional but must be maintained if provided.
- [LCL-BASE-OCI-002] Never bake secrets into images.
- [LCL-BASE-OCI-003] The same core commands must work inside and outside the container.

## 4. Environment checks 🩺

- [LCL-BASE-ENV-001] Where supported, provide a single "doctor" or environment-check command that surfaces actionable fixes.
