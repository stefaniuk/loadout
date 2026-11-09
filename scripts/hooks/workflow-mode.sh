#!/usr/bin/env bash

set -euo pipefail

# Choose the workflow mode of a worktree and keep GitHub Copilot agents to it. A
# workflow mode is a named set of agent skills that belong to one way of
# working. Loadout defines the 'speckit' and 'superpowers' modes in
# 'scripts/hooks/workflow-modes.yaml', and a project changes or adds modes in
# the drop-in files in 'scripts/config/workflow-modes.d/'. One mode is active
# per worktree, so an agent does not mix the skills of two ways of working. The
# script is registered as a Copilot command hook in
# '.github/hooks/workflow-mode.json', and the 'workflow-*' make targets in
# 'scripts/loadout.ext.mk' run its other commands.
#
# Usage:
#   $ ./scripts/hooks/workflow-mode.sh status
#   $ ./scripts/hooks/workflow-mode.sh list
#   $ [options] ./scripts/hooks/workflow-mode.sh use
#   $ ./scripts/hooks/workflow-mode.sh clear
#   $ ./scripts/hooks/workflow-mode.sh hook  # Copilot hook, the event JSON
#                                            # arrives on stdin
#
# Options:
#   mode=name     # Mode to make active, required by 'use'
#   VERBOSE=true  # Show all the executed commands, default is 'false'
#
# Exit codes:
#   0   - The command succeeded, 'hook' always returns 0
#   1   - The mode is missing, malformed or not defined, the chosen mode is not
#         defined or cannot be read or written, or jq or yq cannot run
#   2   - The workflow mode configuration is missing or invalid
#   126 - The command is not recognised
#
# Notes:
#   1) The active mode is the one chosen with 'use', else the configuration's
#      'default', else none. 'status' shows it with its description, skills,
#      where it is set and how to change it, and 'use' and 'clear' show the
#      same after their change. The choice is kept in
#      '$(git rev-parse --git-path workflow-mode)', which is per worktree and
#      never tracked. 'clear' removes it. 'list' also checks the patterns
#      against the skills in '.github/skills' and prints its findings on
#      stderr.
#   2) The hook handles three events. At 'SessionStart' and 'SubagentStart' it
#      tells the agent which mode is active and which skills each mode owns,
#      and names the skills of the mode that only the user can start. At
#      'PreToolUse' it denies a call of the 'skill' tool for a skill that only
#      other modes own. A skill that no mode owns is always allowed, and so is
#      every skill when no mode is active or the chosen mode is not defined or
#      cannot be read.
#   3) The hook fails open. When it cannot run it prints '{}' and the reason on
#      stderr, because the Copilot runtime denies the tool call when a
#      'PreToolUse' command hook fails. At 'SessionStart' and 'SubagentStart',
#      when modes are defined, it tells the agent instead that no mode is
#      enforced.
#   4) The hook reads the configuration from the working tree. It guards
#      against mixing workflows by mistake and is not a security control.
#   5) The editor may start the hook with the macOS Bash 3.2, so the script
#      uses no newer Bash features.

# ==============================================================================

readonly CONFIG_FILE=scripts/hooks/workflow-modes.yaml
readonly CONFIG_DIR=scripts/config/workflow-modes.d
readonly JQ_MODULE_DIR=scripts/hooks
readonly SKILLS_DIR=.github/skills
readonly MODE_PATTERN='^[a-z0-9][a-z0-9-]{0,39}$'
readonly DROP_IN_PATTERN='^[A-Za-z0-9][A-Za-z0-9._-]*\.ya?ml$'
readonly USE_HINT="make workflow-use mode=<name>"
# The guide stays in loadout, destinations get only the scripts
readonly GUIDE=https://github.com/stefaniuk/loadout/blob/main/docs/workflow-modes.md
# Told to the agent at session start when the hook cannot check the mode
readonly FALLBACK_CONTEXT="Workflow mode: the workflow mode check could not run, so no mode is enforced. Tell the user to run 'make workflow-status' to see why."
readonly CONTEXT_EVENT_PATTERN='"hook_event_name"[[:space:]]*:[[:space:]]*"(SessionStart|SubagentStart)"'

# Run the requested command.
function main() {

  local command="${1:-}" top
  if [[ $command == hook ]]; then
    run-hook
    return 0
  fi
  top="$(git rev-parse --show-toplevel)" || return 1
  cd "$top" || return 1
  case $command in
    status)
      prepare-tools jq yq || return "$?"
      status-command || return "$?"
      ;;
    list)
      prepare-tools jq yq || return "$?"
      list-command || return "$?"
      ;;
    use)
      prepare-tools jq yq || return "$?"
      use-command "${mode:-}" || return "$?"
      ;;
    clear)
      prepare-tools jq yq || return "$?"
      clear-command || return "$?"
      ;;
    *)
      echo "Unrecognised command: '$command'. Use one of: status, list, use, clear, hook" >&2
      return 126
      ;;
  esac

  return 0
}

# ==============================================================================
# Commands

# Print the active mode with its description, skills and how to change it, or
# why no mode is active.
function status-command() {

  local config
  config="$(load-config)" || return "$?"
  show-status "$config" || return "$?"

  return 0
}

# Print the defined modes and mark the active one as 'chosen' or 'default'.
function list-command() {

  local config line state value rows installed
  config="$(load-config)" || return "$?"
  if [[ $(jq '.modes | length' <<< "$config") -eq 0 ]]; then
    echo "No workflow modes are defined. Add them in $CONFIG_DIR/<name>.yaml, see $GUIDE."
    return 0
  fi
  line="$(mode-state "$config")" || return 1
  IFS=$'\t' read -r state value <<< "$line"
  if [[ $state != chosen && $state != default ]]; then
    # The list is still useful when the choice cannot be used
    print-status "$config" "$state" "$value" > /dev/null || true
  fi
  rows="$(jq -r -L "$JQ_MODULE_DIR" --arg state "$state" --arg active "$value" 'include "workflow-mode"; .modes[] | [(if .name == $active and ($state == "chosen" or $state == "default") then $state else "" end), .name, (.skills | skills_cell(40)), .description] | @tsv' <<< "$config")" || return 2
  printf '%s\n' "$rows" \
    | awk -F'\t' 'BEGIN { printf "%-8s %-20s %-40s %s\n", "ACTIVE", "NAME", "SKILLS", "DESCRIPTION" } NF > 0 { printf "%-8s %-20s %-40s %s\n", $1, $2, $3, $4 }'
  installed="$(installed-skills)" || return 1
  if [[ $installed != "[]" ]]; then
    jq -r -L "$JQ_MODULE_DIR" --argjson installed "$installed" 'include "workflow-mode"; skill_notes($installed)' <<< "$config" >&2 || return 2
  fi

  return 0
}

# Make a mode active in this worktree, then print the status.
# Arguments:
#   $1=[mode name]
function use-command() {

  local name="$1" config modes file line state value lead
  config="$(load-config)" || return "$?"
  modes="$(modes-sentence "$config")" || return 1
  if [[ -z $name ]]; then
    echo "ERROR: name the mode to use, as in '$USE_HINT'. $modes" >&2
    return 1
  fi
  if [[ ! $name =~ $MODE_PATTERN ]] || ! jq -e --arg name "$name" 'any(.modes[]; .name == $name)' <<< "$config" > /dev/null; then
    # The name comes from the command line, so it is printed escaped
    printf "ERROR: there is no workflow mode '%q'. %s\n" "$name" "$modes" >&2
    return 1
  fi
  file="$(state-file)" || return 1
  require-state-file "$file" || return 1
  line="$(mode-state "$config")" || return 1
  IFS=$'\t' read -r state value <<< "$line"
  if [[ $state == chosen && $value == "$name" ]]; then
    lead="$name is already chosen for this worktree."
  else
    # The shell reports a failed redirection itself, so its message is replaced
    if ! printf '%s\n' "$name" 2> /dev/null > "$file"; then
      echo "ERROR: cannot write the workflow mode to $file. Run 'make workflow-clear', then try again." >&2
      return 1
    fi
    lead="Chose $name for this worktree. Start a new chat session so that the agent uses it."
  fi
  printf '%s\n\n' "$lead"
  show-status "$config" || return "$?"

  return 0
}

# Remove the mode chosen for this worktree, then print the status.
function clear-command() {

  local file config lead
  file="$(state-file)" || return 1
  require-state-file "$file" || return 1
  if [[ -e $file || -L $file ]]; then
    rm -f "$file" || return 1
    lead="Cleared the mode chosen for this worktree. Start a new chat session so that the agent uses the mode below."
  else
    lead="No mode was chosen for this worktree, so nothing changed."
  fi
  config="$(load-config)" || return "$?"
  printf '%s\n\n' "$lead"
  show-status "$config" || return "$?"

  return 0
}

# ==============================================================================
# Hook

# Handle a Copilot hook event from stdin. Print the response and never fail.
# When the hook cannot run, it prints '{}', or when a session or subagent
# starts, a context that says so when modes are defined.
function run-hook() {

  local payload response
  # A read error leaves an empty payload, which is handled as invalid
  payload="$(cat)" || payload=""
  if response="$(handle-hook "$payload")" && [[ -n $response ]]; then
    printf '%s\n' "$response"
  elif [[ $payload =~ $CONTEXT_EVENT_PATTERN ]] && has-modes; then
    printf '{"additionalContext":"%s","hookSpecificOutput":{"hookEventName":"%s","additionalContext":"%s"}}\n' "$FALLBACK_CONTEXT" "${BASH_REMATCH[1]}" "$FALLBACK_CONTEXT"
  else
    echo '{}'
  fi

  return 0
}

# Succeed when modes may be defined: the loadout modes file lists one, or a
# drop-in file exists. It needs neither jq nor yq.
function has-modes() {

  local top path
  top="$(git rev-parse --show-toplevel 2> /dev/null)" || return 1
  if grep -Eq '^[[:space:]]*-[[:space:]]+name:' "$top/$CONFIG_FILE" 2> /dev/null; then
    return 0
  fi
  for path in "$top/$CONFIG_DIR"/*.yaml "$top/$CONFIG_DIR"/*.yml; do
    if [[ -e $path ]]; then
      return 0
    fi
  done

  return 1
}

# Read the hook event and print the response. Only the event name, the tool
# name and the skill name are taken from the payload.
# Arguments:
#   $1=[event JSON]
function handle-hook() {

  local payload="$1" fields event tool skill top config line state value
  prepare-tools jq || return 1
  if ! fields="$(jq -r '[.hook_event_name, .tool_name, (if (.tool_input | type) == "object" then .tool_input.skill else null end)] | map(. // "" | tostring | gsub("[\u0000-\u001f]"; " ")) | join("\u001f")' <<< "$payload" 2> /dev/null)"; then
    echo "ERROR: workflow mode hook: the event is not valid JSON" >&2
    return 1
  fi
  IFS=$'\x1f' read -r event tool skill <<< "$fields"
  case $event in
    SessionStart|SubagentStart)
      ;;
    PreToolUse)
      if [[ $tool != skill || -z $skill ]]; then
        echo '{}'
        return 0
      fi
      ;;
    *)
      echo '{}'
      return 0
      ;;
  esac
  top="$(git rev-parse --show-toplevel)" || return 1
  cd "$top" || return 1
  prepare-tools yq || return 1
  config="$(load-config)" || return 1
  line="$(mode-state "$config")" || return 1
  IFS=$'\t' read -r state value <<< "$line"
  if [[ $event == PreToolUse ]]; then
    if [[ $state == chosen || $state == default ]]; then
      emit-decision "$config" "$value" "$skill" || return 1
    else
      echo '{}'
    fi
  else
    emit-context "$config" "$event" "$state" "$value" || return 1
  fi

  return 0
}

# Print the SessionStart or SubagentStart response. The context goes both at
# the top level, which the Copilot runtime reads, and in hookSpecificOutput,
# which the VS Code Local harness reads.
# Arguments:
#   $1=[configuration JSON]
#   $2=[event name]
#   $3=[state, as printed by mode-state]
#   $4=[mode name or chosen value, as printed by mode-state]
function emit-context() {

  local config="$1" event="$2" state="$3" value="$4" installed
  installed="$(installed-skills)" || return 1
  jq -c -L "$JQ_MODULE_DIR" --arg event "$event" --arg state "$state" --arg value "$value" --argjson installed "$installed" \
    'include "workflow-mode"; [session_context($state; $value; $installed)] | if length == 0 then {} else {additionalContext: .[0], hookSpecificOutput: {hookEventName: $event, additionalContext: .[0]}} end' \
    <<< "$config" || return 1

  return 0
}

# Print the PreToolUse response for a call of the skill tool, in the same two
# places as emit-context.
# Arguments:
#   $1=[configuration JSON]
#   $2=[active mode]
#   $3=[skill name]
function emit-decision() {

  local config="$1" active="$2" skill="$3"
  jq -c -L "$JQ_MODULE_DIR" --arg active "$active" --arg skill "$skill" \
    'include "workflow-mode"; [deny_reason($skill; $active)] | if length == 0 then {} else {permissionDecision: "deny", permissionDecisionReason: .[0], hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: .[0]}} end' \
    <<< "$config" || return 1

  return 0
}

# ==============================================================================
# Configuration and state

# Print the validated configuration as JSON, or why it is invalid.
function load-config() {

  local names file doc docs="" errors out rc=0
  local -a files=("$CONFIG_FILE")
  if [[ ! -f $CONFIG_FILE ]]; then
    echo "ERROR: $CONFIG_FILE is missing. Apply loadout again to restore it." >&2
    return 2
  fi
  names="$(list-drop-ins)" || return 2
  while IFS= read -r file; do
    [[ -n $file ]] || continue
    if ! is-drop-in-name "${file##*/}"; then
      echo "ERROR: $file: drop-in file names may use only ASCII letters, digits, '.', '_' and '-', and end in .yaml or .yml." >&2
      return 2
    fi
    files+=("$file")
  done <<< "$names"
  for file in "${files[@]}"; do
    doc="$(yq -o=json 'explode(.)' "$file")" || { echo "ERROR: $file is not valid YAML." >&2; return 2; }
    # An empty file has no document, which is then reported as not a mapping
    docs="$docs${doc:-null}"$'\n'
  done
  errors="$(mktemp)" || return 2
  out="$(printf '%s' "$docs" | jq -c -s -L "$JQ_MODULE_DIR" --args 'include "workflow-mode"; config($ARGS.positional)' "${files[@]}" 2> "$errors")" || rc=$?
  if [[ $rc -ne 0 ]]; then
    out="$(< "$errors")"
    rm -f "$errors"
    echo "ERROR: ${out#jq: error (at *): }" >&2
    return 2
  fi
  rm -f "$errors"
  printf '%s\n' "$out"

  return 0
}

# Print the drop-in files, one per line in byte order of their names. Only
# regular '*.yaml' and '*.yml' files count, not dot files. A symbolic link is
# skipped with a warning, as quality gate drop-ins are. A name with a line
# break is printed as it is and then rejected as not plain ASCII.
function list-drop-ins() {

  local path
  for path in "$CONFIG_DIR"/*.yaml "$CONFIG_DIR"/*.yml; do
    if [[ -L $path ]]; then
      echo "WARNING: $path is a symbolic link, so it is skipped. Copy the file instead." >&2
    elif [[ -f $path ]]; then
      printf '%s\n' "$path"
    fi
  done | LC_ALL=C sort || return "$?"

  return 0
}

# Succeed when a drop-in file name is plain ASCII. The C locale in a subshell
# compares bytes and leaves the caller's locale alone.
# Arguments:
#   $1=[file name]
function is-drop-in-name() {

  (
    LC_ALL=C
    [[ $1 =~ $DROP_IN_PATTERN ]]
  ) || return 1

  return 0
}

# Print the installed skills as a JSON array of {name, user_only}. A skill is
# user-only when its front matter sets 'disable-model-invocation: true', so
# only the user can start it, with a slash command, and the hook never sees it.
function installed-skills() {

  local file
  local -a files=()
  for file in "$SKILLS_DIR"/*/SKILL.md; do
    if [[ -f $file ]]; then
      files+=("$file")
    fi
  done
  if [[ ${#files[@]} -eq 0 ]]; then
    echo '[]'
    return 0
  fi
  awk '
    function emit() { n = split(file, part, "/"); printf "%s\t%s\n", part[n - 1], (user ? "true" : "false") }
    FNR == 1 { if (file != "") emit(); file = FILENAME; head = ($0 == "---"); user = 0; next }
    head && $0 == "---" { head = 0 }
    head && /^disable-model-invocation:[[:space:]]*true[[:space:]]*$/ { user = 1 }
    END { if (file != "") emit() }
  ' "${files[@]}" \
    | jq -R -s -c '[split("\n")[] | select(length > 0) | split("\t") | select(.[0] | test("^[A-Za-z0-9._-]+$")) | {name: .[0], user_only: (.[1] == "true")}]' \
    || return 1

  return 0
}

# Print the path of the file that holds the mode chosen for this worktree.
function state-file() {

  local file
  file="$(git rev-parse --git-path workflow-mode)" || return 1
  printf '%s\n' "$file"

  return 0
}

# Print how the active mode is found and its name, separated by a tab:
#   chosen <name>, default <name>, no-modes, no-default,
#   undefined <chosen value>, unreadable <path> or not-a-file <path>.
# Arguments:
#   $1=[configuration JSON]
function mode-state() {

  local config="$1" file chosen=""
  file="$(state-file)" || return 1
  if [[ -e $file || -L $file ]]; then
    if [[ ! -f $file ]]; then
      printf 'not-a-file\t%s\n' "$file"
      return 0
    fi
    if [[ ! -r $file ]]; then
      printf 'unreadable\t%s\n' "$file"
      return 0
    fi
    IFS= read -r chosen < "$file" || [[ -n $chosen ]] || chosen=""
  fi
  if [[ -n $chosen ]]; then
    if [[ $chosen =~ $MODE_PATTERN ]] && jq -e --arg name "$chosen" 'any(.modes[]; .name == $name)' <<< "$config" > /dev/null; then
      printf 'chosen\t%s\n' "$chosen"
    else
      printf 'undefined\t%s\n' "$chosen"
    fi
    return 0
  fi
  jq -r 'if .default then "default\t\(.default)" elif (.modes | length) == 0 then "no-modes\t" else "no-default\t" end' <<< "$config" || return 1

  return 0
}

# Print the status for the current state of this worktree.
# Arguments:
#   $1=[configuration JSON]
function show-status() {

  local config="$1" line state value
  line="$(mode-state "$config")" || return 1
  IFS=$'\t' read -r state value <<< "$line"
  print-status "$config" "$state" "$value" || return "$?"

  return 0
}

# Print the status block for a usable state. Fail with the fix when the choice
# cannot be used.
# Arguments:
#   $1=[configuration JSON]
#   $2=[state, as printed by mode-state]
#   $3=[mode name or chosen value, as printed by mode-state]
function print-status() {

  local config="$1" state="$2" value="$3" modes
  case $state in
    chosen|default|no-modes|no-default)
      jq -r -L "$JQ_MODULE_DIR" --arg state "$state" --arg value "$value" \
        'include "workflow-mode"; status_block($state; $value)' <<< "$config" || return 1
      ;;
    undefined)
      modes="$(modes-sentence "$config")" || return 1
      # The value comes from a file, so it is printed escaped
      printf "ERROR: the workflow mode chosen for this worktree, '%q', is not defined. %s Run '%s' to choose one, or 'make workflow-clear' to return to the default.\n" "$value" "$modes" "$USE_HINT" >&2
      return 1
      ;;
    unreadable)
      echo "ERROR: cannot read the workflow mode chosen for this worktree from $value. Run 'make workflow-clear'." >&2
      return 1
      ;;
    *)
      require-state-file "$value" || return 1
      ;;
  esac

  return 0
}

# Print a sentence that names the defined modes, or says how to add some.
# Arguments:
#   $1=[configuration JSON]
function modes-sentence() {

  local config="$1"
  jq -r --arg add "$CONFIG_DIR/<name>.yaml" \
    'if (.modes | length) == 0 then "No modes are defined, add them in \($add)." else "The modes are: \([.modes[].name] | join(", "))." end' \
    <<< "$config" || return 1

  return 0
}

# Fail with the fix when the state path exists but is not a regular file.
# Arguments:
#   $1=[state file path]
function require-state-file() {

  local file="$1"
  if [[ (-e $file || -L $file) && ! -f $file ]]; then
    echo "ERROR: $file is not a file. Remove it, then run the command again." >&2
    return 1
  fi

  return 0
}

# ==============================================================================
# Tools

# Check that each tool runs, and put the mise shims first on PATH when one does
# not, as 'scripts/init.mk' does for recipes. A shim exists even when mise.toml
# is not trusted or the tool is not installed, so finding the command is not
# enough. Another program called 'yq' cannot read YAML the way mikefarah yq 4
# does.
# Arguments:
#   $@=[tool names, 'jq' or 'yq']
function prepare-tools() {

  local tool
  for tool in "$@"; do
    if tool-runs "$tool"; then
      continue
    fi
    add-mise-shims
    if ! tool-runs "$tool"; then
      if [[ $tool == yq ]]; then
        echo "ERROR: cannot run mikefarah yq version 4. Run 'mise trust' and 'make config'." >&2
      else
        echo "ERROR: cannot run $tool. Run 'mise trust' and 'make config'." >&2
      fi
      return 1
    fi
  done

  return 0
}

# Succeed when the tool runs, and for yq when it is mikefarah yq version 4.
# Arguments:
#   $1=[tool name]
function tool-runs() {

  local tool="$1" version
  version="$("$tool" --version 2>&1)" || return 1
  if [[ $tool == yq && $version != *mikefarah/yq*'version v4.'* ]]; then
    return 1
  fi

  return 0
}

# Put the mise shims directory first on PATH, when mise is installed.
function add-mise-shims() {

  local shims
  if command -v mise > /dev/null 2>&1 && shims="$(mise activate bash --shims 2> /dev/null | sed -n 's/^export PATH="\([^:]*\):.*/\1/p')" && [[ -n $shims ]]; then
    PATH="$shims:$PATH"
    export PATH
  fi

  return 0
}

# ==============================================================================

# Check whether the supplied argument represents a true boolean value.
# Arguments:
#   $1=[value to evaluate]
function is-arg-true() {

  local value="$1"
  if [[ "$value" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$ ]]; then
    return 0
  else
    return 1
  fi
}

# ==============================================================================

is-arg-true "${VERBOSE:-false}" && set -x

main "$@"

exit 0
