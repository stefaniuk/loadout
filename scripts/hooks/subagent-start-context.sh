#!/bin/bash

set -euo pipefail

# SubagentStart hook script that injects context for a starting subagent and
# records a JSONL event for later inspection.
#
# Reads hook context from stdin JSON, extracts identifying fields, and emits a
# hook-compatible JSON envelope on stdout with `additionalContext` describing
# the subagent and (when discoverable) the current feature directory.
#
# Usage:
#   $ echo '{"session_id":"abc","cwd":"/tmp","agent_id":"speckit.analyze"}' \
#       | ./subagent-start-context.sh
#
# Exit codes:
#   0 - Hook completed successfully (always; never blocks subagent start)
#
# Diagnostics: see ${COPILOT_PROMPT_LOG_DIR:-~/.local/state/copilot-prompts}/{hooks,errors}.log

# ==============================================================================

# shellcheck disable=SC1091
source "$(dirname "$0")/_common.sh"

# Resolve the log directory, honouring an explicit `LOG_DIR` override (used by
# the test suite) and otherwise delegating to `hook_log_dir`.
function resolve_log_dir() {

  if [[ -n "${LOG_DIR:-}" ]]; then
    mkdir -p "$LOG_DIR"
    echo "$LOG_DIR"
  else
    hook_log_dir
  fi
}

# Extract a top-level field from a JSON payload. Prefers `jq` when available
# and falls back to `python3` so the hook works on minimal environments.
# Arguments:
#   $1 - JSON payload
#   $2 - field name
function json_field() {

  local payload="$1"
  local field="$2"
  if command -v jq >/dev/null 2>&1; then
    echo "$payload" | jq -r --arg f "$field" '.[$f] // empty'
  else
    echo "$payload" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('$field',''))"
  fi
}

# Discover the most recently modified feature directory under `.specify/specs/`
# if one exists. Echoes "unknown" when no candidate is found.
function discover_feature_dir() {

  local specs_dir=".specify/specs"
  if [[ ! -d "$specs_dir" ]]; then
    echo "unknown"
    return 0
  fi
  local latest
  latest=$(find "$specs_dir" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null \
    | xargs -0 -I{} stat -f '%m %N' "{}" 2>/dev/null \
    | sort -nr \
    | head -n1 \
    | cut -d' ' -f2-)
  if [[ -z "$latest" ]]; then
    # Fallback for systems without BSD `stat`.
    latest=$(find "$specs_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -n1)
  fi
  if [[ -z "$latest" ]]; then
    echo "unknown"
  else
    echo "$latest"
  fi
}

function main() {

  hook_init_diagnostics "SubagentStart"

  local input
  input=$(cat)

  local session_id
  session_id=$(json_field "$input" "session_id")
  local agent_id
  agent_id=$(json_field "$input" "agent_id")
  if [[ -z "$agent_id" ]]; then
    agent_id=$(json_field "$input" "agent_type")
  fi
  [[ -z "$agent_id" ]] && agent_id="unknown"
  [[ -z "$session_id" ]] && session_id="unknown"

  local feature_dir
  feature_dir=$(discover_feature_dir)

  local context
  context="Subagent ${agent_id} starting. Feature dir: ${feature_dir}. Parent session: ${session_id}."

  local log_dir
  log_dir=$(resolve_log_dir)
  local log_file="${log_dir}/subagent-events.jsonl"
  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  if command -v jq >/dev/null 2>&1; then
    jq -nc \
      --arg ts "$ts" \
      --arg agent_id "$agent_id" \
      --arg session_id "$session_id" \
      --arg event "start" \
      --arg feature_dir "$feature_dir" \
      '{timestamp: $ts, event: $event, agent_id: $agent_id, session_id: $session_id, feature_dir: $feature_dir}' \
      >>"$log_file"
    jq -nc \
      --arg event "SubagentStart" \
      --arg context "$context" \
      '{hookSpecificOutput: {hookEventName: $event, additionalContext: $context}}'
  else
    LOG_FILE="$log_file" TS="$ts" AGENT_ID="$agent_id" SESSION_ID="$session_id" \
      FEATURE_DIR="$feature_dir" CONTEXT="$context" \
      python3 -c '
import json, os
record = {
  "timestamp": os.environ["TS"],
  "event": "start",
  "agent_id": os.environ["AGENT_ID"],
  "session_id": os.environ["SESSION_ID"],
  "feature_dir": os.environ["FEATURE_DIR"],
}
with open(os.environ["LOG_FILE"], "a") as f:
  f.write(json.dumps(record) + "\n")
print(json.dumps({"hookSpecificOutput": {"hookEventName": "SubagentStart", "additionalContext": os.environ["CONTEXT"]}}))
'
  fi

  return 0
}

main "$@"

exit 0
