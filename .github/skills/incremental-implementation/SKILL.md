---
name: incremental-implementation
description: Delivers changes incrementally. Use when implementing any feature or change that touches more than one file. Use when you're about to write a large amount of code at once, or when a task feels too big to land in one step.
---

# Incremental Implementation

## Overview

Build in thin vertical slices. The slice should come from the controlling
artefact that already exists in the repository.

- In Spec Kit repositories, the controlling artefact is the existing
  `tasks.md` for the active feature.
- In repositories without a task list, define the smallest working slice
  yourself and keep it narrow.

This skill is execution discipline. It is not a second planning system.

## When to Use

- Implementing a multi-file change
- Executing an existing task list or feature plan
- Refactoring or delivery work that should stay deployable between steps
- Any time you are tempted to write more than about 100 lines before a focused
  check

**When NOT to use:** single-file, single-function changes where the scope is
already minimal.

## Operating Modes

### Spec Kit Mode

Use this mode when the repository has a `.specify/` directory or the active
feature already has `spec.md`, `plan.md`, and `tasks.md`.

In this mode:

- `tasks.md` is the sole source of work for implementation.
- Do not create another plan, rewrite the task graph, or invent a competing
  slice map.
- Choose the next increment from the existing phase order, dependency order,
  `[P]` markers, and `Show & Tell` checkpoints.
- Treat one increment as the smallest runnable subset of the existing tasks,
  usually one failing test to green, one dependency chain inside a phase, or
  one story checkpoint.
- If work is missing, route it back to the planning workflow. In Spec Kit
  repositories that usually means `/speckit-converge` or an explicit
  `tasks.md` update, not ad hoc scope growth during implementation.

### Standalone Mode

If no structured task list exists, define the smallest complete slice yourself.
Use the same discipline:

- pick one vertical path
- validate it immediately
- keep the system working between slices
- expand only after the current slice is green

## The Increment Cycle

1. Choose the next smallest slice from the current task list or work queue.
2. Implement only that slice.
3. Run the narrowest test or behaviour check that proves the slice.
4. Run the repository verification commands that could have been affected.
5. Update the controlling artefact:
   - mark completed tasks or checkpoints
   - record follow-up gaps instead of silently expanding scope
6. Record progress using the repository's workflow. Commit only when the user,
   repository policy, or an explicit hook asks for it.

## Slicing Strategies

### Task-First Slices for Spec Kit

Prefer one of these boundaries:

- one test task plus the minimal implementation task it unlocks
- one sequential dependency chain inside a single phase
- one `Show & Tell` checkpoint for a story or phase
- one high-risk technical proof before broader rollout

Do not combine multiple stories or phases just because they touch similar
files.

### Vertical Slices for Standalone Work

Build one complete path through the stack:

```text
Slice 1: Create the minimal end-to-end path
    -> Tests pass and a user can complete the core action

Slice 2: Add the next behaviour on the same path
    -> Tests pass and the second action works without regressions

Slice 3: Add the next dependent behaviour
    -> The system still works between slices
```

### Contract-First Slices

When two parts of the system must align, land the contract first:

```text
Slice 0: Define the contract
Slice 1: Implement one side against the contract
Slice 2: Implement the other side and verify integration
```

### Risk-First Slices

Tackle the riskiest or most uncertain piece first:

```text
Slice 1: Prove the uncertain integration works
Slice 2: Build the first user-facing behaviour on the proven path
Slice 3: Expand only after the risk is retired
```

## Implementation Rules

### Rule 0: Simplicity First

Before writing code, ask: "What is the simplest thing that could work?"

After writing code, review it against these checks:

- Can this be done in fewer lines?
- Are these abstractions earning their complexity?
- Am I building for the current task or a hypothetical future?

Three similar lines of code are usually better than a premature abstraction.
Implement the naive, obviously correct version first. Optimise only after
correctness is proven with tests.

### Rule 0.5: Scope Discipline

Touch only what the current slice requires.

Do not:

- clean up adjacent code unless the current slice needs it
- add features because they seem useful
- rewrite task boundaries because a different plan feels nicer
- widen the change because you are already in the file

If you discover missing work outside the current slice, note it and route it
back into the repository's task system.

### Rule 1: One Logical Change at a Time

Each increment should change one logical thing. Do not mix a feature slice, a
refactor, and build-system churn into the same step.

### Rule 2: Keep It Runnable

After each increment, the project must still build and the relevant tests must
still pass. Do not leave the codebase broken between slices.

### Rule 3: Honour the Controlling Artefact

If the repository already has a plan or task list, follow it. Do not create a
second source of truth in chat, notes, or ad hoc TODOs.

### Rule 4: Safe Defaults and Feature Flags

If a feature is not ready for users but the workflow needs partial delivery,
hide incomplete behaviour behind a safe default or feature flag.

### Rule 5: Rollback-Friendly Changes

Each increment should be easy to revert:

- prefer additive changes where possible
- keep modifications to existing code focused
- separate destructive replacements from new additions

### Rule 6: Commit Only When Appropriate

Do not assume every slice should create a commit. Some repositories use hooks,
manual checkpoints, stacked diffs, or a human-controlled commit step. If the
workflow does require commits, keep them aligned to a completed slice.

## Working with Agents

When directing an agent in a Spec Kit repository:

```text
Implement Phase 3, User Story 1, starting with tasks T010 to T012 only.

Keep tasks.md as the source of truth.
If a required step is missing from the task list, stop and surface the gap
instead of inventing a new plan.

After the slice, run the repository checks that cover the touched files and
execute the relevant Show & Tell steps.
```

When directing an agent outside Spec Kit:

```text
Start with just the schema change and the API endpoint.
Do not touch the UI yet.

After implementing, run the repository's relevant test and build commands to
verify nothing is broken.
```

Be explicit about what is in scope and what is not.

## Increment Checklist

After each increment, verify with the repository's own commands:

- [ ] The change does one thing and does it completely
- [ ] Existing task, phase, and dependency boundaries were respected
- [ ] The narrowest relevant test or behaviour check passed
- [ ] Build, type-check, and lint steps were run where the slice could affect them
- [ ] The new functionality works as expected
- [ ] Completed tasks or checkpoints were updated in the controlling artefact
- [ ] Relevant `Show & Tell` steps were executed for any completed Spec Kit checkpoint
- [ ] Progress was recorded in the repository's preferred mechanism
- [ ] A commit was made only if the workflow explicitly required one

Run each verification command after a change that could affect it. After a
successful run, do not repeat the same command unless the code has changed
since.

## Common Rationalizations

| Rationalization                                               | Reality                                                                                             |
| ------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| "I'll test it all at the end"                                 | Bugs compound. Test each slice.                                                                     |
| "I'll just make a better plan as I go"                        | If `tasks.md` already exists, changing the plan is a workflow decision, not implementation freedom. |
| "These two stories touch the same files, so I'll do both now" | Shared files do not make shared scope. Keep story and phase boundaries intact.                      |
| "I'll add these extra fixes while I'm here"                   | Unplanned work hides regressions and makes review harder. Capture it as follow-up work instead.     |
| "The skill says to commit every slice"                        | Commits are workflow-dependent. Follow the repository policy, not a blanket rule.                   |
| "Let me run the same check again just to be sure"             | Re-running unchanged checks adds no information. Run them again only after more edits.              |

## Red Flags

- Creating a second implementation plan when `tasks.md` already exists
- Marking tasks complete without running their proof step
- Parallelising tasks that share files or explicit dependencies
- Folding extra work into the current slice because you are already nearby
- Re-running the same check for reassurance instead of after a code change
- Large uncommitted or unreviewed changes accumulating because slices are not actually small

## Verification

After completing all increments for a task:

- [ ] Every completed slice was validated with the narrowest relevant check
- [ ] In Spec Kit mode, completed tasks are marked `[X]` and completed `Show & Tell` steps were executed
- [ ] Any discovered gaps were routed back into the repository task system instead of silently absorbed
- [ ] The repository quality gates pass
- [ ] The delivered behaviour matches the controlling spec or task list

## See Also

Per-increment verification is the local check. Before declaring a task done, apply the project-wide Definition of Done as the final gate, the standing bar every increment clears regardless of the task. See `../../references/definition-of-done.md`.
