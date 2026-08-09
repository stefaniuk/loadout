#!/bin/bash
# shellcheck disable=SC2329

set -euo pipefail

# Test suite for install.sh and uninstall.sh.
#
# Usage:
#   $ ./install.test.sh
#
# Tests operate in local/dry-run mode only - no remote clones.

# ==============================================================================

function main() {

  cd "$(git rev-parse --show-toplevel)"

  local tests=( \
    test_install_help_exits_zero \
    test_install_missing_dest_fails \
    test_install_unknown_arg_fails \
    test_install_dry_run_local_mode \
    test_uninstall_help_exits_zero \
    test_uninstall_missing_dest_fails \
    test_uninstall_dry_run \
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

function test_install_help_exits_zero() {

  # Arrange / Act
  local output
  output=$(bash scripts/install.sh --help 2>&1) || return 1

  # Assert
  echo "${output}" | grep -qi "usage" || return 1

  return 0
}

function test_install_missing_dest_fails() {

  # Arrange / Act
  local output
  output=$(bash scripts/install.sh 2>&1) && return 1

  # Assert
  echo "${output}" | grep -qi "dest" || return 1

  return 0
}

function test_install_unknown_arg_fails() {

  # Arrange / Act
  bash scripts/install.sh --bogus > /dev/null 2>&1 && return 1

  return 0
}

function test_install_dry_run_local_mode() {

  # Arrange
  local dest="/tmp/__l5_fake"
  rm -rf "${dest}"

  # Act
  local output
  output=$(bash scripts/install.sh --dest "${dest}" --dry-run 2>&1) || return 1

  # Assert
  echo "${output}" | grep -q "mode=local" || return 1
  echo "${output}" | grep -q "apply.sh" || return 1
  [[ ! -d "${dest}/.github" ]] || return 1

  return 0
}

function test_uninstall_help_exits_zero() {

  # Arrange / Act
  local output
  output=$(bash scripts/uninstall.sh --help 2>&1) || return 1

  # Assert
  echo "${output}" | grep -qi "usage" || return 1

  return 0
}

function test_uninstall_missing_dest_fails() {

  # Arrange / Act
  local output
  output=$(bash scripts/uninstall.sh 2>&1) && return 1

  # Assert
  echo "${output}" | grep -qi "dest" || return 1

  return 0
}

function test_uninstall_dry_run() {

  # Arrange
  local dest="/tmp/__l5_fake_uninstall"
  rm -rf "${dest}"

  # Act
  local output
  output=$(bash scripts/uninstall.sh --dest "${dest}" --dry-run 2>&1) || return 1

  # Assert
  echo "${output}" | grep -q "revert=true" || return 1
  [[ ! -e "${dest}" ]] || return 1

  return 0
}

# ==============================================================================

main "$@"
