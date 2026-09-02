---
description: Create pull request content from the current branch changes
---

**Mandatory preparation:**

- Read the [constitution](../../.specify/memory/constitution.md) and honour its non-negotiable rules.
- Read the Pull Request template at [pull_request_template.md](../pull_request_template.md). This file is the **single source of truth** for the output structure; you must reproduce it verbatim (see Output requirements) and never paraphrase or hard-code a copy of it.
- Read the technology-specific instructions **only for languages actually touched on this branch** (look at the stat in the report; do not preload every instruction file). For example [python.instructions.md](../instructions/python.instructions.md), [shell.instructions.md](../instructions/shell.instructions.md), [makefile.instructions.md](../instructions/makefile.instructions.md).
- Review the design context under `.copilot/analysis/` only when it materially helps describe affected components.

## Goal 🎯

Craft a diff-driven pull request title and body, ready to copy/paste, that compares the current branch against its **detected base branch** (not assumed to be `main`), summarises behaviour, lists verification evidence, and fills every section of [pull_request_template.md](../pull_request_template.md).

### Scope policy (non-negotiable) 🎯

The base branch is **never assumed to be `main`**. It is detected automatically (see §A) from the PR's actual base ref, or the repository's default branch, falling back to `main` only if neither can be determined. Everywhere below, "base branch" or "`<base>`" refers to this detected ref.

This section describes evidence precedence only, it does not instruct you to run anything. The single sanctioned command runs once in §A; everything named below is a description of a block already present in the resulting report.

A PR description covers **the committed changes between the base branch and `HEAD`**, plus any **staged** work when the current branch is the PR head branch. Unstaged working-tree changes are **deliberately excluded**. Evidence precedence is:

1. **Commit subjects + bodies** - primary narrative, found in the report's commit-log block; the branch authors already wrote it (ideally via [util.git-commit-message.prompt.md](util.git-commit-message.prompt.md), which structures each commit to feed these sections).
2. **Diff overview** - structural scope and folder distribution, found in the report's stat and dirstat blocks.
3. **Top-N per-file diffs**, capped, with explicit truncation markers - for the largest or most behaviour-bearing changes, found in the report's per-file diff blocks.
4. **Staged working-tree changes** - found in the report's staged-pending block, present only when the current branch is the PR head branch (the script skips them otherwise and records why). Included as "pending in this branch but not yet committed" and called out separately in the description. Unstaged changes are not captured.

Never expand the full diff between the base branch and `HEAD` into the report; it does not scale beyond a handful of commits and is rarely the cheapest evidence.

---

## Discovery (run before writing) 🔍

### A. Capture a bounded evidence report

Run the evidence script **once** from the repository root. It writes a bounded report to `.copilot/analysis/gh-pr-content-diff-YYYYMMDD-<slug>.report.txt` (where `<slug>` is `pr-<number>` when a PR is known, otherwise the sanitised branch name). Per-file diffs are capped and only the top-N largest changes are inlined.

The script detects the base branch itself: it prefers the actual PR base ref (via `gh pr view --json baseRefName`), then the repository's default branch, then `origin/HEAD`, and only falls back to `main` if none of these resolve. Override it explicitly with `BASE_REF` when needed (for example when raising a PR against a release branch).

Auto-detection only reaches the PR-base tier once a PR actually exists. Before a PR is opened (the common case while drafting locally), there is nothing for `gh pr view` to read, so detection falls straight to the repository's default branch. If you are drafting against a non-default branch (for example a release branch) before opening the PR, set `BASE_REF` explicitly rather than relying on auto-detection.

```bash
bash .github/prompts/util.gh-pr-content.sh
```

To override defaults (top-N files, per-file line cap, explicit PR reference, or explicit base branch):

```bash
PR_REF=123 TOP_N_FILES=30 PER_FILE_CAP=600 bash .github/prompts/util.gh-pr-content.sh
BASE_REF=develop bash .github/prompts/util.gh-pr-content.sh
```

After the script completes, **read `$_report`** (the per-PR or per-branch, per-day file written above) as the authoritative evidence. The report's `>>> base branch detected: <base> (source: ...)` line records which branch was used and which detection tier resolved it (an explicit `BASE_REF` override, the open PR's base, the repository default, or `origin/HEAD`); treat every `main` reference below as shorthand for that detected `<base>`. Two distinct `>>> WARNING:` lines can appear:

- `BASE_REF=... overrides the open PR's actual base ...` means `BASE_REF` was set but disagrees with the base of an actually-open PR - the override still wins, but call this out in the Description so reviewers know why.
- `local branch <candidate> sits between <base> and HEAD (likely stacked-PR parent) ...` means a local branch was found strictly between the detected base and `HEAD` - a common sign that the branch is part of a **stacked PR** built on a release/integration branch (or another branch in the stack) rather than the detected base. This happens most often before a PR is opened, when there is nothing for `gh pr view` to read and detection falls to the repository's default branch. If the named candidate is the branch this PR actually targets, rerun with `BASE_REF=<candidate>` rather than trusting the wider diff - the wider diff pulls in unrelated, already-integrated commits and inflates the evidence report and Description with more analysis than the PR needs.

If the script exits non-zero with a `>>> ERROR: base ref <base> cannot be resolved` line, the detected base is missing locally and could not be fetched: do not proceed on partial evidence; set `BASE_REF` to a valid branch or commit (or fetch the base) and rerun. The report is bounded by design; a single read is sufficient and you must not re-run `git diff <base>...HEAD` for full content.

1. Confirm branch/PR target from `git rev-parse --abbrev-ref HEAD` and `git status -sb`, and confirm the detected base branch from the report's `>>> base branch detected:` line.
2. Use the commit log block as the primary narrative - commits are already grouped, dated, and authored. Distil them into the 1-3 sentence Description summary and the reason each file changed.
3. Use the stat and dirstat blocks to enumerate the substantive files for the Description's file-by-file bullets and to gauge scope and folder distribution.
4. Use the top-N per-file diffs to verify what the commit subjects claim. If a file you need was not in the top-N, request only that file with `git --no-pager diff <base>...HEAD -- <path>`. If a per-file capture was truncated (look for `[...truncated: N more lines...]`), either rerun with `PER_FILE_CAP=<n>` or request that one file unbounded. Never re-expand the whole branch diff.
5. If both committed-vs-base _and_ staged pending blocks are empty, stop and report **"No diff vs `<base>` – nothing to raise."**
6. Mention any pending staged work explicitly in the Description so reviewers know the PR is not yet final. If the report shows a `staged changes skipped` line, the current branch is not the PR head branch, so no staged work is attributed to this PR.

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
   - Fill it exactly as the template's `## Description` guidance comment instructs: a 1-3 sentence summary, then a file-by-file bulleted list (each a repository-relative link with what changed and why), then any notable details, follow-ups, or out-of-scope items.
3. **Populate the Context section**
   - Answer every question in the template's `## Context` guidance comment (why required, previous behaviour and why inadequate, alternatives/trade-offs, and links to issue/ADR/discussion).
4. **Populate the How to test it section**
   - Follow the template's `## How to test it` guidance comment exactly: a `Prerequisites:` line, one numbered `Test N:` per behaviour with the command(s) in a fenced bash block, an `Expected:` line, and a `Clean up:` step when the working tree changes. For docs-only or config-only changes, state that and why no manual test applies.
5. **Set the "Type of changes" checkboxes**
   - Choose `x` for every applicable category (Refactoring, New feature, Breaking change, Bug fix) based on the diff.
   - Leave non-applicable items unchecked (`[ ]`). Never delete a line from the template.
6. **Update the Checklist section**
   - Reflect actual work done (`[x]`) vs outstanding (`[ ]`).
   - Tick "I have described how to test these changes in the section above" once the How to test it section is populated.
   - Always reference whether tests/docs were updated, style guidelines were followed, and collaboration mode (pair or mob programming, AI-assisted sessions) occurred.
7. **Populate "Sensitive Information Declaration"**
   - Confirm (`[x]`) only if you verified no PII/PID/sensitive data exists in the changes; otherwise leave unchecked and note required remediation.
8. **Call out follow-ups**
   - If additional work is deferred, list it succinctly (for example documentation gaps, pending ADRs) under Description or Context as bullet points.
9. **Write the output file (required)**
   - Write all generated PR content to `.copilot/analysis/gh-pr-content-YYYYMMDD-<slug>.report.md` (compute `<slug>` exactly as in §A: `pr-<number>` when a PR is known, otherwise the sanitised branch name).
   - If the file exists, overwrite it with the updated content.
   - Include a **Generated** footer with the current London time in format `YYYY-MM-DD hh:mm:ss`.

---

## Output requirements 📋

- Write the generated content to `.copilot/analysis/gh-pr-content-YYYYMMDD-<slug>.report.md` (slug as derived in §A) and print the same content inline for copy/paste.
- **The single source of truth for the output structure is [pull_request_template.md](../pull_request_template.md).** Read that file at runtime and reproduce it verbatim as the skeleton: every heading, guidance comment placeholder, checkbox, blank line, separator (`---`), and the Sensitive Information Declaration wording must match the template byte-for-byte. Do not hard-code or copy a skeleton into this prompt, and never paraphrase, reorder, add, or drop a section.
- Fill in the body by replacing each `<!-- ... -->` guidance comment with the actual content that comment requests, then delete the comment. Leave every visible heading, checkbox, separator, and the declaration exactly as they appear in the template.
- The only additions permitted are a `# {pull request title}` line at the very top and a `> Generated: YYYY-MM-DD hh:mm:ss` footer at the very bottom (current London time); these are report artefacts, not template sections.
- Tick a checkbox (`[x]`) only when the work genuinely applies; otherwise leave it `[ ]`. Never remove, rewrite, add, or reorder checkbox lines.
- Use workspace-relative Markdown links (for example `[scripts/apply.sh](scripts/apply.sh#L10-L40)`) and keep content ASCII-only unless evidence requires Unicode.
- **Enforcement (do before finalising):** compare your output against [pull_request_template.md](../pull_request_template.md). Ignoring only the filled-in content, the title line, and the footer, every heading, checkbox, and separator must be identical to the template. If anything differs, fix it so it matches exactly. If the template has since changed, re-read it and reproduce the new version.

Add additional sections **only** when [pull_request_template.md](../pull_request_template.md) itself gains them; the template's own order and content always govern the output.
