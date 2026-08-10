#!/bin/bash
# shellcheck disable=SC2329

set -euo pipefail

# Test suite for the apply command.
#
# Optimised for speed: shared apply destinations are pre-built in parallel
# during suite setup and reused by read-only assertion tests. Tests that
# mutate destinations (revert, clean, idempotency, skips, subset, fails)
# run their own apply invocations.
#
# Usage:
#   $ ./apply.test.sh
#
# Arguments (provided as environment variables):
#   VERBOSE=true  # Show all the executed commands, default is 'false'

# ==============================================================================

TEMP_DIR=""
DEFAULT_DEST=""
ALL_DEST=""
REVERT_DEST=""

# Subset shared dests
SUBSET_AGENTS_DEST=""
SUBSET_PROMPTS_AGENTS_DEST=""
SUBSET_INSTR_PY_DEST=""
SUBSET_SPECKIT_DEST=""
SUBSET_DOCS_DEST=""
SUBSET_PROJECT_DEST=""

function main() {

  cd "$(git rev-parse --show-toplevel)"

  test-apply-suite-setup
  local tests=( \
    test-apply-no-args-fails \
    test-apply-empty-dest-fails \
    test-apply-creates-destination-directory \
    test-apply-normalises-escaped-space-destination \
    test-apply-default-copies-expected-artefacts \
    test-apply-default-excludes-tech-files \
    test-apply-all-copies-all-tech-files \
    test-apply-tauri-auto-enables-rust-typescript-reactjs \
    test-apply-django-auto-enables-python-and-copies-skill \
    test-apply-fastapi-auto-enables-python-and-copies-skill \
    test-apply-playwright-python-copies-both-instructions \
    test-apply-playwright-without-lang-fails \
    test-apply-clean-removes-previous-tech-files \
    test-apply-revert-removes-all-managed-artefacts \
    test-apply-idempotent-same-file-count \
    test-apply-skips-existing-singletons \
    test-apply-updates-existing-gitignore-managed-section \
    test-apply-subset-omitted-equivalent-to-default \
    test-apply-subset-all-equivalent-to-default \
    test-apply-subset-agents-only \
    test-apply-subset-prompts-and-agents \
    test-apply-subset-instructions-only-with-python-tech \
    test-apply-subset-invalid-value-fails-with-helpful-message \
    test-apply-subset-comma-whitespace-trimmed \
    test-apply-subset-speckit-only-narrows-skills-and-prompts \
    test-apply-subset-docs-only \
    test-apply-subset-project-only \
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
  test-apply-suite-teardown
  [ $status -gt 0 ] && return 1 || return 0
}

# ==============================================================================

function test-apply-suite-setup() {

  TEMP_DIR=$(mktemp -d)
  DEFAULT_DEST="${TEMP_DIR}/_shared_default"
  ALL_DEST="${TEMP_DIR}/_shared_all"
  REVERT_DEST="${TEMP_DIR}/_shared_revert"
  SUBSET_AGENTS_DEST="${TEMP_DIR}/_subset_agents"
  SUBSET_PROMPTS_AGENTS_DEST="${TEMP_DIR}/_subset_prompts_agents"
  SUBSET_INSTR_PY_DEST="${TEMP_DIR}/_subset_instr_py"
  SUBSET_SPECKIT_DEST="${TEMP_DIR}/_subset_speckit"
  SUBSET_DOCS_DEST="${TEMP_DIR}/_subset_docs"
  SUBSET_PROJECT_DEST="${TEMP_DIR}/_subset_project"

  # Pre-build read-only destinations in parallel.
  (./scripts/apply.sh "${DEFAULT_DEST}" > /dev/null 2>&1) &
  (all=true ./scripts/apply.sh "${ALL_DEST}" > /dev/null 2>&1) &
  (./scripts/apply.sh "${REVERT_DEST}" > /dev/null 2>&1 && \
    revert=true ./scripts/apply.sh "${REVERT_DEST}" > /dev/null 2>&1) &
  (subset=agents ./scripts/apply.sh "${SUBSET_AGENTS_DEST}" > /dev/null 2>&1) &
  (subset="prompts,agents" ./scripts/apply.sh "${SUBSET_PROMPTS_AGENTS_DEST}" > /dev/null 2>&1) &
  (subset=instructions python=true ./scripts/apply.sh "${SUBSET_INSTR_PY_DEST}" > /dev/null 2>&1) &
  (subset=speckit ./scripts/apply.sh "${SUBSET_SPECKIT_DEST}" > /dev/null 2>&1) &
  (subset=docs ./scripts/apply.sh "${SUBSET_DOCS_DEST}" > /dev/null 2>&1) &
  (subset=project ./scripts/apply.sh "${SUBSET_PROJECT_DEST}" > /dev/null 2>&1) &
  wait

  return 0
}

function test-apply-suite-teardown() {

  if [[ -n "${TEMP_DIR}" ]] && [[ -d "${TEMP_DIR}" ]]; then
    rm -rf "${TEMP_DIR}"
  fi

  return 0
}

# Helper: run apply.sh directly with optional env vars.
# Arguments:
#   $1=[destination directory path]
#   $2..=[optional env var assignments, e.g. "python=true"]
function helper-apply() {

  local dest="$1"
  shift
  env "$@" ./scripts/apply.sh "${dest}" > /dev/null 2>&1

  return $?
}

# ==============================================================================
# Argument validation

function test-apply-no-args-fails() {

  local output
  output=$(./scripts/apply.sh 2>&1) && return 1
  echo "${output}" | grep -qi "usage" || return 1
  return 0
}

function test-apply-empty-dest-fails() {

  local output
  output=$(./scripts/apply.sh "" 2>&1) && return 1
  echo "${output}" | grep -qi "empty" || return 1
  return 0
}

function test-apply-creates-destination-directory() {

  local dest="${TEMP_DIR}/creates-dest/nested/dir"
  helper-apply "${dest}" || return 1
  [[ -d "${dest}" ]] || return 1
  return 0
}

function test-apply-normalises-escaped-space-destination() {

  local root_dir="${TEMP_DIR}/workspace"
  local expected_destination="${root_dir}/Mobile Documents/iCloud~md~obsidian/Documents"
  local escaped_destination="${root_dir}/Mobile\\ Documents/iCloud~md~obsidian/Documents"

  mkdir -p "${root_dir}"
  make apply dest="${escaped_destination}" > /dev/null 2>&1 || return 1
  [[ -f "${expected_destination}/project.code-workspace" ]] || return 1
  [[ -d "${expected_destination}/.github/agents" ]] || return 1
  [[ ! -d "${root_dir}/Mobile\\ Documents" ]] || return 1
  return 0
}

# ==============================================================================
# Default apply (read-only checks against shared DEFAULT_DEST)

function test-apply-default-copies-expected-artefacts() {

  local d="${DEFAULT_DEST}"
  # Agents
  [[ -d "${d}/.github/agents" ]] || return 1
  [[ $(find "${d}/.github/agents" -name "*.md" -type f | wc -l | tr -d ' ') -gt 0 ]] || return 1
  # Default instructions
  [[ -f "${d}/.github/instructions/shell.instructions.md" ]] || return 1
  [[ -f "${d}/.github/instructions/docker.instructions.md" ]] || return 1
  [[ -f "${d}/.github/instructions/makefile.instructions.md" ]] || return 1
  [[ -f "${d}/.github/instructions/readme.instructions.md" ]] || return 1
  # Default prompts
  [[ -f "${d}/.github/prompts/enforce.shell.prompt.md" ]] || return 1
  [[ -f "${d}/.github/prompts/enforce.docker.prompt.md" ]] || return 1
  [[ -f "${d}/.github/prompts/enforce.makefile.prompt.md" ]] || return 1
  [[ -f "${d}/.github/prompts/spec.consolidate.prompt.md" ]] || return 1
  # Skills (default set)
  [[ -f "${d}/.github/skills/repository-template/SKILL.md" ]] || return 1
  [[ -f "${d}/.github/skills/enforcement-audit/SKILL.md" ]] || return 1
  [[ -f "${d}/.github/skills/architecture-docs/SKILL.md" ]] || return 1
  [[ -f "${d}/.github/skills/code-review/SKILL.md" ]] || return 1
  [[ -f "${d}/.github/skills/spec-consolidation/SKILL.md" ]] || return 1
  [[ -f "${d}/.github/skills/system-documentation/SKILL.md" ]] || return 1
  # Singleton files
  [[ -f "${d}/.github/copilot-instructions.md" ]] || return 1
  [[ -f "${d}/project.code-workspace" ]] || return 1
  [[ -f "${d}/.github/pull_request_template.md" ]] || return 1
  # Shared resources
  [[ -d "${d}/.specify/memory" ]] || return 1
  [[ -d "${d}/.specify/scripts/python" ]] || return 1
  [[ -d "${d}/.specify/templates" ]] || return 1
  [[ -f "${d}/docs/adr/ADR-nnn_Any_Decision_Record_Template.md" ]] || return 1
  [[ -f "${d}/docs/adr/Tech_Radar.md" ]] || return 1
  [[ -d "${d}/docs/prompt-reports" ]] || return 1
  # VS Code settings
  [[ -f "${d}/.vscode/settings.json" ]] || return 1
  grep -q "chat.skillRecommendations" "${d}/.vscode/settings.json" || return 1
  grep -q "chat.tools.terminal.autoApprove" "${d}/.vscode/settings.json" || return 1
  # .gitignore
  [[ -f "${d}/.gitignore" ]] || return 1
  grep -qF "loadout managed content" "${d}/.gitignore" || return 1
  # Hooks
  [[ -f "${d}/.github/hooks/quality-gates.json" ]] || return 1
  [[ -x "${d}/scripts/hooks/post-edit-lint.sh" ]] || return 1
  [[ -x "${d}/scripts/hooks/stop-gate.sh" ]] || return 1
  return 0
}

function test-apply-default-excludes-tech-files() {

  local d="${DEFAULT_DEST}"
  # Tech-specific instructions absent
  [[ ! -f "${d}/.github/instructions/python.instructions.md" ]] || return 1
  [[ ! -f "${d}/.github/instructions/typescript.instructions.md" ]] || return 1
  [[ ! -f "${d}/.github/instructions/go.instructions.md" ]] || return 1
  [[ ! -f "${d}/.github/instructions/rust.instructions.md" ]] || return 1
  # Tech-specific prompts absent
  [[ ! -f "${d}/.github/prompts/enforce.python.prompt.md" ]] || return 1
  [[ ! -f "${d}/.github/prompts/enforce.typescript.prompt.md" ]] || return 1
  [[ ! -f "${d}/.github/prompts/enforce.go.prompt.md" ]] || return 1
  # Tech-specific skills absent
  [[ ! -d "${d}/.github/skills/django-project" ]] || return 1
  [[ ! -d "${d}/.github/skills/fastapi-project" ]] || return 1
  return 0
}

# ==============================================================================
# all=true (read-only checks against shared ALL_DEST)

function test-apply-all-copies-all-tech-files() {

  local d="${ALL_DEST}"
  # Instructions
  [[ -f "${d}/.github/instructions/python.instructions.md" ]] || return 1
  [[ -f "${d}/.github/instructions/typescript.instructions.md" ]] || return 1
  [[ -f "${d}/.github/instructions/go.instructions.md" ]] || return 1
  [[ -f "${d}/.github/instructions/rust.instructions.md" ]] || return 1
  [[ -f "${d}/.github/instructions/reactjs.instructions.md" ]] || return 1
  [[ -f "${d}/.github/instructions/terraform.instructions.md" ]] || return 1
  [[ -f "${d}/.github/instructions/tauri.instructions.md" ]] || return 1
  [[ -f "${d}/.github/instructions/playwright-python.instructions.md" ]] || return 1
  [[ -f "${d}/.github/instructions/playwright-typescript.instructions.md" ]] || return 1
  # Prompts
  [[ -f "${d}/.github/prompts/enforce.python.prompt.md" ]] || return 1
  [[ -f "${d}/.github/prompts/enforce.typescript.prompt.md" ]] || return 1
  [[ -f "${d}/.github/prompts/enforce.go.prompt.md" ]] || return 1
  [[ -f "${d}/.github/prompts/enforce.rust.prompt.md" ]] || return 1
  [[ -f "${d}/.github/prompts/enforce.reactjs.prompt.md" ]] || return 1
  [[ -f "${d}/.github/prompts/enforce.terraform.prompt.md" ]] || return 1
  [[ -f "${d}/.github/prompts/enforce.tauri.prompt.md" ]] || return 1
  [[ -f "${d}/.github/prompts/enforce.playwright-python.prompt.md" ]] || return 1
  [[ -f "${d}/.github/prompts/enforce.playwright-typescript.prompt.md" ]] || return 1
  # Templates
  [[ -f "${d}/.github/instructions/templates/pyproject.toml" ]] || return 1
  # Skills
  [[ -d "${d}/.github/skills/django-project" ]] || return 1
  [[ -d "${d}/.github/skills/fastapi-project" ]] || return 1
  [[ -d "${d}/.github/skills/repository-template" ]] || return 1
  return 0
}

# ==============================================================================
# Auto-enable technology switches

function test-apply-tauri-auto-enables-rust-typescript-reactjs() {

  local dest="${TEMP_DIR}/tauri-auto"
  tauri=true helper-apply "${dest}" || return 1
  [[ -f "${dest}/.github/instructions/tauri.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/prompts/enforce.tauri.prompt.md" ]] || return 1
  [[ -f "${dest}/.github/instructions/rust.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/instructions/typescript.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/instructions/reactjs.instructions.md" ]] || return 1
  return 0
}

function test-apply-django-auto-enables-python-and-copies-skill() {

  local dest="${TEMP_DIR}/django-combined"
  django=true helper-apply "${dest}" || return 1
  [[ -f "${dest}/.github/instructions/python.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/prompts/enforce.python.prompt.md" ]] || return 1
  [[ -f "${dest}/.github/skills/django-project/SKILL.md" ]] || return 1
  return 0
}

function test-apply-fastapi-auto-enables-python-and-copies-skill() {

  local dest="${TEMP_DIR}/fastapi-combined"
  fastapi=true helper-apply "${dest}" || return 1
  [[ -f "${dest}/.github/instructions/python.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/prompts/enforce.python.prompt.md" ]] || return 1
  [[ -f "${dest}/.github/skills/fastapi-project/SKILL.md" ]] || return 1
  return 0
}

function test-apply-playwright-python-copies-both-instructions() {

  local dest="${TEMP_DIR}/playwright-py"
  python=true playwright=true helper-apply "${dest}" || return 1
  [[ -f "${dest}/.github/instructions/playwright-python.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/prompts/enforce.playwright-python.prompt.md" ]] || return 1
  return 0
}

function test-apply-playwright-without-lang-fails() {

  local dest="${TEMP_DIR}/playwright-no-lang"
  playwright=true helper-apply "${dest}" && return 1
  [[ ! -f "${dest}/.github/copilot-instructions.md" ]] || return 1
  return 0
}

# ==============================================================================
# Clean / revert / idempotency / skip behaviour

function test-apply-clean-removes-previous-tech-files() {

  local dest="${TEMP_DIR}/clean-removes"
  python=true helper-apply "${dest}" || return 1
  [[ -f "${dest}/.github/instructions/python.instructions.md" ]] || return 1

  clean=true helper-apply "${dest}" || return 1
  [[ ! -f "${dest}/.github/instructions/python.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/instructions/shell.instructions.md" ]] || return 1
  return 0
}

function test-apply-revert-removes-all-managed-artefacts() {

  local d="${REVERT_DEST}"
  # Managed directories removed
  [[ ! -d "${d}/.github/agents" ]] || return 1
  [[ ! -d "${d}/.github/instructions" ]] || return 1
  [[ ! -d "${d}/.github/prompts" ]] || return 1
  [[ ! -d "${d}/.github/skills" ]] || return 1
  [[ ! -d "${d}/.github/hooks" ]] || return 1
  [[ ! -d "${d}/.specify" ]] || return 1
  [[ ! -d "${d}/scripts/hooks" ]] || return 1
  # Singleton files removed
  [[ ! -f "${d}/.github/copilot-instructions.md" ]] || return 1
  # VS Code settings managed properties removed (file may or may not still exist)
  if [[ -f "${d}/.vscode/settings.json" ]]; then
    ! grep -q "chat.skillRecommendations" "${d}/.vscode/settings.json" || return 1
    ! grep -q "chat.tools.terminal.autoApprove" "${d}/.vscode/settings.json" || return 1
  fi
  # gitignore managed section removed (file itself may be gone if it was empty)
  if [[ -f "${d}/.gitignore" ]]; then
    ! grep -qF "loadout managed content" "${d}/.gitignore" || return 1
  fi
  return 0
}

function test-apply-idempotent-same-file-count() {

  local dest="${TEMP_DIR}/idempotent"
  all=true helper-apply "${dest}" || return 1
  local count1
  count1=$(find "${dest}" -type f | wc -l | tr -d ' ')

  all=true helper-apply "${dest}" || return 1
  local count2
  count2=$(find "${dest}" -type f | wc -l | tr -d ' ')

  [[ "${count1}" == "${count2}" ]] || return 1
  return 0
}

function test-apply-skips-existing-singletons() {

  local dest="${TEMP_DIR}/skip-singletons"
  mkdir -p "${dest}/.github"
  echo "custom-workspace-content" > "${dest}/project.code-workspace"
  echo "custom-pr-template" > "${dest}/.github/pull_request_template.md"

  helper-apply "${dest}" || return 1

  grep -q "custom-workspace-content" "${dest}/project.code-workspace" || return 1
  grep -q "custom-pr-template" "${dest}/.github/pull_request_template.md" || return 1
  return 0
}

function test-apply-updates-existing-gitignore-managed-section() {

  local dest="${TEMP_DIR}/update-gitignore"
  mkdir -p "${dest}"
  {
    echo "# Custom rules"
    echo "*.log"
    echo "# >>> loadout managed content - DO NOT EDIT BELOW THIS LINE >>>"
    echo "old-managed-content"
    echo "# <<< loadout managed content - DO NOT EDIT ABOVE THIS LINE <<<"
  } > "${dest}/.gitignore"

  helper-apply "${dest}" || return 1

  ! grep -q "old-managed-content" "${dest}/.gitignore" || return 1
  grep -q "Custom rules" "${dest}/.gitignore" || return 1
  grep -qF "loadout managed content" "${dest}/.gitignore" || return 1
  return 0
}

# ==============================================================================
# Subset selector

function test-apply-subset-omitted-equivalent-to-default() {

  local dest_omitted="${TEMP_DIR}/subset-omitted"
  subset="" helper-apply "${dest_omitted}" || return 1
  local count_default count_omitted
  count_default=$(find "${DEFAULT_DEST}" -type f | wc -l | tr -d ' ')
  count_omitted=$(find "${dest_omitted}" -type f | wc -l | tr -d ' ')
  [[ "${count_default}" == "${count_omitted}" ]] || return 1
  return 0
}

function test-apply-subset-all-equivalent-to-default() {

  local dest_all="${TEMP_DIR}/subset-all"
  subset=all helper-apply "${dest_all}" || return 1
  local count_default count_all
  count_default=$(find "${DEFAULT_DEST}" -type f | wc -l | tr -d ' ')
  count_all=$(find "${dest_all}" -type f | wc -l | tr -d ' ')
  [[ "${count_default}" == "${count_all}" ]] || return 1
  return 0
}

function test-apply-subset-agents-only() {

  local d="${SUBSET_AGENTS_DEST}"
  [[ -d "${d}/.github/agents" ]] || return 1
  [[ $(find "${d}/.github/agents" -name "*.md" -type f | wc -l | tr -d ' ') -gt 0 ]] || return 1
  [[ ! -d "${d}/.github/prompts" ]] || return 1
  [[ ! -d "${d}/.github/skills" ]] || return 1
  [[ ! -f "${d}/.github/copilot-instructions.md" ]] || return 1
  return 0
}

function test-apply-subset-prompts-and-agents() {

  local d="${SUBSET_PROMPTS_AGENTS_DEST}"
  [[ -d "${d}/.github/agents" ]] || return 1
  [[ -d "${d}/.github/prompts" ]] || return 1
  [[ -f "${d}/.github/prompts/enforce.shell.prompt.md" ]] || return 1
  [[ ! -d "${d}/.github/skills" ]] || return 1
  [[ ! -d "${d}/.github/instructions" ]] || return 1
  return 0
}

function test-apply-subset-instructions-only-with-python-tech() {

  local d="${SUBSET_INSTR_PY_DEST}"
  [[ -f "${d}/.github/instructions/python.instructions.md" ]] || return 1
  [[ -f "${d}/.github/instructions/shell.instructions.md" ]] || return 1
  [[ ! -d "${d}/.github/prompts" ]] || return 1
  [[ ! -d "${d}/.github/skills" ]] || return 1
  return 0
}

function test-apply-subset-invalid-value-fails-with-helpful-message() {

  local dest="${TEMP_DIR}/subset-invalid"
  mkdir -p "${dest}"
  local output
  output=$(subset=bogus ./scripts/apply.sh "${dest}" 2>&1) && return 1
  echo "${output}" | grep -qF "Valid values:" || return 1
  echo "${output}" | grep -qF "bogus" || return 1
  return 0
}

function test-apply-subset-comma-whitespace-trimmed() {

  local dest="${TEMP_DIR}/subset-whitespace"
  subset=" prompts , agents " helper-apply "${dest}" || return 1
  [[ -d "${dest}/.github/agents" ]] || return 1
  [[ -d "${dest}/.github/prompts" ]] || return 1
  [[ ! -d "${dest}/.github/instructions" ]] || return 1
  return 0
}

function test-apply-subset-speckit-only-narrows-skills-and-prompts() {

  local d="${SUBSET_SPECKIT_DEST}"
  [[ -d "${d}/.github/skills/speckit-specify" ]] || return 1
  [[ -d "${d}/.github/skills/speckit-implement" ]] || return 1
  [[ ! -d "${d}/.github/skills/repository-template" ]] || return 1
  [[ -f "${d}/.github/prompts/review.speckit-code.prompt.md" ]] || return 1
  [[ ! -f "${d}/.github/prompts/enforce.shell.prompt.md" ]] || return 1
  [[ ! -f "${d}/.github/prompts/enforce.docker.prompt.md" ]] || return 1
  [[ ! -f "${d}/.github/prompts/util.git-commit-message.prompt.md" ]] || return 1
  [[ -d "${d}/.specify/memory" ]] || return 1
  [[ -d "${d}/.specify/templates" ]] || return 1
  [[ ! -d "${d}/.github/instructions" ]] || return 1
  [[ ! -d "${d}/.github/agents" ]] || return 1
  return 0
}

function test-apply-subset-docs-only() {

  local d="${SUBSET_DOCS_DEST}"
  [[ -f "${d}/docs/adr/ADR-nnn_Any_Decision_Record_Template.md" ]] || return 1
  [[ -f "${d}/docs/adr/Tech_Radar.md" ]] || return 1
  [[ -d "${d}/docs/prompt-reports" ]] || return 1
  [[ ! -d "${d}/.github/agents" ]] || return 1
  [[ ! -d "${d}/.github/prompts" ]] || return 1
  return 0
}

function test-apply-subset-project-only() {

  local d="${SUBSET_PROJECT_DEST}"
  [[ -f "${d}/.vscode/settings.json" ]] || return 1
  [[ -f "${d}/project.code-workspace" ]] || return 1
  [[ -f "${d}/.gitignore" ]] || return 1
  [[ -f "${d}/.github/copilot-instructions.md" ]] || return 1
  [[ -f "${d}/.github/pull_request_template.md" ]] || return 1
  [[ ! -d "${d}/.github/agents" ]] || return 1
  [[ ! -d "${d}/.github/prompts" ]] || return 1
  [[ ! -d "${d}/.github/instructions" ]] || return 1
  [[ ! -d "${d}/.github/skills" ]] || return 1
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
