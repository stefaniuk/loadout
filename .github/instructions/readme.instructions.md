---
applyTo: "**/README.md"
description: "README Engineering Instructions"
---

# README Engineering Instructions 📘

These instructions define the required structure and content for every repository's top-level README so that users and engineers can trust it as the single onboarding entry point.

They must remain applicable to:

- Product and platform services (internal or open-source)
- Libraries, SDKs, tooling, and infrastructure repos
- Template or example projects that seed new services

They are **non-negotiable** unless an explicit ADR grants a scoped, time-bound exception.

**Identifier scheme.** Every normative rule carries a unique tag in the form `[RD-<prefix>-NNN]`, where the prefix maps to the containing section (for example `QR` for Quick Reference, `STR` for Structure, `SEC` for Section requirements). Use these identifiers when planning or validating documentation work.

---

## 0. Quick reference (apply first) 🧠

- [RD-QR-001] Follow the canonical section order defined in [RD-STR-001] so readers always know where to find information.
- [RD-QR-002] Base every statement on evidenced sources per [RD-GOV-002]; never invent behaviour or guarantees.
- [RD-QR-003] Use explicit `TODO:` placeholders whenever information is missing or unverified ([RD-GOV-003]).
- [RD-QR-004] Keep the opening section short enough for readers to understand purpose, benefit, problem, and approach within 30 seconds ([RD-GOV-005], [RD-VAL-001]).
- [RD-QR-005] Quick start content must document prerequisites, setup, first run, and expected success indicators using repository-supported commands ([RD-SEC-007]–[RD-SEC-012]).
- [RD-QR-006] Always provide a Contributing path with links, dev setup, and quality commands ([RD-SEC-025]–[RD-SEC-028]).
- [RD-QR-007] Use relative links for all in-repo references and include the standard docs/security links when they exist ([RD-LNK-001]–[RD-LNK-002]).
- [RD-QR-008] Run the validation checklist in [RD-VAL-001]–[RD-VAL-006] before finalising any README change.

---

## 1. Purpose and outcomes 🎯

- [RD-PUR-001] The README must explain the project quickly and clearly to new readers.
- [RD-PUR-002] It must state why the reader should care by emphasising tangible benefits or outcomes.
- [RD-PUR-003] It must describe the problem the project solves and outline the high-level approach.
- [RD-PUR-004] It must provide a fast, reliable path to using the project successfully.
- [RD-PUR-005] It must provide a clear path for engineers to contribute, test, and extend the project.

## 2. Audience coverage 👥

- [RD-AUD-001] Write explicitly for two audiences: users who want to run/use it now, and engineers who want to develop, test, or contribute.
- [RD-AUD-002] Make it obvious which parts of the README serve each audience (for example Quick start for users, Contributing for engineers).
- [RD-AUD-003] Even if the repository is internal-only, retain the same structure but adapt wording to "internal users" and "contributors".

## 3. Tone and style ✍️

- [RD-TON-001] Use simple language and British English spelling across the document.
- [RD-TON-002] Prefer short sentences, descriptive headings, and scannable bullet lists where they improve readability. Use prose as the primary voice of each section.
- [RD-TON-003] Avoid marketing fluff. Stay explicit, practical, and evidence-led.
- [RD-TON-004] Use "must/should" only when you describe real constraints or agreed standards.
- [RD-TON-005] Keep the tone direct and instructive, guiding readers to action rather than selling the project.

## 4. Governance and evidence rules 🧾

- [RD-GOV-001] Do not claim features, behaviours, integrations, or guarantees that are not present in the repository.
- [RD-GOV-002] Use only information evidenced in the README you are editing, source code, manifest files (`package.json`, `pyproject.toml`, etc.), `docs/`, the `Makefile`, CI configuration (`.github/workflows/*`), scripts, or configuration examples.
- [RD-GOV-003] When information is missing, insert an explicit `TODO:` placeholder rather than guessing, and make it clear what needs to be confirmed.
- [RD-GOV-004] Always use relative links for files within the repository so the README stays portable across forks and mirrors.
- [RD-GOV-005] Keep the top portion short enough that readers grasp the value proposition in under 30 seconds.
- [RD-GOV-006] Keep the README as a top-level orientation document. Move deep manuals or step-by-step guides into `docs/` and link to them.

## 5. Canonical structure 🧱

- [RD-STR-001] Follow this exact sequence of headings (names may be lightly adapted, but order and intent must stay the same):
  1. [RD-STR-002] `# <Project Name>`: the main title.
  2. [RD-STR-003] One-line summary immediately below the title.
  3. [RD-STR-004] `## Why this project exists`.
  4. [RD-STR-005] `## Quick start`.
  5. [RD-STR-006] `## What it does`.
  6. [RD-STR-007] `## How it solves the problem`.
  7. [RD-STR-008] `## How to use`.
  8. [RD-STR-009] Optional sections (only if helpful) between `How to use` and `Contributing`.
  9. [RD-STR-010] `## Contributing`.
  10. [RD-STR-011] `## Repository layout`.
  11. [RD-STR-012] Optional sections (only if helpful) after `Repository layout` (for example FAQ, Roadmap).
  12. [RD-STR-013] `## Licence`.
- [RD-STR-014] Keep the README at the repository root and preserve the canonical section order from [RD-STR-001]. Move deep manuals, step-by-step procedural guides, and lengthy reference tables into `docs/` (for example `docs/architecture.md`, `docs/onboarding.md`) and link to them from the relevant section. The README itself must remain a compact orientation document, targeting under 200 lines, so readers can scan the whole landing page in one sitting.

## 6. Section-by-section requirements 📚

### 6.1 Title and one-line summary

- [RD-SEC-001] The title must match the repository or package name. If uncertain, use the best available name and add `TODO: confirm project name`.
- [RD-SEC-002] Immediately follow the title with a one-sentence summary answering "What is this?" and "What is it for?".
- [RD-SEC-003] Use the pattern "A <tool/service/library> that <does X> for <audience>." where it improves clarity.

### 6.2 Why this project exists

- [RD-SEC-004] Write this section as unified prose that covers all four topics in a natural flow: **purpose** (what the tool helps the reader do), **benefit to the user** (the practical gain), **problem it solves** (the user's friction or failure mode), and **how it solves it** (the high-level approach). Do not split these into separate subsections. Let the narrative move naturally from one topic to the next.
- [RD-SEC-005] Ground every claim in repository evidence. The section should read like a calm explanation to a new reader and lead naturally into the quick start that follows.

### 6.3 Quick start

- [RD-SEC-007] Document minimal prerequisites (runtime versions, tooling) before instructions.
- [RD-SEC-008] Describe install or setup steps (build, compose, run) using fenced code blocks.
- [RD-SEC-009] Provide a "first run" example and state the expected outcome under a clearly labelled `Expected result` block.
- [RD-SEC-010] Use the fewest possible commands and prefer repository-provided targets or scripts.
- [RD-SEC-011] When steps are unknown, include a minimal skeleton annotated with `TODO:` markers instead of omitting the section.
- [RD-SEC-012] Prefer Makefile targets, project scripts, or documented CLI commands over raw shell instructions whenever they exist.

### 6.4 What it does

- [RD-SEC-013] List 3–8 key features that describe capabilities at a high level.
- [RD-SEC-014] Include 2–6 out-of-scope or non-goal bullets when they prevent a likely misunderstanding. Omit only when boundaries are self-evident from the feature list.
- [RD-SEC-015] Mention supported platforms or versions only when they are known and evidenced (omit otherwise).

### 6.5 How it solves the problem

- [RD-SEC-016] Provide a short flow (bullets or numbered list) showing how inputs become outputs.
- [RD-SEC-017] Introduce key concepts or terms with concise, one-line definitions only when necessary.
- [RD-SEC-018] Stay high level. Avoid detailed internals, implementation trivia, or long paragraphs.

### 6.6 How to use

- [RD-SEC-019] Break the section into clearly labelled subsections such as `Configuration`, `Common workflows`, `Examples`, and optional `Troubleshooting`.
- [RD-SEC-020] Under `Configuration`, document environment variables, config files, flags, and secret handling exactly as implemented.
- [RD-SEC-021] Under `Common workflows`, describe three to five typical usage patterns with short, copyable examples. Move additional workflows to `docs/how-to/`.
- [RD-SEC-022] Under `Examples`, link to `examples/`, `docs/`, or other evidence rather than duplicating long content.
- [RD-SEC-023] Include a `Troubleshooting` subsection only for recurring issues backed by evidence. Omit if unknown.
- [RD-SEC-024] If usage instructions are lengthy, link to a dedicated doc (for example `docs/usage.md`) and summarise why the reader should follow it.

### 6.7 Contributing

- [RD-SEC-025] Link to `.github/contributing.md`. If it does not exist, create a contributing file.
- [RD-SEC-026] Summarise development setup steps (dependencies, local run commands) at a high level.
- [RD-SEC-027] List the quality commands (linting, testing, formatting) that contributors must run.
- [RD-SEC-028] Explain how to propose changes (issues, pull requests, review expectations) without duplicating the full contributing guide.

### 6.8 Repository layout

- [RD-SEC-030] Provide a bullet list or tree-style code block of the most important directories and files that actually exist in the repo.
- [RD-SEC-031] Keep descriptions short, consistent, and action-oriented. Mark unknown paths as `TODO` instead of inventing details.
- [RD-SEC-032] Limit the list to the directories new contributors must know first.

### 6.9 Licence

- [RD-SEC-033] State the licence name exactly as defined in `LICENCE.md`.
- [RD-SEC-034] Link to the licence file using a relative link. If the file is missing, create an MIT licence file.

## 7. Standard links 🔗

- [RD-LNK-001] Include relative links to `LICENCE.md`, `./github/contributing.md`, `./github/SECURITY.md`, `./github/CODE_OF_CONDUCT.md`, and key canonical docs entry points (for example `docs/README.md`, `docs/architecture.md`, or `docs/onboarding.md`) whenever those files exist.
- [RD-LNK-002] Use relative links for every in-repo reference, ensuring they work on forks and mirrors without modification.

## 8. Badges (optional) 🎖️

- [RD-BAD-001] Only add badges that reflect real CI/build/test status, security scans, or releases.
- [RD-BAD-002] Link each badge to the live workflow, dashboard, or status page it represents.
- [RD-BAD-003] Keep the total number of badges to three or fewer.

## 9. Update and maintenance expectations 🔄

- [RD-MTN-001] When updating an existing README, preserve accurate content and only restructure to align with this standard if it materially improves clarity.
- [RD-MTN-002] Remove outdated or incorrect statements and replace them with evidence-backed information.
- [RD-MTN-003] Add any missing required sections using repository evidence before considering the README complete.
- [RD-MTN-004] Keep `TODO:` items visible and actionable until the underlying information is confirmed.

## 10. Validation checklist ✅

Before finalising the README, confirm:

- [RD-VAL-001] The opening section answers purpose, benefit, problem, and high-level approach.
- [RD-VAL-002] Quick start instructions are runnable or clearly marked with `TODO:` placeholders for unknown steps.
- [RD-VAL-003] The Contributing section links to `.github/contributing.md` (or documents the missing file as a TODO).
- [RD-VAL-004] The Licence section links to `LICENCE.md` (or records the need to add one).
- [RD-VAL-005] Every statement is evidence-backed; there are no invented facts or unsupported claims.
- [RD-VAL-006] The document consistently uses British English spelling and punctuation.
