#!/bin/bash
# shellcheck disable=SC2329

set -euo pipefail

# Smoke tests for the SubagentStart/SubagentStop lifecycle hooks.
#
# Usage:
#   $ ./scripts/tests/subagent-hooks.test.sh
#
# Arguments (provided as environment variables):
#   VERBOSE=true  # Show all the executed commands, default is 'false'

# ==============================================================================

TEMP_DIR=""

function main() {

  cd "$(git rev-parse --show-toplevel)"

  test-suite-setup
  local tests=( \
    test_hooks_json_contains_subagent_events \
    test_quality_gates_json_contains_subagent_events \
    test_subagent_start_script_is_executable \
    test_subagent_stop_script_is_executable \
    test_subagent_start_emits_valid_json \
    test_subagent_stop_appends_log \
  )
  local status=0
  for test in "${tests[@]}"; do
    {
      echo -n "$test"
      # shellcheck disable=SC2015
      $test && echo " PASS" || { echo " FAIL"; ((status++)); }
    }
  done
  echo "Total: ${#tests[@]}, Passed: $(( ${#tests[@]} - status )), Failed: $status"
  test-suite-teardown
  if [[ $status -gt 0 ]]; then
    return 1
  fi
  echo "subagent-hooks: ok"
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

function test_hooks_json_contains_subagent_events() {

  jq -e '.hooks.SubagentStart | type == "array" and length > 0 and (.[0].command | type == "string")' hooks.json > /dev/null || return 1
  jq -e '.hooks.SubagentStop  | type == "array" and length > 0 and (.[0].command | type == "string")' hooks.json > /dev/null || return 1

  return 0
}

function test_quality_gates_json_contains_subagent_events() {

  local file=".github/hooks/quality-gates.json"
  jq -e '.hooks.SubagentStart | type == "array" and length > 0 and (.[0].command | type == "string")' "$file" > /dev/null || return 1
  jq -e '.hooks.SubagentStop  | type == "array" and length > 0 and (.[0].command | type == "string")' "$file" > /dev/null || return 1

  return 0
}

function test_subagent_start_script_is_executable() {

  local script="scripts/hooks/subagent-start-context.sh"
  [[ -f "$script" ]] || return 1
  [[ -x "$script" ]] || return 1

  return 0
}

function test_subagent_stop_script_is_executable() {

  local script="scripts/hooks/subagent-stop-log.sh"
  [[ -f "$script" ]] || return 1
  [[ -x "$script" ]] || return 1

  return 0
}

function test_subagent_start_emits_valid_json() {

  local log_dir="${TEMP_DIR}/start"
  mkdir -p "$log_dir"

  local out
  out=$(echo '{"session_id":"test","cwd":"/tmp","agent_id":"speckit.analyze"}' \
    | LOG_DIR="$log_dir" ./scripts/hooks/subagent-start-context.sh) || return 1

  echo "$out" | python3 -c 'import json,sys; json.load(sys.stdin)' || return 1
  echo "$out" | grep -q '"hookEventName":"SubagentStart"' || return 1

  return 0
}

function test_subagent_stop_appends_log() {

  local log_dir="${TEMP_DIR}/stop"
  mkdir -p "$log_dir"

  echo '{"session_id":"test","agent_id":"speckit.analyze","stop_hook_active":false}' \
    | LOG_DIR="$log_dir" ./scripts/hooks/subagent-stop-log.sh > /dev/null || return 1

  local log_file="${log_dir}/subagent-events.jsonl"
  [[ -f "$log_file" ]] || return 1
  [[ -s "$log_file" ]] || return 1
  grep -q '"event":"stop"' "$log_file" || return 1

  return 0
}

# ==============================================================================

main "$@"
