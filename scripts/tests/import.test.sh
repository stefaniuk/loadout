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
    test-import-dry-run-detects-modified-instruction \
    test-import-dry-run-detects-new-file-in-destination \
    test-import-dry-run-detects-new-singleton-file \
    test-import-force-copies-changed-file-back \
    test-import-force-does-not-copy-unchanged-file \
    test-import-new-true-imports-new-files \
    test-import-new-false-does-not-import-new-files \
    test-import-detects-nested-file-in-recursive-tree \
    test-import-ignores-generated-skill-assets \
    test-import-detects-modified-agent \
    test-import-detects-modified-prompt \
    test-import-detects-modified-shared-resource \
    test-import-force-copies-multiple-changed-files \
    test-import-dry-run-reports-changed-count \
    test-import-dry-run-reports-new-count \
    test-import-detects-modified-agents-md \
    test-import-detects-modified-copilot-hook-config \
    test-import-detects-modified-hook-script \
    test-import-force-preserves-hook-script-exec-bit \
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

# Helper: apply assets to a temp destination and return the path.
function helper-apply-copilot() {

  local dest="${TEMP_DIR}/$1"
  mkdir -p "${dest}"
  ./scripts/apply.sh "${dest}" > /dev/null 2>&1
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

function test-import-dry-run-detects-modified-instruction() {

  # Arrange
  local dest
  dest=$(helper-apply-copilot "detect-modified")
  echo "# Modified content" >> "${dest}/.github/instructions/shell.instructions.md"

  # Act
  local output
  output=$(./scripts/import.sh "${dest}" 2>&1)

  # Assert
  echo "${output}" | grep -q "shell.instructions.md" || return 1

  return 0
}

function test-import-dry-run-detects-new-file-in-destination() {

  # Arrange
  local dest
  dest=$(helper-apply-copilot "detect-new")
  echo "# New prompt" > "${dest}/.github/prompts/enforce.custom.prompt.md"

  # Act
  local output
  output=$(./scripts/import.sh "${dest}" 2>&1)

  # Assert
  echo "${output}" | grep -q "enforce.custom.prompt.md" || return 1

  return 0
}

function test-import-dry-run-detects-new-singleton-file() {

  # Arrange
  local dest
  dest=$(helper-apply-copilot "detect-new-singleton")
  track-repo-file-state ".github/copilot-instructions.md"
  rm -f "${REPO_ROOT}/.github/copilot-instructions.md"
  echo "# New singleton copy" >> "${dest}/.github/copilot-instructions.md"

  # Act
  local output
  output=$(./scripts/import.sh "${dest}" 2>&1)

  # Assert
  echo "${output}" | grep -q ".github/copilot-instructions.md" || return 1

  return 0
}

function test-import-force-copies-changed-file-back() {

  # Arrange
  local dest
  dest=$(helper-apply-copilot "force-copy")
  track-repo-file-state ".github/instructions/shell.instructions.md"
  local marker
  marker="# IMPORT-TEST-MARKER-$(date +%s)"
  echo "${marker}" >> "${dest}/.github/instructions/shell.instructions.md"

  # Act
  force=true ./scripts/import.sh "${dest}" > /dev/null 2>&1

  # Assert
  grep -q "IMPORT-TEST-MARKER" "${REPO_ROOT}/.github/instructions/shell.instructions.md" || return 1

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

function test-import-detects-nested-file-in-recursive-tree() {

  # Arrange
  local dest
  dest=$(helper-apply-copilot "nested-recursive")
  local nested_dir=".github/instructions/includes/sub"
  mkdir -p "${dest}/${nested_dir}"
  echo "# Nested include" > "${dest}/${nested_dir}/nested.md"

  # Act
  local output
  output=$(./scripts/import.sh "${dest}" 2>&1)

  # Assert — nested file should appear as new
  echo "${output}" | grep -q "nested.md" || return 1

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

  # Act — force=true but new=false (default)
  force=true ./scripts/import.sh "${dest}" > /dev/null 2>&1

  # Assert — new file should NOT have been imported
  [[ ! -f "${REPO_ROOT}/${new_file}" ]] || return 1

  return 0
}

function test-import-detects-modified-agent() {

  # Arrange
  local dest
  dest=$(helper-apply-copilot "detect-agent")
  echo "# Modified agent" >> "${dest}/.github/agents/speckit.plan.agent.md"

  # Act
  local output
  output=$(./scripts/import.sh "${dest}" 2>&1)

  # Assert
  echo "${output}" | grep -q "speckit.plan.agent.md" || return 1

  return 0
}

function test-import-detects-modified-prompt() {

  # Arrange
  local dest
  dest=$(helper-apply-copilot "detect-prompt")
  echo "# Modified prompt" >> "${dest}/.github/prompts/enforce.shell.prompt.md"

  # Act
  local output
  output=$(./scripts/import.sh "${dest}" 2>&1)

  # Assert
  echo "${output}" | grep -q "enforce.shell.prompt.md" || return 1

  return 0
}

function test-import-detects-modified-shared-resource() {

  # Arrange
  local dest
  dest=$(helper-apply-copilot "detect-shared")
  echo "# Modified constitution" >> "${dest}/.specify/memory/constitution.md"

  # Act
  local output
  output=$(./scripts/import.sh "${dest}" 2>&1)

  # Assert
  echo "${output}" | grep -q "constitution.md" || return 1

  return 0
}

function test-import-force-copies-multiple-changed-files() {

  # Arrange
  local dest
  dest=$(helper-apply-copilot "force-multi")
  track-repo-file-state ".github/instructions/shell.instructions.md"
  track-repo-file-state ".github/instructions/docker.instructions.md"
  local marker
  marker="MULTI-IMPORT-MARKER-$(date +%s)"
  echo "${marker}" >> "${dest}/.github/instructions/shell.instructions.md"
  echo "${marker}" >> "${dest}/.github/instructions/docker.instructions.md"

  # Act
  force=true ./scripts/import.sh "${dest}" > /dev/null 2>&1

  # Assert — both files should have the marker
  grep -q "MULTI-IMPORT-MARKER" "${REPO_ROOT}/.github/instructions/shell.instructions.md" || return 1
  grep -q "MULTI-IMPORT-MARKER" "${REPO_ROOT}/.github/instructions/docker.instructions.md" || return 1

  return 0
}

function test-import-dry-run-reports-changed-count() {

  # Arrange
  local dest
  dest=$(helper-apply-copilot "count-changed")
  echo "# Modified 1" >> "${dest}/.github/instructions/shell.instructions.md"
  echo "# Modified 2" >> "${dest}/.github/instructions/docker.instructions.md"

  # Act
  local output
  output=$(./scripts/import.sh "${dest}" 2>&1)

  # Assert — should report count of changed files
  echo "${output}" | grep -q "Changed files (2)" || return 1

  return 0
}

function test-import-dry-run-reports-new-count() {

  # Arrange
  local dest
  dest=$(helper-apply-copilot "count-new")
  echo "# New 1" > "${dest}/.github/prompts/enforce.new1.prompt.md"
  echo "# New 2" > "${dest}/.github/prompts/enforce.new2.prompt.md"

  # Act
  local output
  output=$(./scripts/import.sh "${dest}" 2>&1)

  # Assert — should report count of new files
  echo "${output}" | grep -q "New files in destination (2)" || return 1

  return 0
}

function test-import-detects-modified-agents-md() {

  # Arrange
  local dest
  dest=$(helper-apply-copilot "detect-agents-md")
  track-repo-file-state "AGENTS.md"
  local marker
  marker="AGENTS-MD-IMPORT-MARKER-$(date +%s)"
  echo "${marker}" >> "${dest}/AGENTS.md"

  # Act — dry-run detection
  local output
  output=$(./scripts/import.sh "${dest}" 2>&1)
  echo "${output}" | grep -qE "(^|[[:space:]])AGENTS\.md" || return 1

  # Act — force import round-trips the change
  force=true ./scripts/import.sh "${dest}" > /dev/null 2>&1

  # Assert
  grep -q "${marker}" "${REPO_ROOT}/AGENTS.md" || return 1

  return 0
}

function test-import-detects-modified-copilot-hook-config() {

  # Arrange
  local dest
  dest=$(helper-apply-copilot "detect-hook-config")
  local rel_path=".github/hooks/quality-gates.json"
  track-repo-file-state "${rel_path}"
  # Modify the JSON in a benign way (append a trailing newline + comment-like marker)
  printf '\n' >> "${dest}/${rel_path}"

  # Act — dry-run detection
  local output
  output=$(./scripts/import.sh "${dest}" 2>&1)
  echo "${output}" | grep -q "quality-gates.json" || return 1

  # Act — force import round-trips the change
  force=true ./scripts/import.sh "${dest}" > /dev/null 2>&1

  # Assert — repo file now matches the destination byte-for-byte
  diff -q "${dest}/${rel_path}" "${REPO_ROOT}/${rel_path}" > /dev/null 2>&1 || return 1

  return 0
}

function test-import-detects-modified-hook-script() {

  # Arrange
  local dest
  dest=$(helper-apply-copilot "detect-hook-script")
  local rel_path="scripts/hooks/post-edit-lint.sh"
  track-repo-file-state "${rel_path}"
  local marker
  marker="# HOOK-SCRIPT-IMPORT-MARKER-$(date +%s)"
  echo "${marker}" >> "${dest}/${rel_path}"

  # Act — dry-run detection
  local output
  output=$(./scripts/import.sh "${dest}" 2>&1)
  echo "${output}" | grep -q "post-edit-lint.sh" || return 1

  # Act — force import round-trips the change
  force=true ./scripts/import.sh "${dest}" > /dev/null 2>&1

  # Assert
  grep -q "${marker}" "${REPO_ROOT}/${rel_path}" || return 1

  return 0
}

function test-import-force-preserves-hook-script-exec-bit() {

  # Arrange
  local dest
  dest=$(helper-apply-copilot "preserve-exec-bit")
  local rel_path="scripts/hooks/stop-gate.sh"
  track-repo-file-state "${rel_path}"
  echo "# EXEC-BIT-MARKER-$(date +%s)" >> "${dest}/${rel_path}"

  # Act
  force=true ./scripts/import.sh "${dest}" > /dev/null 2>&1

  # Assert — imported file must remain executable in the source repo
  [[ -x "${REPO_ROOT}/${rel_path}" ]] || return 1

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
