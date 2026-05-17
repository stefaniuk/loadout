---
applyTo: "**/*.{rs,ts,tsx,js,jsx}"
description: "Tauri Engineering Instructions"
---

# Tauri Engineering Instructions 🖥️

These instructions define **Tauri-specific integration patterns** for building secure, performant desktop applications with a Rust core and web-based UI.

They must remain applicable to:

- Tauri v2 desktop applications
- Cross-platform builds (Windows, macOS, Linux)
- Applications requiring filesystem access, IPC, and system integration
- Enterprise distribution with signing and updates

For general language guidance, defer to:

- [rust.instructions.md](./rust.instructions.md) — Rust idioms, error handling, patterns
- [reactjs.instructions.md](./reactjs.instructions.md) — React component design, hooks, state
- [typescript.instructions.md](./typescript.instructions.md) — TypeScript strictness, typing patterns

This file covers **only** what those files do not: the Tauri security model, IPC design, capability configuration, and desktop-specific integration concerns.

They are **non-negotiable** unless an exception is explicitly documented (with rationale and expiry) in an ADR/decision record.

**Identifier scheme.** Every normative rule carries a unique tag in the form `[TAU-<prefix>-NNN]`, where the prefix maps to the containing section (for example `QR` for Quick Reference, `SEC` for Security Model, `IPC` for IPC Patterns, `CAP` for Capabilities). Use these identifiers when referencing, planning, or validating requirements.

---

## 0. Quick reference (apply first) 🧠

This section exists so humans and AI assistants can reliably apply the most important rules even when context is tight.

- [TAU-QR-001] **Least privilege**: grant only required capabilities per window; never enable everything for convenience ([TAU-CAP-001]).
- [TAU-QR-002] **Strict CSP**: maintain strict Content Security Policy; never weaken it to "make something work" ([TAU-SEC-001]).
- [TAU-QR-003] **No remote content**: do not load remote scripts/CDNs in production; local assets only ([TAU-SEC-003]).
- [TAU-QR-004] **UI is untrusted**: all privileged operations belong in Rust; treat frontend input as hostile ([TAU-SEC-005]).
- [TAU-QR-005] **Commands for request/response**: use Tauri commands for discrete operations ([TAU-IPC-001]).
- [TAU-QR-006] **Events for streaming**: use events for progress, batches, and state changes ([TAU-IPC-002]).
- [TAU-QR-007] **Operation IDs**: tag all long-running work with an `op_id` for tracking and cancellation ([TAU-IPC-005]).
- [TAU-QR-008] **Cleanup listeners**: always unregister event listeners on component unmount ([TAU-IPC-008]).
- [TAU-QR-009] **Stream large results**: never return huge arrays from commands; batch via events ([TAU-IPC-003]).
- [TAU-QR-010] **Sign updates**: if using the updater, signatures are mandatory and cannot be disabled ([TAU-DST-003]).

---

## 1. Security model (Tauri-specific, non-negotiable) 🔒

### 1.1 Content Security Policy

- [TAU-SEC-001] Maintain a **strict CSP**; avoid `unsafe-inline`, `unsafe-eval`, and permissive wildcards.
- [TAU-SEC-002] Prefer local assets bundled with the application; treat remote content as an attack vector.
- [TAU-SEC-003] Do not load remote scripts or CDNs in production builds.
- [TAU-SEC-004] If remote content is ever required (exceptional case), constrain to exact trusted origins and document the risk.

### 1.2 Trust boundary

- [TAU-SEC-005] Treat the frontend as **untrusted input**; validate and sanitise all data received from the UI in Rust.
- [TAU-SEC-006] Never call a shell or execute commands with user-provided strings.
- [TAU-SEC-007] Canonicalise and validate all filesystem paths in Rust before use; handle symlinks explicitly.

---

## 2. Capabilities and permissions 🛡️

- [TAU-CAP-001] Define capabilities **per window/webview**; grant only the permissions that window requires.
- [TAU-CAP-002] For each plugin, explicitly enable only required permissions; document _why_ each is needed.
- [TAU-CAP-003] Avoid broad default permissions (for example `fs:allow-read` on `/`) unless explicitly justified in an ADR.
- [TAU-CAP-004] Review capability configuration as part of code review; treat permission changes as security-sensitive.
- [TAU-CAP-005] If configuring remote URL capabilities, constrain to exact trusted origins and document implications.
- [TAU-CAP-006] Default posture: remote sources must not access local system APIs.

---

## 3. IPC patterns (commands and events) 🔌

### 3.1 Commands vs events

- [TAU-IPC-001] Use **commands** for discrete request/response operations (for example `get_file_info`, `rename_item`).
- [TAU-IPC-002] Use **events** for streaming data: progress updates, large result batches, state-change notifications.
- [TAU-IPC-003] Never return unbounded arrays from commands; stream results in batches (for example 100–500 items per event).
- [TAU-IPC-004] Throttle event frequency (for example ~4–10 updates/sec for progress) to avoid IPC flooding.

### 3.2 Operation lifecycle

- [TAU-IPC-005] All long-running operations must have an `op_id` (generated by UI or returned by Rust).
- [TAU-IPC-006] Emit events tagged with `op_id` so UI can correlate updates to the correct operation.
- [TAU-IPC-007] Provide a cancellation command (for example `cancel_operation({ op_id })`) for interruptible work.

### 3.3 Listener hygiene

- [TAU-IPC-008] Unregister event listeners on component unmount/navigation; leaked listeners cause memory issues and stale updates.
- [TAU-IPC-009] Prefer a single subscription per window that routes by `op_id`, rather than many fine-grained listeners.

### 3.4 API versioning

- [TAU-IPC-010] Use a versioned command namespace (for example `v1_list_dir`, `v1_start_search`) to allow non-breaking evolution.
- [TAU-IPC-011] Keep Rust and TypeScript payload types in sync; generate TS types from Rust where practical.

---

## 4. Typed API layer (frontend) 🎯

- [TAU-API-001] Wrap all `invoke` calls and event subscriptions in a single `coreApi` module; do not scatter raw `invoke` calls.
- [TAU-API-002] Type command inputs and outputs; validate at runtime for critical boundaries.
- [TAU-API-003] Model operation state as a finite-state machine: `idle → running → completed | failed | cancelled`.

---

## 5. Error contract (Rust ↔ UI) ⚠️

- [TAU-ERR-001] Define a stable `AppError` type with:
  - `code` — stable machine-readable identifier (for example `FS_PERMISSION_DENIED`)
  - `message` — user-safe explanation
  - `details` — optional developer context
  - `context` — optional path / `op_id` / job reference
- [TAU-ERR-002] UI must display only `message` by default; `details` is for logs/debug.
- [TAU-ERR-003] Commands must return `Result<T, AppError>`; never panic for user-triggered conditions (per [RS-ERR-001]).

---

## 6. Streaming and performance 🚀

- [TAU-PERF-001] Perform all heavy work (filesystem, hashing, search, large JSON) in Rust; stream results to UI.
- [TAU-PERF-002] Use Tokio `spawn_blocking` or a thread pool for CPU-bound or blocking IO; do not block the async runtime.
- [TAU-PERF-003] Prefer incremental/backpressure-friendly streams over "return everything at once".
- [TAU-PERF-004] UI should virtualise large lists (directories, search hits) to avoid render storms.

---

## 7. Packaging and distribution 📦

- [TAU-DST-001] Pin toolchains: `rust-toolchain.toml`, `Cargo.lock`, and frontend lockfile (`pnpm-lock.yaml` / `package-lock.json`).
- [TAU-DST-002] Build release artefacts in CI with a clean, reproducible environment.
- [TAU-DST-003] If using the Tauri updater, **sign updates**; signatures are mandatory and cannot be disabled.
- [TAU-DST-004] Document key management (rotation, access control; HSM/KMS for enterprise).

---

## 8. Testing strategy 🧪

- [TAU-TST-001] Unit-test Rust command logic in isolation (path handling, error mapping, queue logic).
- [TAU-TST-002] Integration-test file operations using temp directories; cover edge cases (permissions, symlinks, large directories).
- [TAU-TST-003] Smoke-test IPC round-trips: invoke a command from a real webview and assert the response.
- [TAU-TST-004] Include dependency scanning (Rust + npm) in CI; fail on critical vulnerabilities per policy.

---

## 9. Anti-patterns ❌

- [TAU-ANT-001] Do not weaken CSP to "get it working".
- [TAU-ANT-002] Do not grant broad capabilities without explicit justification.
- [TAU-ANT-003] Do not return huge arrays from commands; stream via events.
- [TAU-ANT-004] Do not perform heavy filesystem IO on the UI thread.
- [TAU-ANT-005] Do not load remote web content that can invoke local capabilities.
- [TAU-ANT-006] Do not leak event listeners; always clean up on unmount.

---

## 10. Quality checklist ✅

Before shipping a Tauri application, verify:

- [TAU-CHK-001] Capabilities grant only required permissions per window
- [TAU-CHK-002] CSP is strict; no remote scripts in production
- [TAU-CHK-003] All commands return `Result<T, AppError>`; no panics on user input
- [TAU-CHK-004] Long-running work uses `op_id` and supports cancellation
- [TAU-CHK-005] Large results are streamed, not returned in bulk
- [TAU-CHK-006] Event listeners are cleaned up on unmount
- [TAU-CHK-007] Updates are signed (if updater is enabled)
- [TAU-CHK-008] Rust code follows [rust.instructions.md](./rust.instructions.md)
- [TAU-CHK-009] React/TS code follows [reactjs.instructions.md](./reactjs.instructions.md) and [typescript.instructions.md](./typescript.instructions.md)

---

> **Version**: 1.1.0
> **Last Amended**: 2026-01-11
