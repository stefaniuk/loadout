# Onboarding 🚀

> Linked from the [README](../README.md) under **Quick start** and **How to use**. See also [docs/architecture.md](architecture.md) for the customisation model and lifecycle.

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
git clone https://github.com/stefaniuk/loadout.git
cd loadout

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

**Expected output:** Each command completes with exit code `0`. Linting covers markdown, links, scripts, and configuration; tests exercise the apply pipeline and helper scripts. If either command fails on a clean clone, [open an issue](https://github.com/stefaniuk/loadout/issues) with the failure output.

## Apply workflow to downstream repos

Sync the prompt library into a target repository with a single command:

```bash
make apply dest=/absolute/path/to/target
```

What gets copied:

- `.github/agents`, `.github/hooks`, `.github/instructions`, `.github/prompts`, `.github/skills`
- `.github/copilot-instructions.md`
- `.github/pull_request_template.md` (only if missing in the target)
- `.specify/memory/constitution.md`
- `scripts/hooks/`
- `.specify/scripts/python`, `.specify/templates`
- `docs/adr/ADR-nnn_Any_Decision_Record_Template.md`
- `docs/prompt-reports/`, `docs/.gitignore`
- `project.code-workspace` (only if missing in the target)

After the copy completes, review `git status` in the target repository, commit the changes, and run `make lint && make test` to confirm everything wires up correctly.

## Plugin installation path

The repository can be installed directly as a VS Code agent plugin, providing skills, agents, and hooks without invoking `make apply`:

1. Open VS Code with Copilot agent mode enabled.
2. Run `Cmd+Shift+P` → **Chat: Install Plugin From Source**.
3. Enter the repository URL: `https://github.com/stefaniuk/loadout`.

After installation, skills like `/enforcement-audit` and `/architecture-docs` appear as slash commands, and speckit skills (`/speckit-specify`, `/speckit-plan`, etc.) become available.

> **Note:** Plugin installation provides skills, agents, and hooks only. For project-specific instructions, templates, and include baselines, use `make apply`.

## Selective install

`make apply` accepts per-technology flags so you can scope what gets copied. Pass any of the following as `name=true`:

`all`, `python`, `typescript`, `go`, `reactjs`, `rust`, `terraform`, `tauri`, `playwright`

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

| Token          | Categories included                                                                                                                                                                 |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `all`          | Everything (default; equivalent to omitting `subset`)                                                                                                                               |
| `agents`       | `.github/agents/` (all agents and personas)                                                                                                                                         |
| `hooks`        | `.github/hooks/` and `scripts/hooks/`                                                                                                                                               |
| `instructions` | `.github/instructions/` (plus tech files when language flags are set)                                                                                                               |
| `prompts`      | `.github/prompts/` (plus tech enforcement prompts when language flags are set)                                                                                                      |
| `skills`       | `.github/skills/` (plus tech skills when language flags are set)                                                                                                                    |
| `specify`      | `.specify/memory`, `.specify/scripts/python`, `.specify/templates`                                                                                                                  |
| `docs`         | `docs/adr/` template + Tech Radar, `docs/prompt-reports/`                                                                                                                           |
| `project`      | Project glue: `.github/copilot-instructions.md`, `pull_request_template.md`, `project.code-workspace`, `.vscode/settings.json`, `.gitignore`, hook scripts                          |
| `speckit`      | Narrows `skills` to `speckit-*` and `prompts` to `review.speckit-*` files, and pulls in the `.specify/*` content. Combine with `skills` or `prompts` to widen back to the full set. |
| `mcp`          | Opt-in MCP example pack: `.vscode/mcp.json.example`, `.github/mcp/` per-server READMEs, and `docs/mcp.md`. Included by default and by `all`; otherwise only when listed explicitly. |

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

## Import workflow from downstream repos

The inverse of apply: pull improvements made in a project repository back into this source library.

```bash
make import dest=/absolute/path/to/project
```

The script compares prompt files in the project against the source library and reports which files have changed. By default it prompts before copying each changed file.

### Options

```bash
# Copy all changed files without prompting
force=true make import dest=/path/to/project

# Also import new files that exist in the project but not in this repo
new=true make import dest=/path/to/project

# Both: import everything non-interactively
new=true force=true make import dest=/path/to/project
```

### Typical workflow

1. Apply the library to a project: `make apply dest=/path/to/project`
2. Work in the project, improving instructions, prompts, or skills
3. Import changes back: `make import dest=/path/to/project`
4. Review the diff in this repository, run `make lint && make test`, and commit

## Syncing upstream Spec Kit

The repository uses Spec Kit agents, prompts, and templates from the upstream [github/spec-kit](https://github.com/github/spec-kit) project. Local patches for both imported Spec Kit skills and synced third-party skills are maintained in `scripts/skill-patches/` and applied on top of the fetched upstream files.

### Running sync

```bash
make specify
```

This fetches the latest Spec Kit files, applies local patches declared in `scripts/skill-patches/manifest.yaml`, and writes the patched output to:

- `.github/skills/speckit-*/` (speckit skill definitions)
- `.specify/templates/` (plan, spec, tasks templates)
- `.specify/scripts/python/` (speckit helper scripts)

The resolved Spec Kit version is recorded in `.specify/.speckit-version`.

### Dry run

Preview what would change without modifying files:

```bash
dry_run=true make specify
```

### When to run

Run `make specify` after:

- Pulling updates to this repository (upstream Spec Kit may have changed)
- Modifying files in `scripts/skill-patches/`
- Wanting to reset speckit skills to their canonical patched state

### Prerequisites

The `specify` CLI must be installed. See [github/spec-kit](https://github.com/github/spec-kit) for installation instructions. `yq` is also required for YAML parsing.

## Managing external skills

Third-party agent skills can be cloned into `.github/skills/` from upstream repositories. A YAML manifest at `scripts/config/skills.yaml` declares which skills to fetch, and three make targets manage the lifecycle. The same patch engine and manifest used by `make specify` patch every upstream skill through the shared `scripts/skill-patches/skills/` directory.

### Configuration

Each entry in `scripts/config/skills.yaml` requires `name`, `repo`, and `path`. The `ref` defaults to `main` and `sha` is populated automatically on first sync:

```yaml
skills:
  - name: systematic-debugging
    repo: https://github.com/obra/superpowers.git
    path: skills/systematic-debugging
```

### Adding a skill

**Option A** (edit then sync):

```bash
# 1. Add an entry to scripts/config/skills.yaml
# 2. Fetch it
make skill-sync
```

**Option B** (one command):

```bash
make skill-add name=writing-plans repo=https://github.com/obra/superpowers.git path=skills/writing-plans
```

Both append the skill to `.github/skills/<name>/`, apply any local `SKILL.md` patch from `scripts/skill-patches/skills/`, pin the resolved commit SHA in the manifest, and update lint exclusions.

### Updating skills

Re-run sync to fetch the latest from each declared ref:

```bash
make skill-sync
```

To update a single skill:

```bash
make skill-sync name=systematic-debugging
```

To inspect the vanilla upstream content without applying local patches:

```bash
make skill-sync name=incremental-implementation patch=false
```

To reapply local patches to already-synced skills without fetching upstream:

```bash
make skill-patch
```

To reapply the patch for a single skill:

```bash
make skill-patch name=incremental-implementation
```

### What happens during sync

1. Each skill is shallow-cloned using git sparse checkout (only the declared path).
2. If `scripts/skill-patches/skills/<name>.patch.md` exists, it is injected into the synced `SKILL.md` using the shared rules from `scripts/skill-patches/manifest.yaml` that also apply to imported Spec Kit skills.
3. The resolved commit SHA is written back to `scripts/config/skills.yaml`.
4. The `.markdownlintignore` managed section is updated with all synced skill directories (sorted alphabetically).
5. Synced skill directories are excluded from shellcheck automatically.

### Prerequisites

`yq` is required for YAML manipulation. Install via `brew install yq`.

## Contributor setup and quality gates

Contributors follow the same `make config` flow as users, then layer the quality commands and review checklist on top.

### Development setup

```bash
git clone https://github.com/stefaniuk/loadout.git
cd loadout
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
4. **Follow the constitution** in `.specify/memory/constitution.md` and the repository-wide rules in [.github/copilot-instructions.md](../.github/copilot-instructions.md).

See [.github/contributing.md](../.github/contributing.md) for the full contributor guide.

## Troubleshooting

<!-- TODO: Populate with evidence-backed recurring issues as they emerge from real usage. -->

No recurring issues have been documented yet. If you hit a reproducible problem, [open an issue](https://github.com/stefaniuk/loadout/issues) so it can be triaged and added here.

---

See also: [README](../README.md) · [Architecture](architecture.md)
