# Onboarding 🚀

> Linked from the [README](../README.md) under **Quick start** and **How to
> use**. See also [docs/architecture.md](architecture.md) for the customisation
> model and lifecycle.

This guide walks new users and contributors through every supported installation
path, the first-run experience, the apply workflow for downstream repositories,
and the quality gates expected before opening a pull request.

## Choose your installation path

Three paths are supported. Pick the one that matches your goal:

- **Full clone** - contribute to the library or experiment with every artefact
  locally. Start at [First setup](#first-setup).
- **Plugin install** - get skills and agents in VS Code without managing files
  in your repo. See [Plugin installation path](#plugin-installation-path).
- **Selective copy** - pull only a subset of prompts, instructions, or templates
  into a target repository. See [Selective install](#selective-install).

## Prerequisites

- Git
- [mise](https://mise.jdx.dev/), which installs the tools pinned in `mise.toml`
- GNU Make 3.82 or newer, Bash 5.2 or newer and the GNU userland. On macOS, run
  `make toolchain-install-gnu-macos`
- Docker or Podman, optional, for the containerised quality checks
- A text editor (VS Code recommended for Copilot integration)

## First setup

Clone the repository and configure the local environment:

```bash
git clone https://github.com/stefaniuk/loadout.git
cd loadout

# Install the pinned toolchain, the Git hooks and the pinned Docker images
mise trust mise.toml
make config

# Verify quality gates work
make lint && make validate-customisations && make test
```

`make config` is idempotent - it can be re-run safely after pulling updates.

## Select the active workflow

This repository can host both lifecycle families at once, but only one should be
active in a given worktree.

Check the current mode:

```bash
make workflow-status
```

Switch to Spec Kit:

```bash
make workflow-use mode=speckit
```

Switch to Superpowers:

```bash
make workflow-use mode=superpowers
```

The choice is stored per worktree in the file that
`git rev-parse --git-path workflow-mode` names and is never committed. After
switching, start a fresh chat session so the chat picks up the active workflow
family. See [workflow-modes.md](workflow-modes.md) for how the hook keeps the
agent to the mode.

Copilot also uses `.copilot/analysis/` as a tracked local scaffold for ephemeral
analysis output. The nested `.gitignore` in that directory ignores generated
files while keeping the scaffold itself in git history.

Use one workflow family per worktree:

- `speckit` mode: use `speckit-*` skills and review prompts.
- `superpowers` mode: use the Superpowers lifecycle skills `/brainstorming`,
  `/writing-plans`, `/executing-plans` and `/subagent-driven-development`.

The worktree, review and finishing skills, such as `/requesting-code-review` and
`/receiving-code-review`, belong to no mode and work in both.

## First run + expected output

After `make config`, run the quality gates:

```bash
make lint
make validate-customisations
make test
```

**Expected output:** Each command completes with exit code `0`. Linting covers
file format, Markdown, links, shell scripts and workflow security. The
customisation check covers the frontmatter and naming of instructions, prompts,
agents and skills. Tests exercise the apply pipeline, the helper scripts and the
repository-template quality scripts. If either command fails on a clean clone,
[open an issue](https://github.com/stefaniuk/loadout/issues) with the failure
output.

## Apply workflow to downstream repos

Sync the prompt library into a target repository with a single command:

```bash
make apply dest=/absolute/path/to/target
```

What gets copied:

- `.github/agents`, `.github/instructions`, `.github/prompts`, `.github/skills`
- `.github/copilot-instructions.md`
- `.github/PULL_REQUEST_TEMPLATE.md` (only if the target has no pull request
  template under any letter case)
- `.specify/memory/constitution.md`
- `scripts/hooks/`
- `.specify/scripts/python`, `.specify/templates`
- `docs/adr/ADR-nnn_Any_Decision_Record_Template.md`,
  `docs/adr/Technology_Recommendations.md` and `docs/adr/Tech_Radar.md`
- `.copilot/analysis/.gitignore`

If the pull request template, the ADR template or
`docs/adr/Technology_Recommendations.md` is already tracked in the target
repository's own git history, as in a repository-template repository,
`apply`/`import`/`revert` leave it alone entirely - the target repo, not
loadout, owns that file - and the matching `.gitignore` entry is commented out
for that repository.

The pull request template links `.github/CONTRIBUTING.md`. Add that file to a
target that does not have one. Apply also removes the retired
`.github/skills/repository-template` skill that older loadout versions
installed, unless the target tracks it.

In a repository-template target, loadout's files are git-ignored, so the
template's `make clean CONFIRM=true` deletes them, together with any ignored
plans under `docs/superpowers/`. Run `make apply` again afterwards.

After the copy completes, review `git status` in the target repository, commit
the changes, and run `make lint && make test` to confirm everything wires up
correctly.

## Plugin installation path

The repository can be installed directly as a VS Code agent plugin, providing
skills and any repo-scoped custom agents without invoking `make apply`:

1. Open VS Code with Copilot agent mode enabled.
2. Run `Cmd+Shift+P` → **Chat: Install Plugin From Source**.
3. Enter the repository URL: `https://github.com/stefaniuk/loadout`.

After installation, skills like `/enforcement-audit` and `/architecture-docs`
appear as slash commands, and speckit skills (`/speckit-specify`,
`/speckit-plan`, etc.) become available.

If you also install the Superpowers workflow skills, set the active lane locally
with `make workflow-use ...` before you start work. The plugin install does not
remove the need to choose one workflow family per session.

> **Note:** Plugin installation provides skills and agents only. For
> project-specific instructions, templates, and include baselines, use
> `make apply`.

## Selective install

`make apply` accepts per-technology flags so you can scope what gets copied.
Pass any of the following as `name=true`:

`all`, `python`, `typescript`, `go`, `reactjs`, `rust`, `terraform`, `tauri`,
`playwright`

These per-tech flags correspond to the language packs documented in
[docs/conventions.md](conventions.md#language-packs).

Additional flags:

- `clean=true` - remove previously applied artefacts before copying.
- `subset=<csv>` - restrict the copy to named categories (see below).

To undo a previous apply in the target repo, use
`make revert dest=/path/to/target` instead (see [Revert](#revert)) -
`make apply` has no revert option.

Example - apply only the Python and Terraform packs to a target:

```bash
make apply dest=/path/to/target python=true terraform=true
```

### Subset selection

Use `subset=<csv>` to scope which categories of artefacts are copied. Omitting
`subset` (or setting `subset=all`) preserves the default full-copy behaviour.
Tokens are comma-separated, case-insensitive, and validated against a closed
set.

| Token          | Categories included                                                                                                                                                                 |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `all`          | Everything (default; equivalent to omitting `subset`)                                                                                                                               |
| `agents`       | `.github/agents/` (custom agent files, or the placeholder README when no agents are shipped)                                                                                        |
| `hooks`        | `scripts/hooks/` (workflow mode script, jq module and modes) and `.github/hooks/workflow-mode.json`                                                                                 |
| `instructions` | `.github/instructions/` (plus tech files when language flags are set)                                                                                                               |
| `prompts`      | `.github/prompts/` (plus tech enforcement prompts when language flags are set)                                                                                                      |
| `skills`       | `.github/skills/` (plus tech skills when language flags are set)                                                                                                                    |
| `specify`      | `.specify/memory`, `.specify/scripts/python`, `.specify/templates`                                                                                                                  |
| `docs`         | `docs/adr/` template, Technology Recommendations + Tech Radar                                                                                                                       |
| `project`      | Project glue: `.github/copilot-instructions.md`, `PULL_REQUEST_TEMPLATE.md`, `.vscode/settings.json`, `.gitignore`, `.copilot/analysis/.gitignore`, hook scripts                    |
| `speckit`      | Narrows `skills` to `speckit-*` and `prompts` to `review.speckit-*` files, and pulls in the `.specify/*` content. Combine with `skills` or `prompts` to widen back to the full set. |

Examples:

```bash
make apply dest=/path/to/target subset=prompts,agents
make apply dest=/path/to/target subset=speckit
make apply dest=/path/to/target subset=instructions python=true
```

#### Recommended profiles

The repository is split into a default **core** plugin pack and an optional
**speckit** sub-pack - see
[conventions.md#plugin-packs](conventions.md#plugin-packs). Three common install
profiles:

| Profile                | Command                                                                                        |
| ---------------------- | ---------------------------------------------------------------------------------------------- |
| Full install (default) | `make apply dest=/path/to/target`                                                              |
| Spec-kit only          | `make apply dest=/path/to/target subset=speckit`                                               |
| Non-spec-kit core      | `make apply dest=/path/to/target subset=agents,hooks,instructions,prompts,skills,docs,project` |

For full argument details see `scripts/apply.sh --help` and the `apply` target
in the [Makefile](../Makefile).

## Revert

The opposite of apply: remove all loadout-managed artefacts from a
previously-applied target repository.

```bash
make revert dest=/absolute/path/to/target
```

Add `dry-run=true` to preview what would be removed without changing anything.
Revert keeps the pull request template, which the target may have edited since
apply copied it. This is the only supported way to revert a previous apply -
`scripts/apply.sh` has no revert option. For full argument details see
`scripts/revert.sh --help` and the `revert` target in the
[Makefile](../Makefile).

## Import workflow from downstream repos

The inverse of apply: pull improvements made in a project repository back into
this source library.

```bash
make import dest=/absolute/path/to/project
```

The script compares prompt files in the project against the source library and
reports which files have changed. By default it prompts before copying each
changed file.

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

The repository uses Spec Kit agents, prompts, and templates from the upstream
[github/spec-kit](https://github.com/github/spec-kit) project. Local patches for
both imported Spec Kit skills and synced third-party skills are maintained in
`scripts/config/skill-patches/` and applied on top of the fetched upstream
files.

### Running sync

```bash
make speckit-sync
```

This fetches the latest Spec Kit files, applies local patches declared in
`scripts/config/skill-patches.yaml`, and writes the patched output to:

- `.github/skills/speckit-*/` (speckit skill definitions)
- `.specify/templates/` (plan, spec, tasks templates)
- `.specify/scripts/python/` (speckit helper scripts)

The resolved Spec Kit version is recorded in `.specify/.speckit-version`.

### Dry run

Preview what would change without modifying files:

```bash
dry_run=true make speckit-sync
```

### When to run

Run `make speckit-sync` after:

- Pulling updates to this repository (upstream Spec Kit may have changed)
- Modifying files in `scripts/config/skill-patches/`
- Wanting to reset speckit skills to their canonical patched state

### Speckit-sync prerequisites

The `specify` CLI must be installed. See
[github/spec-kit](https://github.com/github/spec-kit) for installation
instructions. `yq` is also required for YAML parsing.

## Managing external skills

Third-party agent skills can be cloned into `.github/skills/` from upstream
repositories. A YAML manifest at `scripts/config/skills.yaml` declares which
skills to fetch, and three make targets manage the lifecycle. The same patch
engine and manifest used by `make speckit-sync` patch every upstream skill
through the shared `scripts/config/skill-patches/` directory.

### Configuration

Each entry in `scripts/config/skills.yaml` requires `name`, `repo`, and `path`.
The `ref` defaults to `main` and `sha` is populated automatically on first sync:

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

Both append the skill to `.github/skills/<name>/`, apply any local `SKILL.md`
patch from `scripts/config/skill-patches/`, pin the resolved commit SHA in the
manifest, and update lint exclusions.

### Removing a skill

```bash
make skill-remove name=writing-plans
```

This removes the matching entry from `scripts/config/skills.yaml` and deletes
the synced `.github/skills/<name>/` directory, if present. It does not touch
`scripts/config/skill-patches.yaml`. If a patch file exists at
`scripts/config/skill-patches/<name>.patch.md`, review and remove it, along with
its matching entry under `overrides:` in `scripts/config/skill-patches.yaml`,
manually.

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

1. Each skill is shallow-cloned using git sparse checkout (only the declared
   path).
2. If `scripts/config/skill-patches/<name>.patch.md` exists, it is injected into
   the synced `SKILL.md` using the shared rules from
   `scripts/config/skill-patches.yaml` that also apply to imported Spec Kit
   skills.
3. The resolved commit SHA is written back to `scripts/config/skills.yaml`.
4. The synced skill directories are written to the managed sections of
   `.markdownlintignore`, `.prettierignore`, `.commentlengthignore` and
   `lychee.toml`, and to the `Exclude` list of `editorconfig-checker.json`, all
   under `scripts/config/` (sorted alphabetically).
5. Synced skill directories are therefore excluded from the file format,
   Markdown and link checks, and from the shell comment length rule. ShellCheck
   still lints their scripts.

### Skill sync prerequisites

`yq` is required for YAML manipulation. Install via `brew install yq`.

## Contributor setup and quality gates

Contributors follow the same `make config` flow as users, then layer the quality
commands and review checklist on top.

### Development setup

```bash
git clone https://github.com/stefaniuk/loadout.git
cd loadout
make config
```

### Quality commands

```bash
make lint                     # File format, Markdown, links, shell, workflows
make validate-customisations  # Customisation frontmatter and naming
make test                     # Every test suite under scripts/
```

### Quick checklist

1. **Raise an issue or PR** describing the planned changes.
2. **Keep artefacts in sync** - specs, plans, tasks, and docs must align.
3. **Run quality gates** - `make lint`, `make validate-customisations` and
   `make test` must pass before opening a PR. The Copilot Stop hook runs them
   for agent sessions.
4. **Follow the constitution** in `.specify/memory/constitution.md` and the
   repository-wide rules in
   [.github/copilot-instructions.md](../.github/copilot-instructions.md).

See [.github/CONTRIBUTING.md](../.github/CONTRIBUTING.md) for the full
contributor guide.

## Troubleshooting

<!--
TODO: Populate with evidence-backed recurring issues as they emerge from real
usage.
-->

No recurring issues have been documented yet. If you hit a reproducible problem,
[open an issue](https://github.com/stefaniuk/loadout/issues) so it can be
triaged and added here.

---

See also: [README](../README.md) · [Architecture](architecture.md)
