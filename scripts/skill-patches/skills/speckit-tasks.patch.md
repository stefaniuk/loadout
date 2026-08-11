## Workflow Mode Guard

Use this skill only when the active local workflow mode is `speckit`.

Before proceeding:

- Run `./scripts/hooks/workflow-mode.sh status`.
- If the active mode is `superpowers`, stop and tell the user to switch with `make workflow-use mode=speckit` or continue with the Superpowers workflow instead.
- Do not mix `speckit-*` commands with Superpowers workflow skills in the same session or worktree.

You **MUST** adhere to the following mandatory requirements when generating development tasks.

**Workflow context:**

- **Input:** `plan.md` (implementation plan)
- **Output:** `tasks.md` (actionable task list)
- **Next phase:** Implementation (`/speckit-implement`)

**Base requirements:** Follow all rules in [copilot-instructions.md](/.github/copilot-instructions.md), particularly:

- Repository Tooling
- Test-Driven Development
- Repository verification policy

## Show & Tell Sections (Mandatory)

Each phase and user story in `tasks.md` must include a `Show & Tell` subsection. Expand the outline from `plan.md` with specific executable steps:

- Terminal commands to run (with expected output)
- Browser URLs to navigate (if applicable)
- API calls to execute (if applicable)
- Screenshots or expected visual state (described)

These steps will be executed during implementation to verify each phase is complete.

### AI Assistant Execution Requirement (Mandatory)

AI Assistant **MUST** execute every Show & Tell step during `/speckit-implement` and validate that the expected result is achieved.

- Do not allow placeholder or ambiguous steps
- Every step must include explicit pass/fail criteria
- If a step fails, update tasks and/or implementation, then re-run the step
- Do not mark a phase or user story complete until all Show & Tell steps pass

This requirement is non-optional and must not be skipped or missed.

**Format example:**

````markdown
### Show & Tell

```bash
# Start the development server
make run

# Expected: Server running at http://localhost:3000
```

- Navigate to <http://localhost:3000/dashboard>
- Verify the analytics widget displays sample data
````
