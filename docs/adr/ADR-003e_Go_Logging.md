# ADR-003e: Go logging 🧾

> |              |                                                 |
> | ------------ | ----------------------------------------------- |
> | Date         | `2026-02-08` when the decision was last updated |
> | Status       | `Accepted`                                      |
> | Significance | `Quality attributes, Operations`                |

---

- [ADR-003e: Go logging 🧾](#adr-003e-go-logging-)
  - [Context 🧭](#context-)
  - [Decision ✅](#decision-)
    - [Assumptions 🧩](#assumptions-)
    - [Drivers 🎯](#drivers-)
    - [Options 🔀](#options-)
      - [Option A: log/slog](#option-a-logslog)
      - [Option B: zap (Selected) ✅](#option-b-zap-selected-)
      - [Option C: zerolog](#option-c-zerolog)
      - [Option D: logrus](#option-d-logrus)
      - [Option E: go-kit log](#option-e-go-kit-log)
    - [Outcome 🏁](#outcome-)
    - [Rationale 🧠](#rationale-)
  - [Consequences ⚖️](#consequences-️)
  - [Compliance 📏](#compliance-)
  - [Notes 🔗](#notes-)
  - [Actions ✅](#actions-)
  - [Tags 🏷️](#tags-️)

## Context 🧭

The Go tech stack needs a default logging library that supports structured
logging, is easy to adopt, and has long-term stability. The decision must also
account for multi-sink management (structured JSON to file plus a readable,
coloured console output), log levels, and pretty printing for developer use. The
user requested an ADR comparing at least five alternatives.

## Decision ✅

### Assumptions 🧩

- Go 1.25.7 is the baseline toolchain.
- Structured logging is required for observability.
- The logging choice should minimise third-party dependency risk.

### Drivers 🎯

- Structured logging support with JSON output
- Multi-sink management (JSON to file and readable console output)
- Pretty, coloured console output for local use
- Log levels and filtering support
- Performance suitable for services and CLIs
- Low dependency footprint
- Standardisation and ease of onboarding
- Long-term maintenance and stability

Weighted criteria use a 1-5 scale (higher is more important). Scores use ⭐ (1),
⭐⭐ (2), ⭐⭐⭐ (3). Weighted totals exclude Effort and have a maximum of 69.

| Criteria                 | Weight | Rationale                                          |
| ------------------------ | ------ | -------------------------------------------------- |
| Structured logging       | 5      | Highest priority for consistency and observability |
| Multi-sink management    | 4      | Core requirement for JSON file plus console output |
| Console pretty/colour    | 4      | Developer experience for local runs                |
| Log levels and filtering | 4      | Needed for operational control                     |
| Performance              | 2      | Important but secondary                            |
| Dependency footprint     | 2      | Prefer lighter dependencies                        |
| Ecosystem support        | 2      | Adoption matters for longevity                     |

### Options 🔀

#### Option A: log/slog

Use the standard library [`log/slog`](https://github.com/golang/go) with JSON
output for files and text output for console, adding a small fan-out handler or
adapter when multi-sink formatting is needed.

| Criteria                 | Score/Notes                                      |
| ------------------------ | ------------------------------------------------ |
| Structured logging       | ⭐⭐⭐ Built in with JSON handlers               |
| Multi-sink management    | ⭐⭐ Requires a small fan-out handler or adapter |
| Console pretty/colour    | ⭐ Plain text only without adapters              |
| Log levels and filtering | ⭐⭐⭐ Built in levels                           |
| Performance              | ⭐⭐ Good for most use cases                     |
| Dependency footprint     | ⭐⭐⭐ Standard library                          |
| Ecosystem support        | ⭐⭐⭐ Increasing adoption                       |
| Effort                   | M                                                |
| Weighted score (max 69)  | 55                                               |

**Why not chosen**: The weighted criteria prioritise multi-sink and coloured
console output. `slog` needs extra adapters for those requirements and still
lacks native colour support.

#### Option B: zap (Selected) ✅

Use Uber's [`zap`](https://github.com/uber-go/zap) for high-performance
structured logging.

| Criteria                 | Score/Notes                                       |
| ------------------------ | ------------------------------------------------- |
| Structured logging       | ⭐⭐⭐ Strong structured logging                  |
| Multi-sink management    | ⭐⭐⭐ `zapcore.NewTee` supports multiple outputs |
| Console pretty/colour    | ⭐⭐⭐ Console encoder supports colour            |
| Log levels and filtering | ⭐⭐⭐ Strong level control                       |
| Performance              | ⭐⭐⭐ Very fast                                  |
| Dependency footprint     | ⭐⭐ External dependency                          |
| Ecosystem support        | ⭐⭐⭐ Widely used and maintained                 |
| Effort                   | M                                                 |
| Weighted score (max 69)  | 67                                                |

#### Option C: zerolog

Use [`zerolog`](https://github.com/rs/zerolog) for zero allocation logging.

| Criteria                 | Score/Notes                                         |
| ------------------------ | --------------------------------------------------- |
| Structured logging       | ⭐⭐⭐ Strong JSON support                          |
| Multi-sink management    | ⭐⭐⭐ `MultiLevelWriter` supports multiple outputs |
| Console pretty/colour    | ⭐⭐⭐ Console writer supports colour               |
| Log levels and filtering | ⭐⭐⭐ Strong level control                         |
| Performance              | ⭐⭐⭐ Very fast                                    |
| Dependency footprint     | ⭐⭐ External dependency                            |
| Ecosystem support        | ⭐⭐ Popular but not standard                       |
| Effort                   | M                                                   |
| Weighted score (max 69)  | 65                                                  |

**Why not chosen**: Strong feature set, but slightly lower ecosystem maturity
than `zap` in this weighted comparison.

#### Option D: logrus

Use [`logrus`](https://github.com/sirupsen/logrus) for structured logging.

| Criteria                 | Score/Notes                               |
| ------------------------ | ----------------------------------------- |
| Structured logging       | ⭐⭐ Good but older design                |
| Multi-sink management    | ⭐⭐ Hooks and outputs support multi-sink |
| Console pretty/colour    | ⭐⭐ Colour supported                     |
| Log levels and filtering | ⭐⭐⭐ Strong level control               |
| Performance              | ⭐ Low compared with newer options        |
| Dependency footprint     | ⭐⭐ External dependency                  |
| Ecosystem support        | ⭐⭐ Stable but not evolving              |
| Effort                   | M                                         |
| Weighted score (max 69)  | 48                                        |

**Why not chosen**: Slower and less modern than other options.

#### Option E: go-kit log

Use [`go-kit/log`](https://github.com/go-kit/log) for minimal structured
logging.

| Criteria                 | Score/Notes                        |
| ------------------------ | ---------------------------------- |
| Structured logging       | ⭐⭐ Basic key value logging       |
| Multi-sink management    | ⭐⭐ Possible via multiple writers |
| Console pretty/colour    | ⭐ Limited without extra helpers   |
| Log levels and filtering | ⭐ Requires extra filters          |
| Performance              | ⭐⭐ Reasonable                    |
| Dependency footprint     | ⭐⭐ External dependency           |
| Ecosystem support        | ⭐⭐ Niche outside go-kit          |
| Effort                   | M                                  |
| Weighted score (max 69)  | 38                                 |

**Why not chosen**: Smaller ecosystem and less standard than `slog`.

### Outcome 🏁

Adopt `zap` as the default logging library for Go. This decision is reversible
if the standard library adds native multi-sink and coloured console support, or
if dependency footprint becomes the primary driver.

### Rationale 🧠

Using the weighted criteria, `zap` scores highest because it delivers strong
structured logging with built-in multi-sink support, coloured console output,
and robust level control. The additional dependency is an acceptable trade-off
given the priority on developer experience and operational flexibility.

## Consequences ⚖️

- Go services should default to `zap` with JSON output to file and a coloured
  console encoder for local use.
- Multi-sink configuration should be standardised across services.
- Additional logging frameworks require explicit justification.

## Compliance 📏

- New Go code uses `zap` for structured logging.
- Log levels are configured and used consistently.
- Multi-sink outputs are configured for file and console where required.

## Notes 🔗

- Tech Radar: `./Tech_Radar.md`

## Actions ✅

- [x] Copilot, 2026-02-08, update Tech Radar with the Go stack selection

## Tags 🏷️

`#observability #maintainability #simplicity`
