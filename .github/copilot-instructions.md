# GitHub Copilot Instructions ✨

GitHub Copilot in VS Code reads this file alongside [`AGENTS.md`](/AGENTS.md). `AGENTS.md` is the **canonical baseline** for every agent (governance, communication style, toolchain version, ADR discipline, TDD, and workflow guardrails) — read and follow it first. This file holds only the Copilot-specific additions; it must not contradict `AGENTS.md`.

Local quality-gate commands are intentionally not restated here. The canonical policy lives in the constitution and is enforced in Copilot sessions by repository hooks.

## Repository tooling

When you identify missing development capabilities (linting, CI/CD, Docker support, pre-commit hooks, etc.), consult the [repository-template skill](/.github/skills/repository-template/SKILL.md) for standardised implementations.

## Skills and prompts

This workspace ships a set of reusable [skills](/.github/skills/) and [prompts](/.github/prompts/) discovered directly from those directories. Prefer invoking the appropriate skill (semantic match) or slash command (`/<prompt-name>`) over re-deriving a workflow from scratch.

---

> **Version**: 2.0.2
> **Last Amended**: 2026-05-17
