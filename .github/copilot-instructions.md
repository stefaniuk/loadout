# GitHub Copilot Instructions 🤖

This file is the authoritative instruction source for routine GitHub Copilot
work in this repository. Use it as the operational default. Consult the
[constitution](../.specify/memory/constitution.md) directly when a task affects
specifications, behaviour, architecture, ADRs, or governance, or when guidance
conflicts.

## Implementation discipline 🛠️

- Do not invent requirements or widen scope.
- Keep outputs deterministic, make side effects explicit, and surface errors.
- Follow execution or call-flow order where it improves clarity. Group widely
  shared utilities.

## Specification and testing 🧪

- When code and specification diverge, assess both. Fix incorrect code and
  revise wrong or impractical specifications with rationale and impact
  assessment. Align code and tests with the result. Never justify accidental
  behaviour by rewriting the specification.
- For behavioural changes, follow `Red -> Green -> Refactor`.
- Use property-based testing where it adds value.

## Skill invocation gates

- Use the `test-driven-development` skill only when the task requires a new
  failing test that should drive a code or behaviour change.
- On unexpected test, build, or runtime failures, load the
  `systematic-debugging` skill.
- Before completion, load the `verification-before-completion` skill.

## Workflow mode

- Never change the workflow mode yourself. Do not run `make workflow-use` or
  `make workflow-clear`, and do not edit the mode configuration. The session
  start context names the active mode.

## Repository verification policy 🔍

Run failing tests and focused checks while working. After edits, the Stop hook
runs `make lint` and `make test`. Since `make lint` checks tracked files only,
stage newly created files so they are included. Do not stage existing files just
for the hook. Do not rerun the full gates manually unless diagnosing a failure
or the hook is unavailable.

## Communication style 💬

- Use British English.
- Keep language simple, direct, and active.
- Do not use em dashes or semicolons in prose.
- Write short sentences and prefer intention-revealing wording.
- Update existing documentation or comments in place. Avoid competing
  explanations of the same topic.

## Documentation ADRs 🧾

Record significant technical decisions and technology choices in
[docs/adr](../docs/adr). Consult the current internal NHS Tech Radar for
approval status first, then the local
[Technology Recommendations](../docs/adr/Technology_Recommendations.md) for
candidate tools. Even a default choice needs an ADR comparing alternatives using
the [ADR template](../docs/adr/ADR-nnn_Any_Decision_Record_Template.md).

## Toolchain version 🔧

Use the newest eligible stable language, runtime and framework versions that
meet project constraints, including the cooldown in
[Update Dependencies](../docs/guides/template/Update_Dependencies.md).
