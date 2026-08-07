#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/../.."

uv run --with jsonschema --with pyyaml --with wcmatch \
    python scripts/quality/validate-customisations.py "$@"

echo "customisations: ok"
