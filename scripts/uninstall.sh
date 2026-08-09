#!/bin/bash

set -euo pipefail
umask 077

# Uninstaller for loadout.
#
# Thin wrapper around `revert=true scripts/apply.sh <dest>` that removes
# all loadout-managed artifacts from a previously-installed destination.
# Local mode only in v1: requires a sibling apply.sh (cloned repository).
#
# Usage:
#   $ ./scripts/uninstall.sh --dest <path> [--dry-run]
#
# Options:
#   --dest <path>  Destination directory to clean (required).
#   --dry-run      Print the resolved command without running it.
#   --help         Show this help message.
#
# Exit codes:
#   0 - Success.
#   1 - Runtime failure (missing sibling apply.sh, apply.sh failure).
#   2 - Invalid arguments.
#
# Examples:
#   $ ./scripts/uninstall.sh --dest ~/projects/my-app
#   $ ./scripts/uninstall.sh --dest ~/projects/my-app --dry-run

# ==============================================================================

SCRIPT_NAME="uninstall.sh"

function usage() {
  sed -n '4,28p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
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

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local apply_path="${script_dir}/apply.sh"

  if [[ ! -x "${apply_path}" ]]; then
    die 1 "sibling apply.sh not found; clone the repository first or run: scripts/install.sh --dest ${dest} --dry-run"
  fi

  if [[ "${dry_run}" == "true" ]]; then
    printf '%s: dry-run (dest=%s)\n' "${SCRIPT_NAME}" "${dest}"
    printf '%s: would run: revert=true %s %s\n' "${SCRIPT_NAME}" "${apply_path}" "${dest}"
    exit 0
  fi

  revert=true "${apply_path}" "${dest}"

  printf '%s: ok (dest=%s)\n' "${SCRIPT_NAME}" "${dest}"
}

main "$@"
