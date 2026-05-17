---
description: Generate pull request review using architecture overview context
---

**Mandatory preparation:**

- Read the [constitution](../../.specify/memory/constitution.md) and honour its non-negotiable rules.
- Read the Pull Request template at [pull_request_template.md](../pull_request_template.md) so the generated content mirrors it exactly.
- Read the technology-specific instructions for every language touched in the diff (for example [python.instructions.md](../instructions/python.instructions.md), [shell.instructions.md](../instructions/shell.instructions.md), [makefile.instructions.md](../instructions/makefile.instructions.md)).
- Review the design context under `docs/prompt-reports/` to describe affected components accurately.

## Goal 🎯

Produce a thorough, evidence-based peer review of the current branch changes compared to `main`.

Your output must be grounded in:

- The actual diff between this branch and `main`
- The existing design overview documentation under `docs/prompt-reports/`

Where evidence cannot be found, record **Unknown from code – {suggested action}**.

---

## Discovery (run before writing) 🔍

### A. Load design overview context (read before reviewing code)

1. Read the repository documentation that exists under `docs/prompt-reports/`:
   - `README.md`
   - `repository-map.md`
   - `loc-report.txt`
   - `component-*.md`
   - `runtime-flow-*.md`
   - `domain-*.md`
   - `c4-*.dsl`
   - `*-infrastructure.*`
2. Note which components, flows, bounded contexts, and interfaces are relevant to the change set.

### B. Establish an accurate diff against `main`

Run the labelled batch below **once** from the repository root. Output is written to `docs/prompt-reports/git-pr-review-diff.txt` so that large diffs do not overflow the terminal context.

```bash
_diff_file="docs/prompt-reports/git-pr-review-diff.txt"
: > "$_diff_file"
if ! git show-ref --verify --quiet refs/heads/main; then
  printf '\n>>> %s\n' "git fetch origin main:main" | tee -a "$_diff_file"
  git fetch origin main:main 2>&1 | tee -a "$_diff_file"
fi
for cmd in \
  "git diff --stat main...HEAD" \
  "git diff main...HEAD" \
  "git status -sb" \
  "git rev-parse --abbrev-ref HEAD"; do
    printf '\n>>> %s\n' "$cmd" >> "$_diff_file"
    eval "$cmd" >> "$_diff_file" 2>&1
done
printf '\nDiff captured → %s (%s bytes)\n' "$_diff_file" "$(wc -c < "$_diff_file")"
```

After the script completes, **read the file `docs/prompt-reports/git-pr-review-diff.txt`** in full and use its contents as the authoritative diff evidence for the rest of this review.

1. Use `git diff --stat main...HEAD` for the overview and `git diff main...HEAD` for detailed evidence.
2. Capture branch/working-tree information from `git status -sb` and `git rev-parse --abbrev-ref HEAD`.
3. Identify the change category (one or more):
   - Bug fix
   - New feature
   - Refactor
   - Dependency/tooling change
   - Build/CI change
   - Documentation only
4. Identify impacted areas:
   - Entry points / routes / handlers / consumers / schedulers
   - Data stores / schemas / migrations
   - External integrations
   - Configuration and secrets
   - Observability (logs/metrics/tracing)
   - Security and access control

If the diff cannot be produced, record **Unknown from code – run git diff against main** and stop.

### C. Detect prior reviews and new commits (incremental review)

1. Define the review output file path for today:
   - `docs/prompt-reports/pr-review-YYYYMMDD.report.md` (use today's date)
2. If the file already exists:
   - Read it fully.
   - Treat it as the previous review baseline for this branch.
   - Identify which previous findings may already be addressed and which remain open.
   - Detect whether there are additional changes since that review by comparing the captured diff output to the files/areas previously discussed.
   - Focus the new review on:
     - Newly changed files/behaviour
     - Previously raised issues that are still present
     - Previously raised issues that appear fixed (mark as **✅ Resolved** with evidence)
3. If the file does not exist:
   - Proceed with a full review and create it at the end.

### D. Run quality signals (only what is available in the repo)

1. Identify how the project expects checks to run (e.g. `Makefile`, task runner scripts, CI workflows).
2. Run the standard local checks if feasible and quick:
   - Tests
   - Linting and formatting checks
   - Type checking / static analysis (if configured)
3. Record what you ran and the outcomes. If you cannot run checks, record **Unknown from code – run project checks**.

---

## Steps (review and report) 👣

### 1) Summarise what changed (diff-driven)

1. Provide a concise summary of:
   - What files changed
   - What behaviour changed
   - What components/flows are impacted (use names from `component-*.md` and `runtime-flow-*.md`)
2. Call out any public surface changes:
   - API routes/contracts
   - Events/topics/queues and schemas
   - CLI commands
   - Configuration keys / environment variables

### 2) Perform generic peer-review checks (do not assume; use evidence)

Use the following checklist and report findings with evidence links and file paths.

#### 2A. Correctness and behaviour

- Does the change match the apparent intent of the diff and any referenced tickets?
- Are edge cases handled (null/empty, invalid inputs, timeouts, retries)?
- Is error handling consistent (exceptions/errors mapped appropriately)?
- Are defaults safe and explicit?

#### 2B. Tests and verification

- Are there tests for the new/changed behaviour?
- Are tests meaningful (behavioural confidence, not just coverage)?
- Are critical paths and failure paths exercised?
- Are tests stable (no flakiness, no reliance on timing/global state)?

#### 2C. Readability and maintainability

- Is the change easy to understand (naming, structure, small functions/modules)?
- Are responsibilities separated (no "god" modules, no mixed concerns)?
- Are comments/docstrings used appropriately (explain why, not what)?

#### 2D. Consistency with existing architecture and domain

- Does the change respect established component boundaries?
- Does the change align with domain terms and definitions (ubiquitous language)?
- Are domain rules enforced in the right layer (not leaking across boundaries)?
- If it introduces a new concept, does it fit an existing bounded context or require a new one?

#### 2E. Data and persistence safety

- Any schema/migration changes: are they safe, reversible, and compatible?
- Are write paths correct and consistent (transactions/atomicity where needed)?
- Is data ownership respected (no cross-boundary writes unless explicitly intended)?
- Are identifiers and timestamps handled consistently?

#### 2F. Interfaces and compatibility

- Are API contracts backwards compatible (or clearly versioned)?
- Are event/message schemas compatible with existing consumers/producers?
- Are integration changes reflected in configuration and deployment artefacts?

#### 2G. Security and access control

- Any auth/authz changes: are permissions correct and least-privilege?
- Are secrets handled safely (no hard-coded secrets, no sensitive logs)?
- Are inputs validated/sanitised where needed?
- Any dependency changes: do they introduce risk (licence, vulnerabilities)?

#### 2H. Observability and operability

- Are important actions logged appropriately (without sensitive data)?
- Are metrics/tracing updated if behaviour changes?
- Are failure modes diagnosable?
- Are timeouts/retries/backoff reasonable and evidenced?

#### 2I. Performance and resource use

- Any new loops, queries, or network calls: are they efficient?
- Any potential N+1, unbounded operations, or excessive memory usage?
- Are caches or batching used where appropriate (only if already established patterns exist)?

#### 2J. Build, CI, and tooling

- Do changes affect build scripts, CI workflows, or developer tooling?
- Are lockfiles/manifests updated consistently?
- Are generated files avoided unless required?

#### 2K. Documentation and review hygiene

- Do docs need updating (README, runbooks, architecture docs)?
- Are changelog/release notes needed (if the repo uses them)?
- Are commit messages/PR description clear enough for future readers?

### 3) Write the review file (required)

Write all review output to:

- `docs/prompt-reports/pr-review-YYYYMMDD.report.md` (use today's date)

If the file exists, append a new section:

- `## Review update – YYYY-MM-DD – hh:mm:ss`

and include:

- Newly changed areas since the last review
- ✅ Resolved findings (with evidence)
- 🔴 Remaining findings (still present)
- 🆕 New findings introduced by new commits

### 4) Review output format (use emojis for quick scanning)

Structure the review content using these sections:

- **✅ Good practices** — what is done well (keep this brief but real)
- **🔴 Must-fix** — issues that should block merge
- **🟡 Should-fix** — important improvements to consider before merge
- **🟢 Nice-to-have** — optional improvements / polish
- **❓ Questions** — anything that needs author clarification
- **📌 Follow-ups** — suggested next steps (tests, docs, ADRs)

For each item, include:

- What you observed and why it matters
- A specific recommendation
- Evidence (path + symbol/config key)

Use this snippet for each significant finding:

```markdown
### {finding title}

{what you observed and why it matters}

**Recommendation**

- {specific change to make}

**Evidence**

- Evidence: [/path/to/file](/path/to/file#L10-L40) - {symbol/config key}
- Evidence: Unknown from code – {suggested action}
```

---

## Output requirements 📋

- Be precise and constructive.
- Prefer specific, small actionable recommendations.
- Do not speculate; use **Unknown from code – {suggested action}** when evidence is missing.
- Use the same component names as in `component-*.md`.
- Include a **Last Amended** footer in the review file.

---

> **Version**: 1.3.11
> **Last Amended**: 2026-02-20
