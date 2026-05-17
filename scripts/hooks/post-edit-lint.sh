#!/bin/bash

set -euo pipefail

# PostToolUse hook script that runs `make lint` after file-editing tool calls.
# Reads hook context from stdin JSON, decides whether to lint, and outputs
# hook-compatible JSON on stdout.
#
# Usage:
#   $ echo '{"toolName":"create_file"}' | ./post-edit-lint.sh
#
# Exit codes:
#   0 - Hook completed successfully
#
# Notes:
#   1) This script is invoked by VS Code Agent hooks. Do not run interactively.
#   2) Requires jq and make in the environment.
#   3) Diagnostics: see ${COPILOT_PROMPT_LOG_DIR:-~/.local/state/copilot-prompts}/{hooks,errors}.log

# ==============================================================================

# shellcheck disable=SC1091
source "$(dirname "$0")/_common.sh"

function main() {

  hook_init_diagnostics "PostToolUse"

  cd "$(git rev-parse --show-toplevel)"

  local input
  input=$(cat)

  local tool_name
  tool_name=$(echo "$input" | jq -r '.toolName // .tool_name // empty')

  if ! is-edit-tool "$tool_name"; then
    echo '{}'
    return 0
  fi

  local lint_output
  local lint_exit=0
  lint_output=$(make lint 2>&1) || lint_exit=$?

  if [[ $lint_exit -eq 0 ]]; then
    echo '{}'
  else
    local truncated
    truncated=$(truncate-output "$lint_output")
    jq -n \
      --arg event "PostToolUse" \
      --arg context "$truncated" \
      '{hookSpecificOutput: {hookEventName: $event, additionalContext: $context}}'
  fi

  return 0
}

# Truncate long lint output so the model context isn't flooded after every
# edit. Keeps the last MAX_LINT_OUTPUT_LINES lines (default 80) and prefixes
# a marker line if anything was dropped. The full log remains in the user's
# terminal/CI output where `make lint` originally ran.
# Arguments:
#   $1 - full output string
function truncate-output() {

  local output="$1"
  local max_lines="${MAX_LINT_OUTPUT_LINES:-80}"
  local total
  total=$(printf '%s\n' "$output" | wc -l | tr -d ' ')
  if (( total <= max_lines )); then
    printf '%s' "$output"
    return 0
  fi
  local dropped=$(( total - max_lines ))
  printf '...(truncated %s earlier line(s); showing last %s)...\n' "$dropped" "$max_lines"
  printf '%s\n' "$output" | tail -n "$max_lines"
}

# Check whether the given tool name is a file-editing tool.
# Arguments:
#   $1 - tool name
function is-edit-tool() {

  local tool="$1"
  case "$tool" in
    create_file|replace_string_in_file|multi_replace_string_in_file|edit_notebook_file)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# ==============================================================================

main "$@"

exit 0
