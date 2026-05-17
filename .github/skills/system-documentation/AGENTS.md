# Skill-Local Agent Instructions: System Documentation

> **Scope.** This file applies only to the `system-documentation` skill
> subtree. The canonical baseline is the
> [root AGENTS.md](../../../AGENTS.md); nothing here may contradict it.

## Inheritance and precedence

- Inherit all rules from [root AGENTS.md](../../../AGENTS.md) and
  [.github/copilot-instructions.md](../../copilot-instructions.md).
- When a conflict exists within this skill's subtree, the closest file
  applies; otherwise root rules win.
- For the full task workflow, read [SKILL.md](SKILL.md). This file captures
  only behavioural constraints, not the workflow itself.

## Skill-local rules

- **Strict step model.** Run only the requested step or the dependency-ordered
  sequence resolved by [SKILL.md](SKILL.md). Do not invent parallel stages.
- **Mode-sensitive dependencies.** In `establish` and `sync`, missing
  prerequisite outputs block the selected step. In `audit` and
  `pre-pr-review`, the same gaps are findings, not blockers.
- **Canonical location per fact.** Foundation docs remain entrypoints,
  architecture docs remain current-state and ADR-oriented, reference docs stay
  factual, explanation docs stay conceptual, how-to docs stay task-oriented,
  tutorials stay learning-oriented, operations docs stay safety-oriented,
  audience indexes stay link routers, and governance/lifecycle artefacts
  (`CHANGELOG.md`, `.github/SECURITY.md`, `.github/contributing.md`,
  `.github/CODE_OF_CONDUCT.md`, upgrade guides) stay policy- and
  change-oriented.
- **Evidence first.** Prefer current code, configuration, contracts, scripts,
  prompts, skills, agents, hooks, and tests over stale Markdown when sources
  disagree.
- **No normative docs in reports.** `docs/prompt-reports/` stores evidence,
  research, and reports only. Do not move canonical repo guidance there.
- **No task-derived authority.** `tasks.md` is never a canonical source.
  Inspect `plan.md` only narrowly when technical context cannot be recovered
  from code, ADRs, specs, or current docs.
- **Generated files stay generated.** When prompts, skills, agents, or folder
  indexes change, regenerate them with `make catalogue` instead of editing
  generated outputs by hand.
- **Audience pages are not shadow copies.** `docs/developers/README.md` and
  `docs/users/README.md` must link to canonical docs rather than restating
  them.
- **Findings-first reviews.** In `audit` and `pre-pr-review`, report findings
  before summaries and group them as missing, misplaced, duplicated,
  conflicting, or stale documentation.
- **British English, ASCII-only.**

## Deviations from root AGENTS.md

None.

## References

- [SKILL.md](SKILL.md) — the skill workflow.
- [root AGENTS.md](../../../AGENTS.md) — canonical baseline.
- [constitution](../../../.specify/memory/constitution.md) — highest
  authority.
