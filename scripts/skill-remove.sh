#!/bin/bash

set -euo pipefail

# Remove an external skill entry from scripts/config/skills.yaml.
# Deletes the already-synced .github/skills/<name>/ directory, if any.
# Also removes any associated patch file at scripts/config/skill-patches/<name>.patch.md
# and attempts to clean up the matching override entry in scripts/config/skill-patches.yaml.
#
# Usage:
#   $ name=<name> ./scripts/skill-remove.sh
#
# Arguments:
#   name=[skill name]       # Name of the skill entry to remove
#
# Exit codes:
#   0 - Skill removed successfully
#   1 - Missing arguments, missing config, or skill not found

# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config/skills.yaml"
DEST_DIR="${REPO_ROOT}/.github/skills"
PATCH_FILE_DIR="${SCRIPT_DIR}/config/skill-patches"

# ==============================================================================

# Main entry point.
function main() {
  local name=${name:-}

  if [[ -z "$name" ]]; then
    echo "error: name is required" >&2
    echo "Usage: name=<name> ./scripts/skill-remove.sh" >&2
    return 1
  fi

  if ! command -v yq > /dev/null 2>&1; then
    echo "error: yq is required but not installed. Install via: brew install yq" >&2
    return 1
  fi

  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "error: config file not found: ${CONFIG_FILE}" >&2
    return 1
  fi

  # Check the entry exists
  local existing
  existing=$(yq -r ".skills[] | select(.name == \"${name}\") | .name" "$CONFIG_FILE")
  if [[ -z "$existing" ]]; then
    echo "error: skill '${name}' not found in config" >&2
    return 1
  fi

  # Remove the matching entry
  yq -i "del(.skills[] | select(.name == \"${name}\"))" "$CONFIG_FILE"

  local skill_dir="${DEST_DIR}/${name}"
  if [[ -d "$skill_dir" ]]; then
    rm -rf "$skill_dir"
    echo "Removed synced directory ${skill_dir}"
  fi

  # Remove patch file if it exists
  local patch_file="${PATCH_FILE_DIR}/${name}.patch.md"
  if [[ -f "$patch_file" ]]; then
    rm -f "$patch_file"
    echo "Removed patch file ${patch_file}"
  fi

  # Clean up override entry in skill-patches.yaml if it exists
  local patch_manifest="${PATCH_FILE_DIR%/*}/skill-patches.yaml"
  if [[ -f "$patch_manifest" ]] && command -v yq > /dev/null 2>&1; then
    if yq -r ".overrides[\"${name}*\"] // empty" "$patch_manifest" | grep -q .; then
      yq -i "del(.overrides[\"${name}\"]) | del(.overrides[\"${name}-template\"])" "$patch_manifest"
      echo "Cleaned up override entries from ${patch_manifest}"
    fi
  fi

  echo "Removed '${name}' from ${CONFIG_FILE}"
  return 0
}

# ==============================================================================

main
exit 0
