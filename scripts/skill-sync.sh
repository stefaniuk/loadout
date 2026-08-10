#!/bin/bash

set -euo pipefail

# Synchronise external agent skills declared in scripts/config/skills.yaml.
# Clones each skill's directory from its upstream repository into
# .github/skills/<name>/, applies any local patch from the shared
# scripts/skill-patches/ tree, and pins the resolved commit SHA back into
# the config file.
#
# Usage:
#   $ [options] ./scripts/skill-sync.sh
#
# Options:
#   name=<skill>            # Sync only the named skill, default syncs all
#   patch=false             # Skip local patches and use vanilla upstream content, default is 'true'
#   patch_only=true         # Reapply local patches without fetching upstream, default is 'false'
#   VERBOSE=true            # Show all the executed commands, default is 'false'
#
# Exit codes:
#   0 - All skills synced successfully
#   1 - Error during sync

# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

CONFIG_FILE="${SCRIPT_DIR}/config/skills.yaml"
DEST_DIR="${REPO_ROOT}/.github/skills"
PATCHES_DIR="${SCRIPT_DIR}/skill-patches"
MANIFEST_FILE="${PATCHES_DIR}/manifest.yaml"
PATCH_LIB="${PATCHES_DIR}/patch.lib.sh"

if [[ ! -f "${PATCH_LIB}" ]]; then
  echo "error: patch library not found: ${PATCH_LIB}" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "${PATCH_LIB}"

# ==============================================================================

# Main entry point.
function main() {
  cd "${REPO_ROOT}"

  local name=${name:-}

  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "error: config file not found: ${CONFIG_FILE}" >&2
    return 1
  fi

  if ! command -v yq > /dev/null 2>&1; then
    echo "error: yq is required but not installed. Install via: brew install yq" >&2
    return 1
  fi

  mkdir -p "$DEST_DIR"

  local skill_count
  skill_count=$(yq '.skills | length' "$CONFIG_FILE")

  if [[ "$skill_count" -eq 0 ]]; then
    echo "No skills declared in ${CONFIG_FILE}"
    return 0
  fi

  local patch_only=${patch_only:-false}

  local synced=0
  for i in $(seq 0 $((skill_count - 1))); do
    local skill_name
    skill_name=$(yq -r ".skills[$i].name" "$CONFIG_FILE")

    if [[ -n "$name" && "$skill_name" != "$name" ]]; then
      continue
    fi

    if is-arg-true "$patch_only"; then
      local dest="${DEST_DIR}/${skill_name}"
      if [[ ! -d "$dest" ]]; then
        echo "error: skill '${skill_name}' not found on disk; run 'make skill-sync' first" >&2
        return 1
      fi
      patch-local-skill "$skill_name" "$dest"
    else
      sync-skill "$i" "$skill_name"
    fi
    synced=$((synced + 1))
  done

  if [[ -n "$name" && "$synced" -eq 0 ]]; then
    echo "error: skill '${name}' not found in config" >&2
    return 1
  fi

  if is-arg-true "$patch_only"; then
    echo "==> Patched ${synced} skill(s)"
  else
    echo "==> Synced ${synced} skill(s)"
  fi
  update-editorconfig-ignore
  update-markdownlint-ignore
  update-prettier-ignore
  return 0
}

# ==============================================================================

# Update .editorconfigignore with entries for all synced skill directories.
function update-editorconfig-ignore() {
  update-ignore-file "${REPO_ROOT}/scripts/config/.editorconfigignore"
}

# Update .markdownlintignore with entries for all synced skill directories.
function update-markdownlint-ignore() {
  update-ignore-file "${REPO_ROOT}/scripts/config/.markdownlintignore"
}

# Update .prettierignore with entries for all synced skill directories.
function update-prettier-ignore() {
  update-ignore-file "${REPO_ROOT}/scripts/config/.prettierignore"
}

# Update a given ignore file with entries for all synced skill directories.
# Arguments:
#   $1=[path to the ignore file]
function update-ignore-file() {
  local ignore_file="$1"
  local marker_begin="# begin: synced skills"
  local marker_end="# end: synced skills"

  # Build the new block (sorted alphabetically)
  local block="${marker_begin}"
  local entries
  entries=$(yq -r '.skills[].name' "$CONFIG_FILE" | sort)
  while IFS= read -r skill_name; do
    block="${block}"$'\n'".github/skills/${skill_name}/"
  done <<< "$entries"
  block="${block}"$'\n'"${marker_end}"

  if grep -q "$marker_begin" "$ignore_file" 2>/dev/null; then
    # Replace existing block: keep lines outside markers, insert new block
    local tmp
    tmp=$(mktemp)
    local skip=0
    while IFS= read -r line; do
      if [[ "$line" == "$marker_begin" ]]; then
        skip=1
        continue
      fi
      if [[ "$line" == "$marker_end" ]]; then
        skip=0
        continue
      fi
      if [[ "$skip" -eq 0 ]]; then
        printf '%s\n' "$line" >> "$tmp"
      fi
    done < "$ignore_file"
    printf '%s\n' "$block" >> "$tmp"
    mv "$tmp" "$ignore_file"
  else
    # Append new block
    printf '\n%s\n' "$block" >> "$ignore_file"
  fi
  return 0
}

# ==============================================================================

# Apply a local patch fragment to a synced upstream skill.
# Arguments:
#   $1=[skill name]
#   $2=[destination directory]
function patch-local-skill() {
  local skill_name="$1"
  local dest_dir="$2"
  local patch=${patch:-true}
  local skill_file="${dest_dir}/SKILL.md"
  local patch_file="${PATCHES_DIR}/skills/${skill_name}.patch.md"

  if ! is-arg-true "${patch}"; then
    return 0
  fi

  if [[ ! -f "${skill_file}" ]]; then
    return 0
  fi

  if [[ -f "${patch_file}" ]]; then
    local injection_point
    injection_point=$(patch-get-injection-point "$MANIFEST_FILE" "${skill_name}/SKILL.md" "skills")

    echo "  patching .github/skills/${skill_name}/SKILL.md (injection: ${injection_point})"

    local upstream_content
    local patch_content
    local patched_content
    upstream_content=$(cat "${skill_file}")
    patch_content=$(cat "${patch_file}")
    patched_content=$(patch-inject "${upstream_content}" "${patch_content}" "${injection_point}")

    echo "${patched_content}" > "${skill_file}"
  fi

  patch-apply-frontmatter "${skill_file}" "$MANIFEST_FILE" "${skill_name}/SKILL.md"

  return 0
}

# ==============================================================================

# Sync a single skill by its index in the config.
# Arguments:
#   $1=[index in the skills array]
#   $2=[skill name]
function sync-skill() {
  local idx="$1"
  local skill_name="$2"

  local repo path ref
  repo=$(yq -r ".skills[$idx].repo" "$CONFIG_FILE")
  path=$(yq -r ".skills[$idx].path" "$CONFIG_FILE")
  ref=$(yq -r ".skills[$idx].ref // \"main\"" "$CONFIG_FILE")

  echo "==> Syncing '${skill_name}' from ${repo} (ref: ${ref}, path: ${path})"

  local temp_dir
  temp_dir=$(mktemp -d)

  git clone --depth 1 --branch "$ref" --filter=blob:none --sparse "$repo" "$temp_dir" 2>&1 | grep -v "^remote:" || true
  git -C "$temp_dir" sparse-checkout set "$path" 2>/dev/null

  local source_dir="${temp_dir}/${path}"
  if [[ ! -d "$source_dir" ]]; then
    echo "  warning: path '${path}' not found in ${repo}@${ref}, skipping" >&2
    rm -rf "$temp_dir"
    return 0
  fi

  local resolved_sha
  resolved_sha=$(git -C "$temp_dir" rev-parse HEAD)

  local dest="${DEST_DIR}/${skill_name}"
  rm -rf "$dest"
  mkdir -p "$dest"
  cp -R "${source_dir}/." "$dest/"

  patch-local-skill "$skill_name" "$dest"

  rm -rf "$temp_dir"

  # Pin the resolved SHA back into the config
  yq -i ".skills[$idx].ref = \"${ref}\" | .skills[$idx].sha = \"${resolved_sha}\"" "$CONFIG_FILE"

  echo "  copied to .github/skills/${skill_name}/ (sha: ${resolved_sha:0:7})"
  return 0
}

# ==============================================================================

# Parse a boolean argument value.
# Arguments:
#   $1=[value to test]
# Returns:
#   0 if the value is truthy, 1 otherwise
function is-arg-true() {
  if [[ "$1" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$ ]]; then
    return 0
  else
    return 1
  fi
}

# ==============================================================================

if is-arg-true "${VERBOSE:-false}"; then
  set -x
fi

main
exit 0
