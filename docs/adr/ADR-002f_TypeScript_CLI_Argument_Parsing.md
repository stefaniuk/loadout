# ADR-002f: TypeScript CLI argument parsing 🧾

> |              |                                                 |
> | ------------ | ----------------------------------------------- |
> | Date         | `2026-02-08` when the decision was last updated |
> | Status       | `Accepted`                                      |
> | Significance | `Interfaces & contracts`                        |

---

- [ADR-002f: TypeScript CLI argument parsing 🧾](#adr-002f-typescript-cli-argument-parsing-)
  - [Context 🧭](#context-)
  - [Decision ✅](#decision-)
    - [Assumptions 🧩](#assumptions-)
    - [Drivers 🎯](#drivers-)
    - [Options 🔀](#options-)
      - [Option A: commander (Selected) ✅](#option-a-commander-selected-)
      - [Option B: yargs](#option-b-yargs)
      - [Option C: oclif](#option-c-oclif)
      - [Option D: clipanion](#option-d-clipanion)
      - [Option E: cac](#option-e-cac)
    - [Outcome 🏁](#outcome-)
    - [Rationale 🧠](#rationale-)
  - [Consequences ⚖️](#consequences-️)
  - [Compliance 📏](#compliance-)
  - [Notes 🔗](#notes-)
  - [Actions ✅](#actions-)
  - [Tags 🏷️](#tags-️)

## Context 🧭

TypeScript tools need a CLI parsing library that supports subcommands, clear
help output, and a predictable API.

## Decision ✅

### Assumptions 🧩

- Node.js 24.13.0 (LTS) is the baseline runtime.
- TypeScript 5.9 is the baseline language version.
- CLIs should provide consistent `--help` output and exit codes.

### Drivers 🎯

- Subcommand support and help output quality
- TypeScript typings and API ergonomics
- Ecosystem adoption and maintenance
- Reasonable dependency footprint
- Ease of onboarding

### Options 🔀

#### Option A: commander (Selected) ✅

Use [`commander`](https://github.com/tj/commander.js) for CLI parsing.

| Criteria           | Score/Notes                      |
| ------------------ | -------------------------------- |
| Features           | ⭐⭐⭐ Rich subcommands and help |
| TypeScript support | ⭐⭐ Good typings                |
| Ease of use        | ⭐⭐⭐ Simple API                |
| Maintenance        | ⭐⭐⭐ Widely used and stable    |
| Dependencies       | ⭐⭐ External dependency         |
| Effort             | S                                |

#### Option B: yargs

Use [`yargs`](https://github.com/yargs/yargs) for command parsing.

| Criteria           | Score/Notes                      |
| ------------------ | -------------------------------- |
| Features           | ⭐⭐⭐ Strong subcommand support |
| TypeScript support | ⭐⭐ Good typings                |
| Ease of use        | ⭐⭐ More configuration          |
| Maintenance        | ⭐⭐⭐ Stable and popular        |
| Dependencies       | ⭐⭐ External dependency         |
| Effort             | M                                |

**Why not chosen**: More configuration than commander for similar features.

#### Option C: oclif

Use [`oclif`](https://github.com/oclif/oclif) for large CLI frameworks.

| Criteria           | Score/Notes                          |
| ------------------ | ------------------------------------ |
| Features           | ⭐⭐⭐ Very feature-rich             |
| TypeScript support | ⭐⭐⭐ TypeScript-first              |
| Ease of use        | ⭐⭐ Heavier framework               |
| Maintenance        | ⭐⭐⭐ Active and well supported     |
| Dependencies       | ⭐ Low, heavier dependency footprint |
| Effort             | M                                    |

**Why not chosen**: Heavier framework than needed for typical CLIs.

#### Option D: clipanion

Use [`clipanion`](https://github.com/arcanis/clipanion) for typed command trees.

| Criteria           | Score/Notes                       |
| ------------------ | --------------------------------- |
| Features           | ⭐⭐ Good but less common         |
| TypeScript support | ⭐⭐⭐ Strong typings             |
| Ease of use        | ⭐⭐ Different API style          |
| Maintenance        | ⭐⭐ Active but smaller ecosystem |
| Dependencies       | ⭐⭐ External dependency          |
| Effort             | M                                 |

**Why not chosen**: Smaller ecosystem and less conventional API style.

#### Option E: cac

Use [`cac`](https://github.com/cacjs/cac) for lightweight CLI parsing.

| Criteria           | Score/Notes                       |
| ------------------ | --------------------------------- |
| Features           | ⭐⭐ Good for simple CLIs         |
| TypeScript support | ⭐⭐ Basic typings                |
| Ease of use        | ⭐⭐⭐ Minimal and clean API      |
| Maintenance        | ⭐⭐ Active but smaller ecosystem |
| Dependencies       | ⭐⭐⭐ Lightweight                |
| Effort             | M                                 |

**Why not chosen**: Great for small tools, but less capable for larger CLIs.

### Outcome 🏁

Adopt `commander` as the default CLI argument parsing library. This decision is
reversible if a better standard emerges.

### Rationale 🧠

`commander` balances features, stability, and ease of use, making it a reliable
default for CLI tooling.

## Consequences ⚖️

- New CLIs should use commander by default.
- Alternative frameworks require explicit justification.

## Compliance 📏

- CLI entrypoints use commander and include `--help` output.

## Notes 🔗

- Tech Radar: `./Tech_Radar.md`

## Actions ✅

- [x] Copilot, 2026-02-08, record the CLI parsing decision

## Tags 🏷️

`#usability #interfaces #maintainability`
