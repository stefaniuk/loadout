# GitHub Copilot Prompt Files

A curated, specification-first library of prompts, instruction packs, skills, and Copilot agents that keeps AI helpers aligned with the spec-kit operating model.

[![Spec-Kit](https://img.shields.io/badge/spec--kit-powered-blue?style=for-the-badge)](https://github.com/stefaniuk/awesome-copilot-promptfiles)
[![Licence](https://img.shields.io/badge/licence-MIT-green?style=for-the-badge)](LICENCE.md)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen?style=for-the-badge)](./.github/contributing.md)

## Why this project exists

### Purpose

A central source of reusable prompts, instruction packs, skills, and Copilot agents for AI-assisted development workflows, designed to keep AI helpers aligned with a shared, specification-driven operating model.

### Benefit to the user

Teams gain consistent, deterministic automation across repositories. Copy-paste reuse speeds onboarding, and governance gates keep specifications, code, and documentation synchronised.

### Problem it solves

Without shared prompt files, AI assistants drift from agreed standards, produce inconsistent outputs, and lack deterministic validation. Teams end up reinventing the same prompts and struggling to maintain alignment across projects.

### How it solves it (high level)

Prompts, agents, and skills are written directly against the spec-kit constitution. Instruction packs apply deterministic lint, test, and review rules. Every workflow leans on `make lint`, `make test`, and explicit governance gates so behaviour stays measurable and testable.

## Quick start

### Prerequisites

- Git
- GNU Make 3.82+
- A text editor (VS Code recommended for Copilot integration)

### Setup

```bash
git clone https://github.com/stefaniuk/awesome-copilot-promptfiles.git
cd awesome-copilot-promptfiles
make config
make lint && make test
```

**Expected output:** `make lint` and `make test` complete with exit code 0.

See [docs/onboarding.md](docs/onboarding.md) for the full first-run walkthrough, including installation paths, selective install flags, and contributor setup.

## What it does

### Key features

- **Specification-first truth** — prompts, agents, and skills are written against the spec-kit constitution so code, docs, and governance stay synchronised.
- **Consistent guardrails** — instruction packs apply deterministic lint, test, and review rules across every repo.
- **Deterministic automation** — every workflow leans on `make lint`, `make test`, and explicit governance gates.
- **Copy-ready building blocks** — everything is shippable by folder, accelerating onboarding for large organisations.
- **Governance gates** — explicit checkpoints between specification and implementation.

### Non-goals

- Does not implement the underlying spec-kit framework itself.
- Does not provide a runtime execution environment for prompts.
- Not a replacement for language-specific linters or test frameworks.

## How it works

The library is organised into six customisation layers. Each layer builds on the one below, from governance foundations through to deterministic automation hooks.

```text
┌─────────────────────────────────────────────┐
│  Layer 5: Hooks (deterministic gates)       │
│  .github/hooks/*.json                       │
├─────────────────────────────────────────────┤
│  Layer 4: Skills (reusable capabilities)    │
│  .github/skills/*/SKILL.md                  │
├─────────────────────────────────────────────┤
│  Layer 3: Agents (personas + handoffs)      │
│  .github/agents/*.agent.md                  │
├─────────────────────────────────────────────┤
│  Layer 2: Prompts (one-off tasks)           │
│  .github/prompts/*.prompt.md                │
├─────────────────────────────────────────────┤
│  Layer 1: Instructions (standards + rules)  │
│  .github/instructions/*.instructions.md     │
├─────────────────────────────────────────────┤
│  Layer 0: Governance (constitution + ADRs)  │
│  .specify/memory/constitution.md, AGENTS.md │
└─────────────────────────────────────────────┘
```

- **Layer 0 — Governance.** Constitution, ADRs, and cross-agent rules every other layer must honour.
- **Layer 1 — Instructions.** Coding standards scoped by file glob, loaded automatically by Copilot.
- **Layer 2 — Prompts.** One-off, copy-runnable tasks invoked explicitly.
- **Layer 3 — Agents.** Persistent personas with tool restrictions and handoff chains.
- **Layer 4 — Skills.** Reusable multi-step capabilities bundled with helper scripts.
- **Layer 5 — Hooks.** Deterministic automation that runs without an LLM in the loop.

See [docs/architecture.md](docs/architecture.md) for the full model and the artefact type decision matrix.

## Spec-kit lifecycle

1. **Discover** the right prompt from the library.
2. **Ground** it in a specification with `/speckit.specify`.
3. **Plan** the implementation with `/speckit.plan`.
4. **Generate tasks** with `/speckit.tasks`.
5. **Implement** with `/speckit.implement`.
6. **Review** with `/review.speckit-documentation`, `/review.speckit-code`, `/review.speckit-test`.
7. **Automate** every validation step with `make lint` and `make test`.

See [docs/architecture.md#spec-kit-lifecycle](docs/architecture.md#spec-kit-lifecycle) for the orchestration diagram, governance gates, and commit conventions per lifecycle stage.

## How to use

### Configuration

No additional configuration is required beyond `make config`. The library uses convention over configuration with sensible defaults.

### Common workflows

Sync prompt files into a target repository:

```bash
make apply dest=/absolute/path/to/target
```

Selective installs (per-technology flags such as `python=true`, `terraform=true`, `clean=true`, or `subset=<csv>` for category-level scoping) and the full list of copied paths are documented in [docs/onboarding.md#apply-workflow-to-downstream-repos](docs/onboarding.md#apply-workflow-to-downstream-repos). The `speckit.*` artefacts form an optional sub-pack; see [docs/conventions.md#plugin-packs](docs/conventions.md#plugin-packs).

The library can also be installed as a VS Code agent plugin — see [docs/onboarding.md#plugin-installation-path](docs/onboarding.md#plugin-installation-path).

#### Quick install (curl)

Bootstrap the library into a target repository without cloning first:

```bash
curl -fsSL https://raw.githubusercontent.com/stefaniuk/awesome-copilot-promptfiles/main/scripts/install.sh \
  | bash -s -- --dest /absolute/path/to/target
```

Pin to an immutable tag or commit for reproducible, supply-chain-safe installs and select a specific ref:

```bash
curl -fsSL https://raw.githubusercontent.com/stefaniuk/awesome-copilot-promptfiles/v1.0.0/scripts/install.sh \
  | bash -s -- --dest /absolute/path/to/target --ref v1.0.0
```

To uninstall, clone the repository and run the local uninstaller (no remote uninstall mode in v1):

```bash
git clone https://github.com/stefaniuk/awesome-copilot-promptfiles.git
./awesome-copilot-promptfiles/scripts/uninstall.sh --dest /absolute/path/to/target
```

Both wrappers delegate to `scripts/apply.sh`; uninstall is implemented as `revert=true scripts/apply.sh <dest>`. Always pin `--ref` to an immutable tag or commit SHA in CI and shared environments to avoid drift from `main`.

### Install via the GitHub Copilot CLI

Once listed in the [awesome-copilot](https://github.com/github/awesome-copilot) marketplace:

```bash
copilot plugin install awesome-copilot-promptfiles
```

Pending marketplace approval — see [docs/prompt-reports/marketplace-submission.md](docs/prompt-reports/marketplace-submission.md) for status.

### Examples

See [docs/catalogue.md](docs/catalogue.md) for the auto-generated index of every prompt, instruction pack, agent, skill, and hook in this repository, including naming conventions and tags. The cross-cutting taxonomy (language packs, foundation packs, naming, ADR triggers) is described in [docs/conventions.md](docs/conventions.md).

## Resources

- Custom Prompts — [VS Code Docs](https://code.visualstudio.com/docs/copilot/customization/prompt-files)
- Custom Instructions — [VS Code Docs](https://code.visualstudio.com/docs/copilot/customization/custom-instructions)
- Custom Agents — [VS Code Docs](https://code.visualstudio.com/docs/copilot/customization/custom-agents) — note: `.chatmode.md` is **legacy** as of the VS Code April 2026 release; this repository uses `.agent.md` exclusively
- Custom Skills — [VS Code Docs](https://code.visualstudio.com/docs/copilot/customization/agent-skills)
- Copilot Chat (macOS) — [Local setup guide](docs/prompts/vscode-copilot-chat-setup-macos.md)
- Awesome Copilot — [GitHub](https://github.com/github/awesome-copilot)

## Contributing

Contributions are welcome. The short version: clone, run `make config`, make your changes, and ensure `make lint && make test` pass before opening a PR.

See [.github/contributing.md](.github/contributing.md) for the full guide and [docs/onboarding.md#contributor-setup-and-quality-gates](docs/onboarding.md#contributor-setup-and-quality-gates) for the dev setup, quality commands, and quick checklist.

## Repository layout

```text
.
├── AGENTS.md                 # Cross-agent always-on instructions
├── plugin.json               # VS Code agent plugin manifest
├── hooks.json                # Root-level hook bindings
├── Makefile                  # Quality, apply, and utility targets
├── .github/                  # Agents, hooks, instructions, prompts, skills
├── .specify/                 # Spec-kit templates and project constitution
├── docs/                     # Architecture, onboarding, catalogue, ADRs
└── scripts/                  # Build, apply, hook, and utility scripts
```

A full directory listing with per-artefact descriptions is available in [docs/catalogue.md](docs/catalogue.md).

## Roadmap

<details>
<summary><strong>📝 New Prompts</strong></summary>

- `architecture-review.prompt` — architect for flow
- `migrate-from-[tech A]-to-[tech B].prompt`

</details>
<details>
<summary><strong>🔧 Workflow Prompts</strong></summary>

- **Release notes** — changelog entries grouped by spec identifiers

</details>

## Licence

This project is licensed under the MIT Licence. See [LICENCE.md](LICENCE.md) for details.
