#!/bin/bash

set -euo pipefail

# Fetch upstream spec-kit files and apply local extensions to produce
# patched files in the effective locations.
#
# Usage:
#   $ [options] ./scripts/specify.sh
#
# Options:
#   extensions=false        # Skip local extensions and use vanilla upstream files, default is 'true'
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

EXTENSIONS_DIR="${REPO_ROOT}/.specify/extensions"
MANIFEST_FILE="${EXTENSIONS_DIR}/manifest.yaml"

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

  local extensions=${extensions:-true}

  if is-arg-true "$extensions"; then
    echo "==> Applying local extensions..."
    patch-skills "$TEMP_DIR"
    patch-category "$TEMP_DIR" "" "templates" ".specify/templates" "${TARGET_TEMPLATES}" "*-template.md"
  else
    echo "==> Skipping local extensions (extensions=false)."
    copy-vanilla-skills "$TEMP_DIR"
    patch-category "$TEMP_DIR" "" "templates" ".specify/templates" "${TARGET_TEMPLATES}" "*-template.md"
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

# Patch speckit skill files from upstream with local extensions.
# Arguments:
#   $1=[path to temporary directory]
function patch-skills() {
  local temp_dir="$1"
  local source_dir="${temp_dir}/.github/skills"
  local extensions_dir="${EXTENSIONS_DIR}/copilot/skills"
  local dry_run=${dry_run:-false}

  echo "  [copilot/skills]"

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
    local ext_file="${extensions_dir}/${skill_name}.ext.md"
    local target_dir="${TARGET_SKILLS}/${skill_name}"
    local target_file="${target_dir}/SKILL.md"

    if [[ ! -f "$source_file" ]]; then
      continue
    fi

    if ! is-arg-true "$dry_run"; then
      mkdir -p "$target_dir"
    fi

    if [[ -f "$ext_file" ]]; then
      local injection_point
      injection_point=$(get-injection-point "${skill_name}/SKILL.md" "copilot" "skills")
      echo "    Patching: ${skill_name}/SKILL.md (injection: ${injection_point})"
      if ! is-arg-true "$dry_run"; then
        local upstream_content
        local extension_content
        local patched_content
        upstream_content=$(cat "$source_file")
        extension_content=$(cat "$ext_file")
        patched_content=$(inject-extension "$upstream_content" "$extension_content" "$injection_point")
        echo "$patched_content" > "$target_file"
      fi
    else
      echo "    Copying:  ${skill_name}/SKILL.md (no extension)"
      if ! is-arg-true "$dry_run"; then
        cp "$source_file" "$target_file"
      fi
    fi
  done

  return 0
}

# Copy upstream skill files without applying extensions.
# Arguments:
#   $1=[path to temporary directory]
function copy-vanilla-skills() {
  local temp_dir="$1"
  local source_dir="${temp_dir}/.github/skills"
  local dry_run=${dry_run:-false}

  echo "  [copilot/skills] (vanilla)"

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

# Patch a category of files (commands, agents, prompts, or templates).
# Arguments:
#   $1=[path to temporary directory]
#   $2=[AI tool name: copilot, or empty for shared categories]
#   $3=[category name: agents, prompts, or templates]
#   $4=[source subdirectory within temp dir]
#   $5=[target directory for patched files]
#   $6=[glob pattern for files to process]
function patch-category() {
  local temp_dir="$1"
  local ai_tool="$2"
  local category="$3"
  local source_subdir="$4"
  local target_dir="$5"
  local glob_pattern="$6"

  local source_dir="${temp_dir}/${source_subdir}"
  local extensions_subdir
  if [[ -n "${ai_tool}" ]]; then
    extensions_subdir="${EXTENSIONS_DIR}/${ai_tool}/${category}"
  else
    extensions_subdir="${EXTENSIONS_DIR}/${category}"
  fi
  local dry_run=${dry_run:-false}

  local display_name
  if [[ -n "${ai_tool}" ]]; then
    display_name="${ai_tool}/${category}"
  else
    display_name="${category}"
  fi
  echo "  [${display_name}]"

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
    local ext_file="${extensions_subdir}/${filename%.md}.ext.md"
    local target_file="${target_dir}/${filename}"

    if [[ -f "$ext_file" ]]; then
      patch-file "$file" "$ext_file" "$target_file" "$filename" "$ai_tool" "$category"
    else
      copy-file "$file" "$target_file" "$filename"
    fi
  done

  return 0
}

# Patch a single file by injecting the extension at the configured location.
# Arguments:
#   $1=[path to upstream file]
#   $2=[path to extension file]
#   $3=[path to target file]
#   $4=[filename for display]
#   $5=[AI tool name: copilot, or empty for shared categories]
#   $6=[category name: agents, prompts, or templates]
function patch-file() {
  local upstream_file="$1"
  local ext_file="$2"
  local target_file="$3"
  local filename="$4"
  local ai_tool="$5"
  local category="$6"

  local dry_run=${dry_run:-false}
  local injection_point

  injection_point=$(get-injection-point "$filename" "$ai_tool" "$category")

  echo "    Patching: ${filename} (injection: ${injection_point})"

  if is-arg-true "$dry_run"; then
    echo "      Would inject extension from: ${ext_file}"
    return 0
  fi

  local upstream_content
  local extension_content
  local patched_content

  upstream_content=$(cat "$upstream_file")
  extension_content=$(cat "$ext_file")

  # Inject extension at the configured location
  patched_content=$(inject-extension "$upstream_content" "$extension_content" "$injection_point")

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

  echo "    Copying:  ${filename} (no extension)"

  if is-arg-true "$dry_run"; then
    return 0
  fi

  cp "$source_file" "$target_file"

  return 0
}

# Get the injection point for a file from the manifest.
# Arguments:
#   $1=[filename]
#   $2=[AI tool name: copilot, or empty for shared categories]
#   $3=[category name: agents, prompts, or templates]
# Returns:
#   Injection point string (via stdout)
function get-injection-point() {
  local filename="$1"
  local ai_tool="$2"
  local category="$3"
  local default_injection

  default_injection=$(get-default-injection-point "$ai_tool" "$category")

  # Try to read from manifest if yq is available
  if command -v yq > /dev/null 2>&1 && [[ -f "$MANIFEST_FILE" ]]; then
    local override
    override=$(yq -r ".overrides.\"${filename}\" // empty" "$MANIFEST_FILE" 2>/dev/null || echo "")
    if [[ -n "$override" ]]; then
      echo "$override"
      return 0
    fi

    # Query category default from manifest using AI tool prefix
    local category_default=""
    if [[ -n "${ai_tool}" ]]; then
      category_default=$(yq -r ".defaults.\"${ai_tool}\".\"${category}\" // empty" "$MANIFEST_FILE" 2>/dev/null || echo "")
    else
      category_default=$(yq -r ".defaults.\"${category}\" // empty" "$MANIFEST_FILE" 2>/dev/null || echo "")
    fi

    if [[ -n "$category_default" ]]; then
      echo "$category_default"
      return 0
    fi
  fi

  echo "$default_injection"
  return 0
}

# Get the built-in default injection point for a category.
# Arguments:
#   $1=[AI tool name: copilot, or empty for shared categories]
#   $2=[category name: skills, templates, or other manifest category]
# Returns:
#   Default injection point string (via stdout)
function get-default-injection-point() {
  local ai_tool="$1"
  local category="$2"

  if [[ "$ai_tool" == "copilot" ]] && [[ "$category" == "skills" ]]; then
    echo "replace-before-section:## User Input"
  else
    echo "after-frontmatter"
  fi

  return 0
}

# Inject extension content into upstream content at the specified location.
# Arguments:
#   $1=[upstream content]
#   $2=[extension content]
#   $3=[injection point]
# Returns:
#   Patched content (via stdout)
function inject-extension() {
  local upstream_content="$1"
  local extension_content="$2"
  local injection_point="$3"

  case "$injection_point" in
    after-frontmatter)
      inject-after-frontmatter "$upstream_content" "$extension_content"
      ;;
    replace-before-section:*)
      local section_name="${injection_point#replace-before-section:}"
      inject-replace-before-section "$upstream_content" "$extension_content" "$section_name"
      ;;
    before-section:*)
      local section_name="${injection_point#before-section:}"
      inject-before-section "$upstream_content" "$extension_content" "$section_name"
      ;;
    after-section:*)
      local section_name="${injection_point#after-section:}"
      inject-after-section "$upstream_content" "$extension_content" "$section_name"
      ;;
    append)
      inject-append "$upstream_content" "$extension_content"
      ;;
    prepend)
      inject-prepend "$upstream_content" "$extension_content"
      ;;
    *)
      # Default to after-frontmatter
      inject-after-frontmatter "$upstream_content" "$extension_content"
      ;;
  esac

  return 0
}

# Replace the content after front matter up to a specific section heading.
# If the section heading is not found, the remaining upstream content is kept.
# Arguments:
#   $1=[upstream content]
#   $2=[extension content]
#   $3=[section heading to keep from upstream]
# Returns:
#   Patched content (via stdout)
function inject-replace-before-section() {
  local upstream_content="$1"
  local extension_content="$2"
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
    result+=$'\n'"${extension_content}"$'\n'
    content_start_index=$((frontmatter_end_index + 1))
  else
    result+="${extension_content}"$'\n'
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

# Inject extension after YAML front matter (after the closing ---).
# Arguments:
#   $1=[upstream content]
#   $2=[extension content]
# Returns:
#   Patched content (via stdout)
function inject-after-frontmatter() {
  local upstream_content="$1"
  local extension_content="$2"

  # Check if content starts with front matter delimiter
  if [[ "$upstream_content" =~ ^(\`\`\`[a-z]*$'\n')?--- ]]; then
    # Find the closing --- and inject after it
    local in_frontmatter=false
    local frontmatter_closed=false
    local code_fence=""
    local result=""

    while IFS= read -r line || [[ -n "$line" ]]; do
      result+="${line}"$'\n'

      # Handle code fence at start (```chatagent or ```prompt)
      if [[ -z "$code_fence" ]] && [[ "$line" =~ ^\`\`\`[a-z]+ ]]; then
        code_fence="$line"
        continue
      fi

      # Track front matter state
      if [[ "$line" == "---" ]]; then
        if ! $in_frontmatter; then
          in_frontmatter=true
        else
          # This is the closing ---
          if ! $frontmatter_closed; then
            frontmatter_closed=true
            result+=$'\n'"${extension_content}"$'\n'
          fi
        fi
      fi
    done <<< "$upstream_content"

    # Remove trailing newline added by loop
    result="${result%$'\n'}"
    echo "$result"
  else
    # No front matter, prepend extension
    echo "${extension_content}"$'\n'$'\n'"${upstream_content}"
  fi

  return 0
}

# Inject extension before a specific section heading.
# Arguments:
#   $1=[upstream content]
#   $2=[extension content]
#   $3=[section heading to find]
# Returns:
#   Patched content (via stdout)
function inject-before-section() {
  local upstream_content="$1"
  local extension_content="$2"
  local section_name="$3"

  local injected=false
  local result=""

  while IFS= read -r line || [[ -n "$line" ]]; do
    if ! $injected && [[ "$line" == "$section_name"* ]]; then
      result+="${extension_content}"$'\n'$'\n'
      injected=true
    fi
    result+="${line}"$'\n'
  done <<< "$upstream_content"

  # If section not found, append at end
  if ! $injected; then
    result+=$'\n'"${extension_content}"
  fi

  # Remove trailing newline
  result="${result%$'\n'}"
  echo "$result"

  return 0
}

# Inject extension after a specific section heading (and its first paragraph).
# Arguments:
#   $1=[upstream content]
#   $2=[extension content]
#   $3=[section heading to find]
# Returns:
#   Patched content (via stdout)
function inject-after-section() {
  local upstream_content="$1"
  local extension_content="$2"
  local section_name="$3"

  local found_section=false
  local injected=false
  local result=""

  while IFS= read -r line || [[ -n "$line" ]]; do
    result+="${line}"$'\n'

    if ! $injected && [[ "$line" == "$section_name"* ]]; then
      found_section=true
    elif $found_section && ! $injected; then
      # Inject after the section heading line
      result+=$'\n'"${extension_content}"$'\n'
      injected=true
    fi
  done <<< "$upstream_content"

  # If section not found, append at end
  if ! $injected; then
    result+=$'\n'"${extension_content}"
  fi

  # Remove trailing newline
  result="${result%$'\n'}"
  echo "$result"

  return 0
}

# Append extension at the end of the file.
# Arguments:
#   $1=[upstream content]
#   $2=[extension content]
# Returns:
#   Patched content (via stdout)
function inject-append() {
  local upstream_content="$1"
  local extension_content="$2"

  echo "${upstream_content}"$'\n'$'\n'"${extension_content}"

  return 0
}

# Prepend extension at the start of the file.
# Arguments:
#   $1=[upstream content]
#   $2=[extension content]
# Returns:
#   Patched content (via stdout)
function inject-prepend() {
  local upstream_content="$1"
  local extension_content="$2"

  echo "${extension_content}"$'\n'$'\n'"${upstream_content}"

  return 0
}

# ==============================================================================

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
