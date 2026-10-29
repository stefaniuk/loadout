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

# Hook files that older loadout versions installed. The Copilot hooks now live in
# repository-template, which owns '.github/hooks/'.
LEGACY_HOOK_FILES=(
  ".github/hooks/quality-gates.json"
  "scripts/hooks/_common.sh"
  "scripts/hooks/session-start-cheatsheet.sh"
  "scripts/hooks/stop-gate.sh"
  "scripts/hooks/subagent-start-context.sh"
  "scripts/hooks/subagent-stop-log.sh"
  "scripts/hooks/user-prompt-record.sh"
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

# Print how far git can tell what a destination tracks: 'repository' inside a
# work tree, 'none' when no repository holds it, or 'unknown' when git does not
# answer, for example for a repository that another user owns.
# Arguments:
#   $1=[destination directory path]
function destination-git-state() {

  local dir

  if [[ "$(git -C "$1" rev-parse --is-inside-work-tree 2> /dev/null)" == "true" ]]; then
    echo "repository"
    return 0
  fi
  if ! dir="$(cd "$1" 2> /dev/null && pwd -P)"; then
    echo "unknown"
    return 0
  fi
  while true; do
    if [[ -e "${dir}/.git" ]]; then
      echo "unknown"
      return 0
    fi
    [[ "${dir}" != "/" ]] || break
    dir="$(dirname "${dir}")"
  done
  echo "none"

  return 0
}

# Remove the hook files that older loadout versions installed in a destination.
# A file the destination tracks in git is its own, so it is kept with a notice,
# as is every file when git cannot tell what is tracked, or a file that a link
# places outside the destination.
# Arguments:
#   $1=[destination directory path]
function remove-legacy-hook-files() {

  local destination="$1"
  local rel_path git_state real_destination parent

  real_destination="$(cd "${destination}" 2> /dev/null && pwd -P)" || return 0
  git_state="$(destination-git-state "${destination}")"
  for rel_path in "${LEGACY_HOOK_FILES[@]}"; do
    [[ -e "${destination}/${rel_path}" || -L "${destination}/${rel_path}" ]] || continue
    parent="$(cd "$(dirname "${destination}/${rel_path}")" && pwd -P)" || continue
    if [[ "${parent}" != "${real_destination}/"* ]]; then
      print-info "Keeping ${destination}/${rel_path}, which a link places outside the destination"
      continue
    fi
    if [[ "${git_state}" == "unknown" ]]; then
      print-info "Keeping ${destination}/${rel_path}, as git cannot tell whether the destination tracks it. Remove it if it is the old loadout hook"
      continue
    fi
    if [[ "${git_state}" == "repository" ]] && is-destination-owned "${destination}" "${rel_path}"; then
      print-info "Keeping ${destination}/${rel_path}, which the destination tracks. Remove it if it is the old loadout hook"
      continue
    fi
    print-info "Removing old loadout hook file ${destination}/${rel_path}"
    rm -f "${destination:?}/${rel_path}"
  done
  rmdir "${destination}/.github/hooks" 2> /dev/null || true

  return 0
}
