---
name: architecture-docs
description: Generate architecture documentation for a repository, producing structured artefacts from repository maps to C4 models and infrastructure diagrams.
argument-hint: "Specify step: repository-map, component-catalogue, runtime-flows, domain-analysis, c4-model, infrastructure-diagram, or all"
license: MIT
version: 1.0.0
---

# Architecture Documentation Skill

This skill generates architecture documentation following a structured six-step pipeline. Each step builds on the outputs of previous steps. Steps can be run individually or sequentially.

## Step Resolution

Resolve the step from the user's input (`$ARGUMENTS`). Match against the table below.

| Step | Slug                     | Output path                                  | Dependencies |
| ---- | ------------------------ | -------------------------------------------- | ------------ |
| 01   | repository-map           | `docs/prompt-reports/repository-map.md`      | None         |
| 02   | component-catalogue      | `docs/prompt-reports/component-*.md`         | Step 01      |
| 03   | runtime-flows            | `docs/prompt-reports/runtime-flow-*.md`      | Steps 01–02  |
| 04   | domain-analysis          | `docs/prompt-reports/domain-*.md`            | Steps 01–03  |
| 05   | c4-model                 | `docs/prompt-reports/*.c4`                   | Steps 01–04  |
| 06   | infrastructure-diagram   | `docs/prompt-reports/cloud-infrastructure.*` | Steps 01–05  |
| all  | (all steps sequentially) | All of the above                             | None         |

If "all" is specified, run steps 01 through 06 in sequence. If a single step is specified, check that its dependency outputs exist before proceeding.

## Mandatory Preparation

Before starting any step:

1. Read the [architecture overview instructions](../../instructions/includes/architecture-baseline.include.md) and adopt the approach for gathering supporting evidence.
2. For step 05 (c4-model), also read the [LikeC4 instructions](../../instructions/likec4.instructions.md) for DSL syntax.

## Goal

Produce accurate, evidence-based architecture documentation for the repository. Each step targets a specific output artefact. Update the `docs/prompt-reports/README.md` index after each step.

## Workflow Per Step

### Discovery

For every step:

1. Read outputs from all prior steps (if they exist) to build cumulative context.
2. Run `git ls-files` and `scc` (if available) to enumerate the codebase.
3. Perform step-specific discovery as described below.

### Step-Specific Discovery and Output

Each step has a dedicated companion document with the full per-step workflow (Discovery sub-steps A/B/C, sub-steps 1–8, template snippets, evidence rules, and operating principles). Follow the companion document for the step being executed.

**Step 01 - Repository Map**: Classify directories, detect project type (monorepo vs single), read context docs. Output: single flat file documenting repository structure and conventions. See [step-01-repository-map.md](step-01-repository-map.md) for the full workflow.

**Step 02 - Component Catalogue**: Identify explicit component boundaries (package.json, go.mod, Cargo.toml) and implicit boundaries (runtime/API surface). Output: up to 12 component files documenting purpose, interfaces, and dependencies. See [step-02-component-catalogue.md](step-02-component-catalogue.md) for the full workflow, including the per-component template covering identity, interfaces, data, cross-cutting concerns, and evidence.

**Step 03 - Runtime Flows**: Map orchestration/routing points and workflow semantics. Include Mermaid sequence diagrams and `flowchart LR` data lineage diagrams. Output: up to 16 flow files documenting request paths and data flows. See [step-03-runtime-flows.md](step-03-runtime-flows.md) for the full workflow and diagram templates.

**Step 04 - Domain Analysis**: Extract domain model signals, candidate terms, and bounded context boundaries. Output: up to 5 domain analysis files covering ubiquitous language, aggregates, integration patterns, and a context map. See [step-04-domain-analysis.md](step-04-domain-analysis.md) for the full workflow.

**Step 05 - C4 Model**: Confirm diagram candidates in code, produce LikeC4 DSL files at context, container, and component levels. Output: `.c4` files following LikeC4 syntax. See [step-05-c4-model.md](step-05-c4-model.md) for the full workflow, including workspace layout, view definitions, styling guidance, and DSL skeletons.

**Step 06 - Infrastructure Diagram**: Perform Terraform/IaC recon, classify resources, map environment overlays. Output: per-cloud-provider `.drawio` source plus committed `.drawio.svg` exports, with an evidence README. See [step-06-infrastructure-diagram.md](step-06-infrastructure-diagram.md) for the full workflow, layout conventions, and required elements.

### Common Steps

After producing the output for any step:

1. Validate all evidence links resolve to real files and line ranges.
2. Use **Unknown from code - {action}** for anything that cannot be determined from the codebase.
3. Update the `docs/prompt-reports/README.md` index to include the new artefact.

## Output Requirements

- Use concrete evidence links for every claim.
- Maintain ASCII-only text unless the repository already contains Unicode.
- When information is missing, record **Unknown from code - {suggested action}** instead of guessing.
- Prefix file path links with `/` for absolute repository paths.

## Examples

- [example-01-happy-path.md](./examples/example-01-happy-path.md) - full end-to-end run of `step all` on a small FastAPI service, producing every artefact from the repository map through to the AWS infrastructure diagram.
