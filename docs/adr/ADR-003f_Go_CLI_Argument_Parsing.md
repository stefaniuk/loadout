# ADR-003f: Go CLI argument parsing 🧾

> |              |                                                 |
> | ------------ | ----------------------------------------------- |
> | Date         | `2026-02-08` when the decision was last updated |
> | Status       | `Accepted`                                      |
> | Significance | `Interfaces & contracts`                        |

---

- [ADR-003f: Go CLI argument parsing 🧾](#adr-003f-go-cli-argument-parsing-)
  - [Context 🧭](#context-)
  - [Decision ✅](#decision-)
    - [Assumptions 🧩](#assumptions-)
    - [Drivers 🎯](#drivers-)
    - [Options 🔀](#options-)
      - [Option A: cobra (Selected) ✅](#option-a-cobra-selected-)
      - [Option B: urfave/cli](#option-b-urfavecli)
      - [Option C: kong](#option-c-kong)
      - [Option D: kingpin](#option-d-kingpin)
      - [Option E: flag (standard library)](#option-e-flag-standard-library)
    - [Outcome 🏁](#outcome-)
    - [Rationale 🧠](#rationale-)
  - [Consequences ⚖️](#consequences-️)
  - [Compliance 📏](#compliance-)
  - [Notes 🔗](#notes-)
  - [Actions ✅](#actions-)
  - [Tags 🏷️](#tags-️)

## Context 🧭

The Go tech stack needs a CLI argument parsing library for tools and scripts.
The choice should support subcommands, help text, and shell completion, with
minimal friction for developers. The user asked for at least five alternatives
to be compared.

## Decision ✅

### Assumptions 🧩

- Go 1.25.7 is the baseline toolchain.
- CLIs should offer consistent help output and subcommands.
- The library should be stable and well supported.

### Drivers 🎯

- Rich CLI features, including subcommands and completion
- Clear and consistent help output
- Active maintenance and community adoption
- Low friction for new contributors
- Reasonable dependency footprint

### Options 🔀

#### Option A: cobra (Selected) ✅

Use [`cobra`](https://github.com/spf13/cobra) for feature-rich CLI parsing and
command structure.

| Criteria     | Score/Notes                               |
| ------------ | ----------------------------------------- |
| Features     | ⭐⭐⭐ Subcommands, completion, rich help |
| Ease of use  | ⭐⭐ Widely documented                    |
| Maintenance  | ⭐⭐⭐ Active and popular                 |
| Dependencies | ⭐⭐ Moderate                             |
| Effort       | M                                         |

#### Option B: urfave/cli

Use [`urfave/cli`](https://github.com/urfave/cli) for straightforward command
structures.

| Criteria     | Score/Notes                    |
| ------------ | ------------------------------ |
| Features     | ⭐⭐ Good but fewer than cobra |
| Ease of use  | ⭐⭐ Clear API                 |
| Maintenance  | ⭐⭐ Active                    |
| Dependencies | ⭐⭐ Moderate                  |
| Effort       | M                              |

**Why not chosen**: Fewer built-in features for completion and larger CLI
ecosystems.

#### Option C: kong

Use [`kong`](https://github.com/alecthomas/kong) for struct-tag driven CLI
parsing.

| Criteria     | Score/Notes                                    |
| ------------ | ---------------------------------------------- |
| Features     | ⭐⭐ Strong parsing, less focus on subcommands |
| Ease of use  | ⭐⭐ Requires struct tags and conventions      |
| Maintenance  | ⭐⭐ Active                                    |
| Dependencies | ⭐⭐ Moderate                                  |
| Effort       | M                                              |

**Why not chosen**: Different style and less standard for multi-command CLIs.

#### Option D: kingpin

Use [`kingpin`](https://github.com/alecthomas/kingpin) for flag parsing and
subcommands.

| Criteria     | Score/Notes                       |
| ------------ | --------------------------------- |
| Features     | ⭐⭐ Good but project is archived |
| Ease of use  | ⭐⭐ Simple API                   |
| Maintenance  | ⭐ Low, no longer active          |
| Dependencies | ⭐⭐ Moderate                     |
| Effort       | M                                 |

**Why not chosen**: Archived project and no active maintenance.

#### Option E: flag (standard library)

Use the standard [`flag`](https://github.com/golang/go) package.

| Criteria     | Score/Notes                   |
| ------------ | ----------------------------- |
| Features     | ⭐ Low, no subcommand support |
| Ease of use  | ⭐⭐ Simple but limited       |
| Maintenance  | ⭐⭐⭐ Standard library       |
| Dependencies | ⭐⭐⭐ None                   |
| Effort       | S                             |

**Why not chosen**: Too limited for most multi-command CLIs.

### Outcome 🏁

Adopt `cobra` as the default CLI argument parsing library for Go tools. This
decision is reversible if a simpler approach becomes more appropriate or if
maintenance changes.

### Rationale 🧠

`cobra` is the most widely used Go CLI framework, with strong support for
subcommands, help output, and shell completion. It is well documented and
supported, making it a practical default.

## Consequences ⚖️

- Go CLIs should be structured around `cobra` commands by default.
- Smaller scripts may still use `flag` when appropriate, but it should be
  justified.

## Compliance 📏

- New multi-command CLIs use `cobra` unless an exception is documented.

## Notes 🔗

- Tech Radar: `./Tech_Radar.md`

## Actions ✅

- [x] Copilot, 2026-02-08, update Tech Radar with the Go stack selection

## Tags 🏷️

`#usability #maintainability #interfaces`
