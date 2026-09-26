# GitHub Copilot Instructions

This file is the authoritative instruction source for routine GitHub Copilot work in this repository. Use it as the operational default. Consult the [constitution](../.specify/memory/constitution.md) directly when a task affects specifications, behaviour, architecture, ADRs, or governance, or when guidance conflicts.

## Implementation discipline

- Do not invent requirements or widen scope.
- Keep outputs deterministic, make side effects explicit, and surface errors.
- If code and specification diverge, either fix the implementation or amend the specification with rationale.
- Order code to follow the primary execution or call flow when that improves readability, and group widely shared utilities clearly.
- When applying an update or observation to documentation or comments, fold it into the section that already owns that topic. Do not append a parallel section that restates context the reader must reconcile; prefer editing one authoritative place over layering.
- Do not `git add`/stage changes unless explicitly asked to.
- Leave the working tree and the index (staged changes) exactly as they were before the prompt started, except for the changes the prompt actually asked for. Do not stage, unstage, or otherwise touch files unrelated to the request.

## Test-driven development

- For behavioural changes, follow `Red -> Green -> Refactor`.
- Use property-based testing where it adds value.

## Skill invocation gates

- Use the `test-driven-development` skill only when the task requires a new failing test that should drive a code or behaviour change.
- On unexpected test, build, or runtime failures, load the `systematic-debugging` skill.
- Before completion, load the `verification-before-completion` skill.

## Workflow mode

- Resolve the active workflow mode with `make workflow-status` before invoking lifecycle skills.
- If the mode is `speckit`, use only the `speckit-*` lifecycle skills for that session or worktree.
- If the mode is `superpowers`, use only the imported Superpowers workflow skills for that session or worktree.
- Do not mix the Speckit and Superpowers lifecycle commands in the same session or worktree.
- Switch explicitly with `make workflow-use mode=speckit` or `make workflow-use mode=superpowers`, then start a fresh chat session.

## Repository verification policy

The Stop hook is the canonical enforcement for local quality gates.
When that hook is active, do not rerun the same commands manually unless diagnosing a failure or the hook is unavailable.

## Communication style

- Use British English.
- Keep language simple, direct, and active.
- Do not use em dashes or semicolons in prose.
- Write short sentences and prefer intention-revealing wording.

## Documentation ADRs

Record significant technical decisions in [docs/adr](../docs/adr). Consult the [Tech Radar](../docs/adr/Tech_Radar.md) first and follow the existing ADR format.

## Toolchain version

Use the latest stable language, runtime, and framework versions unless the task must stay within an established project constraint.

## Repository tooling

Use the [repository-template skill](skills/repository-template/SKILL.md) when adopting missing repository capabilities such as linting, CI/CD, Docker support, or hooks.
