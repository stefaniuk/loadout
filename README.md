# loadout

A specification-first GitHub Copilot customisation toolkit for teams that want reusable prompts, instructions, agents, skills, hooks, and MCP examples to behave consistently across repositories.

## Why this project exists

AI customisation tends to drift once each repository invents its own prompts, review flow, and guardrails. That makes it harder to trust outputs, onboard contributors, and keep documentation, specs, and validation rules aligned.

loadout packages those pieces into one reusable toolkit. It gives teams a clear starting point for governance, authoring rules, reusable workflows, and quality checks, then makes that toolkit easy to copy into another repository with the same structure and expectations.

## Quick start

This path proves the repository is healthy locally and shows the main contributor workflow.

### Prerequisites

- Git
- GNU Make 3.82 or newer
- VS Code, if you want to use the shipped GitHub Copilot customisations locally

### Install

```bash
git clone https://github.com/stefaniuk/loadout.git
cd loadout
make config
```

### First run

```bash
make lint
make test
```

Expected result

- `make lint` completes without markdown, link, shell, or customisation errors.
- `make test` completes with a zero exit code.

For plugin installation, selective installs, and downstream apply workflows, see [docs/onboarding.md](docs/onboarding.md).

## What it does

The repository collects the files and helper scripts needed to run a specification-first Copilot workflow without rebuilding the same structure in every project.

### Key features

- Instruction packs for languages and tools such as Python, TypeScript, Go, Rust, Docker, Terraform, and Make.
- Prompts and workflow skills for specification-first and Superpowers-based planning, implementation, review, and convergence workflows.
- Reusable skills for documentation, code review, enforcement audits, repository templating, and framework-specific setup.
- Deterministic hooks and quality scripts for markdown, links, shell, MCP config, and customisation metadata.
- Optional MCP example packs with trust guidance and least-privilege defaults.

### Non-goals

- It is not a runtime replacement for GitHub Copilot or VS Code.
- It does not replace the language-specific build, lint, or test tooling inside a downstream repository.
- It does not auto-enable MCP servers or inline secrets into workspace configuration.

## How it solves the problem

The toolkit is organised so teams can adopt shared rules first, then layer reusable workflows on top. Governance lives in the constitution and ADRs. File-scoped instructions shape day-to-day authoring. Prompts, agents, and skills package repeatable tasks. Hooks and quality scripts catch drift before it spreads.

In practice, the flow is simple:

1. Start from the shared governance and authoring rules.
2. Choose the prompts, agents, skills, and hooks that match your workflow.
3. Copy them into a target repository with `make apply`.
4. Use the built-in docs and quality gates to keep the setup understandable and consistent.

Key concepts

- `Instructions`: always-on rules matched to file types.
- `Prompts`: one-off task entrypoints.
- `Agents`: optional custom agents when a repository needs tool-restricted roles or handoff chains.
- `Skills`: multi-step capabilities bundled with supporting assets.
- `Hooks`: deterministic checks that run outside the model.

See [docs/architecture.md](docs/architecture.md) for the full customisation model and the spec-kit lifecycle.

## How to use

The README covers the workflows most people need first. Use the docs for the full catalogue, installation variants, and architecture detail.

### Configuration

Run `make config` when you want a local working copy ready for validation and contribution. When you apply the toolkit to another repository, pass the destination through `dest=/path/to/repo`. Use `subset=` and the language flags, such as `python=true`, when you only want part of the toolkit. MCP examples stay opt-in and are shipped as `.example` files.

### Common workflows

#### Validate the toolkit locally

Use this when you want to confirm the repository is in a good state before changing it.

```bash
make config
make lint
make test
```

Expected result

- Local setup completes.
- Linting passes.
- Tests pass.

Further reading: [docs/onboarding.md#contributor-setup-and-quality-gates](docs/onboarding.md#contributor-setup-and-quality-gates)

#### Apply the full toolkit to another repository

Use this when you want to copy the standard prompt, instruction, agent, skill, and hook set into a target repository.

```bash
make apply dest=/absolute/path/to/target
```

Expected result

- The target repository receives the standard toolkit files.

Further reading: [docs/onboarding.md#apply-workflow-to-downstream-repos](docs/onboarding.md#apply-workflow-to-downstream-repos)

#### Install only selected packs

Use this when you only need a narrower set of artefacts, such as selected languages or categories.

```bash
make apply dest=/absolute/path/to/target subset=instructions,prompts python=true terraform=true
```

Expected result

- Only the requested categories and language packs are copied.

Further reading: [docs/onboarding.md#selective-install](docs/onboarding.md#selective-install)

### Examples

- Read the naming and placement rules in [docs/conventions.md](docs/conventions.md).
- Review the optional MCP pack in [docs/mcp.md](docs/mcp.md).

## Documentation

- [docs/README.md](docs/README.md): documentation landing page for the supporting docs set.
- [docs/onboarding.md](docs/onboarding.md): setup paths, first run, selective install, and contributor flow.
- [docs/architecture.md](docs/architecture.md): customisation layers, lifecycle, and governance gates.
- [docs/conventions.md](docs/conventions.md): naming, placement, frontmatter, and ADR rules.

## Contributing

Contributions should keep the repository's specs, docs, prompts, and helper scripts aligned. Start with `make config`, make the smallest change that fits the documented workflow, then run the quality gates before you open a pull request.

```bash
make lint
make test
```

If you change prompts, agents, skills, hooks, or generated inventories, also run `make catalogue` before you submit the change.

See [.github/contributing.md](.github/contributing.md) for the full contributor guide and [.github/security.md](.github/security.md) for private vulnerability reporting.

## Repository layout

These are the top-level paths most contributors need to recognise first.

```text
.
├── .github/      # Agents, instructions, prompts, skills, hooks, and repo governance files
├── .specify/     # Project constitution and spec-kit templates
├── docs/         # Architecture, onboarding, ADRs, and MCP guidance
├── scripts/      # Apply, import, install, and quality helpers
├── tests/        # Repository tests
├── Makefile      # Main entrypoint for setup, validation, and apply workflows
└── .github/      # Agents, instructions, prompts, skills, hooks, and repo governance files
```

## Licence

This project is licensed under the MIT Licence. See [LICENCE.md](LICENCE.md) for the full text.
