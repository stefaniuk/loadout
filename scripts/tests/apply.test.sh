#!/bin/bash
# shellcheck disable=SC2329

set -euo pipefail

# Test suite for the apply command.
#
# Optimised for speed: all apply destinations are pre-built in parallel
# during suite setup and reused as read-only by assertion tests. Only
# fast-failing validation tests run apply sequentially.
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
TAURI_DEST=""
PLAYWRIGHT_PY_DEST=""
CLEAN_DEST=""
SKIP_SINGLETONS_DEST=""
GITIGNORE_DEST=""
OWNED_FILES_DEST=""
OWNED_REVERT_DEST=""
ESCAPED_SPACE_ROOT=""

# Subset shared dests
SUBSET_AGENTS_DEST=""
SUBSET_PROMPTS_AGENTS_DEST=""
SUBSET_INSTR_PY_DEST=""
SUBSET_SPECKIT_DEST=""
SUBSET_DOCS_DEST=""
SUBSET_PROJECT_DEST=""

# Makefile-integration shared dests
MAKE_PATCH_DEST=""
MAKE_REAPPLY_DEST=""
MAKE_REVERT_DEST=""

function main() {

  cd "$(git rev-parse --show-toplevel)"

  test-apply-suite-setup
  local tests=( \
    test-apply-no-args-fails \
    test-apply-empty-dest-fails \
    test-apply-normalises-escaped-space-destination \
    test-apply-default-copies-expected-artefacts \
    test-apply-default-excludes-tech-files \
    test-apply-all-copies-all-tech-files \
    test-apply-tauri-auto-enables-rust-typescript-reactjs \
    test-apply-playwright-python-copies-both-instructions \
    test-apply-playwright-without-lang-fails \
    test-apply-clean-removes-previous-tech-files \
    test-apply-compatible-downstream-makefile-copies-loadout-module-and-patches-root-makefile \
    test-apply-reapply-does-not-duplicate-loadout-make-include \
    test-revert-removes-all-managed-artefacts \
    test-revert-removes-loadout-make-integration \
    test-apply-skips-existing-singletons \
    test-apply-updates-existing-gitignore-managed-section \
    test-apply-respects-git-tracked-destination-owned-files \
    test-revert-respects-destination-owned-adr-template \
    test-apply-subset-agents-only \
    test-apply-subset-prompts-and-agents \
    test-apply-subset-instructions-only-with-python-tech \
    test-apply-subset-invalid-value-fails-with-helpful-message \
    test-apply-subset-speckit-only-narrows-prompts \
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
  TAURI_DEST="${TEMP_DIR}/_shared_tauri"
  PLAYWRIGHT_PY_DEST="${TEMP_DIR}/_shared_playwright_py"
  CLEAN_DEST="${TEMP_DIR}/_shared_clean"
  SKIP_SINGLETONS_DEST="${TEMP_DIR}/_shared_skip_singletons"
  GITIGNORE_DEST="${TEMP_DIR}/_shared_gitignore"
  OWNED_FILES_DEST="${TEMP_DIR}/_shared_owned_files"
  OWNED_REVERT_DEST="${TEMP_DIR}/_shared_owned_revert"
  ESCAPED_SPACE_ROOT="${TEMP_DIR}/_esc_space"
  SUBSET_AGENTS_DEST="${TEMP_DIR}/_subset_agents"
  SUBSET_PROMPTS_AGENTS_DEST="${TEMP_DIR}/_subset_prompts_agents"
  SUBSET_INSTR_PY_DEST="${TEMP_DIR}/_subset_instr_py"
  SUBSET_SPECKIT_DEST="${TEMP_DIR}/_subset_speckit"
  SUBSET_DOCS_DEST="${TEMP_DIR}/_subset_docs"
  SUBSET_PROJECT_DEST="${TEMP_DIR}/_subset_project"
  MAKE_PATCH_DEST="${TEMP_DIR}/_make_patch"
  MAKE_REAPPLY_DEST="${TEMP_DIR}/_make_reapply"
  MAKE_REVERT_DEST="${TEMP_DIR}/_make_revert"

  # Pre-build all destinations in parallel.
  (./scripts/apply.sh "${DEFAULT_DEST}" > /dev/null 2>&1) &
  (all=true ./scripts/apply.sh "${ALL_DEST}" > /dev/null 2>&1) &
  (./scripts/apply.sh "${REVERT_DEST}" > /dev/null 2>&1 && \
    bash ./scripts/revert.sh --dest "${REVERT_DEST}" > /dev/null 2>&1) &
  (tauri=true ./scripts/apply.sh "${TAURI_DEST}" > /dev/null 2>&1) &
  (python=true playwright=true ./scripts/apply.sh "${PLAYWRIGHT_PY_DEST}" > /dev/null 2>&1) &
  (python=true ./scripts/apply.sh "${CLEAN_DEST}" > /dev/null 2>&1 && \
    clean=true ./scripts/apply.sh "${CLEAN_DEST}" > /dev/null 2>&1) &
  ({
    mkdir -p "${SKIP_SINGLETONS_DEST}/.github"
    echo "custom-pr-template" > "${SKIP_SINGLETONS_DEST}/.github/pull_request_template.md"
    ./scripts/apply.sh "${SKIP_SINGLETONS_DEST}" > /dev/null 2>&1
  }) &
  ({
    mkdir -p "${GITIGNORE_DEST}"
    printf '%s\n' "# Custom rules" "*.log" \
      "# >>> loadout managed content - DO NOT EDIT BELOW THIS LINE >>>" \
      "old-managed-content" \
      "# <<< loadout managed content - DO NOT EDIT ABOVE THIS LINE <<<" \
      > "${GITIGNORE_DEST}/.gitignore"
    ./scripts/apply.sh "${GITIGNORE_DEST}" > /dev/null 2>&1
  }) &
  ({
    mkdir -p "${ESCAPED_SPACE_ROOT}"
    ./scripts/apply.sh "${ESCAPED_SPACE_ROOT}/Mobile\\ Documents/iCloud~md~obsidian/Documents" > /dev/null 2>&1
  }) &
  ({
    seed-destination-owned-files "${OWNED_FILES_DEST}"
    ./scripts/apply.sh "${OWNED_FILES_DEST}" > /dev/null 2>&1
  }) &
  ({
    seed-destination-owned-files "${OWNED_REVERT_DEST}"
    ./scripts/apply.sh "${OWNED_REVERT_DEST}" > /dev/null 2>&1
    bash ./scripts/revert.sh --dest "${OWNED_REVERT_DEST}" > /dev/null 2>&1
  }) &
  (subset=agents ./scripts/apply.sh "${SUBSET_AGENTS_DEST}" > /dev/null 2>&1) &
  (subset="prompts,agents" ./scripts/apply.sh "${SUBSET_PROMPTS_AGENTS_DEST}" > /dev/null 2>&1) &
  (subset=instructions python=true ./scripts/apply.sh "${SUBSET_INSTR_PY_DEST}" > /dev/null 2>&1) &
  (subset=speckit ./scripts/apply.sh "${SUBSET_SPECKIT_DEST}" > /dev/null 2>&1) &
  (subset=docs ./scripts/apply.sh "${SUBSET_DOCS_DEST}" > /dev/null 2>&1) &
  (subset=project ./scripts/apply.sh "${SUBSET_PROJECT_DEST}" > /dev/null 2>&1) &
  (create-template-managed-make-destination "${MAKE_PATCH_DEST}" && \
    ./scripts/apply.sh "${MAKE_PATCH_DEST}" > /dev/null 2>&1) &
  (create-template-managed-make-destination "${MAKE_REAPPLY_DEST}" && \
    ./scripts/apply.sh "${MAKE_REAPPLY_DEST}" > /dev/null 2>&1 && \
    ./scripts/apply.sh "${MAKE_REAPPLY_DEST}" > /dev/null 2>&1) &
  (create-template-managed-make-destination "${MAKE_REVERT_DEST}" && \
    ./scripts/apply.sh "${MAKE_REVERT_DEST}" > /dev/null 2>&1 && \
    bash ./scripts/revert.sh --dest "${MAKE_REVERT_DEST}" > /dev/null 2>&1) &
  wait

  return 0
}

function test-apply-suite-teardown() {

  if [[ -n "${TEMP_DIR}" ]] && [[ -d "${TEMP_DIR}" ]]; then
    rm -rf "${TEMP_DIR}"
  fi

  return 0
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

function test-apply-normalises-escaped-space-destination() {

  local expected="${ESCAPED_SPACE_ROOT}/Mobile Documents/iCloud~md~obsidian/Documents"
  [[ -d "${expected}/.github/agents" ]] || return 1
  [[ ! -d "${ESCAPED_SPACE_ROOT}/Mobile\\ Documents" ]] || return 1
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
  # Skills (all skills copied)
  [[ -f "${d}/.github/skills/repository-template/SKILL.md" ]] || return 1
  [[ -f "${d}/.github/skills/enforcement-audit/SKILL.md" ]] || return 1
  [[ -f "${d}/.github/skills/architecture-docs/SKILL.md" ]] || return 1
  [[ -f "${d}/.github/skills/code-review/SKILL.md" ]] || return 1
  [[ -f "${d}/.github/skills/spec-consolidation/SKILL.md" ]] || return 1
  [[ -f "${d}/.github/skills/system-documentation/SKILL.md" ]] || return 1
  [[ -f "${d}/.github/skills/brainstorming/SKILL.md" ]] || return 1
  [[ -f "${d}/.github/skills/find-bugs/SKILL.md" ]] || return 1
  [[ -f "${d}/.github/skills/systematic-debugging/SKILL.md" ]] || return 1
  [[ -f "${d}/.github/skills/test-driven-development/SKILL.md" ]] || return 1
  [[ -f "${d}/.github/skills/virtual-think-tank/SKILL.md" ]] || return 1
  [[ -f "${d}/.github/skills/verification-before-completion/SKILL.md" ]] || return 1
  # Singleton files
  [[ -f "${d}/.github/copilot-instructions.md" ]] || return 1
  [[ -f "${d}/.github/pull_request_template.md" ]] || return 1
  # Shared resources
  [[ -d "${d}/.specify/memory" ]] || return 1
  [[ -d "${d}/.specify/scripts/python" ]] || return 1
  [[ -d "${d}/.specify/templates" ]] || return 1
  [[ -f "${d}/docs/adr/ADR-nnn_Any_Decision_Record_Template.md" ]] || return 1
  [[ -f "${d}/docs/adr/Tech_Radar.md" ]] || return 1
  [[ -f "${d}/.copilot/analysis/.gitignore" ]] || return 1
  [[ "$(find "${d}/docs" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')" -eq 1 ]] || return 1
  # .gitignore
  [[ -f "${d}/.gitignore" ]] || return 1
  grep -qF "loadout managed content" "${d}/.gitignore" || return 1
  # Hooks
  [[ -f "${d}/.github/hooks/quality-gates.json" ]] || return 1
  [[ ! -f "${d}/hooks.json" ]] || return 1
  [[ -x "${d}/scripts/hooks/session-start-cheatsheet.sh" ]] || return 1
  [[ -x "${d}/scripts/hooks/stop-gate.sh" ]] || return 1
  return 0
}

function test-apply-default-excludes-tech-files() {

  local d="${DEFAULT_DEST}"
  [[ ! -f "${d}/.github/instructions/python.instructions.md" ]] || return 1
  [[ ! -f "${d}/.github/instructions/typescript.instructions.md" ]] || return 1
  [[ ! -f "${d}/.github/instructions/go.instructions.md" ]] || return 1
  [[ ! -f "${d}/.github/instructions/rust.instructions.md" ]] || return 1
  [[ ! -f "${d}/.github/prompts/enforce.python.prompt.md" ]] || return 1
  [[ ! -f "${d}/.github/prompts/enforce.typescript.prompt.md" ]] || return 1
  [[ ! -f "${d}/.github/prompts/enforce.go.prompt.md" ]] || return 1
  return 0
}

# ==============================================================================
# all=true (read-only checks against shared ALL_DEST)

function test-apply-all-copies-all-tech-files() {

  local d="${ALL_DEST}"
  [[ -f "${d}/.github/instructions/python.instructions.md" ]] || return 1
  [[ -f "${d}/.github/instructions/typescript.instructions.md" ]] || return 1
  [[ -f "${d}/.github/instructions/go.instructions.md" ]] || return 1
  [[ -f "${d}/.github/instructions/rust.instructions.md" ]] || return 1
  [[ -f "${d}/.github/instructions/reactjs.instructions.md" ]] || return 1
  [[ -f "${d}/.github/instructions/terraform.instructions.md" ]] || return 1
  [[ -f "${d}/.github/instructions/tauri.instructions.md" ]] || return 1
  [[ -f "${d}/.github/instructions/playwright-python.instructions.md" ]] || return 1
  [[ -f "${d}/.github/instructions/playwright-typescript.instructions.md" ]] || return 1
  [[ -f "${d}/.github/prompts/enforce.python.prompt.md" ]] || return 1
  [[ -f "${d}/.github/prompts/enforce.typescript.prompt.md" ]] || return 1
  [[ -f "${d}/.github/prompts/enforce.go.prompt.md" ]] || return 1
  [[ -f "${d}/.github/prompts/enforce.rust.prompt.md" ]] || return 1
  [[ -f "${d}/.github/prompts/enforce.reactjs.prompt.md" ]] || return 1
  [[ -f "${d}/.github/prompts/enforce.terraform.prompt.md" ]] || return 1
  [[ -f "${d}/.github/prompts/enforce.tauri.prompt.md" ]] || return 1
  [[ -f "${d}/.github/prompts/enforce.playwright-python.prompt.md" ]] || return 1
  [[ -f "${d}/.github/prompts/enforce.playwright-typescript.prompt.md" ]] || return 1
  [[ -f "${d}/.github/instructions/templates/pyproject.toml" ]] || return 1
  [[ -d "${d}/.github/skills/repository-template" ]] || return 1
  return 0
}

# ==============================================================================
# Technology auto-enable and validation

function test-apply-tauri-auto-enables-rust-typescript-reactjs() {

  local d="${TAURI_DEST}"
  [[ -f "${d}/.github/instructions/tauri.instructions.md" ]] || return 1
  [[ -f "${d}/.github/prompts/enforce.tauri.prompt.md" ]] || return 1
  [[ -f "${d}/.github/instructions/rust.instructions.md" ]] || return 1
  [[ -f "${d}/.github/instructions/typescript.instructions.md" ]] || return 1
  [[ -f "${d}/.github/instructions/reactjs.instructions.md" ]] || return 1
  return 0
}

function test-apply-playwright-python-copies-both-instructions() {

  local d="${PLAYWRIGHT_PY_DEST}"
  [[ -f "${d}/.github/instructions/playwright-python.instructions.md" ]] || return 1
  [[ -f "${d}/.github/prompts/enforce.playwright-python.prompt.md" ]] || return 1
  return 0
}

function test-apply-playwright-without-lang-fails() {

  local dest="${TEMP_DIR}/playwright-no-lang"
  playwright=true ./scripts/apply.sh "${dest}" > /dev/null 2>&1 && return 1
  [[ ! -f "${dest}/.github/copilot-instructions.md" ]] || return 1
  return 0
}

# ==============================================================================
# Clean / revert / skip behaviour

function test-apply-clean-removes-previous-tech-files() {

  local d="${CLEAN_DEST}"
  [[ ! -f "${d}/.github/instructions/python.instructions.md" ]] || return 1
  [[ -f "${d}/.github/instructions/shell.instructions.md" ]] || return 1
  return 0
}

function test-apply-compatible-downstream-makefile-copies-loadout-module-and-patches-root-makefile() {

  local d="${MAKE_PATCH_DEST}"
  [[ -f "${d}/scripts/loadout.mk" ]] || return 1
  [[ -f "${d}/Makefile" ]] || return 1
  grep -qF "# >>> loadout managed makefile include - DO NOT EDIT BELOW THIS LINE >>>" "${d}/Makefile" || return 1
  grep -qF "include scripts/loadout.mk" "${d}/Makefile" || return 1
  [[ "$(grep -cF "include scripts/loadout.mk" "${d}/Makefile")" -eq 1 ]] || return 1
  return 0
}

function test-apply-reapply-does-not-duplicate-loadout-make-include() {

  local d="${MAKE_REAPPLY_DEST}"
  [[ "$(grep -cF "# >>> loadout managed makefile include - DO NOT EDIT BELOW THIS LINE >>>" "${d}/Makefile")" -eq 1 ]] || return 1
  [[ "$(grep -cF "include scripts/loadout.mk" "${d}/Makefile")" -eq 1 ]] || return 1
  [[ "$(grep -cF "# <<< loadout managed makefile include - DO NOT EDIT ABOVE THIS LINE <<<" "${d}/Makefile")" -eq 1 ]] || return 1
  return 0
}

function test-revert-removes-all-managed-artefacts() {

  local d="${REVERT_DEST}"
  [[ ! -d "${d}/.github/agents" ]] || return 1
  [[ ! -d "${d}/.github/hooks" ]] || return 1
  [[ ! -d "${d}/.github/instructions" ]] || return 1
  [[ ! -d "${d}/.github/prompts" ]] || return 1
  [[ ! -d "${d}/.github/skills" ]] || return 1
  [[ ! -d "${d}/.specify" ]] || return 1
  [[ ! -d "${d}/.copilot" ]] || return 1
  [[ ! -d "${d}/scripts/hooks" ]] || return 1
  [[ ! -f "${d}/.github/copilot-instructions.md" ]] || return 1
  [[ ! -f "${d}/hooks.json" ]] || return 1
  if [[ -f "${d}/.gitignore" ]]; then
    ! grep -qF "loadout managed content" "${d}/.gitignore" || return 1
  fi
  return 0
}

function test-revert-removes-loadout-make-integration() {

  local d="${MAKE_REVERT_DEST}"
  [[ ! -f "${d}/scripts/loadout.mk" ]] || return 1
  [[ -f "${d}/Makefile" ]] || return 1
  ! grep -qF "loadout managed makefile include" "${d}/Makefile" || return 1
  ! grep -qF "include scripts/loadout.mk" "${d}/Makefile" || return 1
  return 0
}

function test-apply-skips-existing-singletons() {

  local d="${SKIP_SINGLETONS_DEST}"
  grep -q "custom-pr-template" "${d}/.github/pull_request_template.md" || return 1
  return 0
}

function test-apply-updates-existing-gitignore-managed-section() {

  local d="${GITIGNORE_DEST}"
  ! grep -q "old-managed-content" "${d}/.gitignore" || return 1
  grep -q "Custom rules" "${d}/.gitignore" || return 1
  grep -qF "loadout managed content" "${d}/.gitignore" || return 1
  return 0
}

function test-apply-respects-git-tracked-destination-owned-files() {

  local d="${OWNED_FILES_DEST}"
  # Pre-existing, git-tracked files are left untouched, not overwritten.
  grep -q "custom-owned-pr-template" "${d}/.github/pull_request_template.md" || return 1
  grep -q "custom-owned-adr-template" "${d}/docs/adr/ADR-nnn_Any_Decision_Record_Template.md" || return 1
  # Their .gitignore entries are commented out for this destination only.
  grep -qF "# .github/pull_request_template.md" "${d}/.gitignore" || return 1
  grep -qF "# docs/adr/ADR-nnn_Any_Decision_Record_Template.md" "${d}/.gitignore" || return 1
  # Tech_Radar.md is not in the conditionally-owned set, so it stays managed.
  [[ -f "${d}/docs/adr/Tech_Radar.md" ]] || return 1
  grep -qF "docs/adr/Tech_Radar.md" "${d}/.gitignore" || return 1
  ! grep -qF "# docs/adr/Tech_Radar.md" "${d}/.gitignore" || return 1
  return 0
}

function test-revert-respects-destination-owned-adr-template() {

  local d="${OWNED_REVERT_DEST}"
  # Owned files survive revert; Tech_Radar.md (unowned) is removed as usual.
  grep -q "custom-owned-pr-template" "${d}/.github/pull_request_template.md" || return 1
  grep -q "custom-owned-adr-template" "${d}/docs/adr/ADR-nnn_Any_Decision_Record_Template.md" || return 1
  [[ ! -f "${d}/docs/adr/Tech_Radar.md" ]] || return 1
  return 0
}

# ==============================================================================
# Subset selector

function test-apply-subset-agents-only() {

  local d="${SUBSET_AGENTS_DEST}"
  [[ -d "${d}/.github/agents" ]] || return 1
  [[ -f "${d}/.github/agents/README.md" ]] || return 1
  [[ ! -d "${d}/.github/prompts" ]] || return 1
  [[ ! -d "${d}/.github/skills" ]] || return 1
  [[ ! -f "${d}/.github/copilot-instructions.md" ]] || return 1
  return 0
}

function test-apply-subset-prompts-and-agents() {

  local d="${SUBSET_PROMPTS_AGENTS_DEST}"
  [[ -d "${d}/.github/agents" ]] || return 1
  [[ -f "${d}/.github/agents/README.md" ]] || return 1
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

function test-apply-subset-speckit-only-narrows-prompts() {

  local d="${SUBSET_SPECKIT_DEST}"
  [[ ! -d "${d}/.github/skills" ]] || return 1
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
  [[ "$(find "${d}/docs" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')" -eq 1 ]] || return 1
  [[ ! -d "${d}/.copilot" ]] || return 1
  [[ ! -d "${d}/.github/agents" ]] || return 1
  [[ ! -d "${d}/.github/prompts" ]] || return 1
  return 0
}

function test-apply-subset-project-only() {

  local d="${SUBSET_PROJECT_DEST}"
  [[ -f "${d}/.gitignore" ]] || return 1
  [[ -f "${d}/.copilot/analysis/.gitignore" ]] || return 1
  [[ -f "${d}/.github/copilot-instructions.md" ]] || return 1
  [[ -f "${d}/.github/pull_request_template.md" ]] || return 1
  [[ ! -d "${d}/.github/agents" ]] || return 1
  [[ ! -d "${d}/.github/prompts" ]] || return 1
  [[ ! -d "${d}/.github/instructions" ]] || return 1
  [[ ! -d "${d}/.github/skills" ]] || return 1
  return 0
}

function seed-destination-owned-files() {

  local dest="$1"

  mkdir -p "${dest}/.github" "${dest}/docs/adr"
  echo "custom-owned-pr-template" > "${dest}/.github/pull_request_template.md"
  echo "custom-owned-adr-template" > "${dest}/docs/adr/ADR-nnn_Any_Decision_Record_Template.md"

  git -C "${dest}" init -q
  git -C "${dest}" add -A
  git -C "${dest}" -c user.email="test@example.com" -c user.name="Loadout Test" commit -q -m "seed destination-owned files"

  return 0
}

function create-template-managed-make-destination() {

  local dest="$1"

  mkdir -p "${dest}/scripts"

  {
    printf '%s\n' 'include scripts/init.mk'
    printf '\n'
    printf '%s\n' 'project-help: # Example project target @Others'
    printf '\t%s\n' "printf 'project help\\n'"
  } > "${dest}/Makefile"

  {
    printf '%s\n' 'help: # Print help @Others'
    printf '\t%s\n' "printf 'shared help\\n'"
  } > "${dest}/scripts/init.mk"

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
