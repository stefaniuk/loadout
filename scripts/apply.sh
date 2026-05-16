#!/bin/bash

set -euo pipefail

# Copy prompt files assets to a destination repository.
#
# Usage:
#   $ [options] ./scripts/apply.sh <destination-directory>
#
# Arguments:
#   destination-directory   Target directory (absolute or relative path)
#
# Options:
#   clean=true              # Remove destination .github/{agents,instructions,prompts,skills} before copying, default is 'false'
#   revert=true             # Remove all promptfiles-managed artifacts from destination and exit, default is 'false'
#   VERBOSE=true            # Show all the executed commands, default is 'false'
#
# Technology switches (default is 'false' for all, set to 'true' to include):
#   all=true                # Include all technology-specific files
#   python=true             # Include Python instruction and enforcement prompt
#   typescript=true         # Include TypeScript instruction and enforcement prompt
#   go=true                 # Include Go instruction and enforcement prompt
#   reactjs=true            # Include ReactJS instruction and enforcement prompt
#   rust=true               # Include Rust instruction and enforcement prompt
#   terraform=true          # Include Terraform instruction and enforcement prompt
#   tauri=true              # Include Tauri instruction and enforcement prompt (auto-enables rust, typescript, reactjs)
#   playwright=true         # Include Playwright instruction and prompt (requires python or typescript)
#   django=true             # Include Django skill (auto-enables python)
#   fastapi=true            # Include FastAPI skill (auto-enables python)
#
# Always copied (default/glue layer):
#   - All spec-kit agents (.github/agents)
#   - Shell, Docker, Makefile instructions and prompts
#   - Development prompts (dev.implement-*)
#   - Architecture documentation prompts (architecture.*)
#   - Spec-kit prompts (speckit.*, review.speckit-*)
#   - Utility prompts (util.*)
#   - Shared includes (baselines)
#   - Default templates (Makefile, Dockerfile, compose.yaml, shell-script)
#   - Default skills: repository-template, enforcement-audit, architecture-docs, code-review
#   - copilot-instructions.md
#   - AGENTS.md (cross-agent baseline at destination root)
#   - .github/hooks/ (Copilot agent hooks, e.g. quality-gates.json)
#   - scripts/hooks/ (hook executables, e.g. post-edit-lint.sh, stop-gate.sh; chmod +x)
#   - pull_request_template.md (if not already present)
#   - constitution.md
#   - .specify/scripts/bash
#   - .specify/templates
#   - ADR-nnn_Any_Decision_Record_Template.md
#   - Tech_Radar.md
#   - docs/architecture/
#   - docs/prompts/
#   - project.code-workspace (if not already present)
#   - .gitignore content (managed section with begin/end markers)
#
# Exit codes:
#   0 - All files copied successfully
#   1 - Missing or invalid arguments
#
# Examples:
#   $ ./scripts/apply.sh /path/to/my-project
#   $ python=true ./scripts/apply.sh ../my-project
#   $ all=true ./scripts/apply.sh ~/projects/my-app
#   $ python=true playwright=true ./scripts/apply.sh ~/projects/my-app
#   $ django=true ./scripts/apply.sh ~/projects/my-app  # auto-enables python
#   $ revert=true ./scripts/apply.sh ~/projects/my-app  # remove all managed artifacts

# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

COPILOT_AGENTS_DIR="${REPO_ROOT}/.github/agents"
COPILOT_HOOKS_DIR="${REPO_ROOT}/.github/hooks"
COPILOT_INSTRUCTIONS_DIR="${REPO_ROOT}/.github/instructions"
COPILOT_PROMPTS_DIR="${REPO_ROOT}/.github/prompts"
COPILOT_SKILLS_DIR="${REPO_ROOT}/.github/skills"
COPILOT_INSTRUCTIONS_MD_FILE="${REPO_ROOT}/.github/copilot-instructions.md"
AGENTS_MD_FILE="${REPO_ROOT}/AGENTS.md"
HOOK_SCRIPTS_DIR="${REPO_ROOT}/scripts/hooks"

SPECIFY_MEMORY="${REPO_ROOT}/.specify/memory"
SPECIFY_SCRIPTS_BASH="${REPO_ROOT}/.specify/scripts/bash"
SPECIFY_TEMPLATES="${REPO_ROOT}/.specify/templates"

PULL_REQUEST_TEMPLATE="${REPO_ROOT}/.github/pull_request_template.md"
ADR_TEMPLATE="${REPO_ROOT}/docs/adr/ADR-nnn_Any_Decision_Record_Template.md"
ADR_TECH_RADAR="${REPO_ROOT}/docs/adr/Tech_Radar.md"
DOCS_ARCHITECTURE="${REPO_ROOT}/docs/architecture"
DOCS_PROMPTS="${REPO_ROOT}/docs/prompts"
WORKSPACE_FILE="${REPO_ROOT}/project.code-workspace"
GITIGNORE_PROMPTFILES="${REPO_ROOT}/.gitignore.promptfiles"

# Begin/end markers for managed .gitignore content
GITIGNORE_BEGIN_MARKER="# >>> promptfiles-copilot managed content - DO NOT EDIT BELOW THIS LINE >>>"
GITIGNORE_END_MARKER="# <<< promptfiles-copilot managed content - DO NOT EDIT ABOVE THIS LINE <<<"

# Default instruction files (glue layer)
DEFAULT_INSTRUCTIONS=("docker" "makefile" "readme" "shell")

# Default prompt patterns (glue layer and spec-kit)
DEFAULT_PROMPT_PATTERNS=("architecture.*" "dev.implement-*" "enforce.docker" "enforce.makefile" "enforce.shell" "review.speckit-*" "speckit.*" "util.*")

# Default templates (glue layer)
DEFAULT_TEMPLATES=("Makefile.template" "Dockerfile.template" "compose.yaml.template" "shell-script.template.sh")

# Default skills
DEFAULT_SKILLS=("repository-template" "enforcement-audit" "architecture-docs" "code-review")

# All technology switches (for iteration)
ALL_TECHS=("python" "typescript" "go" "reactjs" "rust" "terraform" "tauri" "playwright" "django" "fastapi")

# ==============================================================================

# Main entry point for the script.
function main() {

  if [[ $# -ne 1 ]]; then
    print-usage
    exit 1
  fi

  # Validate destination argument
  if [[ -z "$1" ]]; then
    print-error "Destination directory cannot be empty."
  fi

  # Auto-enable rust, typescript, and reactjs if tauri is specified
  # shellcheck disable=SC2034
  if is-arg-true "${tauri:-false}"; then
    rust=true
    typescript=true
    reactjs=true
  fi

  # Auto-enable python if django or fastapi is specified
  if is-arg-true "${django:-false}" || is-arg-true "${fastapi:-false}"; then
    python=true
  fi

  # Validate playwright requires python or typescript (unless all=true)
  if is-arg-true "${playwright:-false}" && ! is-arg-true "${all:-false}"; then
    if ! is-arg-true "${python:-false}" && ! is-arg-true "${typescript:-false}"; then
      print-error "playwright=true requires either python=true or typescript=true to be set"
    fi
  fi

  local destination
  destination=$(normalise-destination-path "$1")

  # Create destination if it doesn't exist
  if [[ ! -d "${destination}" ]]; then
    print-info "Creating destination directory: ${destination}"
    mkdir -p "${destination}"
  fi

  echo "Applying prompt files to: ${destination}"
  print-enabled-technologies
  echo

  if is-arg-true "${revert:-false}"; then
    revert-promptfiles "${destination}"
    echo
    echo "Done. Promptfiles artifacts reverted from ${destination}"
    return 0
  fi

  copilot-apply "${destination}"

  echo
  echo "Done. Assets copied to ${destination}"
}

# ==============================================================================

# Normalise a destination path passed via make or the shell.
# Converts common escaped spaces to literal spaces, expands a leading home
# directory marker, and resolves relative paths against the current directory.
# Arguments:
#   $1=[destination directory path]
function normalise-destination-path() {

  local destination="$1"

  destination="${destination//\\ / }"

  if [[ "${destination}" == \~ ]]; then
    destination="${HOME}"
  elif [[ "${destination:0:2}" == \~/* ]]; then
    destination="${HOME}/${destination:2}"
  fi

  if [[ "${destination}" != /* ]]; then
    local destination_dir
    local destination_dir_abs
    destination_dir="$(dirname "${destination}")"
    if destination_dir_abs=$(cd "$(pwd)" && cd "${destination_dir}" 2>/dev/null && pwd); then
      destination="${destination_dir_abs}/$(basename "${destination}")"
    else
      destination="$(pwd)/${destination}"
    fi
  fi

  printf '%s\n' "${destination}"

  return 0
}

# ==============================================================================

# Get instruction file name for a technology.
# For playwright, returns the appropriate variant based on python/typescript being enabled.
# Arguments:
#   $1=[technology name]
function get-tech-instruction() {

  case "$1" in
    python) echo "python" ;;
    typescript) echo "typescript" ;;
    go) echo "go" ;;
    reactjs) echo "reactjs" ;;
    rust) echo "rust" ;;
    terraform) echo "terraform" ;;
    tauri) echo "tauri" ;;
    playwright)
      # Return both variants if applicable
      local result=""
      if is-arg-true "${python:-false}" || is-arg-true "${all:-false}"; then
        result="playwright-python"
      fi
      if is-arg-true "${typescript:-false}" || is-arg-true "${all:-false}"; then
        [[ -n "${result}" ]] && result="${result} "
        result="${result}playwright-typescript"
      fi
      echo "${result}"
      ;;
    *) echo "" ;;
  esac
}

# Get prompt file name for a technology.
# For playwright, returns the appropriate variant based on python/typescript being enabled.
# Arguments:
#   $1=[technology name]
function get-tech-prompt() {

  case "$1" in
    python) echo "enforce.python" ;;
    typescript) echo "enforce.typescript" ;;
    go) echo "enforce.go" ;;
    reactjs) echo "enforce.reactjs" ;;
    rust) echo "enforce.rust" ;;
    terraform) echo "enforce.terraform" ;;
    tauri) echo "enforce.tauri" ;;
    playwright)
      # Return both variants if applicable
      local result=""
      if is-arg-true "${python:-false}" || is-arg-true "${all:-false}"; then
        result="enforce.playwright-python"
      fi
      if is-arg-true "${typescript:-false}" || is-arg-true "${all:-false}"; then
        [[ -n "${result}" ]] && result="${result} "
        result="${result}enforce.playwright-typescript"
      fi
      echo "${result}"
      ;;
    *) echo "" ;;
  esac
}

# Get template file name for a technology.
# Arguments:
#   $1=[technology name]
function get-tech-template() {

  case "$1" in
    python) echo "pyproject.toml" ;;
    *) echo "" ;;
  esac
}

# Get skill directory name for a technology.
# Arguments:
#   $1=[technology name]
function get-tech-skill() {

  case "$1" in
    django) echo "django-project" ;;
    fastapi) echo "fastapi-project" ;;
    *) echo "" ;;
  esac
}

# ==============================================================================

# Apply copilot-specific assets to the destination.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function copilot-apply() {

  local destination="$1"

  if is-arg-true "${clean:-false}"; then
    copilot-clean-directories "${destination}"
  fi
  copilot-copy-agents "${destination}"
  copilot-copy-hooks "${destination}"
  copilot-copy-instructions "${destination}"
  copilot-copy-prompts "${destination}"
  copilot-copy-skills "${destination}"
  copilot-copy-instructions-md "${destination}"
  copy-shared-resources "${destination}"
  update-vscode-settings "${destination}"

  return 0
}

# Copy shared resources common to all AI tools.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function copy-shared-resources() {

  local destination="$1"

  copy-specify-memory "${destination}"
  copy-specify-scripts-bash "${destination}"
  copy-specify-templates "${destination}"
  copy-pull-request-template "${destination}"
  copy-adr-template "${destination}"
  copy-docs-architecture "${destination}"
  copy-docs-prompts "${destination}"
  copy-workspace-file "${destination}"
  copy-agents-md "${destination}"
  copy-hook-scripts "${destination}"
  update-gitignore "${destination}"

  return 0
}

# ==============================================================================

# Print which technologies are enabled.
function print-enabled-technologies() {

  local techs=()

  if is-arg-true "${all:-false}"; then
    techs+=("all")
  else
    for tech in "${ALL_TECHS[@]}"; do
      local var_value
      eval "var_value=\${${tech}:-false}"
      if is-arg-true "${var_value}"; then
        techs+=("${tech}")
      fi
    done
  fi

  if [[ ${#techs[@]} -eq 0 ]]; then
    echo "Technologies: default only (use all=true or individual switches to include more)"
  else
    echo "Technologies: default + ${techs[*]}"
  fi
}

# Check if a technology is enabled.
# Arguments:
#   $1=[technology name]
function is-tech-enabled() {

  local tech="$1"

  if is-arg-true "${all:-false}"; then
    return 0
  fi

  # Use indirect variable reference with default value
  local var_value
  eval "var_value=\${${tech}:-false}"
  if is-arg-true "${var_value}"; then
    return 0
  fi

  return 1
}

# Clean copilot target directories before copying.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function copilot-clean-directories() {

  local dest="$1/.github"
  local dirs=("agents" "hooks" "instructions" "prompts" "skills")

  for dir in "${dirs[@]}"; do
    if [[ -d "${dest}/${dir}" ]]; then
      print-info "Removing ${dest}/${dir}"
      rm -rf "${dest:?}/${dir}"
    fi
  done

  return 0
}

# Remove all promptfiles-managed artifacts from the destination.
# This undoes what a previous apply has done.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function revert-promptfiles() {

  local dest="$1"

  echo "Reverting prompt files from: ${dest}"
  echo

  revert-copilot "${dest}"
  revert-shared-resources "${dest}"

  return 0
}

# Remove copilot-specific promptfiles-managed artifacts from the destination.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function revert-copilot() {

  local dest="$1"

  # Remove .github directories
  local github_dirs=("agents" "hooks" "instructions" "prompts" "skills")
  for dir in "${github_dirs[@]}"; do
    if [[ -d "${dest}/.github/${dir}" ]]; then
      print-info "Removing ${dest}/.github/${dir}"
      rm -rf "${dest:?}/.github/${dir}"
    fi
  done

  # Remove copilot-instructions.md
  if [[ -f "${dest}/.github/copilot-instructions.md" ]]; then
    print-info "Removing ${dest}/.github/copilot-instructions.md"
    rm -f "${dest}/.github/copilot-instructions.md"
  fi

  # Remove AGENTS.md
  if [[ -f "${dest}/AGENTS.md" ]]; then
    print-info "Removing ${dest}/AGENTS.md"
    rm -f "${dest}/AGENTS.md"
  fi

  # Remove hook scripts (scripts/hooks/ is fully managed by promptfiles;
  # any user-authored files placed there will be removed on revert)
  if [[ -d "${dest}/scripts/hooks" ]]; then
    print-info "Removing ${dest}/scripts/hooks"
    rm -rf "${dest:?}/scripts/hooks"
  fi

  return 0
}

# Remove shared promptfiles-managed artifacts from the destination.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function revert-shared-resources() {

  local dest="$1"

  # Remove .specify directory
  if [[ -d "${dest}/.specify" ]]; then
    print-info "Removing ${dest}/.specify"
    rm -rf "${dest:?}/.specify"
  fi

  # Remove ADR template files
  local adr_files=("ADR-nnn_Any_Decision_Record_Template.md" "Tech_Radar.md")
  for file in "${adr_files[@]}"; do
    if [[ -f "${dest}/docs/adr/${file}" ]]; then
      print-info "Removing ${dest}/docs/adr/${file}"
      rm -f "${dest}/docs/adr/${file}"
    fi
  done

  # Remove docs/architecture directory if empty or only contains .gitkeep
  if [[ -d "${dest}/docs/architecture" ]]; then
    local arch_contents
    arch_contents=$(ls -A "${dest}/docs/architecture" 2>/dev/null)
    if [[ -z "${arch_contents}" ]] || [[ "${arch_contents}" == ".gitkeep" ]]; then
      print-info "Removing ${dest}/docs/architecture"
      rm -rf "${dest:?}/docs/architecture"
    fi
  fi

  # Remove docs/prompts directory
  if [[ -d "${dest}/docs/prompts" ]]; then
    print-info "Removing ${dest}/docs/prompts"
    rm -rf "${dest:?}/docs/prompts"
  fi

  # Remove managed VS Code settings properties
  if [[ -f "${dest}/.vscode/settings.json" ]]; then
    print-info "Removing promptfiles properties from VS Code settings"
    remove-vscode-json-property "${dest}/.vscode/settings.json" "chat.promptFilesRecommendations"
    remove-vscode-json-property "${dest}/.vscode/settings.json" "chat.tools.terminal.autoApprove"
  fi

  # Remove managed .gitignore section
  if [[ -f "${dest}/.gitignore" ]] && grep -qF "${GITIGNORE_BEGIN_MARKER}" "${dest}/.gitignore"; then
    print-info "Removing promptfiles managed content from .gitignore"
    local temp_file
    temp_file=$(mktemp)
    awk -v begin="${GITIGNORE_BEGIN_MARKER}" -v end="${GITIGNORE_END_MARKER}" '
      $0 == begin { skip = 1; next }
      $0 == end { skip = 0; next }
      !skip { print }
    ' "${dest}/.gitignore" > "${temp_file}"
    # Remove trailing blank lines
    sed -i '' -e :a -e '/^\n*$/{$d;N;ba' -e '}' "${temp_file}" 2>/dev/null || sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "${temp_file}"
    if [[ -s "${temp_file}" ]]; then
      mv "${temp_file}" "${dest}/.gitignore"
    else
      rm -f "${temp_file}" "${dest}/.gitignore"
      print-info "Removed empty .gitignore"
    fi
  fi

  # Clean up empty parent directories
  for dir in "${dest}/.github" "${dest}/docs/adr" "${dest}/docs" "${dest}/.vscode" "${dest}/scripts"; do
    if [[ -d "${dir}" ]] && [[ -z "$(ls -A "${dir}" 2>/dev/null)" ]]; then
      print-info "Removing empty directory ${dir}"
      rmdir "${dir}"
    fi
  done

  return 0
}

# Copy copilot agent files to the destination.
# All agents are spec-kit related and always copied.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function copilot-copy-agents() {

  local dest_agents="$1/.github/agents"
  mkdir -p "${dest_agents}"

  print-info "Copying agent files to ${dest_agents}"
  find "${COPILOT_AGENTS_DIR}" -maxdepth 1 -name "*.md" -type f -exec cp {} "${dest_agents}/" \;
}

# Copy copilot instruction files to the destination.
# Copies default instructions always, technology-specific ones based on switches.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function copilot-copy-instructions() {

  local dest_instructions="$1/.github/instructions"
  mkdir -p "${dest_instructions}"

  print-info "Copying instruction files to ${dest_instructions}"

  # Copy default instruction files
  for instruction in "${DEFAULT_INSTRUCTIONS[@]}"; do
    local file="${COPILOT_INSTRUCTIONS_DIR}/${instruction}.instructions.md"
    if [[ -f "${file}" ]]; then
      cp "${file}" "${dest_instructions}/"
    fi
  done

  # Copy technology-specific instruction files
  for tech in "${ALL_TECHS[@]}"; do
    if is-tech-enabled "${tech}"; then
      local instructions
      instructions=$(get-tech-instruction "${tech}")
      if [[ -n "${instructions}" ]]; then
        # Handle space-separated list (for playwright)
        for instruction in ${instructions}; do
          local file="${COPILOT_INSTRUCTIONS_DIR}/${instruction}.instructions.md"
          if [[ -f "${file}" ]]; then
            cp "${file}" "${dest_instructions}/"
          fi
        done
      fi
    fi
  done

  # Copy includes directory (always - shared baselines)
  if [[ -d "${COPILOT_INSTRUCTIONS_DIR}/includes" ]]; then
    mkdir -p "${dest_instructions}/includes"
    cp -R "${COPILOT_INSTRUCTIONS_DIR}/includes/." "${dest_instructions}/includes/"
  fi

  # Copy templates directory (selective)
  if [[ -d "${COPILOT_INSTRUCTIONS_DIR}/templates" ]]; then
    mkdir -p "${dest_instructions}/templates"

    # Copy default templates
    for template in "${DEFAULT_TEMPLATES[@]}"; do
      local file="${COPILOT_INSTRUCTIONS_DIR}/templates/${template}"
      if [[ -f "${file}" ]]; then
        cp "${file}" "${dest_instructions}/templates/"
      fi
    done

    # Copy technology-specific templates
    for tech in "${ALL_TECHS[@]}"; do
      if is-tech-enabled "${tech}"; then
        local template
        template=$(get-tech-template "${tech}")
        if [[ -n "${template}" ]]; then
          local file="${COPILOT_INSTRUCTIONS_DIR}/templates/${template}"
          if [[ -f "${file}" ]]; then
            cp "${file}" "${dest_instructions}/templates/"
          fi
        fi
      fi
    done
  fi
}

# Copy copilot prompt files to the destination.
# Copies default prompts always, technology-specific ones based on switches.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function copilot-copy-prompts() {

  local dest_prompts="$1/.github/prompts"
  mkdir -p "${dest_prompts}"

  print-info "Copying prompt files to ${dest_prompts}"

  # Copy default prompt files using patterns
  for pattern in "${DEFAULT_PROMPT_PATTERNS[@]}"; do
    # Use find with -name to match patterns
    find "${COPILOT_PROMPTS_DIR}" -maxdepth 1 -name "${pattern}.prompt.md" -type f -exec cp {} "${dest_prompts}/" \; 2>/dev/null || true
  done

  # Copy technology-specific prompt files
  for tech in "${ALL_TECHS[@]}"; do
    if is-tech-enabled "${tech}"; then
      local prompts
      prompts=$(get-tech-prompt "${tech}")
      if [[ -n "${prompts}" ]]; then
        # Handle space-separated list (for playwright)
        for prompt in ${prompts}; do
          local file="${COPILOT_PROMPTS_DIR}/${prompt}.prompt.md"
          if [[ -f "${file}" ]]; then
            cp "${file}" "${dest_prompts}/"
          fi
        done
      fi
    fi
  done
}

# Copy copilot skills files to the destination.
# Copies default skills always, technology-specific ones based on switches.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function copilot-copy-skills() {

  local dest_skills="$1/.github/skills"
  mkdir -p "${dest_skills}"

  print-info "Copying skills files to ${dest_skills}"

  # Copy default skills
  for skill in "${DEFAULT_SKILLS[@]}"; do
    local skill_dir="${COPILOT_SKILLS_DIR}/${skill}"
    if [[ -d "${skill_dir}" ]]; then
      copy-directory-excluding-git "${skill_dir}" "${dest_skills}/${skill}"
    fi
  done

  # Copy technology-specific skills
  for tech in "${ALL_TECHS[@]}"; do
    if is-tech-enabled "${tech}"; then
      local skill
      skill=$(get-tech-skill "${tech}")
      if [[ -n "${skill}" ]]; then
        local skill_dir="${COPILOT_SKILLS_DIR}/${skill}"
        if [[ -d "${skill_dir}" ]]; then
          copy-directory-excluding-git "${skill_dir}" "${dest_skills}/${skill}"
        fi
      fi
    fi
  done
}

# Copy copilot-instructions.md to the destination.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function copilot-copy-instructions-md() {

  local dest="$1/.github"
  mkdir -p "${dest}"

  print-info "Copying copilot-instructions.md to ${dest}"
  cp "${COPILOT_INSTRUCTIONS_MD_FILE}" "${dest}/"
}

# Copy .github/hooks/ to the destination.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function copilot-copy-hooks() {

  local dest="$1/.github/hooks"
  mkdir -p "${dest}"

  print-info "Copying hooks to ${dest}"
  local hooks=()
  shopt -s nullglob
  hooks=("${COPILOT_HOOKS_DIR}"/*.json)
  shopt -u nullglob
  if (( ${#hooks[@]} == 0 )); then
    print-info "No hook configuration files to copy"
    return 0
  fi
  cp "${hooks[@]}" "${dest}/"
}

# Copy AGENTS.md to the destination root.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function copy-agents-md() {

  local dest="$1"
  mkdir -p "${dest}"

  print-info "Copying AGENTS.md to ${dest}"
  cp "${AGENTS_MD_FILE}" "${dest}/"
}

# Copy scripts/hooks/ to the destination.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function copy-hook-scripts() {

  local dest="$1/scripts/hooks"
  mkdir -p "${dest}"

  print-info "Copying hook scripts to ${dest}"
  local scripts=()
  shopt -s nullglob
  scripts=("${HOOK_SCRIPTS_DIR}"/*.sh)
  shopt -u nullglob
  if (( ${#scripts[@]} == 0 )); then
    print-info "No hook scripts to copy"
    return 0
  fi
  cp "${scripts[@]}" "${dest}/"
  chmod +x "${dest}"/*.sh
}

# Copy pull_request_template.md to the destination if missing.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function copy-pull-request-template() {

  local dest_file="$1/.github/pull_request_template.md"
  mkdir -p "$(dirname "${dest_file}")"

  if [[ -f "${dest_file}" ]]; then
    print-info "Skipping pull_request_template.md (already exists)"
  else
    print-info "Copying pull_request_template.md to ${dest_file}"
    cp "${PULL_REQUEST_TEMPLATE}" "${dest_file}"
  fi
}

# Copy .specify/memory directory to the destination.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function copy-specify-memory() {

  local dest="$1/.specify/memory"
  mkdir -p "${dest}"

  print-info "Copying .specify/memory to ${dest}"
  cp -R "${SPECIFY_MEMORY}/." "${dest}/"

  return 0
}

# Copy .specify/scripts/bash directory to the destination.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function copy-specify-scripts-bash() {

  local dest="$1/.specify/scripts/bash"
  mkdir -p "${dest}"

  print-info "Copying .specify/scripts/bash to ${dest}"
  cp -R "${SPECIFY_SCRIPTS_BASH}/". "${dest}/"
}

# Copy .specify/templates directory to the destination.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function copy-specify-templates() {

  local dest="$1/.specify/templates"
  mkdir -p "${dest}"

  print-info "Copying .specify/templates to ${dest}"
  cp -R "${SPECIFY_TEMPLATES}/". "${dest}/"
}

# Copy ADR template files to the destination.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function copy-adr-template() {

  local dest="$1/docs/adr"
  mkdir -p "${dest}"

  print-info "Copying ADR template files to ${dest}"
  cp "${ADR_TEMPLATE}" "${dest}/"
  cp "${ADR_TECH_RADAR}" "${dest}/"

  return 0
}

# Copy docs/architecture directory to the destination.
# Only copies .gitkeep if the destination directory is empty or doesn't exist.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function copy-docs-architecture() {

  local dest="$1/docs/architecture"
  mkdir -p "${dest}"

  print-info "Copying docs/architecture to ${dest}"

  # Check if destination directory has any files (excluding hidden files that start with .)
  local file_count
  file_count=$(find "${dest}" -maxdepth 1 -type f ! -name ".*" 2>/dev/null | wc -l | tr -d ' ')

  if [[ "${file_count}" -eq 0 ]]; then
    # Directory is empty, copy everything including .gitkeep
    cp -R "${DOCS_ARCHITECTURE}/." "${dest}/"
  else
    # Directory has files, copy everything except .gitkeep
    find "${DOCS_ARCHITECTURE}" -maxdepth 1 -type f ! -name ".gitkeep" -exec cp {} "${dest}/" \; 2>/dev/null || true
  fi
}

# Copy docs/prompts directory to the destination.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function copy-docs-prompts() {

  local dest="$1/docs"
  mkdir -p "${dest}/prompts"

  print-info "Copying docs/prompts to ${dest}/prompts"
  cp -R "${DOCS_PROMPTS}/." "${dest}/prompts/"
}

# Copy project.code-workspace to the destination if it does not already exist.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function copy-workspace-file() {

  local dest_file="$1/project.code-workspace"

  if [[ -f "${dest_file}" ]]; then
    print-info "Skipping project.code-workspace (already exists)"
  else
    print-info "Copying project.code-workspace to $1"
    cp "${WORKSPACE_FILE}" "$1/"
  fi
}

# Update .gitignore with promptfiles managed content.
# Creates .gitignore if it doesn't exist, or updates the managed section if it does.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function update-gitignore() {

  local dest_gitignore="$1/.gitignore"
  local source_content
  source_content=$(cat "${GITIGNORE_PROMPTFILES}")

  if [[ ! -f "${dest_gitignore}" ]]; then
    # No .gitignore exists, create it with markers and content
    print-info "Creating .gitignore with promptfiles managed content"
    {
      echo "${GITIGNORE_BEGIN_MARKER}"
      echo "${source_content}"
      echo "${GITIGNORE_END_MARKER}"
    } > "${dest_gitignore}"
  else
    # .gitignore exists, check for existing managed content
    if grep -qF "${GITIGNORE_BEGIN_MARKER}" "${dest_gitignore}"; then
      # Remove existing managed content (between markers, inclusive)
      print-info "Updating promptfiles managed content in .gitignore"
      local temp_file
      temp_file=$(mktemp)
      awk -v begin="${GITIGNORE_BEGIN_MARKER}" -v end="${GITIGNORE_END_MARKER}" '
        $0 == begin { skip = 1; next }
        $0 == end { skip = 0; next }
        !skip { print }
      ' "${dest_gitignore}" > "${temp_file}"
      # Remove trailing blank lines from temp file
      sed -i '' -e :a -e '/^\n*$/{$d;N;ba' -e '}' "${temp_file}" 2>/dev/null || sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "${temp_file}"
      # Write back with new managed content
      {
        cat "${temp_file}"
        echo ""
        echo "${GITIGNORE_BEGIN_MARKER}"
        echo "${source_content}"
        echo "${GITIGNORE_END_MARKER}"
      } > "${dest_gitignore}"
      rm -f "${temp_file}"
    else
      # No managed content exists, append it
      print-info "Appending promptfiles managed content to .gitignore"
      {
        echo ""
        echo "${GITIGNORE_BEGIN_MARKER}"
        echo "${source_content}"
        echo "${GITIGNORE_END_MARKER}"
      } >> "${dest_gitignore}"
    fi
  fi

  return 0
}

# Update .vscode/settings.json with promptfiles settings.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function update-vscode-settings() {

  local dest="$1"
  local settings_dir="${dest}/.vscode"
  local settings_file="${settings_dir}/settings.json"

  mkdir -p "${settings_dir}"

  if [[ ! -f "${settings_file}" || ! -s "${settings_file}" ]]; then
    print-info "Creating VS Code settings: ${settings_file}"
    cat <<'EOF' > "${settings_file}"
{
  "chat.promptFilesRecommendations": {
    "speckit.constitution": true,
    "speckit.specify": true,
    "speckit.plan": true,
    "speckit.tasks": true,
    "speckit.implement": true
  },
  "chat.tools.terminal.autoApprove": {
    ".specify/scripts/bash/": true
  }
}
EOF
    return 0
  fi

  # Always remove existing sections before adding them back
  remove-vscode-json-property "${settings_file}" "chat.promptFilesRecommendations"
  remove-vscode-json-property "${settings_file}" "chat.tools.terminal.autoApprove"

  # Prepare content to insert (always both sections)
  local insert_file
  insert_file=$(mktemp)

  cat <<'EOF' >> "${insert_file}"
  "chat.promptFilesRecommendations": {
    "speckit.constitution": true,
    "speckit.specify": true,
    "speckit.plan": true,
    "speckit.tasks": true,
    "speckit.implement": true
  },
  "chat.tools.terminal.autoApprove": {
    ".specify/scripts/bash/": true
  }
EOF

  local last_brace_line
  last_brace_line=$(awk '/}/ { line=NR } END { print line }' "${settings_file}")

  if [[ -z "${last_brace_line}" ]]; then
    rm -f "${insert_file}"
    print-error "Invalid ${settings_file}: missing closing brace"
  fi

  local prev_line_num
  prev_line_num=$(awk -v last="${last_brace_line}" 'NR < last { if ($0 ~ /[^[:space:]]/) { line=NR } } END { print line }' "${settings_file}")

  local needs_comma=0
  if [[ -n "${prev_line_num}" ]]; then
    local prev_line
    prev_line=$(sed -n "${prev_line_num}p" "${settings_file}")
    if [[ "${prev_line}" =~ ^[[:space:]]*\{[[:space:]]*$ ]]; then
      needs_comma=0
    elif [[ "${prev_line}" =~ ,[[:space:]]*$ ]]; then
      needs_comma=0
    else
      needs_comma=1
    fi
  fi

  local temp_file
  temp_file=$(mktemp)

  awk -v insert_file="${insert_file}" -v insert_line="${last_brace_line}" -v prev_line="${prev_line_num}" -v needs_comma="${needs_comma}" '
    NR == prev_line && needs_comma == 1 {
      sub(/[[:space:]]*$/, "", $0)
      print $0 ","
      next
    }
    NR == insert_line {
      while ((getline line < insert_file) > 0) { print line }
      close(insert_file)
      print $0
      next
    }
    { print }
  ' "${settings_file}" > "${temp_file}"

  mv "${temp_file}" "${settings_file}"
  rm -f "${insert_file}"

  print-info "Updated VS Code settings: ${settings_file}"

  return 0
}

# Remove a JSON property from a VS Code settings file.
# Arguments (provided as function parameters):
#   $1=[settings file path]
#   $2=[property name without quotes]
function remove-vscode-json-property() {

  local file="$1"
  local property="$2"

  # If property doesn't exist, nothing to do
  if ! grep -q "\"${property}\"" "$file" 2>/dev/null; then
    return 0
  fi

  local temp_file
  temp_file=$(mktemp)

  awk -v prop="\"${property}\"" '
    BEGIN { skip = 0; depth = 0; skip_comma = 0 }
    {
      # Check if this line starts the property we want to remove
      if (!skip && match($0, prop "[[:space:]]*:[[:space:]]*\\{")) {
        skip = 1
        depth = 0
        # Count braces on the same line
        rest_of_line = substr($0, RSTART + RLENGTH)
        for (i = 1; i <= length(rest_of_line); i++) {
          c = substr(rest_of_line, i, 1)
          if (c == "{") depth++
          else if (c == "}") depth--
        }
        # If property closes on same line, stop skipping
        if (depth < 0) {
          skip = 0
          skip_comma = 1
        }
        next
      }

      # While inside the property, track brace depth
      if (skip) {
        for (i = 1; i <= length($0); i++) {
          c = substr($0, i, 1)
          if (c == "{") depth++
          else if (c == "}") depth--
        }
        # When depth goes negative, we have closed the property
        if (depth < 0) {
          skip = 0
          skip_comma = 1
        }
        next
      }

      # Skip a trailing comma line if needed
      if (skip_comma) {
        skip_comma = 0
        if ($0 ~ /^[[:space:]]*,[[:space:]]*$/) {
          next
        }
      }

      print
    }
  ' "$file" > "$temp_file"

  mv "$temp_file" "$file"

  return 0
}

# Copy a directory without bringing across any nested .git metadata.
# Arguments (provided as function parameters):
#   $1=[source directory path]
#   $2=[destination directory path]
function copy-directory-excluding-git() {

  local source_dir="$1"
  local target_dir="$2"

  mkdir -p "${target_dir}"

  if command -v rsync > /dev/null 2>&1; then
    rsync -a --exclude='.git' --exclude='.git/' "${source_dir}/" "${target_dir}/"
  else
    tar -C "${source_dir}" --exclude='.git' -cf - . | tar -C "${target_dir}" -xf -
  fi

  return 0
}

# Print usage information.
function print-usage() {

  cat <<EOF
Usage: $(basename "$0") <destination-directory>

Copy prompt files assets to a destination repository.

Arguments:
    destination-directory   Target directory (absolute or relative path)

Technology switches (set to 'true' to include):
    all=true                Include all technology-specific files
    python=true             Python instruction and prompt
    typescript=true         TypeScript instruction and prompt
    go=true                 Go instruction and prompt
    reactjs=true            ReactJS instruction and prompt
    rust=true               Rust instruction and prompt
    terraform=true          Terraform instruction and prompt
    tauri=true              Tauri instruction and prompt (auto-enables rust, typescript, reactjs)
    playwright=true         Playwright instruction and prompt (requires python or typescript)
    django=true             Django skill (auto-enables python)
    fastapi=true            FastAPI skill (auto-enables python)

Other options:
    clean=true              Remove destination directories before copying
    revert=true             Remove all promptfiles-managed artifacts and exit
    VERBOSE=true            Show all executed commands

Always copied (default/glue layer):
    AGENTS.md (cross-agent baseline at destination root)
    .github/copilot-instructions.md
    .github/hooks/ (Copilot agent hooks, e.g. quality-gates.json)
    scripts/hooks/ (hook executables, e.g. post-edit-lint.sh, stop-gate.sh; chmod +x)
    Default skills: repository-template, enforcement-audit, architecture-docs, code-review
    Spec-kit agents, prompts, templates and constitution
    Shell, Docker, Makefile instructions and prompts
    docs/architecture/, docs/prompts/, ADR template, Tech_Radar.md
    project.code-workspace and managed .gitignore section

Examples:
    $(basename "$0") /path/to/my-project
    python=true $(basename "$0") ../my-project
    all=true clean=true $(basename "$0") ~/projects/my-app
    revert=true $(basename "$0") ~/projects/my-app
    python=true playwright=true $(basename "$0") ~/projects/my-app
    django=true $(basename "$0") ~/projects/my-app  # auto-enables python
EOF
}

# Print an error message to stderr and exit.
# Arguments:
#   $1=[error message to display]
function print-error() {

  echo "Error: $1" >&2
  exit 1
}

# Print an informational message.
# Arguments:
#   $1=[message to display]
function print-info() {

  echo "→ $1"
}

# ==============================================================================

# Check if an argument is a truthy value.
# Arguments:
#   $1=[value to check]
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
