---
name: system-documentation
description: Establish, synchronise, audit, and review an opinionated repository documentation system across entrypoints, architecture, reference, explanation, tutorials, how-to guides, operations, audience indexes, and governance/lifecycle artefacts.
argument-hint: "Optional: step (foundation, architecture, reference, explanation, how-to, tutorials, operations, audience-indexes, governance, all), mode (establish, sync, audit, pre-pr-review), and scope (path, feature dir, or changed files)"
license: MIT
version: 1.4.0
allowed-tools: []
---

# System Documentation Skill

This skill manages the repository documentation system as a set of canonical
artefacts instead of treating `README.md` as a catch-all file.

It keeps four layers distinct:

1. Repository entrypoints such as `README.md` and GitHub-conventional files
2. Durable current-state documentation under `docs/`
3. Long-lived architectural decisions under `docs/adr/`
4. Feature-scoped intent and history under `specs/NNN-feature-name/`

The skill is opinionated on purpose. Its job is to keep documentation precise,
placed correctly, and aligned with implemented behaviour.

## Theoretical basis

The skill combines two established frameworks with repository evidence from
mature open-source projects (Django, FastAPI, Kubernetes, Backstage):

- **Diátaxis** ([diataxis.fr](https://diataxis.fr/)) defines the four
  reader-needs modes - tutorials, how-to guides, reference, and
  explanation - and is used here as the **content-quality control**
  framework: every page must have exactly one mode.
- **Docs as Code**
  ([writethedocs.org/guide/docs-as-code](https://www.writethedocs.org/guide/docs-as-code/))
  defines the **operating model**: plain-text under version control,
  reviewed in pull requests, validated automatically, evolved alongside the
  code it documents.

Diátaxis alone does not enumerate every artefact a real software system needs.
Mature repositories also keep architecture overviews, ADRs, runbooks,
troubleshooting/FAQ, security policy, contribution guidance, release notes,
and upgrade guides as first-class documentation. This skill therefore covers
the **whole documentation system**, not only the four core modes.

## Why this exists

Documentation usually drifts in three ways:

- canonical facts get copied into the wrong file
- public-surface changes update code but not reference material
- operational, architectural, and learning content get mixed together

This skill prevents that drift by managing documentation as a dependency-
ordered system of artefacts with explicit contracts.

## Non-goals

This skill does not:

- replace the Spec Kit workflow
- replace feature history under `specs/NNN-*`
- treat `tasks.md` as a documentation source
- move GitHub-conventional files into `docs/`
- generate speculative content without implementation evidence

## Canonical layout

Governance and lifecycle files (`CHANGELOG.md`, `.github/SECURITY.md`,
`.github/contributing.md`, `.github/CODE_OF_CONDUCT.md`, and upgrade guides)
are first-class artefacts. See
[step-09-governance-lifecycle.md](step-09-governance-lifecycle.md).

```text
.
├── README.md
├── CHANGELOG.md
├── .github/
│   ├── contributing.md
│   ├── SECURITY.md
│   └── CODE_OF_CONDUCT.md
├── specs/
│   ├── NNN-feature-name/
│   └── product/
└── docs/
    ├── README.md
    ├── architecture.md
    ├── conventions.md
    ├── onboarding.md
    ├── catalogue.md
    ├── adr/
    ├── tutorials/
    ├── how-to/
    ├── reference/
    ├── explanation/
    ├── operations/
    │   ├── README.md
    │   └── runbooks/
    ├── developers/
    │   └── README.md
    ├── users/
    │   └── README.md
    ├── prompt-reports/
    └── prompts/
```

## Step resolution

Resolve the requested step from `$ARGUMENTS`.

| Step | Slug             | Primary outputs                                                                                                | Dependencies |
| ---- | ---------------- | -------------------------------------------------------------------------------------------------------------- | ------------ |
| 01   | foundation       | `README.md`, `docs/README.md`, `docs/conventions.md`, `docs/onboarding.md`, baseline docs directories          | None         |
| 02   | architecture     | `docs/architecture.md`, `docs/adr/*.md`                                                                        | Step 01      |
| 03   | reference        | `docs/reference/**`                                                                                            | Step 01      |
| 04   | explanation      | `docs/explanation/**`                                                                                          | Steps 02-03  |
| 05   | how-to           | `docs/how-to/**`                                                                                               | Steps 01,03  |
| 06   | tutorials        | `docs/tutorials/**`                                                                                            | Steps 03,05  |
| 07   | operations       | `docs/operations/README.md`, `docs/operations/runbooks/**`                                                     | Steps 01,03  |
| 08   | audience-indexes | `docs/developers/README.md`, `docs/users/README.md`                                                            | Step 01      |
| 09   | governance       | `CHANGELOG.md`, `.github/SECURITY.md`, `.github/contributing.md`, `.github/CODE_OF_CONDUCT.md`, upgrade guides | Step 01      |
| all  | (all steps)      | All applicable outputs                                                                                         | None         |

Apply the following rules in order:

1. Resolve the mode before executing the step.
2. If `all` is selected, run steps 01 -> 02 -> 03 -> 04 -> 05 -> 06 -> 07
   -> 08 -> 09 in order.
3. In `establish` and `sync`, a single selected step is blocked when any
   required dependency output is missing. Stop and instruct the user to run
   the prerequisite step first.
4. In `audit` and `pre-pr-review`, missing dependency outputs are findings.
   Continue and report them under the affected canonical target. Partial
   presence of a step's required outputs is reported per missing artefact,
   attributed to the step that owns it.
5. In `establish`, create the minimal canonical landing page or directory
   index when the model requires a location to exist but detailed content is
   not yet evidenced.
6. In `sync`, update only the smallest canonical set backed by evidence. A
   `sync` run that finds no evidenced drift legitimately produces zero edits;
   report "no changes; no drift detected" and continue to validation.

## Mode resolution

Resolve the requested mode from `$ARGUMENTS`.

| Mode            | Writes files? | Use when                                                                                     |
| --------------- | ------------- | -------------------------------------------------------------------------------------------- |
| `establish`     | Yes           | The repository needs missing structure, baseline files, or initial placement cleanup         |
| `sync`          | Yes           | Code, contracts, configuration, prompts, skills, agents, hooks, or shipped behaviour changed |
| `audit`         | No            | The user wants a documentation quality, completeness, placement, or drift assessment         |
| `pre-pr-review` | No            | The user wants documentation checked against a diff before review                            |

`audit` and `pre-pr-review` are non-destructive. They MUST NOT create, edit,
rename, or delete files. They produce findings only. When delegating either
mode to a subagent, repeat this constraint in the subagent prompt.

Compatibility aliases:

- `feature-sync` -> `sync`, with emphasis on steps 03-06
- `adr-sync` -> `sync`, with emphasis on step 02
- `surface-sync` -> `sync`, with emphasis on step 03
- `release-sync` -> `sync`, with emphasis on step 09

If the user supplies both a mode and an alias, the explicit mode wins.

## Mandatory preparation

Before starting any step:

1. Read the [constitution](../../../.specify/memory/constitution.md).
2. Read [AGENTS.md](../../../AGENTS.md) and
   [.github/copilot-instructions.md](../../copilot-instructions.md).
3. Read the current repository anchors when they exist: `README.md`,
   `docs/conventions.md`, `docs/architecture.md`, and `docs/onboarding.md`.
4. Enumerate `docs/`, `docs/adr/`, and `specs/` when present.
5. Inventory public surfaces from implementation, configuration, contracts,
   scripts, prompts, skills, agents, hooks, and tests.
6. If the request is diff-based or PR-based, inspect the changed paths first.
7. Resolve and state the step, mode, and scope before writing.
8. For repositories with non-trivial documentation systems, prefer
   delegating inventory and drift analysis to a read-only exploration
   subagent. Keep edits in the main agent.

If an expected anchor is missing, apply these fallback rules:

- In `establish`, treat the missing anchor as evidence of a missing output, not
  as a preparation failure. Read the closest existing anchors instead: root
  `README.md`, `docs/README.md`, `docs/adr/`, `specs/`, and the controlling
  implementation, configuration, contract, or test surfaces.
- In `sync`, `audit`, and `pre-pr-review`, treat missing expected anchors as
  drift and handle them through the mode-sensitive dependency rules above.
- State any missing anchors and fallback anchors used before you start
  writing.

## Operating principles

1. **Single canonical location per fact.** If two files claim the same
   canonical fact, one of them is wrong by design. Replace duplication with
   links.
2. **Code is the tiebreaker.** Prefer current code, configuration, contracts,
   and passing tests over stale documentation. When sources disagree, use
   the following promotion order:
   1. current implementation and passing tests
   2. current ADRs and `docs/architecture.md`
   3. current reference docs under `docs/reference/`
   4. `specs/product/` if present
   5. per-feature `specs/NNN-*` artefacts
   6. `plan.md` only as a narrow fallback for missing architecture context
   7. never `tasks.md`

3. **Keep documentation modes separate.** Tutorials teach, how-to guides
   solve tasks, reference docs define interfaces, explanation docs clarify
   concepts, runbooks protect operations, and audience indexes route readers.
4. **Entrypoints are human-first.** Foundation docs, especially `README.md`,
   must read as guided entrypoints for people: prose-led where context is
   needed, selective in their use of bullets, and explicit about where deeper
   canonical docs live.
5. **Feature history stays under `specs/NNN-*`.** Treat `specs/product/` as
   derived, not canonical feature history.
6. **ADR discipline stays intact.** Use ADRs only for long-lived technical
   decisions with alternatives and consequences.
7. **`docs/prompt-reports/` is evidence-only.** Do not place normative docs
   there.
8. **Generated inventories stay generated.** Regenerate `docs/catalogue.md`
   and folder indexes with `make catalogue` instead of editing them by hand.
9. **`plan.md` is narrow context only.** `tasks.md` is never a documentation
   source.

## Common document contract

For files under `docs/reference/`, `docs/explanation/`, `docs/how-to/`,
`docs/tutorials/`, and `docs/operations/`, prefer this minimal front matter
when the repository is establishing or standardising those artefacts:

```yaml
---
title: Add a new skill
doc_type: how-to
audience: contributor
status: active
code_paths: [".github/skills/", ".github/prompts/"]
spec_refs: []
adr_refs: []
---
```

Rules:

- `doc_type` must match the canonical mode of the directory.
- `audience` should be `user`, `operator`, `contributor`, or `mixed`.
- `code_paths` is expected for reference docs and runbooks when practical.
- generated files, `README.md`, and ADRs do not need this contract unless the
  repository already uses it there.
- Prefer bullet lists over Markdown tables when cell widths vary substantially
  or any cell carries a long sentence. Aligned-table lint rules (such as
  MD060) reject rows that overflow the header width, forcing cosmetic
  rewrites. Tables are appropriate only for short, uniform-width data.

## Drift classes

The skill detects and resolves or reports five classes of drift:

1. missing documentation
2. misplaced documentation
3. duplicated documentation
4. conflicting documentation
5. stale documentation

Useful change-to-doc heuristics for `sync`, `audit`, and `pre-pr-review`:

- changed CLI, API, configuration, schema, or contract code without changes
  under `docs/reference/`
- changed user or contributor workflow without changes under `docs/how-to/`
  or `docs/tutorials/`
- changed architecture-affecting modules without changes to ADRs or
  `docs/architecture.md`
- changed operational automation without changes under `docs/operations/`
- shipped user-visible change without a `CHANGELOG.md` entry
- changed supported runtime, dependency policy, or release cadence without
  updates to `.github/SECURITY.md`
- breaking change without an upgrade guide linked from `CHANGELOG.md`

## Anti-patterns to flag

Derived from cross-repository evidence in the research report:

1. README-as-everything - tutorial, explanation, reference, changelog, and
   support guide collapsed into a single file.
2. Mode mixing - a how-to that becomes an architecture essay, or a
   reference page that teaches from scratch.
3. No operational surface - deployment, debugging, or upgrade guidance
   missing for a deployed system.
4. No architecture history - significant decisions visible only in old pull
   requests or tribal memory.
5. No security policy - vulnerability reporters left to guess the channel.
6. No documentation contribution guidance - doc quality dependent on
   institutional memory.
7. Generated reference without curation - reference exists but has no
   landing page or routes.
8. Audience pages that shadow-copy canonical docs instead of routing to
   them.
9. Spec or task content (`plan.md`, `tasks.md`) leaked into durable docs.

## Validation gates

Validation for this skill is documentation-scoped. It does not include the
project test suite, type checker, or language linters; those belong to other
gates. `audit` and `pre-pr-review` runs do not need to execute validation
gates at all, and absence of gate output in those modes is not a finding.

For `establish` and `sync`, every touched file must pass the following
before the step is marked done. Rely on automation where present.

1. Markdown lint passes for the changed files.
2. Internal links resolve (no broken relative links between docs, ADRs,
   specs, and code paths).
3. Front matter, where used, declares `doc_type`, `audience`, and `status`
   consistent with the directory contract.
4. Directory placement matches `doc_type`: reference content lives under
   `docs/reference/`, runbook content under `docs/operations/runbooks/`,
   and so on.
5. Required sections for the artefact type are present (see each step's
   Standardised expectations).
6. Cross-links to `spec_refs`, `adr_refs`, and `code_paths` point to files
   that exist.
7. No canonical fact is duplicated across multiple files for the same
   surface or code path.

## Workflow per step

Each step has a dedicated companion document with detailed instructions,
artefact contracts, and a Definition of Done.

- **Step 01 - Foundation.** See [step-01-foundation.md](step-01-foundation.md).
  Establishes root and docs entrypoints, conventions, onboarding, and
  baseline directories. The deterministic scaffold and templates for the
  top-level `README.md` live in
  [readme-templates.md](readme-templates.md).
- **Step 02 - Architecture.** See
  [step-02-architecture.md](step-02-architecture.md). Maintains the current
  architecture overview and ADR linkage.
- **Step 03 - Reference.** See [step-03-reference.md](step-03-reference.md).
  Maintains code-backed reference documentation for public surfaces.
- **Step 04 - Explanation.** See
  [step-04-explanation.md](step-04-explanation.md). Maintains conceptual docs,
  trade-offs, terminology, and mental models.
- **Step 05 - How-to.** See [step-05-how-to.md](step-05-how-to.md). Maintains
  goal-oriented procedures.
- **Step 06 - Tutorials.** See [step-06-tutorials.md](step-06-tutorials.md).
  Maintains newcomer or happy-path learning journeys.
- **Step 07 - Operations.** See
  [step-07-operations.md](step-07-operations.md). Maintains operational
  overviews and runbooks.
- **Step 08 - Audience indexes.** See
  [step-08-audience-indexes.md](step-08-audience-indexes.md). Maintains
  developer and user navigation pages.
- **Step 09 - Governance and lifecycle.** See
  [step-09-governance-lifecycle.md](step-09-governance-lifecycle.md).
  Maintains `CHANGELOG.md`, `.github/SECURITY.md`, `.github/contributing.md`,
  `.github/CODE_OF_CONDUCT.md`, and upgrade guides.

## Common closing steps

After producing or updating any step output:

1. Run focused documentation-scoped validation on the changed Markdown and
   customisation files. Skip this for `audit` and `pre-pr-review` runs.
2. If prompts, skills, agents, or generated indexes changed, regenerate the
   catalogues with `make catalogue`.
3. Re-run focused validation after generation when applicable.
4. In a combined produce-and-review workflow, if the `audit` phase surfaces
   resolvable drift, re-enter the producing phase to fix it and re-run the
   validation gates. Stop after at most one corrective pass and report any
   drift that remains.
5. Report unresolved drift by class and by canonical target file.
6. In the final assistant message, state the resolved mode, step, and scope,
   or each phase if more than one phase ran, the canonical files created or
   updated, the validation run and result, and any exact gaps left open.

## Definition of Done

- The requested step outputs exist in the canonical location or their absence
  is reported precisely.
- Every updated canonical file matches its documented role.
- Public-surface changes are reflected in reference docs before learning docs.
- Architecture-sensitive changes update ADRs and current-state architecture
  docs where relevant.
- Audience indexes link to canonical docs rather than duplicating them.
- Generated inventories are regenerated when required.
- Focused validation passes on the changed files, or unrelated pre-existing
  failures are separated clearly from new issues.
