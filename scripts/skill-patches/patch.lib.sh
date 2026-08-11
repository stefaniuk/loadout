#!/bin/bash

set -euo pipefail

# Shared helpers for applying local patch fragments to synced or imported
# skill and template files.
#
# Usage:
#   $ source ./patch.lib.sh

# ==============================================================================

# Apply frontmatter field overrides from the manifest to a file on disk.
# Fields set to null in the manifest are removed; all others are set or added.
# Arguments:
#   $1=[path to the target file]
#   $2=[manifest file path]
#   $3=[relative file path key, e.g. find-bugs/SKILL.md]
function patch-apply-frontmatter() {
  local target_file="$1"
  local manifest_file="$2"
  local file_key="$3"

  if ! command -v yq > /dev/null 2>&1 || [[ ! -f "$manifest_file" || ! -f "$target_file" ]]; then
    return 0
  fi

  local has_overrides
  has_overrides=$(yq ".frontmatter.\"${file_key}\" // {} | length" "$manifest_file" 2>/dev/null || echo "0")
  if [[ "$has_overrides" == "0" ]]; then
    return 0
  fi

  local first_line
  first_line=$(head -1 "$target_file")
  if [[ "$first_line" != "---" ]]; then
    return 0
  fi

  local tmp_fm tmp_body tmp_overrides
  tmp_fm=$(mktemp)
  tmp_body=$(mktemp)
  tmp_overrides=$(mktemp)
  touch "$tmp_fm" "$tmp_body"

  awk '
    BEGIN { delim_count = 0; in_body = 0 }
    /^---$/ {
      delim_count++
      if (delim_count == 2) { in_body = 1; next }
      next
    }
    in_body == 0 { print > "'"$tmp_fm"'" }
    in_body == 1 { print > "'"$tmp_body"'" }
  ' "$target_file"

  # Ensure the frontmatter file is valid YAML for yq (empty doc if no content)
  if [[ ! -s "$tmp_fm" ]]; then
    echo "{}" > "$tmp_fm"
  fi

  # Collect keys marked as null (fields to remove)
  local null_keys
  null_keys=$(yq -r ".frontmatter.\"${file_key}\" | to_entries | map(select(.value == null)) | .[].key" "$manifest_file" 2>/dev/null || echo "")

  # Write non-null overrides to a temp file for merging
  yq ".frontmatter.\"${file_key}\" | with_entries(select(.value != null))" "$manifest_file" > "$tmp_overrides" 2>/dev/null

  # Merge overrides into frontmatter
  if [[ -s "$tmp_overrides" ]]; then
    yq -i ". *= load(\"${tmp_overrides}\")" "$tmp_fm"
  fi

  # Delete keys marked as null
  if [[ -n "$null_keys" ]]; then
    while IFS= read -r key; do
      [[ -z "$key" ]] && continue
      yq -i "del(.\"${key}\")" "$tmp_fm"
    done <<< "$null_keys"
  fi

  # Reassemble the file
  {
    echo "---"
    cat "$tmp_fm"
    echo "---"
    cat "$tmp_body"
  } > "$target_file"

  rm -f "$tmp_fm" "$tmp_body" "$tmp_overrides"
  return 0
}

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

# Remove the first exact occurrence of a patch block from upstream content.
# Also trims one blank separator line on either side when present so reinjection
# preserves stable spacing.
# Arguments:
#   $1=[upstream content]
#   $2=[patch content]
# Returns:
#   Upstream content with the first matching patch block removed (via stdout)
function patch-strip-first-existing-content() {
  local upstream_content="$1"
  local patch_content="$2"

  if [[ -z "${patch_content}" ]]; then
    echo "${upstream_content}"
    return 0
  fi

  local -a lines=()
  local -a patch_lines=()
  local line

  while IFS= read -r line || [[ -n "$line" ]]; do
    lines+=("$line")
  done <<< "$upstream_content"

  while IFS= read -r line || [[ -n "$line" ]]; do
    patch_lines+=("$line")
  done <<< "$patch_content"

  local line_count="${#lines[@]}"
  local patch_line_count="${#patch_lines[@]}"

  if (( line_count == 0 || patch_line_count == 0 || patch_line_count > line_count )); then
    echo "${upstream_content}"
    return 0
  fi

  local match_start=-1
  local match_end=-1
  local index=0
  local offset=0

  for ((index=0; index<=line_count-patch_line_count; index++)); do
    local matched=true
    for ((offset=0; offset<patch_line_count; offset++)); do
      if [[ "${lines[$((index + offset))]}" != "${patch_lines[$offset]}" ]]; then
        matched=false
        break
      fi
    done

    if $matched; then
      match_start=$index
      match_end=$((index + patch_line_count - 1))
      break
    fi
  done

  if (( match_start < 0 )); then
    echo "${upstream_content}"
    return 0
  fi

  local remove_start=$match_start
  local remove_end=$match_end

  if (( remove_start > 0 )) && [[ -z "${lines[$((remove_start - 1))]}" ]]; then
    remove_start=$((remove_start - 1))
  fi

  if (( remove_end + 1 < line_count )) && [[ -z "${lines[$((remove_end + 1))]}" ]]; then
    remove_end=$((remove_end + 1))
  fi

  local result=""
  for ((index=0; index<line_count; index++)); do
    if (( index < remove_start || index > remove_end )); then
      result+="${lines[$index]}"$'\n'
    fi
  done

  result="${result%$'\n'}"
  echo "$result"

  return 0
}

# Remove all exact occurrences of a patch block from upstream content before a
# fresh injection pass. This makes repeated patch runs idempotent and also
# normalises files that already contain duplicated injected blocks.
# Arguments:
#   $1=[upstream content]
#   $2=[patch content]
# Returns:
#   Upstream content with all matching patch blocks removed (via stdout)
function patch-strip-existing-content() {
  local upstream_content="$1"
  local patch_content="$2"
  local current_content="$upstream_content"

  while true; do
    local stripped_content
    stripped_content=$(patch-strip-first-existing-content "$current_content" "$patch_content")

    if [[ "$stripped_content" == "$current_content" ]]; then
      break
    fi

    current_content="$stripped_content"
  done

  echo "$current_content"

  return 0
}

# Return success when a patch is already present at the expected
# after-frontmatter location, so reapplying the patch becomes a no-op.
# Arguments:
#   $1=[upstream content]
#   $2=[patch content]
function patch-has-after-frontmatter-injection() {
  local upstream_content="$1"
  local patch_content="$2"

  local -a lines=()
  local -a patch_lines=()
  local line

  while IFS= read -r line || [[ -n "$line" ]]; do
    lines+=("$line")
  done <<< "$upstream_content"

  while IFS= read -r line || [[ -n "$line" ]]; do
    patch_lines+=("$line")
  done <<< "$patch_content"

  local patch_line_count="${#patch_lines[@]}"
  if (( patch_line_count == 0 )); then
    return 1
  fi

  if (( ${#lines[@]} > 0 )) && [[ "${lines[0]}" == "---" ]]; then
    local delimiter_count=0
    local frontmatter_end_index=-1
    local index=0

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
      return 1
    fi

    local patch_start=$((frontmatter_end_index + 2))
    if (( frontmatter_end_index + 1 >= ${#lines[@]} )) || [[ -n "${lines[$((frontmatter_end_index + 1))]}" ]]; then
      return 1
    fi

    if (( patch_start + patch_line_count > ${#lines[@]} )); then
      return 1
    fi

    for ((index=0; index<patch_line_count; index++)); do
      if [[ "${lines[$((patch_start + index))]}" != "${patch_lines[$index]}" ]]; then
        return 1
      fi
    done

    return 0
  fi

  local index=0
  if (( patch_line_count > ${#lines[@]} )); then
    return 1
  fi

  for ((index=0; index<patch_line_count; index++)); do
    if [[ "${lines[$index]}" != "${patch_lines[$index]}" ]]; then
      return 1
    fi
  done

  return 0
}

# Return success when a patch is already present in the exact location implied
# by the injection strategy, making reapplication a no-op.
# Arguments:
#   $1=[upstream content]
#   $2=[patch content]
#   $3=[injection point]
function patch-is-already-applied() {
  local upstream_content="$1"
  local patch_content="$2"
  local injection_point="$3"

  case "$injection_point" in
    after-frontmatter)
      patch-has-after-frontmatter-injection "$upstream_content" "$patch_content"
      return $?
      ;;
    *)
      return 1
      ;;
  esac
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
  local stripped_upstream_content

  if patch-is-already-applied "$upstream_content" "$patch_content" "$injection_point"; then
    echo "$upstream_content"
    return 0
  fi

  stripped_upstream_content=$(patch-strip-existing-content "$upstream_content" "$patch_content")

  case "$injection_point" in
    after-frontmatter)
      patch-inject-after-frontmatter "$stripped_upstream_content" "$patch_content"
      ;;
    replace-before-section:*)
      local section_name="${injection_point#replace-before-section:}"
      patch-inject-replace-before-section "$stripped_upstream_content" "$patch_content" "$section_name"
      ;;
    before-section:*)
      local section_name="${injection_point#before-section:}"
      patch-inject-before-section "$stripped_upstream_content" "$patch_content" "$section_name"
      ;;
    after-section:*)
      local section_name="${injection_point#after-section:}"
      patch-inject-after-section "$stripped_upstream_content" "$patch_content" "$section_name"
      ;;
    append)
      patch-inject-append "$stripped_upstream_content" "$patch_content"
      ;;
    prepend)
      patch-inject-prepend "$stripped_upstream_content" "$patch_content"
      ;;
    *)
      patch-inject-after-frontmatter "$stripped_upstream_content" "$patch_content"
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
