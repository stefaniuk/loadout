#!/bin/bash

set -euo pipefail

# SessionStart hook script that prints the spec-kit cheatsheet to the agent
# context at the beginning of every chat session.
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

function main() {

  hook_init_diagnostics "SessionStart"

  # Drain stdin (hook contract requires us to read it even if unused)
  cat >/dev/null || true

  local cheatsheet
  cheatsheet=$(cat <<'EOF'
## Spec-kit cheatsheet 🧭

Lifecycle: `/speckit.constitution` → `/speckit.specify` → `/speckit.clarify`?
  → `/speckit.plan` → `/speckit.checklist`? → `/speckit.tasks`
  → `/speckit.analyze`? → `/review.speckit-documentation`
  → `/speckit.implement` → `/review.speckit-code` → `/review.speckit-test`

Artefact types (when to use):
  - Instructions  → coding standards, file-glob-scoped rules
  - Prompts       → one-off task templates (slash commands)
  - Agents        → persistent personas, tool boundaries, handoffs
  - Skills        → reusable multi-step capabilities with assets
  - Hooks         → deterministic gates (lint/format/test)

Quality gates: always run `make lint` and `make test` before declaring done.
EOF
)

  # Emit JSON with additionalContext for VS Code Copilot SessionStart hook
  jq -n --arg context "$cheatsheet" '{additionalContext: $context}'
}

main "$@"
