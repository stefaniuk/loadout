# Example 01 - Add the Core Make System and Pre-commit Hooks to a new repository

## Scenario metadata

- **Skill**: repository-template
- **Scenario**: Adopt the foundational capabilities of the template - Core Make System and Pre-commit Hooks - into an otherwise empty repository so that subsequent capabilities (secret scanning, markdown linting, etc.) can be layered on cleanly.
- **Repository context**: A freshly initialised Git repository with only a `README.md` and a `LICENCE.md`. No `Makefile`, no `scripts/`, no `.tool-versions`.
- **User goal**: Get a working `make help`, a `config::` target, and pre-commit hooks installed with the canonical hook set.
- **Invocation**: `Use the repository-template skill to add the Core Make System and Pre-commit Hooks capabilities`

## User prompt

> Use the repository-template skill to add the **Core Make System** and **Pre-commit Hooks** capabilities to this repository. I do not need any other capabilities yet.

## Argument and intent resolution

- Two capabilities requested: `Core Make System` (capability 1) and `Pre-commit Hooks` (capability 2).
- Critical Integration Rule honoured: Core Make System is a prerequisite for Pre-commit Hooks, so it is adopted first.
- Active context detected by `git remote get-url origin` - repository is a downstream consumer, so source files come from `.github/skills/repository-template/assets/` in the prompt catalogue.

## Context gathering

- Confirmed `Makefile`, `scripts/init.mk`, `.tool-versions`, and `scripts/config/pre-commit.yaml` do not exist in the target repository.
- Confirmed `make --version` is `3.82+`.
- Confirmed `python` is installed (required by `pre-commit`).
- Listed `assets/scripts/quality/` to identify the hook wrapper scripts that need to be copied alongside `pre-commit.yaml`.

## Execution

1. **Core Make System (capability 1)**:
   - Copied `assets/Makefile` → `Makefile`.
   - Copied `assets/scripts/init.mk` → `scripts/init.mk` (full file, no edits).
   - Verified `Makefile` includes `include scripts/init.mk` near the top.
   - Added a `config::` target that calls `$(MAKE) _install-dependencies` to wire asdf-managed tools later.
2. **Pre-commit Hooks (capability 2)**:
   - Copied `assets/scripts/config/pre-commit.yaml` → `scripts/config/pre-commit.yaml`.
   - Copied `assets/scripts/quality/{scan-secrets.sh,check-file-format.sh,check-markdown-format.sh,check-markdown-links.sh}` → `scripts/quality/`.
   - Copied supporting configs: `scripts/config/{gitleaks.toml,.gitleaksignore,editorconfig-checker.json,markdownlint.yaml,.markdownlintignore,lychee.toml}`.
   - Created `.tool-versions` with `pre-commit 4.5.1`.
   - Ran `make config` to install pre-commit via asdf.
   - Ran `make githooks-config` to install the git hook at `.git/hooks/pre-commit`.

## Output artefacts

- `Makefile` - project-specific target file with `include scripts/init.mk` and a `config::` extension.
- `scripts/init.mk` - verbatim copy of the upstream file (do not edit).
- `scripts/config/pre-commit.yaml` - hook definitions.
- `scripts/quality/{scan-secrets,check-file-format,check-markdown-format,check-markdown-links}.sh` - hook wrappers.
- `scripts/config/{gitleaks.toml,.gitleaksignore,editorconfig-checker.json,markdownlint.yaml,.markdownlintignore,lychee.toml}` - tool configs.
- `.tool-versions` - pins `pre-commit 4.5.1`.
- `.git/hooks/pre-commit` - installed by `make githooks-config`.

## Validation evidence

- `make --version | head -1` → reports `GNU Make 4.x`.
- `make help` → exits 0 and prints categorised targets including `help`, `config`, `clean`, `scan-secrets`, `check-file-format`, `check-markdown-format`, `check-markdown-links`, `check-shell-lint`.
- `pre-commit --version` → reports `pre-commit 4.5.1`.
- `test -f .git/hooks/pre-commit && echo Hooks installed` → `Hooks installed`.
- `pre-commit run --config scripts/config/pre-commit.yaml --all-files` → all hooks `Passed` or `Skipped`.

## Final assistant response

> Adopted the Core Make System and Pre-commit Hooks capabilities. `make help` now lists the standard categorised targets, and pre-commit is installed at `.git/hooks/pre-commit` with the canonical hook set (secret scan, file format, markdown format, markdown links). The repository is ready for the next capability - Secret Scanning (Gitleaks) configuration is already in place, so you can enable it via pre-commit immediately, or layer additional capabilities (Docker, Markdown linting tuning, CI/CD) on top.

## Notes and follow-ups

- Run the [Updating from the template repository](../SKILL.md#updating-from-the-template-repository) workflow periodically to pull fresh upstream assets.
- Do not partially edit `scripts/init.mk`; always replace the file in full when upgrading.
- Adopt the Docker Support capability next if container builds are in scope; it relies on the `_install-dependencies` wiring established here.
