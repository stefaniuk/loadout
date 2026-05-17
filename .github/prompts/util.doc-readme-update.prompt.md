---
description: "Create or update the top-level README.md following readme.instructions.md: canonical structure, evidence-based content, and validation checklist."
---

**Mandatory preparation:**

- Read the [README instructions](../instructions/readme.instructions.md) as the source of truth for structure and content rules.
- Reference identifiers (for example `[RD-QR-001]`, `[RD-STR-004]`) when assessing or producing content.
- Read the [constitution](../../.specify/memory/constitution.md) for non-negotiable governance rules.

## Goal 🎯

Create or update the repository's **top-level** `README.md` so it:

1. Follows the canonical section order defined in `[RD-STR-001]`.
2. Answers the core questions: purpose, benefit, problem solved, high-level approach, usage, and contribution path.
3. Relies solely on repository evidence per `[RD-GOV-002]`.
4. Passes the validation checklist `[RD-VAL-001]`–`[RD-VAL-006]` before finalising.

---

## Discovery (run before writing) 🔍

### A. Gather repository evidence

Inspect and use only information evidenced in:

- Existing `README.md` (if present)
- `.github/contributing.md`, `LICENCE.md`, `.github/SECURITY.md`, `.github/CODE_OF_CONDUCT.md`
- `docs/` (especially files in the `docs/prompt-reports` directory)
- Build/run metadata:
  - Node: `package.json`, `pnpm-lock.yaml`, `yarn.lock`
  - Python: `pyproject.toml`, `requirements.txt`, `uv.lock`
- Entry points and tooling:
  - `Makefile`
  - `scripts/`, `bin/`, `cmd/`
- CI workflows: `.github/workflows/*`

### B. Note unknowns explicitly

- If something important cannot be determined from evidence, record it as a `TODO:` placeholder per `[RD-GOV-003]`.
- Do not invent features, behaviours, or guarantees.

---

## Steps 👣

### 1) Apply non-negotiable rules

- Use British English `[RD-TON-001]`.
- Prefer relative links for all in-repo references `[RD-GOV-004]`, `[RD-LNK-002]`.
- Keep the opening concise—readers should grasp purpose, benefit, problem, and approach within 30 seconds `[RD-GOV-005]`.
- Do not duplicate lengthy docs content; link to `docs/` instead `[RD-GOV-006]`.

### 2) Produce canonical structure `[RD-STR-001]`

The final `README.md` must contain sections in this exact order:

1. `# <Project Name>` `[RD-STR-002]`
2. One-line summary immediately below the title `[RD-STR-003]`, `[RD-SEC-002]`
3. `## Why this project exists` `[RD-STR-004]` — include the following subsections: **Purpose**, **Benefit to the user**, **Problem it solves**, **How it solves it (high level)** `[RD-SEC-004]`
4. `## Quick start` `[RD-STR-005]` — prerequisites, install/setup, first run, expected output `[RD-SEC-007]`–`[RD-SEC-012]`
5. `## What it does` `[RD-STR-006]` — 3–8 features, 2–6 non-goals, platforms if evidenced `[RD-SEC-013]`–`[RD-SEC-015]`
6. `## How it solves the problem` `[RD-STR-007]` — short flow, key terms `[RD-SEC-016]`–`[RD-SEC-018]`
7. `## How to use` `[RD-STR-008]` — subsections: Configuration, Common workflows, Examples, Troubleshooting (optional) `[RD-SEC-019]`–`[RD-SEC-024]`
8. Optional sections between "How to use" and "Contributing" `[RD-STR-009]` (for example Status, Security, Support)
9. `## Contributing` `[RD-STR-010]` — link to `.github/contributing.md`, dev setup, quality commands `[RD-SEC-025]`–`[RD-SEC-028]`
10. `## Repository layout` `[RD-STR-011]` — bullet list of key directories `[RD-SEC-030]`–`[RD-SEC-032]`
11. Optional sections after Repository layout `[RD-STR-012]` (for example FAQ, Roadmap)
12. `## Licence` `[RD-STR-013]` — name and link to `LICENCE.md` `[RD-SEC-033]`–`[RD-SEC-034]`

### 3) Validate before output `[RD-VAL-001]`–`[RD-VAL-006]`

Before finalising, confirm:

- `[RD-VAL-001]` The opening section answers purpose, benefit, problem, and high-level approach.
- `[RD-VAL-002]` Quick start is runnable or marked with `TODO:` placeholders.
- `[RD-VAL-003]` Contributing links to `.github/contributing.md`.
- `[RD-VAL-004]` Licence links to `LICENCE.md`.
- `[RD-VAL-005]` Every statement is evidence-backed; no invented claims.
- `[RD-VAL-006]` British English spelling and punctuation throughout.

---

## Output requirements 📋

### A) README.md content (required)

Produce the full contents of the updated `README.md`, ready to paste.

### B) Change summary (required when updating)

If a README already existed and you updated it, include a short change summary after the README output:

- 5–10 bullets of key changes
- List any added `TODO:` items

If you created a README from scratch, include a short "Assumptions and TODOs" list instead.

### C) Output format rules

- Output only:
  1. The full `README.md` content
  2. The change summary (or assumptions/TODOs)
- Do not include commentary, analysis, or explanations outside of those outputs.

---

> **Version**: 1.0.1
> **Last Amended**: 2026-01-26
