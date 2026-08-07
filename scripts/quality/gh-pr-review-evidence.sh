#!/bin/bash

set -euo pipefail

# Generate bounded evidence reports for PR review: intent + diff.
#
# Usage:
#   $ ./scripts/quality/gh-pr-review-evidence.sh
#   $ PR_REF=123 TOP_N_FILES=30 PER_FILE_CAP=600 ./scripts/quality/gh-pr-review-evidence.sh
#
# Output:
#   docs/prompt-reports/gh-pr-review-intent-YYYYMMDD-<slug>.report.txt
#   docs/prompt-reports/gh-pr-review-diff-YYYYMMDD-<slug>.report.txt
#
# The intent report captures PR metadata (title, body, labels) or falls back
# to commit log. The diff report captures stat, dirstat, and top-N per-file
# diffs (capped).

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

_date=$(date -u +%Y%m%d)
_pr_ref=${PR_REF:-}
_intent_body_cap=${INTENT_BODY_CAP:-400}
_top_n=${TOP_N_FILES:-20}
_per_file_cap=${PER_FILE_CAP:-400}

# Derive slug: PR number if known, otherwise sanitised branch name.
_pr_num=$( (command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1 \
            && gh pr view ${_pr_ref:+"$_pr_ref"} --json number --jq .number) 2>/dev/null || true )
if [[ -n "$_pr_num" ]]; then
  _slug="pr-$_pr_num"
else
  _slug=$(git rev-parse --abbrev-ref HEAD | tr '/' '-' | tr -cd 'A-Za-z0-9_-')
fi

_intent_file="docs/prompt-reports/gh-pr-review-intent-${_date}-${_slug}.report.txt"
_report="docs/prompt-reports/gh-pr-review-diff-${_date}-${_slug}.report.txt"
_review_file="docs/prompt-reports/gh-pr-review-${_date}-${_slug}.report.md"

mkdir -p "$(dirname "$_intent_file")"
: > "$_intent_file"
: > "$_report"

# --- Part 1: Intent capture ---

truncate_body() {
  awk -v cap="$_intent_body_cap" '
    { lines++; if (lines <= cap) print }
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
    | truncate_body >> "$_intent_file"; then
    _gh_ok=1
    printf '\n>>> source: gh pr view %s\n' "${_pr_ref:-(current branch)}" >> "$_intent_file"
  fi
fi

if [[ "$_gh_ok" -eq 0 ]]; then
  {
    printf '\n>>> gh unavailable or PR not found; using working-tree fallback\n'
    printf '\n--- branch ---\n'
    git rev-parse --abbrev-ref HEAD 2>&1
    printf '\n--- first commit body (often the headline intent) ---\n'
    git log --no-merges --reverse main..HEAD --pretty=format:'%h%n%s%n%n%b%n---' -n 1 \
      | truncate_body
    printf '\n--- subsequent commit subjects ---\n'
    git log --no-merges --reverse main..HEAD --skip=1 --pretty=format:'%h %s' 2>&1
  } >> "$_intent_file"
  for _f in CHANGELOG.md docs/CHANGELOG.md .github/pull_request_template.md; do
    if [[ -f "$_f" ]]; then
      printf '\n--- %s (capped at %s lines) ---\n' "$_f" "$_intent_body_cap" >> "$_intent_file"
      truncate_body < "$_f" >> "$_intent_file"
    fi
  done
fi

printf '\nIntent: %s (%s bytes)\n' "$_intent_file" "$(wc -c < "$_intent_file")"

# --- Part 2: Diff evidence ---

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

printf '\nDiff report: %s (%s bytes, %s lines)\n' \
  "$_report" "$(wc -c < "$_report")" "$(wc -l < "$_report")"
printf 'Review file: %s\n' "$_review_file"
