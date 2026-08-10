#!/bin/bash

set -euo pipefail

# Shared helpers for applying local patch fragments to synced or imported
# skill and template files.
#
# Usage:
#   $ source ./patch.lib.sh

# ==============================================================================

# Resolve the configured injection point for a patched file.
# Arguments:
#   $1=[manifest file path]
#   $2=[relative file path, e.g. incremental-implementation/SKILL.md]
#   $3=[category name: skills, templates, or other manifest category]
# Returns:
#   Injection point string (via stdout)
function patch-get-injection-point() {
  local manifest_file="$1"
  local filename="$2"
  local category="$3"
  local default_injection

  default_injection=$(patch-get-default-injection-point "$category")

  if command -v yq > /dev/null 2>&1 && [[ -f "$manifest_file" ]]; then
    local override
    override=$(yq -r ".overrides.\"${filename}\" // \"\"" "$manifest_file" 2>/dev/null || echo "")
    if [[ -n "$override" ]]; then
      echo "$override"
      return 0
    fi

    local category_default=""
    category_default=$(yq -r ".defaults.\"${category}\" // \"\"" "$manifest_file" 2>/dev/null || echo "")

    if [[ -n "$category_default" ]]; then
      echo "$category_default"
      return 0
    fi
  fi

  echo "$default_injection"

  return 0
}

# Return the built-in default injection point for a category.
# Arguments:
#   $1=[category name: skills, templates, or other manifest category]
# Returns:
#   Default injection point string (via stdout)
function patch-get-default-injection-point() {
  local category="$1"

  echo "after-frontmatter"

  return 0
}

# Inject patch content into upstream content at the specified location.
# Arguments:
#   $1=[upstream content]
#   $2=[patch content]
#   $3=[injection point]
# Returns:
#   Patched content (via stdout)
function patch-inject() {
  local upstream_content="$1"
  local patch_content="$2"
  local injection_point="$3"

  case "$injection_point" in
    after-frontmatter)
      patch-inject-after-frontmatter "$upstream_content" "$patch_content"
      ;;
    replace-before-section:*)
      local section_name="${injection_point#replace-before-section:}"
      patch-inject-replace-before-section "$upstream_content" "$patch_content" "$section_name"
      ;;
    before-section:*)
      local section_name="${injection_point#before-section:}"
      patch-inject-before-section "$upstream_content" "$patch_content" "$section_name"
      ;;
    after-section:*)
      local section_name="${injection_point#after-section:}"
      patch-inject-after-section "$upstream_content" "$patch_content" "$section_name"
      ;;
    append)
      patch-inject-append "$upstream_content" "$patch_content"
      ;;
    prepend)
      patch-inject-prepend "$upstream_content" "$patch_content"
      ;;
    *)
      patch-inject-after-frontmatter "$upstream_content" "$patch_content"
      ;;
  esac

  return 0
}

# Replace the content after front matter up to a specific section heading.
# If the section heading is not found, the remaining upstream content is kept.
# Arguments:
#   $1=[upstream content]
#   $2=[patch content]
#   $3=[section heading to keep from upstream]
# Returns:
#   Patched content (via stdout)
function patch-inject-replace-before-section() {
  local upstream_content="$1"
  local patch_content="$2"
  local section_name="$3"

  local -a lines=()
  local line
  while IFS= read -r line || [[ -n "$line" ]]; do
    lines+=("$line")
  done <<< "$upstream_content"

  local line_count="${#lines[@]}"
  local frontmatter_end_index=-1
  local delimiter_count=0
  local index=0
  local result=""
  local content_start_index=0
  local section_index=-1

  if (( line_count > 0 )) && [[ "${lines[0]}" == "---" ]]; then
    for ((index=0; index<line_count; index++)); do
      if [[ "${lines[$index]}" == "---" ]]; then
        ((delimiter_count++))
        if (( delimiter_count == 2 )); then
          frontmatter_end_index=$index
          break
        fi
      fi
    done
  fi

  if (( frontmatter_end_index >= 0 )); then
    for ((index=0; index<=frontmatter_end_index; index++)); do
      result+="${lines[$index]}"$'\n'
    done
    result+=$'\n'"${patch_content}"$'\n'
    content_start_index=$((frontmatter_end_index + 1))
  else
    result+="${patch_content}"$'\n'
  fi

  for ((index=content_start_index; index<line_count; index++)); do
    if [[ "${lines[$index]}" == "$section_name"* ]]; then
      section_index=$index
      break
    fi
  done

  if (( section_index >= 0 )); then
    result+=$'\n'
    for ((index=section_index; index<line_count; index++)); do
      result+="${lines[$index]}"$'\n'
    done
  else
    for ((index=content_start_index; index<line_count; index++)); do
      result+="${lines[$index]}"$'\n'
    done
  fi

  result="${result%$'\n'}"
  echo "$result"

  return 0
}

# Inject patch content after YAML front matter.
# Arguments:
#   $1=[upstream content]
#   $2=[patch content]
# Returns:
#   Patched content (via stdout)
function patch-inject-after-frontmatter() {
  local upstream_content="$1"
  local patch_content="$2"

  local -a lines=()
  local line
  while IFS= read -r line || [[ -n "$line" ]]; do
    lines+=("$line")
  done <<< "$upstream_content"

  if (( ${#lines[@]} == 0 )) || [[ "${lines[0]}" != "---" ]]; then
    echo "${patch_content}"$'\n'$'\n'"${upstream_content}"
    return 0
  fi

  local delimiter_count=0
  local frontmatter_end_index=-1
  local index=0
  local result=""

  for ((index=0; index<${#lines[@]}; index++)); do
    if [[ "${lines[$index]}" == "---" ]]; then
      ((delimiter_count++))
      if (( delimiter_count == 2 )); then
        frontmatter_end_index=$index
        break
      fi
    fi
  done

  if (( frontmatter_end_index < 0 )); then
    echo "${patch_content}"$'\n'$'\n'"${upstream_content}"
    return 0
  fi

  for ((index=0; index<=frontmatter_end_index; index++)); do
    result+="${lines[$index]}"$'\n'
  done

  result+=$'\n'"${patch_content}"$'\n'

  for ((index=frontmatter_end_index+1; index<${#lines[@]}; index++)); do
    result+="${lines[$index]}"$'\n'
  done

  result="${result%$'\n'}"
  echo "$result"

  return 0
}

# Inject patch content before a specific section heading.
# Arguments:
#   $1=[upstream content]
#   $2=[patch content]
#   $3=[section heading to find]
# Returns:
#   Patched content (via stdout)
function patch-inject-before-section() {
  local upstream_content="$1"
  local patch_content="$2"
  local section_name="$3"

  local injected=false
  local result=""
  local line

  while IFS= read -r line || [[ -n "$line" ]]; do
    if ! $injected && [[ "$line" == "$section_name"* ]]; then
      result+="${patch_content}"$'\n'$'\n'
      injected=true
    fi
    result+="${line}"$'\n'
  done <<< "$upstream_content"

  if ! $injected; then
    result+=$'\n'"${patch_content}"
  fi

  result="${result%$'\n'}"
  echo "$result"

  return 0
}

# Inject patch content after a specific section heading and its first paragraph.
# Arguments:
#   $1=[upstream content]
#   $2=[patch content]
#   $3=[section heading to find]
# Returns:
#   Patched content (via stdout)
function patch-inject-after-section() {
  local upstream_content="$1"
  local patch_content="$2"
  local section_name="$3"

  local found_section=false
  local injected=false
  local result=""
  local line

  while IFS= read -r line || [[ -n "$line" ]]; do
    result+="${line}"$'\n'

    if ! $injected && [[ "$line" == "$section_name"* ]]; then
      found_section=true
    elif $found_section && ! $injected; then
      result+=$'\n'"${patch_content}"$'\n'
      injected=true
    fi
  done <<< "$upstream_content"

  if ! $injected; then
    result+=$'\n'"${patch_content}"
  fi

  result="${result%$'\n'}"
  echo "$result"

  return 0
}

# Append patch content at the end of the file.
# Arguments:
#   $1=[upstream content]
#   $2=[patch content]
# Returns:
#   Patched content (via stdout)
function patch-inject-append() {
  local upstream_content="$1"
  local patch_content="$2"

  echo "${upstream_content}"$'\n'$'\n'"${patch_content}"

  return 0
}

# Prepend patch content at the start of the file.
# Arguments:
#   $1=[upstream content]
#   $2=[patch content]
# Returns:
#   Patched content (via stdout)
function patch-inject-prepend() {
  local upstream_content="$1"
  local patch_content="$2"

  echo "${patch_content}"$'\n'$'\n'"${upstream_content}"

  return 0
}
