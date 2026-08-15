# Step 01 - Repository Map

Build a repository map that documents architecture, technology stack, and repo-level conventions (evidence-first).

## Goal

Create (or update): `.copilot/analysis/repository-map.md`.

Also ensure it is linked from the architecture overview at `.copilot/analysis/README.md`.

## Configuration (optional, evidence-first)

If not set, auto-detect from code/config. Do **not** guess.

- `${PROJECT_TYPE="Auto-detect|.NET|Java|JavaScript|TypeScript|React|Angular|Python|Node.js|Go|Other"}`
- `${ARCHITECTURE_PATTERN="Auto-detect|Clean Architecture|Microservices|Layered|MVVM|MVC|Hexagonal|Event-Driven|Serverless|Monolithic|Other"}`
- `${DETAIL_LEVEL="High-level|Detailed|Comprehensive"}`

## Discovery (run before writing)

### A. Identify "non-source" directories and their purpose

1. List top-level directories and classify them into:
   - **Source code** (application/service/library code)
   - **Infrastructure** (IaC, Kubernetes manifests, Helm, Terraform, etc.)
   - **Build/CI** (pipelines, scripts, tooling)
   - **Documentation/process** (docs, ADRs, runbooks, decision logs)
   - **Tests** (unit/integration/e2e/performance)
   - **Generated/vendor** (ignore for mapping unless referenced by build)
2. Record which directories appear to be **generated/vendor** and should be treated as _non-authoritative_.
3. Run `make clean` (if present), followed by `scc .` from the repository root to capture a lines-of-code breakdown by language.
   - Store the raw output in `.copilot/analysis/loc-report.txt`.
   - Summarise the top languages (by lines) in `repository-map.md` under a short **Size and language mix** section.
   - If `scc` is not available, record **Unknown from code - install scc or provide equivalent LOC output** and continue.

### B. Detect project type and architecture pattern (repo-level, evidence-first)

> This section creates a **single** repo-level statement. Do not repeat this per component; component details live in `component-*.md`.

1. Identify primary technology stacks by examining:
   - Project/config files (e.g. `pyproject.toml`, `package.json`, `tsconfig.json`, `*.csproj`, `pom.xml`, `go.mod`)
   - Lock files and workspace configuration (pnpm/npm/yarn/uv/poetry/pip-tools/Gradle/Maven/etc.)
   - Build and deployment configurations (Dockerfiles, workflows, scripts)
2. Determine the primary architecture pattern(s) by analysing:
   - Folder organisation and naming
   - Dependency direction (imports, layering, package boundaries)
   - Composition roots / DI wiring / router registrations
   - Communication mechanisms (HTTP, events/queues, schedules, CLI)
3. If `${PROJECT_TYPE}` or `${ARCHITECTURE_PATTERN}` are set (not Auto-detect), validate they match the evidence; otherwise record drift as **Unknown from code - reconcile config vs implementation**.

### C. Read context documents (non-authoritative)

1. Identify key context files such as:
   - `README*`, `doc*/**`, `adr/**`, `spec*/**`, `*.md`
2. Read them for hints and vocabulary only.
3. Do **not** treat them as authoritative unless confirmed by code/config. If an item is only present in docs, record it as **Unknown from code - verify**.

## Steps

### 1) Map the repository structure (focused and bounded)

1. Enumerate folders **up to five levels deep**, excluding generated/vendor directories.
2. For each top-level folder (and any folder that looks like a "root" for a product/service), summarise:
   - What it contains (one sentence)
   - Whether it looks like **app/service**, **library**, **shared package**, **infra**, **docs**, **tooling**, **tests**
3. Identify whether the repository is:
   - **Single application**, or
   - **Monorepo** (multiple deployable apps/services), or
   - **Multi-package repo** (shared libs + one deployable), and state which, with evidence.

### 2) Identify deployable units and entry points (per unit)

1. Identify each **deployable unit** (service/app/UI/API/job/CLI) and name it consistently.
2. For each deployable unit, capture:
   - **Entry point type**: HTTP server / worker / scheduled job / CLI / library-only
   - **Primary entry file(s)** (e.g. `main`, `app`, `server`, `cmd/*`, `bin/*`)
   - **How it is started** (command, script, container CMD/ENTRYPOINT, Procfile, systemd, etc.)
3. Identify how routing/command dispatch happens (where applicable):
   - HTTP route registration location(s)
   - CLI command registration location(s)
4. If monorepo, group results by service/app with clear headings.

### 3) Map build, test, and CI/CD (separate concerns)

#### 3A. Local build and run workflows

1. Identify canonical local commands:
   - Build
   - Run
   - Test (unit/integration/e2e)
   - Lint/format
2. Prefer `Makefile`, task runners, or scripts as the source of truth.

#### 3B. CI pipelines and quality gates

1. Identify CI systems in use (e.g. GitHub Actions) and list workflow files.
2. For each workflow, capture:
   - Triggers (push, PR, schedule, manual)
   - Main jobs (build/test/lint/security/deploy)
   - Artefacts produced (images, packages, reports)
3. Record security/scanning steps (SAST, dependency scanning, container scanning, SBOM), if present.
4. If licensing checks exist (e.g. SBOM generation, licence scanning), record them here; otherwise do not invent them.

#### 3C. Deployment artefacts and infrastructure

1. Identify deployment mechanisms:
   - Dockerfiles / container build
   - Helm charts / Kubernetes manifests
   - Terraform / other IaC
2. For each deployable unit, link to the deployment artefacts that apply to it.
3. Note environments if represented (dev/test/prod), and where configuration differs.

### 4) Map dependencies and platform usage (split and explicit)

#### 4A. Languages, frameworks, and runtime

1. Identify languages used and versions, if declared.
2. Identify main frameworks/libraries per deployable unit and versions.

#### 4B. Package managers and manifests

1. Identify manifests and lock files (per ecosystem) and where they live.
2. Note whether the repo uses workspaces (monorepo tooling) where applicable.

#### 4C. External services (inferred from code/config)

1. Identify external dependencies the system relies on, such as:
   - Datastores (SQL/NoSQL)
   - Messaging/queues
   - Caches
   - Object storage
   - Identity/auth providers
   - Third-party APIs
2. Only include a service if you can point to evidence in code/config (imports, clients, env vars, helm values, terraform resources, etc.).
3. Capture cloud managed services where evidenced (AWS/Azure/GCP resources, platform operators, etc.).

### 5) Repo-level conventions and "how to extend" (avoid duplication)

> Keep this repo-level and concise. Do **not** restate per component; component and flow docs hold the detail.

1. Document coding conventions that are enforced by tooling (formatters, linters, CI rules):
   - Naming conventions (if encoded in lint rules or templates)
   - Formatting (prettier/black/ruff/gofmt/etc.)
   - Import/module boundary rules (eslint boundaries, dep checks, etc.)
2. Identify any scaffolding/templates that shape new code (cookiecutter, generators, template dirs).
3. Provide a short "Blueprint for new development" section:
   - Where to put new **services/apps**
   - Where to put new **shared libraries**
   - How to introduce a new **external integration** (config + client + tests)
   - What tests are expected by default (unit/integration boundaries)
4. If the repo appears to use ADRs or decision logs, link to them; do not invent decision rationale.

## Evidence and unknowns (mandatory)

1. For each major statement, add an **Evidence** section with:
   - File path links (URLs must be prefixed with `/` so links resolve correctly)
   - Symbols (function/class names) and/or config keys (env vars, YAML keys)
2. When a required artefact cannot be found, record:
   - **Unknown from code - {action to confirm}**

## Output format

Use the following snippet inside `repository-map.md`:

```markdown
## {area}

{summary}

### Evidence

- Evidence: [path/to/file](/path/to/file#L10-L32) - {symbol or config key}
- Evidence: Unknown from code - {suggested action}
```
