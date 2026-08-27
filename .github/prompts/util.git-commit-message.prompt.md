---
description: Generate conventional commit message and description from the current changes diff
---

**Mandatory preparation:**

- Ensure the repository has the `main` branch locally (fetch it only if missing). `main` is used **only** for branch-naming context and tone, not as commit evidence.
- Read language/tooling instructions that apply to the files actually staged or modified in the working tree (for example [python.instructions.md](../instructions/python.instructions.md), [typescript.instructions.md](../instructions/typescript.instructions.md), [makefile.instructions.md](../instructions/makefile.instructions.md), etc.). Do **not** load instructions for files that are only in already-committed history - they are out of scope.

## Goal 🎯

Produce three copy-ready outputs that describe the **next commit** the user is about to make:

1. A **Branch Name**: if already on a feature branch, report whether it is suitable (and suggest an improvement if not); if on `main`/detached `HEAD`, propose a new branch using `scope-short-description` (e.g. `auth-add-sso-callback`).
2. A single-line conventional **Commit Message** (`type(scope): summary`) describing the dominant change in the commit being prepared.
3. A **commit body** with an overview and highlights capturing intent and rationale (when evidenced), not just a restatement of file changes.

These outputs are the **primary narrative source** for pull-request descriptions: [util.gh-pr-content.prompt.md](util.gh-pr-content.prompt.md) reads `git log main..HEAD` (commit subjects + bodies) as its first evidence tier. Write every commit so it stands alone **and** aggregates cleanly with its siblings into a PR description; Step 3 maps each body part to the PR section it feeds.

### Scope policy (non-negotiable) 🎯

The commit message describes **the next commit**, whose content is **only the staged changes**. This section describes evidence precedence only, it does not instruct you to run anything. The single sanctioned command runs once in §A; everything named below is a description of a block already present in the resulting report.

The authoritative evidence is:

1. **Staged changes** - the sole evidence for the commit, found in the report's staged-stat and staged-diff blocks. If a change is not staged it is not part of this commit.

Unstaged working-tree changes are **deliberately excluded** and are not captured in the report. If nothing is staged, the report says so and you must output **"No staged changes – nothing to commit."** and stop.

The branch-wide stat and recent commit subjects are **context only**, found in the report's branch-log block and used solely to evaluate the current branch name and mirror tone. Never use them as the source of truth for the commit summary, and never expand them into a full per-line diff.

---

## Discovery (run before writing) 🔍

### A. Capture a bounded evidence report

Run the evidence script **once** from the repository root. It writes a bounded report to `.copilot/analysis/git-commit-message-diff-YYYYMMDD-<slug>.report.txt` (where `<slug>` is the sanitised current branch name, so per-branch runs do not overwrite each other). Per-file diffs are capped to keep large changes from blowing up the context.

```bash
bash .github/prompts/util.git-commit-message.sh
```

To increase the per-file line cap (default 400):

```bash
PER_FILE_CAP=800 bash .github/prompts/util.git-commit-message.sh
```

After the script completes, **read `$_report`** (the per-branch, per-day file written above) as the authoritative evidence. The report is bounded by design; a single read is sufficient and you must not re-run `git diff main...HEAD` for full content.

1. Confirm branch state from `git rev-parse --abbrev-ref HEAD` and `git status -sb`, and confirm the commit scope from the report's staged evidence blocks.
2. Use the staged stat + staged content as the **sole** evidence for the next commit. Unstaged working-tree changes are out of scope and are not captured in the report.
3. If the report shows no staged changes, output **"No staged changes – nothing to commit."** and stop.
4. Mirror recent commit tone using `git log -5 --oneline`: match the prefix style (`type(scope):` vs `type:`), the summary voice (imperative, lowercase, no trailing period), and reuse a scope token that already appears in recent history when one fits.
5. If a per-file capped diff was truncated (look for the `[...truncated: N more lines...]` marker), and you genuinely need more lines for one specific file, either rerun the script with `PER_FILE_CAP=<n>` or request only that file with `git --no-pager diff --cached -- <path>`. Do not expand more than necessary, and never expand the branch diff.

### B. Classify the change

1. Determine the dominant change type for Conventional Commits (`feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `build`, `ci`, `perf`, `revert`) from the **staged** changes only.
2. Identify a `scope` by using the most relevant component, package, or directory touched in those changes (prefer values already used in the repo; fall back to a short directory name if unsure).
3. Note any breaking changes or notable follow-ups visible in the in-scope diff.
4. **Multi-thread split heuristic.** If the in-scope changes span two or more clearly unrelated top-level areas (for example a skill update _and_ a CI/tooling pin) with no shared intent, recommend splitting in **Highlights** and still emit one combined Conventional Commit line covering both threads.

---

## Steps 👣

### 1) Extract key evidence

Work only from the **staged** changes (the sole commit evidence).

1. List the primary files/folders touched **in the in-scope changes** (not the whole branch).
2. Summarise behavioural changes (APIs, CLIs, jobs, infra, docs) in plain language.
3. Capture side effects (tests added, config changes, dependency updates).
4. Record unknowns explicitly (**Unknown from code – {action}**).
5. Note the current branch state (feature branch vs `main`/detached). If already on a feature branch, confirm whether its name matches the dominant change and suggest an improvement if not; otherwise, craft a new branch slug using `scope-short-description`. Branch-name suitability may reference the branch-wide stat/log from the report; the commit message itself must draw only on the staged changes.

### 2) Craft the Conventional Commit line

Follow these rules:

1. Format: `type(scope): summary`.
2. `summary` ≤ 72 characters, present tense, no trailing punctuation.
3. Mention breaking changes by appending `!` after the type/scope (`feat(api)!: ...`) and list details in the summary block.
4. Ensure the summary is specific (e.g. `feat(auth): add SSO callback validator`).
5. If multiple change types exist, pick the most user-facing; note secondary changes in the summary section.

### 3) Write the change summary (copy-ready)

Produce the commit body so each part maps onto the pull-request section it will feed (see Goal):

- 1-2 sentence overview of the change impact **and why it was needed** — feeds the PR Description prose and Context.
- Bullet list (max 7) of evidence-backed highlights; each names the file or component changed **and its observable effect** — feeds the PR Description bullets, not just a restatement of the diff.
- A `Testing:` line naming the **concrete commands run** so a reviewer can rerun them verbatim (or **Unknown from code, run {command}**) — feeds the PR "How to test it". Omit entirely if no testing was possible.
- A `Breaking changes:` line with explicit call-outs — feeds the PR "Type of changes" (Breaking change). Omit entirely if none exist.

### 4) Compile the final output (copy-ready template)

Return content exactly in this shape for easy copy/paste. The commit block (subject + body) must be directly pasteable into `git commit` with no labels or headings to remove.

```markdown
Branch: {branch name}
```

```markdown
{type(scope): summary}

{1-2 sentence overview}

- {highlight}
- ...

Testing: {commands or checks}

Breaking changes: {details}
```

Omit the `Testing` and `Breaking changes` lines entirely when they do not apply.

### 5) Write the output file (required)

- Write the same content emitted in step 4 to `.copilot/analysis/git-commit-message-YYYYMMDD-<slug>.report.md` (compute `<slug>` exactly as in §A: the sanitised current branch name).
- If the file exists, overwrite it with the updated content.
- Include a **Generated** footer with the current London time in format `YYYY-MM-DD hh:mm:ss`.

## Output requirements 📋

- Write the generated content to `.copilot/analysis/git-commit-message-YYYYMMDD-<slug>.report.md` (slug as derived in §A) **and** print the same content inline for copy/paste.
- Write every commit subject and body to be **self-contained and PR-ready** — readable in isolation and structured so `git log main..HEAD` can be turned into a PR description by [util.gh-pr-content.prompt.md](util.gh-pr-content.prompt.md) without re-reading the diff.
- Ground every statement in the **staged** diff; if evidence is missing, record **Unknown from code – {suggested action}**.
- If nothing is staged, do not invent a commit: output **"No staged changes – nothing to commit."** and stop.
- Ensure the branch suggestion covers both cases: re-affirm or improve the current feature branch name, or propose a new branch when working directly on `main`/detached `HEAD`.
- Prefer British English and concise, active phrasing.
- If multiple commits might be useful, mention that under **Highlights**, but still emit one Conventional Commit line for the in-scope changes.
- Do not invent scopes, behaviours, or tests; rely solely on repository evidence.
- Do not expand the full branch diff; the bounded report is sufficient.
- Ensure the final output matches the template exactly so it is ready to copy/paste.
