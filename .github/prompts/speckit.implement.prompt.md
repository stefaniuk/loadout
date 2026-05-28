---
agent: speckit.implement
---

You **MUST** adhere to the following mandatory requirements when implementing features.

**Workflow context:**

- **Input:** `tasks.md` (actionable task list)
- **Output:** Working code with passing tests
- **Verification:** Execute Show & Tell steps after each phase

**Base requirements:** Follow all rules in [copilot-instructions.md](/.github/copilot-instructions.md), particularly:

- Repository Tooling
- Test-Driven Development
- Repository verification policy

## Implementation Process (Mandatory)

1. Work through tasks in `tasks.md` sequentially
2. Follow TDD: write failing test first, then implement, then refactor
3. After completing each phase or user story, execute its `Show & Tell` steps to verify correctness
4. Respect the repository's canonical local quality-gate policy after every source code change; where hooks enforce the gates automatically, do not duplicate the same gate commands manually unless diagnosing a failure

## Implementation Completion Checklist (Mandatory)

Before marking implementation as complete, verify:

- [ ] All tasks in `tasks.md` are completed
- [ ] Each repository-template capability that was planned to be implemented using the skill at [.github/skills/repository-template/SKILL.md](/.github/skills/repository-template/SKILL.md) is completed
- [ ] TDD was followed: tests written before implementation
- [ ] All `Show & Tell` steps executed successfully for each phase
- [ ] Repository-template capabilities are present and up to date (see [.github/skills/repository-template/SKILL.md](/.github/skills/repository-template/SKILL.md))
- [ ] The repository's canonical local quality gates pass with zero errors and zero warnings

---

> **Version**: 1.6.1
> **Last Amended**: 2026-05-17
