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

# Compute a stable path for the per-repo working-tree snapshot used to detect
# whether the current turn modified any files. The snapshot is stored in the
# diagnostics log directory keyed by an absolute-path hash so concurrent
# repositories do not collide.
# Echoes the absolute snapshot file path on stdout.
function hook_tree_snapshot_path() {

  local log_dir
  log_dir="$(hook_log_dir)"

  local repo_root
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

  local key
  if command -v shasum >/dev/null 2>&1; then
    key="$(printf '%s' "$repo_root" | shasum | awk '{print $1}')"
  else
    key="$(printf '%s' "$repo_root" | cksum | awk '{print $1}')"
  fi

  echo "${log_dir}/turn-snapshot.${key}"
}

# Compute a fingerprint of the current working tree (untracked + staged +
# unstaged) so two snapshots can be compared cheaply. Echoes the hex digest on
# stdout. Returns the literal string "no-git" when not inside a git repo.
function hook_tree_fingerprint() {

  if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
    echo "no-git"
    return 0
  fi

  local hasher
  if command -v shasum >/dev/null 2>&1; then
    hasher="shasum"
  else
    hasher="cksum"
  fi

  { git status --porcelain=v1 2>/dev/null; git diff --no-color 2>/dev/null; \
    git diff --cached --no-color 2>/dev/null; } \
    | "$hasher" | awk '{print $1}'
}
