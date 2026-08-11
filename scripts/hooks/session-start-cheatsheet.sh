#!/bin/bash

set -euo pipefail

# SessionStart hook script that prints the active workflow cheatsheet to the
# agent context at the beginning of every chat session.
#
# Reads hook context from stdin JSON, emits a hook-compatible JSON envelope on
# stdout whose `additionalContext` field contains the cheatsheet markdown.
#
# Usage:
#   $ echo '{}' | ./session-start-cheatsheet.sh
#
# Exit codes:
#   0 - Hook completed successfully
#
# Diagnostics: see ${COPILOT_PROMPT_LOG_DIR:-~/.local/state/copilot-prompts}/{hooks,errors}.log

# ==============================================================================

# shellcheck disable=SC1091
source "$(dirname "$0")/_common.sh"
# shellcheck disable=SC1091
source "$(dirname "$0")/workflow-mode.lib.sh"

# Render the Spec Kit session banner.
# Echoes markdown on stdout.
function render-speckit-cheatsheet() {

  cat <<'EOF'
## Spec-kit cheatsheet 🧭

Lifecycle: `/speckit-constitution` → `/speckit-specify` → `/speckit-clarify`?
  → `/speckit-plan` → `/speckit-checklist`? → `/speckit-tasks`
  → `/speckit-analyze`? → `/review.speckit-documentation`
  → `/speckit-implement` → `/review.speckit-code` → `/review.speckit-test`

Artefact types (when to use):
  - Instructions  → coding standards, file-glob-scoped rules
  - Prompts       → one-off task templates (slash commands)
  - Agents        → optional custom agents, tool boundaries, handoffs
  - Skills        → reusable multi-step capabilities with assets
  - Hooks         → deterministic gates (lint/format/test)

Quality gates: always run `make lint` and `make test` before declaring done.
EOF

  return 0
}

# Render the Superpowers session banner.
# Echoes markdown on stdout.
function render-superpowers-cheatsheet() {

  cat <<'EOF'
## Superpowers cheatsheet 🧭

Standalone workflow: `/brainstorming` → `/writing-plans`
  → `/executing-plans` or `/subagent-driven-development`

Review loop:
  - `/requesting-code-review`
  - `/receiving-code-review`

Optional helpers:
  - `/dispatching-parallel-agents`
  - `/finishing-a-development-branch`

Cross-cutting skills:
  - `/systematic-debugging`
  - `/test-driven-development`
  - `/verification-before-completion`
  - `/using-git-worktrees`

Guardrail: use one workflow family per session. When Superpowers mode is active,
do not use `/speckit-*` commands in the same session.

Quality gates: always run `make lint` and `make test` before declaring done.
EOF

  return 0
}

function main() {

  hook_init_diagnostics "SessionStart"

  # Drain stdin (hook contract requires us to read it even if unused)
  cat >/dev/null || true

  local workflow_mode
  workflow_mode="$(workflow-mode-read)"

  local cheatsheet
  if [[ "${workflow_mode}" == "superpowers" ]]; then
    cheatsheet="$(render-superpowers-cheatsheet)"
  else
    cheatsheet="$(render-speckit-cheatsheet)"
  fi

  # Emit JSON with additionalContext for VS Code Copilot SessionStart hook
  jq -n --arg context "$cheatsheet" '{additionalContext: $context}'

  return 0
}

main "$@"
