# Example 01 - Audit a Python codebase against `python.instructions.md`

## Scenario metadata

- **Skill**: enforcement-audit
- **Scenario**: Full compliance audit of a small Python service against `python.instructions.md`, producing an inventory, alignment plan, fixes, and a final report.
- **Repository context**: An existing Python project (FastAPI service plus CLI) with `pyproject.toml`, partial ruff/mypy configuration, and incomplete adherence to the `PY-*` rules.
- **User goal**: Identify every divergence from the Python instructions, plan the remediation, implement it in safe batches, and prove compliance via `make lint` and `make test`.
- **Invocation**: `Run the enforcement-audit skill for python`

## User prompt

> Run the enforcement-audit skill against `python`. Produce the inventory and alignment plan, then implement the fixes and validate the quality gates.

## Argument and intent resolution

- `$ARGUMENTS` resolves to `python`.
- Resolved from the table: instruction file `python.instructions.md`, patterns `*.py`, `pyproject.toml`, `uv.lock`, `requirements*.txt`; rule prefix `PY`.
- Output paths: inventory at `docs/prompt-reports/python-inventory.md`, plan at `docs/prompt-reports/python-instructions-alignment-plan.md`.

## Context gathering

- Read `.specify/memory/constitution.md` once for non-negotiables.
- Read `.github/instructions/python.instructions.md` end to end; captured every `[PY-XX-NNN]` identifier into a working checklist.
- Read `architecture-baseline.include.md` for evidence-gathering conventions.
- Ran `git ls-files '*.py' pyproject.toml uv.lock requirements*.txt Makefile` to enumerate 142 files in scope.
- Confirmed no overriding ADR for Python tooling - instructions are fully binding.
- Checked for prior runs: neither inventory nor plan file existed.

## Execution

1. **Build the artefact matrix** - wrote `docs/prompt-reports/python-inventory.md` listing each file, its role (entrypoint, library, test, config, tooling), and the applicable `PY-*` tags. Highlighted three high-risk areas: outbound HTTP client (no timeouts), logging configuration (non-structured), test layout (mixing unit and integration without markers).
2. **Detect discrepancies** - produced 17 findings, each with an evidence link of the form `- Evidence: [path](path#Lx-Ly) - violates [PY-RES-003] because ...` (for example, the outbound payments client did not set an explicit timeout on its `httpx.AsyncClient`).
3. **Plan the rework** - grouped findings into five workstreams in `docs/prompt-reports/python-instructions-alignment-plan.md`: (W1) timeouts and retries, (W2) structured logging, (W3) ruff/mypy config completeness, (W4) test markers and layout, (W5) `pyproject.toml` metadata hygiene. Safety-critical items (W1, W2) ordered first.
4. **Implement in batches** - landed each workstream as a narrowly scoped change set, referencing instruction tags in commit subjects (e.g. `fix(http): set explicit timeouts [PY-RES-003]`). After each batch ran `make lint` and `make test` to confirm green.
5. **Validate quality gates** - final `make lint` and `make test` runs both passed with zero warnings. `uv lock --check` confirmed lockfile drift had been resolved.
6. **Summarise outcomes** - appended a final report section to the plan file: resolved discrepancies (17/17), remaining gaps (none), follow-ups (raise an ADR for retry policy values; tracked as a separate workstream).

## Output artefacts

- `docs/prompt-reports/python-inventory.md` - artefact matrix and high-risk highlights.
- `docs/prompt-reports/python-instructions-alignment-plan.md` - workstreams, batches, and final enforcement report.
- Source changes across `src/app/clients/`, `src/app/core/logging.py`, `pyproject.toml`, and `tests/conftest.py` implementing the five workstreams.

## Validation evidence

- `make lint` - zero errors, zero warnings.
- `make test` - all unit and integration suites green.
- `uv run mypy src tests` - clean.
- `uv lock --check` - no drift.
- Every finding closed in the plan with a back-reference to the implementing commit.

## Final assistant response

> Python enforcement audit complete. 17 findings detected and resolved across five workstreams. Inventory at `docs/prompt-reports/python-inventory.md`, plan and final report at `docs/prompt-reports/python-instructions-alignment-plan.md`. `make lint` and `make test` both green. One follow-up recorded: capture retry policy defaults in a new ADR.

## Notes and follow-ups

- On the next run the skill will parse the existing inventory and plan files and continue from where it left off rather than starting fresh.
- The retry-policy ADR should be raised before any further work on resilience patterns to avoid re-deriving the same defaults.
- Consider scheduling this audit in CI on a weekly cadence to detect drift early.
