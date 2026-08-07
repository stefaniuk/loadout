# Step 02 - Component Catalogue

Create component-level summaries (responsibilities, interfaces, data, and extension points).

## Goal

Create (or update) the component catalogue at `docs/prompt-reports/component-*.md`.

Also ensure they are linked from the architecture overview at `docs/prompt-reports/README.md`.

## Discovery (run before writing)

### A. Refresh what is already known

1. Re-read: `docs/prompt-reports/repository-map.md`.
2. Extract (briefly) into working notes:
   - Deployable units and entry points
   - Repo-level architecture statement and tech stack summary (do not repeat in every component)
   - Domains / bounded areas already mentioned
   - Datastores and external services already identified
   - Key configuration locations (values files, env var lists, config structs)

### B. Find explicit component boundaries (structure-driven)

1. Identify package/module boundaries from repository structure and manifests, for example:
   - Monorepo boundaries: `apps/`, `services/`, `packages/`, `libs/`, `api/`
   - Language-specific roots: `src/`, `cmd/`, `internal/`, `pkg/`, `cli/`
   - Package manifests and workspace configuration (per ecosystem)
2. Identify "shared" vs "owned" code:
   - Shared libraries/packages
   - Common utilities
   - Cross-cutting frameworks (logging, auth, config)

### C. Find implicit component boundaries (runtime-driven)

1. Locate registries and composition roots, for example:
   - HTTP route registration / controllers
   - DI containers / service registries
   - Plugin/module loaders
   - Background job schedulers / worker registries
2. Use these to confirm which components are real at runtime (not just folders).

## Steps

### 1) Select components (explicit criteria)

1. Select up to **12** components that best represent the architecture.
2. Prefer components that are:
   - Deployable units (services/apps/workers/CLIs), or
   - Major domain modules, or
   - Shared platform libraries used across multiple units
3. Ensure coverage across:
   - Primary user/system flows
   - Data ownership (who writes/reads what)
   - Integration surfaces (APIs/events/queues)
4. If selection is ambiguous, record the criteria in the component catalogue (e.g. "picked by deployability + domain ownership + highest call volume surfaces", evidence-based where possible).

### 2) Create one document per component (consistent scope)

For each component, create `docs/prompt-reports/component-[XXX]-[name].md`, where:

- `[XXX]` is a stable numeric order (e.g. `001`, `002`, `003`, ...) so links don't churn
- `[name]` is short and meaningful (kebab-case)

For each component document, capture:

#### 2A. Identity and scope

- Component name
- Component type (service/app/worker/CLI/library/module)
- Where it lives in the repo (folder roots)
- What it owns vs what it depends on (one short "Boundaries" paragraph)
- Architecture role (one line): e.g. edge/API, orchestration, domain core, integration adapter, persistence, shared platform

#### 2B. Purpose and responsibilities

- Purpose (why it exists)
- Responsibilities (bullet list; start each bullet with a verb)
- Non-responsibilities (what it explicitly does not do), if inferable

#### 2C. Internal structure and key abstractions

- Key modules/packages
- Key symbols (classes/functions) that represent the "public surface" of the component
- Composition root / startup wiring location (where applicable)
- Design patterns utilised (e.g. repository, mediator, ports/adapters) **only if evidenced**

#### 2D. Interfaces (split and explicit)

- **Inbound interfaces** (how other things call it)
  - HTTP routes (include route patterns and where they're registered)
  - Events/topics/queues consumed
  - CLI commands (if applicable)
  - Scheduled triggers (cron/schedules) (if applicable)
- **Outbound interfaces** (what it calls)
  - Downstream HTTP/gRPC clients
  - Events/topics/queues published
  - External dependencies (identity, email, payments, etc.)

#### 2E. Data flows and lineage (only if evidenced)

Include a brief, evidence-based view of how data moves through (or is produced/consumed by) this component.

- **Owned data (source of truth):** entities/tables/collections/schemas this component owns and writes
- **Derived/replicated data:** materialised views, projections, caches, read models
- **Consumed data (read-only):** entities/events this component reads but does not own
- **Published data:** events/messages produced, schema locations, topics/queues
- **Consumed data streams:** events/messages consumed, schema locations, topics/queues
- **Transformations:** where data is validated/transformed/enriched; key modules/symbols
- **Lineage notes:** origin → transformations → destinations (keep to 1–3 bullets)

If any item cannot be supported by code/config, record:

- **Unknown from code - {suggested action}**

Add evidence bullets for each of the above categories, for example:

- Evidence: `/path/to/migrations` - {table/entity}
- Evidence: `/path/to/producer#L10-L40` - {event name/topic}
- Evidence: `/path/to/consumer#L50-L120` - {handler/topic}
- Evidence: `/path/to/schema` - {schema name/version}

#### 2F. Cross-cutting concerns (component-specific, no duplication)

Document component-specific implementation details only. If a concern is identical across many components, capture it once (in the most "central" component or a shared doc) and link to it rather than repeating.

- Authentication/authorisation integration points (middleware/guards/clients)
- Error handling strategy (exceptions, error mapping, retry wrappers)
- Logging and correlation (how IDs are propagated)
- Validation (where it happens and what enforces it)
- Configuration and secrets (entry points, key env/config names)

#### 2G. Configuration and feature control

- Config files and config entry points
- Environment variables / config keys used by the component
- Feature flags (where declared, how evaluated)

#### 2H. Observability and operability

- Logging: where it is configured and how correlation is handled (if present)
- Metrics: what is emitted and where
- Tracing: instrumentation and propagation (if present)
- Health checks / readiness / liveness endpoints (if present)
- Retry/backoff/idempotency patterns (if present)

#### 2I. Evolution and extension patterns (only if evidenced)

- Variation points (interfaces, plugins, strategy objects, hook systems)
- How to add a new handler/route/integration safely (where to register)
- Configuration-driven behaviour (what can be changed without code)
- Backwards-compatibility constraints (API versions, event schema evolution), if present

#### 2J. Evidence (mandatory)

- Evidence bullets with:
  - File paths (URLs must be prefixed with `/` so links resolve correctly)
  - Symbols and/or config keys
- If a field cannot be supported by code/config, record:
  - **Unknown from code - {action to confirm}**

### 3) Keep unknowns visible (no guessing)

1. If the component is referenced in docs but not found in code, record:
   - **Unknown from code - verify existence / locate entry point**
2. If a dependency is implied but not evidenced, record:
   - **Unknown from code - locate client initialisation / env var / IaC resource**

### 4) Write concisely, then iterate

1. Write a first draft for all components.
2. Then do a second pass:
   - Improve evidence links
   - Replace vague terms with precise names (symbols/routes/topics/config keys)
   - Reduce duplication across components (move shared info into a shared section or link)

### 5) Update the index

Update `docs/prompt-reports/README.md` with a **Component Catalogue** section linking to every component document (in `[XXX]` order).

## Template snippet per component

```markdown
# Component {name}

{one-paragraph summary}

## Type and boundaries

- Type: {service/app/worker/CLI/library/module}
- Location: {/path}, {/path}
- Role: {edge/API|orchestration|domain core|integration adapter|persistence|shared platform}
- Boundaries: {what it owns vs depends on}

## Purpose

...

## Responsibilities

- ...
- ...

## Key modules and symbols

- {/path/to/module} – {symbol}
- ...

## Interfaces

### Inbound

- HTTP: {METHOD} {ROUTE} – evidence link
- Events: {topic/queue} (consumer) – evidence link
- Scheduled: {schedule} – evidence link
- CLI: {command} – evidence link

### Outbound

- HTTP/gRPC: {service} – evidence link
- Events: {topic/queue} (publisher) – evidence link
- External services: {service} – evidence link

## Data

- Stores: {db/cache/object store}
- Owned entities: {entity/table/collection}
- Key write paths: evidence links
- Key read paths: evidence links

## Cross-cutting concerns (component-specific)

- Auth: evidence link
- Errors/retries: evidence link
- Logging/correlation: evidence link
- Validation: evidence link
- Config/secrets: evidence link

## Configuration and feature control

...

## Observability and operability

...

## Evolution and extension (only if evidenced)

...

## Evidence

- Evidence: [path/to/file](/path/to/file#L20-L58) - {symbol or config key}
- Evidence: Unknown from code - {suggested action}
```
