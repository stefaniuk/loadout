# ADR-001a: Python dependency management 🧾

> |              |                                                 |
> | ------------ | ----------------------------------------------- |
> | Date         | `2026-02-08` when the decision was last updated |
> | Status       | `Accepted`                                      |
> | Significance | `Dependencies, Delivery & build`                |

---

- [ADR-001a: Python dependency management 🧾](#adr-001a-python-dependency-management-)
  - [Context 🧭](#context-)
  - [Decision ✅](#decision-)
    - [Assumptions 🧩](#assumptions-)
    - [Drivers 🎯](#drivers-)
    - [Options 🔀](#options-)
      - [Option A: uv (Selected) ✅](#option-a-uv-selected-)
      - [Option B: Poetry](#option-b-poetry)
      - [Option C: pip-tools](#option-c-pip-tools)
      - [Option D: Pipenv](#option-d-pipenv)
      - [Option E: PDM](#option-e-pdm)
    - [Outcome 🏁](#outcome-)
    - [Rationale 🧠](#rationale-)
  - [Consequences ⚖️](#consequences-️)
  - [Compliance 📏](#compliance-)
  - [Notes 🔗](#notes-)
  - [Actions ✅](#actions-)
  - [Tags 🏷️](#tags-️)

## Context 🧭

The Python tech stack needs a default dependency manager that is fast,
deterministic, and aligned with the toolchain. The decision must support a lock
file and standard Python packaging workflows.

## Decision ✅

### Assumptions 🧩

- Python 3.14.3 is the baseline runtime.
- `pyproject.toml` is the single source of truth for dependencies.
- Deterministic installs and a lock file are required.

### Drivers 🎯

- Deterministic, reproducible installs
- Alignment with modern Python packaging
- Fast dependency resolution and installs
- Low operational complexity
- Good editor and CI support

### Options 🔀

#### Option A: uv (Selected) ✅

Use [`uv`](https://github.com/astral-sh/uv) with `pyproject.toml` and a lock
file.

| Criteria            | Score/Notes                              |
| ------------------- | ---------------------------------------- |
| Toolchain alignment | ⭐⭐⭐ Modern and fast                   |
| Reproducibility     | ⭐⭐⭐ Lock file is first-class          |
| Performance         | ⭐⭐⭐ Very fast resolution and installs |
| Workflow simplicity | ⭐⭐ Single tool for sync and run        |
| Ecosystem support   | ⭐⭐ Growing adoption                    |
| Effort              | S                                        |

#### Option B: Poetry

Use [`Poetry`](https://github.com/python-poetry/poetry) with its lock file and
environment management.

| Criteria            | Score/Notes                |
| ------------------- | -------------------------- |
| Toolchain alignment | ⭐⭐ Common but heavier    |
| Reproducibility     | ⭐⭐⭐ Lock file is strong |
| Performance         | ⭐⭐ Slower than uv        |
| Workflow simplicity | ⭐⭐ More tooling concepts |
| Ecosystem support   | ⭐⭐⭐ Widely used         |
| Effort              | M                          |

**Why not chosen**: Strong feature set but slower and heavier for the baseline
workflow.

#### Option C: pip-tools

Use [`pip-tools`](https://github.com/jazzband/pip-tools) for `requirements.txt`
locking.

| Criteria            | Score/Notes                        |
| ------------------- | ---------------------------------- |
| Toolchain alignment | ⭐⭐ Standard pip workflow         |
| Reproducibility     | ⭐⭐⭐ Good lock via `pip-compile` |
| Performance         | ⭐⭐ Reasonable                    |
| Workflow simplicity | ⭐⭐ Separate steps and files      |
| Ecosystem support   | ⭐⭐⭐ Stable and familiar         |
| Effort              | M                                  |

**Why not chosen**: Does not centre `pyproject.toml` and adds extra workflow
steps.

#### Option D: Pipenv

Use [`Pipenv`](https://github.com/pypa/pipenv) for dependency and virtualenv
management.

| Criteria            | Score/Notes                         |
| ------------------- | ----------------------------------- |
| Toolchain alignment | ⭐ Low, less common in new projects |
| Reproducibility     | ⭐⭐ Lock file exists               |
| Performance         | ⭐ Low on larger sets               |
| Workflow simplicity | ⭐⭐ Mixed behaviours               |
| Ecosystem support   | ⭐⭐ Maintained but lower adoption  |
| Effort              | M                                   |

**Why not chosen**: Lower adoption and slower resolution for larger projects.

#### Option E: PDM

Use [`PDM`](https://github.com/pdm-project/pdm) for PEP 582-style workflows.

| Criteria            | Score/Notes                        |
| ------------------- | ---------------------------------- |
| Toolchain alignment | ⭐⭐ Modern but less common        |
| Reproducibility     | ⭐⭐⭐ Lock file is strong         |
| Performance         | ⭐⭐ Good                          |
| Workflow simplicity | ⭐⭐ Different conventions         |
| Ecosystem support   | ⭐⭐ Growing but smaller ecosystem |
| Effort              | M                                  |

**Why not chosen**: Smaller ecosystem and less standardised workflows than uv.

### Outcome 🏁

Adopt `uv` as the default dependency manager for Python. This decision is
reversible if the toolchain changes or if `uv` loses ecosystem support.

### Rationale 🧠

`uv` delivers fast, deterministic installs with a simple workflow aligned to
modern Python packaging. It supports lock files and keeps the toolchain lean.

## Consequences ⚖️

- Python projects should use `pyproject.toml` with `uv` lock files.
- Alternative tools require explicit justification.

## Compliance 📏

- `uv lock --check` produces no changes.
- `uv sync` succeeds in CI.

## Notes 🔗

- Tech Radar: `./Tech_Radar.md`
- Python downloads: <https://www.python.org/downloads/>

## Actions ✅

- [x] Copilot, 2026-02-08, record the dependency management decision

## Tags 🏷️

`#dependencies #build #reproducibility #maintainability`
