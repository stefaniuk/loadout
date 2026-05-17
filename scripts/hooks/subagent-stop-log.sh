#!/bin/bash

set -euo pipefail

# SubagentStop hook script that records a JSONL event when a subagent stops.
# Informational only; never blocks. Mirrors the recording style of
# user-prompt-record.sh.
#
# Reads hook context from stdin JSON. Recognised fields: `session_id`,
# `agent_id`, `agent_type`, `stop_hook_active`.
#
# Usage:
#   $ echo '{"session_id":"abc","agent_id":"planner"}' | ./subagent-stop-log.sh
#
# Exit codes:
#   0 - Hook completed successfully (always)
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

# Extract a top-level field from a JSON payload. Prefers `jq` and falls back
# to `python3` so the hook works on minimal environments.
# Arguments:
#   $1 - JSON payload
#   $2 - field name
function json_field() {

  local payload="$1"
  local field="$2"
  if command -v jq >/dev/null 2>&1; then
    echo "$payload" | jq -r --arg f "$field" '.[$f] // empty'
  else
    printf '%s' "$payload" | FIELD="$field" python3 -c 'import json, os, sys; d = json.load(sys.stdin); print(d.get(os.environ["FIELD"], ""))'
  fi
}

function main() {

  hook_init_diagnostics "SubagentStop"

  local input
  input=$(cat)

  local session_id
  session_id=$(json_field "$input" "session_id")
  local agent_id
  agent_id=$(json_field "$input" "agent_id")
  if [[ -z "$agent_id" ]]; then
    agent_id=$(json_field "$input" "agent_type")
  fi
  local stop_hook_active
  stop_hook_active=$(json_field "$input" "stop_hook_active")

  [[ -z "$agent_id" ]] && agent_id="unknown"
  [[ -z "$session_id" ]] && session_id="unknown"
  [[ -z "$stop_hook_active" ]] && stop_hook_active="false"

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
      --arg event "stop" \
      --arg stop_hook_active "$stop_hook_active" \
      '{timestamp: $ts, event: $event, agent_id: $agent_id, session_id: $session_id, stop_hook_active: $stop_hook_active}' \
      >>"$log_file"
  else
    LOG_FILE="$log_file" TS="$ts" AGENT_ID="$agent_id" SESSION_ID="$session_id" \
      STOP_HOOK_ACTIVE="$stop_hook_active" \
      python3 -c '
import json, os
record = {
  "timestamp": os.environ["TS"],
  "event": "stop",
  "agent_id": os.environ["AGENT_ID"],
  "session_id": os.environ["SESSION_ID"],
  "stop_hook_active": os.environ["STOP_HOOK_ACTIVE"],
}
with open(os.environ["LOG_FILE"], "a") as f:
  f.write(json.dumps(record) + "\n")
'
  fi

  echo '{}'
  return 0
}

main "$@"

exit 0
