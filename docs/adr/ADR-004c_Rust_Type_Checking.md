# ADR-004c: Rust type checking 🧾

> |              |                                                 |
> | ------------ | ----------------------------------------------- |
> | Date         | `2026-02-08` when the decision was last updated |
> | Status       | `Accepted`                                      |
> | Significance | `Quality attributes`                            |

---

- [ADR-004c: Rust type checking 🧾](#adr-004c-rust-type-checking-)
  - [Context 🧭](#context-)
  - [Decision ✅](#decision-)
    - [Assumptions 🧩](#assumptions-)
    - [Drivers 🎯](#drivers-)
    - [Options 🔀](#options-)
      - [Option A: rustc via cargo check (Selected) ✅](#option-a-rustc-via-cargo-check-selected-)
      - [Option B: rust-analyzer diagnostics](#option-b-rust-analyzer-diagnostics)
      - [Option C: clippy (type-aware linting)](#option-c-clippy-type-aware-linting)
      - [Option D: Miri](#option-d-miri)
      - [Option E: Kani](#option-e-kani)
    - [Outcome 🏁](#outcome-)
    - [Rationale 🧠](#rationale-)
  - [Consequences ⚖️](#consequences-️)
  - [Compliance 📏](#compliance-)
  - [Notes 🔗](#notes-)
  - [Actions ✅](#actions-)
  - [Tags 🏷️](#tags-️)

## Context 🧭

Rust includes static type checking in the compiler. The tech stack still needs a
standard approach for CI-friendly type checking and fast developer feedback.

## Decision ✅

### Assumptions 🧩

- Rust 1.93.0 is the baseline toolchain.
- Type checking must run in CI as a blocking gate.
- Developer workflows should remain fast.

### Drivers 🎯

- Compiler-parity type checking
- Fast feedback in CI
- Minimal extra tooling
- Clear diagnostics
- Long-term maintenance

### Options 🔀

#### Option A: rustc via cargo check (Selected) ✅

Use `cargo check` (Rust compiler) for type checking without producing binaries.

| Criteria         | Score/Notes                          |
| ---------------- | ------------------------------------ |
| Type accuracy    | ⭐⭐⭐ Compiler source of truth      |
| CI integration   | ⭐⭐⭐ Standard Rust workflow        |
| Performance      | ⭐⭐⭐ Fast compared with full build |
| Tooling overhead | ⭐⭐⭐ No extra tools                |
| Maintenance      | ⭐⭐⭐ Official toolchain            |
| Effort           | S                                    |

#### Option B: rust-analyzer diagnostics

Use [`rust-analyzer`](https://github.com/rust-lang/rust-analyzer) diagnostics
for editor checks.

| Criteria         | Score/Notes                      |
| ---------------- | -------------------------------- |
| Type accuracy    | ⭐⭐ Good but not the compiler   |
| CI integration   | ⭐ Low, editor-focused           |
| Performance      | ⭐⭐⭐ Fast for local use        |
| Tooling overhead | ⭐⭐ Requires editor integration |
| Maintenance      | ⭐⭐⭐ Active                    |
| Effort           | M                                |

**Why not chosen**: Editor-first, not suitable for CI enforcement.

#### Option C: clippy (type-aware linting)

Use [`clippy`](https://github.com/rust-lang/rust-clippy) for type-aware linting.

| Criteria         | Score/Notes                            |
| ---------------- | -------------------------------------- |
| Type accuracy    | ⭐⭐ Uses compiler but adds lint focus |
| CI integration   | ⭐⭐ Good as a lint step               |
| Performance      | ⭐⭐ Slower than cargo check           |
| Tooling overhead | ⭐⭐ Additional lint config            |
| Maintenance      | ⭐⭐⭐ Official tool                   |
| Effort           | M                                      |

**Why not chosen**: A linting tool, not a dedicated type checker.

#### Option D: Miri

Use [`Miri`](https://github.com/rust-lang/miri) for undefined behaviour checks.

| Criteria         | Score/Notes                            |
| ---------------- | -------------------------------------- |
| Type accuracy    | ⭐⭐ Strong for UB, not general typing |
| CI integration   | ⭐ Low, slower and nightly             |
| Performance      | ⭐ Low on larger codebases             |
| Tooling overhead | ⭐ Low, nightly toolchain              |
| Maintenance      | ⭐⭐⭐ Active                          |
| Effort           | M                                      |

**Why not chosen**: Great for UB checks but too slow and specialised for default
type checking.

#### Option E: Kani

Use [`Kani`](https://github.com/model-checking/kani) for formal verification.

| Criteria         | Score/Notes                              |
| ---------------- | ---------------------------------------- |
| Type accuracy    | ⭐⭐ Focuses on verification, not typing |
| CI integration   | ⭐ Low, heavy setup                      |
| Performance      | ⭐ Low on complex code                   |
| Tooling overhead | ⭐ Low, specialised toolchain            |
| Maintenance      | ⭐⭐ Active but niche                    |
| Effort           | L                                        |

**Why not chosen**: Valuable for verification but too heavy for default type
checks.

### Outcome 🏁

Adopt `cargo check` as the default type-checking command. This decision is
reversible if tooling changes.

### Rationale 🧠

`cargo check` uses the compiler directly, giving accurate diagnostics with fast
feedback and minimal overhead.

## Consequences ⚖️

- CI must run `cargo check` for Rust projects.
- Additional verification tools require explicit justification.

## Compliance 📏

- `cargo check` succeeds in CI.

## Notes 🔗

- Tech Radar: `./Tech_Radar.md`

## Actions ✅

- [x] Copilot, 2026-02-08, record the type checking decision

## Tags 🏷️

`#quality #correctness #maintainability`
