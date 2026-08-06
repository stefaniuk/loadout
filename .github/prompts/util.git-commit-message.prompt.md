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
3. A concise **Description** (Markdown) capturing intent and rationale (when evidenced), not just a restatement of file changes.

### Scope policy (non-negotiable) 🎯

The commit message describes **the next commit**, so the authoritative evidence is, in order of precedence:

1. **Staged changes** (`git diff --cached`) - primary evidence whenever they exist.
2. **Unstaged working-tree changes** (`git diff`) - used only when nothing is staged; the output must note that nothing is staged yet.
3. **Branch-wide diff** (`main...HEAD`) - used **only** when there are no staged or unstaged changes at all, in which case the output must state explicitly that it summarises the branch history rather than a new commit.

The branch-wide diff (`main...HEAD`) is otherwise **context only**: stat + recent commit subjects, used to evaluate the current branch name and mirror tone. Never use it as the source of truth for the commit summary, and never expand it into a full per-line diff.

---

## Discovery (run before writing) 🔍

### A. Capture a bounded evidence report

Run the labelled batch below **once** from the repository root. It writes a small, capped report to `docs/prompt-reports/git-commit-message-diff-YYYYMMDD-<slug>.report.txt` (where `<slug>` is the sanitised current branch name, so per-branch runs do not overwrite each other). Per-file diffs are capped to keep large changes from blowing up the context.

```bash
_date=$(date -u +%Y%m%d)
_slug=$(git rev-parse --abbrev-ref HEAD | tr '/' '-' | tr -cd 'A-Za-z0-9_-')
_report="docs/prompt-reports/git-commit-message-diff-$_date-$_slug.report.txt"
mkdir -p "$(dirname "$_report")"
: > "$_report"

# Make sure main ref exists locally (for branch naming + tone only).
if ! git show-ref --verify --quiet refs/heads/main; then
  printf '\n>>> %s\n' "git fetch origin main:main" >> "$_report"
  git fetch origin main:main >> "$_report" 2>&1 || true
fi

# Cheap context - always run.
for cmd in \
  "git rev-parse --abbrev-ref HEAD" \
  "git status -sb" \
  "git log -5 --oneline" \
  "git diff --cached --stat" \
  "git diff --stat" \
  "git diff --stat main...HEAD"; do
    printf '\n>>> %s\n' "$cmd" >> "$_report"
    eval "$cmd" >> "$_report" 2>&1
done

# Primary evidence: staged content (capped per file). Falls back to unstaged
# if nothing is staged. Branch diff is NEVER expanded here.
_staged=$(git diff --cached --name-only)
_unstaged=$(git diff --name-only)
_per_file_cap=${PER_FILE_CAP:-400}

# Capture one file's diff, capped at $_per_file_cap lines, appending an
# explicit truncation marker so the agent knows when to drill in. Uses awk
# instead of `head` to avoid SIGPIPE on the upstream git process.
_capture() { # args: <label> <path> <git-diff-args...>
  local label=$1 path=$2; shift 2
  printf '\n--- %s: %s ---\n' "$label" "$path" >> "$_report"
  git --no-pager diff "$@" -- "$path" \
    | awk -v cap="$_per_file_cap" -v file="$path" '
        { lines++; if (lines <= cap) print; }
        END {
          if (lines > cap) {
            printf "\n[...truncated: %d more lines for %s; rerun with PER_FILE_CAP=%d or `git --no-pager diff -- %s` for full content...]\n",
              lines - cap, file, lines, file
          }
        }' >> "$_report"
}

if [ -n "$_staged" ]; then
  printf '\n>>> staged content (per file, capped %s lines each)\n' "$_per_file_cap" >> "$_report"
  printf '%s\n' "$_staged" | while IFS= read -r f; do
    [ -z "$f" ] && continue
    _capture staged "$f" --cached --unified=3
  done
elif [ -n "$_unstaged" ]; then
  printf '\n>>> unstaged content (no staged changes; per file, capped %s lines each)\n' "$_per_file_cap" >> "$_report"
  printf '%s\n' "$_unstaged" | while IFS= read -r f; do
    [ -z "$f" ] && continue
    _capture unstaged "$f" --unified=3
  done
else
  printf '\n>>> no staged or unstaged changes - falling back to branch summary only\n' >> "$_report"
fi

printf '\nReport → %s (%s bytes, %s lines)\n' \
  "$_report" "$(wc -c < "$_report")" "$(wc -l < "$_report")"
```

After the script completes, **read `$_report`** (the per-branch, per-day file written above) as the authoritative evidence. The report is bounded by design; a single read is sufficient and you must not re-run `git diff main...HEAD` for full content.

1. Confirm branch state from `git rev-parse --abbrev-ref HEAD` and `git status -sb`.
2. Determine the commit scope using the Scope policy above:
   - Staged stat + staged content → primary evidence.
   - Unstaged stat + unstaged content (only if nothing is staged) → primary evidence; note the lack of staging.
   - Otherwise use `git diff --stat main...HEAD` and recent log → branch-summary mode.
3. If the report shows no staged, unstaged, **and** no `main...HEAD` differences, output **"No changes detected – nothing to commit."** and stop.
4. Mirror recent commit tone using `git log -5 --oneline`: match the prefix style (`type(scope):` vs `type:`), the summary voice (imperative, lowercase, no trailing period), and reuse a scope token that already appears in recent history when one fits.
5. If a per-file capped diff was truncated (look for the `[...truncated: N more lines...]` marker), and you genuinely need more lines for one specific file, either rerun the script with `PER_FILE_CAP=<n>` or request only that file with `git --no-pager diff --cached -- <path>` (or unstaged equivalent). Do not expand more than necessary, and never expand the branch diff.

### B. Classify the change

1. Determine the dominant change type for Conventional Commits (`feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `build`, `ci`, `perf`, `revert`) from the **in-scope** changes only (staged > unstaged > branch fallback).
2. Identify a `scope` by using the most relevant component, package, or directory touched in those changes (prefer values already used in the repo; fall back to a short directory name if unsure).
3. Note any breaking changes or notable follow-ups visible in the in-scope diff.
4. **Multi-thread split heuristic.** If the in-scope changes span two or more clearly unrelated top-level areas (for example a skill update _and_ a CI/tooling pin) with no shared intent, recommend splitting in **Highlights** and still emit one combined Conventional Commit line covering both threads.

---

## Steps 👣

### 1) Extract key evidence

Work only from the in-scope changes determined by the Scope policy (staged > unstaged > branch fallback).

1. List the primary files/folders touched **in the in-scope changes** (not the whole branch).
2. Summarise behavioural changes (APIs, CLIs, jobs, infra, docs) in plain language.
3. Capture side effects (tests added, config changes, dependency updates).
4. Record unknowns explicitly (**Unknown from code – {action}**).
5. Note the current branch state (feature branch vs `main`/detached). If already on a feature branch, confirm whether its name matches the dominant change and suggest an improvement if not; otherwise, craft a new branch slug using `scope-short-description`. Branch-name suitability may reference the branch-wide stat/log from the report; the commit message itself must not.

### 2) Craft the Conventional Commit line

Follow these rules:

1. Format: `type(scope): summary`.
2. `summary` ≤ 72 characters, present tense, no trailing punctuation.
3. Mention breaking changes by appending `!` after the type/scope (`feat(api)!: ...`) and list details in the summary block.
4. Ensure the summary is specific (e.g. `feat(auth): add SSO callback validator`).
5. If multiple change types exist, pick the most user-facing; note secondary changes in the summary section.

### 3) Write the change summary (copy-ready)

Produce a short Markdown block containing:

- **Overview:** 1–2 sentences describing the change impact.
- **Highlights:** Bullet list (max 7) with evidence-backed points referencing files/components.
- **Testing:** Commands or checks run (or **Unknown from code – run {command}**). Do not print that section at all if no testing was possible.
- **Breaking Changes:** Explicit call-outs if any. Do not print that section at all if none exist.

### 4) Compile the final output (copy-ready template)

Return content exactly in this shape for easy copy/paste:

```markdown
## Branch Name

{branch name}

## Commit Message

{single line of commit message}

## Description

**Overview**

...

**Highlights**

- ...

**Testing**

- ...

**Breaking Changes**

- ...
```

### 5) Write the output file (required)

- Write the same content emitted in step 4 to `docs/prompt-reports/git-commit-message-YYYYMMDD-<slug>.report.md` (compute `<slug>` exactly as in §A: the sanitised current branch name).
- If the file exists, overwrite it with the updated content.
- Include a **Generated** footer with the current UTC timestamp.

## Output requirements 📋

- Write the generated content to `docs/prompt-reports/git-commit-message-YYYYMMDD-<slug>.report.md` (slug as derived in §A) **and** print the same content inline for copy/paste.
- Ground every statement in the **in-scope** diff (staged > unstaged > branch fallback); if evidence is missing, record **Unknown from code – {suggested action}**.
- When using the branch-fallback mode, the **Overview** must state explicitly that the message summarises the branch because no staged or unstaged changes were present.
- When unstaged-only mode is used, the **Overview** must note that nothing is staged yet and suggest `git add` for the relevant files.
- Ensure the branch suggestion covers both cases: re-affirm or improve the current feature branch name, or propose a new branch when working directly on `main`/detached `HEAD`.
- Prefer British English and concise, active phrasing.
- If multiple commits might be useful, mention that under **Highlights**, but still emit one Conventional Commit line for the in-scope changes.
- Do not invent scopes, behaviours, or tests; rely solely on repository evidence.
- Do not expand the full branch diff; the bounded report is sufficient.
- Ensure the final output matches the template exactly so it is ready to copy/paste.
