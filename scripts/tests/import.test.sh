#!/bin/bash
# shellcheck disable=SC2329

set -euo pipefail

# Test suite for the import command.
#
# Usage:
#   $ ./import.test.sh
#
# Arguments (provided as environment variables):
#   VERBOSE=true  # Show all the executed commands, default is 'false'

# ==============================================================================

TEMP_DIR=""
REPO_ROOT=""
SHARED_APPLY_SRC=""
TRACKED_REPO_FILES=()

function main() {

  REPO_ROOT="$(git rev-parse --show-toplevel)"
  cd "${REPO_ROOT}"

  test-import-suite-setup
  trap test-import-suite-teardown EXIT INT TERM
  local tests=( \
    test-import-no-args-fails \
    test-import-empty-source-fails \
    test-import-nonexistent-source-fails \
    test-import-dry-run-shows-no-changes-for-fresh-apply \
    test-import-dry-run-detects-modifications-across-tracked-types \
    test-import-dry-run-detects-new-files \
    test-import-force-copies-changed-files-back \
    test-import-force-does-not-copy-unchanged-file \
    test-import-new-true-imports-new-files \
    test-import-new-false-does-not-import-new-files \
    test-import-ignores-generated-skill-assets \
    test-import-detects-and-round-trips-singletons-and-hooks \
  )
  local status=0
  for test in "${tests[@]}"; do
    {
      echo -n "$test"
      # shellcheck disable=SC2015
      run-test-with-cleanup "$test" && echo " PASS" || { echo " FAIL"; ((status++)); }
    }
  done
  echo "Total: ${#tests[@]}, Passed: $(( ${#tests[@]} - status )), Failed: $status"
  test-import-suite-teardown
  [ $status -gt 0 ] && return 1 || return 0
}

# ==============================================================================

function test-import-suite-setup() {

  TEMP_DIR=$(mktemp -d)
  # Pre-build a single shared apply destination; individual tests fast-copy
  # it rather than re-running apply.sh, which dominates wall time.
  SHARED_APPLY_SRC="${TEMP_DIR}/_shared_apply"
  ./scripts/apply.sh "${SHARED_APPLY_SRC}" > /dev/null 2>&1

  return 0
}

function test-import-suite-teardown() {

  restore-tracked-repo-files

  if [[ -n "${TEMP_DIR}" ]] && [[ -d "${TEMP_DIR}" ]]; then
    rm -rf "${TEMP_DIR}"
  fi

  return 0
}

# Run a single test and always restore tracked repo files afterwards.
# Arguments:
#   $1=[test function name]
function run-test-with-cleanup() {

  local test_name="$1"
  local status=0

  TRACKED_REPO_FILES=()

  if "${test_name}"; then
    status=0
  else
    status=$?
  fi

  restore-tracked-repo-files

  return ${status}
}

# Track the current repo state for a file so it can be restored after tests.
# Arguments:
#   $1=[relative file path under repo root]
function track-repo-file-state() {

  local rel_path="$1"
  local backup_path="${TEMP_DIR}/repo-backups/${rel_path}"

  if is-repo-file-tracked "${rel_path}"; then
    return 0
  fi

  mkdir -p "$(dirname "${backup_path}")"

  if [[ -f "${REPO_ROOT}/${rel_path}" ]]; then
    cp "${REPO_ROOT}/${rel_path}" "${backup_path}"
  else
    : > "${backup_path}.missing"
  fi

  TRACKED_REPO_FILES+=("${rel_path}")

  return 0
}

# Check whether a repo file is already tracked for restoration.
# Arguments:
#   $1=[relative file path under repo root]
function is-repo-file-tracked() {

  local rel_path="$1"
  local tracked_path

  for tracked_path in "${TRACKED_REPO_FILES[@]}"; do
    if [[ "${tracked_path}" == "${rel_path}" ]]; then
      return 0
    fi
  done

  return 1
}

# Restore all tracked repo files to their original state.
function restore-tracked-repo-files() {

  local rel_path
  for rel_path in "${TRACKED_REPO_FILES[@]}"; do
    local backup_path="${TEMP_DIR}/repo-backups/${rel_path}"
    local repo_path="${REPO_ROOT}/${rel_path}"

    if [[ -f "${backup_path}.missing" ]]; then
      rm -f "${repo_path}"
    elif [[ -f "${backup_path}" ]]; then
      mkdir -p "$(dirname "${repo_path}")"
      cp "${backup_path}" "${repo_path}"
    fi
  done

  TRACKED_REPO_FILES=()

  return 0
}

# Helper: provide a fresh destination by cloning the shared apply cache.
# This is ~5x faster than re-running apply.sh per test.
function helper-apply-copilot() {

  local dest="${TEMP_DIR}/$1"
  cp -R "${SHARED_APPLY_SRC}" "${dest}"
  echo "${dest}"

  return 0
}

# ==============================================================================

function test-import-dry-run-shows-no-changes-for-fresh-apply() {

  # Arrange
  local dest
  dest=$(helper-apply-copilot "dry-run-fresh")

  # Act
  local output
  output=$(./scripts/import.sh "${dest}" 2>&1)

  # Assert
  # No changed or new files after a fresh apply
  echo "${output}" | grep -q "No changes detected" || return 1

  return 0
}

function test-import-force-does-not-copy-unchanged-file() {

  # Arrange
  local dest
  dest=$(helper-apply-copilot "no-copy-unchanged")
  local before_hash
  before_hash=$(shasum "${REPO_ROOT}/.github/instructions/shell.instructions.md" | cut -d' ' -f1)

  # Act
  force=true ./scripts/import.sh "${dest}" > /dev/null 2>&1

  # Assert
  local after_hash
  after_hash=$(shasum "${REPO_ROOT}/.github/instructions/shell.instructions.md" | cut -d' ' -f1)
  [[ "${before_hash}" == "${after_hash}" ]] || return 1

  return 0
}

function test-import-new-true-imports-new-files() {

  # Arrange
  local dest
  dest=$(helper-apply-copilot "new-files")
  local new_file=".github/prompts/enforce.brand-new.prompt.md"
  track-repo-file-state "${new_file}"
  echo "# Brand new prompt" > "${dest}/${new_file}"

  # Act
  force=true new=true ./scripts/import.sh "${dest}" > /dev/null 2>&1

  # Assert
  [[ -f "${REPO_ROOT}/${new_file}" ]] || return 1

  return 0
}

function test-import-ignores-generated-skill-assets() {

  # Arrange
  local dest
  dest=$(helper-apply-copilot "ignore-generated-assets")
  local generated_file=".github/skills/repository-template/assets/generated.txt"
  track-repo-file-state "${generated_file}"
  mkdir -p "${dest}/.github/skills/repository-template/assets"
  echo "generated" > "${dest}/${generated_file}"

  # Act
  local output
  output=$(./scripts/import.sh "${dest}" 2>&1)
  force=true new=true ./scripts/import.sh "${dest}" > /dev/null 2>&1

  # Assert
  ! echo "${output}" | grep -q "${generated_file}" || return 1
  [[ ! -f "${REPO_ROOT}/${generated_file}" ]] || return 1

  return 0
}

function test-import-no-args-fails() {

  # Arrange / Act
  local output
  output=$(./scripts/import.sh 2>&1) && return 1

  # Assert
  echo "${output}" | grep -qi "usage" || return 1

  return 0
}

function test-import-empty-source-fails() {

  # Arrange / Act
  local output
  output=$(./scripts/import.sh "" 2>&1) && return 1

  # Assert
  echo "${output}" | grep -qi "empty" || return 1

  return 0
}

function test-import-nonexistent-source-fails() {

  # Arrange / Act
  local output
  output=$(./scripts/import.sh "/nonexistent/path" 2>&1) && return 1

  # Assert
  echo "${output}" | grep -qi "does not exist" || return 1

  return 0
}

function test-import-new-false-does-not-import-new-files() {

  # Arrange
  local dest
  dest=$(helper-apply-copilot "new-false")
  local new_file=".github/prompts/enforce.brand-new-skip.prompt.md"
  track-repo-file-state "${new_file}"
  echo "# Brand new prompt" > "${dest}/${new_file}"

  # Act - force=true but new=false (default)
  force=true ./scripts/import.sh "${dest}" > /dev/null 2>&1

  # Assert - new file should NOT have been imported
  [[ ! -f "${REPO_ROOT}/${new_file}" ]] || return 1

  return 0
}

# Consolidated: detect modifications across instruction, agent, prompt and
# shared-resource files in one dry-run import, and validate the changed-count
# summary.
function test-import-dry-run-detects-modifications-across-tracked-types() {

  local dest
  dest=$(helper-apply-copilot "detect-modifications")
  echo "# Modified instruction" >> "${dest}/.github/instructions/shell.instructions.md"
  echo "# Modified agent" >> "${dest}/.github/agents/speckit.plan.agent.md"
  echo "# Modified prompt" >> "${dest}/.github/prompts/enforce.shell.prompt.md"
  echo "# Modified constitution" >> "${dest}/.specify/memory/constitution.md"

  local output
  output=$(./scripts/import.sh "${dest}" 2>&1)

  echo "${output}" | grep -q "shell.instructions.md" || return 1
  echo "${output}" | grep -q "speckit.plan.agent.md" || return 1
  echo "${output}" | grep -q "enforce.shell.prompt.md" || return 1
  echo "${output}" | grep -q "constitution.md" || return 1
  echo "${output}" | grep -q "Changed files (4)" || return 1

  return 0
}

# Consolidated: detect new files (top-level, nested, and singleton) and
# validate the new-files summary count.
function test-import-dry-run-detects-new-files() {

  local dest
  dest=$(helper-apply-copilot "detect-new-files")
  # Top-level new prompt
  echo "# New prompt" > "${dest}/.github/prompts/enforce.custom.prompt.md"
  # Nested new file inside includes/
  local nested_dir=".github/instructions/includes/sub"
  mkdir -p "${dest}/${nested_dir}"
  echo "# Nested include" > "${dest}/${nested_dir}/nested.md"
  # Singleton file that is missing from REPO_ROOT
  track-repo-file-state ".github/copilot-instructions.md"
  rm -f "${REPO_ROOT}/.github/copilot-instructions.md"
  echo "# New singleton copy" >> "${dest}/.github/copilot-instructions.md"

  local output
  output=$(./scripts/import.sh "${dest}" 2>&1)

  echo "${output}" | grep -q "enforce.custom.prompt.md" || return 1
  echo "${output}" | grep -q "nested.md" || return 1
  echo "${output}" | grep -q ".github/copilot-instructions.md" || return 1
  echo "${output}" | grep -q "New files in destination (3)" || return 1

  return 0
}

# Consolidated: force=true must round-trip changes for one or more files.
function test-import-force-copies-changed-files-back() {

  local dest
  dest=$(helper-apply-copilot "force-copy")
  track-repo-file-state ".github/instructions/shell.instructions.md"
  track-repo-file-state ".github/instructions/docker.instructions.md"
  local marker
  marker="IMPORT-TEST-MARKER-$(date +%s)"
  echo "# ${marker}" >> "${dest}/.github/instructions/shell.instructions.md"
  echo "# ${marker}" >> "${dest}/.github/instructions/docker.instructions.md"

  force=true ./scripts/import.sh "${dest}" > /dev/null 2>&1

  grep -q "${marker}" "${REPO_ROOT}/.github/instructions/shell.instructions.md" || return 1
  grep -q "${marker}" "${REPO_ROOT}/.github/instructions/docker.instructions.md" || return 1

  return 0
}

# Consolidated: AGENTS.md, hook config and hook scripts must all be detected
# in one dry-run and round-trip in one force run; hook scripts keep their
# executable bit.
function test-import-detects-and-round-trips-singletons-and-hooks() {

  local dest
  dest=$(helper-apply-copilot "singletons-and-hooks")
  track-repo-file-state "AGENTS.md"
  track-repo-file-state ".github/hooks/quality-gates.json"
  track-repo-file-state "scripts/hooks/post-edit-lint.sh"
  track-repo-file-state "scripts/hooks/stop-gate.sh"

  local marker
  marker="SINGLETON-HOOK-MARKER-$(date +%s)"
  echo "# ${marker}" >> "${dest}/AGENTS.md"
  printf '\n' >> "${dest}/.github/hooks/quality-gates.json"
  echo "# ${marker}" >> "${dest}/scripts/hooks/post-edit-lint.sh"
  echo "# ${marker}" >> "${dest}/scripts/hooks/stop-gate.sh"

  # Dry-run detection covers all four paths
  local output
  output=$(./scripts/import.sh "${dest}" 2>&1)
  echo "${output}" | grep -qE "(^|[[:space:]])AGENTS\.md" || return 1
  echo "${output}" | grep -q "quality-gates.json" || return 1
  echo "${output}" | grep -q "post-edit-lint.sh" || return 1
  echo "${output}" | grep -q "stop-gate.sh" || return 1

  # Force import round-trips the changes
  force=true ./scripts/import.sh "${dest}" > /dev/null 2>&1
  grep -q "${marker}" "${REPO_ROOT}/AGENTS.md" || return 1
  diff -q "${dest}/.github/hooks/quality-gates.json" "${REPO_ROOT}/.github/hooks/quality-gates.json" > /dev/null 2>&1 || return 1
  grep -q "${marker}" "${REPO_ROOT}/scripts/hooks/post-edit-lint.sh" || return 1
  grep -q "${marker}" "${REPO_ROOT}/scripts/hooks/stop-gate.sh" || return 1
  # Executable bits preserved
  [[ -x "${REPO_ROOT}/scripts/hooks/post-edit-lint.sh" ]] || return 1
  [[ -x "${REPO_ROOT}/scripts/hooks/stop-gate.sh" ]] || return 1

  return 0
}

# ==============================================================================

function is-arg-true() {

  if [[ "$1" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$ ]]; then
    return 0
  else
    return 1
  fi
}

# ==============================================================================

is-arg-true "${VERBOSE:-false}" && set -x

main "$@"

exit 0
