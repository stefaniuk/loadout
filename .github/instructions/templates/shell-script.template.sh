#!/usr/bin/env bash

set -euo pipefail

# Check <what> in the selected files with <tool>. It runs <tool> natively when
# installed, otherwise in a Docker container.
#
# Usage:
#   $ [options] ./scripts/<area>/<script-name>.sh
#
# Options:
#   check={all,staged-changes,working-tree-changes,branch}
#       Check mode, default is 'working-tree-changes'
#   BRANCH_NAME=other-branch-than-main
#       Branch to compare with, default is 'origin/main'
#   FORCE_USE_DOCKER=true
#       Run in a Docker container, default is 'false'
#   VERBOSE=true
#       Show all the executed commands, default is 'false'
#
# Exit codes:
#   0 - All files passed
#   1 - <tool> reported findings, or the check mode is not recognised
#
# Notes:
#   1) Check modes select existing files known to Git, as described in
#      './scripts/quality/git-files.lib.sh'. Untracked files are never checked.
#   2) Pin the <tool> image in the '[_.docker]' table of 'mise.toml'.

# ==============================================================================

# Check the selected files in native or Docker mode.
function main() {

  cd "$(git rev-parse --show-toplevel)"

  # shellcheck disable=SC1091
  source ./scripts/quality/git-files.lib.sh
  local -a files=()
  quality-collect-git-files files "${check:-working-tree-changes}" '*.ext' || return "$?"

  if [[ ${#files[@]} -gt 0 ]]; then
    if command -v toolname > /dev/null 2>&1 && ! is-arg-true "${FORCE_USE_DOCKER:-false}"; then
      run-tool-natively "${files[@]}" || return "$?"
    else
      run-tool-in-docker "${files[@]}" || return "$?"
    fi
  fi

  return 0
}

# Run <tool> natively.
# Arguments:
#   $@=[files to check, relative to the repository root]
function run-tool-natively() {

  toolname \
    --config "$PWD/scripts/config/toolname.yaml" \
    "$@" || return "$?"

  return 0
}

# Run <tool> in a Docker container.
# Arguments:
#   $@=[files to check, relative to the repository root]
function run-tool-in-docker() {

  # shellcheck disable=SC1091
  source ./scripts/docker/docker.lib.sh

  local image
  image=$(name=org/toolname docker-get-image-version-and-pull) || return "$?"
  docker run --rm --platform linux/amd64 \
    --network none \
    --volume "$PWD":/workdir:ro \
    --workdir /workdir \
    "$image" \
      toolname \
        --config /workdir/scripts/config/toolname.yaml \
        "$@" || return "$?"

  return 0
}

# ==============================================================================

# Check whether the supplied argument represents a true boolean value.
# Arguments:
#   $1=[value to evaluate]
function is-arg-true() {

  local value="$1"
  if [[ "$value" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$ ]]; then
    return 0
  else
    return 1
  fi
}

# ==============================================================================

is-arg-true "${VERBOSE:-false}" && set -x

main "$@"

exit 0
