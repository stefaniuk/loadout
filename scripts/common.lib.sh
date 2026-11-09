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
LOADOUT_MAKEFILE_MODULE_PATH="scripts/loadout.ext.mk"
LOADOUT_MAKEFILE_FILE_MARKER="# loadout-managed: scripts/loadout.ext.mk"

# Makefile integration that older loadout versions installed, before
# repository-template's scripts/init.mk loaded every 'scripts/**/*.ext.mk' file.
LEGACY_LOADOUT_MAKEFILE_MODULE_PATH="scripts/loadout.mk"
LEGACY_LOADOUT_MAKEFILE_FILE_MARKER="# loadout-managed: scripts/loadout.mk"
LEGACY_LOADOUT_MAKEFILE_BEGIN_MARKER="# >>> loadout managed makefile include - DO NOT EDIT BELOW THIS LINE >>>"
LEGACY_LOADOUT_MAKEFILE_END_MARKER="# <<< loadout managed makefile include - DO NOT EDIT ABOVE THIS LINE <<<"

# The only Copilot hook file loadout installs. repository-template owns the
# other files in '.github/hooks/'.
WORKFLOW_MODE_HOOK_PATH=".github/hooks/workflow-mode.json"
# Where older loadout versions kept the chosen workflow mode
LEGACY_WORKFLOW_MODE_STATE_PATH=".copilot/workflow-mode.json"

# Paths that, once tracked in a destination repo's own git history, are
# considered destination-owned: apply/import/revert will not manage them. The
# lower-case pull request template is the name older loadout versions used.
CONDITIONALLY_OWNED_PATHS=(
  ".github/PULL_REQUEST_TEMPLATE.md"
  ".github/pull_request_template.md"
  "docs/adr/ADR-nnn_Any_Decision_Record_Template.md"
  "docs/adr/Technology_Recommendations.md"
  ".github/hooks/workflow-mode.json"
)

# Paths that apply overwrites even when the destination tracks them, as
# repository-template does. Their .gitignore entry is commented out for such a
# destination and revert restores the tracked version from git.
TRACKED_OVERWRITTEN_PATHS=(
  ".github/copilot-instructions.md"
)

# Hook files that older loadout versions installed. repository-template now
# owns the quality gate hooks.
LEGACY_HOOK_FILES=(
  ".github/hooks/quality-gates.json"
  "scripts/hooks/_common.sh"
  "scripts/hooks/workflow-mode.lib.sh"
  "scripts/hooks/session-start-cheatsheet.sh"
  "scripts/hooks/stop-gate.sh"
  "scripts/hooks/subagent-start-context.sh"
  "scripts/hooks/subagent-stop-log.sh"
  "scripts/hooks/user-prompt-record.sh"
)

# Skill directories that older loadout versions installed and loadout no longer
# ships.
LEGACY_SKILL_DIRS=(
  ".github/skills/repository-template"
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
# repo, meaning that repo - not loadout - owns the file going forward. The match
# ignores case, so '.github/PULL_REQUEST_TEMPLATE.md' and
# '.github/pull_request_template.md' count as the same file.
# Arguments:
#   $1=[destination directory path]
#   $2=[relative file path]
function is-destination-owned() {

  local destination="$1"
  local rel_path="$2"

  git -C "${destination}" ls-files --error-unmatch ":(icase)${rel_path}" > /dev/null 2>&1
}

# Print the repository-relative path of a destination's pull request template
# in '.github/', in the letter case it has on disk, or nothing if it has none.
# Arguments:
#   $1=[destination directory path]
function find-pull-request-template() {

  local -a found=()

  shopt -s nocaseglob nullglob
  found=("$1"/.github/pull_request_template.m[d])
  shopt -u nocaseglob nullglob
  if [[ ${#found[@]} -gt 0 ]]; then
    printf '.github/%s\n' "${found[0]##*/}"
  fi

  return 0
}

# Check whether a Makefile includes a path outside a loadout-managed block.
# Arguments:
#   $1=[Makefile path]
#   $2=[included path]
function makefile-includes-unmanaged() {

  local makefile="$1"
  local included="$2"

  [[ -f "${makefile}" ]] || return 1
  awk -v begin="${LEGACY_LOADOUT_MAKEFILE_BEGIN_MARKER}" -v end="${LEGACY_LOADOUT_MAKEFILE_END_MARKER}" -v included="${included}" '
    $0 == begin { skip = 1; next }
    $0 == end { skip = 0; next }
    !skip && $1 == "include" && $2 == included { found = 1 }
    END { exit found ? 0 : 1 }
  ' "${makefile}"
}

# Remove the Makefile integration that older loadout versions installed: the
# managed include block in the root Makefile and the loadout-managed
# scripts/loadout.mk. A module the Makefile still includes by hand is kept.
# Arguments:
#   $1=[destination directory path]
function remove-legacy-loadout-make-integration() {

  local dest="$1"
  local dest_makefile="${dest}/Makefile"
  local dest_legacy_module="${dest}/${LEGACY_LOADOUT_MAKEFILE_MODULE_PATH}"
  local stripped_makefile

  if [[ -f "${dest_makefile}" ]] && grep -qF "${LEGACY_LOADOUT_MAKEFILE_BEGIN_MARKER}" "${dest_makefile}"; then
    print-info "Removing old loadout managed Makefile include from ${dest_makefile}"
    stripped_makefile=$(mktemp)
    awk -v begin="${LEGACY_LOADOUT_MAKEFILE_BEGIN_MARKER}" -v end="${LEGACY_LOADOUT_MAKEFILE_END_MARKER}" '
      $0 == begin { skip = 1; next }
      $0 == end { skip = 0; next }
      !skip { print }
    ' "${dest_makefile}" > "${stripped_makefile}"
    cat "${stripped_makefile}" > "${dest_makefile}"
    rm -f "${stripped_makefile}"
  fi

  if [[ -f "${dest_legacy_module}" ]] && grep -qxF "${LEGACY_LOADOUT_MAKEFILE_FILE_MARKER}" "${dest_legacy_module}"; then
    if makefile-includes-unmanaged "${dest_makefile}" "${LEGACY_LOADOUT_MAKEFILE_MODULE_PATH}"; then
      print-info "Keeping ${dest_legacy_module}, which ${dest_makefile} includes outside a loadout-managed block"
    else
      print-info "Removing old loadout Makefile module ${dest_legacy_module}"
      rm -f "${dest_legacy_module}"
    fi
  fi

  return 0
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

# Remove the hook files that older loadout versions installed in a destination,
# as 'is-removable-legacy-path' allows.
# Arguments:
#   $1=[destination directory path]
function remove-legacy-hook-files() {

  local destination="$1"
  local rel_path git_state real_destination

  real_destination="$(cd "${destination}" 2> /dev/null && pwd -P)" || return 0
  git_state="$(destination-git-state "${destination}")"
  for rel_path in "${LEGACY_HOOK_FILES[@]}"; do
    [[ -e "${destination}/${rel_path}" || -L "${destination}/${rel_path}" ]] || continue
    is-removable-legacy-path "${destination}" "${real_destination}" "${git_state}" "${rel_path}" hook || continue
    print-info "Removing old loadout hook file ${destination}/${rel_path}"
    rm -f "${destination:?}/${rel_path}"
  done
  rmdir "${destination}/.github/hooks" 2> /dev/null || true

  return 0
}

# Remove the skill directories that older loadout versions installed and loadout
# no longer ships, as 'is-removable-legacy-path' allows.
# Arguments:
#   $1=[destination directory path]
function remove-legacy-skill-dirs() {

  local destination="$1"
  local rel_path git_state real_destination

  real_destination="$(cd "${destination}" 2> /dev/null && pwd -P)" || return 0
  git_state="$(destination-git-state "${destination}")"
  for rel_path in "${LEGACY_SKILL_DIRS[@]}"; do
    [[ -e "${destination}/${rel_path}" || -L "${destination}/${rel_path}" ]] || continue
    is-removable-legacy-path "${destination}" "${real_destination}" "${git_state}" "${rel_path}" skill || continue
    print-info "Removing retired loadout skill ${destination}/${rel_path}"
    rm -rf "${destination:?}/${rel_path:?}"
  done

  return 0
}

# Check whether a path that older loadout versions installed may be removed. A
# path the destination tracks in git is its own, so it is kept with a notice,
# as is every path when git cannot tell what is tracked, or a path that a link
# places outside the destination.
# Arguments:
#   $1=[destination directory path]
#   $2=[destination directory path with links resolved]
#   $3=[git state, as 'destination-git-state' prints it]
#   $4=[relative path]
#   $5=[kind of artefact, used in notices, for example 'hook']
function is-removable-legacy-path() {

  local destination="$1" real_destination="$2" git_state="$3" rel_path="$4" kind="$5"
  local parent

  parent="$(cd "$(dirname "${destination}/${rel_path}")" && pwd -P)" || return 1
  if [[ "${parent}" != "${real_destination}/"* ]]; then
    print-info "Keeping ${destination}/${rel_path}, which a link places outside the destination"
    return 1
  fi
  if [[ "${git_state}" == "unknown" ]]; then
    print-info "Keeping ${destination}/${rel_path}, as git cannot tell whether the destination tracks it. Remove it if it is the old loadout ${kind}"
    return 1
  fi
  if [[ "${git_state}" == "repository" ]] && is-destination-owned "${destination}" "${rel_path}"; then
    print-info "Keeping ${destination}/${rel_path}, which the destination tracks. Remove it if it is the old loadout ${kind}"
    return 1
  fi

  return 0
}
