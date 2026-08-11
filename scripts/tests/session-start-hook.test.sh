#!/bin/bash
# shellcheck disable=SC2329

set -euo pipefail

# Smoke tests for the SessionStart lifecycle hook.
#
# Usage:
#   $ ./scripts/tests/session-start-hook.test.sh
#
# Arguments (provided as environment variables):
#   VERBOSE=true  # Show all the executed commands, default is 'false'

# ==============================================================================

TEMP_DIR=""

function main() {

  cd "$(git rev-parse --show-toplevel)"

  test-suite-setup
  local tests=( \
    test_session_start_script_is_executable \
    test_session_start_emits_default_superpowers_context \
    test_session_start_emits_superpowers_context_when_mode_file_requests_it \
  )
  local status=0
  for test in "${tests[@]}"; do
    {
      echo -n "$test"
      # shellcheck disable=SC2015
      $test && echo " PASS" || { echo " FAIL"; status=$((status + 1)); }
    }
  done
  echo "Total: ${#tests[@]}, Passed: $(( ${#tests[@]} - status )), Failed: $status"
  test-suite-teardown
  if [[ $status -gt 0 ]]; then
    return 1
  fi
  echo "session-start-hook: ok"
  return 0
}

# ==============================================================================

function test-suite-setup() {

  TEMP_DIR=$(mktemp -d)

  return 0
}

function test-suite-teardown() {

  if [[ -n "${TEMP_DIR}" ]] && [[ -d "${TEMP_DIR}" ]]; then
    rm -rf "${TEMP_DIR}"
  fi

  return 0
}

# ==============================================================================

function test_session_start_script_is_executable() {

  local script="scripts/hooks/session-start-cheatsheet.sh"
  [[ -f "$script" ]] || return 1
  [[ -x "$script" ]] || return 1

  return 0
}

function test_session_start_emits_default_superpowers_context() {

  local out
  out=$(echo '{}' | ./scripts/hooks/session-start-cheatsheet.sh) || return 1

  echo "$out" | jq -e '.additionalContext | contains("Superpowers cheatsheet")' > /dev/null || return 1
  echo "$out" | jq -e '.additionalContext | contains("writing-plans")' > /dev/null || return 1
  echo "$out" | jq -e '.additionalContext | contains("dispatching-parallel-agents")' > /dev/null || return 1
  ! echo "$out" | jq -e '.additionalContext | contains("/speckit-specify")' > /dev/null || return 1

  return 0
}

function test_session_start_emits_superpowers_context_when_mode_file_requests_it() {

  local mode_dir="${TEMP_DIR}/mode"
  local mode_file="${mode_dir}/workflow-mode.json"
  mkdir -p "$mode_dir"
  cat <<'EOF' > "$mode_file"
{"active":"superpowers"}
EOF

  local out
  out=$(echo '{}' | LOADOUT_WORKFLOW_MODE_FILE="$mode_file" ./scripts/hooks/session-start-cheatsheet.sh) || return 1

  echo "$out" | jq -e '.additionalContext | contains("Superpowers cheatsheet")' > /dev/null || return 1
  echo "$out" | jq -e '.additionalContext | contains("writing-plans")' > /dev/null || return 1
  echo "$out" | jq -e '.additionalContext | contains("dispatching-parallel-agents")' > /dev/null || return 1
  echo "$out" | jq -e '.additionalContext | contains("finishing-a-development-branch")' > /dev/null || return 1
  ! echo "$out" | jq -e '.additionalContext | contains("/speckit-specify")' > /dev/null || return 1

  return 0
}

# ==============================================================================

main "$@"
exit 0
