# README Templates and Executable Rules

**Owner step:** [step-01-foundation.md](step-01-foundation.md).
**Status:** normative.
**Scope:** rules and templates the skill MUST apply when producing or syncing
the top-level `README.md` and the `## How to use` section for a repository
that ships one CLI tool or a suite of CLI tools.

This document is the deterministic counterpart to step 01 for the top-level
`README.md`. Where step 01 defines the README role and the four required
subsections of `## Why this project exists` (driven by
[readme.instructions.md](../../instructions/readme.instructions.md)), this
document fixes the reader-facing flow, the section order, the content of each
section, the writing constraints, and the two inline templates the skill must
reuse without improvising.

Other repository archetypes (libraries, frameworks, applications, services
and platforms) may reuse the same section order; only the example content in
the templates is specific to CLI repositories.

Deterministic here does not mean mechanical. The skill should be predictable
about reader questions, routing, and evidence, while still producing a README
that sounds like it was written for a person rather than assembled from a
form.

## When to apply

Apply this document during step 01 whenever:

- the repository ships at least one user-facing CLI binary; or
- `make apply`, `make install`, or a packaging target produces a CLI surface
  exposed on `PATH`; or
- the user requests a README rewrite, audit, or pre-PR review and the primary
  user-facing surface is a command-line tool.

If the repository does not ship a CLI, still apply sections 1-7, 9-11, and
the line budgets; replace the CLI-specific text in `## How to use`,
`## How it solves the problem`, and the templates with the equivalent surface
(library API, HTTP API, service control plane, application UI).

## Design principles

The skill MUST honour these principles when writing the top-level `README.md`:

1. Start with purpose and user outcome, not repository history.
2. Optimise for two audiences in this order: users who want to run the tool
   now, contributors who may work on it later.
3. Make the first successful command obvious and short, and state the
   expected success signal.
4. Keep the README as an orientation document; route everything else.
5. Limit `## How to use` to the top three workflows; move the rest to
   `docs/how-to/`.
6. Move exhaustive command, flag, schema, and config reference to
   `docs/reference/`.
7. Move long, multi-step procedures to `docs/how-to/`.
8. Move newcomer learning journeys to `docs/tutorials/`.
9. Move runbooks and incident response to `docs/operations/`.
10. Keep the canonical section order defined below; do not reorder.
11. Prefer short prose that guides the reader from question to question;
    use bullets only when they improve scanning.

## Human-first writing rules

The research behind this skill showed that the strongest README files feel
guided, not taxonomic. They answer a new reader's questions in a natural
order: what this is, why it matters, how to succeed quickly, and where to go
next. The skill MUST preserve that feel.

Apply these rules when producing or syncing a top-level `README.md`:

1. Open sections with prose before lists when the reader needs context.
   A short paragraph should explain why the section matters before bullets,
   commands, or links appear.
2. Treat bullets as support, not as the main voice of the page.
   Use them for prerequisites, alternative install paths, short feature lists,
   expected results, and directory maps. Do not let whole sections collapse
   into disconnected bullet walls.
3. Preserve narrative transitions.
   The end of `## Why this project exists` should set up `## Quick start`.
   `## Quick start` should set up `## How to use`. `## How to use` should route
   to deeper docs.
4. Keep the prose concrete.
   Prefer short paragraphs that explain outcome, trade-off, or workflow over
   generic slogans, marketing language, or repeated claims.
5. Avoid headings that exist only to satisfy a template.
   The required headings from [readme.instructions.md](../../instructions/readme.instructions.md)
   must stay, but optional subsections should exist only when they help a
   reader make a decision or complete a task.
6. Use examples as teaching moments.
   Commands should be introduced, not dropped in without framing. Tell the
   reader when to run them and what success looks like.
7. Let the README sound edited.
   Repeated sentence stems, identical paragraph shapes, and back-to-back list
   blocks are signs the page has become robotic and should be revised.

## Canonical section order

The top-level `README.md` MUST present sections in exactly this order. Add
optional sections only between section 8 and section 10. Do not insert
sections before section 1.

1. `# <Project Name>` and a one-line summary.
2. Optional badge row (release, CI, licence; maximum three).
3. `## Why this project exists`, with the four required subsections from
   [readme.instructions.md](../../instructions/readme.instructions.md):
   `### Purpose`, `### Benefit to the user`, `### Problem it solves`,
   `### How it solves it (high level)`.
4. `## Quick start`.
5. `## What it does`.
6. `## How it solves the problem`.
7. `## How to use`.
8. Optional cross-cutting sections (`Docs`, `Security`, `Support`,
   `Release policy`). Add only when they solve a real navigation need.
9. `## Contributing`.
10. `## Repository layout`.
11. `## Licence`.

## Content rules by section

The skill MUST treat the guidance below as both a content-completeness check
and a writing-shape check during `establish` and `sync`, and as a finding
during `audit` and `pre-pr-review` when missing.

### Title and one-line summary

Use the H1 for the project name, then follow it immediately with one sentence
of prose stating what the tool is, who it is for, and the main user benefit.
If the primary binary name differs from the project name, include it in that
sentence rather than leaving the reader to infer it later.

### Badges (optional)

If badges are used, keep them subordinate to the opening sentence. Include at
most three, and prefer release, CI status, and licence. Omit sponsor badges,
download counters, and decorative shields that push the reader's first useful
sentence below the fold.

### `## Why this project exists`

This section should read like a calm explanation to a new reader, not a form.
Each required subsection must contain at least one short paragraph of prose.

- `### Purpose` explains what the tool exists to help a user do.
- `### Benefit to the user` names the practical gain in everyday terms.
- `### Problem it solves` describes the user's friction, not the repository's
  internal structure.
- `### How it solves it (high level)` explains the broad approach in plain
  language and should naturally set up the quick-start path that follows.

### `## Quick start`

Start this section with a short paragraph that tells the reader what they are
about to prove: that the tool installs cleanly and works on their machine.

- `### Prerequisites` captures runtime, platform, and shell assumptions.
- `### Install` gives one primary install path first, then alternatives by OS
  or package manager only when relevant; link to `docs/how-to/install.md` if
  a longer guide exists.
- `### First run` gives one or two commands the reader can run immediately,
  followed by a clearly labelled `Expected result` block stating what success
  looks like.

### `## What it does`

Open with a short paragraph that describes the overall shape of the tool in
plain language. After that, use lists sparingly for the parts readers scan.

- `### Key features` should usually be a short list of 3 to 8 capabilities,
  phrased in terms of outcomes rather than implementation detail.
- `### Non-goals` should clarify boundaries only where doing so prevents a
  likely misunderstanding.
- `### Supported environments` should appear only when the repository makes
  explicit support claims.
- `### Tool map` should appear only when the repository ships more than one
  binary; one bullet per binary is enough.

### `## How it solves the problem`

This section should explain the mental model in prose first. A short numbered
flow can follow when it genuinely clarifies the lifecycle from input to
output. Include a `Key concepts` list only when the reader needs terms defined
before moving into real workflows.

### `## How to use`

Open this section with a short paragraph telling the reader that the README
covers only the most common workflows and that deeper guidance lives in the
documentation set.

- `### Configuration` should explain the minimum setup in prose, then show the
  commands and note where configuration lives or how secrets are supplied.
- `### Common workflows` should cover only the top three user jobs. Each
  workflow needs a short sentence explaining when to use it, a copyable command
  block, a short explanation of what happens, an `Expected result` list, and a
  link to the canonical how-to under `docs/how-to/`.
- `### Examples` should route outward rather than repeat detail. Prefer links
  to `docs/reference/`, `docs/how-to/`, and `docs/tutorials/`.
- `### Troubleshooting` should appear only when at least one recurring issue
  is evidenced; otherwise omit it and let `docs/how-to/troubleshooting/` carry
  the recovery path.

### `## Contributing`

Write this as a short invitation followed by the minimal next steps. Link to
`.github/contributing.md`, summarise local setup, and include the exact
quality commands the project gates contributions on.

### `## Repository layout`

Introduce the map with one short sentence, then list only the few top-level
directories a new contributor must recognise. Do not turn this into a full
filesystem tour.

### `## Licence`

State the licence in a short sentence and link to `LICENCE.md`.

## Size and pacing guidance

Use these soft limits to keep the README compact without forcing it into a
checklist shape. Treat them as pacing guidance, not a reason to chop prose
into unnatural fragments. If a section grows materially beyond its guidance,
move detail into the correct canonical doc and leave a link behind.

- the opening screen should let a reader identify the project, understand the
  outcome, and reach the start of either `## Why this project exists` or
  `## Quick start` without scrolling past badge walls or decorative content;
- `## Why this project exists` should usually be four short paragraphs, one per
  required subsection;
- `## Quick start` should stay focused on one install path, optional
  alternatives, and one first success path;
- `## What it does` should usually be one short orienting paragraph plus a
  small amount of scannable detail;
- `## How it solves the problem` should stay conceptual and brief;
- `## How to use` should cover only the most common workflows, not the whole
  manual;
- `## Contributing`, `## Repository layout`, and `## Licence` should stay
  concise and direct.

## Anti-patterns the skill MUST flag

Detect and report these anti-patterns during `audit` and `pre-pr-review`,
and refactor them during `sync`:

- README-as-everything: tutorial, explanation, reference, changelog, or
  runbook content embedded directly in the top-level README;
- a README that reads like a filled-in template rather than a guided landing
  page;
- section after section made only of bullets, labels, or micro-headings with
  no connective prose;
- installation and usage mixed in one block with no clear first-run path;
- the README presented as a reference manual (long flag tables, exhaustive
  config keys, full schema dumps);
- support, bug reporting, and contribution blended into a single generic
  block instead of separated by purpose;
- decorative screenshots that do not shorten an explanation;
- command examples without an `Expected result` block;
- sponsor or marketing content placed above `## Quick start`;
- more than three badges, or badges that signal nothing actionable;
- benchmark sections in the README instead of a short claim plus a link to
  evidence;
- large feature comparison matrices in the README instead of in
  `docs/reference/` or a product page;
- duplicated canonical facts that also live in `docs/reference/`,
  `docs/how-to/`, `docs/architecture.md`, `CHANGELOG.md`, or
  `.github/SECURITY.md`.

## Validation checks specific to the README

In addition to the skill-wide validation gates, the skill MUST verify the
following for the top-level `README.md` in `establish` and `sync` modes:

1. The H1 is the project name and is the first heading in the file.
2. Sections 1, 3, 4, 5, 7, 9, 10, and 11 are present in canonical order.
3. `## Why this project exists` contains all four required subsections from
   [readme.instructions.md](../../instructions/readme.instructions.md).
4. Each subsection under `## Why this project exists` contains prose, not only
   bullets or placeholder fragments.
5. `## Quick start` opens with a short orienting paragraph and contains an
   `Expected result` block under `### First run` or its first runnable example.
6. `## What it does` and `## How to use` each begin with a short paragraph that
   frames the section before any list or command block.
7. `## How to use` contains a `### Configuration` subsection and a
   `### Common workflows` subsection with at most three workflows.
8. Each workflow under `### Common workflows` includes a short sentence
   explaining when to use it, a command block, a short explanation of what it
   does, and an `Expected result` list.
9. Workflows that exceed roughly 20 lines are linked out to
   `docs/how-to/<workflow>.md` instead of being inlined.
10. The README does not contain exhaustive flag tables, full schemas, ADR
    debates, runbooks, or version-by-version upgrade notes.
11. The README is not dominated by consecutive list-only sections where prose
    would better explain purpose or flow.
12. The licence section names the licence and links to `LICENCE.md`.
13. Every relative link points to a file or anchor that exists.

## Definition of Done (README-specific)

A `README.md` produced or updated under this document is done when:

- the section order matches the canonical order above;
- the content and writing-shape rules for each section pass;
- the pacing guidance is respected (or any overshoot is justified by a linked
  evidence file);
- the README-specific validation checks above pass alongside the
  skill-wide validation gates defined in [SKILL.md](SKILL.md);
- no anti-pattern in the list above is present.

## Template A - Top-level `README.md` for a CLI repository

The skill MUST treat this template as the starting scaffold when creating a
new top-level `README.md` for a CLI repository. Replace every `<placeholder>`
with evidenced content. Do not reorder sections. Remove the `Tool map`
subsection when only one binary ships. Remove `### Troubleshooting` when no
recurring issue is evidenced.

````md
# <Project Name>

A CLI tool that <primary outcome> for <primary audience>.

[![CI](ci-badge-url)](ci-url)
[![Latest release](release-url)](release-url)
[![Licence](LICENCE.md)](LICENCE.md)

## Why this project exists

### Purpose

<State in one short paragraph what the tool helps the reader do and why that
job matters.>

### Benefit to the user

<Describe the practical gain in everyday terms: what becomes faster, safer,
clearer, or easier to automate once the tool is in use.>

### Problem it solves

<Describe the user's friction, wasted effort, or repeated failure mode. Keep
the focus on the reader's problem, not the repository internals.>

### How it solves it (high level)

<Explain the broad approach in plain language and lead naturally into the quick
start that follows.>

## Quick start

If you want to confirm that the tool works on your machine, install it and run
the smallest useful command below.

### Prerequisites

You only need the following before you start:

- <runtime or platform requirement>
- <optional dependency>

### Install

Install the tool with the primary path first:

```bash
<install command>
```

If you prefer another package manager or platform-specific path:

- <package manager or OS-specific option>
- <package manager or OS-specific option>

For full install notes, see [docs/how-to/install.md](docs/how-to/install.md).

### First run

Once the tool is installed, run:

```bash
<binary> --version
<binary> <main-subcommand> <minimal-args>
```

Expected result:

- `<binary> --version` prints the installed version.
- `<binary> <main-subcommand> ...` prints or creates <expected result>.

## What it does

At a high level, <Project Name> helps the reader move from <starting state> to
<desired outcome> without having to <manual process or repeated pain>.

### Key features

- <feature one>
- <feature two>
- <feature three>

### Non-goals

- <non-goal one>
- <non-goal two>

### Supported environments

- <supported OS/runtime/backend>

### Tool map

<!-- Keep this subsection only if the repository ships more than one CLI. -->

- `<binary-a>` - <what it is for>
- `<binary-b>` - <what it is for>

## How it solves the problem

Behind the commands, the tool follows a simple flow. It takes a clear input,
applies the repository's rules or automation, and produces an output the user
can act on.

1. <The CLI reads or receives input from the user, files, APIs, or stdin.>
2. <It validates, resolves, or transforms that input.>
3. <It writes, prints, uploads, updates, or exports a result.>

Key concepts:

- `<concept-one>` - <one-line definition>
- `<concept-two>` - <one-line definition>

## How to use

The README covers the three workflows most readers need first. If you need the
full manual, use the linked how-to and reference docs.

### Configuration

Configure the tool once before running the common workflows below.

```bash
export <ENV_VAR>=<value>
<binary> config set <key> <value>
<binary> auth login
```

Why these settings matter:

- `<ENV_VAR>` controls <what it controls>.
- `<config file path>` stores <what it stores>.
- Secrets should be provided via <supported method>.

### Common workflows

#### 1. <Primary workflow>

Use this workflow when <one-sentence trigger or goal>.

```bash
<binary> <subcommand> <args>
```

What happens:

- <effect one>
- <effect two>

Expected result:

- <visible output, file, or state change>

More detail:

- [docs/how-to/<workflow-one>.md](docs/how-to/<workflow-one>.md)

#### 2. <Second workflow>

Use this workflow when <one-sentence trigger or goal>.

```bash
<binary> <subcommand> <args>
```

What happens:

- <effect one>
- <effect two>

Expected result:

- <visible output, file, or state change>

More detail:

- [docs/how-to/<workflow-two>.md](docs/how-to/<workflow-two>.md)

#### 3. <Third workflow>

Use this workflow when <one-sentence trigger or goal>.

```bash
<binary> <subcommand> <args>
```

What happens:

- <effect one>
- <effect two>

Expected result:

- <visible output, file, or state change>

More detail:

- [docs/how-to/<workflow-three>.md](docs/how-to/<workflow-three>.md)

### Examples

- [docs/reference/cli.md](docs/reference/cli.md) - full command and flag reference
- [docs/how-to/README.md](docs/how-to/README.md) - task-oriented guides
- [docs/tutorials/README.md](docs/tutorials/README.md) - newcomer journeys

### Troubleshooting

- If `<common issue>` happens, run `<diagnostic command>`.
- If `<common issue>` persists, see
  [docs/how-to/troubleshooting/<issue>.md](docs/how-to/troubleshooting/<issue>.md).

## Contributing

If you want to contribute, start with the contributor guide and the local
quality gates below.

See [.github/contributing.md](.github/contributing.md) for the full process.

In short:

- install the dev environment;
- run the quality gates;
- open an issue or pull request with context.

Required checks:

```bash
make lint
make test
```

## Repository layout

These are the directories most contributors need to recognise first:

```text
.
├── src/        # CLI implementation
├── docs/       # reference, how-to, tutorials, operations
├── tests/      # automated tests
├── scripts/    # helper scripts and packaging tasks
└── <build files>
```

## Licence

This project is licensed under the <Licence Name>.
See [LICENCE.md](LICENCE.md) for details.
````

## Template B - `## How to use` for up to three main CLI use cases

Use this when the README should teach the three most common jobs a user wants
to complete. If the tool has more than three important workflows, keep the
top three here and move the rest into `docs/how-to/`.

````md
## How to use

This section should feel like a guided starting point, not a miniature manual.
Use it to cover the three workflows most readers are likely to need first, and
link out for everything deeper.

### Configuration

Set the minimum configuration once before running the workflows below.

```bash
export <ENV_VAR>=<value>
<binary> auth login
<binary> config set <key> <value>
```

Why this matters:

- sets the runtime context;
- authenticates the user or machine;
- stores the default behaviour needed by later commands.

Expected result:

- the CLI confirms authentication or saved configuration;
- later commands can run without repeating setup.

### Use case 1 - <primary user job>

Use this workflow when <explain the trigger in one sentence>.

Run:

```bash
<binary> <subcommand> <required-arg>
<binary> <subcommand> <follow-up-arg>
```

What happens:

1. `<binary> <subcommand> ...` - <effect>.
2. `<binary> <subcommand> ...` - <effect>.

Expected result:

- <visible output>
- <file created, record updated, or state changed>

Useful flags:

- `--output <format>` - <what it changes>
- `--dry-run` - <what it validates without changing state>

More detail:

- [docs/how-to/<use-case-one>.md](docs/how-to/<use-case-one>.md)

### Use case 2 - <second user job>

Use this workflow when <explain the trigger in one sentence>.

Run:

```bash
<binary> <subcommand> <required-arg>
<binary> <subcommand> <follow-up-arg>
```

What happens:

1. `<binary> <subcommand> ...` - <effect>.
2. `<binary> <subcommand> ...` - <effect>.

Expected result:

- <visible output>
- <file created, record updated, or state changed>

Useful flags:

- `--filter <expr>` - <what it narrows>
- `--format <value>` - <what it changes>

More detail:

- [docs/how-to/<use-case-two>.md](docs/how-to/<use-case-two>.md)

### Use case 3 - <third user job>

Use this workflow when <explain the trigger in one sentence>.

Run:

```bash
<binary> <subcommand> <required-arg>
<binary> <subcommand> <follow-up-arg>
```

What happens:

1. `<binary> <subcommand> ...` - <effect>.
2. `<binary> <subcommand> ...` - <effect>.

Expected result:

- <visible output>
- <file created, record updated, or state changed>

Useful flags:

- `--verbose` - <what extra detail it prints>
- `--yes` - <what confirmation it skips>

More detail:

- [docs/how-to/<use-case-three>.md](docs/how-to/<use-case-three>.md)

### Examples

- [docs/reference/cli.md](docs/reference/cli.md) - full command reference
- [docs/how-to/README.md](docs/how-to/README.md) - task-oriented guides
- [docs/tutorials/README.md](docs/tutorials/README.md) - first-run journeys

### Troubleshooting

- If `<common issue>` happens, run `<diagnostic command>`.
- If `<common issue>` persists, check
  [docs/how-to/troubleshooting/<issue>.md](docs/how-to/troubleshooting/<issue>.md).
````

## Provenance

The section order, content rules, line budgets, anti-patterns, and templates
in this document derive from a cross-category review of widely used GitHub
repositories spanning CLI tools, libraries, frameworks, applications, and
services and platforms. The review prioritised entrypoint orientation, first
successful action, evidence-backed claims, selective use of lists, and clean
separation of support, bug reporting, and contribution channels. The empirical
sample also showed that stronger README files rely on short prose to connect
sections instead of turning every idea into a heading or bullet. The sample is
summarised here only as provenance; this document is the canonical executable
form.

Reference repositories that informed the rules above include `cli/cli`,
`sharkdp/bat`, `BurntSushi/ripgrep`, `junegunn/fzf`, `sharkdp/fd`,
`jqlang/jq`, `pnpm/pnpm`, `facebook/react`, `psf/requests`,
`pandas-dev/pandas`, `numpy/numpy`, `lodash/lodash`, `pytorch/pytorch`,
`scikit-learn/scikit-learn`, `tensorflow/tensorflow`, `django/django`,
`fastapi/fastapi`, `expressjs/express`, `angular/angular`, `rails/rails`,
`vercel/next.js`, `nestjs/nest`, `microsoft/vscode`,
`signalapp/Signal-Desktop`, `AppFlowy-IO/AppFlowy`,
`obsproject/obs-studio`, `kubernetes/kubernetes`, `supabase/supabase`,
`appwrite/appwrite`, `temporalio/temporal`, `prometheus/prometheus`,
`minio/minio`, and `apache/apisix`.
