# ADR-004e: Rust logging 🧾

> |              |                                                 |
> | ------------ | ----------------------------------------------- |
> | Date         | `2026-02-08` when the decision was last updated |
> | Status       | `Accepted`                                      |
> | Significance | `Quality attributes, Operations`                |

---

- [ADR-004e: Rust logging 🧾](#adr-004e-rust-logging-)
  - [Context 🧭](#context-)
  - [Decision ✅](#decision-)
    - [Assumptions 🧩](#assumptions-)
    - [Drivers 🎯](#drivers-)
    - [Options 🔀](#options-)
      - [Option A: tracing (Selected) ✅](#option-a-tracing-selected-)
      - [Option B: log + env_logger](#option-b-log--env_logger)
      - [Option C: slog](#option-c-slog)
      - [Option D: log4rs](#option-d-log4rs)
      - [Option E: fern](#option-e-fern)
    - [Outcome 🏁](#outcome-)
    - [Rationale 🧠](#rationale-)
  - [Consequences ⚖️](#consequences-️)
  - [Compliance 📏](#compliance-)
  - [Notes 🔗](#notes-)
  - [Actions ✅](#actions-)
  - [Tags 🏷️](#tags-️)

## Context 🧭

The Rust tech stack needs a default logging approach that supports structured
logs, multi-sink output, and good local console readability.

## Decision ✅

### Assumptions 🧩

- Rust 1.93.0 is the baseline toolchain.
- Structured logs are required for services.
- Local developer output should remain readable.

### Drivers 🎯

- Structured logging support with JSON output
- Multi-sink management (JSON to file and readable console output)
- Pretty, coloured console output for local use
- Log levels and filtering support
- Performance suitable for services and CLIs
- Low dependency footprint
- Ecosystem support and longevity

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

#### Option A: tracing (Selected) ✅

Use [`tracing`](https://github.com/tokio-rs/tracing) with
[`tracing-subscriber`](https://github.com/tokio-rs/tracing) for JSON and console
output.

| Criteria                 | Score/Notes                              |
| ------------------------ | ---------------------------------------- |
| Structured logging       | ⭐⭐⭐ Designed for structured events    |
| Multi-sink management    | ⭐⭐⭐ Subscriber layers support fan-out |
| Console pretty/colour    | ⭐⭐ Pretty formatter available          |
| Log levels and filtering | ⭐⭐⭐ Strong filtering controls         |
| Performance              | ⭐⭐ Good for most services              |
| Dependency footprint     | ⭐⭐ External dependency                 |
| Ecosystem support        | ⭐⭐⭐ Widely adopted in Rust services   |
| Effort                   | M                                        |
| Weighted score (max 69)  | 62                                       |

#### Option B: log + env_logger

Use [`log`](https://github.com/rust-lang/log) with
[`env_logger`](https://github.com/env-logger-rs/env_logger).

| Criteria                 | Score/Notes                        |
| ------------------------ | ---------------------------------- |
| Structured logging       | ⭐ Requires custom JSON formatting |
| Multi-sink management    | ⭐⭐ Limited without extra setup   |
| Console pretty/colour    | ⭐⭐ Basic formatting              |
| Log levels and filtering | ⭐⭐⭐ Strong level support        |
| Performance              | ⭐⭐ Good                          |
| Dependency footprint     | ⭐⭐ External dependencies         |
| Ecosystem support        | ⭐⭐⭐ Very common                 |
| Effort                   | M                                  |
| Weighted score (max 69)  | 49                                 |

**Why not chosen**: Structured logging is not first-class without extra tooling.

#### Option C: slog

Use [`slog`](https://github.com/slog-rs/slog) for structured logging.

| Criteria                 | Score/Notes                           |
| ------------------------ | ------------------------------------- |
| Structured logging       | ⭐⭐⭐ Strong structured design       |
| Multi-sink management    | ⭐⭐ Supports drains with extra setup |
| Console pretty/colour    | ⭐⭐ Available with extra crates      |
| Log levels and filtering | ⭐⭐⭐ Strong level support           |
| Performance              | ⭐⭐ Good                             |
| Dependency footprint     | ⭐⭐ External dependency              |
| Ecosystem support        | ⭐⭐ Moderate adoption                |
| Effort                   | M                                     |
| Weighted score (max 69)  | 56                                    |

**Why not chosen**: Less standard than tracing in modern Rust services.

#### Option D: log4rs

Use [`log4rs`](https://github.com/estk/log4rs) for structured logging with
configuration files.

| Criteria                 | Score/Notes                          |
| ------------------------ | ------------------------------------ |
| Structured logging       | ⭐⭐ JSON support with configuration |
| Multi-sink management    | ⭐⭐⭐ Strong appender system        |
| Console pretty/colour    | ⭐⭐ Supports coloured output        |
| Log levels and filtering | ⭐⭐⭐ Strong level support          |
| Performance              | ⭐⭐ Reasonable                      |
| Dependency footprint     | ⭐⭐ External dependency             |
| Ecosystem support        | ⭐⭐ Moderate adoption               |
| Effort                   | M                                    |
| Weighted score (max 69)  | 55                                   |

**Why not chosen**: Configuration-heavy compared with tracing.

#### Option E: fern

Use [`fern`](https://github.com/daboross/fern) for logging setup.

| Criteria                 | Score/Notes                         |
| ------------------------ | ----------------------------------- |
| Structured logging       | ⭐⭐ Supports JSON with extra setup |
| Multi-sink management    | ⭐⭐ Supports chaining              |
| Console pretty/colour    | ⭐⭐ Supports colours               |
| Log levels and filtering | ⭐⭐⭐ Strong level support         |
| Performance              | ⭐⭐ Good                           |
| Dependency footprint     | ⭐⭐ External dependency            |
| Ecosystem support        | ⭐⭐ Moderate adoption              |
| Effort                   | M                                   |
| Weighted score (max 69)  | 52                                  |

**Why not chosen**: Requires more manual setup and has a smaller ecosystem.

### Outcome 🏁

Adopt `tracing` as the default logging library for Rust. This decision is
reversible if ecosystem support shifts.

### Rationale 🧠

Using the weighted criteria, `tracing` scores highest because it provides
structured logging with good fan-out support and modern ecosystem adoption.

## Consequences ⚖️

- Rust services should use tracing with JSON file output and console formatting.
- Alternative logging frameworks require explicit justification.

## Compliance 📏

- New services emit structured JSON logs with level and event fields.
- Multi-sink logging (file and console) is configured where required.

## Notes 🔗

- Tech Radar: `./Tech_Radar.md`

## Actions ✅

- [x] Copilot, 2026-02-08, record the logging decision

## Tags 🏷️

`#observability #maintainability #operability`
