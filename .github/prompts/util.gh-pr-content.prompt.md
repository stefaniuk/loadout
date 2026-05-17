---
description: Create pull request content from the current branch changes
---

**Mandatory preparation:**

- Read the [constitution](../../.specify/memory/constitution.md) and honour its non-negotiable rules.
- Read the Pull Request template at [pull_request_template.md](../pull_request_template.md) so the generated content mirrors it exactly.
- Read the technology-specific instructions **only for languages actually touched on this branch** (look at the stat in the report; do not preload every instruction file). For example [python.instructions.md](../instructions/python.instructions.md), [shell.instructions.md](../instructions/shell.instructions.md), [makefile.instructions.md](../instructions/makefile.instructions.md).
- Review the design context under `docs/prompt-reports/` only when it materially helps describe affected components.

## Goal 🎯

Craft a diff-driven pull request title and body, ready to copy/paste, that compares the current branch against `main`, summarises behaviour, lists verification evidence, and fills every section of [pull_request_template.md](../pull_request_template.md).

### Scope policy (non-negotiable) 🎯

A PR description covers **everything between `main` and `HEAD`**, including any staged or unstaged work that will land in the next commit on this branch. Evidence precedence is:

1. **Commit subjects + bodies** (`git log main..HEAD`) — primary narrative; the branch authors already wrote it.
2. **Diff overview** (`git diff --stat main...HEAD`, `--dirstat`) — structural scope and folder distribution.
3. **Top-N per-file diffs**, capped, with explicit truncation markers — for the largest or most behaviour-bearing changes.
4. **Staged / unstaged working-tree changes** — included as "pending in this branch but not yet committed" and called out separately in the description.

Never expand the full `git diff main...HEAD` into the report; it does not scale beyond a handful of commits and is rarely the cheapest evidence.

---

## Discovery (run before writing) 🔍

### A. Capture a bounded evidence report

Run the labelled batch below **once** from the repository root. It writes a small, capped report to `docs/prompt-reports/gh-pr-content-diff-YYYYMMDD-<slug>.report.txt` (where `<slug>` is `pr-<number>` when a PR is known, otherwise the sanitised branch name; per-PR runs do not overwrite each other). Per-file diffs are capped and only the top-N largest changes are inlined; everything else can be requested on demand.

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
_report="docs/prompt-reports/gh-pr-content-diff-$_date-$_slug.report.txt"
mkdir -p "$(dirname "$_report")"
: > "$_report"

# The report path should be gitignored. If it isn't, this run will leave it as
# an unstaged change that the next run could misread as evidence.
if ! git check-ignore -q "$_report" 2>/dev/null; then
  printf '\n>>> WARNING: %s is not gitignored; add it to .gitignore.\n' "$_report" >> "$_report"
fi

# Ensure main ref exists locally (PR target).
if ! git show-ref --verify --quiet refs/heads/main; then
  printf '\n>>> %s\n' "git fetch origin main:main" >> "$_report"
  git fetch origin main:main >> "$_report" 2>&1 || true
fi

# Cheap context — always run.
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

# Top-N per-file diffs vs main, capped, with truncation markers. Default 20
# files, 400 lines each — both overridable via env. Files are picked by
# absolute change size (insertions + deletions).
_top_n=${TOP_N_FILES:-20}
_per_file_cap=${PER_FILE_CAP:-400}

_top_files=$(
  git diff --numstat main...HEAD \
    | awk '$1 != "-" && $2 != "-" { print ($1 + $2), $3 }' \
    | sort -rn \
    | head -n "$_top_n" \
    | awk '{ $1=""; sub(/^ /, ""); print }'
)

# Capture one file's diff, capped, with truncation marker. awk (not head)
# avoids SIGPIPE on the upstream git process.
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

# Pending working-tree work (called out separately so the PR description can
# distinguish "committed on the branch" from "still to be committed").
_staged=$(git diff --cached --name-only)
_unstaged=$(git diff --name-only)

if [ -n "$_staged" ]; then
  printf '\n>>> staged content (pending; per file, capped %s lines each)\n' "$_per_file_cap" >> "$_report"
  printf '%s\n' "$_staged" | while IFS= read -r f; do
    [ -z "$f" ] && continue
    _capture "staged-pending" "$f" --cached --unified=3
  done
fi
if [ -n "$_unstaged" ]; then
  printf '\n>>> unstaged content (pending; per file, capped %s lines each)\n' "$_per_file_cap" >> "$_report"
  printf '%s\n' "$_unstaged" | while IFS= read -r f; do
    [ -z "$f" ] && continue
    _capture "unstaged-pending" "$f" --unified=3
  done
fi

printf '\nReport → %s (%s bytes, %s lines)\n' \
  "$_report" "$(wc -c < "$_report")" "$(wc -l < "$_report")"
```

After the script completes, **read `$_report`** (the per-PR or per-branch, per-day file written above) as the authoritative evidence. The report is bounded by design; a single read is sufficient and you must not re-run `git diff main...HEAD` for full content.

1. Confirm branch/PR target from `git rev-parse --abbrev-ref HEAD` and `git status -sb`.
2. Use the commit log block as the primary narrative — commits are already grouped, dated, and authored. Group them into change themes for the Description.
3. Use the stat and dirstat blocks for scope and folder distribution; reference them in the Description bullets.
4. Use the top-N per-file diffs to verify what the commit subjects claim. If a file you need was not in the top-N, request only that file with `git --no-pager diff main...HEAD -- <path>`. If a per-file capture was truncated (look for `[...truncated: N more lines...]`), either rerun with `PER_FILE_CAP=<n>` or request that one file unbounded. Never re-expand the whole branch diff.
5. If both committed-vs-main _and_ working-tree pending blocks are empty, stop and report **"No diff vs main – nothing to raise."**
6. Mention any pending staged/unstaged work explicitly in the Description so reviewers know the PR is not yet final.

### B. Summarise behavioural impact

1. Enumerate the files, components, and flows touched (map component names to `docs/prompt-reports/*` only when it adds value).
2. Identify change categories (bug fix, feature, refactor, documentation, tooling) and note any public interfaces affected.
3. Record configuration, schema, or dependency updates.
4. Capture open questions as **Unknown from code – {action needed}**.

### C. Quality gates & evidence

1. Do **not** rerun heavy gates by default. Check `git log` and CI artefacts for evidence that `make lint`, `make test`, or equivalents already ran in this branch's commits. Repository-level hooks may also enforce gates per-edit; if so, rely on that enforcement.
2. If no recent evidence exists and gates are needed for the PR, run them once at the end and record the exact commands, status, and any failures.
3. Note follow-up checks that must still run (for example integration tests in CI).

### D. Detect prior content and determine output file

1. Define the output file path for today, using the same `_date`/`_slug` derivation as §A:
   - `docs/prompt-reports/gh-pr-content-YYYYMMDD-<slug>.report.md` (where `<slug>` is `pr-<number>` when a PR is known, otherwise the sanitised branch name). This prevents same-day runs on different PRs/branches from overwriting each other.
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
   - Summarise behaviour changes in 1–2 sentences referencing affected components.
   - Use bullet points for specifics (inputs, outputs, contracts, migrations, configuration).
   - Reference evidence via workspace-relative Markdown links wherever possible.
3. **Populate the Context section**
   - Explain the problem statement, user need, or specification driver.
   - Call out linked specs/ADRs/tasks via Markdown links.
4. **Set the "Type of changes" checkboxes**
   - Choose `x` for every applicable category (Refactoring, New feature, Breaking change, Bug fix) based on the diff.
   - Leave non-applicable items unchecked (`[ ]`). Never delete a line from the template.
5. **Update the Checklist section**
   - Reflect actual work done (`[x]`) vs outstanding (`[ ]`).
   - Always reference whether tests/docs were updated, style guidelines were followed, and collaboration mode (pair/mob/vibe) occurred.
6. **Populate "Sensitive Information Declaration"**
   - Confirm (`[x]`) only if you verified no PII/PID/sensitive data exists in the changes; otherwise leave unchecked and note required remediation.
7. **Highlight verification evidence**
   - Mention commands run (`make lint`, `make test`, bespoke scripts) and their outcomes inside Description or Context bullets.
   - Use **Unknown from code – run {command}** where evidence is missing.
8. **Call out follow-ups**
   - If additional work is deferred, list it succinctly (for example documentation gaps, pending ADRs) under Description or Context as bullet points.
9. **Write the output file (required)**
   - Write all generated PR content to `docs/prompt-reports/gh-pr-content-YYYYMMDD-<slug>.report.md` (compute `<slug>` exactly as in §A: `pr-<number>` when a PR is known, otherwise the sanitised branch name).
   - If the file exists, overwrite it with the updated content.
   - Include a **Generated** footer with the current timestamp.

---

## Output requirements 📋

- Write the generated content to `docs/prompt-reports/gh-pr-content-YYYYMMDD-<slug>.report.md` (slug as derived in §A).
- Produce copy-ready raw Markdown using the structure below (include the title and every section in order).
- Replace placeholder ellipses with actual content; never leave template instructions in the final text.
- Use workspace-relative Markdown links (for example `[scripts/apply.sh](scripts/apply.sh#L10-L40)`).
- Maintain ASCII-only content unless evidence requires Unicode.

```markdown
# {pull request title}

## Description

{3-5 bullet points grounded in the diff}

## Context

{why the change is needed, linked artefacts/specs}

## How to test it

{steps to verify the change, commands run, evidence}

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
```

Add additional sections (for example "Testing", "Follow-ups") **only** if the template explicitly gains them in future revisions, and keep the order consistent with the template file.

---

> **Version**: 1.3.0
> **Last Amended**: 2026-05-17
