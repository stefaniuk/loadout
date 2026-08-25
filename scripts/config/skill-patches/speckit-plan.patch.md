## Workflow Mode Guard

Use this skill only when the active local workflow mode is `speckit`.

Before proceeding:

- Run `./scripts/hooks/workflow-mode.sh status`.
- If the active mode is `superpowers`, stop and tell the user to switch with `make workflow-use mode=speckit` or continue with the Superpowers workflow instead.
- Do not mix `speckit-*` commands with Superpowers workflow skills in the same session or worktree.

You **MUST** adhere to the following mandatory requirements when creating a development plan.

**Workflow context:**

- **Input:** `spec.md` (feature specification)
- **Output:** `plan.md` (implementation plan)
- **Next phase:** Tasks generation (`/speckit-tasks`)

**Base requirements:** Follow all rules in [copilot-instructions.md](/.github/copilot-instructions.md), particularly:

- Documentation ADRs
- Toolchain version
- Repository tooling

## Show & Tell Sections (Mandatory)

Each phase and user story in `plan.md` must include a `Show & Tell` subsection. This subsection defines the demonstration steps that will be:

1. Expanded with specific commands in `tasks.md` (next phase)
2. Executed by the user during implementation to verify completion

### AI Assistant Execution Requirement (Mandatory)

Show & Tell steps must be written so AI Assistant can execute and validate them without guessing.

- Use explicit, runnable commands, URLs, and API calls
- Include an expected result for every step (output text, status code, or visible UI state)
- Avoid vague language such as "check it works" or "verify manually"
- State pass/fail criteria clearly so steps cannot be skipped or missed during `/speckit-implement`
- For infrastructure, scripts, documentation, or reporting tools, prefer lightweight checks such as file presence, command exit status, or output schema/keys instead of app-style browser flows

During implementation, execute every Show & Tell step and confirm the expected result before marking the phase or user story complete.

- If a step fails because the implementation is wrong, fix it and re-run the step
- If a step fails because the environment is not ready, record the blocker, add the missing setup step, and re-run when the environment is ready

## Plan Completion Checklist (Mandatory)

Before marking `plan.md` as complete, verify:

- [ ] Plan addresses all requirements from `spec.md`
- [ ] All architectural decisions have corresponding ADRs
- [ ] Toolchain versions are specified, verified online during planning, and confirmed as the latest stable releases
- [ ] If the feature introduces Make targets, CLI commands, containers, CI workflows, or managed tools, relevant repository-template capabilities are planned using the skill at [.github/skills/repository-template/SKILL.md](/.github/skills/repository-template/SKILL.md)
- [ ] If no repository-template capabilities apply, `plan.md` states `Not required for this scope`
- [ ] Each phase and user story includes a `Show & Tell` subsection
- [ ] Show & Tell subsections are placed at the end of each phase or user story
- [ ] Show & Tell steps are specific enough for AI Assistant to execute and validate without ambiguity
