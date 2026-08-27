---
description: Generate pull request review using architecture overview context
---

**Mandatory preparation:**

- Read the [constitution](../../.specify/memory/constitution.md) and honour its non-negotiable rules.
- Read the Pull Request template at [pull_request_template.md](../pull_request_template.md) only to understand the author's reporting structure; the review output uses its own structure defined below.
- Read the technology-specific instructions **only for languages actually touched on this branch** (look at the stat in the bounded report; do not preload every instruction file). For example [python.instructions.md](../instructions/python.instructions.md), [shell.instructions.md](../instructions/shell.instructions.md), [makefile.instructions.md](../instructions/makefile.instructions.md).
- Load design context (`.copilot/analysis/repository-map.md`, `component-*.md`, `runtime-flow-*.md`, `domain-*.md`, `c4-*.dsl`, `*-infrastructure.*`) **only if those files actually exist** and only when the diff materially touches the components they describe. Do not block the review on missing design context.

## Goal 🎯

Act as a senior peer reviewer for the pull request that merges this branch into its detected base branch (see the Scope policy). Produce a focused, constructive, evidence-based review whose primary job is to:

1. **Verify intent vs implementation** - does the code do what the PR title/description and commit messages claim, no more and no less?
2. **Surface merge-blockers first** - correctness, safety, security, contract, and data-integrity issues.
3. **Coach, don't nitpick** - every finding is actionable, prioritised, and evidence-backed; lower-severity items are suggestions, not demands.

The reviewer's deliverable is a Markdown report saved under `.copilot/analysis/gh-pr-review-YYYYMMDD-<slug>.report.md` (where `<slug>` is `pr-<number>` when a PR is known, otherwise the sanitised branch name; this prevents collisions when several PRs are reviewed on the same day) and an overall verdict (Approve / Request changes / Comment).

### Quality bar (apply to every finding)

- **Evidence-based.** Cite a path, line range, symbol, or commit hash. No claim without evidence.
- **Specific.** State exactly what to change. "Improve error handling" is not a review; "wrap the call at `apply.sh:128` in a `trap` so failures from `cp` propagate" is.
- **Prioritised.** Use the severity rubric in §3; do not inflate severity to force attention.
- **Charitable.** Phrase as a question or suggestion when intent is unclear; assume the author has reasons you may not see.
- **Scoped.** Stay inside the PR's stated scope. Do not request out-of-scope refactors. Note out-of-scope risks under **📌 Follow-ups**, not under Must-fix/Should-fix.

### What NOT to comment on

- Style/formatting issues already handled by the repo's formatters or linters (the gates will catch them).
- Pre-existing issues not touched by this PR (note under **📌 Follow-ups** at most).
- Personal stylistic preferences that have no measurable impact.
- "While you're here, refactor X" suggestions that widen scope.
- Findings that simply restate what the diff shows; a finding must add new information (risk, alternative, missed case).

### Scope policy (non-negotiable) 🎯

The base branch is **never assumed to be `main`**. It is detected automatically (see §B) from the PR's actual base ref, or the repository's default branch, falling back to `main` only if neither can be determined. Everywhere below, "base branch" or "`<base>`" refers to this detected ref.

This section describes the review focus and evidence sources only, it does not instruct you to run anything. The single sanctioned command runs once in §B and writes both the intent file read in §A and the diff report read in §B; everything named below is a description of a block already present in the resulting reports.

A PR review covers **the committed diff between the base branch and `HEAD`**, plus any **staged** changes when the current branch is the PR head branch, judged against the PR's stated intent. Unstaged working-tree changes are **deliberately excluded**. The review walks these evidence tiers in order:

1. **Stated intent** - the yardstick for all findings, found in the intent file captured in §A (the PR's title, description, and linked issues/specs).
2. **Commit subjects + bodies** - the branch authors' own narrative, found in the report's commit-log block (ideally structured via [util.git-commit-message.prompt.md](util.git-commit-message.prompt.md)).
3. **Diff overview** - structural scope and folder distribution, found in the report's stat and dirstat blocks.
4. **Top-N per-file diffs**, capped, with explicit truncation markers - for the largest or most behaviour-bearing changes, found in the report's per-file diff blocks.
5. **Staged working-tree changes** - found in the report's staged-pending block, present only when the current branch is the PR head branch (the script skips them otherwise and records why). Review them as "pending, not yet committed" and flag that status in the review.
6. **Design context** (optional) - found in `.copilot/analysis/repository-map.md`, `component-*.md`, `runtime-flow-*.md`, etc., **only if those files exist** and only when the diff materially touches the components they describe.

Never expand the full diff between the base branch and `HEAD` into the review; the bounded evidence is sufficient.

---

## Discovery (run before writing) 🔍

### A. Capture the PR's stated intent (cheap, high-value)

The stated intent is the yardstick for the entire review and is captured once, up front by the script in §B below. Read the intent file to extract:

- The PR's stated **scope** (title + body bullet points or first commit body).
- Any linked issues or specs (for example `Closes #123`, `Refs ADR-007`).
- **Draft status**: drafts almost always conclude with a **Comment** verdict (coaching tone). Ready-for-review PRs may be approved or blocked.

The script supports an explicit PR via `PR_REF` (number or branch) so the agent does not need to be checked out on the head branch, and caps the captured body via `INTENT_BODY_CAP` to keep the ingestion cost bounded on long PR descriptions. This is a **no-op after §B runs** — the combined script handles both intent and diff in one pass.

### B. Capture a bounded diff evidence report

The evidence script produces both the stated intent and a bounded diff report in one pass. Same pattern as the PR-content prompt: commit log (primary narrative), structural stat, dirstat, top-N per-file capped diffs.

The script detects the base branch itself: it prefers the actual PR base ref (via `gh pr view --json baseRefName`), then the repository's default branch, then `origin/HEAD`, and only falls back to `main` if none of these resolve. Override it explicitly with `BASE_REF` when needed (for example when reviewing against a release branch).

**Run the combined evidence script once from the repository root.** It produces all necessary evidence files:

```bash
bash .github/prompts/util.gh-pr-review.sh
```

To override defaults (explicit PR, cap sizes, or explicit base branch):

```bash
PR_REF=123 TOP_N_FILES=30 PER_FILE_CAP=600 INTENT_BODY_CAP=600 bash .github/prompts/util.gh-pr-review.sh
BASE_REF=develop bash .github/prompts/util.gh-pr-review.sh
```

The script outputs:

- `.copilot/analysis/gh-pr-review-intent-YYYYMMDD-<slug>.report.txt` (intent)
- `.copilot/analysis/gh-pr-review-diff-YYYYMMDD-<slug>.report.txt` (diff evidence)
- `.copilot/analysis/gh-pr-review-YYYYMMDD-<slug>.report.md` (review output target)

After the script completes, **read both files** as the authoritative evidence. The diff report's `>>> base branch detected: <base> (source: ...)` line records which branch was used and which detection tier resolved it (an explicit `BASE_REF` override, the open PR's base, the repository default, or `origin/HEAD`); treat every `main` reference below as shorthand for that detected `<base>`. A `>>> WARNING:` line means `BASE_REF` was set but disagrees with the base of an actually-open PR - the override still wins, but call this out in the review so readers know why. If the script exits non-zero with a `>>> ERROR: base ref <base> cannot be resolved` line, the detected base is missing locally and could not be fetched: do not proceed on partial evidence; set `BASE_REF` to a valid branch or commit (or fetch the base) and rerun. The reports are bounded by design; a single read is sufficient. Do not re-run `git diff <base>...HEAD` or similar commands; the bounded report is complete.

**Reading the intent file:** Extract the PR's stated **scope**, any linked issues/specs, and draft status.

**Reading the diff report:** If a file you need to scrutinise was not in the top-N or got truncated (look for the `[...truncated: N more lines for <file>...]` marker), pull only that file with `git --no-pager diff <base>...HEAD -- <path>` or rerun with `PER_FILE_CAP=<n>`. Do not expand the whole branch diff. Also read the report's staged-pending block when present (the current branch is the PR head branch); review those staged changes as pending, not-yet-committed work.

If the report shows no `<base>...HEAD` differences **and** no staged-pending block, output **"No diff vs `<base>`, nothing to review."** and stop. If there are no committed differences but a staged-pending block exists, review the staged changes and state clearly that the diff is staged but not yet committed.

### C. Detect prior reviews and scope the work

Do this **before** triage so the triage step can narrow to what actually changed since the last review.

1. The output path was derived in §B as `$_review_file` (`.copilot/analysis/gh-pr-review-YYYYMMDD-<slug>.report.md`). Look for that exact file and for any earlier `gh-pr-review-*-<slug>.report.md` files for the same PR/branch.
2. If no prior review exists, plan a **full** review using the structure in §6.
3. If one or more prior reviews exist:
   - Read the most recent one as the baseline.
   - Compute the changed-files set since that review's `Generated:` timestamp (or, more reliably, since the commit hash it cites). Use `git diff --name-only <last-reviewed-sha>..HEAD` when available.
   - Plan a **delta** review: scope triage (§D) to the changed-since-last-review subset; carry forward previous findings under one of `✅ Resolved` (with evidence), `🔴 Still open`, `🆕 New`.
   - Never overwrite prior review content; the file grows by appending a `## Review update – YYYY-MM-DD hh:mm:ss` section (see §5).

### D. Triage which review areas actually apply

A high-quality review covers what changed; it does not pad with "No findings in this category" for irrelevant areas.

For each rubric category (2A–2K), mark one of:

- **In scope** - the diff materially touches this area; review it.
- **Out of scope** - the diff does not touch this area; do not list it in the report.
- **Spot-check** - touched only incidentally; check briefly and only report if something stands out.

**Adaptive form.** Read the changed-file count from the diff report's `git diff --stat <base>...HEAD` block (the summary line ends `N files changed, ...`); no separate command is needed.

- **≥ 10 files** - write the full triage table (one row per category) in the review's "Scope & approach" section so readers can see what was looked at and what was not.
- **< 10 files** - skip the table; state in-scope categories as a single sentence (e.g. "In scope: 2A correctness, 2B tests, 2J build/CI."). Out-of-scope categories are silently omitted.

For incremental reviews (§C), only re-triage areas whose files changed since the prior review.

### E. Quality signals - rely on existing evidence

This section describes the signal priority; it does not instruct you to run anything by default. All primary evidence was already captured by the script in §B. Reviewers verify; they do not normally rerun expensive gates.

1. Check the captured intent and diff evidence for signs that gates already ran (commit messages, hook-recorded artefacts, and especially `gh pr checks` - if all required checks are green within the last commit window, record that and **do not rerun local gates**).
2. Spot-check one or two changed files with the cheapest gate (e.g. `git --no-pager grep`, `make lint -- <path>` if supported) when the diff suggests a concrete risk.
3. Only rerun a full local `make lint` / `make test` when CI evidence is missing or stale **and** the diff size justifies it.
4. Record what you did - and what you deliberately did not run - under **Verification evidence** in the review.

---

## Steps (review and report) 👣

### 1) Summarise what changed (diff-driven, intent-aware)

1. State the PR's stated intent (one sentence from the title/body).
2. Map commits → change themes using the commit-log block. Note unrelated threads if any.
3. List the components/flows impacted (use names from `component-*.md` / `runtime-flow-*.md` only if those files exist; otherwise use directory or module names).
4. Call out any public surface changes: API routes/contracts, events/topics/queues and schemas, CLI commands, configuration keys / environment variables, exit codes.
5. **Intent gap check:** explicitly compare scope (what the PR says it does) vs implementation (what the diff actually does). Surface any of:
   - Scope creep (code does more than the PR claims).
   - Scope gap (PR claims something the code does not deliver).
   - Drift (code contradicts the linked spec/ADR/issue).
     Intent gaps are typically **Must-fix** or **❓ Questions**.

### 2) Walk the rubric (only the in-scope categories from §D triage)

Use these categories as a checklist; report findings against the categories that triage marked as in-scope or spot-check. Within each, find the highest-value items, not the most items.

#### 2A. Correctness and behaviour

- Does the change match the apparent intent of the diff and any referenced tickets?
- Are edge cases handled (null/empty, invalid inputs, timeouts, retries, cancellation)?
- Is error handling consistent (exceptions/errors mapped appropriately)?
- Are defaults safe and explicit?

#### 2B. Tests and verification

- Are there tests for the new/changed behaviour, and do they exercise failure paths?
- Are tests meaningful (behaviour, not coverage theatre)?
- Are tests stable (no flakiness, no timing/global-state reliance)?
- Are property-based tests used where they would add value?

#### 2C. Readability and maintainability

- Naming, structure, function/module size, separation of concerns.
- Comments explain _why_, not _what_.
- Dead code, commented-out code, TODOs without owners.

#### 2D. Architecture and domain consistency

- Respects component boundaries and ubiquitous language.
- Domain rules enforced in the right layer.
- New concepts fit an existing bounded context or justify a new one.

#### 2E. Data and persistence safety

- Schema/migration changes: safe, reversible, compatible.
- Write paths correct, transactions/atomicity where needed.
- Data ownership respected; identifiers and timestamps consistent.

#### 2F. Interfaces and compatibility

- API contracts backwards compatible or clearly versioned.
- Event/message schemas compatible with consumers/producers.
- Integration changes reflected in configuration and deployment artefacts.

#### 2G. Security and access control

- Auth/authz: least-privilege, no privilege escalation.
- Secrets: no hard-coded credentials, no secrets in logs.
- Inputs validated/sanitised; output encoding correct.
- Dependency changes: licence, known vulnerabilities, supply-chain risk.

#### 2H. Observability and operability

- Important actions logged appropriately (no sensitive data).
- Metrics/tracing updated when behaviour changes.
- Failure modes diagnosable; timeouts/retries/backoff reasonable.

#### 2I. Performance and resource use

- New loops, queries, or network calls are efficient.
- No N+1, no unbounded operations, no excessive memory usage.
- Caches/batching used only where the codebase already establishes the pattern.

#### 2J. Build, CI, and tooling

- Build scripts, CI workflows, developer tooling changes are coherent.
- Lockfiles/manifests updated consistently.
- Generated files avoided unless required and reproducible.

#### 2K. Documentation and review hygiene

- README, runbooks, ADRs, architecture docs updated as needed.
- Changelog/release notes added if the repo uses them.
- Commit messages and PR description are clear for future readers.

### 3) Severity rubric (apply to every finding)

- **🔴 Must-fix (blocker).** Correctness bug, data loss, security vulnerability, broken public contract, failing test that would be missed, or violation of a constitution rule. Merge must not happen until resolved.
- **🟡 Should-fix.** Significant maintainability, observability, or readability issue with concrete near-term cost. Strongly recommended before merge but not strictly blocking.
- **🟢 Nice-to-have.** Minor improvement with low cost-of-delay; author may defer.
- **❓ Question.** Reviewer cannot tell from evidence alone whether something is correct; author response required before classification.
- **📌 Follow-up.** Out-of-scope risk or improvement worth tracking separately (issue/ADR/ticket). Does not block merge.
- **✅ Good practice.** Something done notably well; keep brief, only one or two per review.

Calibration rules:

- If a finding cannot be tied to a constitution rule, instruction file, or concrete risk, demote it.
- Do not raise Must-fix without citing evidence of failure mode or rule violation.
- Resist the temptation to upgrade severity to force a response.
- **Findings ceiling.** Aim for at most **8 combined Must-fix + Should-fix** items per review. If more candidates exist, the diff almost certainly has a small number of root causes - group related items under one finding by theme (e.g. "missing input validation across new endpoints") rather than enumerating each occurrence. Beyond the ceiling, prefer 🟢 Nice-to-have or 📌 Follow-ups.

### 4) Finding template (use for every significant item)

Use this snippet for each finding so authors can scan and act quickly. The outer fence uses four backticks so the inner three-backtick fences (`diff`, `bash`, `python`, etc.) render verbatim.

````markdown
### {severity emoji} {finding title}

{1-3 sentences: what you observed and why it matters. Include the failure mode or rule violated.}

**Recommendation**

- {specific change to make, ideally with the file/line to edit}

**Rule** (optional, omit the heading if not applicable)

- `{rule-id}` - e.g. `PY-QG-001` from [python.instructions.md](../instructions/python.instructions.md), or `SH-HDR-001` from [shell.instructions.md](../instructions/shell.instructions.md), or a constitution clause path.

**Snippet**

```diff
{the smallest excerpt that demonstrates the issue; use the file's language (`bash`, `python`, etc.) for a quote, or `diff` for a proposed patch; omit the whole Snippet block if a path+line citation is sufficient}
```

**Evidence**

- `<workspace-relative path>#L<start>-L<end>` rendered as a Markdown link to the file and line range, plus the `{symbol or config key}`.
- Optional: `{commit hash from the log block, linked issue, ADR}`.
````

Do not use **Unknown from code** inside a finding; if evidence is missing, raise it as a **❓ Question** instead, and ensure the question itself cites the evidence that prompted the doubt rather than speculating about possibilities.

### 5) Write or update the review file (required)

- Path: `$_review_file` as derived in §B - `.copilot/analysis/gh-pr-review-YYYYMMDD-<slug>.report.md` where `<slug>` is `pr-<n>` when a PR number is known, otherwise the sanitised branch name. This keeps same-day reviews of different PRs from colliding.
- New file: write the full review using the structure in §6.
- Existing file (incremental review): append `## Review update – YYYY-MM-DD hh:mm:ss` (current London time) containing only the delta - newly changed areas, ✅ Resolved (with evidence), 🔴 Still open, 🆕 New. Do not overwrite earlier sections.
- End the file with the overall verdict (§7) and a **Generated** footer with the current London time in format `YYYY-MM-DD hh:mm:ss`.

---

## 6) Review output structure 📄

```markdown
# PR Review - {pr title or branch name} - YYYY-MM-DD

**Branch:** `{branch}` → `main` &nbsp;|&nbsp; **Commits:** {n} &nbsp;|&nbsp; **Stated intent:** {one-line summary from PR / log}

## Scope & approach

- **Scope summary** - either a full triage table (categories 2A–2K marked In scope / Out of scope / Spot-check, with one-line rationale) for PRs with ≥ 10 changed files, or a one-sentence inline list of in-scope categories for smaller PRs (see §D for the rule).
- **Verification evidence** - what gates already ran, what was spot-checked, what was deliberately not rerun.
- **Intent vs implementation** - explicit gap statement (none / drift / creep / shortfall).

## Findings

### ✅ Good practices

{1–2 brief items, only real ones}

### 🔴 Must-fix

{findings using the template; omit the heading entirely if none}

### 🟡 Should-fix

{findings; omit heading if none}

### 🟢 Nice-to-have

{findings; omit heading if none}

### ❓ Questions

{findings; omit heading if none}

### 📌 Follow-ups

{out-of-scope items to track separately; omit heading if none}

## Verdict

{Approve / Request changes / Comment} - {one-paragraph rationale}

---

> Generated: YYYY-MM-DD hh:mm:ss
```

Omit empty severity sections entirely; do not write "No findings" placeholders.

## 7) Overall verdict 🧭

Decide one of three outcomes and state it explicitly:

- **Approve** - no Must-fix; Should-fix items (if any) are minor or already acknowledged.
- **Request changes** - at least one Must-fix, or a Should-fix that materially undermines the PR's stated intent. Reserve this verdict for ready-for-review PRs with concrete blockers; do not use it on drafts.
- **Comment** - open questions need author response before a verdict can be issued; or the PR is a draft. **Draft PRs almost always conclude with Comment**: the review is coaching, not gating, regardless of finding severity.

The verdict must be consistent with the findings: do not approve while listing Must-fix items, and do not request changes on a draft.

---

## Output requirements 📋

- British English, ASCII-only unless evidence requires Unicode.
- Be precise, constructive, and charitable; prefer questions to commands when intent is unclear.
- Every finding cites evidence; omit categories with no findings.
- Use the same component names as in `component-*.md` when those files exist; otherwise use directory/module names from the diff.
- Do not invent rules, files, or behaviours; if evidence is missing, use **❓ Question**.
