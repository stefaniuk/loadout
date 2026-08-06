---
description: Generate pull request review using architecture overview context
---

**Mandatory preparation:**

- Read the [constitution](../../.specify/memory/constitution.md) and honour its non-negotiable rules.
- Read the Pull Request template at [pull_request_template.md](../pull_request_template.md) only to understand the author's reporting structure; the review output uses its own structure defined below.
- Read the technology-specific instructions **only for languages actually touched on this branch** (look at the stat in the bounded report; do not preload every instruction file). For example [python.instructions.md](../instructions/python.instructions.md), [shell.instructions.md](../instructions/shell.instructions.md), [makefile.instructions.md](../instructions/makefile.instructions.md).
- Load design context (`docs/prompt-reports/repository-map.md`, `component-*.md`, `runtime-flow-*.md`, `domain-*.md`, `c4-*.dsl`, `*-infrastructure.*`) **only if those files actually exist** and only when the diff materially touches the components they describe. Do not block the review on missing design context.

## Goal 🎯

Act as a senior peer reviewer for the pull request that merges this branch into `main`. Produce a focused, constructive, evidence-based review whose primary job is to:

1. **Verify intent vs implementation** - does the code do what the PR title/description and commit messages claim, no more and no less?
2. **Surface merge-blockers first** - correctness, safety, security, contract, and data-integrity issues.
3. **Coach, don't nitpick** - every finding is actionable, prioritised, and evidence-backed; lower-severity items are suggestions, not demands.

The reviewer's deliverable is a Markdown report saved under `docs/prompt-reports/gh-pr-review-YYYYMMDD-<slug>.report.md` (where `<slug>` is `pr-<number>` when a PR is known, otherwise the sanitised branch name; this prevents collisions when several PRs are reviewed on the same day) and an overall verdict (Approve / Request changes / Comment).

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

---

## Discovery (run before writing) 🔍

### A. Capture the PR's stated intent (cheap, high-value)

The stated intent is the yardstick for the entire review. Capture it once, up front. The script supports an explicit PR via `PR_REF` (number or branch) so the agent does not need to be checked out on the head branch, and caps the captured body via `INTENT_BODY_CAP` to keep the ingestion cost bounded on long PR descriptions.

```bash
_date=$(date -u +%Y%m%d)
_pr_ref=${PR_REF:-}
_intent_body_cap=${INTENT_BODY_CAP:-400}

# Derive slug once: PR number if known, otherwise sanitised branch name.
_pr_num=$( (command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1 \
            && gh pr view ${_pr_ref:+"$_pr_ref"} --json number --jq .number) 2>/dev/null || true )
if [ -n "$_pr_num" ]; then
  _slug="pr-$_pr_num"
else
  _slug=$(git rev-parse --abbrev-ref HEAD | tr '/' '-' | tr -cd 'A-Za-z0-9_-')
fi

_intent_file="docs/prompt-reports/gh-pr-review-intent-$_date-$_slug.report.txt"
_review_file="docs/prompt-reports/gh-pr-review-$_date-$_slug.report.md"
mkdir -p "$(dirname "$_intent_file")"
: > "$_intent_file"

_truncate_body() {
  awk -v cap="$_intent_body_cap" '
    { lines++; if (lines <= cap) print; }
    END {
      if (lines > cap) {
        printf "\n[...truncated: %d more lines of intent body; rerun with INTENT_BODY_CAP=%d for full content...]\n", lines - cap, lines
      }
    }'
}

_gh_ok=0
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  if gh pr view ${_pr_ref:+"$_pr_ref"} \
       --json number,title,body,headRefName,baseRefName,author,isDraft,state,labels,url \
       --jq '"#" + (.number|tostring) + "  " + .title + "\n" +
             "branch: " + .headRefName + " -> " + .baseRefName + "\n" +
             "author: " + (.author.login // "?") + "   draft: " + (.isDraft|tostring) + "   state: " + .state + "\n" +
             "url:    " + .url + "\n" +
             "labels: " + (.labels | map(.name) | join(", ")) + "\n" +
             "\n--- body ---\n" + (.body // "")' \
       2>>"$_intent_file" \
     | _truncate_body >> "$_intent_file"; then
    _gh_ok=1
    printf '\n>>> source: gh pr view %s\n' "${_pr_ref:-(current branch)}" >> "$_intent_file"
  fi
fi

if [ "$_gh_ok" -eq 0 ]; then
  printf '\n>>> gh unavailable or PR not found; using working-tree fallback\n' >> "$_intent_file"
  printf '\n--- branch ---\n' >> "$_intent_file"
  git rev-parse --abbrev-ref HEAD >> "$_intent_file" 2>&1
  printf '\n--- first commit body (often the headline intent) ---\n' >> "$_intent_file"
  git log --no-merges --reverse main..HEAD --pretty=format:'%h%n%s%n%n%b%n---' -n 1 \
    | _truncate_body >> "$_intent_file"
  printf '\n--- subsequent commit subjects ---\n' >> "$_intent_file"
  git log --no-merges --reverse main..HEAD --skip=1 --pretty=format:'%h %s' \
    >> "$_intent_file" 2>&1
  for _f in CHANGELOG.md docs/CHANGELOG.md .github/pull_request_template.md; do
    if [ -f "$_f" ]; then
      printf '\n--- %s (capped at %s lines) ---\n' "$_f" "$_intent_body_cap" >> "$_intent_file"
      _truncate_body < "$_f" >> "$_intent_file"
    fi
  done
fi

# Review output filename was derived above as $_review_file using the same _date/_slug.
printf '\nIntent → %s (%s bytes)\nReview file → %s\n' \
  "$_intent_file" "$(wc -c < "$_intent_file")" "$_review_file"
```

Read the intent file once and extract:

- The PR's stated **scope** (title + body bullet points or first commit body).
- Any linked issues or specs (e.g. `Closes #123`, `Refs ADR-007`).
- **Draft status** - drafts almost always conclude with a **Comment** verdict (coaching tone); ready-for-review PRs may be approved or blocked.

When the fallback path runs, the intent is necessarily weaker; mark the review header with `Intent source: commit log (no PR metadata)` so readers can calibrate trust in the intent-vs-implementation lens.

### B. Capture a bounded diff evidence report

Same pattern as the PR-content prompt: commit log (primary narrative), structural stat, dirstat, top-N per-file capped diffs. Run **once**. Computes `_date`/`_slug` independently so this block remains runnable in isolation.

```bash
_date=$(date -u +%Y%m%d)
_pr_ref=${PR_REF:-}
_pr_num=$( (command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1 \
            && gh pr view ${_pr_ref:+"$_pr_ref"} --json number --jq .number) 2>/dev/null || true )
if [ -n "$_pr_num" ]; then
  _slug="pr-$_pr_num"
else
  _slug=$(git rev-parse --abbrev-ref HEAD | tr '/' '-' | tr -cd 'A-Za-z0-9_-')
fi
_report="docs/prompt-reports/gh-pr-review-diff-$_date-$_slug.report.txt"
mkdir -p "$(dirname "$_report")"
: > "$_report"

if ! git check-ignore -q "$_report" 2>/dev/null; then
  printf '\n>>> WARNING: %s is not gitignored; add it to .gitignore.\n' "$_report" >> "$_report"
fi

if ! git show-ref --verify --quiet refs/heads/main; then
  printf '\n>>> %s\n' "git fetch origin main:main" >> "$_report"
  git fetch origin main:main >> "$_report" 2>&1 || true
fi

for cmd in \
  "git rev-parse --abbrev-ref HEAD" \
  "git status -sb" \
  "git rev-list --no-merges --count main..HEAD" \
  "git log --no-merges --reverse main..HEAD --pretty=format:'%h %an %ad %s%n%b%n---' --date=short" \
  "git diff --stat main...HEAD" \
  "git diff --dirstat=files,1 main...HEAD" \
  "git diff --cached --stat" \
  "git diff --stat"; do
    printf '\n>>> %s\n' "$cmd" >> "$_report"
    eval "$cmd" >> "$_report" 2>&1
done

_top_n=${TOP_N_FILES:-20}
_per_file_cap=${PER_FILE_CAP:-400}

_top_files=$(
  git diff --numstat main...HEAD \
    | awk '$1 != "-" && $2 != "-" { print ($1 + $2), $3 }' \
    | sort -rn \
    | head -n "$_top_n" \
    | awk '{ $1=""; sub(/^ /, ""); print }'
)

_capture() { # args: <label> <path> <git-diff-args...>
  local label=$1 path=$2; shift 2
  printf '\n--- %s: %s ---\n' "$label" "$path" >> "$_report"
  git --no-pager diff "$@" -- "$path" \
    | awk -v cap="$_per_file_cap" -v file="$path" '
        { lines++; if (lines <= cap) print; }
        END {
          if (lines > cap) {
            printf "\n[...truncated: %d more lines for %s; rerun with PER_FILE_CAP=%d or `git --no-pager diff main...HEAD -- %s` for full content...]\n",
              lines - cap, file, lines, file
          }
        }' >> "$_report"
}

if [ -n "$_top_files" ]; then
  printf '\n>>> top %s files vs main by change size (per file, capped %s lines each)\n' \
    "$_top_n" "$_per_file_cap" >> "$_report"
  printf '%s\n' "$_top_files" | while IFS= read -r f; do
    [ -z "$f" ] && continue
    _capture "branch-vs-main" "$f" main...HEAD --unified=3
  done
else
  printf '\n>>> no committed differences between main and HEAD\n' >> "$_report"
fi

printf '\nReport → %s (%s bytes, %s lines)\n' \
  "$_report" "$(wc -c < "$_report")" "$(wc -l < "$_report")"
```

Read the report once. If a file you need to scrutinise was not in the top-N or got truncated (look for the `[...truncated: N more lines for <file>...]` marker), pull only that file with `git --no-pager diff main...HEAD -- <path>` or rerun with `PER_FILE_CAP=<n>`. Do not expand the whole branch diff.

If the report shows no `main...HEAD` differences, output **"No diff vs main – nothing to review."** and stop.

### C. Detect prior reviews and scope the work

Do this **before** triage so the triage step can narrow to what actually changed since the last review.

1. The output path was derived in §A as `$_review_file` (`docs/prompt-reports/gh-pr-review-YYYYMMDD-<slug>.report.md`). Look for that exact file and for any earlier `gh-pr-review-*-<slug>.report.md` files for the same PR/branch.
2. If no prior review exists, plan a **full** review using the structure in §6.
3. If one or more prior reviews exist:
   - Read the most recent one as the baseline.
   - Compute the changed-files set since that review's `Generated:` timestamp (or, more reliably, since the commit hash it cites). Use `git diff --name-only <last-reviewed-sha>..HEAD` when available.
   - Plan a **delta** review: scope triage (§D) to the changed-since-last-review subset; carry forward previous findings under one of `✅ Resolved` (with evidence), `🔴 Still open`, `🆕 New`.
   - Never overwrite prior review content; the file grows by appending a `## Review update – YYYY-MM-DD hh:mm:ss UTC` section (see §5).

### D. Triage which review areas actually apply

A high-quality review covers what changed; it does not pad with "No findings in this category" for irrelevant areas.

For each rubric category (2A–2K), mark one of:

- **In scope** - the diff materially touches this area; review it.
- **Out of scope** - the diff does not touch this area; do not list it in the report.
- **Spot-check** - touched only incidentally; check briefly and only report if something stands out.

**Adaptive form.** Count the changed files: `git diff --name-only main...HEAD | wc -l`.

- **≥ 10 files** - write the full triage table (one row per category) in the review's "Scope & approach" section so readers can see what was looked at and what was not.
- **< 10 files** - skip the table; state in-scope categories as a single sentence (e.g. "In scope: 2A correctness, 2B tests, 2J build/CI."). Out-of-scope categories are silently omitted.

For incremental reviews (§C), only re-triage areas whose files changed since the prior review.

### E. Quality signals - rely on existing evidence

Reviewers verify; they do not normally rerun expensive gates.

1. Check the PR / branch commits for evidence that gates already ran (commit messages, hook-recorded artefacts, and especially `gh pr checks` - if all required checks are green within the last commit window, record that and **do not rerun local gates**).
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

- Path: `$_review_file` as derived in §A - `docs/prompt-reports/gh-pr-review-YYYYMMDD-<slug>.report.md` where `<slug>` is `pr-<n>` when a PR number is known, otherwise the sanitised branch name. This keeps same-day reviews of different PRs from colliding.
- New file: write the full review using the structure in §6.
- Existing file (incremental review): append `## Review update – YYYY-MM-DD hh:mm:ss UTC` containing only the delta - newly changed areas, ✅ Resolved (with evidence), 🔴 Still open, 🆕 New. Do not overwrite earlier sections.
- End the file with the overall verdict (§7) and a `Generated:` footer.

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

> Generated: YYYY-MM-DD hh:mm:ss UTC
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
