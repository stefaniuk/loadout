#!/bin/bash

set -euo pipefail

# Pre-commit git hook to check the EditorConfig rules compliance over changed
# files. It ensures all non-binary files across the codebase are formatted
# according to the style defined in the `.editorconfig` file. This is a
# editorconfig command wrapper. It will run editorconfig natively if it is
# installed, otherwise it will run it in a Docker container.
#
# Usage:
#   $ [options] ./check-file-format.sh
#
# Options:
#   check={all,staged-changes,working-tree-changes,branch}  # Check mode, default is 'working-tree-changes'
#   dry_run=true                                            # Do not check, run dry run only, default is 'false'
#   BRANCH_NAME=other-branch-than-main                      # Branch to compare with, default is `origin/main`
#   FORCE_USE_DOCKER=true                                   # If set to true the command is run in a Docker container, default is 'false'
#   VERBOSE=true                                            # Show all the executed commands, default is `false`
#
# Exit codes:
#   0 - All files are formatted correctly
#   1 - Files are not formatted correctly
#
# The `check` parameter controls which files are checked, so you can
# limit the scope of the check according to what is appropriate at the
# point the check is being applied.
#
#   check=all: check all files in the repository
#   check=staged-changes: check only files staged for commit.
#   check=working-tree-changes: check modified, unstaged files. This is the default.
#   check=branch: check for all changes since branching from $BRANCH_NAME
#
# Notes:
#   Please make sure to enable EditorConfig linting in your IDE. For the
#   Visual Studio Code editor it is `editorconfig.editorconfig` that is already
#   specified in the `./.vscode/extensions.json` file.

# ==============================================================================

function main() {

  cd "$(git rev-parse --show-toplevel)"

  # shellcheck disable=SC2154
  is-arg-true "${dry_run:-false}" && dry_run_opt="--dry-run"

  check=${check:-working-tree-changes}
  case $check in
    "all")
      filter="git ls-files --exclude-standard"
      ;;
    "staged-changes")
      filter="git diff --diff-filter=ACMRT --name-only --cached"
      ;;
    "working-tree-changes")
      filter="git diff --diff-filter=ACMRT --name-only"
      ;;
    "branch")
      filter="git diff --diff-filter=ACMRT --name-only ${BRANCH_NAME:-origin/main}"
      ;;
    *)
      echo "Unrecognised check mode: $check" >&2 && exit 1
      ;;
  esac

  # Exclude files tracked by git but missing from the working tree
  local files
  files=$($filter | while IFS= read -r f; do [ -f "$f" ] && printf '%s\n' "$f"; done || true)
  [[ -z "$files" ]] && return 0

  # Exclude paths listed in .editorconfigignore
  local ignore_file="$PWD/scripts/config/.editorconfigignore"
  if [[ -f "$ignore_file" ]]; then
    local patterns
    patterns=$(grep -v '^#' "$ignore_file" | grep -v '^$' || true)
    if [[ -n "$patterns" ]]; then
      local grep_pattern
      grep_pattern=$(echo "$patterns" | sed 's|/$||' | paste -sd'|' -)
      files=$(echo "$files" | grep -Ev "^($grep_pattern)" || true)
      [[ -z "$files" ]] && return 0
    fi
  fi

  if command -v editorconfig-checker > /dev/null 2>&1 && ! is-arg-true "${FORCE_USE_DOCKER:-false}"; then
    files="$files" dry_run_opt="${dry_run_opt:-}" run-editorconfig-natively
  else
    files="$files" dry_run_opt="${dry_run_opt:-}" run-editorconfig-in-docker
  fi
}

# Run editorconfig natively.
# Arguments (provided as environment variables):
#   dry_run_opt=[dry run option]
#   files=[newline-separated file list]
function run-editorconfig-natively() {

  # shellcheck disable=SC2046,SC2086
  editorconfig-checker \
    -config "$PWD/scripts/config/editorconfig-checker.json" \
    --exclude '.git/' $dry_run_opt $files
}

# Run editorconfig in a Docker container.
# Arguments (provided as environment variables):
#   dry_run_opt=[dry run option]
#   files=[newline-separated file list]
function run-editorconfig-in-docker() {

  # shellcheck disable=SC1091
  source ./scripts/docker/docker.lib.sh

  # shellcheck disable=SC2155
  local image=$(name=mstruebing/editorconfig-checker docker-get-image-version-and-pull)
  # We use /dev/null here as a backstop in case there are no files in the state
  # we choose. If the filter comes back empty, adding `/dev/null` onto it has
  # the effect of preventing `ec` from treating "no files" as "all the files".
  local files_inline
  files_inline=$(echo "$files" | tr '\n' ' ')
  # shellcheck disable=SC2086
  docker run --rm --platform linux/amd64 \
    --volume "$PWD":/check \
    "$image" \
      sh -c "cd /check && ec -config /check/scripts/config/editorconfig-checker.json --exclude '.git/' $dry_run_opt $files_inline /dev/null"
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
