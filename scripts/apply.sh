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
#   revert=true             # Remove all loadout-managed artifacts from destination and exit, default is 'false'
#   subset=<csv>            # Restrict copy to named categories (comma-separated). Valid tokens:
#                           #   agents, hooks, instructions, prompts, skills, specify, docs, project, speckit, mcp, all
#                           # Omitted or 'all' preserves the default full-copy behaviour byte-for-byte.
#                           # The 'speckit' token narrows the prompts copy to review.speckit-* prompts only
#                           # when used WITHOUT 'prompts'.
#                           # The 'mcp' token is opt-in only: MCP assets are NOT copied by default and NOT
#                           # included by 'all'. They are copied only when 'mcp' is named explicitly in the
#                           # subset csv (e.g. subset=all,mcp or subset=mcp).
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
#
# Always copied (default/glue layer):
#   - Agent markdown files under .github/agents (currently README placeholder only)
#   - Shell, Docker, Makefile instructions and prompts
#   - Development prompts (dev.implement-*)
#   - Architecture documentation prompts (architecture.*)
#   - Spec-kit review prompts (review.speckit-*)
#   - Utility prompts (util.*)
#   - Shared includes (baselines)
#   - Default templates (Makefile, Dockerfile, compose.yaml, shell-script)
#   - All skills under .github/skills/
#   - copilot-instructions.md
#   - .github/hooks/ (Copilot agent hooks, e.g. quality-gates.json)
#   - scripts/hooks/ (hook executables, e.g. session-start-cheatsheet.sh, stop-gate.sh; chmod +x)
#   - scripts/loadout.mk plus a managed Makefile include block for downstream repos
#     that already use repository-template's Makefile + scripts/init.mk
#   - pull_request_template.md (if not already present)
#   - constitution.md
#   - .specify/scripts/python
#   - .specify/templates
#   - ADR-nnn_Any_Decision_Record_Template.md
#   - Tech_Radar.md
#   - .copilot/analysis/.gitignore
#   - .gitignore content (managed section with begin/end markers)
#
# Opt-in only (requires explicit subset token):
#   - MCP example pack (.vscode/mcp.json.example, .github/mcp/, docs/mcp.md) - subset=mcp
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
HOOK_SCRIPTS_DIR="${REPO_ROOT}/scripts/hooks"
LOADOUT_MAKEFILE_MODULE="${REPO_ROOT}/scripts/loadout.mk"

SPECIFY_MEMORY="${REPO_ROOT}/.specify/memory"
SPECIFY_SCRIPTS_PYTHON="${REPO_ROOT}/.specify/scripts/python"
SPECIFY_TEMPLATES="${REPO_ROOT}/.specify/templates"

PULL_REQUEST_TEMPLATE="${REPO_ROOT}/.github/pull_request_template.md"
ADR_TEMPLATE="${REPO_ROOT}/docs/adr/ADR-nnn_Any_Decision_Record_Template.md"
ADR_TECH_RADAR="${REPO_ROOT}/docs/adr/Tech_Radar.md"
COPILOT_ANALYSIS_DIR="${REPO_ROOT}/.copilot/analysis"
MCP_VSCODE_EXAMPLE="${REPO_ROOT}/.vscode/mcp.json.example"
MCP_GITHUB_DIR="${REPO_ROOT}/.github/mcp"
MCP_DOC="${REPO_ROOT}/docs/mcp.md"
GITIGNORE_LOADOUT="${REPO_ROOT}/.gitignore.loadout"

# Begin/end markers for managed .gitignore content
GITIGNORE_BEGIN_MARKER="# >>> loadout managed content - DO NOT EDIT BELOW THIS LINE >>>"
GITIGNORE_END_MARKER="# <<< loadout managed content - DO NOT EDIT ABOVE THIS LINE <<<"
LOADOUT_MAKEFILE_BEGIN_MARKER="# >>> loadout managed makefile include - DO NOT EDIT BELOW THIS LINE >>>"
LOADOUT_MAKEFILE_END_MARKER="# <<< loadout managed makefile include - DO NOT EDIT ABOVE THIS LINE <<<"
LOADOUT_MAKEFILE_FILE_MARKER="# loadout-managed: scripts/loadout.mk"

# Default instruction files (glue layer)
DEFAULT_INSTRUCTIONS=("docker" "makefile" "readme" "shell")

# Default prompt patterns (glue layer and spec-kit)
DEFAULT_PROMPT_PATTERNS=("architecture.*" "dev.implement-*" "enforce.docker" "enforce.makefile" "enforce.shell" "review.speckit-*" "spec.*" "util.*")

# Default templates (glue layer)
DEFAULT_TEMPLATES=("Makefile.template" "Dockerfile.template" "compose.yaml.template" "shell-script.template.sh")

# All technology switches (for iteration)
ALL_TECHS=("python" "typescript" "go" "reactjs" "rust" "terraform" "tauri" "playwright")

# Valid subset selector tokens (closed set).
SUBSET_VALID_TOKENS=("agents" "hooks" "instructions" "prompts" "skills" "specify" "docs" "project" "speckit" "mcp" "all")

# Subset category flags - populated by parse-subset. Default (no subset) enables all.
SUBSET_AGENTS=true
SUBSET_HOOKS=true
SUBSET_INSTRUCTIONS=true
SUBSET_PROMPTS=true
SUBSET_SKILLS=true
SUBSET_SPECIFY=true
SUBSET_DOCS=true
SUBSET_PROJECT=true
SUBSET_SPECKIT=true
# MCP is opt-in only: NOT copied by default and NOT enabled by 'all'. It is
# included only when the subset csv explicitly contains 'mcp'.
SUBSET_MCP=false
# True only when subset was explicitly set (used to gate observability messages).
SUBSET_EXPLICIT=false
# Narrowing flag - true when subset contains 'speckit' but not 'prompts'.
SPECKIT_NARROW_PROMPTS=false

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

  # Validate playwright requires python or typescript (unless all=true)
  if is-arg-true "${playwright:-false}" && ! is-arg-true "${all:-false}"; then
    if ! is-arg-true "${python:-false}" && ! is-arg-true "${typescript:-false}"; then
      print-error "playwright=true requires either python=true or typescript=true to be set"
    fi
  fi

  parse-subset

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
    revert-loadout "${destination}"
    echo
    echo "Done. Loadout artifacts reverted from ${destination}"
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

# Parse the optional `subset` env var and populate SUBSET_* and
# SPECKIT_NARROW_* flags. An empty/unset `subset` preserves the default
# behaviour (all flags true, SUBSET_EXPLICIT=false). Validation is strict -
# the first invalid token aborts with exit code 1.
function parse-subset() {

  local raw="${subset:-}"

  if [[ -z "${raw// /}" ]]; then
    return 0
  fi

  SUBSET_EXPLICIT=true

  # All flags default to false when subset is explicit; tokens turn them on.
  SUBSET_AGENTS=false
  SUBSET_HOOKS=false
  SUBSET_INSTRUCTIONS=false
  SUBSET_PROMPTS=false
  SUBSET_SKILLS=false
  SUBSET_SPECIFY=false
  SUBSET_DOCS=false
  SUBSET_PROJECT=false
  SUBSET_SPECKIT=false
  SUBSET_MCP=false

  local -a tokens=()
  local token lc trimmed valid match
  # Use a space-delimited string for membership tracking (bash 3.2 compatible -
  # no associative arrays).
  local seen=" "

  IFS=',' read -r -a tokens <<< "${raw}"
  for token in "${tokens[@]}"; do
    # Trim leading/trailing whitespace
    trimmed="${token#"${token%%[![:space:]]*}"}"
    trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
    [[ -z "${trimmed}" ]] && continue
    # Lowercase
    lc="$(printf '%s' "${trimmed}" | tr '[:upper:]' '[:lower:]')"
    # Dedupe
    if [[ "${seen}" == *" ${lc} "* ]]; then
      continue
    fi
    # Validate against the closed set
    valid=false
    for match in "${SUBSET_VALID_TOKENS[@]}"; do
      if [[ "${lc}" == "${match}" ]]; then
        valid=true
        break
      fi
    done
    if [[ "${valid}" != "true" ]]; then
      echo "[apply] ERROR: invalid subset value '${lc}'. Valid values: agents, hooks, instructions, prompts, skills, specify, docs, project, speckit, mcp, all." >&2
      exit 1
    fi
    seen="${seen}${lc} "
  done

  if [[ "${seen}" == *" all "* ]]; then
    SUBSET_AGENTS=true
    SUBSET_HOOKS=true
    SUBSET_INSTRUCTIONS=true
    SUBSET_PROMPTS=true
    SUBSET_SKILLS=true
    SUBSET_SPECIFY=true
    SUBSET_DOCS=true
    SUBSET_PROJECT=true
    SUBSET_SPECKIT=true
    # MCP remains opt-in even with 'all'; require explicit 'mcp' token.
    return 0
  fi

  [[ "${seen}" == *" agents "* ]] && SUBSET_AGENTS=true
  [[ "${seen}" == *" hooks "* ]] && SUBSET_HOOKS=true
  [[ "${seen}" == *" instructions "* ]] && SUBSET_INSTRUCTIONS=true
  [[ "${seen}" == *" prompts "* ]] && SUBSET_PROMPTS=true
  [[ "${seen}" == *" skills "* ]] && SUBSET_SKILLS=true
  [[ "${seen}" == *" specify "* ]] && SUBSET_SPECIFY=true
  [[ "${seen}" == *" docs "* ]] && SUBSET_DOCS=true
  [[ "${seen}" == *" project "* ]] && SUBSET_PROJECT=true
  [[ "${seen}" == *" speckit "* ]] && SUBSET_SPECKIT=true
  [[ "${seen}" == *" mcp "* ]] && SUBSET_MCP=true

  # Speckit narrowing: when the caller asked for speckit but NOT prompts,
  # restrict prompts to review.speckit-*.
  if [[ "${SUBSET_SPECKIT}" == "true" && "${SUBSET_PROMPTS}" != "true" ]]; then
    SPECKIT_NARROW_PROMPTS=true
  fi

  return 0
}

# Emit a "skipping" info message for an unselected category. No-op unless
# subset was explicitly set by the caller.
# Arguments:
#   $1=[category name]
function subset-skip() {

  if [[ "${SUBSET_EXPLICIT}" == "true" ]]; then
    echo "[apply] skipping $1 (not in subset)"
  fi

  return 0
}

# Apply copilot-specific assets to the destination.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function copilot-apply() {

  local destination="$1"

  if is-arg-true "${clean:-false}"; then
    copilot-clean-directories "${destination}"
  fi
  if [[ "${SUBSET_AGENTS}" == "true" ]]; then
    copilot-copy-agents "${destination}"
  else
    subset-skip "agents"
  fi
  if [[ "${SUBSET_HOOKS}" == "true" ]]; then
    copilot-copy-hooks "${destination}"
  else
    subset-skip "hooks"
  fi
  if [[ "${SUBSET_INSTRUCTIONS}" == "true" ]]; then
    copilot-copy-instructions "${destination}"
  else
    subset-skip "instructions"
  fi
  if [[ "${SUBSET_PROMPTS}" == "true" || "${SUBSET_SPECKIT}" == "true" ]]; then
    copilot-copy-prompts "${destination}"
  else
    subset-skip "prompts"
  fi
  if [[ "${SUBSET_SKILLS}" == "true" ]]; then
    copilot-copy-skills "${destination}"
  else
    subset-skip "skills"
  fi
  if [[ "${SUBSET_PROJECT}" == "true" ]]; then
    copilot-copy-instructions-md "${destination}"
  else
    subset-skip "copilot-instructions.md"
  fi
  copy-shared-resources "${destination}"

  return 0
}

# Copy shared resources common to all AI tools.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function copy-shared-resources() {

  local destination="$1"

  if [[ "${SUBSET_SPECIFY}" == "true" || "${SUBSET_SPECKIT}" == "true" ]]; then
    copy-specify-memory "${destination}"
    copy-specify-scripts-python "${destination}"
    copy-specify-templates "${destination}"
  else
    subset-skip "specify"
  fi
  if [[ "${SUBSET_PROJECT}" == "true" ]]; then
    copy-pull-request-template "${destination}"
  else
    subset-skip "pull-request-template"
  fi
  if [[ "${SUBSET_DOCS}" == "true" ]]; then
    copy-adr-template "${destination}"
  else
    subset-skip "docs"
  fi
  if [[ "${SUBSET_PROJECT}" == "true" ]]; then
    copy-copilot-analysis "${destination}"
    copy-loadout-make-integration "${destination}"
  else
    subset-skip "project-files"
  fi
  if [[ "${SUBSET_HOOKS}" == "true" || "${SUBSET_PROJECT}" == "true" ]]; then
    copy-hook-scripts "${destination}"
  else
    subset-skip "hook-scripts"
  fi
  if [[ "${SUBSET_PROJECT}" == "true" ]]; then
    update-gitignore "${destination}"
  else
    subset-skip "gitignore"
  fi
  if [[ "${SUBSET_MCP}" == "true" ]]; then
    copy-mcp-assets "${destination}"
  else
    subset-skip "mcp"
  fi

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

# Remove all loadout-managed artifacts from the destination.
# This undoes what a previous apply has done.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function revert-loadout() {

  local dest="$1"

  echo "Reverting prompt files from: ${dest}"
  echo

  revert-copilot "${dest}"
  revert-shared-resources "${dest}"

  return 0
}

# Remove copilot-specific loadout-managed artifacts from the destination.
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

  # Remove hook scripts (scripts/hooks/ is fully managed by loadout;
  # any user-authored files placed there will be removed on revert)
  if [[ -d "${dest}/scripts/hooks" ]]; then
    print-info "Removing ${dest}/scripts/hooks"
    rm -rf "${dest:?}/scripts/hooks"
  fi

  return 0
}

# Remove shared loadout-managed artifacts from the destination.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function revert-shared-resources() {

  local dest="$1"

  revert-loadout-make-integration "${dest}"

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

  # Remove .copilot/analysis directory if empty or only contains .gitignore.
  if [[ -d "${dest}/.copilot/analysis" ]]; then
    local analysis_contents
    analysis_contents=$(ls -A "${dest}/.copilot/analysis" 2>/dev/null)
    if [[ -z "${analysis_contents}" ]] || [[ "${analysis_contents}" == ".gitignore" ]]; then
      print-info "Removing ${dest}/.copilot/analysis"
      rm -rf "${dest:?}/.copilot/analysis"
    fi
  fi

  # Remove managed .gitignore section
  if [[ -f "${dest}/.gitignore" ]] && grep -qF "${GITIGNORE_BEGIN_MARKER}" "${dest}/.gitignore"; then
    print-info "Removing loadout managed content from .gitignore"
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

  # Remove MCP example pack
  if [[ -f "${dest}/.vscode/mcp.json.example" ]]; then
    print-info "Removing ${dest}/.vscode/mcp.json.example"
    rm -f "${dest}/.vscode/mcp.json.example"
  fi
  if [[ -d "${dest}/.github/mcp" ]]; then
    print-info "Removing ${dest}/.github/mcp"
    rm -rf "${dest:?}/.github/mcp"
  fi
  if [[ -f "${dest}/docs/mcp.md" ]]; then
    print-info "Removing ${dest}/docs/mcp.md"
    rm -f "${dest}/docs/mcp.md"
  fi

  # Clean up empty parent directories
  for dir in "${dest}/.github" "${dest}/docs/adr" "${dest}/docs" "${dest}/.vscode" "${dest}/scripts" "${dest}/.copilot"; do
    if [[ -d "${dir}" ]] && [[ -z "$(ls -A "${dir}" 2>/dev/null)" ]]; then
      print-info "Removing empty directory ${dir}"
      rmdir "${dir}"
    fi
  done

  return 0
}

# Copy scripts/loadout.mk and patch a compatible downstream root Makefile.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function copy-loadout-make-integration() {

  local dest="$1"
  local dest_makefile="${dest}/Makefile"
  local dest_loadout_module="${dest}/scripts/loadout.mk"

  if ! destination-has-compatible-root-makefile "${dest}"; then
    print-info "Skipping loadout Makefile integration (destination does not have repository-template Makefile + scripts/init.mk)"
    return 0
  fi

  if [[ -f "${dest_makefile}" ]] && ! grep -qF "${LOADOUT_MAKEFILE_BEGIN_MARKER}" "${dest_makefile}" && grep -qF "include scripts/loadout.mk" "${dest_makefile}"; then
    print-info "Skipping loadout Makefile integration (destination Makefile already includes scripts/loadout.mk outside the managed block)"
    return 0
  fi

  if [[ -f "${dest_loadout_module}" ]] && ! grep -qF "${LOADOUT_MAKEFILE_FILE_MARKER}" "${dest_loadout_module}"; then
    print-info "Skipping loadout Makefile integration (destination scripts/loadout.mk exists and is not loadout-managed)"
    return 0
  fi

  mkdir -p "${dest}/scripts"
  print-info "Copying scripts/loadout.mk to ${dest}/scripts"
  cp "${LOADOUT_MAKEFILE_MODULE}" "${dest_loadout_module}"

  update-loadout-make-include "${dest_makefile}"

  return 0
}

# Check whether a destination repository has the repository-template root Makefile surface.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function destination-has-compatible-root-makefile() {

  local dest="$1"
  local dest_makefile="${dest}/Makefile"
  local dest_init_mk="${dest}/scripts/init.mk"

  if [[ ! -f "${dest_makefile}" ]] || [[ ! -f "${dest_init_mk}" ]]; then
    return 1
  fi

  if ! grep -Eq '^[[:space:]]*include[[:space:]]+scripts/init\.mk([[:space:]]*(#.*)?)?$' "${dest_makefile}"; then
    return 1
  fi

  return 0
}

# Insert or refresh the managed loadout include block in a downstream Makefile.
# Arguments (provided as function parameters):
#   $1=[path to the destination Makefile]
function update-loadout-make-include() {

  local dest_makefile="$1"
  local stripped_makefile
  local updated_makefile

  stripped_makefile=$(mktemp)
  updated_makefile=$(mktemp)

  if grep -qF "${LOADOUT_MAKEFILE_BEGIN_MARKER}" "${dest_makefile}"; then
    awk -v begin="${LOADOUT_MAKEFILE_BEGIN_MARKER}" -v end="${LOADOUT_MAKEFILE_END_MARKER}" '
      $0 == begin { skip = 1; next }
      $0 == end { skip = 0; next }
      !skip { print }
    ' "${dest_makefile}" > "${stripped_makefile}"
  else
    cp "${dest_makefile}" "${stripped_makefile}"
  fi

  if ! awk -v begin="${LOADOUT_MAKEFILE_BEGIN_MARKER}" -v include_line="include scripts/loadout.mk" -v end="${LOADOUT_MAKEFILE_END_MARKER}" '
    {
      print
      if (!inserted && $0 ~ /^[[:space:]]*include[[:space:]]+scripts\/init\.mk([[:space:]]*(#.*)?)?$/) {
        print begin
        print include_line
        print end
        inserted = 1
      }
    }
    END { exit inserted ? 0 : 1 }
  ' "${stripped_makefile}" > "${updated_makefile}"; then
    rm -f "${stripped_makefile}" "${updated_makefile}"
    print-error "Could not find 'include scripts/init.mk' in ${dest_makefile}"
  fi

  mv "${updated_makefile}" "${dest_makefile}"
  rm -f "${stripped_makefile}"

  return 0
}

# Remove the managed loadout Makefile integration from a downstream repository.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function revert-loadout-make-integration() {

  local dest="$1"
  local dest_makefile="${dest}/Makefile"
  local dest_loadout_module="${dest}/scripts/loadout.mk"
  local stripped_makefile

  if [[ -f "${dest_makefile}" ]] && grep -qF "${LOADOUT_MAKEFILE_BEGIN_MARKER}" "${dest_makefile}"; then
    print-info "Removing loadout managed Makefile include from ${dest_makefile}"
    stripped_makefile=$(mktemp)
    awk -v begin="${LOADOUT_MAKEFILE_BEGIN_MARKER}" -v end="${LOADOUT_MAKEFILE_END_MARKER}" '
      $0 == begin { skip = 1; next }
      $0 == end { skip = 0; next }
      !skip { print }
    ' "${dest_makefile}" > "${stripped_makefile}"
    mv "${stripped_makefile}" "${dest_makefile}"
  fi

  if [[ -f "${dest_loadout_module}" ]] && grep -qF "${LOADOUT_MAKEFILE_FILE_MARKER}" "${dest_loadout_module}"; then
    print-info "Removing ${dest_loadout_module}"
    rm -f "${dest_loadout_module}"
  fi

  return 0
}

# Copy copilot agent files to the destination.
# Copies any markdown files present under .github/agents recursively.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function copilot-copy-agents() {

  local dest_agents="$1/.github/agents"
  mkdir -p "${dest_agents}"

  print-info "Copying agent files to ${dest_agents}"
  # Preserve the relative directory structure under .github/agents/.
  local src_file rel_path target_dir
  while IFS= read -r -d '' src_file; do
    rel_path="${src_file#"${COPILOT_AGENTS_DIR}/"}"
    target_dir="${dest_agents}/$(dirname "${rel_path}")"
    mkdir -p "${target_dir}"
    cp "${src_file}" "${target_dir}/"
  done < <(find "${COPILOT_AGENTS_DIR}" -name "*.md" -type f -print0)
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

  # Default prompt pattern set; narrow to speckit-only when requested.
  local -a patterns
  if [[ "${SPECKIT_NARROW_PROMPTS:-false}" == "true" ]]; then
    patterns=("review.speckit-*")
  else
    patterns=("${DEFAULT_PROMPT_PATTERNS[@]}")
  fi

  # Copy default prompt files using patterns
  for pattern in "${patterns[@]}"; do
    # Use find with -name to match patterns
    find "${COPILOT_PROMPTS_DIR}" -maxdepth 1 -name "${pattern}.prompt.md" -type f -exec cp {} "${dest_prompts}/" \; 2>/dev/null || true
  done

  # Skip technology-specific prompts when narrowing to speckit only.
  if [[ "${SPECKIT_NARROW_PROMPTS:-false}" == "true" ]]; then
    return 0
  fi

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

# Copy all copilot skills to the destination.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function copilot-copy-skills() {

  local dest_skills="$1/.github/skills"
  mkdir -p "${dest_skills}"

  print-info "Copying skills files to ${dest_skills}"

  local skill_dir
  for skill_dir in "${COPILOT_SKILLS_DIR}"/*/; do
    [[ -d "$skill_dir" ]] || continue
    local skill_name
    skill_name=$(basename "$skill_dir")
    copy-directory-excluding-git "${skill_dir}" "${dest_skills}/${skill_name}"
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

  return 0
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

# Copy .specify/scripts/python directory to the destination.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function copy-specify-scripts-python() {

  local dest="$1/.specify/scripts/python"
  mkdir -p "${dest}"

  print-info "Copying .specify/scripts/python to ${dest}"
  cp -R "${SPECIFY_SCRIPTS_PYTHON}/". "${dest}/"
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

# Copy the tracked .copilot/analysis scaffold to the destination.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function copy-copilot-analysis() {

  local dest="$1/.copilot/analysis"
  mkdir -p "${dest}"

  print-info "Copying .copilot/analysis scaffold to ${dest}"
  cp -R "${COPILOT_ANALYSIS_DIR}/." "${dest}/"

  return 0
}

# Update .gitignore with loadout managed content.
# Creates .gitignore if it doesn't exist, or updates the managed section if it does.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function update-gitignore() {

  local dest_gitignore="$1/.gitignore"
  local source_content
  source_content=$(cat "${GITIGNORE_LOADOUT}")

  if [[ ! -f "${dest_gitignore}" ]]; then
    # No .gitignore exists, create it with markers and content
    print-info "Creating .gitignore with loadout managed content"
    {
      echo "${GITIGNORE_BEGIN_MARKER}"
      echo "${source_content}"
      echo "${GITIGNORE_END_MARKER}"
    } > "${dest_gitignore}"
  else
    # .gitignore exists, check for existing managed content
    if grep -qF "${GITIGNORE_BEGIN_MARKER}" "${dest_gitignore}"; then
      # Remove existing managed content (between markers, inclusive)
      print-info "Updating loadout managed content in .gitignore"
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
      print-info "Appending loadout managed content to .gitignore"
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

# Copy MCP example pack to the destination.
# Distributes .vscode/mcp.json.example, .github/mcp/ (per-server READMEs) and
# docs/mcp.md. The .example suffix prevents VS Code from auto-loading the
# config so the explicit trust prompt remains in effect.
# Arguments (provided as function parameters):
#   $1=[destination directory path]
function copy-mcp-assets() {

  local dest="$1"

  if [[ -f "${MCP_VSCODE_EXAMPLE}" ]]; then
    local dest_vscode="${dest}/.vscode"
    mkdir -p "${dest_vscode}"
    print-info "Copying .vscode/mcp.json.example to ${dest_vscode}"
    cp "${MCP_VSCODE_EXAMPLE}" "${dest_vscode}/"
  fi

  if [[ -d "${MCP_GITHUB_DIR}" ]]; then
    local dest_mcp="${dest}/.github/mcp"
    mkdir -p "${dest_mcp}"
    print-info "Copying .github/mcp to ${dest_mcp}"
    copy-directory-excluding-git "${MCP_GITHUB_DIR}" "${dest_mcp}"
  fi

  if [[ -f "${MCP_DOC}" ]]; then
    local dest_docs="${dest}/docs"
    mkdir -p "${dest_docs}"
    print-info "Copying docs/mcp.md to ${dest_docs}"
    cp "${MCP_DOC}" "${dest_docs}/"
  fi

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

Other options:
    clean=true              Remove destination directories before copying
    revert=true             Remove all loadout-managed artifacts and exit
    subset=<csv>            Restrict copy to named categories (comma-separated).
                            Valid tokens: agents, hooks, instructions, prompts,
                            skills, specify, docs, project, speckit, mcp, all.
                            Omitted or 'all' preserves full-copy behaviour.
    VERBOSE=true            Show all executed commands

Always copied (default/glue layer):
    .github/copilot-instructions.md
    .github/hooks/ (Copilot agent hooks, e.g. quality-gates.json)
    scripts/hooks/ (hook executables, e.g. session-start-cheatsheet.sh, stop-gate.sh; chmod +x)
    scripts/loadout.mk plus a managed Makefile include block for downstream repos
      that already use repository-template's Makefile + scripts/init.mk
    Default skills: repository-template, enforcement-audit, architecture-docs, code-review, spec-consolidation, system-documentation
    Spec-kit agents, prompts, templates and constitution
    Shell, Docker, Makefile instructions and prompts
    .copilot/analysis/.gitignore, ADR template, Tech_Radar.md
    managed .gitignore section

Examples:
    $(basename "$0") /path/to/my-project
    python=true $(basename "$0") ../my-project
    all=true clean=true $(basename "$0") ~/projects/my-app
    revert=true $(basename "$0") ~/projects/my-app
    python=true playwright=true $(basename "$0") ~/projects/my-app
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
