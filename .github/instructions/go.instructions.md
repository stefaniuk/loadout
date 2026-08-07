---
applyTo: "**/*.go"
description: "Go Engineering Instructions (CLI + API, framework-agnostic)"
---

# Go Engineering Instructions (CLI + API, framework-agnostic) 🐹

These instructions define the expert engineering approach for building **modern, production-grade Go CLIs and APIs**.

They must remain applicable to:

- Minimal CLIs (standard library `flag`)
- Command frameworks (for example Cobra, urfave/cli)
- HTTP APIs (standard library `net/http`, Chi, Echo, Gin)
- gRPC services
- **AWS Lambda–hosted APIs** (for example API Gateway + Lambda)

They are **non-negotiable** unless an exception is explicitly documented (with rationale and expiry) in an ADR/decision record.

**Identifier scheme.** Every normative rule carries a unique tag in the form `[GO-<prefix>-NNN]`, where the prefix maps to the containing section (for example `OP` for Operating Principles, `LCL` for Local-first developer experience, `QG` for Quality Gates, continuing through `AI` for AI-assisted expectations). Use these identifiers when referencing, planning, or validating requirements.

---

## 0. Quick reference (apply first) 🧠

This section exists so humans and AI assistants can reliably apply the most important rules even when context is tight.

- [GO-QR-001] **Specification first**: treat the specification as the source of truth for behaviour ([GO-OP-001]).
- [GO-QR-002] **Small, safe changes**: prefer small, explicit, testable changes ([GO-OP-002], [GO-OP-006]).
- [GO-QR-003] **Fast feedback**: local development and tests must be quick and confidence-building ([GO-OP-007], [GO-LCL-001]–[GO-LCL-008]).
- [GO-QR-004] **Run the quality gates** after any code/test change and iterate to clean ([GO-QG-001]–[GO-QG-005]).
- [GO-QR-005] **Accept interfaces, return structs**: define interfaces at the consumer side, not the producer ([GO-INT-001]–[GO-INT-003]).
- [GO-QR-006] **Deterministic outputs**: stable ordering, stable field naming, no hidden randomness ([GO-OP-003], [GO-CTR-007]).
- [GO-QR-007] **Correct CLI streams**: stdout for primary output, stderr for diagnostics ([GO-BEH-008]–[GO-BEH-011]).
- [GO-QR-008] **No secrets in args or logs**: use env vars or secure prompts; never print secrets ([GO-SEC-001]–[GO-SEC-004], [GO-OBS-013]).
- [GO-QR-009] **Local by default**: no real cloud/network by default; use fakes/emulators; explicit integration mode switches ([GO-EXT-001]–[GO-EXT-007]).
- [GO-QR-010] **Operational visibility**: correlation IDs and structured logs for APIs; controlled diagnostics only ([GO-OBS-004]–[GO-OBS-010]).
- [GO-QR-011] **Handle errors explicitly**: never ignore returned errors; wrap with context using `%w` ([GO-ERR-001]–[GO-ERR-012]).
- [GO-QR-012] **Avoid common anti-patterns**: naked goroutines, nil channel operations, interface pollution, init() abuse, global mutable state (§21).

---

## 1. Operating principles 🧭

These principles extend [constitution.md §3](../../.specify/memory/constitution.md#3-core-principles-non-negotiable).

- [GO-OP-001] Treat the **specification as the source of truth** for behaviour. If behaviour is not specified, it does not exist.
- [GO-OP-002] Prefer **small, explicit, testable** changes over broad rewrites or large refactors.
- [GO-OP-003] Design for **determinism** (stable outputs for the same inputs) and:
  - [GO-OP-003a] **operability** (clear errors, easy diagnosis) for CLIs
  - [GO-OP-003b] **observability** (you can explain what happened and why) for APIs
- [GO-OP-004] Optimise for **maintenance, usability/operability, and change safety**, not cleverness.
- [GO-OP-005] **Fast feedback is paramount**: local development must be quick, automated, and confidence-building.
- [GO-OP-006] Avoid inventing requirements, widening scope, or introducing behaviour not present in the specification.
- [GO-OP-007] Avoid heavyweight work at `init()` time (slow startup, surprises in tests, higher cold-start cost). Initialise heavy resources lazily or behind explicit entrypoints.
- [GO-OP-008] Keep global state minimal and explicit. Prefer dependency injection via constructors over hidden package-level singletons.
- [GO-OP-009] **Write Go programs by writing code, not by defining types.** Start with functions; add type parameters only when you find yourself writing the exact same code multiple times with different types.

---

## 2. Local-first developer experience (bleeding-edge fast feedback) ⚡

The system must be **fully developable and testable locally**, even when it integrates with external services as part of a larger system.

Follow the shared [local-first developer experience baseline](./includes/local-first-dev-baseline.include.md) for common expectations, plus the language-specific requirements below.

### 2.1 Single-command workflow (must exist)

Provide repository-standard commands so an engineer can do the following quickly:

- [GO-LCL-001] Bootstrap: `make deps` - installs tooling and dependencies, and prepares a usable local environment
- [GO-LCL-002] Format: `make format`
- [GO-LCL-003] Lint: `make lint`
- [GO-LCL-004] Static analysis: `make staticcheck` - runs staticcheck as a blocking gate
- [GO-LCL-005] Test (fast lane): `make test` - must run quickly (aim: < 10 seconds, provide another make target for slower tests) and deterministically
- [GO-LCL-006] Full suite: `make test-all` - includes integration/e2e tiers
- [GO-LCL-007] Run CLI locally: `make run` - runs with safe defaults (**no cloud dependencies by default**)
- [GO-LCL-008] Run API locally: `make up` / `make down` - starts/stops local dependency stack (if applicable)

### 2.2 Reproducible toolchain (avoid "works on my machine")

- [GO-LCL-009] Pin the Go version in `go.mod` (for example `go 1.23`) and use toolchain directives when needed.
- [GO-LCL-010] Use Go modules (`go mod`) with `go.sum` for deterministic dependency management.
- [GO-LCL-011] Use `go mod tidy` and `go mod verify` in CI to catch dependency drift.
- [GO-LCL-012] Keep the developer toolchain minimal and fast.

Repository defaults (unless the repository explicitly documents an alternative):

- [GO-LCL-013] `gofmt` is mandatory for formatting (zero-config, non-negotiable).
- [GO-LCL-014] `golangci-lint` is the mandatory meta-linter; configure `.golangci.yml` with a strict baseline.
  - [GO-LCL-014a] Enable `depguard` for import-direction constraints (see [GO-CODE-009]).
  - [GO-LCL-014b] Enable `gomodguard` for module allow/deny lists (see [GO-CODE-010]).
- [GO-LCL-015] `staticcheck` is **mandatory** for static analysis; run in CI as a blocking gate.
- [GO-LCL-016] `go test` with race detector (`-race`) for tests.

### 2.3 Pre-commit hooks (strongly recommended)

Provide a `pre-commit` configuration that runs the same checks as CI in a fast, local-friendly way:

- [GO-LCL-017] formatting (`gofmt -s -d`)
- [GO-LCL-018] linting (`golangci-lint run`)
- [GO-LCL-019] `go vet` on changed packages
- [GO-LCL-020] secret scanning (for example gitleaks)

### 2.4 OCI images for parity and zero-setup (strongly recommended)

Provide an OCI-based option so behaviour is consistent across laptops and CI:

- [GO-LCL-021] A lightweight dev image that includes:
  - [GO-LCL-021a] Go toolchain + locked dependencies
  - [GO-LCL-021b] lint/test tooling
  - [GO-LCL-021c] any required system packages
- [GO-LCL-022] Provide one command to use it:
  - [GO-LCL-022a] `make docker-test` / `make docker-run` (or Dev Containers), etc.

- [GO-LCL-023] OCI support must be **optional** (native dev still works), but it must be maintained.
- [GO-LCL-024] Never bake secrets into images.
- [GO-LCL-025] The same commands (`make format`, `make lint`, `make staticcheck`, `make test`) must work inside and outside the container.

### 2.5 Fast iteration patterns (recommended)

- [GO-LCL-026] Support watch mode when feasible (for example `make test-watch` using `watchexec` or similar).
- [GO-LCL-027] Support parallel tests: `go test -parallel` (default behaviour).
- [GO-LCL-028] Provide clear test markers and commands:
  - [GO-LCL-028a] `make test-unit` (short tests, no network)
  - [GO-LCL-028b] `make test-integration` (uses containers/emulators)
  - [GO-LCL-028c] `make test-e2e` (critical journeys only)

### 2.6 Test tiers (must adopt)

Define clear tiers with predictable markers/commands:

- [GO-LCL-029] Unit (default): no network, no containers; use `-short` flag for filtering
- [GO-LCL-030] Integration: uses containers/emulators; still local and repeatable
- [GO-LCL-031] End-to-end (few): critical journeys only; time-boxed

### 2.7 System dependencies and runtime parity (recommended, but often decisive)

- [GO-LCL-032] If the project needs OS/system packages (for example `libsqlite3`, `openssl`), pin and document them (Dev Container, OCI dev image, or a clear install script).
- [GO-LCL-033] Keep local defaults safe: local dev must not require real cloud credentials, and must not mutate real cloud resources by default.
- [GO-LCL-034] Document the supported runtime execution modes (local native, containerised, CI) and keep the core commands consistent across them ([GO-LCL-025]).
- [GO-LCL-035] Where supported by your tooling, provide a single "environment check" command (for example `make doctor`) that confirms local prerequisites and surfaces actionable fixes.

---

## 3. Mandatory local quality gates ✅

Per [constitution.md §7.8](../../.specify/memory/constitution.md#78-mandatory-local-quality-gates), after making **any** change to implementation code or tests, you must run the repository's **canonical** quality gates:

1. Prefer:
   - [GO-QG-001] `make lint`
   - [GO-QG-002] `make staticcheck`
   - [GO-QG-003] `make test`

2. If `make` targets do not exist, discover and run the project's equivalent commands (for example `golangci-lint run`, `staticcheck ./...`, `go test -race ./...`).
   - [GO-QG-004] Follow the shared [quality gates baseline](./includes/quality-gates-baseline.include.md) for iteration and warning handling rules.
   - [GO-QG-005] Follow the shared [quality gates baseline](./includes/quality-gates-baseline.include.md) for command selection and equivalents.

---

## 4. Contracts and public surface area 📜

Go projects have contracts, even when they are "just code"; treat every boundary as intentional.

### 4.1 CLI contract and user experience (applies to CLIs) ⌨️

#### CLI is a contract (not an accident)

- [GO-CTR-001] Treat the CLI as a **stable interface contract**:
  - [GO-CTR-001a] command names
  - [GO-CTR-001b] flags/options and defaults
  - [GO-CTR-001c] argument parsing rules
  - [GO-CTR-001d] exit codes
  - [GO-CTR-001e] stdout/stderr behaviour
  - [GO-CTR-001f] output formats
- [GO-CTR-001g] CLI entrypoints must remain thin adapters per the shared [CLI contract](./includes/cli-contract-baseline.include.md#5-wrappers-and-shared-libraries): parse + validate inputs, delegate to shared library code, and forward exit codes; move any business logic into reusable modules.
- [GO-CTR-001h] When CLIs target managed/cloud runtimes (for example AWS Lambda), follow the [CLI contract cloud guidance](./includes/cli-contract-baseline.include.md#6-cloud-and-serverless-workloads): flush streams explicitly and keep diagnostics CloudWatch/Stackdriver-friendly.
- [GO-CTR-002] Backwards-incompatible changes must be **intentional, documented, and reviewable**.

#### Help, discoverability, and documentation

- [GO-CTR-003] Every command must have:
  - [GO-CTR-003a] a clear one-line summary
  - [GO-CTR-003b] detailed `--help` text (including examples)
  - [GO-CTR-003c] explicit argument/option descriptions
- [GO-CTR-004] Prefer consistent patterns:
  - [GO-CTR-004a] `--verbose`, `--quiet`
  - [GO-CTR-004b] `--format` for output formats
  - [GO-CTR-004c] `--output` for output paths
  - [GO-CTR-004d] `--dry-run` for non-destructive preview
- [GO-CTR-005] Provide examples that match real usage and are copy-paste ready.

#### Output compatibility (humans and automation)

- [GO-CTR-006] Support both:
  - [GO-CTR-006a] **human-readable** output (default), and
  - [GO-CTR-006b] **machine-readable** output (when applicable), for example `--format json` or `--json`.
- [GO-CTR-007] Output must be deterministic:
  - [GO-CTR-007a] stable ordering rules (use `slices.Sort` or sorted iteration)
  - [GO-CTR-007b] stable field naming
  - [GO-CTR-007c] no hidden randomness (use `math/rand/v2` with explicit seed for reproducibility)
- [GO-CTR-008] Never mix progress/status messages into structured output.

### 4.2 API contract and surface area (applies to APIs) 🌐

#### API is a contract (not an accident)

- [GO-CTR-009] Treat the external API as a **stable contract** (HTTP semantics, payload shapes, status codes, headers).
- [GO-CTR-010] Changes to the contract must be **intentional, documented, and reviewable**.
- [GO-CTR-011] Prefer backward-compatible changes. When breaking changes are necessary:
  - [GO-CTR-011a] make them explicit
  - [GO-CTR-011b] provide a migration path
  - [GO-CTR-011c] version the API where appropriate

#### Versioning policy

- [GO-CTR-012] Prefer **non-breaking evolution** (additive fields, new endpoints, optional query parameters).
- [GO-CTR-013] If versioning is required:
  - [GO-CTR-013a] use a consistent scheme (for example `/v1/` path prefix or content negotiation)
  - [GO-CTR-013b] avoid ad-hoc per-endpoint versioning

#### OpenAPI / schema outputs (where supported)

- [GO-CTR-014] If the framework can generate OpenAPI or an equivalent schema, treat it as **first-class**:
  - [GO-CTR-014a] accurate request/response models
  - [GO-CTR-014b] clear summaries/descriptions
  - [GO-CTR-014c] examples when they reduce ambiguity
- [GO-CTR-015] Do not leak internal persistence models or implementation details into the contract.

---

## 5. Interface design (expert-level) 🔌

Go interfaces are powerful but easily misused. These rules prevent interface pollution and ensure testability.

### 5.1 Accept interfaces, return structs

- [GO-INT-001] **Define interfaces at the consumer side, not the producer.** The package that uses the interface should define the minimal interface it needs, not the package that implements it.
- [GO-INT-002] Return concrete types (structs) from constructors and exported functions. Let consumers define their own interfaces for the subset of behaviour they need.
- [GO-INT-003] Prefer small interfaces (1-3 methods). The larger the interface, the weaker the abstraction.

### 5.2 Interface compliance verification

- [GO-INT-004] **Verify interface compliance at compile time** using the blank identifier pattern:

  ```go
  var _ http.Handler = (*MyServer)(nil)
  var _ io.ReadWriteCloser = (*MyBuffer)(nil)
  ```

  Place these declarations at package scope, near the type definition. This catches interface drift immediately at compile time rather than at runtime.

### 5.3 When to use interfaces

- [GO-INT-005] Use interfaces when:
  - [GO-INT-005a] You need to mock dependencies in tests
  - [GO-INT-005b] You have multiple implementations (for example different backends)
  - [GO-INT-005c] You need to break import cycles
- [GO-INT-006] Do not use interfaces when:
  - [GO-INT-006a] There is only one implementation and no foreseeable need for mocking
  - [GO-INT-006b] The interface would have many methods (consider breaking down)
  - [GO-INT-006c] You're just cargo-culting from other languages

### 5.4 Interface embedding

- [GO-INT-007] Embed interfaces in structs sparingly. When you do:
  - [GO-INT-007a] Document which methods the outer type is expected to override
  - [GO-INT-007b] Never embed interfaces in public API structs-it exposes internal details
  - [GO-INT-007c] Prefer explicit delegation over embedding when behaviour is complex

---

## 6. Error handling (expert patterns) ⚠️

Go's explicit error handling is a strength. These rules maximise its value.

### 6.1 Core principles

- [GO-ERR-001] **Never ignore returned errors.** Use `_ = fn()` only when the function documents that errors are informational and safe to ignore, and comment the reason.
- [GO-ERR-002] **Wrap errors with context** using `fmt.Errorf("context: %w", err)`. The `%w` verb allows `errors.Is()` and `errors.As()` to work through the chain.
- [GO-ERR-003] Use `%v` instead of `%w` when you intentionally want to **break the error chain** (for example to hide internal details from external callers).
- [GO-ERR-004] **Error strings should not be capitalised or end with punctuation** - they often appear mid-sentence in logs.

### 6.2 Sentinel errors and custom types

- [GO-ERR-005] Define sentinel errors for conditions that callers need to check programmatically:

  ```go
  var ErrNotFound = errors.New("resource not found")
  ```

- [GO-ERR-006] Use custom error types when you need to convey structured information:

  ```go
  type ValidationError struct {
      Field   string
      Message string
  }
  func (e *ValidationError) Error() string {
      return fmt.Sprintf("validation failed on %s: %s", e.Field, e.Message)
  }
  ```

- [GO-ERR-007] Check errors with `errors.Is()` for sentinel errors and `errors.As()` for typed errors - never compare error strings.

### 6.3 Error handling patterns (reduce boilerplate)

- [GO-ERR-008] **Errors are values** - leverage this by creating stateful error writers or builders when you have repetitive error-checking patterns:

  ```go
  type errWriter struct {
      w   io.Writer
      err error
  }
  func (ew *errWriter) write(data []byte) {
      if ew.err != nil {
          return
      }
      _, ew.err = ew.w.Write(data)
  }
  ```

- [GO-ERR-009] For operations that can only fail once (like `bufio.Writer`), check the error at the end rather than after each operation.

### 6.4 Panic and recover

- [GO-ERR-010] **Never panic for expected error conditions.** Panics are for truly unrecoverable situations (programmer errors, invariant violations).
- [GO-ERR-011] Use `recover()` only at well-defined boundaries (HTTP handlers, goroutine entry points) to prevent one bad request from crashing the service.
- [GO-ERR-012] When recovering, log the panic with stack trace and return a proper error to the caller.

---

## 7. Concurrency patterns (expert-level) 🔄

Go's concurrency model is powerful but has subtle pitfalls. These rules ensure correct, maintainable concurrent code.

### 7.1 Goroutine lifecycle management

- [GO-CONC-001] **Never start goroutines that you cannot stop.** Every goroutine must have a clear termination condition.
- [GO-CONC-002] Use `context.Context` for cancellation propagation. Pass context as the first parameter to functions that may block.
- [GO-CONC-003] When spawning goroutines, prefer `errgroup.Group` for coordinated error handling and cancellation:

  ```go
  g, ctx := errgroup.WithContext(ctx)
  g.Go(func() error { return worker1(ctx) })
  g.Go(func() error { return worker2(ctx) })
  if err := g.Wait(); err != nil {
      return err
  }
  ```

- [GO-CONC-004] Document goroutine ownership clearly. The entity that starts the goroutine should be responsible for ensuring it terminates.

### 7.2 Channel patterns

- [GO-CONC-005] **Prefer channel size of zero (unbuffered) or one.** Any other size requires strong justification with performance data.
- [GO-CONC-006] Unbuffered channels provide synchronisation guarantees; buffered channels are for decoupling. Choose deliberately.
- [GO-CONC-007] The sender should close channels, never the receiver. Only close channels when there are no more values to send.
- [GO-CONC-008] Use `select` with a `default` case only when you truly mean "non-blocking"; otherwise, let the `select` block.

### 7.3 Mutex patterns

- [GO-CONC-009] **Use zero-value mutexes.** Do not initialise mutexes explicitly; `var mu sync.Mutex` is ready to use.
- [GO-CONC-010] **Never copy mutexes.** Pass by pointer or embed in structs (which are also not copied).
- [GO-CONC-011] Keep mutex scope minimal. Protect only the data that needs protection, not entire functions.
- [GO-CONC-012] Prefer `sync.RWMutex` when reads significantly outnumber writes and there's proven contention.

### 7.4 Atomic operations

- [GO-CONC-013] Use `sync/atomic` for simple counters and flags. Prefer `atomic.Int64`, `atomic.Bool` (Go 1.19+) over raw `atomic.AddInt64`.
- [GO-CONC-014] Do not use atomics when the operation requires reading and writing multiple fields - use a mutex instead.

### 7.5 Avoiding data races

- [GO-CONC-015] **Always run tests with `-race`** in CI. Data races are undefined behaviour in Go.
- [GO-CONC-016] **Copy slices and maps at API boundaries** to prevent accidental sharing:

  ```go
  func (s *Store) GetItems() []Item {
      s.mu.RLock()
      defer s.mu.RUnlock()
      return slices.Clone(s.items) // Defensive copy
  }
  ```

---

## 8. Memory, allocation, and GC (expert tuning) 🧠

Understanding Go's memory model enables significant performance improvements.

### 8.1 Escape analysis awareness

- [GO-MEM-001] **Understand stack vs. heap allocation.** Values that don't escape the function are stack-allocated (cheap). Values that escape (returned, stored in interface, passed to goroutines) are heap-allocated (GC pressure).
- [GO-MEM-002] Use `go build -gcflags='-m=3'` to see escape analysis decisions. Address hot paths that escape unnecessarily.
- [GO-MEM-003] Returning pointers to local variables is fine in Go (compile-safe), but increases heap allocations. Return values when practical.

### 8.2 Reducing allocations

- [GO-MEM-004] **Pre-allocate slices and maps** when the size is known or estimable:

  ```go
  items := make([]Item, 0, expectedCount)
  lookup := make(map[string]Item, expectedCount)
  ```

- [GO-MEM-005] Use `sync.Pool` for frequently allocated and discarded objects (for example buffers in HTTP handlers).
- [GO-MEM-006] Use `strings.Builder` for string concatenation in loops, not `+` or `fmt.Sprintf`.

### 8.3 GC tuning

- [GO-MEM-007] **Understand GOGC and GOMEMLIMIT** (Go 1.19+):
  - `GOGC=100` (default): GC triggers when heap doubles
  - Increase `GOGC` to reduce GC frequency at cost of memory
  - Use `GOMEMLIMIT` to cap memory usage (for containers); allows setting `GOGC=off` for latency-critical workloads
- [GO-MEM-008] For containerised workloads, set `GOMEMLIMIT` to 90-95% of the container limit, leaving headroom for non-heap memory.
- [GO-MEM-009] Pointer-free data structures have lower GC overhead. Group pointer fields at the start of structs so the GC can stop scanning earlier.

### 8.4 Profile-Guided Optimisation (PGO)

- [GO-MEM-010] **Use PGO for production builds** (Go 1.21+):
  - Collect CPU profiles from production with `runtime/pprof`
  - Place `default.pgo` in the main package directory
  - Build with `go build` (auto-detects PGO file) or `go build -pgo=path/to/profile.pprof`
- [GO-MEM-011] PGO typically provides 2-7% performance improvement. Re-collect profiles periodically as code changes.

---

## 9. Structured logging with `log/slog` (Go 1.21+) 📝

- [GO-LOG-001] **Use `log/slog`** for structured logging in new code. It is the standard library solution and supports JSON output natively.
- [GO-LOG-002] Structure log calls with key-value attributes:

  ```go
  slog.Info("request completed",
      "method", r.Method,
      "path", r.URL.Path,
      "duration", time.Since(start),
      "status", status,
  )
  ```

- [GO-LOG-003] Create child loggers with context-specific attributes:

  ```go
  logger := slog.With("request_id", requestID, "user_id", userID)
  ```

- [GO-LOG-004] Use appropriate log levels: `Debug` for development, `Info` for operational events, `Warn` for recoverable issues, `Error` for failures.
- [GO-LOG-005] In production, use `slog.NewJSONHandler` for machine-parseable logs. Use `slog.NewTextHandler` for human-readable development logs.
- [GO-LOG-006] **Never log secrets, tokens, passwords, or PII** - use redaction helpers if needed.
- [GO-LOG-007] Use `slog.LogValuer` interface to customise how types are logged (for example to redact sensitive fields).

---

## 10. Testing approach (TDD, table-driven) 🧪

Per [constitution.md §3.6](../../.specify/memory/constitution.md#36-design-for-testability-tdd), follow a test-first flow for behaviour changes:

1. Write/update a test **from the specification**.
2. Confirm it fails for the right reason.
3. Implement the minimal change to pass.
4. Refactor after green, preserving behaviour.

### 10.1 Table-driven tests

- [GO-TST-001] **Prefer table-driven tests** for functions with multiple input/output scenarios:

  ```go
  func TestParseDuration(t *testing.T) {
      tests := []struct {
          name    string
          input   string
          want    time.Duration
          wantErr bool
      }{
          {"valid seconds", "30s", 30 * time.Second, false},
          {"valid minutes", "5m", 5 * time.Minute, false},
          {"invalid", "abc", 0, true},
      }
      for _, tt := range tests {
          t.Run(tt.name, func(t *testing.T) {
              got, err := ParseDuration(tt.input)
              if (err != nil) != tt.wantErr {
                  t.Errorf("error = %v, wantErr %v", err, tt.wantErr)
                  return
              }
              if got != tt.want {
                  t.Errorf("got %v, want %v", got, tt.want)
              }
          })
      }
  }
  ```

- [GO-TST-002] Include `name` field in test cases for clear failure messages.
- [GO-TST-003] Use `t.Parallel()` for independent tests, but understand when shared state prevents parallelism.

### 10.2 Test organisation

- [GO-TST-004] Prefer the test pyramid:
  - [GO-TST-004a] **most tests**: unit (fast, deterministic, behaviour-focused)
  - [GO-TST-004b] **some tests**: integration (uses real databases/services via containers)
  - [GO-TST-004c] **few tests**: end-to-end (critical journeys only)
- [GO-TST-005] Tests must be deterministic:
  - [GO-TST-005a] control time (inject `time.Now` or use `clockwork`)
  - [GO-TST-005b] use `t.TempDir()` for filesystem tests
  - [GO-TST-005c] avoid real network by default
- [GO-TST-006] Use build tags (`//go:build integration`) to separate slow tests from `go test ./...`.

### 10.3 Testability patterns

- [GO-TST-007] Use **functional options** for configurable dependencies:

  ```go
  func NewClient(opts ...Option) *Client {
      c := &Client{httpClient: http.DefaultClient, timeout: 30 * time.Second}
      for _, opt := range opts {
          opt(c)
      }
      return c
  }

  func WithHTTPClient(hc *http.Client) Option {
      return func(c *Client) { c.httpClient = hc }
  }
  ```

  This pattern is superior to config structs for:
  - Backward-compatible API evolution
  - Clear defaults that can be overridden
  - Self-documenting option functions

- [GO-TST-008] Design for dependency injection. Accept interfaces in constructors for mockable boundaries.
- [GO-TST-009] For compile-time dependency injection, consider **Wire** (google/wire) for complex dependency graphs.

---

## 11. Code organisation and maintainability ✍️

Per [constitution.md §7](../../.specify/memory/constitution.md#7-code-quality-guardrails):

### 11.1 Package design

- [GO-CODE-001] **Package by domain, not by layer.** Prefer `user/`, `order/`, `payment/` over `models/`, `controllers/`, `services/`.
- [GO-CODE-002] Keep packages cohesive. If a package has many unrelated responsibilities, split it.
- [GO-CODE-003] Avoid package names like `util`, `common`, `helpers`, `misc` - they become dumping grounds.
- [GO-CODE-004] Use `internal/` for code that should not be imported by other modules.

### 11.2 Enforcing architectural boundaries with linter rules

When a specification or architecture decision imposes import-direction or dependency constraints, **express them as linter configuration rather than custom Go test code**. Linter rules run on every `make lint`, produce clear error messages, and require no custom test maintenance.

- [GO-CODE-009] Use `depguard` (in `.golangci.yml`) to enforce import restrictions between packages:
  - [GO-CODE-009a] Define named rule groups scoping file patterns to allowed/denied import paths.
  - [GO-CODE-009b] Include the requirement ID in the `desc` field so failures are self-documenting.
  - [GO-CODE-009c] Typical patterns: pipeline isolation (no concrete rule/formatter imports), rule isolation (no sibling rule imports), logger discipline (no stdlib `log` outside the logger package).
- [GO-CODE-010] Use `gomodguard` (in `.golangci.yml`) to enforce module-level bans:
  - [GO-CODE-010a] Block deprecated or banned modules with a `reason` referencing the requirement ID.
  - [GO-CODE-010b] Use for non-goal enforcement (e.g. banning AI/NLP libraries from an MVP).
- [GO-CODE-011] **Only use custom Go architecture tests** (AST scanning, `go/packages`) for constraints that linter rules cannot express: call-order verification, banned function-call patterns within a package, interface signature checks, or cross-file structural invariants.

### 11.3 Naming conventions

- [GO-CODE-005] Use **MixedCaps** (exported) and **mixedCaps** (unexported). Do not use underscores in Go names.
- [GO-CODE-006] Prefer short, descriptive names. In Go: `i` for loop index, `r` for reader, `w` for writer, `ctx` for context, `err` for error.
- [GO-CODE-007] Avoid stuttering: `user.User` is fine, but `user.UserService` in package `user` should just be `Service`.
- [GO-CODE-008] Acronyms should be all caps: `HTTP`, `URL`, `ID`, not `Http`, `Url`, `Id`.

### 11.4 Struct organisation

- [GO-CODE-012] Group struct fields logically. Put related fields together.
- [GO-CODE-013] Order fields to minimise padding (largest alignment first), or use `fieldalignment` linter.
- [GO-CODE-014] **Start enums at one, not zero**, unless zero has explicit meaning:

  ```go
  type Status int

  const (
      StatusUnknown Status = iota // Zero value means "unset"
      StatusPending
      StatusActive
      StatusComplete
  )
  ```

  This ensures uninitialized values are distinguishable from valid values.

### 11.5 Time handling

- [GO-CODE-015] **Always use `time.Duration` for time periods**, never raw integers:

  ```go
  // Good
  func Retry(attempts int, delay time.Duration) error

  // Bad - is this seconds? milliseconds?
  func Retry(attempts int, delay int) error
  ```

- [GO-CODE-016] Store and transmit times in UTC. Convert to local time only for display.
- [GO-CODE-017] Use `time.Time` for timestamps, not Unix epoch integers.

---

## 12. HTTP handling (net/http patterns) 🌐

Go 1.22+ introduced improved `ServeMux` patterns.

### 12.1 Modern routing (Go 1.22+)

- [GO-HTTP-001] Use method patterns in routes:

  ```go
  mux.HandleFunc("GET /users/{id}", getUser)
  mux.HandleFunc("POST /users", createUser)
  mux.HandleFunc("DELETE /users/{id}", deleteUser)
  ```

- [GO-HTTP-002] Access path parameters with `r.PathValue("id")`.
- [GO-HTTP-003] Use wildcards for catch-all routes:

  ```go
  mux.HandleFunc("GET /files/{path...}", serveFile)
  ```

### 12.2 Handler patterns

- [GO-HTTP-004] Handlers should be methods on a struct containing dependencies:

  ```go
  type Server struct {
      store  Store
      logger *slog.Logger
  }

  func (s *Server) handleGetUser(w http.ResponseWriter, r *http.Request) {
      // Access s.store, s.logger
  }
  ```

- [GO-HTTP-005] Use middleware for cross-cutting concerns (logging, auth, tracing). Chain with:

  ```go
  handler := logging(auth(server.handleGetUser))
  ```

### 12.3 Timeouts and graceful shutdown

- [GO-HTTP-006] **Always set server timeouts**:

  ```go
  server := &http.Server{
      Addr:         ":8080",
      ReadTimeout:  5 * time.Second,
      WriteTimeout: 10 * time.Second,
      IdleTimeout:  120 * time.Second,
  }
  ```

- [GO-HTTP-007] Implement graceful shutdown:

  ```go
  ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
  defer cancel()
  if err := server.Shutdown(ctx); err != nil {
      log.Error("shutdown error", "error", err)
  }
  ```

---

## 13. Modern Go features (1.21+) 🆕

### 13.1 Generics (use judiciously)

- [GO-GEN-001] Use generics for **container types and utility functions** operating on language-defined types (slices, maps, channels).
- [GO-GEN-002] Use generics when you find yourself writing **identical code for different types**.
- [GO-GEN-003] **Do not use generics to replace interface parameters** - if method behaviour differs per type, interfaces are correct.
- [GO-GEN-004] For generic data structures needing comparison, prefer passing a comparator function over requiring a method:

  ```go
  type Tree[T any] struct {
      cmp func(a, b T) int
      // ...
  }
  ```

### 13.2 Iterators (Go 1.23+)

- [GO-GEN-005] Use range-over-function for custom iteration:

  ```go
  func (s *Store) All() iter.Seq[Item] {
      return func(yield func(Item) bool) {
          for _, item := range s.items {
              if !yield(item) {
                  return
              }
          }
      }
  }

  // Usage: for item := range store.All() { ... }
  ```

- [GO-GEN-006] Use `slices.Sorted(maps.Keys(m))` for sorted key iteration (Go 1.23+).

### 13.3 New standard library packages

- [GO-GEN-007] Use `slices` package for slice operations: `slices.Sort`, `slices.Contains`, `slices.Clone`, `slices.Compact`.
- [GO-GEN-008] Use `maps` package for map operations: `maps.Keys`, `maps.Values`, `maps.Clone`.
- [GO-GEN-009] Use `cmp` package for comparisons: `cmp.Or` for defaults, `cmp.Compare` for ordering.
- [GO-GEN-010] Use `unique` package (Go 1.23+) for interning/canonicalising comparable values when memory efficiency matters.

---

## 14. Build, packaging, and release 📦

### 14.1 Build reproducibility

- [GO-PKG-001] Use `go build -trimpath` to remove local paths from binaries.
- [GO-PKG-002] Embed version information at build time:

  ```go
  var version = "dev"

  // Build with: go build -ldflags="-X main.version=1.2.3"
  ```

- [GO-PKG-003] Use `go build -buildvcs=true` (default in Go 1.18+) to embed VCS info accessible via `runtime/debug.ReadBuildInfo()`.

### 14.2 Binary distribution

- [GO-PKG-004] Provide `--version` flag that prints version, commit SHA, and build time.
- [GO-PKG-005] Cross-compile with `GOOS` and `GOARCH` environment variables.
- [GO-PKG-006] Use `CGO_ENABLED=0` for static binaries when cgo is not required.

---

## 15. Security 🔒

- [GO-SEC-001] **Use `crypto/rand` for security-sensitive randomness**, never `math/rand`:

  ```go
  import "crypto/rand"

  bytes := make([]byte, 32)
  if _, err := rand.Read(bytes); err != nil {
      return err
  }
  ```

- [GO-SEC-002] Never store secrets in code. Use environment variables, secrets managers, or config files excluded from VCS.
- [GO-SEC-003] Validate and sanitise all external input at system boundaries.
- [GO-SEC-004] Use `html/template` for HTML output (auto-escaping). Never use `text/template` for HTML.
- [GO-SEC-005] Set appropriate HTTP security headers (CSP, X-Frame-Options, etc.) in API responses.
- [GO-SEC-006] Use `gosec` linter (via golangci-lint) to detect security anti-patterns.

---

## 16. AI-assisted change expectations 🤖

Per [constitution.md §3.5](../../.specify/memory/constitution.md#35-ai-assisted-development-discipline--change-governance), when you create or modify code:

- [GO-AI-001] Follow the shared [AI change baseline](./includes/ai-assisted-change-baseline.include.md) for scope, quality, and governance.
- [GO-AI-002] Update documentation/contracts only when required by the specification.

---

## 17. Documentation and style ✏️

- [GO-DOC-001] Write doc comments for all exported symbols. Start with the symbol name:

  ```go
  // Client represents an HTTP client for the user service.
  type Client struct { ... }

  // NewClient creates a new Client with the given options.
  func NewClient(opts ...Option) *Client { ... }
  ```

- [GO-DOC-002] Use complete sentences ending with periods in doc comments.
- [GO-DOC-003] Add package-level documentation in `doc.go` for non-trivial packages.
- [GO-DOC-004] Use `// Deprecated:` comment prefix for deprecated symbols.

---

## 18. Observability (baseline) 📊

Follow the shared [observability baseline](./includes/observability-baseline.include.md) and these Go-specific additions:

- [GO-OBS-001] Use `log/slog` with correlation IDs for request tracing (§9).
- [GO-OBS-002] Export metrics via Prometheus client or OpenTelemetry.
- [GO-OBS-003] Use `runtime/pprof` and `net/http/pprof` for profiling. Enable pprof endpoint in debug builds only.
- [GO-OBS-004] For distributed tracing, use OpenTelemetry SDK with context propagation.

---

## 19. External dependencies and boundaries 🔗

- [GO-EXT-001] **Prefer standard library** when it meets requirements. Third-party dependencies add maintenance burden.
- [GO-EXT-002] Wrap external dependencies behind interfaces for testability and substitutability.
- [GO-EXT-003] Pin dependency versions and review updates carefully.
- [GO-EXT-004] Prefer direct dependencies over transitive ones when both are options.
- [GO-EXT-005] Local development must not require cloud credentials by default.
- [GO-EXT-006] Use emulators or fakes for local testing of external services.
- [GO-EXT-007] Mark integration tests with build tags: `//go:build integration`.

---

## 20. Performance and resilience 🚀

### 20.1 General performance

- [GO-PERF-001] Avoid premature optimisation, but do not allow unbounded inefficiency.
- [GO-PERF-002] Profile before optimising. Use `go tool pprof` with CPU, memory, and block profiles.
- [GO-PERF-003] Use benchmarks (`func BenchmarkXxx(b *testing.B)`) to measure and prevent regressions.

### 20.2 Resilience patterns

- [GO-PERF-004] All outbound calls must have explicit timeouts via `context.WithTimeout`.
- [GO-PERF-005] Implement retries with exponential backoff and jitter for transient failures.
- [GO-PERF-006] Use circuit breakers for failing downstream services.
- [GO-PERF-007] Prefer streaming/pagination for large datasets.

### 20.3 AWS Lambda considerations

- [GO-PERF-008] Minimise cold starts: keep binary small, avoid init() work, lazy-load heavy resources.
- [GO-PERF-009] Reuse clients across invocations (declare at package scope, initialise once).
- [GO-PERF-010] Set `GOMEMLIMIT` appropriately for Lambda memory configuration.

---

## 21. Anti-patterns (recognise and avoid) 🚫

These patterns cause recurring issues in Go codebases. Avoid them unless an ADR documents a justified exception.

- [GO-ANT-001] **Ignoring errors** - every error must be handled or explicitly ignored with `_ =` and a comment.
- [GO-ANT-002] **Naked goroutines** - goroutines without lifecycle management leak resources. Use errgroup or explicit shutdown.
- [GO-ANT-003] **init() abuse** - `init()` runs implicitly, making code hard to test and reason about. Prefer explicit initialisation.
- [GO-ANT-004] **Global mutable state** - avoid package-level variables that can be modified. Use dependency injection.
- [GO-ANT-005] **Interface pollution** - defining interfaces you don't need or interfaces with too many methods.
- [GO-ANT-006] **Returning interfaces** - return concrete types; let consumers define interfaces.
- [GO-ANT-007] **Using `panic` for error handling** - panic is for unrecoverable situations, not control flow.
- [GO-ANT-008] **Nil channel operations** - sending to or receiving from a nil channel blocks forever. Initialise channels before use.
- [GO-ANT-009] **Copying sync types** - `sync.Mutex`, `sync.WaitGroup`, etc. must not be copied. Pass by pointer.
- [GO-ANT-010] **Empty slice vs. nil slice confusion** - `var s []int` is nil, `s := []int{}` is empty but non-nil. Be explicit about which you mean.
- [GO-ANT-011] **Using `time.Sleep` for synchronisation** - use channels or sync primitives for coordination, not sleep.
- [GO-ANT-012] **Shadow declarations** - redeclaring variables in inner scopes (especially `err`) causes subtle bugs. Use `golangci-lint` with `govet` shadow check.
- [GO-ANT-013] **Embedding exported types in exported structs** - promotes all embedded methods, breaking encapsulation. Prefer explicit delegation.
- [GO-ANT-014] **Using reflection when generics suffice** - reflection is slower, harder to read, and not type-safe. Use generics when type flexibility is needed.
- [GO-ANT-015] **Comparing structs containing slices/maps directly** - use `reflect.DeepEqual` or custom comparison; direct comparison fails to compile or compares pointers.
