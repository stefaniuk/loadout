# Example 01 - Bootstrap architecture documentation for a new service

## Scenario metadata

- **Skill**: architecture-docs
- **Scenario**: First-time architecture documentation pass on a small Python/FastAPI service with a Postgres dependency and Terraform infrastructure.
- **Repository context**: A repository previously scaffolded by the `fastapi-project` skill, with Terraform under `infra/aws/` and no existing `.copilot/analysis/` content.
- **User goal**: Produce the full set of architecture artefacts from repository map through to the cloud infrastructure diagram in a single pass.
- **Invocation**: `Run the architecture-docs skill with step all`

## User prompt

> Please run the architecture-docs skill end to end (step `all`) and generate every artefact the pipeline supports for this repository.

## Argument and intent resolution

- `$ARGUMENTS` resolves to `all`, so the skill runs steps 01 → 06 sequentially.
- No prior outputs exist under `.copilot/analysis/`, therefore dependency checks succeed by virtue of being satisfied within the same run.
- LikeC4 companion instructions are loaded ahead of step 05.

## Context gathering

- Read `architecture-baseline.include.md` and `likec4.instructions.md` (loaded once, reused).
- Ran `git ls-files` to enumerate ~180 tracked files; `scc` summarised lines of code per language.
- Inspected `pyproject.toml`, `src/app/main.py`, `src/app/api/v1/routes/`, and `infra/aws/*.tf` for component and resource signals.
- Confirmed the absence of `.copilot/analysis/README.md` so a fresh index will be created.

## Execution

1. **Step 01 - Repository Map**: classified directories (`src/app/`, `tests/`, `infra/aws/`, `scripts/`), detected a single-project layout, and captured tooling provenance from `pyproject.toml` and `Makefile`.
2. **Step 02 - Component Catalogue**: identified three components - `app-api` (FastAPI service), `app-worker` (Arq background worker), and `infra-aws` (Terraform stack) - and authored one file per component.
3. **Step 03 - Runtime Flows**: documented the inbound request flow for `POST /v1/orders`, the worker job lifecycle, and the readiness probe with Mermaid `sequenceDiagram` and `flowchart LR` diagrams.
4. **Step 04 - Domain Analysis**: extracted ubiquitous terms (`Order`, `Customer`, `Payment`), drafted bounded contexts, and produced a context map showing the single context plus its outbound integrations.
5. **Step 05 - C4 Model**: wrote LikeC4 DSL files for context, container, and component levels, including styling and a deployment view tied to the AWS environment.
6. **Step 06 - Infrastructure Diagram**: parsed Terraform under `infra/aws/`, classified resources by tier (compute, data, network), exported `.drawio` source plus `.drawio.svg`, and wrote an evidence README.

## Output artefacts

- `.copilot/analysis/repository-map.md` - classified directory inventory with evidence links.
- `.copilot/analysis/component-app-api.md`, `component-app-worker.md`, `component-infra-aws.md` - per-component catalogue entries.
- `.copilot/analysis/runtime-flow-create-order.md`, `runtime-flow-worker-job.md`, `runtime-flow-readiness.md` - runtime flow narratives with diagrams.
- `.copilot/analysis/domain-ubiquitous-language.md`, `domain-aggregates.md`, `domain-context-map.md` - domain analysis set.
- `.copilot/analysis/likec4/model.c4`, `containers.c4`, `views.c4`, `styles.c4` - LikeC4 DSL files covering context, container, and component views.
- `.copilot/analysis/infrastructure/infra-aws.drawio`, `infra-aws.drawio.svg`, `README.md` - infrastructure diagram and evidence trail.
- `.copilot/analysis/README.md` - refreshed index linking every artefact above.

## Validation evidence

- Spot-checked every evidence link (`path#Lx-Ly`) by reading the cited line ranges; all resolved.
- `likec4 validate .copilot/analysis/likec4` returned zero errors for the new DSL workspace.
- `make lint` passed (markdownlint and link checker covered the new Markdown files).
- No `Unknown from code` items remained except one explicitly recorded follow-up for the worker autoscaling policy, which was flagged for maintainers.

## Final assistant response

> Generated the full six-step architecture pack under `.copilot/analysis/`. The index `README.md` lists 14 new artefacts including three components, three runtime flows, three domain documents, a LikeC4 workspace, and the AWS infrastructure diagram. One follow-up was recorded: confirm the worker autoscaling policy with the platform team - see `component-app-worker.md`.

## Notes and follow-ups

- Re-run individual steps (e.g. `runtime-flows`) whenever the corresponding source areas change rather than running `all` each time.
- The LikeC4 DSL assumes a single deployment environment; extend `model.c4`, `containers.c4`, and `views.c4` when staging or DR environments are introduced.
- `infra-aws.drawio.svg` should be committed alongside the source `.drawio` to keep diffs reviewable.
