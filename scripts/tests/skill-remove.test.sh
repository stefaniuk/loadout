#!/bin/bash
# shellcheck disable=SC2329

set -euo pipefail

# Test suite for scripts/skill-remove.sh.
#
# Usage:
#   $ ./scripts/tests/skill-remove.test.sh
#
# Arguments (provided as environment variables):
#   VERBOSE=true  # Show all the executed commands, default is 'false'

# ==============================================================================

TEMP_DIR=""
REPO_ROOT=""

function main() {

  REPO_ROOT="$(git rev-parse --show-toplevel)"
  cd "${REPO_ROOT}"

  test-skill-remove-suite-setup
  trap test-skill-remove-suite-teardown EXIT INT TERM

  local tests=( \
    test-skill-remove-fails-without-name \
    test-skill-remove-fails-when-skill-not-found \
    test-skill-remove-deletes-config-entry \
    test-skill-remove-deletes-synced-directory \
    test-skill-remove-succeeds-without-synced-directory \
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

  return ${status}
}

# ==============================================================================

function test-skill-remove-suite-setup() {

  TEMP_DIR=$(mktemp -d)

  return 0
}

function test-skill-remove-suite-teardown() {

  if [[ -n "${TEMP_DIR}" ]] && [[ -d "${TEMP_DIR}" ]]; then
    rm -rf "${TEMP_DIR}"
  fi

  return 0
}

# Create an isolated fixture repository for exercising scripts/skill-remove.sh.
# Arguments:
#   $1=[fixture directory]
function create-skill-remove-fixture() {

  local fixture_dir="$1"

  mkdir -p "${fixture_dir}/scripts/config/skill-patches"
  mkdir -p "${fixture_dir}/.github/skills"

  cp "${REPO_ROOT}/scripts/skill-remove.sh" "${fixture_dir}/scripts/skill-remove.sh"
  chmod +x "${fixture_dir}/scripts/skill-remove.sh"

  cat <<'EOF' > "${fixture_dir}/scripts/config/skills.yaml"
skills:
  - name: keep-me
    repo: https://example.invalid/keep.git
    path: skills/keep-me
    ref: main
    sha: 0000000000000000000000000000000000000000
  - name: doomed-skill
    repo: https://example.invalid/doomed.git
    path: skills/doomed-skill
    ref: main
    sha: 1111111111111111111111111111111111111111
EOF

  return 0
}

# Run scripts/skill-remove.sh inside a fixture repository.
# Arguments:
#   $1=[fixture directory]
#   $2=[skill name, may be empty]
function run-skill-remove-fixture() {

  local fixture_dir="$1"
  local skill_name="${2:-}"

  (cd "${fixture_dir}" && name="${skill_name}" ./scripts/skill-remove.sh)
}

# ==============================================================================

function test-skill-remove-fails-without-name() {

  local fixture_dir="${TEMP_DIR}/fails-without-name"
  create-skill-remove-fixture "${fixture_dir}"

  local output
  if output=$(run-skill-remove-fixture "${fixture_dir}" "" 2>&1); then
    echo "expected failure, got success: ${output}"
    return 1
  fi

  if [[ "$output" != *"name is required"* ]]; then
    echo "expected 'name is required' error, got: ${output}"
    return 1
  fi

  return 0
}

function test-skill-remove-fails-when-skill-not-found() {

  local fixture_dir="${TEMP_DIR}/fails-when-not-found"
  create-skill-remove-fixture "${fixture_dir}"

  local output
  if output=$(run-skill-remove-fixture "${fixture_dir}" "missing-skill" 2>&1); then
    echo "expected failure, got success: ${output}"
    return 1
  fi

  if [[ "$output" != *"missing-skill"* || "$output" != *"not found"* ]]; then
    echo "expected 'not found' error mentioning the skill name, got: ${output}"
    return 1
  fi

  return 0
}

function test-skill-remove-deletes-config-entry() {

  local fixture_dir="${TEMP_DIR}/deletes-config-entry"
  create-skill-remove-fixture "${fixture_dir}"

  if ! run-skill-remove-fixture "${fixture_dir}" "doomed-skill" > /dev/null 2>&1; then
    echo "expected success"
    return 1
  fi

  if grep -q "doomed-skill" "${fixture_dir}/scripts/config/skills.yaml"; then
    echo "expected 'doomed-skill' to be removed from config"
    return 1
  fi

  if ! grep -q "keep-me" "${fixture_dir}/scripts/config/skills.yaml"; then
    echo "expected 'keep-me' to remain in config"
    return 1
  fi

  local remaining
  remaining=$(yq -r ".skills[] | select(.name == \"keep-me\") | .name" "${fixture_dir}/scripts/config/skills.yaml")
  if [[ "$remaining" != "keep-me" ]]; then
    echo "expected valid YAML with 'keep-me' entry intact, got: ${remaining}"
    return 1
  fi

  return 0
}

function test-skill-remove-deletes-synced-directory() {

  local fixture_dir="${TEMP_DIR}/deletes-synced-directory"
  create-skill-remove-fixture "${fixture_dir}"
  mkdir -p "${fixture_dir}/.github/skills/doomed-skill"
  echo "content" > "${fixture_dir}/.github/skills/doomed-skill/SKILL.md"

  if ! run-skill-remove-fixture "${fixture_dir}" "doomed-skill" > /dev/null 2>&1; then
    echo "expected success"
    return 1
  fi

  if [[ -d "${fixture_dir}/.github/skills/doomed-skill" ]]; then
    echo "expected synced directory to be deleted"
    return 1
  fi

  return 0
}

function test-skill-remove-succeeds-without-synced-directory() {

  local fixture_dir="${TEMP_DIR}/succeeds-without-synced-directory"
  create-skill-remove-fixture "${fixture_dir}"

  if ! run-skill-remove-fixture "${fixture_dir}" "doomed-skill" > /dev/null 2>&1; then
    echo "expected success even without a synced directory"
    return 1
  fi

  return 0
}

# ==============================================================================

if main "$@"; then
  exit 0
fi

exit 1
