#!/bin/bash

set -euo pipefail

# Shared helpers for resolving the active local workflow mode.
#
# Usage:
#   $ source ./workflow-mode.lib.sh
#   $ workflow-mode-read
#
# Arguments (provided as environment variables):
#   LOADOUT_WORKFLOW_MODE_FILE=[path to workflow-mode.json, optional]

# ==============================================================================

# Resolve the workflow mode file path.
# Echoes the absolute path on stdout.
function workflow-mode-file-path() {

  if [[ -n "${LOADOUT_WORKFLOW_MODE_FILE:-}" ]]; then
    echo "${LOADOUT_WORKFLOW_MODE_FILE}"
    return 0
  fi

  local repo_root
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  echo "${repo_root}/.copilot/workflow-mode.json"

  return 0
}

# Normalise a workflow mode string.
# Arguments:
#   $1=[candidate mode]
# Echoes the supported mode value on stdout.
function workflow-mode-normalise() {

  local candidate="${1:-}"

  case "${candidate}" in
    speckit)
      echo "speckit"
      ;;
    superpowers)
      echo "superpowers"
      ;;
    *)
      echo "superpowers"
      ;;
  esac

  return 0
}

# Read the active workflow mode from disk.
# Echoes `speckit` or `superpowers` on stdout.
function workflow-mode-read() {

  local mode_file
  mode_file="$(workflow-mode-file-path)"

  if [[ ! -f "${mode_file}" ]]; then
    echo "superpowers"
    return 0
  fi

  local active=""
  if command -v jq > /dev/null 2>&1; then
    active="$(jq -r '.active // empty' "${mode_file}" 2>/dev/null || echo "")"
  elif grep -Eq '"active"[[:space:]]*:[[:space:]]*"superpowers"' "${mode_file}"; then
    active="superpowers"
  elif grep -Eq '"active"[[:space:]]*:[[:space:]]*"speckit"' "${mode_file}"; then
    active="speckit"
  fi

  workflow-mode-normalise "${active}"

  return 0
}
