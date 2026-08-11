#!/bin/bash

set -euo pipefail

# Manage the active local workflow mode for this repository.
#
# Usage:
#   $ ./scripts/hooks/workflow-mode.sh status
#   $ ./scripts/hooks/workflow-mode.sh switch
#   $ ./scripts/hooks/workflow-mode.sh use speckit
#   $ ./scripts/hooks/workflow-mode.sh use superpowers
#
# Arguments (provided as environment variables):
#   LOADOUT_WORKFLOW_MODE_FILE=[path to workflow-mode.json, optional]
#   VERBOSE=true                        # Show all the executed commands, default is 'false'

# ==============================================================================

# shellcheck disable=SC1091
source "$(dirname "$0")/workflow-mode.lib.sh"

# ==============================================================================

# Main entry point.
function main() {

  local command="${1:-status}"

  case "${command}" in
    status)
      workflow-status
      ;;
    switch)
      workflow-switch
      ;;
    use)
      workflow-use "${2:-}"
      ;;
    *)
      echo "error: unknown command '${command}'" >&2
      print-usage >&2
      return 1
      ;;
  esac

  return 0
}

# Print command usage.
function print-usage() {

  cat <<'EOF'
Usage:
  ./scripts/hooks/workflow-mode.sh status
  ./scripts/hooks/workflow-mode.sh switch
  ./scripts/hooks/workflow-mode.sh use speckit
  ./scripts/hooks/workflow-mode.sh use superpowers
EOF

  return 0
}

# Print the current active workflow mode.
function workflow-status() {

  workflow-mode-read

  return 0
}

# Resolve the next workflow mode when toggling the active lane.
# Echoes `speckit` or `superpowers` on stdout.
function workflow-switch-next-mode() {

  local current_mode
  current_mode="$(workflow-mode-read)"

  case "${current_mode}" in
    superpowers)
      echo "speckit"
      ;;
    speckit|*)
      echo "superpowers"
      ;;
  esac

  return 0
}

# Validate the requested workflow mode.
# Arguments:
#   $1=[requested mode]
# Echoes the valid mode on stdout.
function workflow-use-validate() {

  local requested_mode="${1:-}"

  case "${requested_mode}" in
    speckit|superpowers)
      echo "${requested_mode}"
      return 0
      ;;
    *)
      echo "error: mode must be speckit or superpowers" >&2
      return 1
      ;;
  esac
}

# Persist the requested active workflow mode.
# Arguments:
#   $1=[requested mode]
function workflow-use() {

  local requested_mode
  requested_mode="$(workflow-use-validate "${1:-}")" || return 1

  local mode_file
  mode_file="$(workflow-mode-file-path)"
  mkdir -p "$(dirname "${mode_file}")"

  cat <<EOF > "${mode_file}"
{"active":"${requested_mode}"}
EOF

  printf '%s\n' "${requested_mode}"

  return 0
}

# Switch the active workflow mode to the opposite lane.
function workflow-switch() {

  local next_mode
  next_mode="$(workflow-switch-next-mode)"

  workflow-use "${next_mode}"

  return 0
}

# ==============================================================================

main "$@"
exit 0
