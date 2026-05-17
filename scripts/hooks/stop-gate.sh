#!/bin/bash

set -euo pipefail

# Stop hook script that runs `make lint` and `make test` before allowing the
# agent to complete. Blocks completion if either quality gate fails.
#
# Usage:
#   $ echo '{}' | ./stop-gate.sh
#
# Exit codes:
#   0 - Hook completed successfully (agent may or may not be blocked)
#
# Notes:
#   1) This script is invoked by VS Code Agent hooks. Do not run interactively.
#   2) Requires jq and make in the environment.
#   3) Uses a re-entry guard to prevent infinite loops.
#   4) Diagnostics: see ${COPILOT_PROMPT_LOG_DIR:-~/.local/state/copilot-prompts}/{hooks,errors}.log

# ==============================================================================

# shellcheck disable=SC1091
source "$(dirname "$0")/_common.sh"

function main() {

  hook_init_diagnostics "Stop"

  cd "$(git rev-parse --show-toplevel)"

  local input
  input=$(cat)

  # Re-entry guard: if this hook is already active, allow completion
  local hook_active
  hook_active=$(echo "$input" | jq -r '.stop_hook_active // empty')
  if [[ "$hook_active" == "true" ]]; then
    echo '{}'
    return 0
  fi

  local lint_output
  local lint_exit=0
  lint_output=$(make lint 2>&1) || lint_exit=$?

  if [[ $lint_exit -ne 0 ]]; then
    emit-block "make lint failed" "$lint_output"
    return 0
  fi

  local test_output
  local test_exit=0
  test_output=$(make test 2>&1) || test_exit=$?

  if [[ $test_exit -ne 0 ]]; then
    emit-block "make test failed" "$test_output"
    return 0
  fi

  # Both gates passed — allow completion
  echo '{}'

  return 0
}

# Emit a blocking response with the given reason and detail.
# Arguments:
#   $1 - reason summary
#   $2 - detail output
function emit-block() {

  local reason="$1"
  local detail="$2"

  jq -n \
    --arg event "Stop" \
    --arg decision "block" \
    --arg reason "$reason" \
    --arg detail "$detail" \
    '{hookSpecificOutput: {hookEventName: $event, decision: $decision, reason: $reason, additionalContext: $detail}}'

  return 0
}

# ==============================================================================

main "$@"

exit 0
