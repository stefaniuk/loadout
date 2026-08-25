#!/bin/bash
# shellcheck disable=SC2329

set -euo pipefail

# Test suite for revert.sh.
#
# Usage:
#   $ ./revert.test.sh
#
# Tests operate in local/dry-run mode only - no remote clones.

# ==============================================================================

function main() {

  cd "$(git rev-parse --show-toplevel)"

  local tests=( \
    test_revert_help_exits_zero \
    test_revert_missing_dest_fails \
    test_revert_dry_run \
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
  [ $status -gt 0 ] && return 1 || return 0
}

# ==============================================================================

function test_revert_help_exits_zero() {

  # Arrange / Act
  local output
  output=$(bash scripts/revert.sh --help 2>&1) || return 1

  # Assert
  echo "${output}" | grep -qi "usage" || return 1

  return 0
}

function test_revert_missing_dest_fails() {

  # Arrange / Act
  local output
  output=$(bash scripts/revert.sh 2>&1) && return 1

  # Assert
  echo "${output}" | grep -qi "dest" || return 1

  return 0
}

function test_revert_dry_run() {

  # Arrange
  local dest="/tmp/__l5_fake_revert"
  rm -rf "${dest}"

  # Act
  local output
  output=$(bash scripts/revert.sh --dest "${dest}" --dry-run 2>&1) || return 1

  # Assert
  echo "${output}" | grep -q "would remove" || return 1
  [[ ! -e "${dest}" ]] || return 1

  return 0
}

# ==============================================================================

main "$@"
