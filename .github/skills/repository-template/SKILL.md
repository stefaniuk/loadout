---
name: repository-template
description: Create code repository from template, or/and update it in parts from the content of the template that contains example of use of tools like make, pre-commit git hooks, Docker, and quality checks.
argument-hint: "Name the capability to add, remove, or improve from the repository template"
license: MIT
version: 1.0.0
---

# Repository Template Skill 🧩

This skill enables adopting, configuring, or removing capabilities from the [NHS England Tools Repository Template](https://github.com/stefaniuk/repository-template). Each capability is modular and can be applied independently.

## Source Reference 📚

All implementation files are located in the `assets/` subdirectory, which is a git subtree of the upstream repository template. When copying files to a target repository, use the contents from:

```text
.github/skills/repository-template/assets/
```

For example, to adopt `scripts/init.mk`, copy from:

```text
.github/skills/repository-template/assets/scripts/init.mk
```

to your target repository's `scripts/init.mk`.

⚠️ Distribution note: this SKILL file is mirrored verbatim across three homes - the NHS England shared GitHub Copilot prompt catalogue (similar to the [Awesome GitHub Copilot Customizations](https://github.com/github/awesome-copilot)), the upstream [Repository Template](https://github.com/stefaniuk/repository-template), and every repository created from that template. Keep the wording identical in all locations, instead of editing per environment, detect where you are and resolve paths accordingly.

🤖 Assistant behaviour: when a user asks broad questions such as _"repository template – describe how to use this skill"_, respond by summarising the capability list below, you must list all the capabilities in a tabular form as the next step and invite user to issue a follow-up prompt that names a specific capability plus an action (add, remove or improve) they want performed in their repository. This keeps replies actionable and focused on the modular building blocks.

AI assistants or automation should detect the active context before copying files. For a reliable conclusion, check the repository's git URL first (for example, `git remote get-url origin`). If it points to `stefaniuk/repository-template`, you are working inside the upstream template and can read directly from the project root.

Use the following checks after confirming the git URL:

1. If `.github/skills/repository-template/assets/` exists and contains files, use that subtree as the source (typical in the prompt catalogue or when the assets subtree is vendor-copied).
2. If the `assets/` directory exists but is empty while template root files such as `Makefile`, `scripts/`, and `docs/` are present, you are inside the `repository-template` itself-read directly from the project root.
3. If neither case applies (for example, inside a repository that was generated from the template), treat the instructions as referring to files rooted in the current repository, because the template content has already been adopted there.

When in doubt, follow the [Updating from the template repository](./SKILL.md#updating-from-the-template-repository) workflow to pull fresh assets.

### Critical Integration Rules 🚨

When adopting **any** capability from this skill, AI assistants **must** follow these rules:

1. **Core Make System is a prerequisite** - Most capabilities depend on make targets defined in `scripts/init.mk`. If `scripts/init.mk` does not exist in the target repository, adopt the [Core Make System](#1-core-make-system-gnu-make) first.
2. **Preserve `init.mk` in full** - Never partially copy `scripts/init.mk`. It contains interdependent targets (`_install-dependencies`, `githooks-config`, `clean`, etc.) that other capabilities rely on. Always copy the complete file.
3. **Ensure `include scripts/init.mk`** - The repository's `Makefile` must contain `include scripts/init.mk` near the top. Without this, make targets from `init.mk` are unavailable.
4. **Wire up `config::` for dependencies** - When adopting capabilities that require asdf-managed tools (pre-commit, gitleaks, etc.):
   - Add the tool to `.tool-versions`
   - Ensure the `Makefile` has a `config::` target that calls `$(MAKE) _install-dependencies`
   - Example:

     ```makefile
     config:: # Configure development environment @Configuration
         $(MAKE) _install-dependencies
     ```

5. **Verify after adoption** - Always run the verification commands listed in each capability section to confirm correct integration.

## Scope and non-goals 🎯

**Scope**:

- Provide modular, copyable capabilities for repository setup, quality checks, tooling, and documentation
- Standardise local and CI workflows through Make targets and shared scripts
- Offer repeatable, deterministic setup via pinned tool versions

**Non-goals**:

- Full application scaffolding (use the feature-specific skills for that)
- Windows-native or PowerShell-first workflows
- Opinionated runtime or framework choices beyond the capabilities listed below

## Compatibility 🧩

- **Supported**: macOS and Linux
- **Supported via WSL**: Windows (WSL2 with a Linux distribution)
- **Not supported**: Windows-native shells and PowerShell workflows
- **Core tooling expectations**: GNU Make 3.82+ and a POSIX-compatible shell
- **Optional tooling**: asdf for version pinning, Docker/Podman for container-related capabilities

## Prerequisites ✅

- **GNU Make 3.82+** (macOS users may need `brew install make` and to update `$PATH`)
- **Docker or Podman** for container-related tasks
- **asdf** for pinned tool versions (optional if you manage versions another way)
- **Python** required for Git hooks
- **jq** for JSON processing in scripts
- **GNU sed, GNU grep, GNU coreutils, GNU binutils** for script compatibility (especially on macOS)

## Troubleshooting 🛠️

- **Make target not found**: Ensure `scripts/init.mk` exists and `include scripts/init.mk` is present near the top of `Makefile`.
- **asdf command missing**: Install asdf or remove asdf-specific steps from the capability you are adopting.
- **Pre-commit hooks do not run**: Run `make githooks-config` and confirm `.git/hooks/pre-commit` exists.
- **Docker checks fail**: Confirm Docker/Podman is installed and running, then rerun `make docker-lint`.

## Upgrade guidance 🔄

When updating a repository that already uses this template:

1. Pull fresh assets using `./.github/skills/repository-template/scripts/git-clone-repository-template.sh`
2. Compare changed files and copy only the capabilities you use
3. Re-run `make config` and any verification steps for the updated capabilities
4. Review CI workflows and `.tool-versions` for version pin changes
5. You can ask GitHub Copilot to use this skill to perform the upgrade for you

## Security considerations 🔐

- Do not commit secrets; rely on secret scanning and ignore lists for known false positives
- Keep CI credentials scoped to the minimum required permissions
- Treat `.tool-versions` and configuration files as security-sensitive inputs
- Review new third-party tools before adoption and pin versions where possible

## FAQ ❓

**Does this support Windows?**
No. Use WSL2 with a Linux distribution if you are on Windows.

**Can I adopt a single capability?**
Yes. Each capability is modular; copy only the files it references.

**Do I need asdf?**
Only for capabilities that rely on version pinning; it is optional otherwise.

**Where do the source files live?**
They are in the `assets/` subtree under this skill.

## Quick Reference 🧠

| Capability                                                      | Purpose                      | Key Files                                                                      |
| --------------------------------------------------------------- | ---------------------------- | ------------------------------------------------------------------------------ |
| [Core Make System](#1-core-make-system-gnu-make)                | Standardised task runner     | `Makefile`, `scripts/init.mk`                                                  |
| [Pre-commit Hooks](#2-pre-commit-hooks)                         | Git hooks framework          | `scripts/config/pre-commit.yaml`, `scripts/quality/`                           |
| [Secret Scanning](#3-secret-scanning-gitleaks)                  | Prevent credential leaks     | `scripts/quality/scan-secrets.sh`, `scripts/config/gitleaks.toml`              |
| [File Format Checking](#4-file-format-checking-editorconfig)    | Consistent file formatting   | `.editorconfig`, `scripts/quality/check-file-format.sh`                        |
| [Markdown Linting](#5-markdown-linting-markdownlint-cli)        | Documentation quality        | `scripts/quality/check-markdown-format.sh`, `scripts/config/markdownlint.yaml` |
| [Markdown Link Checking](#6-markdown-link-checking-lychee)      | Validate Markdown links      | `scripts/quality/check-markdown-links.sh`, `scripts/config/lychee.toml`        |
| [Shell Script Linting](#7-shell-script-linting-shellcheck)      | Bash quality checks          | `scripts/quality/check-shell-lint.sh`                                          |
| [Docker Support](#8-docker-support-dockerpodman)                | Container build/run/lint     | `scripts/docker/`, `scripts/config/hadolint.yaml`                              |
| [GitHub Actions CI/CD](#9-github-actions-cicd)                  | Pipeline workflows           | `.github/workflows/`, `.github/actions/`                                       |
| [Dependabot](#10-dependabot)                                    | Automated dependency updates | `.github/dependabot.yaml`                                                      |
| [VS Code Integration](#11-vs-code-integration)                  | Editor configuration         | `.vscode/`, `project.code-workspace`                                           |
| [Tool Version Management](#12-tool-version-management-asdf)     | Reproducible toolchain       | `.tool-versions`                                                               |
| [GitHub Repository Templates](#13-github-repository-templates)  | Issue/PR/security templates  | `.github/ISSUE_TEMPLATE/`, `.github/pull_request_template.md`                  |
| [Documentation Structure](#14-documentation-structure-markdown) | ADRs and guides              | `docs/adr/`, `docs/guides/`                                                    |

---

## Capabilities 🧰

### 1. Core Make System (GNU Make)

**Purpose**: Provides a standardised task runner with self-documenting help, common targets, and extensibility.

**Benefits**: A single, well-documented entry point lowers cognitive load and aligns local and CI workflows. It improves reproducibility and makes automation safer because commands are deterministic and discoverable.

**Problem it solves**: Teams often grow ad-hoc scripts and tribal knowledge for routine tasks, which leads to inconsistent results and slow onboarding.

**How it solves it**: The core Makefile and init module provide stable targets, shared defaults, and explicit configuration hooks, so every engineer and pipeline uses the same contract.

**Dependencies**: GNU Make 3.82+

**Source files** (in `assets/`):

- [`Makefile`](assets/Makefile) - Project-specific targets (customise this)
- [`scripts/init.mk`](assets/scripts/init.mk) - Common targets and infrastructure (do not edit)

**Key make targets**:

```bash
make help              # Show all available targets with descriptions
make config            # Configure development environment
make clean             # Remove generated files
make list-variables    # Debug: show all make variables
make scan-secrets      # Scan for secrets
make check-file-format # Check file format compliance
make check-markdown-format # Check Markdown formatting
make check-markdown-links # Check Markdown links
make check-shell-lint  # Lint shell scripts
make version-create-effective-file # Create .version from VERSION
```

**Template project targets (from `assets/Makefile`)**:

- `make env` - Set up project environment (placeholder)
- `make deps` - Install project dependencies (placeholder)
- `make format` - Auto-format code (placeholder)
- `make lint-file-format`, `make lint-markdown-format`, `make lint-markdown-links`, `make lint-shell` - Run individual checks
- `make lint` - Runs all four lint targets above
- `make typecheck`, `make test`, `make build`, `make publish`, `make deploy` - Project-specific placeholders you implement

**To adopt**:

1. Copy `assets/Makefile` and `assets/scripts/init.mk` to your repository
2. Ensure `Makefile` contains `include scripts/init.mk` near the top (after any variable definitions)
3. Customise the `Makefile` with your project-specific targets
4. Add `@Pipeline`, `@Operations`, `@Configuration`, `@Development`, `@Testing`, `@Quality`, or `@Others` annotations to target comments for categorisation
5. Add a `config::` target that calls `$(MAKE) _install-dependencies` to ensure asdf tools are installed:

   ```makefile
   config:: # Configure development environment @Configuration
       $(MAKE) _install-dependencies
   ```

**Essential make targets from `init.mk`** (do not remove or modify):

| Target                          | Purpose                                                                                                    |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `help`                          | Self-documenting target list                                                                               |
| `config`                        | Base configuration (extended via `config::`)                                                               |
| `clean`                         | Base cleanup (extended via `clean::`)                                                                      |
| `scan-secrets`                  | Scan for secrets using the gitleaks wrapper                                                                |
| `check-file-format`             | Check EditorConfig compliance                                                                              |
| `check-markdown-format`         | Check Markdown formatting                                                                                  |
| `check-markdown-links`          | Check Markdown links                                                                                       |
| `check-shell-lint`              | Lint shell scripts (fails on errors, excludes `.github/skills/repository-template/` and `.specify/` paths) |
| `version-create-effective-file` | Create the `.version` file from `VERSION` placeholders                                                     |
| `_install-dependencies`         | Install all tools from `.tool-versions` via asdf                                                           |
| `_install-dependency`           | Install a single asdf tool                                                                                 |
| `githooks-config`               | Install pre-commit hooks                                                                                   |
| `githooks-run`                  | Run all pre-commit hooks                                                                                   |

**Verification** (run after adoption):

```bash
# Check make is available and version is 3.82+
make --version | head -1

# Verify help target works and shows categorised output
make help

# Expected: Exit code 0, output includes target names with descriptions
# Success indicator: Output contains "help" target and category headers
```

**To remove**: Delete `Makefile` and `scripts/init.mk`

---

### 2. Pre-commit Hooks

**Purpose**: Framework for running quality checks before commits using the `pre-commit` tool.

**Benefits**: Early feedback reduces rework and keeps the main branch clean. It also shortens CI cycles by catching simple issues before a push.

**Problem it solves**: Quality checks run late or inconsistently, so defects slip into review and break pipelines.

**How it solves it**: Pre-commit runs the same repo-defined checks locally through Make targets and shared scripts, ensuring the local and CI gates are aligned.

**Dependencies**: Python, pre-commit (`pip install pre-commit`), make

**Source files** (in `assets/`):

- [`scripts/config/pre-commit.yaml`](assets/scripts/config/pre-commit.yaml) - Hook definitions
- [`scripts/quality/scan-secrets.sh`](assets/scripts/quality/scan-secrets.sh) - Secret scan hook wrapper
- [`scripts/quality/check-file-format.sh`](assets/scripts/quality/check-file-format.sh) - File format hook wrapper
- [`scripts/quality/check-markdown-format.sh`](assets/scripts/quality/check-markdown-format.sh) - Markdown format hook wrapper
- [`scripts/quality/check-markdown-links.sh`](assets/scripts/quality/check-markdown-links.sh) - Markdown link hook wrapper
- [`scripts/config/gitleaks.toml`](assets/scripts/config/gitleaks.toml) - Gitleaks configuration
- [`scripts/config/.gitleaksignore`](assets/scripts/config/.gitleaksignore) - Gitleaks ignore list
- [`scripts/config/editorconfig-checker.json`](assets/scripts/config/editorconfig-checker.json) - EditorConfig checker configuration
- [`scripts/config/markdownlint.yaml`](assets/scripts/config/markdownlint.yaml) - Markdownlint configuration
- [`scripts/config/.markdownlintignore`](assets/scripts/config/.markdownlintignore) - Markdownlint ignore list
- [`scripts/config/lychee.toml`](assets/scripts/config/lychee.toml) - Lychee configuration

**Configuration**:

```bash
make githooks-config   # Install hooks
make githooks-run      # Run all hooks manually
```

**Available hooks** (each can be enabled/disabled in `pre-commit.yaml`):

- `scan-secrets` - Gitleaks secret scanning
- `check-file-format` - EditorConfig compliance
- `check-markdown-format` - Markdown linting
- `check-markdown-links` - Markdown link checking

**To adopt**:

1. **Prerequisite**: Ensure [Core Make System](#1-core-make-system-gnu-make) is already adopted
2. Copy `scripts/config/pre-commit.yaml`
3. Copy `scripts/quality/` and `scripts/config/` (the hooks call make targets backed by these scripts and configs)
4. Add `pre-commit` to `.tool-versions` (e.g., `pre-commit 4.5.1`)
5. Ensure `Makefile` has `config::` target that calls `$(MAKE) _install-dependencies`:

   ```makefile
   config:: # Configure development environment @Configuration
       $(MAKE) _install-dependencies
   ```

6. Run `make config` to install pre-commit via asdf
7. Run `make githooks-config` to install the git hooks

**Verification** (run after adoption):

```bash
# Check pre-commit is installed
pre-commit --version

# Verify hooks are configured
test -f .git/hooks/pre-commit && echo "Hooks installed" || echo "Hooks not installed"

# Run hooks manually (should complete without errors on clean repo)
pre-commit run --config scripts/config/pre-commit.yaml --all-files

# Expected: Exit code 0 if all checks pass, non-zero if issues found
# Success indicator: "Passed" or "Skipped" for each hook
```

**To remove**:

1. Run `pre-commit uninstall`
2. Delete `scripts/config/pre-commit.yaml` and remove any hook references to it

---

### 3. Secret Scanning (Gitleaks)

**Purpose**: Prevent hardcoded secrets from being committed to the repository.

**Benefits**: It reduces the risk of credential exposure and downstream incidents, and supports compliance expectations for secret hygiene.

**Problem it solves**: Manual review cannot reliably spot secrets, and a single leak can force rotation and downtime.

**How it solves it**: Gitleaks scans staged changes and history with a tuned rule set and allowlist, producing deterministic results that can be enforced in hooks and CI.

**Dependencies**: Gitleaks (native or Docker)

**Source files** (in `assets/`):

- [`scripts/quality/scan-secrets.sh`](assets/scripts/quality/scan-secrets.sh) - Scanner wrapper
- [`scripts/config/gitleaks.toml`](assets/scripts/config/gitleaks.toml) - Gitleaks configuration
- [`scripts/config/.gitleaksignore`](assets/scripts/config/.gitleaksignore) - Ignore file for false positives

**Optional baseline file**:

- If you create `scripts/config/.gitleaks-baseline.json`, the wrapper will include it automatically.

**Configuration** (`scripts/config/gitleaks.toml`):

- Extends default Gitleaks rules
- Custom IPv4 detection with private network allowlist
- Excludes lock files (`poetry.lock`, `yarn.lock`)

**Check modes**:

```bash
check=staged-changes ./scripts/quality/scan-secrets.sh   # Pre-commit (default)
check=last-commit ./scripts/quality/scan-secrets.sh      # Last commit only
check=whole-history ./scripts/quality/scan-secrets.sh    # Full repository history
```

**Usage**:

```bash
make scan-secrets check=whole-history
check=staged-changes ./scripts/quality/scan-secrets.sh
```

**To adopt**:

1. Copy `scripts/quality/scan-secrets.sh`, `scripts/config/gitleaks.toml`, and `scripts/config/.gitleaksignore`
2. Add `gitleaks` to `.tool-versions` (e.g., `gitleaks 8.30.0`) for native execution
3. Optionally add Docker image entry to `.tool-versions` for Docker fallback:

   ```text
   # docker/ghcr.io/gitleaks/gitleaks v8.30.0@sha256:691af3c7c5a48b16f187ce3446d5f194838f91238f27270ed36eef6359a574d9 # SEE: https://github.com/gitleaks/gitleaks/pkgs/container/gitleaks
   ```

4. Run `asdf install` to install gitleaks (if using native)
5. Add to `pre-commit.yaml` or run standalone

**Verification** (run after adoption):

```bash
# Check gitleaks is available
gitleaks version

# Run secret scan on staged changes (default mode)
./scripts/quality/scan-secrets.sh

# Or scan the whole repository history
check=whole-history ./scripts/quality/scan-secrets.sh

# Alternative: run gitleaks directly
gitleaks detect --config scripts/config/gitleaks.toml --source . --verbose --redact

# Expected: Exit code 0 if no secrets found
# Success indicator: "no leaks found" or empty output
```

**To remove**: Delete the files and remove from `pre-commit.yaml`

---

### 4. File Format Checking (EditorConfig)

**Purpose**: Ensure consistent file formatting (indentation, line endings, charset) across the codebase.

**Benefits**: Consistent formatting improves readability, reduces merge noise, and keeps diffs focused on behaviour.

**Problem it solves**: Inconsistent whitespace and line endings cause churn and make code review harder.

**How it solves it**: EditorConfig defines the contract and the checker enforces it over the chosen file scope, so formatting stays stable across editors and platforms.

**Dependencies**: editorconfig-checker (native or Docker)

**Source files** (in `assets/`):

- [`.editorconfig`](assets/.editorconfig) - Format rules
- [`scripts/quality/check-file-format.sh`](assets/scripts/quality/check-file-format.sh) - Checker wrapper
- [`scripts/config/editorconfig-checker.json`](assets/scripts/config/editorconfig-checker.json) - Checker configuration

**Configuration** (`.editorconfig`):

```ini
[*]
charset = utf-8
end_of_line = lf
indent_size = 2
indent_style = space
insert_final_newline = true
trim_trailing_whitespace = true

[*.py]
indent_size = 4

[{Makefile,*.mk}]
indent_style = tab
```

**Check modes**:

```bash
check=all ./scripts/quality/check-file-format.sh                # All files
check=staged-changes ./scripts/quality/check-file-format.sh     # Staged only
check=working-tree-changes ./scripts/quality/check-file-format.sh # Working tree only
check=branch ./scripts/quality/check-file-format.sh             # Changes since branching
```

**Extra options**:

- `BRANCH_NAME=origin/main` to override the branch used for `check=branch`
- `dry_run=true` to list issues without failing the check
- `FORCE_USE_DOCKER=true` to force Docker execution
- `VERBOSE=true` to show commands

**Usage**:

```bash
make check-file-format check=all
check=branch ./scripts/quality/check-file-format.sh
```

**To adopt**:

1. Copy `.editorconfig`, `scripts/quality/check-file-format.sh`, and `scripts/config/editorconfig-checker.json`
2. Add Docker image entry to `.tool-versions` for editorconfig-checker:

   ```text
   # docker/mstruebing/editorconfig-checker v3.6@sha256:af556694c3eb0a16b598efbe84c1171d40dfb779fdac6f01b89baedde065556f # SEE: https://hub.docker.com/r/mstruebing/editorconfig-checker/tags
   ```

3. Install VS Code extension `editorconfig.editorconfig`

**Verification** (run after adoption):

```bash
# Check editorconfig-checker is available
editorconfig-checker --version || ec --version

# Run format check on all files
check=all ./scripts/quality/check-file-format.sh

# Alternative: run checker directly
editorconfig-checker -config scripts/config/editorconfig-checker.json

# Expected: Exit code 0 if all files comply
# Success indicator: No output (silent success) or "No issues found"
```

**To remove**: Delete the files

---

### 5. Markdown Linting (markdownlint-cli)

**Purpose**: Enforce consistent Markdown formatting and best practices.

**Benefits**: It keeps documentation consistent and easy to render across tooling, improving trust in the docs.

**Problem it solves**: Markdown style drift leads to broken layouts, noisy diffs, and unclear guidance.

**How it solves it**: markdownlint applies a shared ruleset and ignore list, giving a repeatable check in local workflows and CI.

**Dependencies**: markdownlint-cli (native or Docker)

**Source files** (in `assets/`):

- [`scripts/quality/check-markdown-format.sh`](assets/scripts/quality/check-markdown-format.sh) - Linter wrapper
- [`scripts/config/markdownlint.yaml`](assets/scripts/config/markdownlint.yaml) - Rule configuration
- [`scripts/config/.markdownlintignore`](assets/scripts/config/.markdownlintignore) - Ignore patterns

**Configuration** (`scripts/config/markdownlint.yaml`):

```yaml
MD010: # Allow hard tabs in makefile code blocks
  ignore_code_languages: [makefile]
MD013: false # Disable line length
MD024: # Allow duplicate headings in siblings
  siblings_only: true
MD029:
  style: ordered
MD033: false # Allow inline HTML
MD036: false # Allow emphasis instead of headings
MD041: false # Allow files without an H1
```

**Check modes**:

```bash
check=all ./scripts/quality/check-markdown-format.sh                 # All markdown files
check=staged-changes ./scripts/quality/check-markdown-format.sh      # Staged only
check=working-tree-changes ./scripts/quality/check-markdown-format.sh # Working tree only
check=branch ./scripts/quality/check-markdown-format.sh              # Changes since branching
```

**Extra options**:

- `BRANCH_NAME=origin/main` to override the branch used for `check=branch`
- `FORCE_USE_DOCKER=true` to force Docker execution
- `VERBOSE=true` to show commands

**Usage**:

```bash
make check-markdown-format check=all
check=branch ./scripts/quality/check-markdown-format.sh
```

**To adopt**:

1. Copy `scripts/quality/check-markdown-format.sh`, `scripts/config/markdownlint.yaml`, and `scripts/config/.markdownlintignore`
2. Add Docker image entry to `.tool-versions` for markdownlint-cli:

   ```text
   # docker/ghcr.io/igorshubovych/markdownlint-cli v0.47.0@sha256:9f06c8c9a75aa08b87b235b66d618f7df351f09f08faf703177f670e38ee6511 # SEE: https://github.com/igorshubovych/markdownlint-cli/pkgs/container/markdownlint-cli
   ```

3. Install VS Code extension `davidanson.vscode-markdownlint`

**Verification** (run after adoption):

```bash
# Check markdownlint is available
markdownlint --version

# Run on all markdown files
check=all ./scripts/quality/check-markdown-format.sh

# Alternative: run markdownlint directly
markdownlint --config scripts/config/markdownlint.yaml --ignore-path scripts/config/.markdownlintignore "**/*.md"

# Expected: Exit code 0 if all files pass
# Success indicator: No output (silent success)
```

**To remove**: Delete the files

---

### 6. Markdown Link Checking (Lychee)

**Purpose**: Validate Markdown links for broken or unreachable references.

**Benefits**: Reliable links keep docs usable and reduce support overhead, especially for onboarding and audits.

**Problem it solves**: Link rot and typos silently break guidance, which wastes time and undermines confidence.

**How it solves it**: Lychee scans Markdown files using a defined configuration and scope, so broken links are detected early and consistently.

**Dependencies**: Lychee (native or Docker)

**Source files** (in `assets/`):

- [`scripts/quality/check-markdown-links.sh`](assets/scripts/quality/check-markdown-links.sh) - Link checker wrapper
- [`scripts/config/lychee.toml`](assets/scripts/config/lychee.toml) - Lychee configuration

**Configuration** (`scripts/config/lychee.toml`):

- Uses a tuned set of defaults for reliability and reduced noise
- Centralises link exclusions and timeouts for consistent results

**Check modes**:

```bash
check=all ./scripts/quality/check-markdown-links.sh                 # All markdown files
check=staged-changes ./scripts/quality/check-markdown-links.sh      # Staged only
check=working-tree-changes ./scripts/quality/check-markdown-links.sh # Working tree only
check=branch ./scripts/quality/check-markdown-links.sh              # Changes since branching
```

**Extra options**:

- `BRANCH_NAME=origin/main` to override the branch used for `check=branch`
- `FORCE_USE_DOCKER=true` to force Docker execution
- `VERBOSE=true` to show commands

**Usage**:

```bash
make check-markdown-links check=all
check=branch ./scripts/quality/check-markdown-links.sh
```

**To adopt**:

1. Copy `scripts/quality/check-markdown-links.sh` and `scripts/config/lychee.toml`
2. Optionally pin the Docker image in `.tool-versions` using the standard format:

   ```text
   # docker/lycheeverse/lychee <tag>@<digest> # SEE: https://github.com/lycheeverse/lychee
   ```

**Verification** (run after adoption):

```bash
# Check lychee is available
lychee --version

# Run on all markdown files
check=all ./scripts/quality/check-markdown-links.sh

# Alternative: run lychee directly
lychee --config scripts/config/lychee.toml --no-progress --quiet "**/*.md"

# Expected: Exit code 0 if all links are valid
# Success indicator: No output (silent success)
```

**To remove**: Delete the files

---

### 7. Shell Script Linting (ShellCheck)

**Purpose**: Static analysis for shell scripts to catch common bugs and enforce best practices.

**Benefits**: Static analysis catches common shell pitfalls and improves script reliability, which is critical for automation and CI.

**Problem it solves**: Shell scripts fail in subtle ways due to quoting, globbing, and error handling quirks.

**How it solves it**: ShellCheck runs via a wrapper that standardises execution and tooling, producing consistent findings for developers and pipelines.

**Dependencies**: ShellCheck (native or Docker)

**Source files** (in `assets/`):

- [`scripts/quality/check-shell-lint.sh`](assets/scripts/quality/check-shell-lint.sh) - ShellCheck wrapper

**Configuration**:

- Uses ShellCheck default rules with no repo-specific overrides
- Runs natively when available, with a Docker fallback for parity

**Check modes**:

- All scripts: `make check-shell-lint` (scans every `*.sh` in the repo, excluding `.github/skills/repository-template/` and `.specify/` paths)
- Single script: `file=path/to/script.sh ./scripts/quality/check-shell-lint.sh`

**Extra options**:

- `FORCE_USE_DOCKER=true` to force Docker execution
- `VERBOSE=true` to show commands

**Usage**:

```bash
file=path/to/script.sh ./scripts/quality/check-shell-lint.sh
make check-shell-lint       # Lint all .sh files in the repo
```

**Verification** (run after adoption):

```bash
# Check shellcheck is available
shellcheck --version

# Run on a specific script
file=scripts/quality/check-shell-lint.sh ./scripts/quality/check-shell-lint.sh

# Alternative: run shellcheck directly
make check-shell-lint

# Expected: Exit code 0 if no issues, non-zero with error details if issues found
# Success indicator: No output (silent success) or warnings/errors listed
```

**To adopt**:

1. Copy `scripts/quality/check-shell-lint.sh`
2. Add Docker image entry to `.tool-versions` for shellcheck:

   ```text
   # docker/koalaman/shellcheck v0.11.0@sha256:61862eba1fcf09a484ebcc6feea46f1782532571a34ed51fedf90dd25f925a8d # SEE: https://hub.docker.com/r/koalaman/shellcheck/tags
   ```

**To remove**: Delete the file

---

### 8. Docker Support (Docker/Podman)

**Purpose**: Build, lint, run, and manage Docker images with standardised metadata.

**Benefits**: Standardised build and lint steps improve image security, reproducibility, and operational consistency.

**Problem it solves**: Ad-hoc Dockerfiles and build commands lead to drift, insecure defaults, and slow debugging.

**How it solves it**: Shared make targets and libraries encode best practices, apply metadata, and enforce hadolint checks with version-pinned tooling.

**Dependencies**: Docker, hadolint (for linting)

**Source files** (in `assets/`):

- [`scripts/docker/docker.mk`](assets/scripts/docker/docker.mk) - Make targets
- [`scripts/docker/docker.lib.sh`](assets/scripts/docker/docker.lib.sh) - Shell functions library
- [`scripts/docker/dockerfile-linter.sh`](assets/scripts/docker/dockerfile-linter.sh) - Hadolint wrapper
- [`scripts/docker/Dockerfile.metadata`](assets/scripts/docker/Dockerfile.metadata) - OCI label template
- [`scripts/config/hadolint.yaml`](assets/scripts/config/hadolint.yaml) - Hadolint configuration
- [`scripts/docker/dgoss.sh`](assets/scripts/docker/dgoss.sh) - Container testing with dgoss
- [`scripts/docker/tests/`](assets/scripts/docker/tests/) - Docker test fixtures

**Make targets**:

```bash
make docker-bake-dockerfile # Create Dockerfile.effective
make docker-build           # Build image with metadata
make docker-lint            # Lint Dockerfile with hadolint
make docker-push            # Push to registry
make docker-run             # Run container
make docker-shellscript-lint # Lint Docker module shell scripts
make docker-test-suite-run  # Run Docker test suite
```

**Features**:

- Automatic `Dockerfile.effective` generation with version baking
- Version metadata generation via `.version` created from `VERSION` placeholders
- OCI-compliant image labels (title, version, git info, build date)
- Trusted registry allowlist in hadolint config
- Test suite support with dgoss
- **Docker image version pinning via `.tool-versions`** - see [Tool Version Management (asdf)](#12-tool-version-management-asdf) for the extended format

**Docker image versioning**:

Docker image versions can be pinned in `.tool-versions` using an extended comment format. The `docker-get-image-version-and-pull` function in `docker.lib.sh` parses these entries, pulls images by digest for reproducibility, and tags them locally for caching.

```text
# docker/ghcr.io/gitleaks/gitleaks v8.30.0@sha256:691af3c7c5a48b16f187ce3446d5f194838f91238f27270ed36eef6359a574d9 # SEE: https://github.com/gitleaks/gitleaks/pkgs/container/gitleaks
```

See [section 12](#12-tool-version-management-asdf) for full format documentation.

**To adopt**:

1. Copy the entire `scripts/docker/` directory
2. Copy `scripts/config/hadolint.yaml`
3. Add Docker image entry to `.tool-versions` for hadolint:

   ```text
   # docker/hadolint/hadolint 2.14.0-alpine@sha256:7aba693c1442eb31c0b015c129697cb3b6cb7da589d85c7562f9deb435a6657c # SEE: https://hub.docker.com/r/hadolint/hadolint/tags
   ```

4. Create your Dockerfile in `infrastructure/images/`
5. Optionally add additional Docker image pins to `.tool-versions`

**Verification** (run after adoption):

```bash
# Check Docker is available
docker --version

# Check hadolint is available (for Dockerfile linting)
hadolint --version || docker run --rm hadolint/hadolint hadolint --version

# Lint a Dockerfile
file=path/to/Dockerfile ./scripts/docker/dockerfile-linter.sh

# Alternative: run hadolint directly
hadolint --config scripts/config/hadolint.yaml path/to/Dockerfile

# Verify docker make targets exist
make help | grep -E "docker-bake-dockerfile|docker-build|docker-lint|docker-push|docker-run|docker-shellscript-lint|docker-test-suite-run"

# Expected: Exit code 0 if Dockerfile is valid
# Success indicator: No lint errors, make targets visible in help
```

**To remove**: Delete `scripts/docker/` and remove `include scripts/docker/docker.mk` from `scripts/init.mk`

---

### 9. GitHub Actions CI/CD

**Purpose**: Multi-stage CI/CD pipeline with reusable workflows and composite actions.

**Benefits**: A predictable pipeline enforces quality gates and makes delivery repeatable, improving reliability and auditability.

**Problem it solves**: Manual or inconsistent CI steps cause flaky results and slow down releases.

**How it solves it**: Reusable workflows and composite actions provide a single source of truth for stages and checks, reducing duplication and drift.

**Dependencies**: GitHub repository with Actions enabled; GitHub CLI available on runners (used to detect pull requests); `contents: read` and `pull-requests: read` permissions for the metadata job

**Source files** (in `assets/`):

- [`assets/.github/workflows/cicd-1-pull-request.yaml`](assets/.github/workflows/cicd-1-pull-request.yaml) - Main PR workflow
- [`assets/.github/workflows/cicd-2-publish.yaml`](assets/.github/workflows/cicd-2-publish.yaml) - Publish workflow
- [`assets/.github/workflows/cicd-3-deploy.yaml`](assets/.github/workflows/cicd-3-deploy.yaml) - Deployment workflow
- [`assets/.github/workflows/stage-1-commit.yaml`](assets/.github/workflows/stage-1-commit.yaml) - Commit stage (quality checks)
- [`assets/.github/workflows/stage-2-test.yaml`](assets/.github/workflows/stage-2-test.yaml) - Test stage
- [`assets/.github/workflows/stage-3-build.yaml`](assets/.github/workflows/stage-3-build.yaml) - Build stage
- [`assets/.github/workflows/stage-4-acceptance.yaml`](assets/.github/workflows/stage-4-acceptance.yaml) - Acceptance stage
- [`assets/.github/actions/`](assets/.github/actions/) - Composite actions for each check

**Metadata job**:

- Captures build timestamps, epoch, Node.js/Python versions (when present in `.tool-versions`), and generates `.version`
- Detects whether a pull request exists using `gh pr list` to gate downstream stages

**Pipeline stages**:

1. **Commit stage** (~2 min): Secret scan, file format, Markdown format, Markdown links
2. **Test stage** (~5 min): Unit tests (`make test` placeholder)
3. **Build stage** (~3 min): Artefact build placeholders (runs only when a PR exists or on opened/reopened PR events)
4. **Acceptance stage** (~10 min): Environment setup, contract/security/UI/performance/integration/accessibility/load tests, then teardown (runs only when a PR exists or on opened/reopened PR events)

**Composite actions** (`.github/actions/`):

- `scan-secrets/`
- `check-file-format/`
- `check-markdown-format/`
- `check-markdown-links/`

**To adopt**:

1. Copy `.github/workflows/` and `.github/actions/`
2. Customise stages for your project
3. Configure secrets in GitHub repository settings

**Verification** (run after adoption):

```bash
# Verify workflow files exist
ls -la .github/workflows/*.yaml

# Validate YAML syntax (requires yq or python)
yq eval '.' .github/workflows/cicd-1-pull-request.yaml > /dev/null && echo "Valid YAML"

# Check for composite actions
ls -la .github/actions/

# Verify workflow references valid actions
grep -r "uses:.*\.github/actions/" .github/workflows/

# Expected: Workflow files present, valid YAML syntax
# Success indicator: Files exist, no YAML parse errors
# Note: Full verification requires pushing to GitHub and observing Actions tab
```

**To remove**: Delete `.github/workflows/` and `.github/actions/`

---

### 10. Dependabot

**Purpose**: Automated dependency update pull requests for multiple package ecosystems.

**Benefits**: Automated updates reduce security exposure and maintenance effort, while keeping changes reviewable.

**Problem it solves**: Dependencies age quickly, and manual updates are often missed or deferred.

**How it solves it**: Dependabot raises scheduled PRs per ecosystem so teams can review and merge controlled updates.

**Dependencies**: GitHub repository with Dependabot enabled

**Source files** (in `assets/`):

- [`.github/dependabot.yaml`](assets/.github/dependabot.yaml) - Dependabot configuration

**Configured ecosystems**:

| Ecosystem        | Schedule | Purpose                    |
| ---------------- | -------- | -------------------------- |
| `docker`         | Daily    | Base image updates         |
| `github-actions` | Daily    | Action version updates     |
| `npm`            | Daily    | Node.js dependency updates |
| `pip`            | Daily    | Python dependency updates  |

**Features**:

- Daily update checks for all ecosystems
- Automatic PR creation for outdated dependencies
- Security vulnerability alerts and fixes

**To adopt**:

1. Copy `.github/dependabot.yaml`
2. Remove ecosystems not used by your project
3. Adjust schedule frequency if needed (daily, weekly, monthly)

**Verification** (run after adoption):

```bash
# Check dependabot config exists
test -f .github/dependabot.yaml && echo "Dependabot config OK"

# Validate YAML syntax
yq eval '.' .github/dependabot.yaml > /dev/null && echo "Valid YAML"

# Check configured ecosystems
yq eval '.updates[].package-ecosystem' .github/dependabot.yaml

# Expected: File exists with valid YAML
# Success indicator: Dependabot PRs appear in repository after enabling
# Note: Full verification requires pushing to GitHub and checking Insights > Dependency graph
```

**To remove**: Delete `.github/dependabot.yaml`

---

### 11. VS Code Integration

**Purpose**: Standardised editor configuration and recommended extensions.

**Benefits**: Consistent editor settings reduce formatting churn and improve onboarding speed.

**Problem it solves**: Different local editor setups cause inconsistent outputs and avoidable lint failures.

**How it solves it**: Workspace settings and recommended extensions align tooling behaviour, making local results match CI expectations.

**Dependencies**: Visual Studio Code (or a compatible editor that honours the workspace files)

**Source files** (in `assets/`):

- [`.vscode/extensions.json`](assets/.vscode/extensions.json) - Recommended extensions
- [`.vscode/settings.json`](assets/.vscode/settings.json) - Workspace settings
- [`project.code-workspace`](assets/project.code-workspace) - Multi-root workspace file

**Recommended extensions**:

- `alefragnani.bookmarks` - Bookmarks
- `davidanson.vscode-markdownlint` - Markdown linting
- `dbaeumer.vscode-eslint` - ESLint
- `eamodio.gitlens` - Git enhancements
- `editorconfig.editorconfig` - EditorConfig support
- `esbenp.prettier-vscode` - Formatting support
- `github.github-vscode-theme` - GitHub theme
- `github.vscode-github-actions` - GitHub Actions
- `github.vscode-pull-request-github` - GitHub PRs
- `johnpapa.vscode-peacock` - Workspace colour
- `mhutchie.git-graph` - Git graph
- `ms-azuretools.vscode-docker` - Docker support
- `ms-vscode.hexeditor` - Hex editor
- `ms-vscode.live-server` - Live server
- `ms-vsliveshare.vsliveshare` - Live Share
- `redhat.vscode-xml` - XML support
- `streetsidesoftware.code-spell-checker-british-english` - British English spellchecking
- `tamasfe.even-better-toml` - TOML support
- `tomoki1207.pdf` - PDF preview
- `vscode-icons-team.vscode-icons` - File icons
- `vstirbu.vscode-mermaid-preview` - Mermaid diagram preview
- `wayou.vscode-todo-highlight` - TODO highlighting
- `yzhang.dictionary-completion` - Dictionary completion
- `yzhang.markdown-all-in-one` - Markdown tooling

**Verification** (run after adoption):

```bash
# Check VS Code config files exist
test -f .vscode/settings.json && echo "settings.json OK"
test -f .vscode/extensions.json && echo "extensions.json OK"
test -f project.code-workspace && echo "workspace file OK"

# Validate JSON syntax
jq '.' .vscode/settings.json > /dev/null && echo "settings.json valid"
jq '.' .vscode/extensions.json > /dev/null && echo "extensions.json valid"
jq '.' project.code-workspace > /dev/null && echo "workspace file valid"

# List recommended extensions
jq -r '.recommendations[]' .vscode/extensions.json

# Expected: All files exist and contain valid JSON
# Success indicator: Extension list displayed
```

**To adopt**: Copy `.vscode/` directory and `project.code-workspace`

**To remove**: Delete the files

---

### 12. Tool Version Management (asdf)

**Purpose**: Pin and manage tool versions consistently across the team, including Docker images.

**Benefits**: Pinned tools make builds repeatable and reduce environment-related defects.

**Problem it solves**: Unpinned versions create “works on my machine” issues and inconsistent outputs.

**How it solves it**: `.tool-versions` defines tool and Docker image versions, and shared scripts use those pins to ensure deterministic execution.

**Dependencies**: asdf version manager

**Source files** (in `assets/`):

- [`.tool-versions`](assets/.tool-versions) - Tool version pins (standard and Docker)

**Standard tool entries**:

```text
gitleaks 8.30.0
pre-commit 4.5.1
```

**Extended format for Docker images**:

The `.tool-versions` file is extended beyond standard asdf usage to pin Docker image versions. These entries are formatted as comments (so asdf ignores them) and parsed by the `docker-get-image-version-and-pull` function in `scripts/docker/docker.lib.sh`.

```text
# docker/<registry>/<image> <tag>@<digest> # SEE: <url>
```

**Example Docker entries**:

```text
# docker/ghcr.io/gitleaks/gitleaks v8.30.0@sha256:691af3c7c5a48b16f187ce3446d5f194838f91238f27270ed36eef6359a574d9 # SEE: https://github.com/gitleaks/gitleaks/pkgs/container/gitleaks
# docker/ghcr.io/igorshubovych/markdownlint-cli v0.47.0@sha256:9f06c8c9a75aa08b87b235b66d618f7df351f09f08faf703177f670e38ee6511 # SEE: https://github.com/igorshubovych/markdownlint-cli/pkgs/container/markdownlint-cli
# docker/hadolint/hadolint 2.14.0-alpine@sha256:7aba693c1442eb31c0b015c129697cb3b6cb7da589d85c7562f9deb435a6657c # SEE: https://hub.docker.com/r/hadolint/hadolint/tags
# docker/koalaman/shellcheck v0.11.0@sha256:61862eba1fcf09a484ebcc6feea46f1782532571a34ed51fedf90dd25f925a8d # SEE: https://hub.docker.com/r/koalaman/shellcheck/tags
# docker/mstruebing/editorconfig-checker v3.6@sha256:af556694c3eb0a16b598efbe84c1171d40dfb779fdac6f01b89baedde065556f # SEE: https://hub.docker.com/r/mstruebing/editorconfig-checker/tags
```

**Format breakdown**:

| Component            | Description                                               | Example                     |
| -------------------- | --------------------------------------------------------- | --------------------------- |
| `# docker/`          | Prefix marker (comment for asdf, parsed by docker.lib.sh) | `# docker/`                 |
| `<registry>/<image>` | Full image name                                           | `ghcr.io/gitleaks/gitleaks` |
| `<tag>`              | Version tag                                               | `v8.30.0`                   |
| `@<digest>`          | Content-addressable SHA256 digest                         | `@sha256:691af3c7c...`      |
| `# SEE: <url>`       | Reference URL (optional, for maintainability)             | `# SEE: https://...`        |

**Why use digests?**

- **Reproducibility**: Digests are immutable; tags can be overwritten
- **Security**: Prevents supply-chain attacks via tag substitution
- **Caching**: The `docker-get-image-version-and-pull` function pulls by digest and tags locally to avoid repeated downloads

**Usage**:

```bash
make config                             # Installs all asdf tools from .tool-versions
make _install-dependency name=gitleaks # Install specific asdf tool

# Docker images are pulled on-demand by scripts using docker-get-image-version-and-pull
```

**To adopt**:

1. Copy `.tool-versions`
2. Adjust versions for your project
3. Run `make config`
4. For Docker images, add entries following the format above

**Verification** (run after adoption):

```bash
# Check asdf is available
asdf --version

# Check .tool-versions exists and has content
test -f .tool-versions && cat .tool-versions

# Verify asdf tools are installed at specified versions
asdf current

# Install all asdf tools (if not already installed)
asdf install

# Check a specific tool matches pinned version
asdf current gitleaks

# Check Docker entries exist
grep "^# docker/" .tool-versions

# Expected: All tools listed in .tool-versions are installed
# Success indicator: `asdf current` shows all tools with matching versions
# Docker images are pulled automatically when scripts invoke docker-get-image-version-and-pull
```

**To remove**: Delete `.tool-versions`

---

### 13. GitHub Repository Templates

**Purpose**: Standardised templates for issues, pull requests, and security policies to ensure consistent contributor experience.

**Benefits**: Structured issues and PRs improve triage quality and reduce review cycles, while a clear security policy supports responsible disclosure.

**Problem it solves**: Unstructured requests lack critical context and slow down decisions.

**How it solves it**: Templates and guidance define required fields and workflows, which standardises contributions and expectations.

**Dependencies**: GitHub repository with Issues enabled and access to security policy settings

**Source files** (in `assets/`):

- [`.github/ISSUE_TEMPLATE/`](assets/.github/ISSUE_TEMPLATE/) - Issue form templates
- [`.github/pull_request_template.md`](assets/.github/pull_request_template.md) - PR description template
- [`.github/security.md`](assets/.github/security.md) - Security vulnerability reporting policy
- [`.github/contributing.md`](assets/.github/contributing.md) - Contributing guide

**Issue templates**:

- `1_support_request.yaml` - Support and help requests
- `2_feature_request.yaml` - New feature proposals
- `3_bug_report.yaml` - Bug reports with reproduction steps

**PR template contents**:

- Description section
- Context/problem statement
- Type of changes checklist (refactoring, feature, breaking change, bug fix)
- Contributor checklist (code style, tests, documentation, pair programming)

**Security policy**:

- NHS England security contact information
- Vulnerability reporting procedures via email
- NCSC (National Cyber Security Centre) reporting option

**To adopt**:

1. Copy `.github/ISSUE_TEMPLATE/` directory
2. Copy `.github/pull_request_template.md`
3. Copy `.github/security.md` and customise contact details
4. Copy `.github/contributing.md` and tailor to your project

**Verification** (run after adoption):

```bash
# Check templates exist
ls -la .github/ISSUE_TEMPLATE/
test -f .github/pull_request_template.md && echo "PR template OK"
test -f .github/security.md && echo "Security policy OK"
test -f .github/contributing.md && echo "Contributing guide OK"

# Validate YAML syntax for issue templates
for f in .github/ISSUE_TEMPLATE/*.yaml; do
  yq eval '.' "$f" > /dev/null && echo "$f valid"
done

# Expected: All template files present
# Success indicator: Templates appear in GitHub UI when creating issues/PRs
# Note: Full verification requires creating a test issue/PR on GitHub
```

**To remove**: Delete the template files

---

### 14. Documentation Structure (Markdown)

**Purpose**: Standardised documentation layout with Architecture Decision Records (ADRs) and guides.

**Benefits**: A clear documentation layout preserves design intent and reduces knowledge loss.

**Problem it solves**: Scattered or missing docs slow onboarding and lead to repeated decisions.

**How it solves it**: ADRs capture architectural choices and guides provide practical usage patterns in a predictable location.

**Dependencies**: None beyond a Markdown renderer for viewing

**Source files** (in `assets/`):

- [`docs/adr/`](assets/docs/adr/) - Architecture Decision Records
- [`docs/guides/`](assets/docs/guides/) - Developer and user guides

**ADR structure** (`docs/adr/`):

- `ADR-nnn_Any_Decision_Record_Template.md` - Template for new ADRs

**ADR template fields**:

| Field        | Description                                               |
| ------------ | --------------------------------------------------------- |
| Date         | When decision was last updated                            |
| Status       | RFC, Proposed, Accepted, Deprecated, Superseded, etc.     |
| Deciders     | Stakeholder groups involved                               |
| Significance | Structure, non-functional, dependencies, interfaces, etc. |
| Owners       | Decision owners                                           |

**Guides** (`docs/guides/`):

- `Bash_and_Make.md` - Shell scripting and Make conventions
- `Run_Git_hooks_on_commit.md` - Pre-commit hook usage
- `Scan_secrets.md` - Secret scanning usage
- `Scripting_Docker.md` - Docker patterns and practices
- `Sign_Git_commits.md` - Git commit signing guidance

**To adopt**:

1. Copy `docs/` directory structure
2. Customise ADR template for your organisation
3. Remove example guides not applicable
4. Add project-specific documentation

**Verification** (run after adoption):

```bash
# Check documentation structure exists
test -d docs/adr && echo "ADR directory OK"
test -d docs/guides && echo "Guides directory OK"

# Check ADR template exists
test -f docs/adr/ADR-nnn_Any_Decision_Record_Template.md && echo "ADR template OK"

# List documentation files
find docs -name "*.md" -type f

# Expected: Documentation directories with markdown files
# Success indicator: Organised documentation visible in repository
```

**To remove**: Delete `docs/` directory or specific subdirectories

---

## Adoption Patterns 🧭

### Full Template Adoption

To adopt the complete template directly from GitHub:

```bash
git clone https://github.com/stefaniuk/repository-template.git my-project
cd my-project
rm -rf .git
git init
make config
```

Or copy from the local `assets/` directory:

```bash
cp -r .github/skills/repository-template/assets/* my-project/
cd my-project
make config
```

### Selective Capability Adoption

To add a single capability to an existing repository:

1. Identify the capability from the table above
2. Copy the required files from [`assets/`](assets/) to your repository root
3. Update any include statements in `Makefile` or `scripts/init.mk`
4. Run `make config` if using pre-commit hooks

### Capability Removal

To remove a capability:

1. Delete the associated files
2. Remove any `include` statements referencing the capability
3. Remove from `scripts/config/pre-commit.yaml` if applicable
4. Remove from `.github/workflows/` if applicable

---

## File Reference 📚

All source files are located in the [`assets/`](assets/) directory. Copy them to your repository root (or the equivalent path).

### Root Files

| File                                                             | Purpose                         | Capability              |
| ---------------------------------------------------------------- | ------------------------------- | ----------------------- |
| [`assets/.editorconfig`](assets/.editorconfig)                   | File formatting rules           | File Format Checking    |
| [`assets/.gitattributes`](assets/.gitattributes)                 | Git file handling               | Core                    |
| [`assets/.gitignore`](assets/.gitignore)                         | Git ignore patterns             | Core                    |
| [`assets/.tool-versions`](assets/.tool-versions)                 | Tool version pins               | Tool Version Management |
| [`assets/.vscode/`](assets/.vscode/)                             | VS Code settings and extensions | VS Code Integration     |
| [`assets/LICENCE.md`](assets/LICENCE.md)                         | MIT licence                     | Core                    |
| [`assets/Makefile`](assets/Makefile)                             | Project make targets            | Core Make System        |
| [`assets/README.md`](assets/README.md)                           | Template README                 | Core                    |
| [`assets/project.code-workspace`](assets/project.code-workspace) | VS Code workspace               | VS Code Integration     |
| [`assets/VERSION`](assets/VERSION)                               | Project version                 | Core                    |

### Documentation Directory

| Path                                                                                                                 | Purpose                       |
| -------------------------------------------------------------------------------------------------------------------- | ----------------------------- |
| [`assets/docs/adr/`](assets/docs/adr/)                                                                               | Architecture Decision Records |
| [`assets/docs/adr/ADR-nnn_Any_Decision_Record_Template.md`](assets/docs/adr/ADR-nnn_Any_Decision_Record_Template.md) | ADR template                  |
| [`assets/docs/guides/`](assets/docs/guides/)                                                                         | Developer and user guides     |

### Scripts Directory

| Path                                                           | Purpose                  |
| -------------------------------------------------------------- | ------------------------ |
| [`assets/scripts/init.mk`](assets/scripts/init.mk)             | Core make infrastructure |
| [`assets/scripts/config/`](assets/scripts/config/)             | Tool configurations      |
| [`assets/scripts/quality/`](assets/scripts/quality/)           | Quality check scripts    |
| [`assets/scripts/docker/`](assets/scripts/docker/)             | Docker support           |
| [`assets/scripts/docker/tests/`](assets/scripts/docker/tests/) | Docker test scripts      |

### GitHub Directory

| Path                                                                                 | Purpose                  |
| ------------------------------------------------------------------------------------ | ------------------------ |
| [`assets/.github/workflows/`](assets/.github/workflows/)                             | CI/CD pipeline workflows |
| [`assets/.github/actions/`](assets/.github/actions/)                                 | Composite actions        |
| [`assets/.github/ISSUE_TEMPLATE/`](assets/.github/ISSUE_TEMPLATE/)                   | Issue templates          |
| [`assets/.github/pull_request_template.md`](assets/.github/pull_request_template.md) | PR template              |
| [`assets/.github/security.md`](assets/.github/security.md)                           | Security policy          |
| [`assets/.github/contributing.md`](assets/.github/contributing.md)                   | Contributing guide       |
| [`assets/.github/copilot-instructions.md`](assets/.github/copilot-instructions.md)   | Copilot instructions     |
| [`assets/.github/dependabot.yaml`](assets/.github/dependabot.yaml)                   | Dependency updates       |

---

## Updating from the template repository 🔄

To pull updates from the upstream run the following command:

```bash
.github/skills/repository-template/scripts/git-clone-repository-template.sh
```

Then selectively copy relevant files to your repository.

---

## Examples 📓

- [example-01-happy-path.md](./examples/example-01-happy-path.md) - adopting the Core Make System and Pre-commit Hooks capabilities into a fresh repository, including verification commands and expected outputs.
