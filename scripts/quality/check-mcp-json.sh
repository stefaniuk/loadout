#!/bin/bash

set -euo pipefail

# Validate JSON syntax of every .vscode/*.example MCP configuration file.
#
# Usage:
#   $ ./scripts/quality/check-mcp-json.sh
#
# Exit codes:
#   0 - All .example files under .vscode/ parsed as valid JSON
#   1 - One or more files failed to parse (offending path printed to stderr)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "${REPO_ROOT}"

shopt -s nullglob
files=(.vscode/*.example)
shopt -u nullglob

if (( ${#files[@]} == 0 )); then
  echo "mcp-json: ok (no .vscode/*.example files found)"
  exit 0
fi

status=0
for f in "${files[@]}"; do
  if ! python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "${f}" 2>/dev/null; then
    echo "mcp-json: invalid JSON in ${f}" >&2
    status=1
  fi
done

if (( status != 0 )); then
  exit "${status}"
fi

echo "mcp-json: ok"
exit 0
