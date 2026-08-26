#!/bin/bash
# shellcheck disable=SC2329

set -euo pipefail

# Test suite for the import command.
#
# Optimised for speed: every test runs against its own isolated copy of the
# repo (via LOADOUT_IMPORT_REPO_ROOT) and its own applied destination, so the
# whole suite runs in parallel and never mutates the real repository.
#
# Usage:
#   $ ./import.test.sh
#
# Arguments (provided as environment variables):
#   VERBOSE=true  # Show all the executed commands, default is 'false'

# ==============================================================================

TEMP_DIR=""
REPO_ROOT=""
REPO_SNAPSHOT=""

# Import-relevant subtree of the repo (mirrors the paths import.sh compares).
IMPORT_PATHS=(
  ".github/copilot-instructions.md"
  ".github/agents"
  ".github/hooks"
  ".github/instructions"
  ".github/prompts"
  ".github/skills"
  ".specify/memory/constitution.md"
  ".specify/scripts/python"
  ".specify/templates"
  "docs/adr/ADR-nnn_Any_Decision_Record_Template.md"
  "docs/adr/Tech_Radar.md"
  "scripts/hooks"
)

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
    test-import-skips-destination-owned-adr-template \
    test-import-detects-and-round-trips-singletons-and-hooks \
  )

  local log_dir="${TEMP_DIR}/logs"
  mkdir -p "${log_dir}"

  local pids=() names=()
  for test in "${tests[@]}"; do
    ("${test}") > "${log_dir}/${test}.log" 2>&1 &
    pids+=("$!")
    names+=("${test}")
  done

  local status=0 i
  for i in "${!pids[@]}"; do
    echo -n "${names[$i]}"
    # shellcheck disable=SC2015
    if wait "${pids[$i]}"; then
      echo " PASS"
    else
      echo " FAIL"
      cat "${log_dir}/${names[$i]}.log"
      status=$((status + 1))
    fi
  done

  echo "Total: ${#tests[@]}, Passed: $(( ${#tests[@]} - status )), Failed: $status"
  [ $status -gt 0 ] && return 1 || return 0
}

# ==============================================================================

function test-import-suite-setup() {

  TEMP_DIR=$(mktemp -d)

  # Pre-build a faithful snapshot of the repo's import-relevant subtree. Tests
  # copy it so imports round-trip into an isolated tree instead of the real repo.
  # The snapshot doubles as the destination template: a fresh dest and repo
  # start byte-identical, so a clean import reports no changes.
  REPO_SNAPSHOT="${TEMP_DIR}/_repo_snapshot"
  build-repo-snapshot "${REPO_SNAPSHOT}"

  return 0
}

function test-import-suite-teardown() {

  if [[ -n "${TEMP_DIR}" ]] && [[ -d "${TEMP_DIR}" ]]; then
    rm -rf "${TEMP_DIR}"
  fi

  return 0
}

# Build an isolated copy of the repo's import-relevant subtree.
# Arguments:
#   $1=[destination snapshot directory]
function build-repo-snapshot() {

  local dst="$1"
  local rel

  for rel in "${IMPORT_PATHS[@]}"; do
    if [[ -e "${REPO_ROOT}/${rel}" ]]; then
      mkdir -p "${dst}/$(dirname "${rel}")"
      cp -R "${REPO_ROOT}/${rel}" "${dst}/${rel}"
    fi
  done

  return 0
}

# Provide a fresh destination for a test (isolated copy of the repo snapshot).
# A fresh dest starts identical to a fresh repo, so unmodified imports are clean.
# Arguments:
#   $1=[unique key]
function make-dest() {

  local dest="${TEMP_DIR}/$1/dest"
  mkdir -p "${TEMP_DIR}/$1"
  cp -R "${REPO_SNAPSHOT}" "${dest}"
  echo "${dest}"

  return 0
}

# Provide a fresh isolated repo snapshot for a test to import into.
# Arguments:
#   $1=[unique key]
function make-repo() {

  local repo="${TEMP_DIR}/$1/repo"
  mkdir -p "${TEMP_DIR}/$1"
  cp -R "${REPO_SNAPSHOT}" "${repo}"
  echo "${repo}"

  return 0
}

# ==============================================================================

function test-import-dry-run-shows-no-changes-for-fresh-apply() {

  # Round-trip fidelity: apply.sh output imported against the repo snapshot
  # must report no changes. The apply runs here (overlapped with other tests)
  # rather than serially in setup.
  local dest repo
  dest="${TEMP_DIR}/dry-run-fresh/applied"
  mkdir -p "${TEMP_DIR}/dry-run-fresh"
  ./scripts/apply.sh "${dest}" > /dev/null 2>&1
  repo=$(make-repo "dry-run-fresh")

  local output
  output=$(LOADOUT_IMPORT_REPO_ROOT="${repo}" ./scripts/import.sh "${dest}" 2>&1)

  echo "${output}" | grep -q "No changes detected" || return 1

  return 0
}

function test-import-force-does-not-copy-unchanged-file() {

  local dest repo
  dest=$(make-dest "no-copy-unchanged")
  repo=$(make-repo "no-copy-unchanged")
  local target="${repo}/.github/instructions/shell.instructions.md"
  local before_hash
  before_hash=$(shasum "${target}" | cut -d' ' -f1)

  LOADOUT_IMPORT_REPO_ROOT="${repo}" force=true ./scripts/import.sh "${dest}" > /dev/null 2>&1

  local after_hash
  after_hash=$(shasum "${target}" | cut -d' ' -f1)
  [[ "${before_hash}" == "${after_hash}" ]] || return 1

  return 0
}

function test-import-new-true-imports-new-files() {

  local dest repo
  dest=$(make-dest "new-files")
  repo=$(make-repo "new-files")
  local new_file=".github/prompts/enforce.brand-new.prompt.md"
  echo "# Brand new prompt" > "${dest}/${new_file}"

  LOADOUT_IMPORT_REPO_ROOT="${repo}" force=true new=true ./scripts/import.sh "${dest}" > /dev/null 2>&1

  [[ -f "${repo}/${new_file}" ]] || return 1

  return 0
}

function test-import-ignores-generated-skill-assets() {

  local dest repo
  dest=$(make-dest "ignore-generated-assets")
  repo=$(make-repo "ignore-generated-assets")
  local generated_file=".github/skills/repository-template/assets/generated.txt"
  mkdir -p "${dest}/.github/skills/repository-template/assets"
  echo "generated" > "${dest}/${generated_file}"

  local output
  output=$(LOADOUT_IMPORT_REPO_ROOT="${repo}" ./scripts/import.sh "${dest}" 2>&1)
  LOADOUT_IMPORT_REPO_ROOT="${repo}" force=true new=true ./scripts/import.sh "${dest}" > /dev/null 2>&1

  ! echo "${output}" | grep -q "${generated_file}" || return 1
  [[ ! -f "${repo}/${generated_file}" ]] || return 1

  return 0
}

function test-import-skips-destination-owned-adr-template() {

  local dest repo
  dest=$(make-dest "owned-adr-template")
  repo=$(make-repo "owned-adr-template")
  local adr_rel="docs/adr/ADR-nnn_Any_Decision_Record_Template.md"

  echo "# destination customised ADR template" >> "${dest}/${adr_rel}"
  git -C "${dest}" init -q
  git -C "${dest}" add -A
  git -C "${dest}" -c user.email="test@example.com" -c user.name="Loadout Test" commit -q -m "seed"

  local output
  output=$(LOADOUT_IMPORT_REPO_ROOT="${repo}" ./scripts/import.sh "${dest}" 2>&1)
  ! echo "${output}" | grep -q "${adr_rel}" || return 1

  LOADOUT_IMPORT_REPO_ROOT="${repo}" force=true new=true ./scripts/import.sh "${dest}" > /dev/null 2>&1
  ! grep -q "destination customised ADR template" "${repo}/${adr_rel}" || return 1

  return 0
}

function test-import-no-args-fails() {

  local output
  output=$(./scripts/import.sh 2>&1) && return 1

  echo "${output}" | grep -qi "usage" || return 1

  return 0
}

function test-import-empty-source-fails() {

  local output
  output=$(./scripts/import.sh "" 2>&1) && return 1

  echo "${output}" | grep -qi "empty" || return 1

  return 0
}

function test-import-nonexistent-source-fails() {

  local output
  output=$(./scripts/import.sh "/nonexistent/path" 2>&1) && return 1

  echo "${output}" | grep -qi "does not exist" || return 1

  return 0
}

function test-import-new-false-does-not-import-new-files() {

  local dest repo
  dest=$(make-dest "new-false")
  repo=$(make-repo "new-false")
  local new_file=".github/prompts/enforce.brand-new-skip.prompt.md"
  echo "# Brand new prompt" > "${dest}/${new_file}"

  # force=true but new=false (default)
  LOADOUT_IMPORT_REPO_ROOT="${repo}" force=true ./scripts/import.sh "${dest}" > /dev/null 2>&1

  [[ ! -f "${repo}/${new_file}" ]] || return 1

  return 0
}

# Consolidated: detect modifications across instruction, skill, prompt and
# shared-resource files in one dry-run import, and validate the changed-count
# summary.
function test-import-dry-run-detects-modifications-across-tracked-types() {

  local dest repo
  dest=$(make-dest "detect-modifications")
  repo=$(make-repo "detect-modifications")
  echo "# Modified instruction" >> "${dest}/.github/instructions/shell.instructions.md"
  echo "# Modified skill" >> "${dest}/.github/skills/repository-template/SKILL.md"
  echo "# Modified prompt" >> "${dest}/.github/prompts/enforce.shell.prompt.md"
  echo "# Modified setup script" >> "${dest}/.specify/scripts/python/setup_plan.py"
  echo "# Modified constitution" >> "${dest}/.specify/memory/constitution.md"

  local output
  output=$(LOADOUT_IMPORT_REPO_ROOT="${repo}" ./scripts/import.sh "${dest}" 2>&1)

  echo "${output}" | grep -q "shell.instructions.md" || return 1
  echo "${output}" | grep -q "repository-template/SKILL.md" || return 1
  echo "${output}" | grep -q "enforce.shell.prompt.md" || return 1
  echo "${output}" | grep -q ".specify/scripts/python/setup_plan.py" || return 1
  echo "${output}" | grep -q "constitution.md" || return 1
  echo "${output}" | grep -q "Changed files (5)" || return 1

  return 0
}

# Consolidated: detect new files (top-level, nested, and singleton) and
# validate the new-files summary count.
function test-import-dry-run-detects-new-files() {

  local dest repo
  dest=$(make-dest "detect-new-files")
  repo=$(make-repo "detect-new-files")
  # Top-level new prompt
  echo "# New prompt" > "${dest}/.github/prompts/enforce.custom.prompt.md"
  # Nested new file inside includes/
  local nested_dir=".github/instructions/includes/sub"
  mkdir -p "${dest}/${nested_dir}"
  echo "# Nested include" > "${dest}/${nested_dir}/nested.md"
  # Singleton file that is missing from the repo snapshot
  rm -f "${repo}/.github/copilot-instructions.md"
  echo "# New singleton copy" >> "${dest}/.github/copilot-instructions.md"

  local output
  output=$(LOADOUT_IMPORT_REPO_ROOT="${repo}" ./scripts/import.sh "${dest}" 2>&1)

  echo "${output}" | grep -q "enforce.custom.prompt.md" || return 1
  echo "${output}" | grep -q "nested.md" || return 1
  echo "${output}" | grep -q ".github/copilot-instructions.md" || return 1
  echo "${output}" | grep -q "New files in destination (3)" || return 1

  return 0
}

# Consolidated: force=true must round-trip changes for one or more files.
function test-import-force-copies-changed-files-back() {

  local dest repo
  dest=$(make-dest "force-copy")
  repo=$(make-repo "force-copy")
  local marker
  marker="IMPORT-TEST-MARKER-$(date +%s)"
  echo "# ${marker}" >> "${dest}/.github/instructions/shell.instructions.md"
  echo "# ${marker}" >> "${dest}/.github/instructions/docker.instructions.md"

  LOADOUT_IMPORT_REPO_ROOT="${repo}" force=true ./scripts/import.sh "${dest}" > /dev/null 2>&1

  grep -q "${marker}" "${repo}/.github/instructions/shell.instructions.md" || return 1
  grep -q "${marker}" "${repo}/.github/instructions/docker.instructions.md" || return 1

  return 0
}

# Consolidated: hook config and hook scripts must all be detected in one
# dry-run and round-trip in one force run; hook scripts keep their executable
# bit.
function test-import-detects-and-round-trips-singletons-and-hooks() {

  local dest repo
  dest=$(make-dest "singletons-and-hooks")
  repo=$(make-repo "singletons-and-hooks")

  local marker
  marker="SINGLETON-HOOK-MARKER-$(date +%s)"
  printf '\n' >> "${dest}/.github/hooks/quality-gates.json"
  echo "# ${marker}" >> "${dest}/scripts/hooks/session-start-cheatsheet.sh"
  echo "# ${marker}" >> "${dest}/scripts/hooks/stop-gate.sh"

  # Dry-run detection covers all three paths
  local output
  output=$(LOADOUT_IMPORT_REPO_ROOT="${repo}" ./scripts/import.sh "${dest}" 2>&1)
  echo "${output}" | grep -q "quality-gates.json" || return 1
  echo "${output}" | grep -q "session-start-cheatsheet.sh" || return 1
  echo "${output}" | grep -q "stop-gate.sh" || return 1

  # Force import round-trips the changes
  LOADOUT_IMPORT_REPO_ROOT="${repo}" force=true ./scripts/import.sh "${dest}" > /dev/null 2>&1
  diff -q "${dest}/.github/hooks/quality-gates.json" "${repo}/.github/hooks/quality-gates.json" > /dev/null 2>&1 || return 1
  grep -q "${marker}" "${repo}/scripts/hooks/session-start-cheatsheet.sh" || return 1
  grep -q "${marker}" "${repo}/scripts/hooks/stop-gate.sh" || return 1
  # Executable bits preserved
  [[ -x "${repo}/scripts/hooks/session-start-cheatsheet.sh" ]] || return 1
  [[ -x "${repo}/scripts/hooks/stop-gate.sh" ]] || return 1

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

if main "$@"; then
  exit 0
fi

exit 1
