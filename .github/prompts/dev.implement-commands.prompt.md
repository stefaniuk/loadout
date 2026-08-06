---
description: Evaluate and enforce specific development commands discipline across the codebase
---

**Input argument:** `Language` (for example `Python`, `TypeScript`, `Go`, `Rust`).

## Goal 🎯

Audit and enforce **development command discipline** across the repository. Make is the canonical interface for local development and CI, and every command must be discoverable, stable, and well documented. Ensure a top-level Makefile exists and that required targets and quality checks are present, help text is consistent, and complex logic is delegated to scripts. Align all changes to:

- [.github/instructions/makefile.instructions.md](../instructions/makefile.instructions.md)
- [repository-template skill](../skills/repository-template/SKILL.md)

## Steps 👣

### Step 1: Discover command surfaces

1. Read the [repository-template skill](../skills/repository-template/SKILL.md) and identify the **Core Make System** capability and any linked capabilities that apply.
2. Read and apply the rules in [.github/instructions/makefile.instructions.md](../instructions/makefile.instructions.md).
3. Locate all command surfaces:
   - Top-level `Makefile` and any included `*.mk` modules
   - Command scripts under `scripts/`
   - CI workflows that call build or test commands
   - Documentation that lists developer commands
4. Build a command map that links each target to its script(s) and intended purpose.

### Step 2: Assess compliance

For each Makefile and related script, assess compliance with all categories in **Implementation requirements**. Identify missing targets, inconsistent naming, undocumented variables, missing help text, and any direct tool invocations in CI that bypass Make.

### Step 3: Remediate

Apply fixes immediately using sensible defaults and the repository-template skill:

- Keep the root Makefile thin and include shared modules.
- Add missing required targets and wire them to scripts.
- Keep complex logic out of Make recipes.
- Ensure `make help` is the default and lists all public targets.
- Align local and CI commands to use the same Make targets.

### Step 4: Validate

After changes to Makefiles or scripts, run `make lint` and `make test` (or the repository equivalents) and iterate until clean.

## Implementation requirements 🛠️

### Anti-patterns (flag and fix immediately) 🚫

- Missing top-level `Makefile` or missing `help` target.
- Public targets without help descriptions or categories.
- Complex logic embedded in Make recipes (> ~5 effective lines) instead of scripts.
- Direct tool invocation in CI that bypasses Make targets.
- Missing required targets (`env`, `deps`, `build`, `format`, `lint`, `typecheck`, `test`).
- Required quality checks missing or not wired into `make lint`.
- Inconsistent or ambiguous target names (avoid mixed naming like `test_unit` vs `test-unit`).
- Destructive targets without explicit confirmation or safe defaults.
- Interactive prompts in CI paths or hidden prompts by default.
- Secrets or credentials embedded in Makefiles or echoed in logs.

### Principles 🧭

- Make is the **public contract** for local development and CI.
- Prefer small, explicit, deterministic targets.
- Delegate work to scripts; Make orchestrates only.
- Help-first UX: make targets discoverable and documented.
- Keep behaviour stable and avoid breaking changes unless requested.

### Required targets (non-negotiable) ✅

Each repository **must** provide these public targets with clear descriptions and categories:

- `env` - create or manage language/runtime environments (for example asdf, venv, node).
- `deps` - install dependencies from lock files.
- `build` - build or package artefacts.
- `format` - apply formatters (may call multiple tools).
- `lint` - run the full lint suite, **including the required quality checks** below.
- `typecheck` - run static type checks.
- `test` - run the fast test suite (typically unit tests).
- `clean` - remove build artefacts and temporary files.
- `config` - configure the development environment and install tooling (calls `_install-dependencies`).

If a target is not applicable, document why and provide a no-op target that exits successfully with a clear message.

### Mandatory quality checks ✅

At minimum, the lint suite must include these targets (or equivalent scripts) and `make lint` must invoke them:

- `lint-file-format` - file format checks (EditorConfig or equivalent).
- `lint-markdown-format` - markdown linting.
- `lint-markdown-links` - markdown internal link checks.
- `scan-secrets` - secret scanning.

### Makefile structure and UX 📖

- Root `Makefile` is thin and includes shared modules (for example `include scripts/init.mk`).
- `.DEFAULT_GOAL := help` and a readable `help` target exists.
- Public targets include descriptions and categories using the standard format.
- Use verb–noun target names with hyphens (for example `test-unit`).
- Helper targets are prefixed with `_` and kept private.

### Script delegation and shell safety 🧯

- Recipes remain small; move complex logic to scripts under `scripts/`.
- Scripts are runnable standalone and return clear exit codes.
- Fail fast; do not mask failures.
- Avoid unscoped destructive commands (for example unbounded `rm -rf`).

### Variables and configuration 🔧

- Use `?=` for defaults.
- Document required variables in help text.
- Avoid hardcoded paths; prefer variables with safe defaults.
- Never print secrets or sensitive values.

### CI/CD alignment 🧰

- CI workflows should call Make targets, not inline tool commands.
- CI targets must be non-interactive and deterministic.
- Local and CI paths should use the same target names and scripts.

### Documentation and discoverability 📚

- Developer documentation lists the canonical Make targets and their purpose.
- Help output is the primary source of truth; docs should align with it.

### Testing expectations 🧪

- If command behaviour changes, add or update tests for the script or Make target.
- Use Red → Green → Refactor when adding tests.
- Keep tests deterministic and assert exit codes.

## Output requirements 📋

1. **Findings per file**: for each category above and each of its bullet point, state one of the following statuses with a brief explanation and the emoji shown: ✅ Fully compliant, ⚠️ Partially compliant, ❌ Not compliant.
2. **Evidence links**: reference specific lines using workspace-relative Markdown links (e.g., `[src/app.ext](src/app.ext#L10-L40)`).
3. **Immediate fixes**: apply sensible defaults inline where possible; do not defer trivial remediations.
4. **Unknowns**: when information is missing, record **Unknown from code – {suggested action}** rather than guessing.
5. **Summary checklist**: after processing all CLIs, confirm overall compliance with:
   - [ ] Principles
   - [ ] Required targets
   - [ ] Mandatory quality checks
   - [ ] Makefile structure and UX
   - [ ] Script delegation and shell safety
   - [ ] Variables and configuration
   - [ ] CI/CD alignment
   - [ ] Documentation and discoverability
   - [ ] Testing expectations
