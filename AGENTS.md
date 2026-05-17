# Agent Instructions

Cross-agent always-on instructions for every AI-assisted development tool used in this repository (GitHub Copilot, Cursor, OpenAI Codex CLI, Claude Code, Aider, Jules, Sourcegraph Amp, and any other agent that honours the [agents.md](https://agents.md) convention).

This file is the canonical baseline. Agent-specific additions live alongside (for example `.github/copilot-instructions.md` for GitHub Copilot in VS Code), but they must not contradict anything here.

## Governance

Read and adhere to the [constitution](/.specify/memory/constitution.md) at all times.

## Communication style

- Use British English
- Keep language simple

## Toolchain version

Use the latest stable language, runtime, and framework versions at the time of change. When unsure, search the internet for the current stable release.

## Architectural decisions (ADRs)

When making architectural or otherwise significant technical decisions, document them as Architecture Decision Records (ADRs) under [/docs/adr](/docs/adr).

**What requires an ADR:**

- Architectural style choices (e.g. event-driven vs layered, monolith vs microservices)
- Architectural pattern choices (e.g. composition over inheritance, repository pattern, event sourcing)
- Language and framework selections
- Any other significant technical decision that shapes the system

**ADR requirements:**

- Only consult the ADR template when creating or updating an ADR; do not read it otherwise
- Use the [ADR template](/docs/adr/ADR-nnn_Any_Decision_Record_Template.md) when an ADR is required
- Follow the existing ADR format for consistency
- Always present 3 or more options with trade-offs
- Include the conversational context that led to the decision
- Document decisions regardless of whether you made them independently or were guided by the user

ADR discipline is mandatory throughout the spec-driven development cycle: `spec` → `plan` → `tasks` → `implement`.

For any technology or language choice, consult the [Tech Radar](/docs/adr/Tech_Radar.md) first.

## Test-driven development (mandatory)

- Define tasks using a strict TDD approach
- For each specified functionality, sequence tasks as Red (write failing test first), Green (implement to pass), then Refactor (improve code without changing behaviour)
- Ensure tests are always listed before implementation tasks
- Use property-based testing (PBT) where applicable to maximise coverage and edge case validation

## Quality gates (mandatory)

After any source code change:

1. The repository's canonical local quality gates must pass before the task is complete
2. In environments where hooks or other automation enforce those gates, rely on that enforcement rather than manually duplicating the same commands after every edit
3. If a gate fails, fix all errors and warnings — including those in files you did not modify when they block the gate
4. Manually rerun the relevant gate only when diagnosing a failure, recovering from unavailable automation, or when the user explicitly asks for the output
