# ADR-001d: Python testing tooling 🧾

> |              |                                                 |
> | ------------ | ----------------------------------------------- |
> | Date         | `2026-02-28` when the decision was last updated |
> | Status       | `Accepted`                                      |
> | Significance | `Quality attributes`                            |

---

- [ADR-001d: Python testing tooling 🧾](#adr-001d-python-testing-tooling-)
  - [Context 🧭](#context-)
  - [Decision ✅](#decision-)
    - [Assumptions 🧩](#assumptions-)
    - [Drivers 🎯](#drivers-)
    - [Options 🔀](#options-)
      - [Option A: pytest (Selected) ✅](#option-a-pytest-selected-)
      - [Option B: unittest (standard library)](#option-b-unittest-standard-library)
      - [Option C: nose2](#option-c-nose2)
      - [Option D: behave](#option-d-behave)
      - [Option E: Robot Framework](#option-e-robot-framework)
    - [Outcome 🏁](#outcome-)
    - [Rationale 🧠](#rationale-)
    - [Property-based testing tooling 🔬](#property-based-testing-tooling-)
  - [Consequences ⚖️](#consequences-️)
  - [Compliance 📏](#compliance-)
  - [Notes 🔗](#notes-)
  - [Actions ✅](#actions-)
  - [Tags 🏷️](#tags-️)

## Context 🧭

The Python tech stack needs a default test framework that is fast, expressive,
and widely adopted, with good plugin support for CI.

## Decision ✅

### Assumptions 🧩

- Python 3.14.3 is the baseline runtime.
- Tests must be deterministic and quick for local runs.
- Integration and end-to-end tiers may be added later.

### Drivers 🎯

- Developer productivity and readability
- Plugin ecosystem and CI integrations
- Speed and reliability
- Low onboarding overhead
- Long-term maintenance

### Options 🔀

#### Option A: pytest (Selected) ✅

Use [`pytest`](https://github.com/pytest-dev/pytest) as the primary test
framework.

| Criteria           | Score/Notes                         |
| ------------------ | ----------------------------------- |
| Expressiveness     | ⭐⭐⭐ Rich fixtures and assertions |
| Ecosystem support  | ⭐⭐⭐ Large plugin ecosystem       |
| Performance        | ⭐⭐ Fast and parallelisable        |
| Ease of onboarding | ⭐⭐⭐ Simple and familiar          |
| Maintenance        | ⭐⭐⭐ Active and stable            |
| Effort             | S                                   |

#### Option B: unittest (standard library)

Use the standard [`unittest`](https://github.com/python/cpython) framework.

| Criteria           | Score/Notes                         |
| ------------------ | ----------------------------------- |
| Expressiveness     | ⭐⭐ Works but more verbose         |
| Ecosystem support  | ⭐⭐ Smaller plugin ecosystem       |
| Performance        | ⭐⭐ Reasonable                     |
| Ease of onboarding | ⭐⭐ Familiar but boilerplate-heavy |
| Maintenance        | ⭐⭐⭐ Standard library             |
| Effort             | S                                   |

**Why not chosen**: More boilerplate and less flexibility for fixtures and
plugins.

#### Option C: nose2

Use [`nose2`](https://github.com/nose-devs/nose2) as a test runner.

| Criteria           | Score/Notes               |
| ------------------ | ------------------------- |
| Expressiveness     | ⭐⭐ Reasonable           |
| Ecosystem support  | ⭐ Low, small ecosystem   |
| Performance        | ⭐⭐ Acceptable           |
| Ease of onboarding | ⭐⭐ Simple               |
| Maintenance        | ⭐⭐ Maintained but niche |
| Effort             | M                         |

**Why not chosen**: Smaller ecosystem and lower adoption.

#### Option D: behave

Use [`behave`](https://github.com/behave/behave) for BDD-style tests.

| Criteria           | Score/Notes                  |
| ------------------ | ---------------------------- |
| Expressiveness     | ⭐⭐ Good for BDD            |
| Ecosystem support  | ⭐⭐ Active but smaller      |
| Performance        | ⭐ Low for large suites      |
| Ease of onboarding | ⭐⭐ Requires BDD discipline |
| Maintenance        | ⭐⭐ Maintained              |
| Effort             | M                            |

**Why not chosen**: BDD style adds overhead for the baseline stack.

#### Option E: Robot Framework

Use [`Robot Framework`](https://github.com/robotframework/robotframework) for
keyword-driven testing.

| Criteria           | Score/Notes                        |
| ------------------ | ---------------------------------- |
| Expressiveness     | ⭐⭐ Good for acceptance testing   |
| Ecosystem support  | ⭐⭐ Active but separate ecosystem |
| Performance        | ⭐ Low for large suites            |
| Ease of onboarding | ⭐ Low for Python-first teams      |
| Maintenance        | ⭐⭐ Maintained                    |
| Effort             | M                                  |

**Why not chosen**: A different workflow with higher onboarding costs.

### Outcome 🏁

Adopt `pytest` as the default testing framework. This decision is reversible if
a stronger standard emerges.

### Rationale 🧠

`pytest` offers the best mix of expressiveness, plugin support, and performance.
It is the most widely adopted option for modern Python projects.

### Property-based testing tooling 🔬

For Python projects that already use `pytest`, we compared practical
property-based testing options for day-to-day engineering use.

| Tool                                                                                | Score/Notes                                                                                                                 |
| ----------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| [Hypothesis](https://github.com/HypothesisWorks/hypothesis)                         | ⭐⭐⭐ Best general default with strong `pytest` fit, shrinking, strategy ecosystem, and active maintenance.                |
| [Schemathesis](https://github.com/schemathesis/schemathesis)                        | ⭐⭐ Excellent for OpenAPI/GraphQL property testing; best as an API-focused add-on, not a full replacement for general PBT. |
| [CrossHair](https://github.com/pschanely/CrossHair)                                 | ⭐⭐ Strong symbolic counterexample finding for contract-heavy code; useful but more specialised workflow.                  |
| [hypothesis-jsonschema](https://github.com/python-jsonschema/hypothesis-jsonschema) | ⭐⭐ Helpful schema-to-strategy bridge when JSON Schema is central; narrower in scope than a full PBT framework.            |
| [pytest-quickcheck](https://github.com/Stranger6667/pytest-quickcheck)              | ⭐ Simpler random testing pattern, but limited compared with modern Hypothesis workflows.                                   |

**Recommended choice**: `Hypothesis` as the default property-based testing
companion to `pytest`.

## Consequences ⚖️

- Tests should be written using `pytest` by default.
- Property-based tests should use `Hypothesis` with `pytest`.
- Other frameworks require explicit justification.

## Compliance 📏

- `uv run pytest` succeeds in CI.

## Notes 🔗

- Tech Radar: `./Tech_Radar.md`

## Actions ✅

- [x] Copilot, 2026-02-08, record the testing decision
- [x] Copilot, 2026-02-28, add the PBT tooling comparison and recommendation

## Tags 🏷️

`#testability #quality #maintainability`
