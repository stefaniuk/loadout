#!/bin/bash

set -euo pipefail

# Generate a bounded evidence report for crafting a conventional commit message.
#
# Usage:
#   $ .github/prompts/util.git-commit-message.sh
#   $ PER_FILE_CAP=800 .github/prompts/util.git-commit-message.sh
#   $ BASE_REF=long-lived-branch .github/prompts/util.git-commit-message.sh
#
# Output:
#   .copilot/analysis/git-commit-message-diff-YYYYMMDD-<slug>.report.txt
#
# The base branch (used only for branch-naming context and tone, never as
# commit evidence) is not assumed to be `main`: it is taken from BASE_REF if
# set, otherwise an already-open PR's actual base ref, otherwise the
# repository's default branch, otherwise `origin/HEAD`, falling back to
# `main` only if none of these can be detected. This mirrors the base-branch
# detection in util.gh-pr-content.sh so tone/context is drawn from the branch
# this work will actually be merged into (for example a long-running
# integration/stacked-PR trunk), not always the repo's nominal default -
# which can differ even when a PR is already open against that trunk.
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

# Detect the base branch: explicit override, then an open PR's actual base,
# then repo default branch, then origin/HEAD, falling back to 'main' as a
# last resort. _base_source records which tier resolved it, for transparency
# in the report.
_base_ref=${BASE_REF:-}
_base_source=""
[[ -n "$_base_ref" ]] && _base_source="BASE_REF override"
if [[ -z "$_base_ref" ]]; then
  _base_ref=$( (command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1 \
                && gh pr view --json baseRefName --jq .baseRefName) 2>/dev/null || true )
  [[ -n "$_base_ref" ]] && _base_source="gh pr baseRefName"
fi
if [[ -z "$_base_ref" ]]; then
  _base_ref=$( (command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1 \
                && gh repo view --json defaultBranchRef --jq .defaultBranchRef.name) 2>/dev/null || true )
  [[ -n "$_base_ref" ]] && _base_source="repo default branch"
fi
if [[ -z "$_base_ref" ]]; then
  _base_ref=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##') || true
  [[ -n "$_base_ref" ]] && _base_source="origin/HEAD"
fi
if [[ -z "$_base_ref" ]]; then
  _base_ref="main"
  _base_source="fallback default"
fi

# Make sure the base ref exists locally (for branch naming + tone only).
if ! git rev-parse --verify --quiet "${_base_ref}^{commit}" >/dev/null 2>&1; then
  printf '\n>>> %s\n' "git fetch origin $_base_ref:$_base_ref" >> "$_report"
  git fetch origin "$_base_ref:$_base_ref" >> "$_report" 2>&1 || true
fi

printf '\n>>> base branch detected: %s (source: %s, context/tone only - never commit evidence)\n' "$_base_ref" "$_base_source" >> "$_report"

# Cheap context.
for cmd in \
  "git rev-parse --abbrev-ref HEAD" \
  "git status -sb" \
  "git log -5 --oneline" \
  "git diff --cached --stat" \
  "git diff --stat $_base_ref...HEAD"; do
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
