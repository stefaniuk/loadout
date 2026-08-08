#!/bin/bash

set -euo pipefail

# Add a new external skill entry to scripts/config/skills.yaml.
# Does not fetch the skill; run `make skill-sync` afterwards.
#
# Usage:
#   $ name=<name> repo=<repo-url> path=<path-in-repo> [ref=<branch>] ./scripts/skill-add.sh
#
# Arguments:
#   name=[skill name]       # Local directory name under .github/skills/external/
#   repo=[repository URL]   # Git clone URL (https)
#   path=[path in repo]     # Subdirectory within the repository to copy
#   ref=[branch or tag]     # Optional, defaults to 'main'
#
# Exit codes:
#   0 - Skill added successfully
#   1 - Missing arguments or skill already exists

# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config/skills.yaml"

# ==============================================================================

# Main entry point.
function main() {
  local name=${name:-}
  local repo=${repo:-}
  local path=${path:-}
  local ref=${ref:-main}

  if [[ -z "$name" || -z "$repo" || -z "$path" ]]; then
    echo "error: name, repo, and path are required" >&2
    echo "Usage: name=<name> repo=<url> path=<path> ./scripts/skills/add-skill.sh" >&2
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

  # Check for duplicates
  local existing
  existing=$(yq -r ".skills[] | select(.name == \"${name}\") | .name" "$CONFIG_FILE")
  if [[ -n "$existing" ]]; then
    echo "error: skill '${name}' already exists in config" >&2
    return 1
  fi

  # Append the new entry
  yq -i ".skills += [{\"name\": \"${name}\", \"repo\": \"${repo}\", \"path\": \"${path}\", \"ref\": \"${ref}\"}]" "$CONFIG_FILE"

  echo "Added '${name}' to ${CONFIG_FILE}"
  echo "Run 'make skill-sync' to fetch it."
  return 0
}

# ==============================================================================

main
exit 0
