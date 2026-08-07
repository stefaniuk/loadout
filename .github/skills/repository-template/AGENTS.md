# Skill-Local Agent Instructions: Repository Template

> **Scope.** This file applies only to the `repository-template` skill subtree. The canonical baseline is the [root AGENTS.md](../../../AGENTS.md); nothing here may contradict it.

## Inheritance and precedence

- Inherit all rules from [root AGENTS.md](../../../AGENTS.md) and [.github/copilot-instructions.md](../../copilot-instructions.md).
- When a conflict exists within this skill's subtree, the closest file applies; otherwise root rules win.
- For the full task workflow, read [SKILL.md](SKILL.md). This file captures only behavioural constraints, not the workflow itself.

## Skill-local rules

- **Distribution mirroring.** The [`assets/`](assets/) tree is a downstream-shaped scaffold and must mirror the destination repository layout exactly. Do not introduce files under `assets/` that would not belong in a target repository.
- **Triple-home parity.** This skill is mirrored verbatim across the prompt catalogue, the upstream [`stefaniuk/repository-template`](https://github.com/stefaniuk/repository-template), and every repository generated from it. Edit wording in one place only if it remains valid in all three; otherwise leave it untouched.
- **Context detection before copying.** Always detect the active context (git remote, presence/emptiness of `assets/`, presence of root `Makefile`/`scripts/`) before suggesting file moves; never overwrite an existing destination file without explicit user consent.
- **`scripts/init.mk` is indivisible.** Never partially copy `scripts/init.mk`; always copy the complete file and ensure the destination `Makefile` contains `include scripts/init.mk` near the top.
- **Wire `config::` for asdf-managed tools.** When adopting a capability that pulls a tool via `.tool-versions`, ensure the destination `Makefile` has a `config::` target invoking `$(MAKE) _install-dependencies`.
- **Verify after adoption.** After any `make apply` (or manual copy), instruct the user to run `make lint && make test` in the destination and to execute the capability-specific verification commands documented in [SKILL.md](SKILL.md).
- **Identifier discipline.** When introducing rule blocks inside this skill, use the `[REPO-TEMPLATE-<area>-NNN]` tag scheme so downstream audits can cite them.

## Deviations from root AGENTS.md

None.

## References

- [SKILL.md](SKILL.md) - the skill's task workflow and capability catalogue.
- [root AGENTS.md](../../../AGENTS.md) - canonical baseline.
