---
name: enforcement-audit
description: Run a compliance audit against a technology instruction file, detecting discrepancies, planning workstreams, implementing fixes, and validating quality gates.
argument-hint: "Specify the technology to audit: python, typescript, go, docker, rust, shell, makefile, terraform, reactjs, tauri, playwright-python, or playwright-typescript"
license: MIT
version: 1.0.0
---

# Enforcement Audit Skill

This skill runs a structured compliance audit for a specific technology against its instruction file. It replaces the individual `enforce.*` prompts with a single parameterised workflow.

## Technology Resolution

Resolve the technology from the user's input (`$ARGUMENTS`). Match against the table below to determine the instruction file, file patterns, rule prefix, and output paths.

| Technology            | Instruction file                        | File patterns                                                  | Rule prefix | Inventory path                                           | Plan path                                                                  |
| --------------------- | --------------------------------------- | -------------------------------------------------------------- | ----------- | -------------------------------------------------------- | -------------------------------------------------------------------------- |
| python                | `python.instructions.md`                | `*.py`, `pyproject.toml`, `uv.lock`, `requirements*.txt`       | PY          | `docs/prompt-reports/python-inventory.md`                | `docs/prompt-reports/python-instructions-alignment-plan.md`                |
| typescript            | `typescript.instructions.md`            | `*.ts`, `*.tsx`, `*.js`, `package.json`, `tsconfig.json`       | TS          | `docs/prompt-reports/typescript-inventory.md`            | `docs/prompt-reports/typescript-instructions-alignment-plan.md`            |
| go                    | `go.instructions.md`                    | `*.go`, `go.mod`, `go.sum`                                     | GO          | `docs/prompt-reports/go-inventory.md`                    | `docs/prompt-reports/go-instructions-alignment-plan.md`                    |
| docker                | `docker.instructions.md`                | `Dockerfile`, `Dockerfile.*`, `compose.yaml`, `compose.*.yaml` | DF          | `docs/prompt-reports/docker-inventory.md`                | `docs/prompt-reports/docker-instructions-alignment-plan.md`                |
| rust                  | `rust.instructions.md`                  | `*.rs`, `Cargo.toml`, `Cargo.lock`                             | RS          | `docs/prompt-reports/rust-inventory.md`                  | `docs/prompt-reports/rust-instructions-alignment-plan.md`                  |
| shell                 | `shell.instructions.md`                 | `*.sh`, `*.bash`, `*.zsh`                                      | SH          | `docs/prompt-reports/shell-inventory.md`                 | `docs/prompt-reports/shell-instructions-alignment-plan.md`                 |
| makefile              | `makefile.instructions.md`              | `Makefile`, `*.mk`                                             | MK          | `docs/prompt-reports/makefile-inventory.md`              | `docs/prompt-reports/makefile-instructions-alignment-plan.md`              |
| terraform             | `terraform.instructions.md`             | `*.tf`, `*.tfvars`                                             | TF          | `docs/prompt-reports/terraform-inventory.md`             | `docs/prompt-reports/terraform-instructions-alignment-plan.md`             |
| reactjs               | `reactjs.instructions.md`               | `*.jsx`, `*.tsx`, `*.js`, `*.ts`                               | RJS         | `docs/prompt-reports/reactjs-inventory.md`               | `docs/prompt-reports/reactjs-instructions-alignment-plan.md`               |
| tauri                 | `tauri.instructions.md`                 | `*.rs`, `*.ts`, `*.tsx`, `*.js`, `*.jsx`                       | TAU         | `docs/prompt-reports/tauri-inventory.md`                 | `docs/prompt-reports/tauri-instructions-alignment-plan.md`                 |
| playwright-python     | `playwright-python.instructions.md`     | `*.py`                                                         | PPW         | `docs/prompt-reports/playwright-python-inventory.md`     | `docs/prompt-reports/playwright-python-instructions-alignment-plan.md`     |
| playwright-typescript | `playwright-typescript.instructions.md` | `*.ts`, `*.tsx`                                                | PTW         | `docs/prompt-reports/playwright-typescript-inventory.md` | `docs/prompt-reports/playwright-typescript-instructions-alignment-plan.md` |

If the technology is not in this table, inform the user and list the supported technologies.

## Mandatory Preparation

Before starting the audit:

1. Read the [constitution](../../../.specify/memory/constitution.md) for non-negotiable rules, if you have not done already.
2. Read the instruction file for the resolved technology (from the table above, located in `.github/instructions/`).
3. Note the reference identifiers (e.g. `[PY-QR-001]`) - you must assess compliance against each of them.
4. Read the [architecture overview instructions](../../instructions/includes/architecture-baseline.include.md) and adopt the approach for gathering supporting evidence.

## Goal

Enumerate every artefact of the resolved technology in the repository, detect any discrepancies against the instruction file, plan the refactor/rework workstream, implement the required changes, and confirm compliance.

## Discovery (run before writing)

### A. Enumerate scope

1. Run `git ls-files` with the file patterns from the table above (and include glue files such as `Makefile`, CI configs) to capture the full footprint.
2. Categorise each file by role (entrypoints, libraries, tests, configuration, tooling, etc.).
3. Record locations that declare tooling to ensure instructions apply consistently.

### B. Load enforcement context

1. Re-read the relevant sections of the instruction file for the features present.
2. Note any repository ADRs or docs that explicitly override defaults; if none exist, assume the instructions are fully binding.
3. Summarise any uncertainties as **Unknown from code - verify {topic} with maintainers** before proceeding.

## Steps

> **Note:** On subsequent runs, check whether the artefacts produced by earlier executions (inventory and alignment plan) already exist and parse them so progress is cumulative rather than duplicated.

### 1) Build the artefact matrix

1. Produce a table in the inventory path (from the table above) listing each file/folder, its role, and key instruction tags that apply.
2. Highlight high-risk areas where divergence is most likely.

### 2) Detect discrepancies against instructions

1. For each artefact and file, scan for violations of the instruction tags.
2. Assess each artefact and file against compliance of each reference identifier from the instruction file.
3. Capture findings with precise evidence links, formatted as `- Evidence: [path/to/file](path/to/file#L10-L40) - violates [{PREFIX}-XXX-NNN] because ...` (using the rule prefix from the table).
4. Record unknowns explicitly using **Unknown from code - {action}**.

### 3) Plan refactoring and rework

1. Group findings into actionable workstreams.
2. For each workstream, provide: objective, files to touch, specific instruction tags satisfied, order of execution (prioritise safety-critical fixes first).
3. Store the plan in the plan path from the table above for traceability.

### 4) Implement the changes (iterative, safe batches)

1. Execute the plan in small batches, keeping commits narrowly scoped and referencing instruction tags.
2. Prefer refactors that move logic into shared modules, add missing tooling config, or adjust CLIs/APIs to match the contract.
3. Update docs, Makefiles, CI, and configuration to keep guidance, automation, and behaviour in sync.

### 5) Validate quality gates and behavioural parity

1. After each batch, run `make lint` and `make test`; iterate until all pass with zero errors or warnings.
2. If additional technology-specific checks exist, run them when the touched areas require it.
3. Document any failures and fixes in the plan file; unresolved issues must be tracked as blockers.

### 6) Summarise outcomes and next steps

1. Produce a final enforcement report (append to the plan file) covering: resolved discrepancies, remaining gaps, follow-up actions.
2. Confirm there are no lingering **Unknown from code** items; if any remain, turn them into explicit follow-ups.
3. Share the plan/report with maintainers (e.g. via PR description).

## Output Requirements

- Use concrete evidence links for every finding or change request.
- Reference instruction identifiers when explaining discrepancies or fixes.
- Keep activities broken into the steps above; do not skip steps even if the code appears compliant.
- Prefer automation (scripts, linters) over manual spot checks where feasible.
- Maintain ASCII-only text unless the repository already contains Unicode in the touched files.
- When information is missing, record **Unknown from code - {suggested action}** instead of guessing.

## Examples

- [example-01-happy-path.md](./examples/example-01-happy-path.md) - a full `python` audit producing the inventory and alignment plan, implementing fixes across five workstreams, and validating with `make lint` and `make test`.
