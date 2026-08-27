#!/bin/bash

set -euo pipefail

# Generate a bounded evidence report for crafting a conventional commit message.
#
# Usage:
#   $ .github/prompts/util.git-commit-message.sh
#   $ PER_FILE_CAP=800 .github/prompts/util.git-commit-message.sh
#
# Output:
#   .copilot/analysis/git-commit-message-diff-YYYYMMDD-<slug>.report.txt
#
# The report captures git status, recent log, stat summaries, and per-file
# diffs (capped) for the staged changes only. Unstaged working-tree changes
# are deliberately excluded. Branch diffs are never expanded into full content.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

ANALYSIS_DIR=".copilot/analysis"
_date=$(date -u +%Y%m%d)
_slug=$(git rev-parse --abbrev-ref HEAD | tr '/' '-' | tr -cd 'A-Za-z0-9_-')
_report="${ANALYSIS_DIR}/git-commit-message-diff-${_date}-${_slug}.report.txt"
_per_file_cap=${PER_FILE_CAP:-400}

mkdir -p "$(dirname "$_report")"
: > "$_report"

# Make sure main ref exists locally (for branch naming + tone only).
if ! git show-ref --verify --quiet refs/heads/main; then
  printf '\n>>> %s\n' "git fetch origin main:main" >> "$_report"
  git fetch origin main:main >> "$_report" 2>&1 || true
fi

# Cheap context.
for cmd in \
  "git rev-parse --abbrev-ref HEAD" \
  "git status -sb" \
  "git log -5 --oneline" \
  "git diff --cached --stat" \
  "git diff --stat main...HEAD"; do
    printf '\n>>> %s\n' "$cmd" >> "$_report"
    eval "$cmd" >> "$_report" 2>&1
done

# Capture one file's diff, capped at $_per_file_cap lines.
capture_file() {
  local label=$1 path=$2
  shift 2
  printf '\n--- %s: %s ---\n' "$label" "$path" >> "$_report"
  git --no-pager diff "$@" -- "$path" \
    | awk -v cap="$_per_file_cap" -v file="$path" '
        { lines++; if (lines <= cap) print }
        END {
          if (lines > cap) {
            printf "\n[...truncated: %d more lines for %s; rerun with PER_FILE_CAP=%d or git diff -- %s for full content...]\n",
              lines - cap, file, lines, file
          }
        }' >> "$_report"
}

# Primary (and only) commit evidence: staged changes. Unstaged working-tree
# changes are deliberately excluded - if it is not staged it is not committed.
_staged=$(git diff --cached --name-only)

if [[ -n "$_staged" ]]; then
  printf '\n>>> staged content (per file, capped %s lines each)\n' "$_per_file_cap" >> "$_report"
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    capture_file staged "$f" --cached --unified=3
  done <<< "$_staged"
else
  printf '\n>>> no staged changes - nothing to commit\n' >> "$_report"
fi

printf '\nReport: %s (%s bytes, %s lines)\n' \
  "$_report" "$(wc -c < "$_report")" "$(wc -l < "$_report")"
