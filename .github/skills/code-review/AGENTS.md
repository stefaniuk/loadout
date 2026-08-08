# Skill-Local Agent Instructions: Code Review

> **Scope.** This file applies only to the `code-review` skill subtree. The canonical baseline is the [root AGENTS.md](../../../AGENTS.md); nothing here may contradict it.

## Inheritance and precedence

- Inherit all rules from [root AGENTS.md](../../../AGENTS.md) and [.github/copilot-instructions.md](../../copilot-instructions.md).
- When a conflict exists within this skill's subtree, the closest file applies; otherwise root rules win.
- For the full task workflow, read [SKILL.md](SKILL.md). This file captures only behavioural constraints, not the workflow itself.

## Skill-local rules

- **Single-mode routing.** Each invocation runs exactly one review type (`documentation`, `code`, or `test`). Do not bundle modes in a single run; if the user wants more than one, run them sequentially in the prescribed order.
- **Constitution first.** Read [`.specify/memory/constitution.md`](../../../.specify/memory/constitution.md) before the spec artefacts so findings resolve against the highest-authority rules from the start.
- **Mandatory context order.** Read spec artefacts in feature order: `spec.md` → `plan.md` → `tasks.md` → implementation (and tests for the `test` mode). Skipping or reordering this sequence is not permitted.
- **Pipeline position.** Treat `documentation` as a pre-implementation review and `code` and `test` as post-implementation reviews. When the user wants more than one pass, keep the order `documentation` → `code` → `test`.
- **Evidence-first findings.** Every finding must cite the offending `path/to/file#L10-L40` plus the constitution rule or spec/requirement identifier it violates. Speculative or stylistic comments unsupported by evidence are out of scope.
- **Mark unknowns explicitly.** Use `Unknown from code - {suggested action}` for missing information rather than guessing.
- **Severity discipline.** Prioritise output as blockers → warnings → suggestions; each item must be specific, deterministic, and ready to implement without further clarification.

## Deviations from root AGENTS.md

None.

## References

- [SKILL.md](SKILL.md) - the skill's task workflow and per-type companion documents.
- [root AGENTS.md](../../../AGENTS.md) - canonical baseline.
