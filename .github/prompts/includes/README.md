# Prompt Includes 🧩

Shared prompt fragments referenced by `.github/prompts/*.prompt.md` via plain Markdown relative links, mirroring the [instructions/includes/](../../instructions/includes/) convention.

## When to use this directory

Use an include only when **both** conditions hold:

1. The fragment is **substantive** (more than a single sentence of plumbing).
2. The fragment is **duplicated verbatim across 4+ prompts** with no per-prompt variation.

If a fragment can be expressed as a one-line instruction, or is already encapsulated by a **skill** that the prompt delegates to, do **not** extract it. The skill mechanism is this repository's primary DRY abstraction for prompts.

## Conventions

- Filename: `<topic>.include.md` (no leading underscore; matches [instructions/includes/](../../instructions/includes/)).
- Reference syntax: plain Markdown relative link, e.g. `See [quality-gates.include.md](includes/quality-gates.include.md) for the standard procedure.`
- Do **not** use `#file:` syntax - the repo standard is plain links.
- Frontmatter: mirror the shape used in [instructions/includes/quality-gates-baseline.include.md](../../instructions/includes/quality-gates-baseline.include.md).
- Identifier scheme: every normative rule carries a unique tag (e.g. `[PROMPT-INC-<topic>-NNN]`).
- Keep each include under ~60 lines; split if it grows larger.

## Current state

This directory is intentionally **empty of fragments** today. As of v2.0.0:

- All `enforce.*.prompt.md` files (12) are thin delegates to the [enforcement-audit](../../skills/enforcement-audit/SKILL.md) skill.
- All `review.speckit-*.prompt.md` files (3) are thin delegates to the [code-review](../../skills/code-review/SKILL.md) skill.
- Substantive shared content lives inside those skills, not in the prompts.

The directory exists as a **scaffold** so future long-form prompts can adopt the include pattern without bespoke setup. When you add the first include file here, also update [.github/prompts/README.md](../README.md) to surface this subdirectory.
