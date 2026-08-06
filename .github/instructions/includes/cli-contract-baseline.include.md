# CLI Contract Baseline ⌨️

Use this shared baseline for the **canonical CLI contract** (exit codes and stream semantics) across languages. Individual instruction sets must link here instead of duplicating the guidance.

**Identifier scheme.** Every normative rule carries a unique tag in the form `[CLI-<prefix>-NNN]`, where the prefix maps to the containing section (for example `EXIT` for Exit Codes, `STR` for Streams, `DOC` for Documentation, `ERG` for Ergonomics, `WRP` for Wrappers, `CLD` for Cloud). Use these identifiers when referencing, planning, or validating requirements.

---

## 1. Exit codes (non-negotiable) 🚦

- [CLI-EXIT-001] `0` - successful completion.
- [CLI-EXIT-002] `1` - general operational failure (unexpected error, dependency failure) when no more specific code exists.
- [CLI-EXIT-003] `2` - usage error (invalid flags/args, missing required input, mutually exclusive options).
- [CLI-EXIT-004] Reserve additional non-zero codes **only** when automation depends on them; document the mapping (code, meaning, user-facing hint) and add regression tests.
- [CLI-EXIT-005] Exit with the **first failure cause**; do not mask distinct failures behind the same code unless explicitly documented.
- [CLI-EXIT-006] Tests covering CLI boundaries must assert the relevant exit codes.
- [CLI-EXIT-007] Wrappers translating upstream tools or libraries must normalise their exit codes to this contract. If the wrapped system emits rich errors (for example JSON error payloads) surface the actionable snippet in diagnostics and map the numeric code to `0/1/2` (or a documented reserved value).

## 2. Stdout vs stderr (stream semantics) 📤

- [CLI-STR-001] `stdout` carries the primary result payloads (machine-readable JSON, tables, paths, generated artefacts). It **must** be safe to pipe into other commands without post-processing to strip diagnostics.
- [CLI-STR-002] `stderr` carries diagnostics (progress, warnings, errors, verbose/debug output). Diagnostics must remain human-readable and should include actionable next steps when reporting failures.
- [CLI-STR-003] Commands must behave correctly when `stdout` is redirected or piped; never interleave diagnostic text onto `stdout`.
- [CLI-STR-004] Long-running commands should emit progress to `stderr` (or structured logs) so that `stdout` remains clean.
- [CLI-STR-005] When producing mixed human + machine output, provide an explicit flag (for example `--json`) that switches `stdout` to the machine format while keeping diagnostics on `stderr`.
- [CLI-STR-006] Cloud runtimes (Lambda, Cloud Run, Functions) often wire `stdout/stderr` into log aggregators; keep payloads compact and avoid ANSI control codes unless the platform supports them.
- [CLI-STR-007] Flush and close streams explicitly before exiting short-lived serverless handlers so platforms do not drop trailing bytes.

## 3. Documentation and testing expectations 📋

- [CLI-DOC-001] Every published CLI must document the supported exit codes and diagnostic behaviours (README/help text + tests).
- [CLI-DOC-002] Integration tests must cover at least one success case (`0`) and each reserved non-zero code to prevent future drift.
- [CLI-DOC-003] When wrapping other tools, normalise their exit codes to this contract (translate upstream codes if necessary) and document any deliberate exceptions via ADR.
- [CLI-DOC-004] Help output (`--help`, `-h`) must describe the primary flags, mutually exclusive options, default value sources (env vars, config files), and provide a short usage example that demonstrates piping/JSON output when relevant.
- [CLI-DOC-005] Include smoke tests for wrapper CLIs proving that upstream failures still yield deterministic codes/diagnostics.

## 4. Colour and rich output 🎨

- [CLI-COL-001] Use colour only as a hinting system (headings, command names, required vs optional, warnings). Avoid colouring full paragraphs.
- [CLI-COL-002] Enable colour only when output is a TTY, respect `NO_COLOR` and `TERM=dumb`, and expose `--color=auto|always|never` (or `--no-color`).
- [CLI-COL-003] Keep output readable without colour; never rely on colour alone to convey meaning.
- [CLI-COL-004] Prefer well-formatted layouts that feel TUI-like but remain stream-friendly: aligned tables, grouped sections, and consistent 2-space indentation.
- [CLI-COL-005] Use progress spinners/bars only for long-running tasks and emit them to `stderr` so `stdout` remains pipe-safe.
- [CLI-COL-006] Avoid ANSI control codes in machine-readable outputs (`--json`) and in logs captured by cloud runtimes unless explicitly supported.
- [CLI-COL-007] When using styling helpers (`rich`, `chalk`, `fatih/color`, or `clap` styling), keep a single accent colour, wrap lines at 80–100 columns, and ensure placeholders are dimmed rather than bright.

## 5. Developer ergonomics 🧑‍💻

- [CLI-ERG-001] Provide `--help`, `--version`, and `--verbose` (or `--quiet`) switches consistently so that scripts can introspect capabilities and humans can self-serve.
- [CLI-ERG-002] Prefer explicit flags over positional arguments once more than two inputs are required; accept configuration via environment variables only when documented, and echo which sources were used in verbose diagnostics.
- [CLI-ERG-003] Offer `--dry-run` when the command mutates resources so that automation can validate intent without side effects.
- [CLI-ERG-004] Keep interactive prompts opt-in (`--interactive` or detection of TTY) and always provide a non-interactive equivalent flag for CI/CD use.

## 6. Wrappers and shared libraries 📦

- [CLI-WRP-001] Keep CLI entrypoints as thin adapters: parse/validate input, hand off to shared library functions, and forward exit codes. No business logic or domain processing belongs in the CLI handler itself.
- [CLI-WRP-002] When discrepancies arise between CLI behaviour and the underlying library (forked validation, duplicated transformations, etc.), schedule and execute a refactor to relocate the logic back into the shared code before adding new features.
- [CLI-WRP-003] When exposing library functionality through a CLI wrapper, surface the same validation rules and defaults as the library API so that behaviours stay aligned.
- [CLI-WRP-004] If multiple CLIs share common parsing or logging helpers, centralise that code in a module to keep flag semantics identical (for example the same `--region`, `--profile`, `--timeout` handling everywhere).
- [CLI-WRP-005] Ensure wrapper CLIs can be imported as libraries themselves where sensible (for example `main(args: list[str]) -> int`) so that AWS Lambda or other orchestrators can reuse the parsing logic without shelling out.

## 7. Cloud and serverless workloads

- [CLI-CLD-001] Design CLIs so they run cleanly inside short-lived containers/functions: avoid relying on background daemons, global temp dirs, or writable current directories unless you provision them explicitly.
- [CLI-CLD-002] Honour platform-imposed timeouts by surfacing `--timeout` flags and by writing periodic progress logs to `stderr` so that CloudWatch / Stackdriver shows activity.
- [CLI-CLD-003] Emit structured logs that comply with the shared observability baseline so that managed log routers can parse request IDs, correlation IDs, and severity levels.
- [CLI-CLD-004] Do not require interactive authentication flows; support token injection (`AWS_PROFILE`, `AZURE_TENANT_ID`, etc.) or credential files suitable for automation.
