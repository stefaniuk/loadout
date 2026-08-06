# Tech Radar

## Python tech stack

- [Python and dependency management](ADR-001a_Python_Dependency_Management.md): `uv`
- [Linting and formatting](ADR-001b_Python_Linting_and_Formatting.md): `ruff`
- [Type checking](ADR-001c_Python_Type_Checking.md): `mypy`
- [Testing](ADR-001d_Python_Testing_Tooling.md): `pytest` + `hypothesis` (PBT)
- [Logging](ADR-001e_Python_Logging.md): `structlog` or `Powertools for AWS Lambda`
- [CLI argument parsing](ADR-001f_Python_CLI_Argument_Parsing.md): `typer` + `rich`
- [TUI framework](ADR-001g_Python_TUI_Framework.md): `textual`

## TypeScript tech stack

- [TypeScript and dependency management](ADR-002a_TypeScript_Dependency_Management.md): Node.js (LTS) and `pnpm`
- [Linting and formatting](ADR-002b_TypeScript_Linting_and_Formatting.md): `biome`
- [Type checking](ADR-002c_TypeScript_Type_Checking.md): `tsc`
- [Testing](ADR-002d_TypeScript_Testing_Tooling.md): `vitest` + `fast-check` (PBT)
- [Logging](ADR-002e_TypeScript_Logging.md): `winston` or `Powertools for AWS Lambda`
- [CLI argument parsing](ADR-002f_TypeScript_CLI_Argument_Parsing.md): `commander` + `chalk`
- [TUI framework](ADR-002g_TypeScript_TUI_Framework.md): `ink`

## Go tech stack

- [Go and dependency management](ADR-003a_Go_Dependency_Management.md): Go and `go mod`
- [Linting and formatting](ADR-003b_Go_Linting_and_Formatting.md): `gofmt` and `golangci-lint`
- [Type checking](ADR-003c_Go_Static_Analysis_and_Type_Checking.md): `staticcheck`
- [Testing](ADR-003d_Go_Testing_Tooling.md): `go test` + `rapid` (PBT)
- [Logging](ADR-003e_Go_Logging.md): `zap`
- [CLI argument parsing](ADR-003f_Go_CLI_Argument_Parsing.md): `cobra` + `fatih/color`
- [TUI framework](ADR-003g_Go_TUI_Framework.md): `bubbletea` + `lipgloss`

## Rust tech stack

- [Rust and dependency management](ADR-004a_Rust_Dependency_Management.md): Rust and Cargo
- [Linting and formatting](ADR-004b_Rust_Linting_and_Formatting.md): `rustfmt` and `clippy`
- [Type checking](ADR-004c_Rust_Type_Checking.md): `cargo check`
- [Testing](ADR-004d_Rust_Testing_Tooling.md): `cargo test` + `proptest` (PBT)
- [Logging](ADR-004e_Rust_Logging.md): `tracing`
- [CLI argument parsing](ADR-004f_Rust_CLI_Argument_Parsing.md): `clap` (built-in styling)
- [TUI framework](ADR-004g_Rust_TUI_Framework.md): `ratatui`

Note: The `+` libraries (`rich`, `chalk`, `fatih/color`) provide colourful, well-formatted CLI output including styled `--help` text, progress bars, and terminal colours. They support TTY detection, `NO_COLOR`, and `--color=auto|always|never` flags.

Note: Selecting any default tool above still requires an ADR that compares and assesses at least two or three popular alternatives using the [ADR template](./ADR-nnn_Any_Decision_Record_Template.md).
