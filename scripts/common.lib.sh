#!/bin/bash
# shellcheck disable=SC2034

set -euo pipefail

# Shared constants and helpers used by scripts/apply.sh, scripts/import.sh,
# and scripts/revert.sh. Keeping these in one place ensures the markers
# apply.sh writes are the exact markers revert.sh looks for when reverting.
#
# Usage:
#   $ source ./common.lib.sh

# Begin/end markers for managed .gitignore content
GITIGNORE_BEGIN_MARKER="# >>> loadout managed content - DO NOT EDIT BELOW THIS LINE >>>"
GITIGNORE_END_MARKER="# <<< loadout managed content - DO NOT EDIT ABOVE THIS LINE <<<"
LOADOUT_MAKEFILE_BEGIN_MARKER="# >>> loadout managed makefile include - DO NOT EDIT BELOW THIS LINE >>>"
LOADOUT_MAKEFILE_END_MARKER="# <<< loadout managed makefile include - DO NOT EDIT ABOVE THIS LINE <<<"
LOADOUT_MAKEFILE_FILE_MARKER="# loadout-managed: scripts/loadout.mk"

# Paths that, once tracked in a destination repo's own git history, are
# considered destination-owned: apply/import/revert will not manage them.
CONDITIONALLY_OWNED_PATHS=(
  ".github/pull_request_template.md"
  "docs/adr/ADR-nnn_Any_Decision_Record_Template.md"
)

# ==============================================================================

# Print an informational message.
# Arguments:
#   $1=[message to display]
function print-info() {

  echo "→ $1"
}

# Normalise a destination path passed via make or the shell.
# Converts common escaped spaces to literal spaces, expands a leading home
# directory marker, and resolves relative paths against the current directory.
# Arguments:
#   $1=[destination directory path]
function normalise-destination-path() {

  local destination="$1"

  destination="${destination//\\ / }"

  if [[ "${destination}" == \~ ]]; then
    destination="${HOME}"
  elif [[ "${destination:0:2}" == \~/* ]]; then
    destination="${HOME}/${destination:2}"
  fi

  if [[ "${destination}" != /* ]]; then
    local destination_dir
    local destination_dir_abs
    destination_dir="$(dirname "${destination}")"
    if destination_dir_abs=$(cd "$(pwd)" && cd "${destination_dir}" 2>/dev/null && pwd); then
      destination="${destination_dir_abs}/$(basename "${destination}")"
    else
      destination="$(pwd)/${destination}"
    fi
  fi

  printf '%s\n' "${destination}"

  return 0
}

# Check whether a relative path is already tracked by git in a destination
# repo, meaning that repo - not loadout - owns the file going forward.
# Arguments:
#   $1=[destination directory path]
#   $2=[relative file path]
function is-destination-owned() {

  local destination="$1"
  local rel_path="$2"

  git -C "${destination}" ls-files --error-unmatch "${rel_path}" > /dev/null 2>&1
}
