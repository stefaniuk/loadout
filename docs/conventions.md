# Repository Conventions

This document is the cross-cutting taxonomy and naming reference for contributors. It defines the **language-pack** convention that groups related artefacts under a single tech slug, and points to the canonical locations for naming, frontmatter, and ADR rules rather than duplicating them.

## Language packs

A **language pack** is a named, composable unit of Copilot customisation keyed by a tech slug (for example `python`, `terraform`, `reactjs`). Packs are a metadata concept: artefacts continue to live in their normal folders, but the pack vocabulary lets the catalogue, onboarding flow, and selective-install tooling reason about them together.

**Pack ID format.** `language-pack.<tech>`, kebab-case, where `<tech>` matches the instruction basename exactly (the part before `.instructions.md`).

**A language pack MUST contain:**

- one `.github/instructions/<tech>.instructions.md`
- one `.github/prompts/enforce.<tech>.prompt.md`

**A language pack MAY contain:**

- one or more related skills under `.github/skills/<name>/SKILL.md` (typically framework skills such as `django-project` for the `python` pack);
- an ADR cluster under `docs/adr/ADR-NNN[a-g]_<Tech>_*.md` covering tooling choices for the language;
- optional templates under `.github/instructions/templates/`.

### Pack classes

Every language pack belongs to one of three classes:

- **language** - general-purpose programming languages: `python`, `typescript`, `go`, `rust`.
- **tool** - non-language tooling with its own grammar and idioms: `docker`, `makefile`, `shell`, `terraform`.
- **framework** - composite or framework-specific packs that sit on top of a language: `reactjs`, `tauri`, `playwright-python`, `playwright-typescript`.

### Foundation packs (orphan policy)

An instruction file that has **no** matching enforce prompt is a **foundation pack**, not a language pack. Foundation packs provide cross-cutting authoring guidance and are exempt from the enforce-prompt pairing rule. They are listed separately in the catalogue and are not surfaced through the per-tech apply flags.

Foundation packs today: `likec4`, `readme`.

### Current packs

The table below is descriptive; the authoritative listing is generated into [catalogue.md](catalogue.md#language-packs) and [catalogue.json](../catalogue.json).

| Pack ID                               | Class     | Constituent artefacts                                                                                              |
| ------------------------------------- | --------- | ------------------------------------------------------------------------------------------------------------------ |
| `language-pack.python`                | language  | `python.instructions.md`, `enforce.python.prompt.md`, skills `django-project` + `fastapi-project`, ADR-001 cluster |
| `language-pack.typescript`            | language  | `typescript.instructions.md`, `enforce.typescript.prompt.md`, ADR-002 cluster                                      |
| `language-pack.go`                    | language  | `go.instructions.md`, `enforce.go.prompt.md`, ADR-003 cluster                                                      |
| `language-pack.rust`                  | language  | `rust.instructions.md`, `enforce.rust.prompt.md`, ADR-004 cluster                                                  |
| `language-pack.docker`                | tool      | `docker.instructions.md`, `enforce.docker.prompt.md`                                                               |
| `language-pack.makefile`              | tool      | `makefile.instructions.md`, `enforce.makefile.prompt.md`                                                           |
| `language-pack.shell`                 | tool      | `shell.instructions.md`, `enforce.shell.prompt.md`                                                                 |
| `language-pack.terraform`             | tool      | `terraform.instructions.md`, `enforce.terraform.prompt.md`                                                         |
| `language-pack.reactjs`               | framework | `reactjs.instructions.md`, `enforce.reactjs.prompt.md`                                                             |
| `language-pack.tauri`                 | framework | `tauri.instructions.md`, `enforce.tauri.prompt.md`                                                                 |
| `language-pack.playwright-python`     | framework | `playwright-python.instructions.md`, `enforce.playwright-python.prompt.md`                                         |
| `language-pack.playwright-typescript` | framework | `playwright-typescript.instructions.md`, `enforce.playwright-typescript.prompt.md`                                 |

## Naming and frontmatter

Conventions for filenames, identifier schemes, and frontmatter live in the per-folder READMEs and are not duplicated here:

- Slugs and pack IDs are kebab-case.
- Instruction packs use the `[PREFIX-NNN]` identifier scheme for normative rules.
- Frontmatter required fields differ by artefact type; consult the relevant index:
  - [.github/instructions/README.md](../.github/instructions/README.md)
  - [.github/prompts/README.md](../.github/prompts/README.md)
  - [.github/agents/README.md](../.github/agents/README.md)
  - [.github/skills/README.md](../.github/skills/README.md)
- README authoring rules live in [.github/instructions/readme.instructions.md](../.github/instructions/readme.instructions.md).

## ADR triggers

Architecture Decision Records capture significant technical choices. The complete trigger list and ADR workflow are defined in [AGENTS.md](../AGENTS.md#architectural-decisions-adrs). In short, raise an ADR when a change affects:

- architectural style or pattern;
- language, framework, or tooling selection within a language pack;
- any other decision that shapes the system beyond a single file.

Language-pack ADR clusters are numbered by language (ADR-001 python, ADR-002 typescript, ADR-003 go, ADR-004 rust) with letter suffixes for sub-topics (dependency management, linting, testing, etc.). Consult the [Tech Radar](adr/Tech_Radar.md) before introducing a new tool.

## Discovery

The canonical pack listing is regenerated on every `make catalogue` run:

- [catalogue.json](../catalogue.json) - machine-readable, with derived `packs`, `foundationPacks`, and `counts.packs` fields.
- [catalogue.md](catalogue.md) - human-readable, with **Language packs** and **Foundation packs** tables.

Selective-install flags accepted by `make apply` (for example `python=true`, `terraform=true`) correspond one-to-one with the language packs above.

## Naming and slug rules

All artefacts use **kebab-case** slugs (lowercase ASCII letters, digits, and hyphens; no underscores, no dots inside the slug, no leading or trailing hyphens). The slug is the portion of the filename before any artefact suffix such as `.instructions.md`, `.prompt.md`, `.agent.md`, or before the `/SKILL.md` segment for skills.

Per-artefact slug constraints:

| Artefact type    | Slug constraint                                                                                                    | Example                                    |
| ---------------- | ------------------------------------------------------------------------------------------------------------------ | ------------------------------------------ |
| Instruction pack | Tech slug; must match the language-pack `<tech>` exactly when the file is part of a pack                           | `python`, `playwright-typescript`          |
| Prompt           | Mandatory **prefix.** (see table below) followed by a descriptive kebab-case slug                                  | `enforce.python`, `dev.implement-logging`  |
| Agent            | Either a persona slug under `personas/` or a `speckit.<step>` slug matching the spec-kit step                      | `implementer`, `speckit.plan`              |
| Skill            | Folder name only; kebab-case noun-phrase describing the capability                                                 | `code-review`, `fastapi-project`           |
| Include fragment | `<topic>` kebab-case noun-phrase; suffix `.include.md`; no leading underscore                                      | `quality-gates-baseline.include.md`        |
| Pack ID          | `language-pack.<tech>` where `<tech>` matches the instruction slug                                                 | `language-pack.reactjs`                    |
| ADR              | `ADR-NNN[a-z]?_<Pascal_Snake>_<Title>.md`; cluster letters (`a`–`g`) are reserved for language-pack ADR sub-topics | `ADR-001a_Python_Dependency_Management.md` |

**Prompt prefixes.** Prompts must begin with one of the following registered prefixes; the prefix is part of the filename and is followed by a literal dot:

| Prefix          | Purpose                                                        |
| --------------- | -------------------------------------------------------------- |
| `enforce.`      | Repository-wide compliance audits against an instruction pack  |
| `review.`       | Review and audit prompts (typically spec-kit-aware)            |
| `speckit.`      | Spec-kit lifecycle steps (`specify`, `plan`, `tasks`, …)       |
| `dev.`          | Developer-workflow helpers (commands, logging, CLI parsing, …) |
| `architecture.` | Evidence-first architecture-documentation flows                |
| `util.`         | Operational utilities (PR content, commit messages, …)         |

Adding a new prefix requires an ADR (it shapes the catalogue surface) and a matching entry in [.github/prompts/README.md](../.github/prompts/README.md#naming-convention).

## File extension and location matrix

| Artefact             | Extension / file form                 | Canonical location                | Notes                                                             |
| -------------------- | ------------------------------------- | --------------------------------- | ----------------------------------------------------------------- |
| Instruction pack     | `<slug>.instructions.md`              | `.github/instructions/`           | Carries `applyTo` glob; auto-applied to matching files            |
| Instruction template | `*.instructions.md`                   | `.github/instructions/templates/` | Scaffolds used by automation; never auto-loaded                   |
| Instruction include  | `<topic>.include.md`                  | `.github/instructions/includes/`  | Shared baseline fragments referenced from instruction packs       |
| Prompt               | `<prefix>.<slug>.prompt.md`           | `.github/prompts/`                | Invokable as slash command `/<prefix>.<slug>`                     |
| Prompt include       | `<topic>.include.md`                  | `.github/prompts/includes/`       | Currently a reserved scaffold; see directory README before adding |
| Agent (persona)      | `<slug>.agent.md`                     | `.github/agents/personas/`        | General-purpose roles                                             |
| Agent (spec-kit)     | `speckit.<step>.agent.md`             | `.github/agents/`                 | Paired one-to-one with a `speckit.<step>.prompt.md`               |
| Skill                | `SKILL.md` (+ `assets/`, `examples/`) | `.github/skills/<slug>/`          | Folder-based; `SKILL.md` is mandatory                             |
| Hook                 | `<name>.json`                         | `.github/hooks/`                  | Lifecycle hooks (Preview); see [hooks.json](../hooks.json)        |
| ADR                  | `ADR-NNN[a-z]?_*.md`                  | `docs/adr/`                       | Cluster letters reserved for language-pack ADRs                   |
| Catalogue (machine)  | `catalogue.json`                      | repository root                   | Regenerated by `make catalogue`; never hand-edit                  |
| Catalogue (human)    | `catalogue.md`                        | `docs/`                           | Regenerated by `make catalogue`; never hand-edit                  |

## Frontmatter schema by artefact type

Frontmatter is YAML, delimited by `---` lines, and **must** be the first content in the file. Required fields below are normative; field lists are derived from the per-folder READMEs and the live artefacts.

### Instructions (`.instructions.md`)

| Field         | Required | Purpose                                                                                 |
| ------------- | -------- | --------------------------------------------------------------------------------------- |
| `description` | yes      | Short summary shown on hover in the Chat view and used by semantic matching             |
| `applyTo`     | yes¹     | Glob (relative to workspace root) controlling automatic application; `**` for repo-wide |
| `name`        | no       | Display name override; defaults to the filename                                         |

¹ Required in this repository for predictable auto-application; VS Code itself treats `applyTo` as optional.

```yaml
---
applyTo: "**/*.py"
description: "Python Engineering Instructions (CLI + API, framework-agnostic)"
---
```

### Prompts (`.prompt.md`)

| Field           | Required | Purpose                                                              |
| --------------- | -------- | -------------------------------------------------------------------- |
| `description`   | yes      | Short summary shown in the slash-command palette                     |
| `agent`         | no       | Routes the prompt to a specific agent (e.g. `agent`, `speckit.plan`) |
| `argument-hint` | no       | One-line UI hint for `$ARGUMENTS`                                    |
| `tools`         | no       | Restricts the tool surface for the invocation                        |

```yaml
---
agent: agent
argument-hint: "Optional: target paths/files to audit (defaults to whole repository)"
description: Enforce repository-wide compliance with python.instructions.md
---
```

### Agents (`.agent.md`)

| Field           | Required | Purpose                                                                   |
| --------------- | -------- | ------------------------------------------------------------------------- |
| `description`   | yes      | Persona/role summary                                                      |
| `argument-hint` | no       | One-line UI hint for `$ARGUMENTS`                                         |
| `handoffs`      | no       | List of `{ label, agent, prompt, send }` entries enabling guided handoffs |
| `tools`         | no       | Restricts the tool surface for the agent                                  |
| `model`         | no       | Pins the model for the agent                                              |

```yaml
---
description: Execute an approved plan, make the necessary code changes, and run the project's quality gates.
argument-hint: "Pass the planner's brief or a direct change request"
handoffs:
  - label: Review changes
    agent: reviewer
    prompt: Review the diff against the plan and the governance rules.
    send: true
---
```

### Skills (`SKILL.md`)

| Field           | Required | Purpose                                                 |
| --------------- | -------- | ------------------------------------------------------- |
| `name`          | yes      | Skill identifier; must match the folder name            |
| `description`   | yes      | Capability summary used by semantic matching            |
| `argument-hint` | no       | One-line UI hint for `$ARGUMENTS`                       |
| `license`       | no       | SPDX licence identifier; defaults to repository licence |
| `version`       | no       | SemVer string for the skill                             |
| `allowed-tools` | no       | Tool allow-list; empty array means inherit              |

```yaml
---
name: code-review
description: Run a structured Spec Kit review focused on code compliance, documentation quality, or test coverage, positioned within the spec-driven development pipeline.
argument-hint: "Specify review type: code, documentation, or test"
license: MIT
version: 1.0.0
allowed-tools: []
---
```

## Include-file contract

Includes are reusable Markdown fragments referenced from instruction packs (and, in future, prompts). They keep cross-cutting baselines DRY without violating the "one identifier per rule" discipline.

- **Allowed locations.** `.github/instructions/includes/` for instruction fragments and `.github/prompts/includes/` for prompt fragments. No other directory may host an include.
- **Filename.** `<topic>.include.md`, kebab-case, no leading underscore, single `.include.md` suffix. Match the topic to the dominant noun-phrase (for example `quality-gates-baseline.include.md`).
- **Reference style.** Use **plain Markdown relative links**, for example `[quality gates baseline](./includes/quality-gates-baseline.include.md)`. Do **not** use the `#file:` reference syntax; the repository standard is plain links so that `lychee` can validate them.
- **Identifier scheme.** Every normative rule in an include carries a unique tag of the form `[<DOMAIN>-BASE-<PREFIX>-NNN]` (for example `[QG-BASE-RUN-001]`). Including packs reference these identifiers; they never restate the rule body.
- **Size.** Keep each include under roughly 60 lines; split by topic if it grows.
- **No circular includes.** An include must not reference another include, and an instruction pack must not be referenced from within an include. The dependency graph is one-deep: pack → include.
- **No silent extraction.** Extract a fragment only when it is substantive **and** duplicated verbatim across 4+ artefacts; otherwise inline it. See [.github/prompts/includes/README.md](../.github/prompts/includes/README.md) for the prompt-side rationale.

## ADR trigger checklist

Raise an ADR if any answer below is **yes**. Full prose, workflow, and template requirements live in [AGENTS.md](../AGENTS.md#architectural-decisions-adrs); do not duplicate them here.

- [ ] Does the change adopt or replace an **architectural style** (event-driven, layered, microservices, monolith, …)?
- [ ] Does it adopt or replace an **architectural pattern** (event sourcing, repository pattern, composition over inheritance, …)?
- [ ] Does it select or change a **language, runtime, or framework**?
- [ ] Does it select or change a **tool within a language pack** (linter, formatter, type checker, test runner, logger, CLI parser, TUI framework, …)?
- [ ] Does it introduce a new **prompt prefix**, **artefact category**, or **pack class**?
- [ ] Does it change the **catalogue schema** or **plugin-pack boundary**?
- [ ] Does it materially alter **governance, quality gates, or TDD policy**?

For tooling choices inside a language pack, consult the [Tech Radar](adr/Tech_Radar.md) first and use the per-language ADR cluster numbering (ADR-001 python, ADR-002 typescript, ADR-003 go, ADR-004 rust).

## Instruction precedence and merge semantics

VS Code combines every applicable instruction file into the chat context. When the rules conflict, the **higher-priority source wins**:

1. **Personal instructions** - user-profile `.instructions.md` files and personal `AGENTS.md`/`CLAUDE.md` variants. Highest priority.
2. **Repository instructions** - `.github/copilot-instructions.md`, `AGENTS.md`, and every `.github/instructions/*.instructions.md` whose `applyTo` glob matches the current file.
3. **Organisation instructions** - GitHub-org-level instructions discovered via `github.copilot.chat.organizationInstructions.enabled`. Lowest priority.

Within a single tier, **no merge order is guaranteed**. VS Code states explicitly that "if you have multiple instruction files in your project, VS Code combines and adds them to the chat context, no specific order is guaranteed" ([custom-instructions docs](https://code.visualstudio.com/docs/copilot/customization/custom-instructions#_types-of-instruction-files)). Treat every set of co-applying instruction files as an **unordered bag of rules**.

Practical consequences in this repository:

- `AGENTS.md` is the canonical baseline (see its preamble). Workspace `.instructions.md` files must not contradict it; agent-specific additions live in sibling files such as `.github/copilot-instructions.md`.
- Two instruction packs whose `applyTo` globs overlap (for example `playwright-typescript.instructions.md` and `typescript.instructions.md` both match `**/*.ts`) are both loaded. Their rules **must be compatible** - if a tension exists, narrow one pack's `applyTo` or move the disputed rule into an include shared by both.
- Foundation packs (`likec4`, `readme`) are loaded purely by `applyTo` matching and have no enforce prompt to resolve conflicts; keep them strictly additive.

### Writing conflict-safe instructions

- **Be order-independent.** A rule that depends on another rule being read first is fragile. State preconditions explicitly inside the rule itself.
- **Scope tightly with `applyTo`.** Use the narrowest glob that captures the intended files. Repo-wide rules belong in `AGENTS.md` or `.github/copilot-instructions.md`, not in a `.instructions.md` with `applyTo: "**"`.
- **Avoid contradictions across packs.** Before adding a rule to a pack whose `applyTo` overlaps another, search the overlapping pack for the same topic and reconcile, or extract the shared rule into an include.
- **Single source of truth per rule.** Each normative rule carries a unique identifier (for example `[PY-LOG-003]`) and is stated in exactly one location; cross-cutting baselines live in `includes/`.
- **Use diagnostics to verify load order is irrelevant.** Run **Chat: Diagnostics** to enumerate which instruction files were applied; if a rule's behaviour changes when an unrelated pack is added, the rule is order-dependent and must be rewritten.

## Plugin packs

Independently of the per-tech _language packs_, the repository's artefacts are also split into two **plugin packs**, which describe the spec-kit boundary for selective install:

- **Core pack** - all language packs, foundation packs, persona agents, util/dev/architecture prompts, hooks, and skills (with the caveat noted below).
- **Speckit pack** (optional sub-pack) - every `speckit.*` agent, every `speckit.*` prompt, the `review.speckit-*` review prompts, and the entire `.specify/` tree (constitution, templates, scripts).

VS Code's plugin manifest does not currently support first-class sub-plugins, so [plugin.json](../plugin.json) ships **both packs together** under a single manifest. To install only one pack, use the `make apply subset=…` flag (see [onboarding.md#subset-selection](onboarding.md#subset-selection)).

**Code-review skill dependency.** The [code-review skill](../.github/skills/code-review/SKILL.md) is part of the **core** pack, but its prose assumes spec-kit-style artefacts (`spec.md`, `plan.md`, `tasks.md`). A consumer who installs the core pack without speckit can still use the skill, but the workflow language will reference files they do not have.

### Pack boundary

| Artefact                                                     | Pack                                          |
| ------------------------------------------------------------ | --------------------------------------------- |
| `.github/agents/speckit.*.agent.md`                          | speckit                                       |
| `.github/agents/**` (everything else, including `personas/`) | core                                          |
| `.github/prompts/speckit.*.prompt.md`                        | speckit                                       |
| `.github/prompts/review.speckit-*.prompt.md`                 | speckit                                       |
| `.github/prompts/**` (everything else)                       | core                                          |
| `.github/instructions/**`                                    | core                                          |
| `.github/skills/**`                                          | core (note: `code-review` references speckit) |
| `.github/hooks/**`, `hooks.json`                             | core                                          |
| `.specify/**`                                                | speckit                                       |

### Recommended profiles

| Profile                   | Command                                                                          |
| ------------------------- | -------------------------------------------------------------------------------- |
| Full install (default)    | `make apply dest=…`                                                              |
| Spec-kit only             | `make apply dest=… subset=speckit`                                               |
| Non-spec-kit core (today) | `make apply dest=… subset=agents,hooks,instructions,prompts,skills,docs,project` |

The "non-spec-kit core" profile uses chained category tokens to omit `speckit` and `specify`. A single `core` shorthand is not implemented today because it would require an inverse exclusion filter inside `copilot-copy-agents`/`copilot-copy-prompts` (the broader category tokens currently include speckit artefacts). Until that lands, use the chained-subset form above.
