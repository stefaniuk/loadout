# Skill-Local Agent Instructions: Architecture Docs

> **Scope.** This file applies only to the `architecture-docs` skill subtree. The canonical baseline is [.github/copilot-instructions.md](../../copilot-instructions.md); nothing here may contradict it.

## Inheritance and precedence

- Inherit all rules from [.github/copilot-instructions.md](../../copilot-instructions.md).
- When a conflict exists within this skill's subtree, the closest file applies; otherwise repository-wide Copilot rules win.
- For the full task workflow, read [SKILL.md](SKILL.md). This file captures only behavioural constraints, not the workflow itself.

## Skill-local rules

- **Strict step sequencing.** The six steps (`repository-map` → `component-catalogue` → `runtime-flows` → `domain-analysis` → `c4-model` → `infrastructure-diagram`) must run in order. When a single step is requested, verify the dependency outputs from earlier steps already exist before starting.
- **Mandatory preparatory reads.** Before any step, read [`.github/instructions/includes/architecture-baseline.include.md`](../../instructions/includes/architecture-baseline.include.md). Additionally, before step 05 (`c4-model`), read [`.github/instructions/likec4.instructions.md`](../../instructions/likec4.instructions.md).
- **Cumulative context.** At the start of each step, read the outputs of all prior steps (if present) so analysis is additive rather than restarted.
- **Evidence-first authoring.** Every claim must cite a concrete repository path (with line range where applicable) or an external source. Never guess.
- **Mark unknowns explicitly.** When information cannot be determined from the codebase, record `Unknown from code - {suggested action}` rather than inferring.
- **Update the index on every step.** After producing any artefact, update `.copilot/analysis/README.md` so the catalogue stays in sync before handing off.

## Deviations from repository-wide Copilot instructions

None.

## References

- [SKILL.md](SKILL.md) - the skill's task workflow.
- [.github/copilot-instructions.md](../../copilot-instructions.md) - canonical baseline.
