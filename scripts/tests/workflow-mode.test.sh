#!/bin/bash
# shellcheck disable=SC2329

set -euo pipefail

# Smoke tests for the workflow mode command surface.
#
# Usage:
#   $ ./scripts/tests/workflow-mode.test.sh
#
# Arguments (provided as environment variables):
#   VERBOSE=true  # Show all the executed commands, default is 'false'

# ==============================================================================

TEMP_DIR=""

function main() {

  cd "$(git rev-parse --show-toplevel)"

  test-suite-setup
  local tests=( \
    test_workflow_status_defaults_to_superpowers \
    test_workflow_use_sets_superpowers_mode \
    test_workflow_switch_flips_superpowers_to_speckit \
    test_workflow_switch_flips_speckit_to_superpowers \
    test_workflow_use_rejects_invalid_mode \
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
  echo "workflow-mode: ok"
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

function test_workflow_status_defaults_to_superpowers() {

  local mode_file="${TEMP_DIR}/workflow-mode.json"
  local out
  out=$(LOADOUT_WORKFLOW_MODE_FILE="${mode_file}" make workflow-status 2>&1) || return 1

  echo "${out}" | grep -qx 'superpowers' || return 1
  [[ ! -f "${mode_file}" ]] || return 1

  return 0
}

function test_workflow_use_sets_superpowers_mode() {

  local mode_file="${TEMP_DIR}/workflow-mode.json"
  LOADOUT_WORKFLOW_MODE_FILE="${mode_file}" make workflow-use mode=superpowers > /dev/null 2>&1 || return 1

  [[ -f "${mode_file}" ]] || return 1
  jq -e '.active == "superpowers"' "${mode_file}" > /dev/null || return 1

  local out
  out=$(LOADOUT_WORKFLOW_MODE_FILE="${mode_file}" make workflow-status 2>&1) || return 1
  echo "${out}" | grep -qx 'superpowers' || return 1

  return 0
}

function test_workflow_switch_flips_superpowers_to_speckit() {

  local mode_file="${TEMP_DIR}/workflow-mode-switch-default.json"
  local out
  out=$(LOADOUT_WORKFLOW_MODE_FILE="${mode_file}" make workflow-switch 2>&1) || return 1

  echo "${out}" | grep -qx 'speckit' || return 1
  [[ -f "${mode_file}" ]] || return 1
  jq -e '.active == "speckit"' "${mode_file}" > /dev/null || return 1

  return 0
}

function test_workflow_switch_flips_speckit_to_superpowers() {

  local mode_file="${TEMP_DIR}/workflow-mode-switch-speckit.json"
  LOADOUT_WORKFLOW_MODE_FILE="${mode_file}" make workflow-use mode=speckit > /dev/null 2>&1 || return 1

  local out
  out=$(LOADOUT_WORKFLOW_MODE_FILE="${mode_file}" make workflow-switch 2>&1) || return 1

  echo "${out}" | grep -qx 'superpowers' || return 1
  jq -e '.active == "superpowers"' "${mode_file}" > /dev/null || return 1

  return 0
}

function test_workflow_use_rejects_invalid_mode() {

  local mode_file="${TEMP_DIR}/workflow-mode.json"
  local out
  out=$(LOADOUT_WORKFLOW_MODE_FILE="${mode_file}" make workflow-use mode=invalid 2>&1) && return 1

  echo "${out}" | grep -qi 'mode must be speckit or superpowers' || return 1

  return 0
}

# ==============================================================================

main "$@"
exit 0
