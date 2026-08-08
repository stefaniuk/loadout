# Skill-Local Agent Instructions: Enforcement Audit

> **Scope.** This file applies only to the `enforcement-audit` skill subtree. The canonical baseline is [.github/copilot-instructions.md](../../copilot-instructions.md); nothing here may contradict it.

## Inheritance and precedence

- Inherit all rules from [.github/copilot-instructions.md](../../copilot-instructions.md).
- When a conflict exists within this skill's subtree, the closest file applies; otherwise repository-wide Copilot rules win.
- For the full task workflow, read [SKILL.md](SKILL.md). This file captures only behavioural constraints, not the workflow itself.

## Skill-local rules

- **No skipped steps.** The audit sequence (Discovery → Artefact Matrix → Discrepancy Detection → Plan → Implement → Validate → Summarise) is fixed. Execute every step, even when the code appears compliant; partial execution is not permitted.
- **Authoritative rule source.** The `<tech>.instructions.md` file resolved from the technology table in [SKILL.md](SKILL.md) is the sole source of compliance rules for that audit. Do not invent rules or import rules from other technologies.
- **Constitution first.** Re-read [`.specify/memory/constitution.md`](../../../.specify/memory/constitution.md) before applying the technology-specific rules so findings resolve against the highest-authority constraints from the start.
- **Evidence requirement.** Every finding must cite the rule identifier (e.g. `[GO-LINT-001]`) plus a concrete `path/to/file#L10-L40` reference. Findings without both are not acceptable.
- **Cumulative artefacts.** On re-runs, parse the existing inventory and alignment plan paths from the table and extend them; do not regenerate from scratch or duplicate entries.
- **Output contract.** Produce a structured remediation list per finding capturing severity, file, line range, rule identifier, and proposed fix; group fixes into workstreams with explicit order of execution.
- **Quality-gate compliance.** Each implementation batch must satisfy the repository quality gates before the next batch or final summary. When hooks or other automation already enforce those gates, rely on that enforcement rather than rerunning the same commands blindly.
- **Mark unknowns explicitly.** Record `Unknown from code - verify {topic} with maintainers` rather than assuming; unresolved unknowns must be tracked as explicit follow-ups in the plan file.

## Deviations from repository-wide Copilot instructions

None.

## References

- [SKILL.md](SKILL.md) - the skill's task workflow and technology resolution table.
- [.github/copilot-instructions.md](../../copilot-instructions.md) - canonical baseline.
