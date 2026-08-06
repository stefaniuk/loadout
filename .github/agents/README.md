# Agents 🤖

Auto-generated index of custom agents in this directory. Each `.agent.md` defines a persistent persona with optional `tools`, `model`, and `handoffs`. See [VS Code custom agents docs](https://code.visualstudio.com/docs/copilot/customization/custom-agents).

> **Note:** `.chatmode.md` is the legacy extension; this repository uses `.agent.md` per the VS Code April 2026 release.
> **Do not edit by hand.** Regenerate with `make catalogue`.

## Catalogue

### Top-level

| File                                                             | Description                                                                                                                                  | Handoffs                           |
| ---------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------- |
| [speckit.analyze.agent.md](speckit.analyze.agent.md)             | Perform a non-destructive cross-artifact consistency and quality analysis across spec.md, plan.md, and tasks.md after task generation        | -                                  |
| [speckit.checklist.agent.md](speckit.checklist.agent.md)         | Generate a custom checklist for the current feature based on user requirements                                                               | -                                  |
| [speckit.clarify.agent.md](speckit.clarify.agent.md)             | Identify underspecified areas in the current feature spec by asking up to 5 highly targeted clarification questions and encoding answers bac | speckit.plan                       |
| [speckit.constitution.agent.md](speckit.constitution.agent.md)   | Create or update the project constitution from interactive or provided principle inputs                                                      | speckit.specify                    |
| [speckit.converge.agent.md](speckit.converge.agent.md)           | Assess the current codebase against the feature's spec, plan, and tasks, then append any remaining unbuilt work as new tasks to tasks.md so  | -                                  |
| [speckit.implement.agent.md](speckit.implement.agent.md)         | Execute the implementation plan by processing and executing all tasks defined in tasks.md                                                    | -                                  |
| [speckit.plan.agent.md](speckit.plan.agent.md)                   | Execute the implementation planning workflow using the plan template to generate design artifacts                                            | speckit.tasks, speckit.checklist   |
| [speckit.specify.agent.md](speckit.specify.agent.md)             | Create or update the feature specification from a natural language feature description                                                       | speckit.plan, speckit.clarify      |
| [speckit.tasks.agent.md](speckit.tasks.agent.md)                 | Generate an actionable, dependency-ordered tasks.md for the feature based on available design artifacts                                      | speckit.analyze, speckit.implement |
| [speckit.taskstoissues.agent.md](speckit.taskstoissues.agent.md) | Convert existing tasks into actionable, dependency-ordered GitHub issues for the feature based on available design artifacts                 | -                                  |

### `personas/`

| File                                                                   | Description                                                                                     | Handoffs                     |
| ---------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- | ---------------------------- |
| [personas/implementer.agent.md](personas/implementer.agent.md)         | Execute an approved plan, make the necessary code changes, and run the project's quality gates  | reviewer                     |
| [personas/planner.agent.md](personas/planner.agent.md)                 | Turn a user goal into an actionable execution plan with acceptance criteria and a risk list     | implementer                  |
| [personas/release-manager.agent.md](personas/release-manager.agent.md) | Final readiness check, changelog draft, and rollout/rollback notes before human approval        | implementer                  |
| [personas/reviewer.agent.md](personas/reviewer.agent.md)               | Perform a strict code review with a bugs/regressions/tests-first mindset and enforce governance | implementer, release-manager |

`Handoffs` column lists the `agent:` field of each entry in the file's `handoffs:` block, comma-separated. Show `-` if no handoffs declared.
