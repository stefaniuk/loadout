#!/bin/bash
# shellcheck disable=SC2329

set -euo pipefail

# Test suite for the apply command.
#
# Usage:
#   $ ./apply.test.sh
#
# Arguments (provided as environment variables):
#   VERBOSE=true  # Show all the executed commands, default is 'false'

# ==============================================================================

TEMP_DIR=""

function main() {

  cd "$(git rev-parse --show-toplevel)"

  test-apply-suite-setup
  local tests=( \
    test-apply-no-args-fails \
    test-apply-empty-dest-fails \
    test-apply-creates-destination-directory \
    test-apply-normalises-escaped-space-destination \
    test-apply-default-copies-agents \
    test-apply-default-copies-default-instructions \
    test-apply-default-excludes-tech-instructions \
    test-apply-default-copies-default-prompts \
    test-apply-default-excludes-tech-prompts \
    test-apply-default-copies-repository-template-skill \
    test-apply-default-excludes-tech-skills \
    test-apply-default-copies-copilot-instructions-md \
    test-apply-default-copies-shared-resources \
    test-apply-default-copies-vscode-settings \
    test-apply-default-copies-gitignore \
    test-apply-default-copies-workspace-file \
    test-apply-default-copies-pull-request-template \
    test-apply-python-copies-python-instruction \
    test-apply-python-copies-python-prompt \
    test-apply-python-copies-pyproject-template \
    test-apply-typescript-copies-typescript-instruction \
    test-apply-go-copies-go-instruction \
    test-apply-rust-copies-rust-instruction \
    test-apply-reactjs-copies-reactjs-instruction \
    test-apply-terraform-copies-terraform-instruction \
    test-apply-tauri-auto-enables-rust-typescript-reactjs \
    test-apply-django-auto-enables-python \
    test-apply-django-copies-django-skill \
    test-apply-fastapi-auto-enables-python \
    test-apply-fastapi-copies-fastapi-skill \
    test-apply-playwright-python-copies-both-instructions \
    test-apply-playwright-without-lang-fails \
    test-apply-all-copies-all-tech-instructions \
    test-apply-all-copies-all-tech-prompts \
    test-apply-all-copies-all-tech-skills \
    test-apply-clean-removes-previous-tech-files \
    test-apply-revert-removes-github-dirs \
    test-apply-revert-removes-specify-dir \
    test-apply-revert-removes-gitignore-managed-section \
    test-apply-revert-removes-vscode-settings-properties \
    test-apply-idempotent-same-file-count \
    test-apply-skips-existing-workspace-file \
    test-apply-skips-existing-pull-request-template \
    test-apply-updates-existing-gitignore-managed-section \
    test-apply-default-copies-agents-md \
    test-apply-default-copies-hooks \
    test-apply-default-copies-hook-scripts \
    test-apply-default-copies-enforcement-audit-skill \
    test-apply-default-copies-architecture-docs-skill \
    test-apply-default-copies-code-review-skill \
    test-apply-revert-removes-agents-md \
    test-apply-revert-removes-hooks \
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
  test-apply-suite-teardown
  [ $status -gt 0 ] && return 1 || return 0
}

# ==============================================================================

function test-apply-suite-setup() {

  TEMP_DIR=$(mktemp -d)

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

function test-apply-no-args-fails() {

  # Arrange / Act
  local output
  output=$(./scripts/apply.sh 2>&1) && return 1

  # Assert
  echo "${output}" | grep -qi "usage" || return 1

  return 0
}

function test-apply-empty-dest-fails() {

  # Arrange / Act
  local output
  output=$(./scripts/apply.sh "" 2>&1) && return 1

  # Assert
  echo "${output}" | grep -qi "empty" || return 1

  return 0
}

function test-apply-creates-destination-directory() {

  # Arrange
  local dest="${TEMP_DIR}/creates-dest/nested/dir"

  # Act
  helper-apply "${dest}" || return 1

  # Assert
  [[ -d "${dest}" ]] || return 1

  return 0
}

function test-apply-normalises-escaped-space-destination() {

  # Arrange
  local root_dir="${TEMP_DIR}/workspace"
  local expected_destination="${root_dir}/Mobile Documents/iCloud~md~obsidian/Documents"
  local escaped_destination="${root_dir}/Mobile\\ Documents/iCloud~md~obsidian/Documents"

  mkdir -p "${root_dir}"

  # Act
  make apply dest="${escaped_destination}" > /dev/null 2>&1 || return 1

  # Assert
  [[ -f "${expected_destination}/project.code-workspace" ]] || return 1
  [[ -d "${expected_destination}/.github/agents" ]] || return 1
  [[ ! -d "${root_dir}/Mobile\\ Documents" ]] || return 1

  return 0
}

# --- Default apply tests ---

function test-apply-default-copies-agents() {

  # Arrange
  local dest="${TEMP_DIR}/default-agents"

  # Act
  helper-apply "${dest}" || return 1

  # Assert
  [[ -d "${dest}/.github/agents" ]] || return 1
  local agent_count
  agent_count=$(find "${dest}/.github/agents" -maxdepth 1 -name "*.md" -type f | wc -l | tr -d ' ')
  [[ "${agent_count}" -gt 0 ]] || return 1

  return 0
}

function test-apply-default-copies-default-instructions() {

  # Arrange
  local dest="${TEMP_DIR}/default-instructions"

  # Act
  helper-apply "${dest}" || return 1

  # Assert
  [[ -f "${dest}/.github/instructions/shell.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/instructions/docker.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/instructions/makefile.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/instructions/readme.instructions.md" ]] || return 1

  return 0
}

function test-apply-default-excludes-tech-instructions() {

  # Arrange
  local dest="${TEMP_DIR}/default-no-tech"

  # Act
  helper-apply "${dest}" || return 1

  # Assert — technology-specific instructions must not be present
  [[ ! -f "${dest}/.github/instructions/python.instructions.md" ]] || return 1
  [[ ! -f "${dest}/.github/instructions/typescript.instructions.md" ]] || return 1
  [[ ! -f "${dest}/.github/instructions/go.instructions.md" ]] || return 1
  [[ ! -f "${dest}/.github/instructions/rust.instructions.md" ]] || return 1

  return 0
}

function test-apply-default-copies-default-prompts() {

  # Arrange
  local dest="${TEMP_DIR}/default-prompts"

  # Act
  helper-apply "${dest}" || return 1

  # Assert
  [[ -f "${dest}/.github/prompts/enforce.shell.prompt.md" ]] || return 1
  [[ -f "${dest}/.github/prompts/enforce.docker.prompt.md" ]] || return 1
  [[ -f "${dest}/.github/prompts/enforce.makefile.prompt.md" ]] || return 1

  return 0
}

function test-apply-default-excludes-tech-prompts() {

  # Arrange
  local dest="${TEMP_DIR}/default-no-tech-prompts"

  # Act
  helper-apply "${dest}" || return 1

  # Assert
  [[ ! -f "${dest}/.github/prompts/enforce.python.prompt.md" ]] || return 1
  [[ ! -f "${dest}/.github/prompts/enforce.typescript.prompt.md" ]] || return 1
  [[ ! -f "${dest}/.github/prompts/enforce.go.prompt.md" ]] || return 1

  return 0
}

function test-apply-default-copies-repository-template-skill() {

  # Arrange
  local dest="${TEMP_DIR}/default-skills"

  # Act
  helper-apply "${dest}" || return 1

  # Assert
  [[ -d "${dest}/.github/skills/repository-template" ]] || return 1
  [[ -f "${dest}/.github/skills/repository-template/SKILL.md" ]] || return 1

  return 0
}

function test-apply-default-excludes-tech-skills() {

  # Arrange
  local dest="${TEMP_DIR}/default-no-tech-skills"

  # Act
  helper-apply "${dest}" || return 1

  # Assert
  [[ ! -d "${dest}/.github/skills/django-project" ]] || return 1
  [[ ! -d "${dest}/.github/skills/fastapi-project" ]] || return 1

  return 0
}

function test-apply-default-copies-copilot-instructions-md() {

  # Arrange
  local dest="${TEMP_DIR}/default-copilot-md"

  # Act
  helper-apply "${dest}" || return 1

  # Assert
  [[ -f "${dest}/.github/copilot-instructions.md" ]] || return 1

  return 0
}

function test-apply-default-copies-shared-resources() {

  # Arrange
  local dest="${TEMP_DIR}/default-shared"

  # Act
  helper-apply "${dest}" || return 1

  # Assert
  [[ -d "${dest}/.specify/memory" ]] || return 1
  [[ -d "${dest}/.specify/scripts/bash" ]] || return 1
  [[ -d "${dest}/.specify/templates" ]] || return 1
  [[ -f "${dest}/docs/adr/ADR-nnn_Any_Decision_Record_Template.md" ]] || return 1
  [[ -f "${dest}/docs/adr/Tech_Radar.md" ]] || return 1
  [[ -d "${dest}/docs/architecture" ]] || return 1
  [[ -d "${dest}/docs/prompts" ]] || return 1

  return 0
}

function test-apply-default-copies-vscode-settings() {

  # Arrange
  local dest="${TEMP_DIR}/default-vscode"

  # Act
  helper-apply "${dest}" || return 1

  # Assert
  [[ -f "${dest}/.vscode/settings.json" ]] || return 1
  grep -q "chat.promptFilesRecommendations" "${dest}/.vscode/settings.json" || return 1
  grep -q "chat.tools.terminal.autoApprove" "${dest}/.vscode/settings.json" || return 1

  return 0
}

function test-apply-default-copies-gitignore() {

  # Arrange
  local dest="${TEMP_DIR}/default-gitignore"

  # Act
  helper-apply "${dest}" || return 1

  # Assert
  [[ -f "${dest}/.gitignore" ]] || return 1
  grep -qF "promptfiles-copilot managed content" "${dest}/.gitignore" || return 1

  return 0
}

function test-apply-default-copies-workspace-file() {

  # Arrange
  local dest="${TEMP_DIR}/default-workspace"

  # Act
  helper-apply "${dest}" || return 1

  # Assert
  [[ -f "${dest}/project.code-workspace" ]] || return 1

  return 0
}

function test-apply-default-copies-pull-request-template() {

  # Arrange
  local dest="${TEMP_DIR}/default-pr-template"

  # Act
  helper-apply "${dest}" || return 1

  # Assert
  [[ -f "${dest}/.github/pull_request_template.md" ]] || return 1

  return 0
}

# --- Technology switch tests ---

function test-apply-python-copies-python-instruction() {

  # Arrange
  local dest="${TEMP_DIR}/python-instruction"

  # Act
  python=true helper-apply "${dest}" || return 1

  # Assert
  [[ -f "${dest}/.github/instructions/python.instructions.md" ]] || return 1

  return 0
}

function test-apply-python-copies-python-prompt() {

  # Arrange
  local dest="${TEMP_DIR}/python-prompt"

  # Act
  python=true helper-apply "${dest}" || return 1

  # Assert
  [[ -f "${dest}/.github/prompts/enforce.python.prompt.md" ]] || return 1

  return 0
}

function test-apply-python-copies-pyproject-template() {

  # Arrange
  local dest="${TEMP_DIR}/python-template"

  # Act
  python=true helper-apply "${dest}" || return 1

  # Assert
  [[ -f "${dest}/.github/instructions/templates/pyproject.toml" ]] || return 1

  return 0
}

function test-apply-typescript-copies-typescript-instruction() {

  # Arrange
  local dest="${TEMP_DIR}/ts-instruction"

  # Act
  typescript=true helper-apply "${dest}" || return 1

  # Assert
  [[ -f "${dest}/.github/instructions/typescript.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/prompts/enforce.typescript.prompt.md" ]] || return 1

  return 0
}

function test-apply-go-copies-go-instruction() {

  # Arrange
  local dest="${TEMP_DIR}/go-instruction"

  # Act
  go=true helper-apply "${dest}" || return 1

  # Assert
  [[ -f "${dest}/.github/instructions/go.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/prompts/enforce.go.prompt.md" ]] || return 1

  return 0
}

function test-apply-rust-copies-rust-instruction() {

  # Arrange
  local dest="${TEMP_DIR}/rust-instruction"

  # Act
  rust=true helper-apply "${dest}" || return 1

  # Assert
  [[ -f "${dest}/.github/instructions/rust.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/prompts/enforce.rust.prompt.md" ]] || return 1

  return 0
}

function test-apply-reactjs-copies-reactjs-instruction() {

  # Arrange
  local dest="${TEMP_DIR}/reactjs-instruction"

  # Act
  reactjs=true helper-apply "${dest}" || return 1

  # Assert
  [[ -f "${dest}/.github/instructions/reactjs.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/prompts/enforce.reactjs.prompt.md" ]] || return 1

  return 0
}

function test-apply-terraform-copies-terraform-instruction() {

  # Arrange
  local dest="${TEMP_DIR}/terraform-instruction"

  # Act
  terraform=true helper-apply "${dest}" || return 1

  # Assert
  [[ -f "${dest}/.github/instructions/terraform.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/prompts/enforce.terraform.prompt.md" ]] || return 1

  return 0
}

function test-apply-tauri-auto-enables-rust-typescript-reactjs() {

  # Arrange
  local dest="${TEMP_DIR}/tauri-auto"

  # Act
  tauri=true helper-apply "${dest}" || return 1

  # Assert — tauri itself
  [[ -f "${dest}/.github/instructions/tauri.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/prompts/enforce.tauri.prompt.md" ]] || return 1
  # Assert — auto-enabled technologies
  [[ -f "${dest}/.github/instructions/rust.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/instructions/typescript.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/instructions/reactjs.instructions.md" ]] || return 1

  return 0
}

function test-apply-django-auto-enables-python() {

  # Arrange
  local dest="${TEMP_DIR}/django-auto"

  # Act
  django=true helper-apply "${dest}" || return 1

  # Assert
  [[ -f "${dest}/.github/instructions/python.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/prompts/enforce.python.prompt.md" ]] || return 1

  return 0
}

function test-apply-django-copies-django-skill() {

  # Arrange
  local dest="${TEMP_DIR}/django-skill"

  # Act
  django=true helper-apply "${dest}" || return 1

  # Assert
  [[ -d "${dest}/.github/skills/django-project" ]] || return 1
  [[ -f "${dest}/.github/skills/django-project/SKILL.md" ]] || return 1

  return 0
}

function test-apply-fastapi-auto-enables-python() {

  # Arrange
  local dest="${TEMP_DIR}/fastapi-auto"

  # Act
  fastapi=true helper-apply "${dest}" || return 1

  # Assert
  [[ -f "${dest}/.github/instructions/python.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/prompts/enforce.python.prompt.md" ]] || return 1

  return 0
}

function test-apply-fastapi-copies-fastapi-skill() {

  # Arrange
  local dest="${TEMP_DIR}/fastapi-skill"

  # Act
  fastapi=true helper-apply "${dest}" || return 1

  # Assert
  [[ -d "${dest}/.github/skills/fastapi-project" ]] || return 1
  [[ -f "${dest}/.github/skills/fastapi-project/SKILL.md" ]] || return 1

  return 0
}

function test-apply-playwright-python-copies-both-instructions() {

  # Arrange
  local dest="${TEMP_DIR}/playwright-py"

  # Act
  python=true playwright=true helper-apply "${dest}" || return 1

  # Assert
  [[ -f "${dest}/.github/instructions/playwright-python.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/prompts/enforce.playwright-python.prompt.md" ]] || return 1

  return 0
}

function test-apply-playwright-without-lang-fails() {

  # Arrange
  local dest="${TEMP_DIR}/playwright-no-lang"

  # Act — should fail because playwright requires python or typescript
  playwright=true helper-apply "${dest}" && return 1

  # Assert — destination should not have been fully created
  [[ ! -f "${dest}/.github/copilot-instructions.md" ]] || return 1

  return 0
}

function test-apply-all-copies-all-tech-instructions() {

  # Arrange
  local dest="${TEMP_DIR}/all-instructions"

  # Act
  all=true helper-apply "${dest}" || return 1

  # Assert
  [[ -f "${dest}/.github/instructions/python.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/instructions/typescript.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/instructions/go.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/instructions/rust.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/instructions/reactjs.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/instructions/terraform.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/instructions/tauri.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/instructions/playwright-python.instructions.md" ]] || return 1
  [[ -f "${dest}/.github/instructions/playwright-typescript.instructions.md" ]] || return 1

  return 0
}

function test-apply-all-copies-all-tech-prompts() {

  # Arrange
  local dest="${TEMP_DIR}/all-prompts"

  # Act
  all=true helper-apply "${dest}" || return 1

  # Assert
  [[ -f "${dest}/.github/prompts/enforce.python.prompt.md" ]] || return 1
  [[ -f "${dest}/.github/prompts/enforce.typescript.prompt.md" ]] || return 1
  [[ -f "${dest}/.github/prompts/enforce.go.prompt.md" ]] || return 1
  [[ -f "${dest}/.github/prompts/enforce.rust.prompt.md" ]] || return 1
  [[ -f "${dest}/.github/prompts/enforce.reactjs.prompt.md" ]] || return 1
  [[ -f "${dest}/.github/prompts/enforce.terraform.prompt.md" ]] || return 1
  [[ -f "${dest}/.github/prompts/enforce.tauri.prompt.md" ]] || return 1
  [[ -f "${dest}/.github/prompts/enforce.playwright-python.prompt.md" ]] || return 1
  [[ -f "${dest}/.github/prompts/enforce.playwright-typescript.prompt.md" ]] || return 1

  return 0
}

function test-apply-all-copies-all-tech-skills() {

  # Arrange
  local dest="${TEMP_DIR}/all-skills"

  # Act
  all=true helper-apply "${dest}" || return 1

  # Assert
  [[ -d "${dest}/.github/skills/django-project" ]] || return 1
  [[ -d "${dest}/.github/skills/fastapi-project" ]] || return 1
  [[ -d "${dest}/.github/skills/repository-template" ]] || return 1

  return 0
}

# --- Clean and revert tests ---

function test-apply-clean-removes-previous-tech-files() {

  # Arrange — first apply with python, then apply with clean but no python
  local dest="${TEMP_DIR}/clean-removes"
  python=true helper-apply "${dest}" || return 1
  [[ -f "${dest}/.github/instructions/python.instructions.md" ]] || return 1

  # Act
  clean=true helper-apply "${dest}" || return 1

  # Assert — python-specific files should be gone
  [[ ! -f "${dest}/.github/instructions/python.instructions.md" ]] || return 1
  # Assert — default files should still be present
  [[ -f "${dest}/.github/instructions/shell.instructions.md" ]] || return 1

  return 0
}

function test-apply-revert-removes-github-dirs() {

  # Arrange
  local dest="${TEMP_DIR}/revert-github"
  helper-apply "${dest}" || return 1
  [[ -d "${dest}/.github/agents" ]] || return 1

  # Act
  revert=true helper-apply "${dest}" || return 1

  # Assert
  [[ ! -d "${dest}/.github/agents" ]] || return 1
  [[ ! -d "${dest}/.github/instructions" ]] || return 1
  [[ ! -d "${dest}/.github/prompts" ]] || return 1
  [[ ! -d "${dest}/.github/skills" ]] || return 1
  [[ ! -d "${dest}/.github/hooks" ]] || return 1
  [[ ! -f "${dest}/.github/copilot-instructions.md" ]] || return 1
  [[ ! -f "${dest}/AGENTS.md" ]] || return 1
  [[ ! -d "${dest}/scripts/hooks" ]] || return 1

  return 0
}

function test-apply-revert-removes-specify-dir() {

  # Arrange
  local dest="${TEMP_DIR}/revert-specify"
  helper-apply "${dest}" || return 1
  [[ -d "${dest}/.specify" ]] || return 1

  # Act
  revert=true helper-apply "${dest}" || return 1

  # Assert
  [[ ! -d "${dest}/.specify" ]] || return 1

  return 0
}

function test-apply-revert-removes-gitignore-managed-section() {

  # Arrange
  local dest="${TEMP_DIR}/revert-gitignore"
  mkdir -p "${dest}"
  printf "# My custom rules\n*.log\n" > "${dest}/.gitignore"
  helper-apply "${dest}" || return 1
  grep -qF "promptfiles-copilot managed content" "${dest}/.gitignore" || return 1

  # Act
  revert=true helper-apply "${dest}" || return 1

  # Assert — managed section removed but custom content preserved
  [[ -f "${dest}/.gitignore" ]] || return 1
  ! grep -qF "promptfiles-copilot managed content" "${dest}/.gitignore" || return 1
  grep -q "My custom rules" "${dest}/.gitignore" || return 1

  return 0
}

function test-apply-revert-removes-vscode-settings-properties() {

  # Arrange
  local dest="${TEMP_DIR}/revert-vscode"
  helper-apply "${dest}" || return 1
  grep -q "chat.promptFilesRecommendations" "${dest}/.vscode/settings.json" || return 1

  # Act
  revert=true helper-apply "${dest}" || return 1

  # Assert
  if [[ -f "${dest}/.vscode/settings.json" ]]; then
    ! grep -q "chat.promptFilesRecommendations" "${dest}/.vscode/settings.json" || return 1
    ! grep -q "chat.tools.terminal.autoApprove" "${dest}/.vscode/settings.json" || return 1
  fi

  return 0
}

# --- Idempotency and skip tests ---

function test-apply-idempotent-same-file-count() {

  # Arrange
  local dest="${TEMP_DIR}/idempotent"
  all=true helper-apply "${dest}" || return 1
  local count1
  count1=$(find "${dest}" -type f | wc -l | tr -d ' ')

  # Act
  all=true helper-apply "${dest}" || return 1
  local count2
  count2=$(find "${dest}" -type f | wc -l | tr -d ' ')

  # Assert
  [[ "${count1}" == "${count2}" ]] || return 1

  return 0
}

function test-apply-skips-existing-workspace-file() {

  # Arrange
  local dest="${TEMP_DIR}/skip-workspace"
  mkdir -p "${dest}"
  echo "custom-workspace-content" > "${dest}/project.code-workspace"

  # Act
  helper-apply "${dest}" || return 1

  # Assert — original content preserved
  grep -q "custom-workspace-content" "${dest}/project.code-workspace" || return 1

  return 0
}

function test-apply-skips-existing-pull-request-template() {

  # Arrange
  local dest="${TEMP_DIR}/skip-pr-template"
  mkdir -p "${dest}/.github"
  echo "custom-pr-template" > "${dest}/.github/pull_request_template.md"

  # Act
  helper-apply "${dest}" || return 1

  # Assert — original content preserved
  grep -q "custom-pr-template" "${dest}/.github/pull_request_template.md" || return 1

  return 0
}

function test-apply-updates-existing-gitignore-managed-section() {

  # Arrange
  local dest="${TEMP_DIR}/update-gitignore"
  mkdir -p "${dest}"
  {
    echo "# Custom rules"
    echo "*.log"
    echo "# >>> promptfiles-copilot managed content - DO NOT EDIT BELOW THIS LINE >>>"
    echo "old-managed-content"
    echo "# <<< promptfiles-copilot managed content - DO NOT EDIT ABOVE THIS LINE <<<"
  } > "${dest}/.gitignore"

  # Act
  helper-apply "${dest}" || return 1

  # Assert — old managed content replaced
  ! grep -q "old-managed-content" "${dest}/.gitignore" || return 1
  # Assert — custom rules preserved
  grep -q "Custom rules" "${dest}/.gitignore" || return 1
  # Assert — managed section still exists
  grep -qF "promptfiles-copilot managed content" "${dest}/.gitignore" || return 1

  return 0
}

function test-apply-default-copies-agents-md() {

  # Arrange
  local dest="${TEMP_DIR}/default-agents-md"

  # Act
  helper-apply "${dest}" || return 1

  # Assert
  [[ -f "${dest}/AGENTS.md" ]] || return 1

  return 0
}

function test-apply-default-copies-hooks() {

  # Arrange
  local dest="${TEMP_DIR}/default-hooks"

  # Act
  helper-apply "${dest}" || return 1

  # Assert
  [[ -f "${dest}/.github/hooks/quality-gates.json" ]] || return 1

  return 0
}

function test-apply-default-copies-hook-scripts() {

  # Arrange
  local dest="${TEMP_DIR}/default-hook-scripts"

  # Act
  helper-apply "${dest}" || return 1

  # Assert
  [[ -x "${dest}/scripts/hooks/post-edit-lint.sh" ]] || return 1
  [[ -x "${dest}/scripts/hooks/stop-gate.sh" ]] || return 1

  return 0
}

function test-apply-revert-removes-agents-md() {

  # Arrange
  local dest="${TEMP_DIR}/revert-agents-md"
  helper-apply "${dest}" || return 1
  [[ -f "${dest}/AGENTS.md" ]] || return 1

  # Act
  revert=true helper-apply "${dest}" || return 1

  # Assert
  [[ ! -f "${dest}/AGENTS.md" ]] || return 1

  return 0
}

function test-apply-revert-removes-hooks() {

  # Arrange
  local dest="${TEMP_DIR}/revert-hooks"
  helper-apply "${dest}" || return 1
  [[ -d "${dest}/.github/hooks" ]] || return 1

  # Act
  revert=true helper-apply "${dest}" || return 1

  # Assert
  [[ ! -d "${dest}/.github/hooks" ]] || return 1
  [[ ! -d "${dest}/scripts/hooks" ]] || return 1

  return 0
}

function test-apply-default-copies-enforcement-audit-skill() {

  # Arrange
  local dest="${TEMP_DIR}/default-enforcement-audit-skill"

  # Act
  helper-apply "${dest}" || return 1

  # Assert
  [[ -f "${dest}/.github/skills/enforcement-audit/SKILL.md" ]] || return 1

  return 0
}

function test-apply-default-copies-architecture-docs-skill() {

  # Arrange
  local dest="${TEMP_DIR}/default-architecture-docs-skill"

  # Act
  helper-apply "${dest}" || return 1

  # Assert
  [[ -f "${dest}/.github/skills/architecture-docs/SKILL.md" ]] || return 1

  return 0
}

function test-apply-default-copies-code-review-skill() {

  # Arrange
  local dest="${TEMP_DIR}/default-code-review-skill"

  # Act
  helper-apply "${dest}" || return 1

  # Assert
  [[ -f "${dest}/.github/skills/code-review/SKILL.md" ]] || return 1

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
