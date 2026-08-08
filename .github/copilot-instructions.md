# GitHub Copilot Instructions

This file is the authoritative instruction source for routine GitHub Copilot work in this repository. Use it as the operational default. Consult the [constitution](../.specify/memory/constitution.md) directly when a task affects specifications, behaviour, architecture, ADRs, or governance, or when guidance conflicts.

## Implementation discipline

- Do not invent requirements or widen scope.
- Keep outputs deterministic, make side effects explicit, and surface errors.
- If code and specification diverge, either fix the implementation or amend the specification with rationale.
- Order code to follow the primary execution or call flow when that improves readability, and group widely shared utilities clearly.

## Test-driven development

- For behavioural changes, follow `Red -> Green -> Refactor`.
- Use property-based testing where it adds value.

## Skill invocation gates

- Before implementation, load the `test-driven-development` skill.
- On unexpected test, build, or runtime failures, load the `systematic-debugging` skill.
- Before completion, load the `verification-before-completion` skill.

## Repository verification policy

After source code changes, satisfy the repository's canonical local quality gates. If hooks already enforce them, do not rerun the same commands unless diagnosing a failure.

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
