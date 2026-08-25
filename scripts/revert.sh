#!/bin/bash

set -euo pipefail
umask 077

# Reverter for loadout.
#
# Removes all loadout-managed artifacts from a previously-applied destination
# repository. This is the sole supported way to revert a `make apply` /
# scripts/apply.sh installation - scripts/apply.sh has no revert capability.
# Local mode only in v1: requires a sibling common.lib.sh (cloned repository).
#
# Usage:
#   $ ./scripts/revert.sh --dest <path> [--dry-run]
#
# Options:
#   --dest <path>  Destination directory to clean (required).
#   --dry-run      Print what would be removed without changing anything.
#   --help         Show this help message.
#
# Exit codes:
#   0 - Success.
#   1 - Runtime failure (missing sibling library).
#   2 - Invalid arguments.
#
# Examples:
#   $ ./scripts/revert.sh --dest ~/projects/my-app
#   $ ./scripts/revert.sh --dest ~/projects/my-app --dry-run

# ==============================================================================

SCRIPT_NAME="revert.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function usage() {
  sed -n '6,28p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

function die() {
  local code="$1"; shift
  printf '%s: error: %s\n' "${SCRIPT_NAME}" "$*" >&2
  exit "${code}"
}

function main() {

  local dest=""
  local dry_run="false"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dest)
        [[ $# -ge 2 ]] || die 2 "--dest requires a value"
        dest="$2"
        shift 2
        ;;
      --dest=*)
        dest="${1#--dest=}"
        shift
        ;;
      --dry-run)
        dry_run="true"
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        printf 'Usage: %s --dest <path> [--dry-run]\n' "${SCRIPT_NAME}" >&2
        die 2 "unknown argument: $1"
        ;;
    esac
  done

  [[ -n "${dest}" ]] || { \
    printf 'Usage: %s --dest <path> [--dry-run]\n' "${SCRIPT_NAME}" >&2; \
    die 2 "--dest is required"; \
  }

  if [[ ! -f "${SCRIPT_DIR}/common.lib.sh" ]]; then
    die 1 "sibling common.lib.sh not found; clone the repository first"
  fi

  # shellcheck source=./common.lib.sh
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/common.lib.sh"

  local destination
  destination=$(normalise-destination-path "${dest}")

  if [[ "${dry_run}" == "true" ]]; then
    printf '%s: dry-run (dest=%s)\n' "${SCRIPT_NAME}" "${destination}"
    printf '%s: would remove all loadout-managed artifacts from %s\n' "${SCRIPT_NAME}" "${destination}"
    exit 0
  fi

  echo "Reverting loadout-managed files from: ${destination}"
  echo
  revert-loadout "${destination}"
  echo
  echo "Done. Loadout artifacts reverted from ${destination}"

  printf '%s: ok (dest=%s)\n' "${SCRIPT_NAME}" "${destination}"
}

# ==============================================================================

# Remove all loadout-managed artifacts from the destination.
# This undoes what a previous apply has done.
# Arguments:
#   $1=[destination directory path]
function revert-loadout() {

  local dest="$1"

  revert-copilot "${dest}"
  revert-shared-resources "${dest}"

  return 0
}

# Remove copilot-specific loadout-managed artifacts from the destination.
# Arguments:
#   $1=[destination directory path]
function revert-copilot() {

  local dest="$1"

  # Remove .github directories
  local github_dirs=("agents" "hooks" "instructions" "prompts" "skills")
  for dir in "${github_dirs[@]}"; do
    if [[ -d "${dest}/.github/${dir}" ]]; then
      print-info "Removing ${dest}/.github/${dir}"
      rm -rf "${dest:?}/.github/${dir}"
    fi
  done

  # Remove copilot-instructions.md
  if [[ -f "${dest}/.github/copilot-instructions.md" ]]; then
    print-info "Removing ${dest}/.github/copilot-instructions.md"
    rm -f "${dest}/.github/copilot-instructions.md"
  fi

  # Remove hook scripts (scripts/hooks/ is fully managed by loadout;
  # any user-authored files placed there will be removed on revert)
  if [[ -d "${dest}/scripts/hooks" ]]; then
    print-info "Removing ${dest}/scripts/hooks"
    rm -rf "${dest:?}/scripts/hooks"
  fi

  return 0
}

# Remove shared loadout-managed artifacts from the destination.
# Arguments:
#   $1=[destination directory path]
function revert-shared-resources() {

  local dest="$1"

  revert-loadout-make-integration "${dest}"

  # Remove .specify directory
  if [[ -d "${dest}/.specify" ]]; then
    print-info "Removing ${dest}/.specify"
    rm -rf "${dest:?}/.specify"
  fi

  # Remove ADR template files
  local adr_files=("ADR-nnn_Any_Decision_Record_Template.md" "Tech_Radar.md")
  for file in "${adr_files[@]}"; do
    if [[ -f "${dest}/docs/adr/${file}" ]]; then
      print-info "Removing ${dest}/docs/adr/${file}"
      rm -f "${dest}/docs/adr/${file}"
    fi
  done

  # Remove .copilot/analysis directory if empty or only contains .gitignore.
  if [[ -d "${dest}/.copilot/analysis" ]]; then
    local analysis_contents
    analysis_contents=$(ls -A "${dest}/.copilot/analysis" 2>/dev/null)
    if [[ -z "${analysis_contents}" ]] || [[ "${analysis_contents}" == ".gitignore" ]]; then
      print-info "Removing ${dest}/.copilot/analysis"
      rm -rf "${dest:?}/.copilot/analysis"
    fi
  fi

  # Remove managed .gitignore section
  if [[ -f "${dest}/.gitignore" ]] && grep -qF "${GITIGNORE_BEGIN_MARKER}" "${dest}/.gitignore"; then
    print-info "Removing loadout managed content from .gitignore"
    local temp_file
    temp_file=$(mktemp)
    awk -v begin="${GITIGNORE_BEGIN_MARKER}" -v end="${GITIGNORE_END_MARKER}" '
      $0 == begin { skip = 1; next }
      $0 == end { skip = 0; next }
      !skip { print }
    ' "${dest}/.gitignore" > "${temp_file}"
    # Remove trailing blank lines
    sed -i '' -e :a -e '/^\n*$/{$d;N;ba' -e '}' "${temp_file}" 2>/dev/null || sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "${temp_file}"
    if [[ -s "${temp_file}" ]]; then
      mv "${temp_file}" "${dest}/.gitignore"
    else
      rm -f "${temp_file}" "${dest}/.gitignore"
      print-info "Removed empty .gitignore"
    fi
  fi

  # Clean up empty parent directories
  for dir in "${dest}/.github" "${dest}/docs/adr" "${dest}/docs" "${dest}/.vscode" "${dest}/scripts" "${dest}/.copilot"; do
    if [[ -d "${dir}" ]] && [[ -z "$(ls -A "${dir}" 2>/dev/null)" ]]; then
      print-info "Removing empty directory ${dir}"
      rmdir "${dir}"
    fi
  done

  return 0
}

# Remove the managed loadout Makefile integration from a downstream repository.
# Arguments:
#   $1=[destination directory path]
function revert-loadout-make-integration() {

  local dest="$1"
  local dest_makefile="${dest}/Makefile"
  local dest_loadout_module="${dest}/scripts/loadout.mk"
  local stripped_makefile

  if [[ -f "${dest_makefile}" ]] && grep -qF "${LOADOUT_MAKEFILE_BEGIN_MARKER}" "${dest_makefile}"; then
    print-info "Removing loadout managed Makefile include from ${dest_makefile}"
    stripped_makefile=$(mktemp)
    awk -v begin="${LOADOUT_MAKEFILE_BEGIN_MARKER}" -v end="${LOADOUT_MAKEFILE_END_MARKER}" '
      $0 == begin { skip = 1; next }
      $0 == end { skip = 0; next }
      !skip { print }
    ' "${dest_makefile}" > "${stripped_makefile}"
    mv "${stripped_makefile}" "${dest_makefile}"
  fi

  if [[ -f "${dest_loadout_module}" ]] && grep -qF "${LOADOUT_MAKEFILE_FILE_MARKER}" "${dest_loadout_module}"; then
    print-info "Removing ${dest_loadout_module}"
    rm -f "${dest_loadout_module}"
  fi

  return 0
}

# ==============================================================================

main "$@"
