# Contributing to Prompt Files

Thank you for your interest in contributing to this prompt library! This guide will help you understand how to add, improve, or extend prompts, instructions, agents, and skills.

---

## 📋 Table of Contents

- [Contributing to Prompt Files](#contributing-to-prompt-files)
  - [📋 Table of Contents](#-table-of-contents)
  - [🤝 Code of Conduct](#-code-of-conduct)
  - [💡 Ways to Contribute](#-ways-to-contribute)
  - [🧭 Quickstart Chooser](#-quickstart-chooser)
  - [🚀 Getting Started](#-getting-started)
    - [Prerequisites](#prerequisites)
    - [Setup](#setup)
    - [Repository Structure](#repository-structure)
  - [📦 Artefact Types](#-artefact-types)
    - [Prompts (`.github/prompts/*.prompt.md`)](#prompts-githubpromptspromptmd)
    - [Instructions (`.github/instructions/*.instructions.md`)](#instructions-githubinstructionsinstructionsmd)
    - [Agents (`.github/agents/*.md`)](#agents-githubagentsmd)
    - [Skills (`.github/skills/<skill-name>/`)](#skills-githubskillsskill-name)
  - [🚀 Quickstart Templates](#-quickstart-templates)
    - [📋 Instructions Quickstart](#-instructions-quickstart)
    - [✨ Prompts Quickstart](#-prompts-quickstart)
    - [🤖 Agents Quickstart](#-agents-quickstart)
    - [🧠 Skills Quickstart](#-skills-quickstart)
    - [🪝 Hooks Quickstart](#-hooks-quickstart)
  - [⚖️ Instruction Precedence Quick Reference](#️-instruction-precedence-quick-reference)
  - [✍️ Writing Guidelines](#️-writing-guidelines)
    - [For Prompts](#for-prompts)
    - [For Instructions](#for-instructions)
    - [Identifier Format](#identifier-format)
    - [For Agents](#for-agents)
  - [✅ Quality Standards](#-quality-standards)
    - [Before Submitting](#before-submitting)
    - [Content Checklist](#content-checklist)
    - [Identifier Requirements](#identifier-requirements)
  - [🔄 Pull Request Process](#-pull-request-process)
    - [1. Create an Issue (Optional but Recommended)](#1-create-an-issue-optional-but-recommended)
    - [2. Branch Naming](#2-branch-naming)
    - [3. Commit Messages](#3-commit-messages)
    - [4. PR Description](#4-pr-description)
    - [5. Review Process](#5-review-process)
  - [🎨 Style Guide](#-style-guide)
    - [Markdown](#markdown)
    - [Code Examples](#code-examples)
    - [Tables](#tables)
    - [Lists](#lists)
  - [🙋 Questions?](#-questions)

---

<a id="code-of-conduct"></a>

## 🤝 Code of Conduct

- Be respectful and constructive in all interactions
- Focus on the work, not the person
- Welcome newcomers and help them get started
- Share knowledge openly

---

<a id="ways-to-contribute"></a>

## 💡 Ways to Contribute

| Contribution Type    | Description                                          |
| -------------------- | ---------------------------------------------------- |
| 🐛 **Bug fixes**     | Fix errors in existing prompts or instructions       |
| ✨ **New prompts**   | Add prompts for new workflows or tools               |
| 📋 **Instructions**  | Create coding standards for new languages/frameworks |
| 🤖 **Agents**        | Build new Copilot agents for specific tasks          |
| 🧠 **Skills**        | Package complex capabilities with supporting assets  |
| 📖 **Documentation** | Improve README, examples, or inline comments         |
| 🧪 **Testing**       | Validate prompts work as expected                    |

---

<a id="quickstart-chooser"></a>

## 🧭 Quickstart Chooser

Not sure which artefact to create? Use this **"I want to do X → use Y"** table to jump straight to the right quickstart block.

| 🎯 I want to…                                                  | 📦 Use this artefact | 🚀 Jump to                                          |
| -------------------------------------------------------------- | -------------------- | --------------------------------------------------- |
| Enforce coding standards for a language or framework           | **Instructions**     | [Instructions Quickstart](#quickstart-instructions) |
| Capture a repeatable one-shot workflow (review, refactor, doc) | **Prompt**           | [Prompts Quickstart](#quickstart-prompts)           |
| Drive a multi-step Spec Kit / Copilot workflow                 | **Agent**            | [Agents Quickstart](#quickstart-agents)             |
| Package a complex capability with templates, examples, assets  | **Skill**            | [Skills Quickstart](#quickstart-skills)             |
| Automate per-edit feedback (lint after edit, block on stop)    | **Hook**             | [Hooks Quickstart](#quickstart-hooks)               |
| Document an architectural or technology decision               | **ADR**              | See [docs/adr/](../docs/adr/)                       |

For a deeper decision matrix (when to pick a Skill over a Prompt, etc.), see [docs/architecture.md](../docs/architecture.md).

---

<a id="getting-started"></a>

## 🚀 Getting Started

### Prerequisites

- Git
- Make (for running quality gates)
- A text editor (VS Code recommended for Copilot integration)

### Setup

```bash
# Clone the repository
git clone https://github.com/stefaniuk/loadout.git
cd loadout

# Verify quality gates work
make lint && make test
```

### Repository Structure

```text
.github/
├── agents/           # Copilot agent definitions
├── instructions/     # Coding standards by language/framework
│   ├── includes/     # Shared instruction fragments
│   └── templates/    # Instruction templates
├── prompts/          # Task-specific prompts
├── skills/           # Bundled capabilities with assets
└── copilot-instructions.md  # Global Copilot instructions

.specify/
├── memory/           # Project constitution and context
└── templates/        # Spec, plan, and task templates

docs/
└── adr/              # Architecture decision records
```

---

<a id="artefact-types"></a>

## 📦 Artefact Types

### Prompts (`.github/prompts/*.prompt.md`)

Single-purpose prompt files that guide Copilot through specific tasks.

**When to create a prompt:**

- Repeatable workflow (code review, documentation, refactoring)
- Task requiring specific structure or format
- Process with defined steps or checklist

**File naming:** `<prefix>.<category-or-action>.prompt.md` (prefix + category + verb)

Examples: `architecture.01-repository-map.prompt.md`, `review.speckit-code.prompt.md`, `util.gh-pr.prompt.md`, `enforce.python.prompt.md`

### Instructions (`.github/instructions/*.instructions.md`)

Coding standards and best practices scoped to specific file types.

**When to create instructions:**

- New programming language support
- Framework-specific conventions (React, Django, Terraform)
- Tool-specific rules (Docker, Makefile)

**File naming:** `<technology>.instructions.md`

Examples: `python.instructions.md`, `terraform.instructions.md`

**Required frontmatter:**

```yaml
---
applyTo: "**/*.py" # Glob pattern for file matching
---
```

### Agents (`.github/agents/*.md`)

Copilot agent definitions that combine prompts with specific behaviours.

**When to create an agent:**

- Complex multi-step workflow
- Specialised domain expertise
- Workflow requiring specific agent configuration

**File naming:** `<slug>.agent.md` or `<namespace>.<action>.agent.md`

Examples: `docs-review.agent.md`, `workflow.release-check.agent.md`

### Skills (`.github/skills/<skill-name>/`)

Bundled capabilities with supporting assets (templates, examples, data).

**When to create a skill:**

- Capability requiring supporting files
- Complex domain needing examples or templates
- Workflow with reusable assets

**Structure:**

```text
.github/skills/<skill-name>/
├── SKILL.md           # Main skill definition
├── templates/         # Supporting templates
└── examples/          # Usage examples
```

---

<a id="quickstart-templates"></a>

## 🚀 Quickstart Templates

Copy-paste starters for each artefact type. Each block follows the same shape: **when to choose · minimal template · required fields · pre-PR checklist · typical review failures**.

> **Frontmatter authority:** the canonical frontmatter schema for every artefact type lives in [docs/conventions.md](../docs/conventions.md#frontmatter-schema-by-artefact-type). The templates below are the smallest valid shape; consult conventions for the full field reference.

<a id="quickstart-instructions"></a>

### 📋 Instructions Quickstart

**When to choose this artefact.** You need language/framework/tool rules that VS Code auto-applies to matching files (e.g. all `**/*.py`). Rules must be order-independent and additive. See the [artefact decision matrix](../docs/architecture.md) for borderline cases.

**Minimal starter template** - save as `.github/instructions/<technology>.instructions.md`:

````markdown
---
applyTo: "**/*.<ext>"
description: "<Technology> Engineering Instructions (one-line summary)"
---

# <Technology> Engineering Instructions 🛠️

These instructions define the default engineering approach for <scope>. They are **non-negotiable** unless an exception is documented in an ADR.

## Quick Reference

| ID          | Rule                       |
| ----------- | -------------------------- |
| [XX-QR-001] | <One-line, testable rule.> |

## Quality

### [XX-QUAL-001] <Rule title>

<Rationale and normative statement.>

## Security

### [XX-SEC-001] <Rule title>

<Rationale and normative statement.>
```
````

**Required fields and naming constraints.** `applyTo` glob; `description` ≤ 120 chars; filename `<technology>.instructions.md`; every normative rule tagged `[XX-YYY-NNN]`. Full schema: [docs/conventions.md](../docs/conventions.md#frontmatter-schema-by-artefact-type).

**Pre-PR validation checklist.**

- [ ] `applyTo` glob is **as tight as possible** (no `**/*` unless truly global)
- [ ] Every rule has a unique `[XX-YYY-NNN]` identifier and appears in the Quick Reference table
- [ ] No contradictions with other instruction files whose `applyTo` overlaps yours
- [ ] `make lint && make test` pass with zero warnings
- [ ] Cross-linked from `.github/instructions/README.md` if it's a new technology

**Typical review failures.**

- Overly broad `applyTo` causing rules to bleed into unrelated files
- Imperative "do X before Y" phrasing that breaks when rules load in a different order
- Duplicate or missing identifiers, or identifiers not surfaced in the Quick Reference

<a id="quickstart-prompts"></a>

### ✨ Prompts Quickstart

**When to choose this artefact.** You have a **single repeatable task** (review, generate, refactor, audit) invoked on demand via `/<prompt-name>`. If it needs templates, multi-file assets, or branching logic, prefer a Skill instead. See [docs/architecture.md](../docs/architecture.md).

**Minimal starter template** - save as `.github/prompts/<prefix>.<action>.prompt.md`:

````markdown
---
agent: agent
argument-hint: "Optional: extra context or target paths"
description: <One-line summary of what this prompt does.>
---

# <Prompt Title>

<1–2 sentence context: what this prompt does and when to use it.>

## Inputs

```text
$ARGUMENTS
```

## Steps

1. <First action - be specific.>
2. <Second action.>
3. <Validation / output.>

## Success Criteria

- <What "done" looks like.>

```

```
````

**Required fields and naming constraints.** `description` (required, ≤ 120 chars); `agent` and `argument-hint` optional; filename `<prefix>.<category-or-action>.prompt.md` (e.g. `enforce.python.prompt.md`, `review.speckit-code.prompt.md`). Full schema: [docs/conventions.md](../docs/conventions.md#frontmatter-schema-by-artefact-type).

**Pre-PR validation checklist.**

- [ ] Frontmatter parses (try `/<prompt-name>` in VS Code Copilot Chat)
- [ ] Prompt produces deterministic, reviewable output
- [ ] Linked from `.github/prompts/README.md` under the right category
- [ ] `make lint && make test` pass
- [ ] No secrets, tokens, or absolute user paths in the prompt body

**Typical review failures.**

- Prompt drifts into instruction-territory (rules that should live in `.github/instructions/`)
- Vague "improve this code" steps without success criteria
- Missing `description` - prompt is then invisible in the Copilot picker

<a id="quickstart-agents"></a>

### 🤖 Agents Quickstart

**When to choose this artefact.** You're building a **multi-step workflow with handoffs** between custom agents. For Spec Kit lifecycle stages, prefer the `speckit-*` skills. For one-shot work, a Prompt is enough. See [docs/architecture.md](../docs/architecture.md).

**Minimal starter template** - save as `.github/agents/<namespace>.<action>.agent.md`:

````markdown
---
description: <One-line summary of what the agent does.>
argument-hint: "Optional: additional context"
tools: [search, read_file, list_dir, semantic_search, grep_search, file_search]
handoffs:
  - label: <Next step label>
    agent: <namespace.next-agent>
    prompt: <Seed prompt for the next agent.>
---

# <Agent Title>

## Role

<What this agent is responsible for. Single responsibility.>

## Scope

- **Will:** <bounded list of actions>
- **Will not:** <explicit non-goals>

## Steps

1. <First action.>
2. <Second action.>

## Outputs

- <Concrete artefact(s) produced.>

```

```
````

**Required fields and naming constraints.** `description` (required); `tools` array scoped to the **minimum** needed; `handoffs` if the agent participates in a chain; filename `<slug>.agent.md` or `<namespace>.<action>.agent.md` (for example `docs-review.agent.md`). Full schema: [docs/conventions.md](../docs/conventions.md#frontmatter-schema-by-artefact-type).

**Pre-PR validation checklist.**

- [ ] Agent has a single, named responsibility
- [ ] `tools` list is minimal - no `[*]` or unused tools
- [ ] All `handoffs.agent` targets exist in `.github/agents/`
- [ ] Listed in `.github/agents/README.md`
- [ ] `make lint && make test` pass

**Typical review failures.**

- Overlapping responsibility with an existing agent (should extend, not duplicate)
- Broad `tools` grant that violates least-privilege
- Handoffs that point to non-existent agents (causes silent dead-ends)

<a id="quickstart-skills"></a>

### 🧠 Skills Quickstart

**When to choose this artefact.** You're packaging a **capability + supporting assets** (templates, examples, datasets, scripts) that an agent or prompt can invoke. If you only need text guidance, a Prompt is lighter. See [docs/architecture.md](../docs/architecture.md).

**Minimal starter structure** - create `.github/skills/<skill-name>/`:

```text
.github/skills/<skill-name>/
├── SKILL.md           # Required - the skill definition
├── templates/         # Optional - copy-pasteable templates
└── examples/          # Optional - worked examples
```

**Minimal `SKILL.md` template:**

````markdown
---
name: <skill-name>
description: <One-line summary of what the skill does and when to use it.>
argument-hint: "<What the caller should pass in>"
license: MIT
version: 1.0.0
allowed-tools: []
---

# <Skill Title>

## When to Use

<Trigger conditions - how an agent decides to invoke this skill.>

## Inputs

<What `$ARGUMENTS` should contain.>

## Steps

1. <First action.>
2. <Second action.>

## Outputs

- <Concrete artefact(s).>

## Assets

- `templates/<file>` - <purpose>
- `examples/<file>` - <purpose>

```

```
````

**Required fields and naming constraints.** `name` must match the directory name; `description` (required, must explain _when_ to invoke); `version` follows semver; `allowed-tools` scoped to minimum. Full schema: [docs/conventions.md](../docs/conventions.md#frontmatter-schema-by-artefact-type).

**Pre-PR validation checklist.**

- [ ] `SKILL.md` `name` matches the directory name
- [ ] `description` makes the **invocation trigger** obvious to an agent
- [ ] All referenced `templates/` and `examples/` files exist
- [ ] Listed in `.github/skills/README.md`
- [ ] `make lint && make test` pass

**Typical review failures.**

- Vague `description` so agents never discover the skill
- Missing or broken relative links to template/example assets
- Skill duplicates a Prompt that would do the job with less ceremony

<a id="quickstart-hooks"></a>

### 🪝 Hooks Quickstart

**When to choose this artefact.** You need to **automate the inner feedback loop** - run a script on `SessionStart`, after every edit (`PostToolUse`), or block the agent from finishing (`Stop`). See [docs/architecture.md](../docs/architecture.md) and the existing [`hooks.json`](../hooks.json).

**Minimal starter template** - add to the root [`hooks.json`](../hooks.json):

```jsonc
{
  "hooks": {
    "PostToolUse": [
      {
        "type": "command",
        "command": "./scripts/hooks/<your-script>.sh",
        "timeout": 60000,
      },
    ],
  },
}
```

And the script - save as `scripts/hooks/<your-script>.sh`, `chmod +x`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Receives hook payload on stdin (JSON). Exit 0 = pass; non-zero = fail/block.
# Keep fast: PostToolUse runs after EVERY edit.
make lint
```

**Required fields and naming constraints.** Supported events: `SessionStart`, `UserPromptSubmit`, `PostToolUse`, `Stop`. Each entry needs `type: "command"`, a `command` path, and a `timeout` (ms). Scripts must be POSIX-portable and idempotent.

**Pre-PR validation checklist.**

- [ ] Script is executable (`chmod +x`) and shellcheck-clean
- [ ] Timeout is realistic (PostToolUse < 60 s; Stop < 30 s)
- [ ] Script is **idempotent** and safe to run on every edit
- [ ] No network calls or long-running work in `PostToolUse`
- [ ] `make lint && make test` pass

**Typical review failures.**

- Slow `PostToolUse` hook that throttles the whole agent session
- Non-idempotent side effects (e.g. appending to a file every edit)
- Hard-coded absolute paths instead of repo-relative ones

---

<a id="instruction-precedence"></a>

## ⚖️ Instruction Precedence Quick Reference

VS Code Copilot merges every instruction file whose `applyTo` glob matches the current file. The full precedence rules live in [docs/conventions.md](../docs/conventions.md#instruction-precedence-and-merge-semantics). Practical rules of thumb:

- **Write order-independent rules.** Never assume file A loads before file B - both apply simultaneously.
- **Scope `applyTo` tightly.** A narrow glob (`src/api/**/*.py`) wins fewer conflicts than `**/*.py`.
- **Avoid contradictions across files.** If two files target the same path, their rules must be additive. Resolve conflicts by merging or splitting `applyTo`.
- **Verify the loaded set in VS Code.** Open a target file → run _Developer: Show Language Server Output_ or check the Copilot diagnostics panel to confirm which instruction files were actually applied.
- **Global rules go in `.github/copilot-instructions.md`.** Per-language rules go in `.github/instructions/*.instructions.md`.

---

<a id="writing-guidelines"></a>

## ✍️ Writing Guidelines

### For Prompts

1. **Start with context** - explain what the prompt does and when to use it
2. **Be specific** - vague instructions produce vague results
3. **Include examples** - show expected inputs and outputs
4. **Define success criteria** - what does "done" look like?
5. **Handle edge cases** - what should happen with invalid input?

### For Instructions

1. **Use unique identifiers** - every rule gets a tag like `[PY-QR-001]`
2. **Group logically** - organise by concern (quality, security, testing)
3. **Explain why** - rationale helps AI and humans apply rules correctly
4. **Link to constitution** - reference relevant sections
5. **Provide quick reference** - summarise critical rules at the top

### Identifier Format

```text
[<LANG>-<SECTION>-<NUMBER>]

Examples:
[PY-QR-001]   Python, Quick Reference, rule 1
[TS-SEC-003]  TypeScript, Security, rule 3
[TF-BEH-010]  Terraform, Behaviour, rule 10
```

### For Agents

1. **Single responsibility** - one agent, one job
2. **Clear activation** - explain how to invoke the agent
3. **Define scope** - what the agent will and won't do
4. **Specify outputs** - what artefacts the agent produces

---

<a id="quality-standards"></a>

## ✅ Quality Standards

### Before Submitting

All contributions must pass quality gates:

```bash
make lint && make test
```

### Content Checklist

- [ ] **British English** - colour, behaviour, organisation (not color, behavior, organization)
- [ ] **Simple language** - avoid jargon where possible
- [ ] **Consistent formatting** - follow existing patterns
- [ ] **No sensitive data** - no credentials, tokens, or personal information
- [ ] **Tested** - verify prompts produce expected results
- [ ] **Documented** - include usage examples

### Identifier Requirements

For instructions files:

- [ ] Every normative rule has a unique identifier
- [ ] Identifiers follow the `[XX-YYY-NNN]` format
- [ ] No duplicate identifiers within or across files
- [ ] Identifiers are referenced in quick reference section

---

<a id="pull-request-process"></a>

## 🔄 Pull Request Process

### 1. Create an Issue (Optional but Recommended)

For significant changes, open an issue first to discuss:

- What problem does this solve?
- What's the proposed approach?
- Are there alternatives considered?

### 2. Branch Naming

```text
<type>/<short-description>

Examples:
feat/rust-instructions
fix/python-typing-rules
docs/contributing-guide
```

### 3. Commit Messages

Follow conventional commits:

```text
<type>(<scope>): <description>

Types: feat, fix, docs, style, refactor, test, chore

Examples:
feat(instructions): add Rust coding standards
fix(prompts): correct review.speckit-code checklist
docs(readme): update quick start section
```

### 4. PR Description

Include:

- **What** - summary of changes
- **Why** - motivation and context
- **How** - implementation approach
- **Testing** - how you verified the changes work

### 5. Review Process

1. Automated checks must pass (`make lint && make test`)
2. At least one maintainer review required
3. Address feedback promptly
4. Squash commits before merge (if requested)

---

<a id="style-guide"></a>

## 🎨 Style Guide

### Markdown

- Use ATX-style headers (`#`, `##`, `###`)
- One sentence per line (for better diffs)
- Blank line before and after code blocks
- Use fenced code blocks with language hints

### Code Examples

- Use realistic, self-contained examples
- Include comments explaining non-obvious parts
- Show both correct and incorrect patterns where helpful

### Tables

```markdown
| Column A | Column B |
| -------- | -------- |
| Value 1  | Value 2  |
```

### Lists

- Use `-` for unordered lists
- Use `1.` for ordered lists (let Markdown handle numbering)
- Indent nested items with 2 spaces

---

## 🙋 Questions?

- Check existing issues and PRs for similar topics
- Open an issue for questions about contributing
- Tag maintainers if you need guidance

---

**Thank you for helping make AI-assisted development better for everyone!**
