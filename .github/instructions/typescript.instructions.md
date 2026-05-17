---
applyTo: "**/*.{js,ts,tsx}"
description: "TypeScript Engineering Instructions (CLI + API + UI, framework-agnostic)"
---

# TypeScript Engineering Instructions (CLI + API + UI, framework-agnostic) 🟦

These instructions define the default engineering approach for building **modern, production-grade TypeScript** systems (services, CLIs, libraries, and web apps).

They must remain applicable to:

- Node.js services (REST/GraphQL/events), serverless, and workers
- Web apps (SPA/SSR), SDKs, and shared libraries
- Monorepos (workspaces) and single-package repos
- Mixed TS/JS repos during migration

They are **non-negotiable** unless an exception is explicitly documented (with rationale and expiry) in an ADR/decision record.

**Identifier scheme.** Every normative rule carries a unique tag in the form `[TS-<prefix>-NNN]`, where the prefix maps to the containing section (for example `OP` for Operating Principles, `LCL` for Local-first developer experience, `QG` for Quality Gates, continuing through `AI` for AI-assisted expectations). Use these identifiers when referencing, planning, or validating requirements.

---

## 0. Quick reference (apply first) 🧠

This section exists so humans and AI assistants can reliably apply the most important rules even when context is tight.

- [TS-QR-001] **Specification first**: treat the specification as the source of truth for behaviour ([TS-OP-001]).
- [TS-QR-002] **Small, safe changes**: prefer small, explicit, testable changes ([TS-OP-002], [TS-OP-004]).
- [TS-QR-003] **Fast feedback**: local development and tests must be quick and confidence-building ([TS-OP-005], [TS-LCL-001]–[TS-LCL-007]).
- [TS-QR-004] **Run the quality gates** after any code/test change and iterate to clean ([TS-QG-001]–[TS-QG-006]).
- [TS-QR-005] **Strict TypeScript**: `strict: true` is non-negotiable; treat `any` as a last resort ([TS-TSC-001]–[TS-TSC-004]).
- [TS-QR-006] **Validate at boundaries** and reject ambiguous inputs ([TS-DATA-001]–[TS-DATA-003], [TS-BEH-007]–[TS-BEH-008]).
- [TS-QR-007] **Deterministic outputs**: stable ordering, stable formatting, no hidden randomness ([TS-OP-003], [TS-BEH-001]–[TS-BEH-002]).
- [TS-QR-008] **Correct CLI streams**: stdout for primary output, stderr for diagnostics ([TS-BEH-016]–[TS-BEH-018]).
- [TS-QR-009] **Async correctness**: no fire-and-forget promises; explicit timeouts on outbound calls ([TS-BEH-003]–[TS-BEH-006]).
- [TS-QR-010] **No secrets in args or logs**: use env vars or secret managers; never log secrets ([TS-SEC-005]–[TS-SEC-008]).
- [TS-QR-011] **Local by default**: no real cloud/network by default; use fakes/emulators; explicit integration mode switches ([TS-EXT-001]–[TS-EXT-004]).
- [TS-QR-012] **Operational visibility**: correlation IDs and structured logs for services ([TS-OBS-001]–[TS-OBS-007]).
- [TS-QR-013] **Accessible UI by default**: meet WCAG 2.2 AA expectations; keyboard-first and semantic HTML ([TS-UI-001]–[TS-UI-013]).
- [TS-QR-014] **UI performance**: design for Core Web Vitals and fast interaction feedback ([TS-UI-020]–[TS-UI-027]).
- [TS-QR-015] **Function size limit**: split functions exceeding ~50 lines or 3 levels of nesting ([TS-CODE-017]).
- [TS-QR-016] **Module size limit**: keep modules under ~500 lines excluding tests ([TS-CODE-018]).

---

## 1. Operating principles 🧭

These principles extend [constitution.md §3](../../.specify/memory/constitution.md#3-core-principles-non-negotiable).

- [TS-OP-001] Treat the **specification as the source of truth** for behaviour. If behaviour is not specified, it does not exist.
- [TS-OP-002] Prefer **small, explicit, testable** changes over broad rewrites or large refactors.
- [TS-OP-003] Design for **determinism** (stable outputs for the same inputs) and:
  - [TS-OP-003a] **operability** (clear errors, easy diagnosis) for CLIs
  - [TS-OP-003b] **observability** (you can explain what happened and why) for services
- [TS-OP-004] Optimise for **maintenance, usability/operability, and change safety**, not cleverness.
- [TS-OP-005] **Fast feedback is paramount**: local development must be quick, automated, and confidence-building.
- [TS-OP-006] Avoid inventing requirements, widening scope, or introducing behaviour not present in the specification.
- [TS-OP-007] Prefer **type-driven design**: make illegal states unrepresentable, validate at boundaries, keep domain logic pure.
- [TS-OP-008] Avoid heavyweight work at import/module-load time (slow startup, surprises in tests). Initialise heavy resources lazily or behind explicit entrypoints.
- [TS-OP-009] Keep global state minimal and explicit. Prefer dependency injection and explicit wiring over hidden module-level singletons.
- [TS-OP-010] Record design trade-offs and assumptions when behaviour is not obvious so future engineers understand the intent.

---

## 2. Local-first developer experience (bleeding-edge fast feedback) ⚡

The system must be **fully developable and testable locally**, even when it integrates with external services as part of a larger system.

Follow the shared [local-first developer experience baseline](./includes/local-first-dev-baseline.include.md) for common expectations, plus the language-specific requirements below.

### 2.1 Single-command workflow (must exist)

Provide repository-standard commands so an engineer can do the following quickly:

- [TS-LCL-001] Bootstrap: `make deps` — installs tooling and dependencies, and prepares a usable local environment
- [TS-LCL-002] Format: `make format`
- [TS-LCL-003] Lint: `make lint`
- [TS-LCL-004] Type-check: `make typecheck`
- [TS-LCL-005] Test (fast lane): `make test` — must run quickly (aim: < 10 seconds for unit-only; provide another target for slower tests) and deterministically
- [TS-LCL-006] Full suite: `make test-all` — includes integration/e2e tiers where applicable
- [TS-LCL-007] Run (dev): `make run` — runs with safe defaults (**no cloud dependencies by default**)

### 2.2 Reproducible toolchain (avoid "works on my machine")

- [TS-LCL-008] Pin the runtime version:
  - [TS-LCL-008a] Node.js: `.nvmrc`, `.node-version`, and/or `engines.node` in `package.json`
- [TS-LCL-009] Use a workspace-aware package manager where relevant (prefer `pnpm` for most repos).
- [TS-LCL-010] Commit and enforce a lock file.
- [TS-LCL-011] Prefer `corepack` (when supported) to pin package manager versions.
- [TS-LCL-012] Keep the toolchain minimal and fast:
  - TypeScript (`tsc`) for typechecking
  - ESLint + typescript-eslint for linting (or the repository-approved alternative)
  - Prettier or Biome for formatting (choose one; avoid double-formatting)
  - A modern test runner (see §14)

### 2.3 Pre-commit hooks (strongly recommended)

Provide a `pre-commit`, Husky, or equivalent configuration that runs the same checks as CI in a fast, local-friendly way:

- [TS-LCL-013] formatting
- [TS-LCL-014] linting
- [TS-LCL-015] typecheck (when fast enough; otherwise CI-only)
- [TS-LCL-016] tests (fast lane)
- [TS-LCL-017] secret scanning (for example gitleaks)

### 2.4 OCI images for parity and zero-setup (strongly recommended)

Provide an OCI-based option so behaviour is consistent across laptops and CI:

- [TS-LCL-018] A lightweight dev image that includes:
  - [TS-LCL-018a] Node.js + locked dependencies
  - [TS-LCL-018b] lint/test/typecheck tooling
  - [TS-LCL-018c] any required system packages
- [TS-LCL-019] Provide one command to use it:
  - `make docker-test` / `make docker-run` (or Dev Containers), etc.

- [TS-LCL-020] OCI support must be **optional** (native dev still works), but it must be maintained.
- [TS-LCL-021] Never bake secrets into images.
- [TS-LCL-022] The same commands (`make lint`, `make typecheck`, `make test`) must work inside and outside the container.

### 2.5 Fast iteration patterns (recommended)

- [TS-LCL-023] Support watch mode when feasible (for example `make test-watch`).
- [TS-LCL-024] Support parallel tests where safe.
- [TS-LCL-025] Provide clear test markers and commands:
  - [TS-LCL-025a] `make test-unit`
  - [TS-LCL-025b] `make test-integration`
  - [TS-LCL-025c] `make test-e2e`

### 2.6 Test tiers (must adopt)

Define clear tiers with predictable markers/commands:

- [TS-LCL-026] Unit (default): no network, no containers
- [TS-LCL-027] Integration: uses containers/emulators; still local and repeatable
- [TS-LCL-028] End-to-end (few): critical journeys only; time-boxed

### 2.7 System dependencies and runtime parity (recommended)

- [TS-LCL-029] If the project needs OS/system packages, pin and document them (Dev Container, OCI dev image, or a clear install script).
- [TS-LCL-030] Keep local defaults safe: local dev must not require real cloud credentials, and must not mutate real cloud resources by default.
- [TS-LCL-031] Document the supported runtime execution modes (local native, containerised, CI) and keep the core commands consistent across them ([TS-LCL-022]).
- [TS-LCL-032] Where supported by your tooling, provide a single "environment check" command (for example `make doctor`) that confirms local prerequisites and surfaces actionable fixes.

---

## 3. Mandatory local quality gates ✅

Per [constitution.md §7.8](../../.specify/memory/constitution.md#78-mandatory-local-quality-gates), after making **any** change to implementation code or tests, you must run the repository's **canonical** quality gates:

1. Prefer:
   - [TS-QG-001] `make format`
   - [TS-QG-002] `make lint`
   - [TS-QG-003] `make typecheck`
   - [TS-QG-004] `make test`

2. If `make` targets do not exist, discover and run the equivalent commands (for example `pnpm lint`, `pnpm -s typecheck`, `pnpm -s test`).
   - [TS-QG-005] Follow the shared [quality gates baseline](./includes/quality-gates-baseline.include.md) for iteration and warning handling rules.
   - [TS-QG-006] Follow the shared [quality gates baseline](./includes/quality-gates-baseline.include.md) for command selection and equivalents.
   - [TS-QG-007] Follow the shared [quality gates baseline](./includes/quality-gates-baseline.include.md) for repository-target usage.

---

## 4. Contracts and public surface area 📜

TypeScript projects have contracts, even when they are "just code"; treat every boundary as intentional.

### 4.1 Public API contract (libraries/SDKs)

- [TS-CTR-001] Treat exported symbols as a **stable interface contract**.
- [TS-CTR-002] Changes to exports must be intentional, documented, and reviewable.
- [TS-CTR-003] Prefer additive evolution over breaking changes.
- [TS-CTR-004] Use `exports` in `package.json` for libraries, with explicit entrypoints.
- [TS-CTR-005] Publish type declarations (`.d.ts`) and keep them accurate.

### 4.2 Runtime contract (services/CLIs)

- [TS-CTR-006] Treat inputs and outputs as contracts:
  - HTTP semantics, payload shapes, status codes, headers
  - CLI flags, defaults, exit codes, stdout/stderr behaviour
  - Event/message schemas (topics, attributes, versioning)
- [TS-CTR-007] Backwards-incompatible changes must be intentional, documented, and reviewable.
- [TS-CTR-008] When versioning is required, use one consistent scheme (document it).

### 4.3 CLI contract and user experience (applies to CLIs) ⌨️

#### CLI is a contract (not an accident)

- [TS-CTR-009] Treat the CLI as a **stable interface contract**:
  - [TS-CTR-009a] command names and subcommands
  - [TS-CTR-009b] flags/options and defaults
  - [TS-CTR-009c] argument parsing rules
  - [TS-CTR-009d] exit codes
  - [TS-CTR-009e] stdout/stderr behaviour
  - [TS-CTR-009f] output formats
- [TS-CTR-009g] CLI entrypoints must remain thin adapters per the shared [CLI contract](./includes/cli-contract-baseline.include.md#5-wrappers-and-shared-libraries): parse + validate input, delegate to shared modules, and forward exit codes instead of duplicating business logic.
- [TS-CTR-009h] When CLIs run inside managed runtimes (Lambda, Cloud Run, Functions), follow the [CLI contract cloud guidance](./includes/cli-contract-baseline.include.md#6-cloud-and-serverless-workloads): keep stdout/stderr compact, avoid ANSI noise unless supported, and flush streams explicitly before exit.
- [TS-CTR-010] Backwards-incompatible changes must be **intentional, documented, and reviewable**.

#### Help, discoverability, and documentation

- [TS-CTR-011] Every command must have:
  - [TS-CTR-011a] a clear one-line summary
  - [TS-CTR-011b] detailed `--help` text (including examples)
  - [TS-CTR-011c] explicit argument/option descriptions
- [TS-CTR-012] Prefer consistent option patterns:
  - `--verbose`, `--quiet`
  - `--format` for output formats
  - `--output` for output paths
  - `--dry-run` for non-destructive preview
- [TS-CTR-013] Examples must match real usage and be copy-paste ready.

#### Output compatibility (humans and automation)

- [TS-CTR-014] Support both:
  - [TS-CTR-014a] **human-readable** output (default), and
  - [TS-CTR-014b] **machine-readable** output (when applicable), for example `--format json` or `--json`.
- [TS-CTR-015] Never mix progress/status messages into structured output.

### 4.4 API contract and surface area (applies to APIs) 🌐

- [TS-CTR-016] Treat the external API as a **stable contract** (HTTP semantics, payload shapes, status codes, headers).
- [TS-CTR-017] Changes to the contract must be **intentional, documented, and reviewable**.
- [TS-CTR-018] Prefer backward-compatible changes. When breaking changes are necessary:
  - [TS-CTR-018a] make them explicit
  - [TS-CTR-018b] provide a migration path
  - [TS-CTR-018c] version the API where appropriate

#### Versioning policy

- [TS-CTR-019] Prefer **non-breaking evolution** (additive fields, new endpoints, optional query parameters).
- [TS-CTR-020] If versioning is required:
  - use a consistent scheme (for example `/v1/` path prefix or content negotiation)
  - avoid ad-hoc per-endpoint versioning

#### OpenAPI / schema outputs (where supported)

- [TS-CTR-021] If the framework can generate OpenAPI or an equivalent schema, treat it as **first-class**:
  - [TS-CTR-021a] accurate request/response models
  - [TS-CTR-021b] clear summaries/descriptions
  - [TS-CTR-021c] examples when they reduce ambiguity
- [TS-CTR-022] Do not leak internal persistence models or implementation details into the contract.

---

## 5. TypeScript configuration and compiler discipline 🧩

### 5.1 Strictness (non-negotiable)

- [TS-TSC-001] Enable `strict: true` unless an ADR explicitly documents why not.
- [TS-TSC-002] Treat `any` as a last resort:
  - [TS-TSC-002a] prefer `unknown` at boundaries, then narrow
  - [TS-TSC-002b] use `never` to prove impossible states
- [TS-TSC-003] Prefer safer options for modern codebases (unless they cause disproportionate migration cost):
  - `noUncheckedIndexedAccess`
  - `exactOptionalPropertyTypes`
  - `useUnknownInCatchVariables`
  - `noImplicitOverride` (when using inheritance)

### 5.2 Module system (choose deliberately)

- [TS-TSC-004] Choose ESM vs CJS deliberately and document the choice.
- [TS-TSC-005] Prefer ESM for new code where the runtime/tooling supports it.
- [TS-TSC-006] Use consistent module resolution across the repo (`NodeNext`/`Bundler`/`Node`) and avoid per-package drift.

### 5.3 Project references (monorepos and large repos)

- [TS-TSC-007] Use TypeScript project references where it materially improves build performance and layering.
- [TS-TSC-008] Avoid circular references between packages; treat them as architecture defects.

### 5.4 Language target and emit

- [TS-TSC-009] Default to TypeScript 5.x compiling to an ES2022 output baseline unless the runtime explicitly requires a different target; document any deviation.
- [TS-TSC-010] Prefer native platform features over polyfills; if down-level transpilation is required, record the trade-off and the surface it affects.
- [TS-TSC-011] Use pure ES modules for new code and bundling paths; do not emit `require`, `module.exports`, or other CommonJS helpers unless an ADR captures the exception.

### 5.5 Type system usage patterns

- [TS-TSC-012] Model real-time events, finite states, and workflows with discriminated unions so illegal states remain unrepresentable.
- [TS-TSC-013] Centralise shared contracts and DTOs instead of duplicating structural types in multiple modules.
- [TS-TSC-014] Use expressive utility types (`Readonly`, `Partial`, `Record`, etc.) to document intent and reduce bespoke helper types.

---

## 6. Linting, formatting, and code style ✍️

### 6.1 One formatter (non-negotiable)

- [TS-LINT-001] Use exactly one formatter: Prettier **or** Biome (repository choice).
- [TS-LINT-002] Do not fight the formatter. Avoid style rules that duplicate formatting.
- [TS-LINT-003] Enforce formatting in CI and in pre-commit.

### 6.2 ESLint (recommended default)

- [TS-LINT-004] Use ESLint with typescript-eslint for TypeScript-aware linting.
- [TS-LINT-005] Prefer the modern ESLint configuration style (flat config) where supported.
- [TS-LINT-006] Use type-aware linting selectively:
  - enable type-aware rules for high-value packages/modules
  - keep CI time bounded; avoid making every package "full type-aware lint" if it slows feedback loops

### 6.3 Rule intent (avoid cargo-culting)

- [TS-LINT-007] Prefer rules that prevent real production incidents:
  - unsafe promises / missing awaits
  - floating promises
  - unhandled rejections
  - incorrect equality / coercions
  - implicit any / unsafe casts
- [TS-LINT-008] Avoid rules that only enforce personal preference unless the repo agrees.

### 6.4 Style discipline

- [TS-LINT-009] Match the repository's indentation, quote, and trailing comma rules; do not override formatter intent locally.
- [TS-LINT-010] Keep functions and methods tightly scoped; extract helpers when branches or responsibilities multiply.
- [TS-LINT-011] Favour immutable data structures and pure functions when practical to keep reasoning simple.

---

## 7. Behaviour rules 🚦

**Section summary (key subsections):**

- 7.1 Runtime determinism — stable, repeatable outputs
- 7.2 Async correctness — promise handling, timeouts, cancellation
- 7.3 Boundary correctness — input validation and domain conversion
- 7.4 CLI behaviour rules — subcommands, exit codes, stdout/stderr
- 7.5 HTTP behaviour rules — methods, status codes, retries, pagination

### 7.1 Runtime determinism

- [TS-BEH-001] Outputs must be deterministic:
  - [TS-BEH-001a] stable ordering
  - [TS-BEH-001b] stable formatting
  - [TS-BEH-001c] no hidden randomness
- [TS-BEH-002] Time and randomness must be controllable in tests.

### 7.2 Async correctness (non-negotiable)

- [TS-BEH-003] Never "fire and forget" promises unless explicitly specified and safe.
- [TS-BEH-004] Await or explicitly handle promise outcomes (including background tasks).
- [TS-BEH-005] Define timeouts for outbound calls (HTTP, DB, queues).
- [TS-BEH-006] Propagate cancellation where practical (AbortController).

### 7.3 Boundary correctness

- [TS-BEH-007] Do not trust external inputs:
  - [TS-BEH-007a] request bodies, query params, headers
  - [TS-BEH-007b] environment variables and config files
  - [TS-BEH-007c] message/event payloads
  - [TS-BEH-007d] file contents
- [TS-BEH-008] Validate at the boundary, then convert to domain types.

### 7.4 CLI behaviour rules (applies to CLIs) ⌨️

#### Subcommands and composition

- [TS-BEH-009] Prefer a consistent shape: `tool <command> <subcommand> [options]`.
- [TS-BEH-010] Use subcommands to separate behaviours, not positional-argument tricks.
- [TS-BEH-011] Keep commands single-responsibility; avoid "do everything" commands.
- [TS-BEH-011a] If behaviour diverges between the CLI and its shared library implementation, refactor to restore a single source of truth before adding new features.

#### Exit codes (must be consistent)

- [TS-BEH-012] Exit codes must follow the shared [CLI contract](./includes/cli-contract-baseline.include.md#1-exit-codes-non-negotiable) (`0` success, `1` general failure, `2` usage error) unless an ADR records a justified deviation.
- [TS-BEH-013] Never signal failure only via text; exit codes must reflect outcomes.
- [TS-BEH-014] When no specific mapping exists, default to `1` for operational failures per the CLI contract and document any reserved codes.
- [TS-BEH-015] If automation depends on specific failure modes, define, document, and test those exit codes referencing the CLI contract expectations.

#### Stdout vs stderr (non-negotiable)

- [TS-BEH-016] Follow the [CLI contract stream semantics](./includes/cli-contract-baseline.include.md#2-stdout-vs-stderr-stream-semantics): emit primary outputs on `stdout`, diagnostics on `stderr`.
- [TS-BEH-017] Diagnostics (progress, warnings, debug, human-readable errors) must never contaminate `stdout`.
- [TS-BEH-018] Commands must behave correctly when stdout is piped or redirected; no diagnostic leakage to `stdout`.
- [TS-BEH-018a] Flush `stdout`/`stderr` explicitly in short-lived serverless environments so hosted runtimes do not truncate diagnostics.

#### Timeouts and cancellation

- [TS-BEH-019] Long-running operations must be interruptible:
  - [TS-BEH-019a] handle `Ctrl+C` gracefully
  - [TS-BEH-019b] avoid leaving partial/corrupt outputs
- [TS-BEH-020] All outbound calls must have explicit timeouts.
- [TS-BEH-021] Provide a `--timeout` option where it materially affects UX.

### 7.5 HTTP behaviour rules (applies to APIs) 🌐

#### Semantics

- [TS-BEH-022] Use correct methods: `GET` (read), `POST` (create), `PUT` (replace), `PATCH` (partial update), `DELETE` (remove).
- [TS-BEH-023] Use correct status codes:
  - `200/204` for successful reads/updates/deletes as appropriate
  - `201` for create with a `Location` header when applicable
  - `400` for invalid input, `401` unauthenticated, `403` unauthorised, `404` not found
  - `409` for conflicts (including concurrency conflicts)
  - `422` only where the chosen framework's conventions make it the correct and consistent choice
  - `429` for rate limiting
  - `5xx` only for server faults

#### Idempotency and retries

- [TS-BEH-024] Design for safe retries:
  - [TS-BEH-024a] `GET`, `PUT`, `DELETE` must be idempotent by design.
  - [TS-BEH-024b] `POST` should be idempotent **when the client may retry** (support idempotency keys where appropriate).
- [TS-BEH-025] Make concurrency rules explicit:
  - [TS-BEH-025a] use optimistic concurrency controls (ETags/version fields) where relevant
  - [TS-BEH-025b] return `409` on conflicts with a clear error code

#### Pagination, filtering, sorting

- [TS-BEH-026] For collections, prefer:
  - [TS-BEH-026a] pagination (cursor-based when feasible)
  - [TS-BEH-026b] explicit filtering (query parameters)
  - [TS-BEH-026c] stable sorting with deterministic defaults
- [TS-BEH-027] Make ordering rules explicit and deterministic.

#### Timeouts

- [TS-BEH-028] All outbound calls must have explicit timeouts.
- [TS-BEH-029] Avoid unbounded waits in request/response flows.

### 7.6 Async workflow hygiene

- [TS-BEH-030] Use `async/await` flows with explicit `try/catch` blocks so errors map to the structured logging/telemetry strategy.
- [TS-BEH-031] Guard edge cases at the top of functions to avoid deeply nested control flow.
- [TS-BEH-032] Route errors through the shared logging, tracing, and notification utilities instead of ad-hoc `console` calls.
- [TS-BEH-033] Surface user-facing failures via the repository's standard notification pattern so behaviour stays consistent across features.
- [TS-BEH-034] Debounce configuration-driven updates and dispose acquired resources deterministically to avoid leaks.

---

## 8. Configuration and precedence ⚙️

### 8.1 Precedence order (must be explicit)

Define and document precedence. Prefer this order:

1. CLI flags/options (if applicable)
2. Environment variables
3. Configuration file(s)
4. Built-in defaults

### 8.2 Configuration rules

- [TS-CFG-001] Validate configuration at startup and fail fast with a clear error.
- [TS-CFG-002] Do not silently coerce ambiguous config values.
- [TS-CFG-003] Never log secrets.

### 8.3 Environment variables

- [TS-CFG-004] Use a consistent prefix where applicable (for example `APP_...`).
- [TS-CFG-005] Document each variable and how it maps to flags/options.
- [TS-CFG-006] Default local configuration must be safe: do not require real cloud credentials, and do not enable destructive behaviour unless explicitly requested.

### 8.4 Configuration helpers and documentation

- [TS-CFG-007] Reach configuration through the repository's shared helpers/utilities instead of scattering direct `process.env` access.
- [TS-CFG-008] Validate configuration objects with schemas or dedicated validators so `undefined`/invalid values are caught immediately.
- [TS-CFG-009] Guard optional config and secret reads with explicit error messages rather than letting them flow as `undefined`.
- [TS-CFG-010] Document any new configuration key (and update corresponding tests) whenever you introduce it.

---

## 9. External integrations without slowing local dev 🔌

If the system depends on external services (cloud APIs, databases, third-party services), local feedback must still be fast.

- [TS-EXT-001] Default local behaviour must not require network access.
- [TS-EXT-002] Provide integration modes, in order of preference:
  1. **Fake** (in-process implementation for fast unit tests)
  2. **Emulator** (external local service, for example Docker-based DB, local stub servers)
  3. **Real cloud** (only for explicit integration runs)
- [TS-EXT-003] Use dependency injection / adapters so the system can swap implementations cleanly.
- [TS-EXT-004] Tests must not hit real cloud by default.
- [TS-EXT-005] Instantiate external clients outside hot paths and inject them so tests can swap implementations cheaply.
- [TS-EXT-006] Apply retries, backoff, and cancellation policies to network or IO calls according to the specification.
- [TS-EXT-007] Normalise third-party responses and map their errors to domain-level shapes before they leak deeper into the system.

---

## 10. Data validation and modelling 🧱

### 10.1 Validation (mandatory at boundaries)

- [TS-DATA-001] Validate inputs at the boundary using a schema library (repository choice).
- [TS-DATA-002] Validation must be deterministic, explicit, and testable.
- [TS-DATA-003] Prefer producing a structured list of validation errors over a generic failure message.

### 10.2 Model separation

- [TS-DATA-004] Keep these concepts separate:
  - [TS-DATA-004a] API models (request/response, event schemas)
  - [TS-DATA-004b] domain models (business concepts and invariants)
  - [TS-DATA-004c] persistence models (database representations)
- [TS-DATA-005] Do not expose persistence models directly through public APIs.

### 10.3 Stable contracts

- [TS-DATA-006] Prefer additive changes (new optional fields) over breaking changes.
- [TS-DATA-007] If a field becomes deprecated, keep it readable for a defined period and document the migration.

---

## 11. Error handling and failure semantics 🧯

**Section summary (key subsections):**

- 11.1 Fail explicitly — silent failure forbidden
- 11.2 Error shape — consistent machine-parseable structure
- 11.3 Logging exceptions — once, with context
- 11.3a Error classification — validation, domain, auth, not-found, conflicts, dependency
- 11.4 CLI error semantics — exit codes, error formatting
- 11.5 API error semantics — HTTP status codes, response structure
- 11.6 Debugging modes — verbose/debug flags

### 11.1 Fail explicitly, not silently (non-negotiable)

- [TS-ERR-001] Silent failure is forbidden.
- [TS-ERR-002] Partial success must be explicit (and specified).
- [TS-ERR-003] Do not return "success" responses with embedded error messages.

### 11.2 Error shape (APIs and structured CLIs)

- [TS-ERR-004] Use a consistent, machine-parseable error structure, for example:
  - `error_code` (stable)
  - `message` (plain language)
  - `details` (optional structured details)
  - `correlation_id` (when available)
- [TS-ERR-005] Map errors to stable status codes / exit codes.
- [TS-ERR-006] Do not leak secrets or sensitive internals in error messages.

### 11.3 Logging exceptions (once, with context)

- [TS-ERR-007] Log exceptions once, close to the boundary:
  - include `error_code`, `correlation_id`, `trace_id` (if present)
  - include stack traces in server logs only (never in client responses)
  - [TS-ERR-007a] Emit the exception log at `ERROR` level **even when the software can recover**, so operators always see the failure signal.
- [TS-ERR-008] Avoid duplicate logging at multiple layers unless each log adds new information.

### 11.3a Error classification (applies to APIs; recommended for CLIs with structured output)

- [TS-ERR-009] Distinguish between:
  - validation errors
  - domain/business rule errors
  - authentication/authorisation errors
  - not found
  - conflicts/concurrency errors
  - dependency/boundary errors (database, network)
- [TS-ERR-010] Do not leak sensitive internals in error messages.

### 11.4 CLI error output rules (applies to CLIs)

- [TS-ERR-011] Error output must be:
  - [TS-ERR-011a] concise
  - [TS-ERR-011b] plain language
  - [TS-ERR-011c] actionable ("what to do next")
- [TS-ERR-012] Avoid stack traces by default.
- [TS-ERR-013] Where helpful, include:
  - a stable `error_code`
  - a short "next steps" hint
  - a reference to documentation/runbook (if available)

### 11.5 API error response rules (applies to APIs)

- [TS-ERR-014] Use the standard error structure from [TS-ERR-004] for all non-2xx responses (including validation errors).
- [TS-ERR-015] Do not return `200` with an embedded error.
- [TS-ERR-016] Ensure correlation ids are returned in response headers and in the body where applicable.

### 11.6 Debugging modes 🪲

- [TS-ERR-017] Support controlled diagnostics (see also [§5.1 of the baseline](./includes/observability-baseline.include.md#51-log-level-hierarchy) for level hierarchy):
  - [TS-ERR-017a] `--verbose` increases detail (CLIs)
  - [TS-ERR-017b] `--debug` may include stack traces and enables function/method entry logging (trace-like behaviour; still never secrets)
- [TS-ERR-018] Diagnostics must not change behaviour, only observability.

---

## 12. Observability and operational readiness 🔭

Observability is non-negotiable.

**Section summary (key subsections):**

- 12.1 Correlation and tracing — request identity and propagation
- 12.2 Logging — structured logs, what to include, what never to log
- 12.3 Metrics — golden signals and cardinality rules
- 12.4 Runbooks — actionable error references
- 12.5 Browser/UI observability — RUM, errors, and cross-tier correlation

### 12.1 Correlation and tracing

- [TS-OBS-001] Accept an inbound request id (prefer `X-Request-Id`) or generate one if missing.
- [TS-OBS-002] Propagate correlation ids and trace context to all outbound calls.
- [TS-OBS-003] Return correlation ids to callers where applicable.

### 12.2 Logging

- [TS-OBS-004] Prefer structured logs (JSON) and follow the [Structured Logging Baseline](./includes/observability-baseline.include.md) for canonical field definitions.
- [TS-OBS-005] Service/API logs must include the required metadata from [section 1](./includes/observability-baseline.include.md#1-required-fields-services-apis); do not remove or rename those fields locally.
- [TS-OBS-006] CLI/worker logs that emit structured output must include the CLI invocation fields from [section 2](./includes/observability-baseline.include.md#2-required-fields-clis).
- [TS-OBS-007] Apply the secrecy and event taxonomy rules from [sections 3–4](./includes/observability-baseline.include.md#3-sensitive-data--secrecy-rules); never log secrets or personal data, and keep event names (`request.*`, `dependency.*`, etc.) stable for automation.
  - [TS-OBS-007a] When verbose or debug logging is enabled, emit a single function/method entry log for every call path with the operation name and a sanitised summary of arguments per [section 5](./includes/observability-baseline.include.md#5-diagnostics--sampling); never include sensitive payloads.

### 12.3 Metrics

- [TS-OBS-008] Provide golden signals: latency, traffic, errors, saturation.
- [TS-OBS-009] Avoid high-cardinality labels (no raw ids in metrics).

### 12.4 Runbooks

- [TS-OBS-010] For operationally meaningful errors, include a runbook reference (link or identifier) in logs and alerts.

### 12.5 Browser/UI observability (web apps)

- [TS-OBS-011] UI error reporting must be explicit and actionable:
  - [TS-OBS-011a] capture unhandled errors and unhandled promise rejections
  - [TS-OBS-011b] include build/version, route, and correlation id (when available)
  - [TS-OBS-011c] avoid sending personal data
- [TS-OBS-012] Cross-tier correlation is mandatory for systems with both UI and API:
  - [TS-OBS-012a] propagate `X-Request-Id` (or equivalent) from UI to API
  - [TS-OBS-012b] return it to the UI and include it in client-side error reports
- [TS-OBS-013] Collect Real User Monitoring (RUM) signals where appropriate:
  - [TS-OBS-013a] web vitals
  - [TS-OBS-013b] long tasks
  - [TS-OBS-013c] error rates by route
  - [TS-OBS-013d] frontend-to-backend latency
- [TS-OBS-014] Keep client telemetry safe and bounded:
  - [TS-OBS-014a] sample in production
  - [TS-OBS-014b] avoid high-cardinality labels
  - [TS-OBS-014c] never include raw identifiers or payloads

---

## 13. Security defaults 🔐

**Section summary (key subsections):**

- 13.1 Dependencies and supply chain — minimal deps, scanning, lock files
- 13.2 Secrets — never commit, inject at runtime
- 13.3 Web security — HTTPS, headers, CORS
- 13.4 Content handling — CSP, sanitisation

### 13.1 Dependencies and supply chain

- [TS-SEC-001] Keep dependencies minimal.
- [TS-SEC-002] Pin dependencies via lock file and update intentionally.
- [TS-SEC-003] Run dependency and code security scanning in CI (repository tool choice).
- [TS-SEC-004] Treat high/critical findings as blocking unless waived in an ADR (rationale + expiry).

### 13.2 Secrets

- [TS-SEC-005] Never commit secrets.
- [TS-SEC-006] Do not pass secrets via CLI args unless unavoidable (they leak via shell history and process lists).
- [TS-SEC-007] Use a secret manager where available; inject secrets at runtime.
- [TS-SEC-008] Do not log secrets or full tokens.

### 13.3 Web security (when applicable)

- [TS-SEC-009] Enforce HTTPS.
- [TS-SEC-010] Use strict CORS allow-lists (no `*` for authenticated endpoints).
- [TS-SEC-011] Use CSRF protection for cookie-based sessions.
- [TS-SEC-012] Validate and normalise untrusted inputs (including headers).

### 13.4 Browser/UI security (web apps)

- [TS-SEC-013] Treat the UI as part of the security boundary:
  - [TS-SEC-013a] do not trust client-side validation
  - [TS-SEC-013b] do not assume "internal users" makes the UI safe
- [TS-SEC-014] Prevent XSS by default:
  - [TS-SEC-014a] prefer safe DOM APIs and framework escaping
  - [TS-SEC-014b] minimise dynamic HTML injection; where unavoidable, sanitise and constrain
- [TS-SEC-015] Use Content Security Policy (CSP) where feasible to reduce XSS impact.
- [TS-SEC-016] Never store access tokens in places vulnerable to XSS (for example `localStorage`) unless the threat model explicitly accepts it and documents mitigations.
- [TS-SEC-017] Prefer short-lived tokens and least-privilege scopes.
- [TS-SEC-018] Keep security headers and transport rules consistent across environments.

### 13.5 Secure coding patterns

- [TS-SEC-019] Validate and sanitise external inputs with schema validators or type guards before they reach domain logic.
- [TS-SEC-020] Avoid dynamic code execution or untrusted template rendering; when templating is required, stick to vetted, sandboxed engines.
- [TS-SEC-021] Encode or escape untrusted content before rendering HTML, even on the server.
- [TS-SEC-022] Use parameterised queries or prepared statements for all persistence access to block injection.
- [TS-SEC-023] Keep secrets in managed storage, rotate them regularly, and request only least-privilege scopes.
- [TS-SEC-024] Prefer immutable data flows and defensive copies for sensitive information so downstream code cannot mutate it accidentally.
- [TS-SEC-025] Use vetted cryptography libraries; never hand-roll crypto primitives.
- [TS-SEC-026] Patch dependencies promptly and monitor advisory feeds; treat high/critical advisories as blocking until resolved.

---

## 14. File, I/O, and boundary behaviour 🧱

- [TS-IO-001] Use atomic writes for output files (write temp then rename).
- [TS-IO-002] Define deterministic traversal and ordering rules.
- [TS-IO-003] Make error strategy explicit (fail-fast vs continue-with-report).
- [TS-IO-004] Treat external dependencies (DB, HTTP, queues, filesystem) as boundaries behind adapters:
  - [TS-IO-004a] databases
  - [TS-IO-004b] HTTP clients
  - [TS-IO-004c] queues and event buses
  - [TS-IO-004d] filesystem
- [TS-IO-005] Make transaction boundaries explicit:
  - [TS-IO-005a] avoid implicit global transactions
  - [TS-IO-005b] ensure consistency rules are specified and tested
- [TS-IO-006] Do not let business logic depend on framework request objects.

---

## 15. Testing approach (TDD, unit-test first) 🧪

Per [constitution.md §3.6](../../.specify/memory/constitution.md#36-design-for-testability-tdd), follow a test-first flow for behaviour changes:

1. Write/update a unit test **from the specification**.
2. Confirm it fails for the right reason.
3. Implement the minimal change to pass.
4. Refactor after green, preserving behaviour.

### 15.1 Test pyramid

- [TS-TST-001] Prefer the test pyramid:
  - [TS-TST-001a] **most tests**: unit (fast, deterministic, behaviour-focused)
  - [TS-TST-001b] **some tests**: integration (filesystem, DB/emulators, HTTP stubs)
  - [TS-TST-001c] **few tests**: end-to-end (critical journeys only)
- [TS-TST-002] Tests must be deterministic:
  - [TS-TST-002a] control time and randomness
  - [TS-TST-002b] avoid real network by default
  - [TS-TST-002c] avoid relying on wall-clock sleeps; use fakes or polling with timeouts
- [TS-TST-003] Do not couple tests to implementation details unnecessarily.

### 15.2 Tooling guidance (choose per context)

- [TS-TST-004] Prefer a modern, fast unit test runner (for example Vitest) for most new projects.
- [TS-TST-005] Use Jest when ecosystem constraints require it (legacy projects or specific integrations).
- [TS-TST-006] Use Playwright for browser end-to-end tests where applicable.
- [TS-TST-007] For UI component testing, prefer user-centric testing practices over implementation detail tests.

### 15.3 Additional expectations

- [TS-TST-008] Add or update unit tests whenever behaviour changes, following the repository's naming and layout conventions.
- [TS-TST-009] Expand integration or end-to-end suites when work spans multiple modules or touches external platforms.
- [TS-TST-010] Run targeted test commands for fast feedback before submitting larger suites, then finish with the canonical quality gates.
- [TS-TST-011] Avoid brittle timing assertions; use fake timers or injected clocks to keep async flows deterministic.
- [TS-TST-012] UI implementation or behaviour changes must ship with both component-level tests using the framework's preferred runner and screen-level Playwright journeys that cover primary flows, validation, accessibility states, and keyboard navigation; document any new selectors/test IDs in the spec or plan before relying on them.

---

## 16. Code organisation and maintainability ✍️

Per [constitution.md §7](../../.specify/memory/constitution.md#7-code-quality-guardrails):

- [TS-CODE-001] Keep business/domain logic independent of frameworks and delivery mechanisms.
- [TS-CODE-002] Separate:
  - [TS-CODE-002a] boundary adapters (HTTP, DB, queues, filesystem)
  - [TS-CODE-002b] orchestration/use-cases
  - [TS-CODE-002c] domain logic and policies
  - [TS-CODE-002d] presentation/API models
- [TS-CODE-003] Prefer small modules with explicit exports; avoid "god modules".
- [TS-CODE-004] Align naming to domain language; avoid ambiguous "util" dumping grounds.
- [TS-CODE-005] Keep functions small and single-purpose.
- [TS-CODE-006] Order code to aid navigation:
  - [TS-CODE-006a] entrypoints and public APIs first
  - [TS-CODE-006b] key behaviour next
  - [TS-CODE-006c] helpers near the behaviour they support
  - [TS-CODE-006d] shared utilities clearly grouped
- [TS-CODE-007] Keep framework objects at the edges: do not let request/response objects leak into domain or use-case logic.
- [TS-CODE-008] Follow the repository's established folder and responsibility layout; extend existing abstractions before inventing new ones.
- [TS-CODE-009] Use kebab-case filenames (for example `user-session.ts`) unless the repository explicitly chooses a different convention.
- [TS-CODE-010] Keep related tests, types, and helpers near their implementation when it improves discovery without bloating modules.
- [TS-CODE-011] Reuse or extend shared utilities before adding a new helper; document the rationale when a new abstraction is unavoidable.
- [TS-CODE-012] Use PascalCase for classes, interfaces, enums, and type aliases; camelCase for functions, variables, and instances.
- [TS-CODE-013] Skip interface prefixes such as `I`; rely on descriptive names instead.
- [TS-CODE-014] Name modules and symbols for the behaviour or domain meaning they deliver, not the underlying implementation detail.
- [TS-CODE-015] Follow the repository's dependency injection/composition approach so modules stay single-purpose and testable.
- [TS-CODE-016] Respect initialise/dispose sequences and provide lifecycle hooks (plus targeted tests) when wiring new services.

---

## 17. Build, packaging, and release 📦

### 17.1 Build outputs

- [TS-BLD-001] Prefer a single source of truth for builds:
  - typecheck (`tsc --noEmit`) is always required
  - runtime build/bundle depends on target (Node service vs library vs web app)
- [TS-BLD-002] Produce sourcemaps for production debugging where supported and safe.
- [TS-BLD-003] Ensure builds are reproducible (clean install + deterministic outputs).

### 17.2 Libraries and SDKs

- [TS-BLD-004] Decide and document supported runtimes (Node version range, browser targets).
- [TS-BLD-005] Provide correct `exports` and types for each entrypoint.
- [TS-BLD-006] Verify declaration output matches runtime output (no missing exports).

### 17.3 Versioning

- [TS-BLD-007] Use semantic versioning for public packages and stable CLIs/APIs.
- [TS-BLD-008] Breaking changes must be explicit, documented, and reviewable.

---

## 18. Performance and resilience 🚀

### 18.1 Performance and resilience (general)

- [TS-PERF-001] Avoid premature optimisation, but do not allow unbounded inefficiency.
- [TS-PERF-002] Use timeouts, retries, and backoff for outbound calls (where safe):
  - [TS-PERF-002a] explicit timeouts
  - [TS-PERF-002b] retries with backoff
  - [TS-PERF-002c] circuit-breaking patterns where appropriate
- [TS-PERF-003] Prefer streaming/pagination for large datasets.
- [TS-PERF-004] Avoid unbounded concurrency; cap parallelism where relevant.
- [TS-PERF-005] Make performance characteristics explicit and testable where relevant.
- [TS-PERF-006] Lazy-load heavy dependencies and dispose them when no longer needed.
- [TS-PERF-007] Defer expensive computation until a user or downstream system actually needs it.
- [TS-PERF-008] Batch or debounce high-frequency events to avoid thrashing the runtime and backend services.
- [TS-PERF-009] Track resource lifetimes (files, sockets, observers, timers) to prevent leaks.

---

## 19. AI-assisted change expectations 🤖

Per [constitution.md §3.5](../../.specify/memory/constitution.md#35-ai-assisted-development-discipline--change-governance), when you create or modify code:

- [TS-AI-001] Follow the shared [AI change baseline](./includes/ai-assisted-change-baseline.include.md) for scope, quality, and governance.
- [TS-AI-002] Update documentation/contracts only when required by the specification.

---

## 20. UI engineering (web apps) 🎨

This section defines a **framework-agnostic** baseline for building maintainable, accessible, secure, and fast UIs with TypeScript.

### 20.1 Accessibility baseline (non-negotiable) ♿️

- [TS-UI-001] Meet **WCAG 2.2 Level AA** expectations unless an ADR explicitly documents why not.
- [TS-UI-002] Keyboard accessibility is mandatory:
  - every interactive element is reachable and operable with the keyboard
  - focus order matches the visual order
  - focus is always visible
- [TS-UI-003] Prefer semantic HTML first:
  - buttons are `<button>`, links are `<a>`, form controls use native elements
  - do not build custom widgets when native elements provide the behaviour
- [TS-UI-004] Use ARIA only when required, and only according to established patterns:
  - roles and labels must match actual behaviour
  - do not add ARIA that changes meaning incorrectly
- [TS-UI-005] When you implement custom widgets, follow standard keyboard interaction patterns (for example arrow-key navigation in composite widgets).
- [TS-UI-006] Forms must be accessible:
  - label every input
  - associate error messages to the field
  - ensure errors are announced to assistive tech
- [TS-UI-007] Do not rely on colour alone to convey meaning.
- [TS-UI-008] Maintain adequate contrast and respect user preferences:
  - reduced motion
  - high contrast modes
- [TS-UI-009] Provide accessible names for controls (label/aria-label/aria-labelledby).
- [TS-UI-010] Manage focus intentionally:
  - focus is moved after navigation/modals where appropriate
  - trap focus only when needed (for example modal dialogs)
  - provide an escape path (Esc closes modals where applicable)
- [TS-UI-011] Dynamic content changes must be perceivable:
  - use live regions when necessary
  - avoid aggressive announcements

### 20.2 UX and interaction design rules 🧭

- [TS-UI-012] Prefer predictable interaction patterns over novelty.
- [TS-UI-013] Provide clear feedback for async actions:
  - loading states
  - disabled states (with explanation where useful)
  - error states with a recovery path
- [TS-UI-014] Avoid "toast-only" error reporting for critical failures; ensure errors are discoverable and persistent when needed.
- [TS-UI-015] Use consistent copy and content patterns:
  - concise, plain language
  - action-oriented button labels
- [TS-UI-016] Support responsive layouts (small screens and zoom).
- [TS-UI-017] Prefer progressive disclosure for complex flows.
- [TS-UI-018] Avoid dark patterns (misleading opt-ins, hidden fees, confusing defaults).

### 20.3 UI architecture and component design 🧩

- [TS-UI-019] Treat UI as a composition of:
  - presentation components (pure rendering)
  - containers/orchestrators (data fetching, state, policies)
  - adapters (API clients, storage, analytics)
- [TS-UI-020] Keep side effects at the edges:
  - fetch, storage, navigation, analytics, timers
  - do not hide side effects in "utility" functions
- [TS-UI-021] Prefer unidirectional data flow:
  - state transitions are explicit
  - avoid hidden shared mutable state
- [TS-UI-022] Define component contracts:
  - explicit props interfaces
  - stable event callback names (`onChange`, `onSubmit`, etc.)
  - avoid "bag of options" props
- [TS-UI-023] Keep components small and single-responsibility.
- [TS-UI-024] Avoid prop drilling for cross-cutting concerns; use a deliberate state/context solution where needed.
- [TS-UI-025] Keep routing concerns at the edge (route params validated at the boundary).

### 20.4 State management and data fetching 🌊

- [TS-UI-026] Separate:
  - **server state** (fetched data, caching, invalidation)
  - **UI state** (local view state, transient UI flags)
  - **form state** (validation, dirty tracking)
- [TS-UI-027] Prefer declarative data fetching and caching where appropriate (repository choice), but keep domain rules outside of framework hooks.
- [TS-UI-028] All client-to-server requests must have:
  - explicit timeouts
  - cancellation (AbortController) where practical
  - retry behaviour that is safe and bounded
- [TS-UI-029] Never assume the UI is the only writer:
  - handle stale data and concurrency (optimistic updates only with clear rollback)
- [TS-UI-030] Validate data from APIs at the boundary (schema validation) before use.

### 20.5 Performance and industry UX metrics 🚀

- [TS-UI-031] Design for **fast interaction responsiveness** and avoid long tasks on the main thread.
- [TS-UI-032] Treat Core Web Vitals as a first-class performance signal:
  - responsiveness (INP)
  - loading (LCP)
  - visual stability (CLS)
- [TS-UI-033] Prefer performance budgets:
  - bundle size budgets
  - route-level loading budgets
  - "no regressions" alerts in CI where feasible
- [TS-UI-034] Use code splitting and lazy loading intentionally:
  - keep initial routes lean
  - prefetch only when it improves real user outcomes
- [TS-UI-035] Optimise assets:
  - responsive images
  - compression
  - caching headers and immutable asset fingerprints
- [TS-UI-036] Avoid unnecessary re-renders and expensive computations:
  - memoise intentionally (do not cargo-cult)
  - move expensive work off the main thread when appropriate (workers)
- [TS-UI-037] Prefer "measure then improve":
  - use lab tooling (Lighthouse) and real-user telemetry (RUM) where appropriate

### 20.6 Frontend security and hardening 🛡️

- [TS-UI-038] Prevent XSS:
  - avoid rendering untrusted HTML
  - sanitise and constrain if unavoidable
- [TS-UI-039] Use defence-in-depth:
  - CSP where feasible
  - dependency pinning and audits
  - strict transport rules
- [TS-UI-040] Treat supply-chain risk as a UI risk:
  - minimise dependencies
  - prefer well-maintained packages
  - audit transitive dependency changes on upgrades
- [TS-UI-041] Store credentials safely:
  - prefer HttpOnly secure cookies for browser sessions where feasible
  - avoid long-lived tokens in browser storage unless justified in an ADR
- [TS-UI-042] Avoid leaking sensitive information in:
  - error messages
  - client logs/telemetry
  - page source / build artefacts

### 20.7 UI testing and accessibility checks 🧪

- [TS-UI-043] Use a layered testing strategy:
  - unit tests for pure functions and reducers
  - component tests for rendering and user interactions
  - end-to-end tests for critical journeys (Playwright)
- [TS-UI-044] Prefer user-centric testing for UI components (what the user sees and does), not internal component details.
- [TS-UI-045] Accessibility checks must exist:
  - automated linting where available
  - automated checks in tests (for example axe-based checks) where practical
  - manual keyboard and screen-reader smoke checks for key journeys
- [TS-UI-046] Test error and loading states explicitly.
- [TS-UI-047] Visual regressions are allowed where they provide real confidence, but keep snapshots small and meaningful.

### 20.8 Styling, theming, and design systems 🎨

- [TS-UI-048] Choose one styling strategy per repo (document it):
  - CSS modules, utility CSS, CSS-in-JS, etc.
- [TS-UI-049] Use a design system (or component library) deliberately:
  - centralise typography, spacing, colours, and component primitives
  - keep the public "design API" stable
- [TS-UI-050] Theme must preserve accessibility:
  - contrast requirements
  - focus states
  - reduced motion support

### 20.9 Internationalisation and localisation 🌍

- [TS-UI-051] If the product is user-facing, i18n must be considered early:
  - avoid hard-coded strings in components where translation is expected
  - support pluralisation and date/number formatting
- [TS-UI-052] Do not couple UI layout to English-only text lengths.

### 20.10 UI orchestration patterns

- [TS-UI-053] Keep UI layers thin; push heavyweight business logic into services or state managers that can be tested independently.
- [TS-UI-054] Use messaging or event channels to decouple UI components from business logic so changes stay isolated.

## 21. Documentation and comments 📝

- [TS-DOC-001] Add JSDoc (with `@remarks`/`@example` where useful) to public APIs so intent stays clear to both humans and tools.
- [TS-DOC-002] Write comments that capture intent and trade-offs; remove or update them whenever the behaviour changes.
- [TS-DOC-003] Update architecture/design documentation when you introduce notable patterns, lifecycle hooks, or dependencies so the wider system view stays current.

---

## 22. Anti-patterns ❌

- [TS-ANT-001] **Do not** use `any` except as a last resort with a justifying comment; prefer `unknown` at boundaries.
- [TS-ANT-002] **Do not** fire-and-forget promises; always await or explicitly handle outcomes.
- [TS-ANT-003] **Do not** make outbound calls without explicit timeouts.
- [TS-ANT-004] **Do not** log secrets, tokens, or PII.
- [TS-ANT-005] **Do not** pass secrets via CLI arguments; use environment variables or secret managers.
- [TS-ANT-006] **Do not** let functions exceed ~50 lines or 3 levels of nesting without extraction.
- [TS-ANT-007] **Do not** let modules exceed ~500 lines (excluding tests) without splitting by responsibility.
- [TS-ANT-008] **Do not** use `console.log` in production code; use structured logging utilities.
- [TS-ANT-009] **Do not** ignore linter or type-checker warnings; fix them or explicitly waive with rationale.
- [TS-ANT-010] **Do not** expose persistence/internal models directly through public APIs.
- [TS-ANT-011] **Do not** return HTTP 200 with embedded error messages; use correct status codes.
- [TS-ANT-012] **Do not** use unbounded concurrency; cap parallelism explicitly.
- [TS-ANT-013] **Do not** rely on wall-clock sleeps in tests; use fake timers or polling with timeouts.
- [TS-ANT-014] **Do not** hit real cloud/network in unit tests by default.
- [TS-ANT-015] **Do not** store access tokens in `localStorage` without documented threat-model acceptance.

---

> **Version**: 1.6.0
> **Last Amended**: 2026-01-20
