## Workflow Mode Guard

Use this skill only when the active local workflow mode is `speckit`.

Before proceeding:

- Run `./scripts/hooks/workflow-mode.sh status`.
- If the active mode is `superpowers`, stop and tell the user to switch with `make workflow-use mode=speckit` or continue with the Superpowers workflow instead.
- Do not mix `speckit-*` commands with Superpowers workflow skills in the same session or worktree.

You **MUST** adhere to the following mandatory requirements when implementing features.

**Workflow context:**

- **Input:** `tasks.md` (actionable task list)
- **Output:** Working code with passing tests
- **Verification:** Execute Show & Tell steps after each phase

**Base requirements:** Follow all rules in [copilot-instructions.md](/.github/copilot-instructions.md), particularly:

- Repository tooling
- Test-driven development
- Repository verification policy

**Prerequisite:** This skill assumes `tasks.md` already exists. If `tasks.md` does not exist, stop and tell the user to run `/speckit-tasks` first.

## Scope Notes

- For infrastructure, scripts, documentation, or reporting tools, use lightweight validation that stays explicit and deterministic
- If project setup or ignore-file guidance does not apply to the feature scope, skip that work instead of inventing application-style setup tasks

## Implementation Process (Mandatory)

1. Work through tasks in `tasks.md` sequentially
2. For code tasks, follow TDD: write failing test first, then implement, then refactor
3. After completing each phase or user story, execute its `Show & Tell` steps to verify correctness
4. For infrastructure, scripts, documentation, or reporting tools, lightweight validation such as file presence, expected keys, or deterministic command output is sufficient
5. Respect the repository's canonical local quality-gate policy after every source code change; where hooks enforce the gates automatically, do not duplicate the same gate commands manually unless diagnosing a failure

## Implementation Completion Checklist (Mandatory)

Before marking implementation as complete, verify:

- [ ] All tasks in `tasks.md` are completed
- [ ] Any repository-template capabilities explicitly planned for this feature are completed
- [ ] If no repository-template capabilities were required, that decision is recorded in the plan or implementation notes
- [ ] TDD was followed for code tasks; documentation and tooling tasks passed focused quality checks
- [ ] All `Show & Tell` steps executed successfully for each phase
- [ ] The repository's canonical local quality gates pass with zero errors and zero warnings
