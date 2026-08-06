# Onboarding 🚀

> Linked from the [README](../README.md) under **Quick start** and **How to use**. See also [docs/architecture.md](architecture.md) for the customisation model and lifecycle, and [docs/catalogue.md](catalogue.md) for the auto-generated artefact index.

This guide walks new users and contributors through every supported installation path, the first-run experience, the apply workflow for downstream repositories, and the quality gates expected before opening a pull request.

## Choose your installation path

Three paths are supported. Pick the one that matches your goal:

- **Full clone** - contribute to the library or experiment with every artefact locally. Start at [First setup](#first-setup).
- **Plugin install** - get skills, agents, and hooks in VS Code without managing files in your repo. See [Plugin installation path](#plugin-installation-path).
- **Selective copy** - pull only a subset of prompts, instructions, or templates into a target repository. See [Selective install](#selective-install).

## Prerequisites

- Git
- GNU Make 3.82 or newer
- A text editor (VS Code recommended for Copilot integration)

## First setup

Clone the repository and configure the local environment:

```bash
git clone https://github.com/stefaniuk/awesome-copilot-promptfiles.git
cd awesome-copilot-promptfiles

# Configure the development environment (installs git hooks, sets up scripts)
make config

# Verify quality gates work
make lint && make test
```

`make config` is idempotent - it can be re-run safely after pulling updates.

## First run + expected output

After `make config`, run both quality gates:

```bash
make lint
make test
```

**Expected output:** Each command completes with exit code `0`. Linting covers markdown, links, scripts, and configuration; tests exercise the apply pipeline and helper scripts. If either command fails on a clean clone, [open an issue](https://github.com/stefaniuk/awesome-copilot-promptfiles/issues) with the failure output.

## Apply workflow to downstream repos

Sync the prompt library into a target repository with a single command:

```bash
make apply dest=/absolute/path/to/target
```

What gets copied:

- `AGENTS.md`
- `.github/agents`, `.github/hooks`, `.github/instructions`, `.github/prompts`, `.github/skills`
- `.github/copilot-instructions.md`
- `.github/pull_request_template.md` (only if missing in the target)
- `.specify/memory/constitution.md`
- `scripts/hooks/`
- `.specify/scripts/bash`, `.specify/templates`
- `docs/adr/ADR-nnn_Any_Decision_Record_Template.md`
- `docs/prompt-reports/`, `docs/prompts/`, `docs/.gitignore`
- `project.code-workspace` (only if missing in the target)

After the copy completes, review `git status` in the target repository, commit the changes, and run `make lint && make test` to confirm everything wires up correctly.

## Plugin installation path

The repository can be installed directly as a VS Code agent plugin, providing skills, agents, and hooks without invoking `make apply`:

1. Open VS Code with Copilot agent mode enabled.
2. Run `Cmd+Shift+P` → **Chat: Install Plugin From Source**.
3. Enter the repository URL: `https://github.com/stefaniuk/awesome-copilot-promptfiles`.

After installation, skills like `/enforcement-audit` and `/architecture-docs` appear as slash commands, and `speckit.*` agents appear in the agent dropdown.

> **Note:** Plugin installation provides skills, agents, and hooks only. For project-specific instructions, templates, and include baselines, use `make apply`.

## Selective install

`make apply` accepts per-technology flags so you can scope what gets copied. Pass any of the following as `name=true`:

`all`, `python`, `typescript`, `go`, `reactjs`, `rust`, `terraform`, `tauri`, `playwright`, `django`, `fastapi`

These per-tech flags correspond to the language packs documented in [docs/conventions.md](conventions.md#language-packs).

Additional flags:

- `clean=true` - remove previously applied artefacts before copying.
- `revert=true` - undo a previous apply in the target repo.
- `subset=<csv>` - restrict the copy to named categories (see below).

Example - apply only the Python and Terraform packs to a target:

```bash
make apply dest=/path/to/target python=true terraform=true
```

### Subset selection

Use `subset=<csv>` to scope which categories of artefacts are copied. Omitting `subset` (or setting `subset=all`) preserves the default full-copy behaviour. Tokens are comma-separated, case-insensitive, and validated against a closed set.

| Token          | Categories included                                                                                                                                                                  |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `all`          | Everything (default; equivalent to omitting `subset`)                                                                                                                                |
| `agents`       | `.github/agents/` (all agents and personas)                                                                                                                                          |
| `hooks`        | `.github/hooks/` and `scripts/hooks/`                                                                                                                                                |
| `instructions` | `.github/instructions/` (plus tech files when language flags are set)                                                                                                                |
| `prompts`      | `.github/prompts/` (plus tech enforcement prompts when language flags are set)                                                                                                       |
| `skills`       | `.github/skills/` (plus tech skills when `django`/`fastapi` are set)                                                                                                                 |
| `specify`      | `.specify/memory`, `.specify/scripts/bash`, `.specify/templates`                                                                                                                     |
| `docs`         | `docs/adr/` template + Tech Radar, `docs/prompt-reports/`, `docs/prompts/`                                                                                                           |
| `project`      | Project glue: `AGENTS.md`, `.github/copilot-instructions.md`, `pull_request_template.md`, `project.code-workspace`, `.vscode/settings.json`, `.gitignore`, hook scripts              |
| `speckit`      | Narrows `agents` and `prompts` to `speckit.*` and `review.speckit-*` files, and pulls in the `.specify/*` content. Combine with `agents` or `prompts` to widen back to the full set. |
| `mcp`          | Opt-in MCP example pack: `.vscode/mcp.json.example`, `.github/mcp/` per-server READMEs, and `docs/mcp.md`. Included by default and by `all`; otherwise only when listed explicitly.  |

Examples:

```bash
make apply dest=/path/to/target subset=prompts,agents
make apply dest=/path/to/target subset=speckit
make apply dest=/path/to/target subset=instructions python=true
```

#### Recommended profiles

The repository is split into a default **core** plugin pack and an optional **speckit** sub-pack - see [conventions.md#plugin-packs](conventions.md#plugin-packs). Three common install profiles:

| Profile                | Command                                                                                        |
| ---------------------- | ---------------------------------------------------------------------------------------------- |
| Full install (default) | `make apply dest=/path/to/target`                                                              |
| Spec-kit only          | `make apply dest=/path/to/target subset=speckit`                                               |
| Non-spec-kit core      | `make apply dest=/path/to/target subset=agents,hooks,instructions,prompts,skills,docs,project` |

For full argument details see `scripts/apply.sh --help` and the `apply` target in the [Makefile](../Makefile).

## Counting tokens

Estimate context-window usage for any subset of prompt files:

```bash
# Default: scan Copilot prompt files
make count-tokens

# Scan all markdown, sorted by token count
make count-tokens args="--all --sort-by tokens"

# Target specific paths
make count-tokens args=".github/instructions .specify"
```

The report shows:

- **Tokens** - per-file token counts.
- **No IDs** - counts with identifiers like `[ID-<prefix>-NNN]` stripped.
- **Usage %** - context-window usage against a 200K baseline.

## Contributor setup and quality gates

Contributors follow the same `make config` flow as users, then layer the quality commands and review checklist on top.

### Development setup

```bash
git clone https://github.com/stefaniuk/awesome-copilot-promptfiles.git
cd awesome-copilot-promptfiles
make config
```

### Quality commands

```bash
make lint   # File format, markdown format, markdown links
make test   # Apply pipeline and script tests
```

### Quick checklist

1. **Raise an issue or PR** describing the planned changes.
2. **Keep artefacts in sync** - specs, plans, tasks, and docs must align.
3. **Run quality gates** - `make lint && make test` must pass before opening a PR.
4. **Follow the constitution** in `.specify/memory/constitution.md` and the cross-agent rules in [AGENTS.md](../AGENTS.md).

See [.github/contributing.md](../.github/contributing.md) for the full contributor guide.

## Troubleshooting

<!-- TODO: Populate with evidence-backed recurring issues as they emerge from real usage. -->

No recurring issues have been documented yet. If you hit a reproducible problem, [open an issue](https://github.com/stefaniuk/awesome-copilot-promptfiles/issues) so it can be triaged and added here.

---

See also: [README](../README.md) · [Architecture](architecture.md) · [Catalogue](catalogue.md)
