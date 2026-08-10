#!/bin/bash

set -euo pipefail

# Fetch upstream spec-kit files and apply shared local patches to produce
# patched files in the effective locations.
#
# Usage:
#   $ [options] ./scripts/specify.sh
#
# Options:
#   patch=false             # Skip local patches and use vanilla upstream files, default is 'true'
#   dry_run=true            # Show what would change without modifying files, default is 'false'
#   VERBOSE=true            # Show all the executed commands, default is 'false'
#
# Exit codes:
#   0 - All files patched successfully
#   1 - Error during patching
#
# Notes:
#   1) Requires the 'specify' CLI to be installed
#   2) Requires 'yq' for YAML parsing (falls back to defaults if not available)

# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

PATCHES_DIR="${SCRIPT_DIR}/skill-patches"
MANIFEST_FILE="${PATCHES_DIR}/manifest.yaml"
PATCH_LIB="${PATCHES_DIR}/patch.lib.sh"

if [[ ! -f "${PATCH_LIB}" ]]; then
  echo "error: patch library not found: ${PATCH_LIB}" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "${PATCH_LIB}"

# Target locations for patched files
TARGET_SKILLS="${REPO_ROOT}/.github/skills"
TARGET_TEMPLATES="${REPO_ROOT}/.specify/templates"
TARGET_SCRIPTS="${REPO_ROOT}/.specify/scripts/python"
VERSION_FILE="${REPO_ROOT}/.specify/.speckit-version"

# Global variable for temp directory (used by trap)
TEMP_DIR=""

# ==============================================================================

# Main entry point for the patching workflow.
function main() {
  cd "${REPO_ROOT}"

  local dry_run=${dry_run:-false}

  echo "==> Fetching upstream spec-kit files..."
  TEMP_DIR=$(create-temp-directory)
  trap 'cleanup-temp-directory "$TEMP_DIR"' EXIT

  fetch-upstream-files "$TEMP_DIR"

  echo "==> Saving spec-kit version..."
  save-speckit-version

  local patch=${patch:-true}

  if is-arg-true "$patch"; then
    echo "==> Applying shared local patches..."
    patch-skills "$TEMP_DIR"
    patch-category "$TEMP_DIR" "templates" ".specify/templates" "${TARGET_TEMPLATES}" "*-template.md"
  else
    echo "==> Skipping shared local patches (patch=false)."
    copy-vanilla-skills "$TEMP_DIR"
    patch-category "$TEMP_DIR" "templates" ".specify/templates" "${TARGET_TEMPLATES}" "*-template.md"
  fi

  echo "==> Copying spec-kit scripts (Python)..."
  copy-scripts "$TEMP_DIR"

  if is-arg-true "$dry_run"; then
    echo "==> Dry run complete. No files were modified."
  else
    echo "==> Patching complete."
  fi

  emit-commit-message

  return 0
}

# ==============================================================================

# Create a temporary directory for upstream files.
# Returns:
#   Path to the temporary directory (via stdout)
function create-temp-directory() {
  local temp_dir
  temp_dir=$(mktemp -d)
  echo "$temp_dir"
  return 0
}

# Clean up the temporary directory.
# Arguments:
#   $1=[path to temporary directory]
# shellcheck disable=SC2329
function cleanup-temp-directory() {
  local temp_dir="$1"
  if [[ -d "$temp_dir" ]]; then
    rm -rf "$temp_dir"
  fi
  return 0
}

# Detect and save the installed spec-kit CLI version to the version file.
# Warns if the installed version is older than the latest GitHub release.
function save-speckit-version() {
  local dry_run=${dry_run:-false}
  local version_output
  version_output=$(specify --version 2>/dev/null || echo "")
  local version="${version_output#specify }"

  if [[ -z "$version" ]]; then
    echo "    Warning: Could not detect spec-kit version"
    return 0
  fi

  echo "    Installed: ${version}"
  check-speckit-latest "$version"

  if ! is-arg-true "$dry_run"; then
    mkdir -p "$(dirname "$VERSION_FILE")"
    echo "$version" > "$VERSION_FILE"
  fi

  return 0
}

# Compare the installed version against the latest GitHub release.
# Emits a warning if the installed version is behind.
# Arguments:
#   $1=[installed version string, e.g. "0.14.2"]
function check-speckit-latest() {
  local installed="$1"
  local latest

  # Fetch latest release tag from GitHub (silent, best-effort)
  latest=$(curl -fsSL \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/github/spec-kit/releases/latest" 2>/dev/null \
    | grep -m1 '"tag_name"' | sed 's/.*"v\?\([^"]*\)".*/\1/')

  if [[ -z "$latest" ]]; then
    return 0
  fi

  if [[ "$installed" == "$latest" ]]; then
    echo "    Latest:    ${latest} (up to date)"
  elif is-version-older "$installed" "$latest"; then
    echo "    Latest:    ${latest}"
    echo "    WARNING: Installed spec-kit ${installed} is behind latest ${latest}."
    echo "             Run: specify self upgrade"
  else
    echo "    Latest:    ${latest} (up to date)"
  fi

  return 0
}

# Compare two semver strings. Returns 0 (true) if $1 < $2.
# Arguments:
#   $1=[version a]
#   $2=[version b]
function is-version-older() {
  local IFS='.'
  # shellcheck disable=SC2206
  local a=($1) b=($2)
  local i

  for i in 0 1 2; do
    local ai="${a[$i]:-0}"
    local bi="${b[$i]:-0}"
    if (( ai < bi )); then
      return 0
    elif (( ai > bi )); then
      return 1
    fi
  done

  # Equal
  return 1
}

# Print a suggested conventional commit message using the installed version.
function emit-commit-message() {
  local version=""
  if [[ -f "$VERSION_FILE" ]]; then
    version=$(<"$VERSION_FILE")
  fi
  if [[ -z "$version" ]]; then
    return 0
  fi
  echo "==> Suggested commit message:"
  echo "    build(speckit): upgrade to spec-kit ${version}"
  return 0
}

# Copy Python scripts from the upstream init output, removing any
# legacy bash scripts directory.
# Arguments:
#   $1=[path to temporary directory]
function copy-scripts() {
  local temp_dir="$1"
  local source_dir="${temp_dir}/.specify/scripts/python"
  local bash_dir="${REPO_ROOT}/.specify/scripts/bash"
  local dry_run=${dry_run:-false}

  if [[ ! -d "$source_dir" ]]; then
    echo "    Warning: Python scripts directory not found: ${source_dir}"
    return 0
  fi

  # Remove legacy bash scripts
  if [[ -d "$bash_dir" ]]; then
    echo "    Removing legacy bash scripts"
    if ! is-arg-true "$dry_run"; then
      rm -rf "$bash_dir"
    fi
  fi

  # Copy Python scripts
  if ! is-arg-true "$dry_run"; then
    mkdir -p "$TARGET_SCRIPTS"
  fi

  local file
  for file in "${source_dir}"/*.py; do
    [[ -f "$file" ]] || continue
    local filename
    filename=$(basename "$file")
    echo "    Copying: ${filename}"
    if ! is-arg-true "$dry_run"; then
      cp "$file" "${TARGET_SCRIPTS}/${filename}"
    fi
  done

  return 0
}

# Patch Spec Kit skill files from upstream with shared local skill patches.
# Arguments:
#   $1=[path to temporary directory]
function patch-skills() {
  local temp_dir="$1"
  local source_dir="${temp_dir}/.github/skills"
  local patches_dir="${PATCHES_DIR}/skills"
  local dry_run=${dry_run:-false}

  echo "  [skills]"

  if [[ ! -d "$source_dir" ]]; then
    echo "    Warning: Skills source directory not found: ${source_dir}"
    return 0
  fi

  local skill_dir
  for skill_dir in "${source_dir}"/speckit-*/; do
    [[ -d "$skill_dir" ]] || continue

    local skill_name
    skill_name=$(basename "$skill_dir")
    local source_file="${skill_dir}SKILL.md"
    local patch_file="${patches_dir}/${skill_name}.patch.md"
    local target_dir="${TARGET_SKILLS}/${skill_name}"
    local target_file="${target_dir}/SKILL.md"

    if [[ ! -f "$source_file" ]]; then
      continue
    fi

    if ! is-arg-true "$dry_run"; then
      mkdir -p "$target_dir"
    fi

    if [[ -f "$patch_file" ]]; then
      local injection_point
      injection_point=$(patch-get-injection-point "$MANIFEST_FILE" "${skill_name}/SKILL.md" "skills")
      echo "    Patching: ${skill_name}/SKILL.md (injection: ${injection_point})"
      if ! is-arg-true "$dry_run"; then
        local upstream_content
        local patch_content
        local patched_content
        upstream_content=$(cat "$source_file")
        patch_content=$(cat "$patch_file")
        patched_content=$(patch-inject "$upstream_content" "$patch_content" "$injection_point")
        echo "$patched_content" > "$target_file"
      fi
    else
      echo "    Copying:  ${skill_name}/SKILL.md (no patch)"
      if ! is-arg-true "$dry_run"; then
        cp "$source_file" "$target_file"
      fi
    fi

    if ! is-arg-true "$dry_run"; then
      patch-apply-frontmatter "$target_file" "$MANIFEST_FILE" "${skill_name}/SKILL.md"
    fi
  done

  return 0
}

# Copy upstream skill files without applying patches.
# Arguments:
#   $1=[path to temporary directory]
function copy-vanilla-skills() {
  local temp_dir="$1"
  local source_dir="${temp_dir}/.github/skills"
  local dry_run=${dry_run:-false}

  echo "  [skills] (vanilla)"

  if [[ ! -d "$source_dir" ]]; then
    echo "    Warning: Skills source directory not found: ${source_dir}"
    return 0
  fi

  local skill_dir
  for skill_dir in "${source_dir}"/speckit-*/; do
    [[ -d "$skill_dir" ]] || continue

    local skill_name
    skill_name=$(basename "$skill_dir")
    local source_file="${skill_dir}SKILL.md"
    local target_dir="${TARGET_SKILLS}/${skill_name}"
    local target_file="${target_dir}/SKILL.md"

    if [[ ! -f "$source_file" ]]; then
      continue
    fi

    echo "    Copying:  ${skill_name}/SKILL.md"
    if ! is-arg-true "$dry_run"; then
      mkdir -p "$target_dir"
      cp "$source_file" "$target_file"
    fi
  done

  return 0
}

# Fetch upstream spec-kit files using the specify CLI.
# Runs specify init for copilot so that all upstream artifacts are
# available for patching.
# Arguments:
#   $1=[path to temporary directory]
function fetch-upstream-files() {
  local temp_dir="$1"

  (
    cd "$temp_dir"
    specify init \
      --integration copilot \
      --integration-options="--skills" \
      --script py \
      --ignore-agent-tools \
      --here \
      --force \
      > /dev/null 2>&1
  )

  return 0
}

# Patch a category of files from the shared local patch tree.
# Arguments:
#   $1=[path to temporary directory]
#   $2=[category name: templates or another shared patch category]
#   $3=[source subdirectory within temp dir]
#   $4=[target directory for patched files]
#   $5=[glob pattern for files to process]
function patch-category() {
  local temp_dir="$1"
  local category="$2"
  local source_subdir="$3"
  local target_dir="$4"
  local glob_pattern="$5"

  local source_dir="${temp_dir}/${source_subdir}"
  local patches_subdir="${PATCHES_DIR}/${category}"
  local dry_run=${dry_run:-false}

  echo "  [${category}]"

  if [[ ! -d "$source_dir" ]]; then
    echo "    Warning: Source directory not found: ${source_dir}"
    return 0
  fi

  # Ensure target directory exists
  if ! is-arg-true "$dry_run"; then
    mkdir -p "$target_dir"
  fi

  # Process each file matching the pattern
  local file
  for file in "${source_dir}"/${glob_pattern}; do
    if [[ ! -f "$file" ]]; then
      continue
    fi

    local filename
    filename=$(basename "$file")
    local patch_file="${patches_subdir}/${filename%.md}.patch.md"
    local target_file="${target_dir}/${filename}"

    if [[ -f "$patch_file" ]]; then
      patch-file "$file" "$patch_file" "$target_file" "$filename" "$category"
    else
      copy-file "$file" "$target_file" "$filename"
    fi
  done

  return 0
}

# Patch a single file by injecting the patch content at the configured location.
# Arguments:
#   $1=[path to upstream file]
#   $2=[path to patch file]
#   $3=[path to target file]
#   $4=[filename for display]
#   $5=[category name: templates or another shared patch category]
function patch-file() {
  local upstream_file="$1"
  local patch_file="$2"
  local target_file="$3"
  local filename="$4"
  local category="$5"

  local dry_run=${dry_run:-false}
  local injection_point

  injection_point=$(patch-get-injection-point "$MANIFEST_FILE" "$filename" "$category")

  echo "    Patching: ${filename} (injection: ${injection_point})"

  if is-arg-true "$dry_run"; then
    echo "      Would inject patch from: ${patch_file}"
    return 0
  fi

  local upstream_content
  local patch_content
  local patched_content

  upstream_content=$(cat "$upstream_file")
  patch_content=$(cat "$patch_file")

  patched_content=$(patch-inject "$upstream_content" "$patch_content" "$injection_point")

  echo "$patched_content" > "$target_file"

  return 0
}

# Copy a file without patching.
# Arguments:
#   $1=[path to source file]
#   $2=[path to target file]
#   $3=[filename for display]
function copy-file() {
  local source_file="$1"
  local target_file="$2"
  local filename="$3"

  local dry_run=${dry_run:-false}

  echo "    Copying:  ${filename} (no patch)"

  if is-arg-true "$dry_run"; then
    return 0
  fi

  cp "$source_file" "$target_file"

  return 0
}

# Check if an argument is truthy (true, yes, y, on, 1).
# Arguments:
#   $1=[value to check]
# Returns:
#   0 if truthy, 1 otherwise
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
