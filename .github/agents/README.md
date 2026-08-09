# Agents 🤖

Auto-generated index of custom agents in this directory. Each `.agent.md` defines a persistent persona with optional `tools`, `model`, and `handoffs`. See [VS Code custom agents docs](https://code.visualstudio.com/docs/copilot/customization/custom-agents).

> **Note:** `.chatmode.md` is the legacy extension; this repository uses `.agent.md` per the VS Code April 2026 release.
> **Do not edit by hand.** Regenerate with `make catalogue`.

## Catalogue

### `personas/`

| File                                                                   | Description                                                                                     | Handoffs                     |
| ---------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- | ---------------------------- |
| [personas/implementer.agent.md](personas/implementer.agent.md)         | Execute an approved plan, make the necessary code changes, and run the project's quality gates  | reviewer                     |
| [personas/planner.agent.md](personas/planner.agent.md)                 | Turn a user goal into an actionable execution plan with acceptance criteria and a risk list     | implementer                  |
| [personas/release-manager.agent.md](personas/release-manager.agent.md) | Final readiness check, changelog draft, and rollout/rollback notes before human approval        | implementer                  |
| [personas/reviewer.agent.md](personas/reviewer.agent.md)               | Perform a strict code review with a bugs/regressions/tests-first mindset and enforce governance | implementer, release-manager |

`Handoffs` column lists the `agent:` field of each entry in the file's `handoffs:` block, comma-separated. Show `-` if no handoffs declared.
