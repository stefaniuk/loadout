# ADR-001b: Python linting and formatting 🧾

> |              |                                                 |
> | ------------ | ----------------------------------------------- |
> | Date         | `2026-02-08` when the decision was last updated |
> | Status       | `Accepted`                                      |
> | Significance | `Quality attributes, Delivery & build`          |

---

- [ADR-001b: Python linting and formatting 🧾](#adr-001b-python-linting-and-formatting-)
  - [Context 🧭](#context-)
  - [Decision ✅](#decision-)
    - [Assumptions 🧩](#assumptions-)
    - [Drivers 🎯](#drivers-)
    - [Options 🔀](#options-)
      - [Option A: Ruff (Selected) ✅](#option-a-ruff-selected-)
      - [Option B: Black + isort + Flake8](#option-b-black--isort--flake8)
      - [Option C: Pylint + Black](#option-c-pylint--black)
      - [Option D: autopep8 + pycodestyle](#option-d-autopep8--pycodestyle)
      - [Option E: YAPF + Flake8](#option-e-yapf--flake8)
    - [Outcome 🏁](#outcome-)
    - [Rationale 🧠](#rationale-)
  - [Consequences ⚖️](#consequences-️)
  - [Compliance 📏](#compliance-)
  - [Notes 🔗](#notes-)
  - [Actions ✅](#actions-)
  - [Tags 🏷️](#tags-️)

## Context 🧭

The Python tech stack needs a single, fast, consistent approach for linting and
formatting that can run in CI and locally without heavy configuration.

## Decision ✅

### Assumptions 🧩

- Python 3.14.3 is the baseline runtime.
- Formatting must be deterministic and consistent across the codebase.
- Linting should catch correctness and style issues with low noise.

### Drivers 🎯

- One-tool workflow where possible
- Fast execution for local and CI use
- Deterministic formatting
- High signal linting
- Active maintenance and ecosystem support

### Options 🔀

#### Option A: Ruff (Selected) ✅

Use [`ruff`](https://github.com/astral-sh/ruff) for both linting and formatting.

| Criteria               | Score/Notes                     |
| ---------------------- | ------------------------------- |
| Formatting consistency | ⭐⭐⭐ Built-in formatter       |
| Lint coverage          | ⭐⭐⭐ Broad checks in one tool |
| Performance            | ⭐⭐⭐ Very fast                |
| Configuration overhead | ⭐⭐ Simple unified config      |
| Ecosystem support      | ⭐⭐⭐ Strong and growing       |
| Effort                 | S                               |

#### Option B: Black + isort + Flake8

Use [`Black`](https://github.com/psf/black),
[`isort`](https://github.com/PyCQA/isort), and
[`Flake8`](https://github.com/PyCQA/flake8) together.

| Criteria               | Score/Notes                       |
| ---------------------- | --------------------------------- |
| Formatting consistency | ⭐⭐⭐ Black is stable            |
| Lint coverage          | ⭐⭐ Needs multiple plugins       |
| Performance            | ⭐⭐ Multiple tools add overhead  |
| Configuration overhead | ⭐⭐ Many configs to keep in sync |
| Ecosystem support      | ⭐⭐⭐ Mature and stable          |
| Effort                 | M                                 |

**Why not chosen**: Good quality but slower and more complex than a single tool.

#### Option C: Pylint + Black

Use [`Pylint`](https://github.com/pylint-dev/pylint) for linting and Black for
formatting.

| Criteria               | Score/Notes                         |
| ---------------------- | ----------------------------------- |
| Formatting consistency | ⭐⭐⭐ Black is stable              |
| Lint coverage          | ⭐⭐⭐ Deep checks but can be noisy |
| Performance            | ⭐⭐ Slower on large codebases      |
| Configuration overhead | ⭐⭐ Significant tuning             |
| Ecosystem support      | ⭐⭐ Stable but heavier             |
| Effort                 | M                                   |

**Why not chosen**: Higher noise and slower than Ruff for the default stack.

#### Option D: autopep8 + pycodestyle

Use [`autopep8`](https://github.com/hhatto/autopep8) and
[`pycodestyle`](https://github.com/PyCQA/pycodestyle).

| Criteria               | Score/Notes                           |
| ---------------------- | ------------------------------------- |
| Formatting consistency | ⭐⭐ Less strict and less predictable |
| Lint coverage          | ⭐ Low, basic checks                  |
| Performance            | ⭐⭐⭐ Fast                           |
| Configuration overhead | ⭐⭐ Moderate                         |
| Ecosystem support      | ⭐⭐ Stable but older stack           |
| Effort                 | M                                     |

**Why not chosen**: Weaker lint coverage and less deterministic formatting.

#### Option E: YAPF + Flake8

Use [`YAPF`](https://github.com/google/yapf) with Flake8.

| Criteria               | Score/Notes                      |
| ---------------------- | -------------------------------- |
| Formatting consistency | ⭐⭐ Configurable but subjective |
| Lint coverage          | ⭐⭐ Depends on Flake8 plugins   |
| Performance            | ⭐⭐ Reasonable                  |
| Configuration overhead | ⭐⭐ More tuning required        |
| Ecosystem support      | ⭐⭐ Maintained but less common  |
| Effort                 | M                                |

**Why not chosen**: More configuration with no clear benefit over Ruff.

### Outcome 🏁

Adopt `ruff` for both linting and formatting. This decision is reversible if
tooling changes or if ruff ceases to meet coverage needs.

### Rationale 🧠

Ruff provides a fast, single-tool workflow with strong lint coverage and a
built-in formatter. It keeps the toolchain simple and consistent.

## Consequences ⚖️

- Projects should configure Ruff in `pyproject.toml`.
- Additional linters require explicit justification.

## Compliance 📏

- `uv run ruff format --check .` produces no changes.
- `uv run ruff check .` succeeds in CI.

## Notes 🔗

- Tech Radar: `./Tech_Radar.md`

## Actions ✅

- [x] Copilot, 2026-02-08, record the linting and formatting decision

## Tags 🏷️

`#quality #consistency #maintainability`
