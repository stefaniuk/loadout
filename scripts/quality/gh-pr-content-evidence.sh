#!/bin/bash

set -euo pipefail

# Generate a bounded evidence report for crafting PR content.
#
# Usage:
#   $ ./scripts/quality/gh-pr-content-evidence.sh
#   $ PR_REF=123 TOP_N_FILES=30 PER_FILE_CAP=600 ./scripts/quality/gh-pr-content-evidence.sh
#
# Output:
#   docs/prompt-reports/gh-pr-content-diff-YYYYMMDD-<slug>.report.txt
#
# The report captures commit log, stat, dirstat, top-N per-file diffs (capped),
# and any pending staged/unstaged changes.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

_date=$(date -u +%Y%m%d)
_pr_ref=${PR_REF:-}
_pr_num=$( (command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1 \
            && gh pr view ${_pr_ref:+"$_pr_ref"} --json number --jq .number) 2>/dev/null || true )
if [[ -n "$_pr_num" ]]; then
  _slug="pr-$_pr_num"
else
  _slug=$(git rev-parse --abbrev-ref HEAD | tr '/' '-' | tr -cd 'A-Za-z0-9_-')
fi
_report="docs/prompt-reports/gh-pr-content-diff-${_date}-${_slug}.report.txt"
_top_n=${TOP_N_FILES:-20}
_per_file_cap=${PER_FILE_CAP:-400}

mkdir -p "$(dirname "$_report")"
: > "$_report"

# Warn if report is not gitignored.
if ! git check-ignore -q "$_report" 2>/dev/null; then
  printf '\n>>> WARNING: %s is not gitignored; add it to .gitignore.\n' "$_report" >> "$_report"
fi

# Ensure main ref exists locally.
if ! git show-ref --verify --quiet refs/heads/main; then
  printf '\n>>> %s\n' "git fetch origin main:main" >> "$_report"
  git fetch origin main:main >> "$_report" 2>&1 || true
fi

# Cheap context.
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

# Capture one file's diff, capped.
capture_file() {
  local label=$1 path=$2
  shift 2
  printf '\n--- %s: %s ---\n' "$label" "$path" >> "$_report"
  git --no-pager diff "$@" -- "$path" \
    | awk -v cap="$_per_file_cap" -v file="$path" '
        { lines++; if (lines <= cap) print }
        END {
          if (lines > cap) {
            printf "\n[...truncated: %d more lines for %s; rerun with PER_FILE_CAP=%d or git diff main...HEAD -- %s for full content...]\n",
              lines - cap, file, lines, file
          }
        }' >> "$_report"
}

# Top-N per-file diffs vs main by change size.
_top_files=$(
  git diff --numstat main...HEAD \
    | awk '$1 != "-" && $2 != "-" { print ($1 + $2), $3 }' \
    | sort -rn \
    | head -n "$_top_n" \
    | awk '{ $1=""; sub(/^ /, ""); print }'
)

if [[ -n "$_top_files" ]]; then
  printf '\n>>> top %s files vs main by change size (per file, capped %s lines each)\n' \
    "$_top_n" "$_per_file_cap" >> "$_report"
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    capture_file "branch-vs-main" "$f" main...HEAD --unified=3
  done <<< "$_top_files"
else
  printf '\n>>> no committed differences between main and HEAD\n' >> "$_report"
fi

# Pending working-tree work.
_staged=$(git diff --cached --name-only)
_unstaged=$(git diff --name-only)

if [[ -n "$_staged" ]]; then
  printf '\n>>> staged content (pending; per file, capped %s lines each)\n' "$_per_file_cap" >> "$_report"
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    capture_file "staged-pending" "$f" --cached --unified=3
  done <<< "$_staged"
fi
if [[ -n "$_unstaged" ]]; then
  printf '\n>>> unstaged content (pending; per file, capped %s lines each)\n' "$_per_file_cap" >> "$_report"
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    capture_file "unstaged-pending" "$f" --unified=3
  done <<< "$_unstaged"
fi

printf '\nReport: %s (%s bytes, %s lines)\n' \
  "$_report" "$(wc -c < "$_report")" "$(wc -l < "$_report")"
