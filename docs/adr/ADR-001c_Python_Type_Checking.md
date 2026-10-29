# ADR-001c: Python type checking 🧾

> |              |                                                 |
> | ------------ | ----------------------------------------------- |
> | Date         | `2026-02-08` when the decision was last updated |
> | Status       | `Accepted`                                      |
> | Significance | `Quality attributes`                            |

---

- [ADR-001c: Python type checking 🧾](#adr-001c-python-type-checking-)
  - [Context 🧭](#context-)
  - [Decision ✅](#decision-)
    - [Assumptions 🧩](#assumptions-)
    - [Drivers 🎯](#drivers-)
    - [Options 🔀](#options-)
      - [Option A: mypy (Selected) ✅](#option-a-mypy-selected-)
      - [Option B: Pyright](#option-b-pyright)
      - [Option C: Pyre](#option-c-pyre)
      - [Option D: pytype](#option-d-pytype)
      - [Option E: pyanalyze](#option-e-pyanalyze)
      - [Option F: ty](#option-f-ty)
    - [Outcome 🏁](#outcome-)
    - [Rationale 🧠](#rationale-)
  - [Consequences ⚖️](#consequences-️)
  - [Compliance 📏](#compliance-)
  - [Notes 🔗](#notes-)
  - [Actions ✅](#actions-)
  - [Tags 🏷️](#tags-️)

## Context 🧭

The Python tech stack needs a static type checker that is accurate, widely
adopted, and easy to integrate in CI and local workflows.

## Decision ✅

### Assumptions 🧩

- Python 3.14.3 is the baseline runtime.
- Type hints are mandatory for public APIs.
- Static analysis must run in CI as a blocking gate.

### Drivers 🎯

- Type accuracy and quality of diagnostics
- Ecosystem adoption and type stub support
- Speed for local and CI use
- Configuration simplicity
- Long-term maintenance and trust

### Options 🔀

#### Option A: mypy (Selected) ✅

Use [`mypy`](https://github.com/python/mypy) as the default type checker.

| Criteria          | Score/Notes                         |
| ----------------- | ----------------------------------- |
| Type accuracy     | ⭐⭐⭐ Mature and strict            |
| Ecosystem support | ⭐⭐⭐ Broad type stub coverage     |
| Performance       | ⭐⭐ Good, with incremental support |
| Configuration     | ⭐⭐ Straightforward                |
| Maintenance       | ⭐⭐⭐ Stable and well supported    |
| Effort            | S                                   |

#### Option B: Pyright

Use [`pyright`](https://github.com/microsoft/pyright) for fast type checking.

| Criteria          | Score/Notes                       |
| ----------------- | --------------------------------- |
| Type accuracy     | ⭐⭐⭐ Strong and strict          |
| Ecosystem support | ⭐⭐⭐ Excellent, large community |
| Performance       | ⭐⭐⭐ Very fast                  |
| Configuration     | ⭐⭐ JSON config and Node runtime |
| Maintenance       | ⭐⭐⭐ Active and widely used     |
| Effort            | M                                 |

**Why not chosen**: Excellent tool, but adds a Node dependency where a pure
Python tool is preferred.

#### Option C: Pyre

Use [`Pyre`](https://github.com/facebook/pyre-check) for strong type checking.

| Criteria          | Score/Notes                       |
| ----------------- | --------------------------------- |
| Type accuracy     | ⭐⭐⭐ Strong                     |
| Ecosystem support | ⭐⭐ Smaller ecosystem            |
| Performance       | ⭐⭐⭐ Fast with server mode      |
| Configuration     | ⭐⭐ More setup and a daemon      |
| Maintenance       | ⭐⭐ Active but narrower adoption |
| Effort            | M                                 |

**Why not chosen**: Extra setup and smaller adoption than mypy.

#### Option D: pytype

Use [`pytype`](https://github.com/google/pytype) for type inference.

| Criteria          | Score/Notes                       |
| ----------------- | --------------------------------- |
| Type accuracy     | ⭐⭐ Good, but inference-driven   |
| Ecosystem support | ⭐⭐ Moderate                     |
| Performance       | ⭐⭐ Reasonable                   |
| Configuration     | ⭐⭐ Some complexity              |
| Maintenance       | ⭐⭐ Active but narrower adoption |
| Effort            | M                                 |

**Why not chosen**: Less common and not as strict as mypy for annotated
codebases.

#### Option E: pyanalyze

Use [`pyanalyze`](https://github.com/quora/pyanalyze) for advanced type checks.

| Criteria          | Score/Notes              |
| ----------------- | ------------------------ |
| Type accuracy     | ⭐⭐ Strong but niche    |
| Ecosystem support | ⭐ Low, limited adoption |
| Performance       | ⭐⭐ Reasonable          |
| Configuration     | ⭐⭐ More tuning         |
| Maintenance       | ⭐⭐ Active but niche    |
| Effort            | M                        |

**Why not chosen**: Niche tool with a smaller ecosystem.

#### Option F: ty

Use [`ty`](https://github.com/astral-sh/ty) for fast type checking.

| Criteria          | Score/Notes                         |
| ----------------- | ----------------------------------- |
| Type accuracy     | ⭐⭐ Promising but early-stage      |
| Ecosystem support | ⭐ Early adoption and limited stubs |
| Performance       | ⭐⭐⭐ Very fast                    |
| Configuration     | ⭐⭐ Simple defaults                |
| Maintenance       | ⭐⭐ Active but new                 |
| Effort            | M                                   |

**Why not chosen**: Too early-stage for a default, with limited ecosystem
coverage.

### Outcome 🏁

Adopt `mypy` as the default type checker. This decision is reversible if
ecosystem support shifts or a better standard emerges.

### Rationale 🧠

`mypy` has the broadest adoption and strongest ecosystem support in Python. It
provides reliable diagnostics and fits a pure-Python toolchain.

## Consequences ⚖️

- New Python code must include type hints.
- CI must run mypy as a blocking gate.

## Compliance 📏

- `uv run mypy .` succeeds in CI.

## Notes 🔗

- Tech Radar: `./Tech_Radar.md`

## Actions ✅

- [x] Copilot, 2026-02-08, record the type checking decision

## Tags 🏷️

`#quality #correctness #maintainability`
