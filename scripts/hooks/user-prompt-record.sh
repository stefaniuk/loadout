#!/bin/bash

set -euo pipefail

# UserPromptSubmit hook script that records each user prompt to a per-user
# central daily log so a single chronological view spans every repository the
# user works on. Each record carries the originating repository, branch, and
# working directory.
#
# Reads hook context from stdin JSON. The prompt text is expected under
# `.prompt` or `.userPrompt`. Outputs an empty hook envelope on stdout.
#
# Log location (first match wins):
#   1. $COPILOT_PROMPT_LOG_DIR  (explicit override; supports per-repo opt-in)
#   2. $XDG_STATE_HOME/copilot-prompts
#   3. $HOME/.local/state/copilot-prompts
#
# Record schema (one JSON object per line):
#   { "timestamp": "<ISO8601 UTC>",
#     "repo":      "<git remote origin URL, or basename of cwd if none>",
#     "branch":    "<current branch, or empty>",
#     "cwd":       "<absolute working directory>",
#     "prompt":    "<verbatim user prompt>" }
#
# Usage:
#   $ echo '{"prompt":"Plan the next feature"}' | ./user-prompt-record.sh
#
# Exit codes:
#   0 - Hook completed successfully (always; failures are logged silently)

# ==============================================================================

# shellcheck disable=SC1091
source "$(dirname "$0")/_common.sh"

function main() {

  hook_init_diagnostics "UserPromptSubmit"

  local log_dir
  log_dir="$(hook_log_dir)"

  local input
  input=$(cat)

  local prompt
  prompt=$(echo "$input" | jq -r '.prompt // .userPrompt // empty')

  if [[ -z "$prompt" ]]; then
    # Record the raw payload once so we can inspect the actual schema VS Code
    # delivers if the expected field is ever missing.
    hook_diag "empty prompt; raw input: $input"
    echo '{}'
    return 0
  fi

  local log_file
  log_file="${log_dir}/$(date +%Y-%m-%d).jsonl"

  # Capture originating repository context
  local cwd
  cwd="$(pwd)"

  local repo
  repo="$(git remote get-url origin 2>/dev/null || true)"
  if [[ -z "$repo" ]]; then
    repo="$(basename "$cwd")"
  fi

  local branch
  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"

  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  jq -nc \
    --arg ts "$ts" \
    --arg repo "$repo" \
    --arg branch "$branch" \
    --arg cwd "$cwd" \
    --arg prompt "$prompt" \
    '{timestamp: $ts, repo: $repo, branch: $branch, cwd: $cwd, prompt: $prompt}' \
    >>"$log_file"

  echo '{}'
}

main "$@"
