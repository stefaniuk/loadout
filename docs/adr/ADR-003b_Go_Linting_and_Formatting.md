# ADR-003b: Go linting and formatting 🧾

> |              |                                                 |
> | ------------ | ----------------------------------------------- |
> | Date         | `2026-02-08` when the decision was last updated |
> | Status       | `Accepted`                                      |
> | Significance | `Quality attributes, Delivery & build`          |

---

- [ADR-003b: Go linting and formatting 🧾](#adr-003b-go-linting-and-formatting-)
  - [Context 🧭](#context-)
  - [Decision ✅](#decision-)
    - [Assumptions 🧩](#assumptions-)
    - [Drivers 🎯](#drivers-)
    - [Options 🔀](#options-)
      - [Option A: gofmt + golangci-lint (Selected) ✅](#option-a-gofmt--golangci-lint-selected-)
      - [Option B: gofmt + staticcheck + revive](#option-b-gofmt--staticcheck--revive)
      - [Option C: gofumpt + golangci-lint](#option-c-gofumpt--golangci-lint)
      - [Option D: gofmt + go vet + golint](#option-d-gofmt--go-vet--golint)
      - [Option E: gofmt only](#option-e-gofmt-only)
    - [Outcome 🏁](#outcome-)
    - [Rationale 🧠](#rationale-)
  - [Consequences ⚖️](#consequences-️)
  - [Compliance 📏](#compliance-)
  - [Notes 🔗](#notes-)
  - [Actions ✅](#actions-)
  - [Tags 🏷️](#tags-️)

## Context 🧭

The Go tech stack needs a standard approach for linting and formatting that is
consistent, low friction, and easy to run in CI. The choice should align with Go
1.25.7 and avoid deprecated tooling.

## Decision ✅

### Assumptions 🧩

- Go 1.25.7 is the baseline toolchain.
- Formatting must be deterministic and standard across the codebase.
- Linting should provide broad coverage without high noise.

### Drivers 🎯

- Canonical formatting that matches Go community expectations
- High signal linting with reasonable performance
- Low configuration overhead
- Good editor and CI integration
- Long-term maintenance and active support

### Options 🔀

#### Option A: gofmt + golangci-lint (Selected) ✅

Use [`gofmt`](https://github.com/golang/go) for formatting and
[`golangci-lint`](https://github.com/golangci/golangci-lint) as the lint runner
with a curated rule set.

| Criteria               | Score/Notes                                |
| ---------------------- | ------------------------------------------ |
| Formatting consistency | ⭐⭐⭐ `gofmt` is the Go standard          |
| Lint coverage          | ⭐⭐⭐ Many linters in one tool            |
| Performance            | ⭐⭐ Fast enough for CI and local use      |
| Maintenance            | ⭐⭐ Active project and standard workflows |
| Effort                 | S                                          |

#### Option B: gofmt + staticcheck + revive

Run [`gofmt`](https://github.com/golang/go),
[`staticcheck`](https://github.com/dominikh/go-tools), and
[`revive`](https://github.com/mgechev/revive) separately.

| Criteria               | Score/Notes                        |
| ---------------------- | ---------------------------------- |
| Formatting consistency | ⭐⭐⭐ `gofmt` is the Go standard  |
| Lint coverage          | ⭐⭐ Good, but split across tools  |
| Performance            | ⭐⭐ Separate invocations add time |
| Maintenance            | ⭐⭐ More moving parts             |
| Effort                 | M                                  |

**Why not chosen**: Extra configuration and tool management without clear
benefits over the aggregate runner.

#### Option C: gofumpt + golangci-lint

Use stricter formatting with [`gofumpt`](https://github.com/mvdan/gofumpt) and
linting via [`golangci-lint`](https://github.com/golangci/golangci-lint).

| Criteria               | Score/Notes                              |
| ---------------------- | ---------------------------------------- |
| Formatting consistency | ⭐⭐ Opinionated beyond the Go standard  |
| Lint coverage          | ⭐⭐⭐ Strong via `golangci-lint`        |
| Performance            | ⭐⭐ Similar to Option A                 |
| Maintenance            | ⭐⭐ Active, but more formatting debates |
| Effort                 | M                                        |

**Why not chosen**: Adds extra style rules that are not broadly standard,
increasing review friction.

#### Option D: gofmt + go vet + golint

Use [`gofmt`](https://github.com/golang/go) with
[`go vet`](https://github.com/golang/go) and the deprecated
[`golint`](https://github.com/golang/lint).

| Criteria               | Score/Notes                    |
| ---------------------- | ------------------------------ |
| Formatting consistency | ⭐⭐⭐ Standard `gofmt`        |
| Lint coverage          | ⭐ Low, limited checks         |
| Performance            | ⭐⭐⭐ Fast                    |
| Maintenance            | ⭐ Low, `golint` is deprecated |
| Effort                 | S                              |

**Why not chosen**: Limited coverage and a deprecated lint tool.

#### Option E: gofmt only

Rely on [`gofmt`](https://github.com/golang/go) formatting without linting.

| Criteria               | Score/Notes             |
| ---------------------- | ----------------------- |
| Formatting consistency | ⭐⭐⭐ Standard `gofmt` |
| Lint coverage          | ⭐ None                 |
| Performance            | ⭐⭐⭐ Fast             |
| Maintenance            | ⭐⭐⭐ Minimal tooling  |
| Effort                 | S                       |

**Why not chosen**: Misses important correctness and quality checks.

### Outcome 🏁

Adopt `gofmt` for formatting and `golangci-lint` for linting with a curated rule
set. This is reversible if the Go community standard shifts or the lint runner
becomes unmaintained.

### Rationale 🧠

`gofmt` is the canonical formatter, and `golangci-lint` provides strong lint
coverage with manageable performance and configuration. This combination
balances standard practice with practical quality controls.

## Consequences ⚖️

- CI should run `gofmt` and `golangci-lint`.
- A shared linter configuration will be required if Go code is added.

## Compliance 📏

- `gofmt -w` produces no changes in CI.
- `golangci-lint run ./...` succeeds.

## Notes 🔗

- Tech Radar: `./Tech_Radar.md`

## Actions ✅

- [x] Copilot, 2026-02-08, update Tech Radar with the Go stack selection

## Tags 🏷️

`#quality #maintainability #consistency #build`
