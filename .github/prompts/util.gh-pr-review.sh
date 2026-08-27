#!/bin/bash

set -euo pipefail

# Generate bounded evidence reports for PR review: intent + diff.
#
# Usage:
#   $ .github/prompts/util.gh-pr-review.sh
#   $ PR_REF=123 TOP_N_FILES=30 PER_FILE_CAP=600 .github/prompts/util.gh-pr-review.sh
#   $ BASE_REF=develop .github/prompts/util.gh-pr-review.sh
#
# Output:
#   .copilot/analysis/gh-pr-review-intent-YYYYMMDD-<slug>.report.txt
#   .copilot/analysis/gh-pr-review-diff-YYYYMMDD-<slug>.report.txt
#
# The base branch is not assumed to be `main`: it is taken from BASE_REF if set,
# otherwise from the PR's actual base ref, otherwise from the repository's
# default branch, falling back to `main` only if none of these can be detected.
#
# The intent report captures PR metadata (title, body, labels) or falls back
# to commit log. The diff report captures stat, dirstat, top-N per-file diffs
# (capped), and any staged changes when the current branch is the PR head.
# Unstaged working-tree changes are deliberately excluded.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

ANALYSIS_DIR=".copilot/analysis"
_date=$(date -u +%Y%m%d)
_pr_ref=${PR_REF:-}
_intent_body_cap=${INTENT_BODY_CAP:-400}
_top_n=${TOP_N_FILES:-20}
_per_file_cap=${PER_FILE_CAP:-400}

# Derive slug: PR number if known, otherwise sanitised branch name.
# One combined call for number + base + head avoids extra gh round-trips.
_pr_json=$( (command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1 \
            && gh pr view ${_pr_ref:+"$_pr_ref"} --json number,baseRefName,headRefName \
            --jq '(.number|tostring) + "\t" + .baseRefName + "\t" + .headRefName') 2>/dev/null || true )
if [[ "$_pr_json" == *$'\t'*$'\t'* ]]; then
  _pr_num=${_pr_json%%$'\t'*}
  _pr_rest=${_pr_json#*$'\t'}
  _pr_base=${_pr_rest%%$'\t'*}
  _pr_head=${_pr_rest#*$'\t'}
else
  _pr_num=""; _pr_base=""; _pr_head=""
fi
if [[ -n "$_pr_num" ]]; then
  _slug="pr-$_pr_num"
else
  _slug=$(git rev-parse --abbrev-ref HEAD | tr '/' '-' | tr -cd 'A-Za-z0-9_-')
fi

# Detect the base branch: explicit override, then PR's actual base, then repo
# default branch, then origin/HEAD, falling back to 'main' as a last resort.
# _base_source records which tier resolved it, for transparency in the report.
_base_ref=${BASE_REF:-}
_base_source=""
if [[ -n "$_base_ref" ]]; then
  _base_source="BASE_REF override"
elif [[ -n "$_pr_base" ]]; then
  _base_ref="$_pr_base"
  _base_source="gh pr baseRefName"
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

_intent_file="${ANALYSIS_DIR}/gh-pr-review-intent-${_date}-${_slug}.report.txt"
_report="${ANALYSIS_DIR}/gh-pr-review-diff-${_date}-${_slug}.report.txt"
_review_file="${ANALYSIS_DIR}/gh-pr-review-${_date}-${_slug}.report.md"

mkdir -p "$(dirname "$_intent_file")"
: > "$_intent_file"
: > "$_report"

# Resolve and validate the base ref up front so both intent and diff capture
# can rely on it. Diagnostics are written to the diff report.
if ! git check-ignore -q "$_report" 2>/dev/null; then
  printf '\n>>> WARNING: %s is not gitignored; add it to .gitignore.\n' "$_report" >> "$_report"
fi

# Ensure the base ref resolves locally; fetch it if it only exists on origin.
# rev-parse (not show-ref) so a BASE_REF commit SHA is accepted without a fetch.
if ! git rev-parse --verify --quiet "${_base_ref}^{commit}" >/dev/null 2>&1; then
  printf '\n>>> %s\n' "git fetch origin $_base_ref:$_base_ref" >> "$_report"
  git fetch origin "$_base_ref:$_base_ref" >> "$_report" 2>&1 || true
fi

printf '\n>>> base branch detected: %s (source: %s)\n' "$_base_ref" "$_base_source" >> "$_report"

# Stop with an actionable message if the base still cannot be resolved, rather
# than letting later git commands abort with a raw fatal error mid-report.
if ! git rev-parse --verify --quiet "${_base_ref}^{commit}" >/dev/null 2>&1; then
  printf '\n>>> ERROR: base ref %s cannot be resolved locally or on origin.\n' "$_base_ref" >> "$_report"
  printf '>>> Set BASE_REF to a valid branch or commit, or fetch it first.\n' >> "$_report"
  printf 'ERROR: base ref %s cannot be resolved; see %s\n' "$_base_ref" "$_report" >&2
  exit 1
fi

# Flag a silent mismatch: an explicit override should win, but reviewers must
# know it disagrees with the PR that is actually open.
if [[ "$_base_source" == "BASE_REF override" && -n "$_pr_base" && "$_pr_base" != "$_base_ref" ]]; then
  printf '\n>>> WARNING: BASE_REF=%s overrides the open PR'"'"'s actual base %s\n' "$_base_ref" "$_pr_base" >> "$_report"
fi

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
    git log --no-merges --reverse "$_base_ref"..HEAD --pretty=format:'%h%n%s%n%n%b%n---' -n 1 \
      | truncate_body
    printf '\n--- subsequent commit subjects ---\n'
    git log --no-merges --reverse "$_base_ref"..HEAD --skip=1 --pretty=format:'%h %s' 2>&1
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

for cmd in \
  "git rev-parse --abbrev-ref HEAD" \
  "git status -sb" \
  "git rev-list --no-merges --count $_base_ref..HEAD" \
  "git log --no-merges --reverse $_base_ref..HEAD --pretty=format:'%h %an %ad %s%n%b%n---' --date=short" \
  "git diff --stat $_base_ref...HEAD" \
  "git diff --dirstat=files,1 $_base_ref...HEAD" \
  "git diff --cached --stat"; do
    printf '\n>>> %s\n' "$cmd" >> "$_report"
    eval "$cmd" >> "$_report" 2>&1
done

# Capture one file's diff, capped.
capture_file() {
  local label=$1 path=$2
  shift 2
  printf '\n--- %s: %s ---\n' "$label" "$path" >> "$_report"
  git --no-pager diff "$@" -- "$path" \
    | awk -v cap="$_per_file_cap" -v file="$path" -v base="$_base_ref" '
        { lines++; if (lines <= cap) print }
        END {
          if (lines > cap) {
            printf "\n[...truncated: %d more lines for %s; rerun with PER_FILE_CAP=%d or git diff %s...HEAD -- %s for full content...]\n",
              lines - cap, file, lines, base, file
          }
        }' >> "$_report"
}

_top_files=$(
  git diff --numstat "$_base_ref"...HEAD \
    | awk '$1 != "-" && $2 != "-" { print ($1 + $2), $3 }' \
    | sort -rn \
    | head -n "$_top_n" \
    | awk '{ $1=""; sub(/^ /, ""); print }'
)

if [[ -n "$_top_files" ]]; then
  printf '\n>>> top %s files vs %s by change size (per file, capped %s lines each)\n' \
    "$_top_n" "$_base_ref" "$_per_file_cap" >> "$_report"
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    capture_file "branch-vs-$_base_ref" "$f" "$_base_ref"...HEAD --unified=3
  done <<< "$_top_files"
else
  printf '\n>>> no committed differences between %s and HEAD\n' "$_base_ref" >> "$_report"
fi

# Staged changes count as part of the PR only when this working tree is checked
# out on the PR's head branch. Unstaged working-tree changes are always excluded.
_cur_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
if [[ -z "$_pr_head" || "$_pr_head" == "$_cur_branch" ]]; then
  _staged=$(git diff --cached --name-only)
  if [[ -n "$_staged" ]]; then
    printf '\n>>> staged content (pending on PR head branch; per file, capped %s lines each)\n' "$_per_file_cap" >> "$_report"
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      capture_file "staged-pending" "$f" --cached --unified=3
    done <<< "$_staged"
  fi
else
  printf '\n>>> staged changes skipped: current branch %s is not the PR head branch %s\n' "$_cur_branch" "$_pr_head" >> "$_report"
fi

printf '\nDiff report: %s (%s bytes, %s lines)\n' \
  "$_report" "$(wc -c < "$_report")" "$(wc -l < "$_report")"
printf 'Review file: %s\n' "$_review_file"
