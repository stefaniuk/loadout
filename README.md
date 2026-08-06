# GitHub Copilot Prompt Files

A curated, specification-first library of prompts, instruction packs, skills, and Copilot agents that keeps AI helpers aligned with the spec-kit operating model.

[![Licence](https://img.shields.io/badge/licence-MIT-green?style=for-the-badge)](LICENCE.md)

## Why this project exists

This library provides a central source of reusable prompts, instruction packs, skills, and Copilot agents for AI-assisted development workflows. It keeps AI helpers aligned with a shared, specification-driven operating model so teams gain consistent, deterministic automation across repositories.

Without shared prompt files, AI assistants drift from agreed standards, produce inconsistent outputs, and lack deterministic validation. Teams end up reinventing the same prompts and struggling to maintain alignment across projects.

This library solves that by writing prompts, agents, and skills directly against the spec-kit constitution, applying deterministic lint, test, and review rules through instruction packs, and leaning on `make lint`, `make test`, and explicit governance gates so behaviour stays measurable and testable. Copy-paste reuse speeds onboarding, and governance gates keep specifications, code, and documentation synchronised.

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

Expected result:

- `make lint` and `make test` complete with exit code 0.

See [docs/onboarding.md](docs/onboarding.md) for the full first-run walkthrough, including installation paths, selective install flags, and contributor setup.

## What it does

### Key features

- **Specification-first truth:** prompts, agents, and skills are written against the spec-kit constitution so code, docs, and governance stay synchronised.
- **Consistent guardrails:** instruction packs apply deterministic lint, test, and review rules across every repo.
- **Deterministic automation:** every workflow leans on `make lint`, `make test`, and explicit governance gates.
- **Copy-ready building blocks:** everything is shippable by folder, accelerating onboarding for large organisations.
- **Governance gates:** explicit checkpoints between specification and implementation.

### Non-goals

- Does not implement the underlying spec-kit framework itself.
- Does not provide a runtime execution environment for prompts.
- Not a replacement for language-specific linters or test frameworks.

## How it solves the problem

The library is organised into six customisation layers. Each layer builds on the one below, from governance foundations through to deterministic automation hooks.

```text
┌─────────────────────────────────────────────┐
│  Layer 5: Hooks (deterministic gates)       │
├─────────────────────────────────────────────┤
│  Layer 4: Skills (reusable capabilities)    │
├─────────────────────────────────────────────┤
│  Layer 3: Agents (personas + handoffs)      │
├─────────────────────────────────────────────┤
│  Layer 2: Prompts (one-off tasks)           │
├─────────────────────────────────────────────┤
│  Layer 1: Instructions (standards + rules)  │
├─────────────────────────────────────────────┤
│  Layer 0: Governance (constitution + ADRs)  │
└─────────────────────────────────────────────┘
```

A typical workflow follows the spec-kit lifecycle: discover the right prompt, ground it in a specification, plan, generate tasks, implement, converge, and review. Every validation step runs through `make lint` and `make test`.

See [docs/architecture.md](docs/architecture.md) for the full layer model, artefact type decision matrix, orchestration diagram, and commit conventions per lifecycle stage.

## How to use

This section covers the three workflows most users need first. For the full reference, see [docs/onboarding.md](docs/onboarding.md).

### Configuration

No additional configuration is required beyond `make config`. The library uses convention over configuration with sensible defaults.

### Common workflows

#### 1. Apply the full library to a target repo

Use this when you want to sync all prompt files into a downstream repository.

```bash
make apply dest=/absolute/path/to/target
```

Expected result:

- Prompt files, instructions, skills, and hooks are copied into the target.

#### 2. Remote bootstrap via curl

Use this when you want to install without cloning first.

```bash
curl -fsSL https://raw.githubusercontent.com/stefaniuk/awesome-copilot-promptfiles/main/scripts/install.sh \
  | bash -s -- --dest /absolute/path/to/target --ref v1.0.0
```

Expected result:

- The target repository receives the library at the pinned ref.

Always pin `--ref` to an immutable tag or commit SHA in CI and shared environments.

#### 3. Selective install

Use this when you only need a subset of the library (for example, Python-only or Terraform-only files).

```bash
make apply dest=/absolute/path/to/target python=true
```

Expected result:

- Only the selected technology pack is copied to the target.

See [docs/onboarding.md#apply-workflow-to-downstream-repos](docs/onboarding.md#apply-workflow-to-downstream-repos) for the full list of flags and category-level scoping.

### Examples

See [docs/catalogue.md](docs/catalogue.md) for the auto-generated index of every prompt, instruction pack, agent, skill, and hook in this repository. The cross-cutting taxonomy is described in [docs/conventions.md](docs/conventions.md).

## Resources

- [Custom Prompts](https://code.visualstudio.com/docs/copilot/customization/prompt-files): VS Code docs
- [Custom Instructions](https://code.visualstudio.com/docs/copilot/customization/custom-instructions): VS Code docs
- [Custom Agents](https://code.visualstudio.com/docs/copilot/customization/custom-agents): VS Code docs (this repository uses `.agent.md` exclusively)
- [Custom Skills](https://code.visualstudio.com/docs/copilot/customization/agent-skills): VS Code docs
- [Copilot Chat setup (macOS)](docs/prompts/vscode-copilot-chat-setup-macos.md): local setup guide
- [Awesome Copilot](https://github.com/github/awesome-copilot): community index

## Contributing

Contributions are welcome. The short version: clone, run `make config`, make your changes, and ensure `make lint && make test` pass before opening a PR.

See [.github/contributing.md](.github/contributing.md) for the full guide, [.github/security.md](.github/security.md) for the security policy, and [docs/onboarding.md#contributor-setup-and-quality-gates](docs/onboarding.md#contributor-setup-and-quality-gates) for dev setup and quality commands.

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

## Licence

This project is licensed under the MIT Licence. See [LICENCE.md](LICENCE.md) for details.
