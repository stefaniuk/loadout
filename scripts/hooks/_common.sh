#!/bin/bash

# Shared diagnostics helpers for VS Code Agent hook scripts.
#
# Source this file at the top of every hook script:
#
#   source "$(dirname "$0")/_common.sh"
#   hook_init_diagnostics "<hook-event-name>"
#
# After init, stderr from the calling script is appended to a sibling
# `errors.log` so set -e exits, jq parse errors, and missing dependencies
# leave an inspectable trail. Each invocation also appends a one-line marker
# to `hooks.log` so it is possible to see whether a hook fired at all.
#
# Log location (first match wins):
#   1. $COPILOT_PROMPT_LOG_DIR  (explicit override)
#   2. $XDG_STATE_HOME/copilot-prompts
#   3. $HOME/.local/state/copilot-prompts

# ==============================================================================

# Resolve and create the diagnostics log directory.
# Echoes the absolute path on stdout. Safe to call multiple times.
function hook_log_dir() {

  local log_dir
  if [[ -n "${COPILOT_PROMPT_LOG_DIR:-}" ]]; then
    log_dir="$COPILOT_PROMPT_LOG_DIR"
  elif [[ -n "${XDG_STATE_HOME:-}" ]]; then
    log_dir="$XDG_STATE_HOME/copilot-prompts"
  else
    log_dir="$HOME/.local/state/copilot-prompts"
  fi
  mkdir -p "$log_dir"
  echo "$log_dir"
}

# Initialise diagnostics for the calling hook.
# Arguments:
#   $1 - hook event name (e.g. "PostToolUse", "Stop")
#
# Side effects:
#   - Creates the diagnostics directory if needed.
#   - Redirects this shell's stderr to ${log_dir}/errors.log so subsequent
#     command failures and `set -e` exits leave a trail.
#   - Appends one line to ${log_dir}/hooks.log marking the invocation.
function hook_init_diagnostics() {

  local event="${1:-unknown}"
  local log_dir
  log_dir="$(hook_log_dir)"

  exec 2>>"${log_dir}/errors.log"

  printf '[%s] %s pid=%s cwd=%s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "$event" \
    "$$" \
    "$(pwd)" \
    >>"${log_dir}/hooks.log"
}

# Append a free-form diagnostic line to errors.log with a timestamp prefix.
# Use this from hook code to record schema mismatches or unexpected branches.
# Arguments:
#   $@ - message tokens (joined with spaces)
function hook_diag() {

  printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >&2
}
