#!/bin/bash

set -euo pipefail
umask 077

# Bootstrap installer for awesome-copilot-promptfiles.
#
# Thin wrapper around scripts/apply.sh that supports two modes:
#   - local mode: run when a sibling apply.sh is present (cloned repo).
#   - remote mode: clone the repository to a temporary directory and
#     invoke apply.sh from there. Suitable for `curl | bash` usage.
#
# Usage:
#   $ ./scripts/install.sh --dest <path> [--ref <ref>] [--subset <csv>] [--dry-run]
#   $ curl -fsSL https://raw.githubusercontent.com/stefaniuk/awesome-copilot-promptfiles/main/scripts/install.sh \
#         | bash -s -- --dest <path> [--ref <ref>] [--subset <csv>]
#
# Options:
#   --dest <path>        Destination directory (required).
#   --ref <ref>          Branch, tag, or commit SHA to install from (default: 'main').
#                        Overridable via the PROMPTFILES_REF environment variable.
#   --subset <csv>       Restrict copy to named categories (forwarded to apply.sh).
#   --dry-run            Print the resolved mode and the exact command without running it.
#   --help               Show this help message.
#
# Environment variables:
#   PROMPTFILES_REPO       owner/repo slug (default: 'stefaniuk/awesome-copilot-promptfiles').
#   PROMPTFILES_GIT_URL    Full git URL; overrides derivation from PROMPTFILES_REPO.
#   PROMPTFILES_REF        Default value for --ref.
#   PROMPTFILES_NO_CLEANUP If 'true', the temporary clone directory is retained.
#
# Exit codes:
#   0 - Success.
#   1 - Runtime failure (missing tools, clone failure, apply failure).
#   2 - Invalid arguments.
#
# Examples:
#   $ ./scripts/install.sh --dest ~/projects/my-app
#   $ ./scripts/install.sh --dest ~/projects/my-app --ref v1.2.3
#   $ ./scripts/install.sh --dest ~/projects/my-app --subset agents,prompts
#   $ curl -fsSL https://raw.githubusercontent.com/stefaniuk/awesome-copilot-promptfiles/main/scripts/install.sh \
#       | bash -s -- --dest ~/projects/my-app --ref v1.2.3

# ==============================================================================

SCRIPT_NAME="install.sh"

function usage() {
  sed -n '4,42p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

function die() {
  local code="$1"; shift
  printf '%s: error: %s\n' "${SCRIPT_NAME}" "$*" >&2
  exit "${code}"
}

function main() {

  local dest=""
  local ref="${PROMPTFILES_REF:-main}"
  local subset=""
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
      --ref)
        [[ $# -ge 2 ]] || die 2 "--ref requires a value"
        ref="$2"
        shift 2
        ;;
      --ref=*)
        ref="${1#--ref=}"
        shift
        ;;
      --subset)
        [[ $# -ge 2 ]] || die 2 "--subset requires a value"
        subset="$2"
        shift 2
        ;;
      --subset=*)
        subset="${1#--subset=}"
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
        printf 'Usage: %s --dest <path> [--ref <ref>] [--subset <csv>] [--dry-run]\n' "${SCRIPT_NAME}" >&2
        die 2 "unknown argument: $1"
        ;;
    esac
  done

  [[ -n "${dest}" ]] || { \
    printf 'Usage: %s --dest <path> [--ref <ref>] [--subset <csv>] [--dry-run]\n' "${SCRIPT_NAME}" >&2; \
    die 2 "--dest is required"; \
  }

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  local mode="remote"
  if [[ -x "${script_dir}/apply.sh" ]]; then
    mode="local"
  fi

  local apply_path
  if [[ "${mode}" == "local" ]]; then
    apply_path="${script_dir}/apply.sh"
  else
    apply_path="<tempdir>/scripts/apply.sh"
  fi

  local env_prefix=""
  if [[ -n "${subset}" ]]; then
    env_prefix="subset=${subset} "
  fi

  if [[ "${dry_run}" == "true" ]]; then
    printf '%s: dry-run (dest=%s, mode=%s, ref=%s)\n' "${SCRIPT_NAME}" "${dest}" "${mode}" "${ref}"
    printf '%s: would run: %s%s %s\n' "${SCRIPT_NAME}" "${env_prefix}" "${apply_path}" "${dest}"
    exit 0
  fi

  if [[ "${mode}" == "local" ]]; then
    if [[ -n "${subset}" ]]; then
      subset="${subset}" "${apply_path}" "${dest}"
    else
      "${apply_path}" "${dest}"
    fi
  else
    install_remote "${dest}" "${ref}" "${subset}"
  fi

  printf '%s: ok (dest=%s, mode=%s, ref=%s)\n' "${SCRIPT_NAME}" "${dest}" "${mode}" "${ref}"
}

function install_remote() {

  local dest="$1"
  local ref="$2"
  local subset="$3"

  command -v git > /dev/null 2>&1 || die 1 "git is required for remote install; install git or run from a cloned repository"

  local repo="${PROMPTFILES_REPO:-stefaniuk/awesome-copilot-promptfiles}"
  local git_url="${PROMPTFILES_GIT_URL:-https://github.com/${repo}.git}"

  local tmp_dir
  tmp_dir="$(mktemp -d 2>/dev/null || mktemp -d -t promptfiles-install)"

  if [[ "${PROMPTFILES_NO_CLEANUP:-false}" != "true" ]]; then
    # shellcheck disable=SC2064
    trap "rm -rf '${tmp_dir}'" EXIT INT TERM
  fi

  if ! git clone --depth 1 --branch "${ref}" "${git_url}" "${tmp_dir}" > /dev/null 2>&1; then
    rm -rf "${tmp_dir}"
    tmp_dir="$(mktemp -d 2>/dev/null || mktemp -d -t promptfiles-install)"
    if [[ "${PROMPTFILES_NO_CLEANUP:-false}" != "true" ]]; then
      # shellcheck disable=SC2064
      trap "rm -rf '${tmp_dir}'" EXIT INT TERM
    fi
    git clone "${git_url}" "${tmp_dir}" > /dev/null 2>&1 \
      || die 1 "failed to clone ${git_url}"
    (cd "${tmp_dir}" && git checkout "${ref}" > /dev/null 2>&1) \
      || die 1 "failed to checkout ref '${ref}' from ${git_url}"
  fi

  local apply_path="${tmp_dir}/scripts/apply.sh"
  [[ -x "${apply_path}" ]] || die 1 "apply.sh not found or not executable in cloned repository: ${apply_path}"

  if [[ -n "${subset}" ]]; then
    subset="${subset}" "${apply_path}" "${dest}"
  else
    "${apply_path}" "${dest}"
  fi
}

main "$@"
