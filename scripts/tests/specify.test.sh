#!/bin/bash
# shellcheck disable=SC2329

set -euo pipefail

# Test suite for the specify patching workflow.
#
# Usage:
#   $ ./scripts/tests/specify.test.sh
#
# Arguments (provided as environment variables):
#   VERBOSE=true  # Show all the executed commands, default is 'false'

# ==============================================================================

TEMP_DIR=""
REPO_ROOT=""

function main() {

  REPO_ROOT="$(git rev-parse --show-toplevel)"
  cd "${REPO_ROOT}"

  test-specify-suite-setup
  trap test-specify-suite-teardown EXIT INT TERM

  local tests=( \
    test-specify-passes-skills-init-option \
    test-specify-replaces-patched-skill-prologues \
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

function test-specify-suite-setup() {

  TEMP_DIR=$(mktemp -d)

  return 0
}

function test-specify-suite-teardown() {

  if [[ -n "${TEMP_DIR}" ]] && [[ -d "${TEMP_DIR}" ]]; then
    rm -rf "${TEMP_DIR}"
  fi

  return 0
}

# Create a temporary repository fixture for exercising scripts/specify.sh.
# Arguments:
#   $1=[fixture directory]
function create-specify-fixture-repo() {

  local fixture_dir="$1"

  mkdir -p "${fixture_dir}/scripts"
  mkdir -p "${fixture_dir}/.specify/extensions/copilot/skills"
  mkdir -p "${fixture_dir}/bin"

  cp "${REPO_ROOT}/scripts/specify.sh" "${fixture_dir}/scripts/specify.sh"
  cp "${REPO_ROOT}/.specify/extensions/manifest.yaml" "${fixture_dir}/.specify/extensions/manifest.yaml"
  cp "${REPO_ROOT}/.specify/extensions/copilot/skills/speckit-plan.ext.md" \
    "${fixture_dir}/.specify/extensions/copilot/skills/speckit-plan.ext.md"
  cp "${REPO_ROOT}/.specify/extensions/copilot/skills/speckit-tasks.ext.md" \
    "${fixture_dir}/.specify/extensions/copilot/skills/speckit-tasks.ext.md"
  cp "${REPO_ROOT}/.specify/extensions/copilot/skills/speckit-implement.ext.md" \
    "${fixture_dir}/.specify/extensions/copilot/skills/speckit-implement.ext.md"

  create-specify-stub "${fixture_dir}/bin/specify"
  create-curl-stub "${fixture_dir}/bin/curl"

  chmod +x "${fixture_dir}/scripts/specify.sh" \
    "${fixture_dir}/bin/specify" \
    "${fixture_dir}/bin/curl"

  return 0
}

# Create a stub specify CLI that emits a minimal upstream skills layout.
# Arguments:
#   $1=[stub path]
function create-specify-stub() {

  local stub_path="$1"

  cat <<'EOF' > "${stub_path}"
#!/bin/bash

set -euo pipefail

if [[ "${1:-}" == "--version" ]]; then
  echo "specify 0.16.1"
  exit 0
fi

printf '%s\n' "$*" >> "${SPECIFY_CALL_LOG}"

mkdir -p .github/skills/speckit-plan
mkdir -p .github/skills/speckit-tasks
mkdir -p .github/skills/speckit-implement
mkdir -p .github/skills/speckit-specify
mkdir -p .specify/templates
mkdir -p .specify/scripts/python

cat <<'PLAN' > .github/skills/speckit-plan/SKILL.md
---
name: "speckit-plan"
---

**Workflow context:**

- **Next phase:** Tasks generation (`/speckit.tasks`)

## Show & Tell Sections (Mandatory)

- State pass/fail criteria clearly so steps cannot be skipped or missed during `/speckit.implement`

## User Input
PLAN

cat <<'TASKS' > .github/skills/speckit-tasks/SKILL.md
---
name: "speckit-tasks"
---

**Workflow context:**

- **Next phase:** Implementation (`/speckit.implement`)

## Show & Tell Sections (Mandatory)

AI Assistant **MUST** execute every Show & Tell step during `/speckit.implement` and validate that the expected result is achieved.

## User Input
TASKS

cat <<'IMPLEMENT' > .github/skills/speckit-implement/SKILL.md
---
name: "speckit-implement"
---

Old implementation instructions.

## User Input
IMPLEMENT

cat <<'SPECIFY' > .github/skills/speckit-specify/SKILL.md
---
name: "speckit-specify"
---

## User Input
SPECIFY

cat <<'TEMPLATE' > .specify/templates/plan-template.md
# plan template
TEMPLATE

cat <<'PYTHON' > .specify/scripts/python/setup_plan.py
print("setup plan")
PYTHON
EOF

  return 0
}

# Create a curl stub so the test never depends on network access.
# Arguments:
#   $1=[stub path]
function create-curl-stub() {

  local stub_path="$1"

  cat <<'EOF' > "${stub_path}"
#!/bin/bash

set -euo pipefail

cat <<'JSON'
{"tag_name":"v0.16.1"}
JSON
EOF

  return 0
}

# Run scripts/specify.sh inside a fixture repository.
# Arguments:
#   $1=[fixture name]
# Returns:
#   Fixture directory path (via stdout)
function run-specify-fixture() {

  local fixture_name="$1"
  local fixture_dir="${TEMP_DIR}/${fixture_name}"

  create-specify-fixture-repo "${fixture_dir}"

  SPECIFY_CALL_LOG="${fixture_dir}/specify-calls.log" \
    PATH="${fixture_dir}/bin:${PATH}" \
    "${fixture_dir}/scripts/specify.sh" > "${fixture_dir}/run.log" 2>&1

  echo "${fixture_dir}"

  return 0
}

# ==============================================================================

function test-specify-passes-skills-init-option() {

  local fixture_dir
  fixture_dir=$(run-specify-fixture "skills-option")

  grep -qF -- "--integration-options=--skills" "${fixture_dir}/specify-calls.log" || return 1

  return 0
}

function test-specify-replaces-patched-skill-prologues() {

  local fixture_dir
  fixture_dir=$(run-specify-fixture "replace-prologue")

  grep -qF "/speckit-tasks" "${fixture_dir}/.github/skills/speckit-plan/SKILL.md" || return 1
  ! grep -qF "/speckit.tasks" "${fixture_dir}/.github/skills/speckit-plan/SKILL.md" || return 1

  grep -qF "/speckit-implement" "${fixture_dir}/.github/skills/speckit-tasks/SKILL.md" || return 1
  ! grep -qF "/speckit.implement" "${fixture_dir}/.github/skills/speckit-tasks/SKILL.md" || return 1

  grep -qF "Follow TDD: write failing test first" "${fixture_dir}/.github/skills/speckit-implement/SKILL.md" || return 1
  ! grep -qF "Old implementation instructions" "${fixture_dir}/.github/skills/speckit-implement/SKILL.md" || return 1

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
