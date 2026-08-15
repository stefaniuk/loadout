---
description: Create pull request content from the current branch changes
---

**Mandatory preparation:**

- Read the [constitution](../../.specify/memory/constitution.md) and honour its non-negotiable rules.
- Read the Pull Request template at [pull_request_template.md](../pull_request_template.md) so the generated content mirrors it exactly.
- Read the technology-specific instructions **only for languages actually touched on this branch** (look at the stat in the report; do not preload every instruction file). For example [python.instructions.md](../instructions/python.instructions.md), [shell.instructions.md](../instructions/shell.instructions.md), [makefile.instructions.md](../instructions/makefile.instructions.md).
- Review the design context under `.copilot/analysis/` only when it materially helps describe affected components.

## Goal 🎯

Craft a diff-driven pull request title and body, ready to copy/paste, that compares the current branch against `main`, summarises behaviour, lists verification evidence, and fills every section of [pull_request_template.md](../pull_request_template.md).

### Scope policy (non-negotiable) 🎯

A PR description covers **everything between `main` and `HEAD`**, including any staged or unstaged work that will land in the next commit on this branch. Evidence precedence is:

1. **Commit subjects + bodies** (`git log main..HEAD`) - primary narrative; the branch authors already wrote it.
2. **Diff overview** (`git diff --stat main...HEAD`, `--dirstat`) - structural scope and folder distribution.
3. **Top-N per-file diffs**, capped, with explicit truncation markers - for the largest or most behaviour-bearing changes.
4. **Staged / unstaged working-tree changes** - included as "pending in this branch but not yet committed" and called out separately in the description.

Never expand the full `git diff main...HEAD` into the report; it does not scale beyond a handful of commits and is rarely the cheapest evidence.

---

## Discovery (run before writing) 🔍

### A. Capture a bounded evidence report

Run the evidence script **once** from the repository root. It writes a bounded report to `.copilot/analysis/gh-pr-content-diff-YYYYMMDD-<slug>.report.txt` (where `<slug>` is `pr-<number>` when a PR is known, otherwise the sanitised branch name). Per-file diffs are capped and only the top-N largest changes are inlined.

```bash
bash scripts/quality/gh-pr-content-evidence.sh
```

To override defaults (top-N files, per-file line cap, or explicit PR reference):

```bash
PR_REF=123 TOP_N_FILES=30 PER_FILE_CAP=600 bash scripts/quality/gh-pr-content-evidence.sh
```

After the script completes, **read `$_report`** (the per-PR or per-branch, per-day file written above) as the authoritative evidence. The report is bounded by design; a single read is sufficient and you must not re-run `git diff main...HEAD` for full content.

1. Confirm branch/PR target from `git rev-parse --abbrev-ref HEAD` and `git status -sb`.
2. Use the commit log block as the primary narrative - commits are already grouped, dated, and authored. Group them into change themes for the Description.
3. Use the stat and dirstat blocks for scope and folder distribution; reference them in the Description bullets.
4. Use the top-N per-file diffs to verify what the commit subjects claim. If a file you need was not in the top-N, request only that file with `git --no-pager diff main...HEAD -- <path>`. If a per-file capture was truncated (look for `[...truncated: N more lines...]`), either rerun with `PER_FILE_CAP=<n>` or request that one file unbounded. Never re-expand the whole branch diff.
5. If both committed-vs-main _and_ working-tree pending blocks are empty, stop and report **"No diff vs main – nothing to raise."**
6. Mention any pending staged/unstaged work explicitly in the Description so reviewers know the PR is not yet final.

### B. Summarise behavioural impact

1. Enumerate the files, components, and flows touched (map component names to `.copilot/analysis/*` only when it adds value).
2. Identify change categories (bug fix, feature, refactor, documentation, tooling) and note any public interfaces affected.
3. Record configuration, schema, or dependency updates.
4. Capture open questions as **Unknown from code – {action needed}**.

### C. Quality gates & evidence

1. Do **not** rerun heavy gates by default. Check `git log` and CI artefacts for evidence that `make lint`, `make test`, or equivalents already ran in this branch's commits. Repository-level hooks may also enforce gates per-edit; if so, rely on that enforcement.
2. If no recent evidence exists and gates are needed for the PR, run them once at the end and record the exact commands, status, and any failures.
3. Note follow-up checks that must still run (for example integration tests in CI).

### D. Detect prior content and determine output file

1. Define the output file path for today, using the same `_date`/`_slug` derivation as §A:
   - `.copilot/analysis/gh-pr-content-YYYYMMDD-<slug>.report.md` (where `<slug>` is `pr-<number>` when a PR is known, otherwise the sanitised branch name). This prevents same-day runs on different PRs/branches from overwriting each other.
2. If the file already exists:
   - Read it fully.
   - Compare against the current diff to identify what has changed since the last run.
   - Overwrite the file with updated content reflecting the latest branch state.
3. If the file does not exist:
   - Create it with the generated PR content.

---

## Steps 👣

1. **Derive the pull request title**
   - Use Conventional Commit style `type(scope): summary` with lower-case type and bracketed scope (for example `feat(shell): tighten hook logging`).
   - Keep it ≤ 72 characters, action-oriented, British English.
   - Reflect the dominant change category and scope (for example `fix(ci): stabilise markdown lint`).
   - Mention breaking changes explicitly by adding `!` after the type/scope (for example `feat(api)!: ...`).
2. **Populate the Description section**
   - Open with 1-2 short paragraphs of plain prose explaining what the change does and why it matters. Write for a reviewer who has not seen the code yet. Avoid jargon and keep sentences short.
   - Follow the prose with 5-7 bullet points grounded in the diff. Each bullet should name the file or component changed and state the observable effect. Reference evidence via workspace-relative Markdown links.
   - Do not start with bullets. The prose comes first.
3. **Populate the How to test it section**
   - List every CLI command a reviewer needs to verify the change, in the order they should run. Use fenced code blocks.
   - Include setup steps (for example `git checkout`, `make install`, environment variables) so the reviewer can reproduce from a clean state.
   - If the change is not testable from the CLI (for example pure documentation), state that explicitly and describe how to verify instead (for example "open the rendered Markdown and confirm the links resolve").
   - Aim for empathy: assume the reviewer is unfamiliar with the area and make the path from checkout to confidence as short as possible.
4. **Populate the Context section**
   - Explain the problem statement, user need, or specification driver.
   - Call out linked specs/ADRs/tasks via Markdown links.
5. **Set the "Type of changes" checkboxes**
   - Choose `x` for every applicable category (Refactoring, New feature, Breaking change, Bug fix) based on the diff.
   - Leave non-applicable items unchecked (`[ ]`). Never delete a line from the template.
6. **Update the Checklist section**
   - Reflect actual work done (`[x]`) vs outstanding (`[ ]`).
   - Always reference whether tests/docs were updated, style guidelines were followed, and collaboration mode (pair/mob/vibe) occurred.
7. **Populate "Sensitive Information Declaration"**
   - Confirm (`[x]`) only if you verified no PII/PID/sensitive data exists in the changes; otherwise leave unchecked and note required remediation.
8. **Call out follow-ups**
   - If additional work is deferred, list it succinctly (for example documentation gaps, pending ADRs) under Description or Context as bullet points.
9. **Write the output file (required)**
   - Write all generated PR content to `.copilot/analysis/gh-pr-content-YYYYMMDD-<slug>.report.md` (compute `<slug>` exactly as in §A: `pr-<number>` when a PR is known, otherwise the sanitised branch name).
   - If the file exists, overwrite it with the updated content.
   - Include a **Generated** footer with the current timestamp.

---

## Output requirements 📋

- Write the generated content to `.copilot/analysis/gh-pr-content-YYYYMMDD-<slug>.report.md` (slug as derived in §A).
- Produce copy-ready raw Markdown using the structure below (include the title and every section in order).
- Replace placeholder ellipses with actual content; never leave template instructions in the final text.
- Use workspace-relative Markdown links (for example `[scripts/apply.sh](scripts/apply.sh#L10-L40)`).
- Maintain ASCII-only content unless evidence requires Unicode.

````markdown
# {pull request title}

## Description

{1-2 paragraphs of plain prose explaining the change and its purpose}

- {5-7 diff-grounded bullets naming files/components and observable effects}
- ...

## Context

{why the change is needed, linked artefacts/specs}

## How to test it

    ```bash
    {command 1 - setup}
    {command 2 - run tests or verify}
    {command 3 - check output}
    ```

{brief notes on expected output or manual verification if CLI is not applicable}

## Type of changes

- [ ] Refactoring (non-breaking change)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would change existing functionality)
- [ ] Bug fix (non-breaking change which fixes an issue)

## Checklist

- [ ] I am familiar with the contributing guidelines
- [ ] I have followed the code style of the project
- [ ] I have added tests to cover my changes
- [ ] I have updated the documentation accordingly
- [ ] This PR is a result of pair or mob programming
- [ ] This PR is a result of AI-assisted development sessions

## Sensitive Information Declaration

- [ ] I confirm that neither PII/PID nor sensitive data are included in this PR and the codebase changes.

---

> Generated: YYYY-MM-DD hh:mm:ss
````

Add additional sections (for example "Testing", "Follow-ups") **only** if the template explicitly gains them in future revisions, and keep the order consistent with the template file.
