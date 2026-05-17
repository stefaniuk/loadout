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
    jq -n \
      --arg event "PostToolUse" \
      --arg context "$lint_output" \
      '{hookSpecificOutput: {hookEventName: $event, additionalContext: $context}}'
  fi

  return 0
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
