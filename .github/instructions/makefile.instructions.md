---
applyTo: "{Makefile,**/Makefile,**/*.mk}"
description: "Makefile Engineering Instructions (developer experience, CI-aligned)"
---

# Makefile Engineering Instructions (developer experience, CI-aligned) 🛠️

These instructions define the default engineering approach for using **Makefiles
as orchestration**, not as a place for complex logic.

They must remain applicable to:

- Small repos with a single `Makefile`
- Modular repos that include shared `*.mk` modules (recommended)
- Repos where `make` is the **canonical interface** for local dev and CI/CD

They are **non-negotiable** unless an exception is explicitly documented (with
rationale and expiry) in an ADR/decision record.

**Identifier scheme.** Every normative rule carries a unique tag in the form
`[MK-<prefix>-NNN]`, where the prefix maps to the containing section (for
example `OP` for Operating Principles, `LCL` for Local-first developer
experience, `STR` for Structure, `UX` for Target UX, `SH` for Shell & safety,
`VAR` for Variables, `SEC` for Security, `CI` for CI alignment, `QG` for Quality
Gates, and `AI` for AI-assisted expectations). Use these identifiers when
referencing, planning, or validating requirements.

---

## 0. Quick reference (apply first) 🧠

This section exists so humans and AI assistants can reliably apply the most
important rules even when context is tight.

- [MK-QR-001] **Thin root Makefile**: the root `Makefile` includes
  `scripts/init.mk` and defines only project targets; push reusable logic into
  `scripts/**/*.mk` and `scripts/**/*.sh` ([MK-STR-001], [MK-STR-004],
  [MK-SH-008]).
- [MK-QR-002] **Help-first UX**: default goal is `help`; every public target has
  an inline description and category ([MK-UX-001]–[MK-UX-006]).
- [MK-QR-003] **Safe by default**: destructive targets preview by default and
  act only with `CONFIRM=true` ([MK-SEC-001]–[MK-SEC-006]).
- [MK-QR-004] **Fail fast**: recipes must fail on errors; never hide failures
  ([MK-SH-001]–[MK-SH-006]).
- [MK-QR-005] **CI uses make**: CI/CD should call the same targets developers
  run locally ([MK-CI-001]–[MK-CI-006]).
- [MK-QR-006] **Deterministic targets**: stable outputs and consistent
  environment handling ([MK-OP-003], [MK-VAR-001]–[MK-VAR-006]).
- [MK-QR-007] **Small, testable changes**: prefer incremental improvements; do
  not rewrite the build system as a "clean-up" ([MK-OP-002], [MK-AI-001]).
- [MK-QR-008] **Fast feedback**: local development and tests must be quick and
  confidence-building ([MK-OP-005], [MK-LCL-001]–[MK-LCL-005]).
- [MK-QR-009] **Run the quality gates** after any Makefile/script change and
  iterate to clean ([MK-QG-001]–[MK-QG-003]).
- [MK-QR-010] **Avoid common anti-patterns**: `|| true` without comment, large
  inline shell, hardcoded paths, unscoped `rm -rf` (§12).
- [MK-QR-011] **The repository (based on the repository template) is the
  reference**: `Makefile`, `scripts/init.mk`, `scripts/docker/docker.mk` and
  [Use_Bash_and_Make.md](../../docs/guides/Use_Bash_and_Make.md) show these
  rules applied; when they disagree with this file, follow them and correct this
  file.

---

## 1. Operating principles 🧭

These principles extend
[constitution.md §3](../../.specify/memory/constitution.md#3-core-principles-non-negotiable).

- [MK-OP-001] Treat the Makefile interface as a **public contract** for
  engineers and CI: stable target names, stable variables, predictable
  behaviour.
- [MK-OP-002] Prefer **small, explicit, testable** changes over broad rewrites.
- [MK-OP-003] Design for **determinism**: the same inputs produce the same
  outputs.
- [MK-OP-004] Make is for **orchestration**. Complex logic belongs in scripts,
  e.g. shell, Python, etc. See the [Technology Recommendations](../../docs/adr/Technology_Recommendations.md)
  guide.
- [MK-OP-005] **Fast feedback is paramount**: key local targets must be quick,
  automated, and confidence-building.
- [MK-OP-006] Avoid inventing requirements or expanding scope beyond what the
  repo needs.
- [MK-OP-007] Optimise for **maintenance, usability, and change safety**, not
  cleverness.

---

## 2. Local-first developer experience (bleeding-edge fast feedback) ⚡

The build system must be **fully usable locally**, providing rapid feedback
before CI.

**Terminology.** This document distinguishes two things that are easy to
conflate:

- **Dependency / deps**: the shipped project's own runtime and dev packages
  (npm, uv/pip, Cargo, Go modules, etc.), pinned in a language lock file and
  installed by the language's own package manager. Always addressed as `deps`,
  or `deps-prod` and `deps-update` where a project needs them ([MK-LCL-001]).
- **Toolchain**: the CLI tools the build system itself needs to run (linters,
  formatters, runtimes), pinned in the `[tools]` table of `mise.toml` and
  installed by `make config`, not by the project's package manager. Container
  images used by tool wrappers are pinned in the `[_.docker]` table of the same
  file.

Never call a toolchain tool a "dependency"; keep the two vocabularies and their
target names separate (see [MK-LCL-008]).

### 2.1 Single-command workflow (must exist)

Provide repository-standard targets so an engineer can operate the repo quickly:

- [MK-LCL-001] Bootstrap: `make config` provisions the toolchain, Git hooks and
  pinned images, and `make deps` installs the project's dependencies from the
  lock file. Add `make deps-prod` when production-only dependencies differ.
- [MK-LCL-002] Lint/format: `make lint` and `make format`. `make lint` runs one
  `lint-*` target per check from `scripts/init.mk`, in `check=all` mode by
  default so a local pass predicts the pre-commit hook and CI.
  `make lint check=branch` limits the file checks to the branch's changes, and
  `lint-shell` always runs with `check=all`.
- [MK-LCL-003] Type-check: `make typecheck` - runs the static type checker (e.g.
  mypy) as a blocking gate.
- [MK-LCL-004] Test: `make test` runs every test suite deterministically. Keep
  it fast by running suites in parallel and stubbing external tools, as
  `./scripts/tests/run-test-suites.sh` does.
- [MK-LCL-005] Full suite: optionally add an extended target (commonly
  `make test-all`) that builds on the Section 11 `test` recipe to include
  integration/e2e tiers when applicable.
- [MK-LCL-006] Build: reuse the Section 11 `build` target to compile or package
  artefacts locally when applicable.
- [MK-LCL-007] Run locally: `make run` or `make up` / `make down` - use the
  optional Section 11 operations targets to start/stop the application or
  dependency stack (if applicable).
- [MK-LCL-013] Install, when the project ships a package or CLI:
  `make install` - install the project's package or binary locally and ensure
  its CLI entry point is available on the user's `PATH`. The target must be
  language- and packaging-agnostic (e.g. `pip install .`, `uv tool install .`,
  `npm install -g .`, `cargo install --path .`, `go install ./...`,
  `make build && cp …`), idempotent, and emit an actionable message when the
  resulting command is not yet on `PATH`.
- [MK-LCL-014] Uninstall, whenever `make install` exists: `make uninstall` -
  reverse `make install` by removing the project's package or binary from the
  user environment using the same package manager or path it was installed with
  (e.g. `pip uninstall -y <pkg>`, `uv tool uninstall <pkg>`,
  `npm uninstall -g <pkg>`, `cargo uninstall <pkg>`, `rm -f $(GOBIN)/<bin>`).
  The target must be idempotent (succeed when nothing is installed) and must not
  remove unrelated files.
- [MK-LCL-015] Link (optional alternative to install, not in the template):
  `make link` - link a built package or binary from the repository into a
  user-writable bin directory that is already on `PATH` (e.g. `~/.local/bin`,
  `~/bin`, or `$(go env GOBIN)`), so changes in the working tree are reflected
  without reinstalling. Implementations may use editable installs
  (`pip install -e .`, `uv pip install -e .`), packaging links (`npm link`,
  `pnpm link --global`), or symlinks to built artefacts
  (`ln -sf $(PWD)/dist/<bin> ~/.local/bin/<bin>`). The target must select the
  destination from a documented, overridable variable (e.g.
  `BIN_DIR ?= $(HOME)/.local/bin`), refuse to overwrite an unrelated file at the
  destination, and warn when `BIN_DIR` is not on `PATH`.
- [MK-LCL-016] Unlink, whenever `make link` exists: `make unlink` - reverse
  `make link` by removing the editable install or symlink created in
  `$(BIN_DIR)` (e.g. `pip uninstall -y <pkg>`, `npm unlink -g <pkg>`,
  `rm -f $(BIN_DIR)/<bin>`). The target must verify the link points into the
  repository before removing it (to avoid deleting unrelated files), be
  idempotent, and use the same overridable `BIN_DIR` as `link`.

### 2.2 Clear, actionable errors

- [MK-LCL-008] Any target that runs tools must produce clear, actionable errors
  when tools are missing. For a missing toolchain tool, point at the toolchain
  provisioning target (for example "run `make config`", or the manager's own
  install command such as `mise install`). For a missing application dependency,
  point at `make deps`. Do not conflate the two in one message.
- [MK-LCL-009] Do not fail silently; prefer explicit prerequisite checks with
  helpful messages.

### 2.3 Script delegation (recommended)

- [MK-LCL-010] Prefer calling scripts under `scripts/**/*.sh` (or similar) from
  make, rather than writing test/build logic inside make recipes.
- [MK-LCL-011] Scripts should be independently runnable for debugging.

### 2.4 Environment check (recommended)

- [MK-LCL-012] Provide an environment check target that confirms local
  prerequisites and surfaces actionable fixes. This repository uses
  `make toolchain-verify-gnu`, which checks GNU Make, Bash and a container
  runtime.

---

## 3. Structure and modularity 🧱

### 3.1 File layout and includes (recommended baseline)

- [MK-STR-001] The root `Makefile` must be **thin**:
  - its first line is `include scripts/init.mk`, which brings in the Make
    settings, `help`, the quality and toolchain targets, and
    `scripts/docker/docker.mk`;
  - it then defines only project-specific targets, followed by their
    `${VERBOSE}.SILENT:` list.
- [MK-STR-002] Shared targets must live in `scripts/**/*.mk` modules where
  feasible.
- [MK-STR-003] Required modules use `include`. Optional modules use `-include`.
- [MK-STR-004] Reusable logic must live in scripts (for example
  `scripts/**/something.sh`) and be called from a wrapper target; do not embed
  large shell programs inside recipes.
- [MK-STR-005] A module copied from another repository starts with a one-line
  marker naming its source, for example
  `# loadout-managed: scripts/loadout.ext.mk`. Do not add "do not edit" banners.
- [MK-STR-008] Add capabilities as extension modules. `scripts/init.mk` includes
  every `*.ext.mk` file under `scripts/` in sorted order. Name only entry points
  `*.ext.mk`, name helpers `*.lib.mk`, and never include one `*.ext.mk` from
  another ([Use_Bash_and_Make.md](../../docs/guides/Use_Bash_and_Make.md)).
- [MK-STR-009] Keep the Make settings (`.DEFAULT_GOAL`, `.ONESHELL`,
  `.SHELLFLAGS`, `SHELL`, `.PHONY: *`) and the `help` implementation in
  `scripts/init.mk` only. Never repeat them in the root `Makefile` or a module.

### 3.2 Target composition across modules

- [MK-STR-006] When multiple included modules contribute to the same target, use
  **double-colon** rules so modules can extend safely:
  - `clean::` for cleanup steps
  - `config::` for environment configuration steps
- [MK-STR-007] Each module's contribution to `clean::` and `config::` must be
  independently safe and not depend on another module having run first.

---

## 4. Target UX and discoverability 📖

### 4.1 Help is mandatory

- [MK-UX-001] `.DEFAULT_GOAL := help` must be set.
- [MK-UX-002] A `help` target must exist and print a readable list of public
  targets.
- [MK-UX-003] Each **public** target must include an inline description using
  the standard pattern:

  ```makefile
  some-target: # One-line description - mandatory: foo=[...]; optional: bar=[..., default is X] @Category
  ```

- [MK-UX-004] Categories must be short and consistent. Use the set already in
  this repository, and do not invent new ones:
  - `@Build`, `@Configuration`, `@Development`, `@ExamplesAndTests`,
    `@Operations`, `@Quality`, `@Release`, `@Others`
- [MK-UX-005] Internal/helper targets must be prefixed with `_` and must not be
  presented as the primary entrypoints. `make help` hides them.
- [MK-UX-006] Target names use kebab-case, starting with the area so related
  targets sort together: `docker-build`, `toolchain-upgrade`, `githooks-run`. A
  `lint-*` target runs one quality script with a configurable `check` mode. Do
  not wrap it in a second target that only fixes a mode. Set the mode where
  `make lint` calls it instead.

### 4.2 Guardrails for "public" targets

- [MK-UX-007] Public targets must document required variables
  (mandatory/optional) in the help description.
- [MK-UX-008] Public targets must not rely on interactive prompts in CI paths;
  provide non-interactive defaults and flags.
- [MK-UX-009] Treat every `make` target as a CLI surface that follows the shared
  [CLI contract](./includes/cli-contract-baseline.include.md): keep targets
  thin, delegate real work to scripts, honour exit-code/stream rules, and
  refactor when behaviour drifts from the underlying tooling.
- [MK-UX-010] Add every target to the `${VERBOSE}.SILENT:` list of the file that
  defines it, in alphabetical order, so recipes print only their output unless
  `VERBOSE=true`.
- [MK-UX-011] A target that wraps a check prints one success line when it
  passes, for example
  `./scripts/quality/check-shell-lint.sh && echo "shell lint: ok"`. A failing
  script prints its own diagnostics on stderr.
- [MK-UX-012] Give a target's mode a default on the line above its definition,
  so the target and the script can differ, for example
  `lint-file-format: check ?= all`.

---

## 5. Shell execution model and failure behaviour 🧨

**Section summary (key subsections):**

- 5.1 Fail-fast defaults - non-negotiable shell safety
- 5.2 Parallelism and environment - recursive calls and job control
- 5.3 Keep recipes small - delegation to scripts

### 5.1 Fail-fast defaults (non-negotiable)

- [MK-SH-001] Use bash consistently unless the repo explicitly documents another
  shell:
  - `SHELL := $(shell command -v bash)` selects Bash 5.2+ from `PATH` at Make
    startup, including with `.ONESHELL:`. GNU Make 3.82 or later is required.
- [MK-SH-002] Use a fail-fast shell mode (at least `-e`), and prefer:
  - `.ONESHELL:`, so a recipe can `source scripts/docker/docker.lib.sh` and call
    its functions on the following lines
  - `.SHELLFLAGS := -ce`, switched to `-cex` when `VERBOSE` is true
- [MK-SH-003] Do not mask failures. Avoid patterns like `|| true` unless there
  is a clear comment explaining why it is safe.
- [MK-SH-004] When a recipe fails, it must fail the make target (non-zero exit).

### 5.2 Parallelism and environment

- [MK-SH-005] Default to `.NOTPARALLEL:` unless you have proved targets are safe
  in parallel.
- [MK-SH-006] Prefer `$(MAKE)` over `make` for recursive calls, so flags and
  jobserver settings propagate.
- [MK-SH-009] Recipes reach the pinned toolchain through the mise shims that
  `scripts/init.mk` puts first on `PATH`. Never install or version tools inside
  a recipe.

### 5.3 Keep recipes small

- [MK-SH-007] A make recipe should not exceed ~5 effective lines of logic. If it
  does, move that logic into a script.
- [MK-SH-008] Wrapper targets (for example `_docker`, `_test`, `_terraform`) are
  encouraged:
  - set up environment/variables
  - call a script or sourced library function
  - handle "missing file/tool" with an actionable error message

---

## 6. Variables, parameters, and defaults 🔧

- [MK-VAR-001] Expose common parameters as variables with sane defaults using
  `?=`.
- [MK-VAR-002] Support convenient aliases where it improves usability (for
  example allow `docker_dir` and `dir` to map to the same value).
- [MK-VAR-003] Do not hardcode organisation- or environment-specific paths
  inside recipes; prefer variables and documented defaults.
- [MK-VAR-004] Variables passed to scripts must be explicit and stable (avoid
  hidden global coupling). Use lowercase for options of one target (`check`,
  `dir`, `file`, `dry_run`) and uppercase for settings shared across targets
  (`VERBOSE`, `FORCE_USE_DOCKER`, `CONFIRM`, `DOCKER_IMAGE`).
- [MK-VAR-005] Do not print secrets when listing variables or echoing commands.
  Treat variables ending with `_PASSWORD`, `_PASS`, `_KEY`, `_SECRET`, `_TOKEN`
  as sensitive by default.
- [MK-VAR-006] Set `MAKEFLAGS := --no-print-directory` in `scripts/init.mk` to
  reduce noise.
- [MK-VAR-007] Document precedence when variables can be set via multiple
  sources (command-line, environment, file). Prefer: command-line >
  environment > file > built-in default.

---

## 7. Safety and security defaults 🔐

**Section summary (key subsections):**

- 7.1 Destructive actions - safe defaults, confirmation patterns
- 7.2 Secrets handling - never embed or print secrets
- 7.3 Network and cloud operations - explicit intent, no implicit cloud calls

### 7.1 Destructive actions

- [MK-SEC-001] Default behaviour must be safe. Destructive actions must require
  explicit intent.
- [MK-SEC-002] `clean` must only delete well-known generated artefacts within
  the repo (no unscoped `rm -rf` outside the workspace). The shared `clean::`
  previews `git clean -X` and deletes only with `CONFIRM=true`.
- [MK-SEC-003] If a target can delete or overwrite user data, it must preview by
  default and act only when `CONFIRM=true`. A target that rewrites tracked files
  offers `dry_run=true`, as `make toolchain-upgrade` does. Parse both with the
  same true values as `is-arg-true`.

### 7.2 Secrets handling

- [MK-SEC-004] Never embed secrets in Makefiles.
- [MK-SEC-005] Never print secrets in logs, help output, or error messages.
- [MK-SEC-006] Sensitive variable patterns are defined in [MK-VAR-005].

### 7.3 Network and cloud operations

- [MK-SEC-007] Network or cloud operations must be explicit (for example
  `make deploy ENV=...`) and must not run by default in `dev`, `lint`, or
  `test`.
- [MK-SEC-008] Default local targets must not require real cloud credentials.

---

## 8. CI/CD alignment 🧰

**Section summary (key subsections):**

- 8.1 Target naming and stability - predictable CI interface
- 8.2 Reproducibility - determinism and clean workspaces

### 8.1 Target naming and stability

- [MK-CI-001] CI/CD workflows should call make targets (not duplicated inline
  bash).
- [MK-CI-002] Pipeline targets should be stable and predictable. Common names
  include:
  - `deps`, `build`, `test`, `publish`, `deploy`, `clean`
- [MK-CI-003] Targets used in CI must be non-interactive.

### 8.2 Reproducibility

- [MK-CI-004] Targets used in CI must be deterministic and safe in a clean
  workspace.
- [MK-CI-005] Where possible, local and CI use the **same** targets and scripts.
- [MK-CI-006] If CI requires extra flags (for example `CI=true`), they must be
  documented and should not change core behaviour beyond safety and logging.
- [MK-CI-007] Logs produced by CI targets must be structured or parseable where
  possible; prefer stable output formats.

---

## 9. Mandatory quality gates (constitution §7.8) ✅

Per operating principles ([MK-OP-002], [MK-OP-005]) **and**
[constitution.md §7.8](../../.specify/memory/constitution.md#78-mandatory-local-quality-gates),
after making **any** change to Makefiles, scripts, or build configuration, you
must run the repository's **canonical** quality gates:

1. Prefer:
   - [MK-QG-001] `make lint`
   - [MK-QG-002] `make test`

2. If `make` targets do not exist, discover and run the project's equivalent
   commands.
   - [MK-QG-003] Follow the shared
     [quality gates baseline](./includes/quality-gates-baseline.include.md) for
     iteration and warning handling rules.
   - [MK-QG-004] Follow the shared
     [quality gates baseline](./includes/quality-gates-baseline.include.md) for
     command selection and equivalents.

---

## 10. AI-assisted change expectations 🤖

This section defines expectations when AI assistants modify Makefiles or build
scripts.

### 10.1 Scope and intent

- [MK-AI-001] Follow the shared
  [AI change baseline](./includes/ai-assisted-change-baseline.include.md) for
  scope, quality, and governance.

### 10.2 New target checklist

If you introduce a new public target, you must:

- [MK-AI-004] Add a help description + category ([MK-UX-003], [MK-UX-004]).
- [MK-AI-005] Keep the recipe small ([MK-SH-007]).
- [MK-AI-006] Add/update scripts as needed ([MK-SH-008]).
- [MK-AI-007] Ensure it runs locally and in CI where intended
  ([MK-CI-001]–[MK-CI-006]).
- [MK-AI-008] Run quality gates and iterate to clean ([MK-QG-001]–[MK-QG-004]).
- [MK-AI-012] Add it to the `${VERBOSE}.SILENT:` list ([MK-UX-010]).
- [MK-AI-013] Never use `make -n` to inspect a target that recurses: GNU Make
  still runs recipe lines containing `$(MAKE)`. Read the recipe instead.

### 10.3 Existing target modifications

When modifying existing targets:

- [MK-AI-009] Preserve backward compatibility unless a breaking change is
  explicitly requested.
- [MK-AI-010] Document any behavioural changes in commit messages or PR
  descriptions.
- [MK-AI-011] Verify the change works in both local and CI contexts.

---

## 11. Makefile format (non-negotiable) 📐

The root Makefile format lives in
[templates/Makefile.template](./templates/Makefile.template), which mirrors this
repository's own [Makefile](../../Makefile). Projects must adopt this naming
convention, structure, and formatting as their baseline. Targets may be added,
removed, or customised to suit project needs, but the overall layout and style
must remain consistent. The template adds an optional section with `run`, `up`,
`down`, `install` and `uninstall`. Keep only the targets the project needs, and
keep the `${VERBOSE}.SILENT:` list in step with them.

---

## 12. Anti-patterns (recognise and avoid) 🚫

These patterns cause recurring issues in Makefiles and build scripts. Avoid them
unless an ADR documents a justified exception.

- [MK-ANT-001] **`|| true` without comment** - masks failures silently; always
  document why it is safe.
- [MK-ANT-002] **Large inline shell blocks (>5 lines)** - hard to test and
  debug; extract to `scripts/**/*.sh`.
- [MK-ANT-003] **Hardcoded absolute paths** - breaks portability across
  machines; use variables with sensible defaults.
- [MK-ANT-004] **`rm -rf` without path constraints** - dangerous; scope to known
  directories (e.g. `rm -rf $(BUILD_DIR)`).
- [MK-ANT-005] **Recursive `make` without `$(MAKE)`** - breaks jobserver and
  flag propagation; always use `$(MAKE)`.
- [MK-ANT-006] **Secrets in variable defaults** - leaks to logs and process
  lists; inject via environment at runtime.
- [MK-ANT-007] **Tab/space inconsistency** - recipes require tabs; mixed
  indentation breaks execution.
- [MK-ANT-008] **Targets without help descriptions** - poor discoverability;
  always add `# description @Category`.
- [MK-ANT-009] **Silent failures via subshell** - `(command)` can hide exit
  codes; use `set -e` or check explicitly.
- [MK-ANT-010] **Over-engineered dependency graphs** - hard to maintain and
  debug; keep prerequisites simple and explicit.
- [MK-ANT-011] **`$(shell ...)` in prerequisites** - evaluated at parse time,
  not execution; can cause surprising behaviour.
- [MK-ANT-012] **Per-target `.PHONY` lists** - `scripts/init.mk` declares
  `.PHONY: *` for every target; do not add or change `.PHONY` declarations.
- [MK-ANT-013] **`@` prefixes on recipe lines** - inconsistent with the
  `${VERBOSE}.SILENT:` lists; add the target to the list instead.
- [MK-ANT-014] **Repeated Make settings** - a second `SHELL`, `.ONESHELL` or
  `help` definition outside `scripts/init.mk` causes conflicting behaviour
  ([MK-STR-009]).
