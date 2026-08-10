#!/bin/bash
# shellcheck disable=SC2329

set -euo pipefail

# Test suite for the external skill sync patching workflow.
#
# Usage:
#   $ ./scripts/tests/skill-sync.test.sh
#
# Arguments (provided as environment variables):
#   VERBOSE=true  # Show all the executed commands, default is 'false'

# ==============================================================================

TEMP_DIR=""
REPO_ROOT=""

function main() {

  REPO_ROOT="$(git rev-parse --show-toplevel)"
  cd "${REPO_ROOT}"

  test-skill-sync-suite-setup
  trap test-skill-sync-suite-teardown EXIT INT TERM

  local tests=( \
    test-skill-sync-copies-skills-without-patches \
    test-skill-sync-applies-default-skill-patch \
    test-skill-sync-applies-per-skill-replacement-patch \
    test-skill-sync-skips-patches-when-patch-false \
  )
  local status=0

  for test in "${tests[@]}"; do
    {
      echo -n "$test"
      # shellcheck disable=SC2015
      $test && echo " PASS" || { echo " FAIL"; status=$((status + 1)); }
    }
  done

  echo "Total: ${#tests[@]}, Passed: $(( ${#tests[@]} - status )), Failed: $status"

  return ${status}
}

# ==============================================================================

function test-skill-sync-suite-setup() {

  TEMP_DIR=$(mktemp -d)

  return 0
}

function test-skill-sync-suite-teardown() {

  if [[ -n "${TEMP_DIR}" ]] && [[ -d "${TEMP_DIR}" ]]; then
    rm -rf "${TEMP_DIR}"
  fi

  return 0
}

# Create a temporary repository fixture for exercising scripts/skill-sync.sh.
# Arguments:
#   $1=[fixture directory]
function create-skill-sync-fixture-repo() {

  local fixture_dir="$1"
  local upstream_dir="${fixture_dir}/upstream-skills"

  mkdir -p "${fixture_dir}/scripts/config"
  mkdir -p "${fixture_dir}/scripts/skill-patches/skills"
  mkdir -p "${fixture_dir}/bin"

  cp "${REPO_ROOT}/scripts/skill-sync.sh" "${fixture_dir}/scripts/skill-sync.sh"
  cp "${REPO_ROOT}/scripts/skill-patches/patch.lib.sh" "${fixture_dir}/scripts/skill-patches/patch.lib.sh"

  create-skill-sync-config "${fixture_dir}" "${upstream_dir}"
  create-skill-sync-manifest "${fixture_dir}"
  create-skill-sync-patches "${fixture_dir}"
  create-yq-stub "${fixture_dir}/bin/yq"
  create-upstream-skill-repo "${upstream_dir}"

  chmod +x "${fixture_dir}/scripts/skill-sync.sh" "${fixture_dir}/bin/yq"

  return 0
}

# Create the external skills manifest consumed by the sync script.
# Arguments:
#   $1=[fixture directory]
function create-skill-sync-config() {

  local fixture_dir="$1"
  local upstream_dir="$2"

  cat <<EOF > "${fixture_dir}/scripts/config/skills.yaml"
{
  "skills": [
    {
      "name": "vanilla-skill",
      "repo": "${upstream_dir}",
      "path": "skills/vanilla-skill",
      "ref": "main"
    },
    {
      "name": "additive-skill",
      "repo": "${upstream_dir}",
      "path": "skills/additive-skill",
      "ref": "main"
    },
    {
      "name": "incremental-implementation",
      "repo": "${upstream_dir}",
      "path": "skills/incremental-implementation",
      "ref": "main"
    }
  ]
}
EOF

  return 0
}

# Create the local patch manifest for external skills.
# Arguments:
#   $1=[fixture directory]
function create-skill-sync-manifest() {

  local fixture_dir="$1"

  cat <<'EOF' > "${fixture_dir}/scripts/skill-patches/manifest.yaml"
defaults:
  skills: after-frontmatter

overrides:
  incremental-implementation/SKILL.md: replace-before-section:## See Also
EOF

  return 0
}

# Create patch fragments that will be injected into synced skills.
# Arguments:
#   $1=[fixture directory]
function create-skill-sync-patches() {

  local fixture_dir="$1"

  cat <<'EOF' > "${fixture_dir}/scripts/skill-patches/skills/additive-skill.patch.md"
## Local Patch

This line should be injected after the front matter.
EOF

  cat <<'EOF' > "${fixture_dir}/scripts/skill-patches/skills/incremental-implementation.patch.md"
# Incremental Implementation

## Overview

Patched overview for Spec Kit compatibility.

## Verification

- Verify against the existing task list.
EOF

  return 0
}

# Create a tiny yq-compatible stub that handles both JSON and simple YAML.
# Arguments:
#   $1=[stub path]
function create-yq-stub() {

  local stub_path="$1"

  cat <<'EOF' > "${stub_path}"
#!/usr/bin/env python3

import json
import re
import sys
from pathlib import Path


def load_file(path: str):
    text = Path(path).read_text(encoding="utf-8")
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        return _parse_simple_yaml(text)


def _parse_simple_yaml(text: str):
    """Minimal YAML parser for flat manifests (no arrays, no nesting beyond one level)."""
    result = {}
    stack = [result]
    prev_indent = -1
    keys = [""]
    for line in text.splitlines():
        stripped = line.lstrip()
        if not stripped or stripped.startswith("#"):
            continue
        indent = len(line) - len(stripped)
        if ":" not in stripped:
            continue
        key, _, val = stripped.partition(":")
        key = key.strip()
        val = val.strip()
        while indent <= prev_indent and len(stack) > 1:
            stack.pop()
            keys.pop()
            prev_indent -= 2
        if val:
            stack[-1][key] = val
        else:
            new_dict = {}
            stack[-1][key] = new_dict
            stack.append(new_dict)
            keys.append(key)
            prev_indent = indent
    return result


def dump_json(path: str, payload):
    Path(path).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def query_value(query: str, payload):
    if query == ".skills | length":
        return str(len(payload["skills"]))

    if query == ".skills[].name":
        return "\n".join(item["name"] for item in payload["skills"])

    match = re.fullmatch(r'\.skills\[(\d+)\]\.([A-Za-z0-9_-]+)(?: // "([^"]+)")?', query)
    if match:
        index = int(match.group(1))
        key = match.group(2)
        default = match.group(3)
        value = payload["skills"][index].get(key)
        if value is None:
            value = default if default is not None else ""
        return str(value)

    match = re.fullmatch(r'\.overrides\."([^"]+)" // ""', query)
    if match:
        return payload.get("overrides", {}).get(match.group(1), "")

    if query in {'.defaults.skills // ""', '.defaults."skills" // ""'}:
        return payload.get("defaults", {}).get("skills", "")

    raise SystemExit(f"unsupported query: {query}")


def apply_update(query: str, payload):
    match = re.fullmatch(
        r'\.skills\[(\d+)\]\.ref = "([^"]+)" \| \.skills\[\1\]\.sha = "([^"]+)"',
        query,
    )
    if not match:
        raise SystemExit(f"unsupported update: {query}")

    index = int(match.group(1))
    payload["skills"][index]["ref"] = match.group(2)
    payload["skills"][index]["sha"] = match.group(3)


def main():
    args = sys.argv[1:]
    if not args:
      raise SystemExit("missing query")

    raw = False
    inplace = False
    while args and args[0].startswith("-"):
        flag = args.pop(0)
        if flag == "-r":
            raw = True
        elif flag == "-i":
            inplace = True
        else:
            raise SystemExit(f"unsupported flag: {flag}")

    if len(args) != 2:
        raise SystemExit("usage: yq [flags] <query> <file>")

    query, path = args
    payload = load_file(path)

    if inplace:
        apply_update(query, payload)
        dump_json(path, payload)
        return

    result = query_value(query, payload)
    if raw:
        sys.stdout.write(result)
    else:
        sys.stdout.write(result)


if __name__ == "__main__":
    main()
EOF

  return 0
}

# Create a local git repository that acts as the upstream external skill source.
# Arguments:
#   $1=[upstream repository directory]
function create-upstream-skill-repo() {

  local upstream_dir="$1"

  mkdir -p "${upstream_dir}/skills/vanilla-skill"
  mkdir -p "${upstream_dir}/skills/additive-skill"
  mkdir -p "${upstream_dir}/skills/incremental-implementation"

  cat <<'EOF' > "${upstream_dir}/skills/vanilla-skill/SKILL.md"
---
name: vanilla-skill
description: Use when copying a skill without a local patch.
---

# Vanilla Skill

Original content.
EOF

  cat <<'EOF' > "${upstream_dir}/skills/additive-skill/SKILL.md"
---
name: additive-skill
description: Use when testing the default after-frontmatter injection.
---

# Additive Skill

Original additive content.
EOF

  cat <<'EOF' > "${upstream_dir}/skills/incremental-implementation/SKILL.md"
---
name: incremental-implementation
description: Use when testing local skill replacement.
---

# Incremental Implementation

Original content that should be replaced.

## See Also

Keep this trailing section from upstream.
EOF

  git -C "${upstream_dir}" init --initial-branch=main > /dev/null 2>&1
  git -C "${upstream_dir}" config user.name "Fixture"
  git -C "${upstream_dir}" config user.email "fixture@example.com"
  git -C "${upstream_dir}" add .
  git -C "${upstream_dir}" commit -m "fixture" > /dev/null 2>&1

  return 0
}

# Run scripts/skill-sync.sh inside a fixture repository.
# Arguments:
#   $1=[fixture name]
#   $2=[patch flag value]
# Returns:
#   Fixture directory path (via stdout)
function run-skill-sync-fixture() {

  local fixture_name="$1"
  local patch_flag="${2:-true}"
  local fixture_dir="${TEMP_DIR}/${fixture_name}"

  create-skill-sync-fixture-repo "${fixture_dir}"

  PATH="${fixture_dir}/bin:${PATH}" \
    patch="${patch_flag}" \
    "${fixture_dir}/scripts/skill-sync.sh" > "${fixture_dir}/run.log" 2>&1

  echo "${fixture_dir}"

  return 0
}

# ==============================================================================

function test-skill-sync-copies-skills-without-patches() {

  local fixture_dir
  fixture_dir=$(run-skill-sync-fixture "vanilla-copy")

  grep -qF "Original content." "${fixture_dir}/.github/skills/vanilla-skill/SKILL.md" || return 1
  ! grep -qF "Local Patch" "${fixture_dir}/.github/skills/vanilla-skill/SKILL.md" || return 1

  return 0
}

function test-skill-sync-applies-default-skill-patch() {

  local fixture_dir
  fixture_dir=$(run-skill-sync-fixture "default-patch")

  grep -qF "This line should be injected after the front matter." "${fixture_dir}/.github/skills/additive-skill/SKILL.md" || return 1

  local skill_file="${fixture_dir}/.github/skills/additive-skill/SKILL.md"
  local patch_line
  local heading_line
  patch_line=$(grep -nF "This line should be injected after the front matter." "${skill_file}" | cut -d: -f1)
  heading_line=$(grep -nF "# Additive Skill" "${skill_file}" | cut -d: -f1)
  [[ -n "${patch_line}" ]] || return 1
  [[ -n "${heading_line}" ]] || return 1
  [[ "${patch_line}" -lt "${heading_line}" ]] || return 1

  return 0
}

function test-skill-sync-applies-per-skill-replacement-patch() {

  local fixture_dir
  fixture_dir=$(run-skill-sync-fixture "replacement-patch")

  grep -qF "Patched overview for Spec Kit compatibility." "${fixture_dir}/.github/skills/incremental-implementation/SKILL.md" || return 1
  ! grep -qF "Original content that should be replaced." "${fixture_dir}/.github/skills/incremental-implementation/SKILL.md" || return 1
  grep -qF "Keep this trailing section from upstream." "${fixture_dir}/.github/skills/incremental-implementation/SKILL.md" || return 1

  return 0
}

function test-skill-sync-skips-patches-when-patch-false() {

  local fixture_dir
  fixture_dir=$(run-skill-sync-fixture "bypass" "false")

  grep -qF "Original content that should be replaced." "${fixture_dir}/.github/skills/incremental-implementation/SKILL.md" || return 1
  ! grep -qF "Patched overview for Spec Kit compatibility." "${fixture_dir}/.github/skills/incremental-implementation/SKILL.md" || return 1

  return 0
}

# ==============================================================================

function is-arg-true() {

  if [[ "$1" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$ ]]; then
    return 0
  else
    return 1
  fi
}

# ==============================================================================

is-arg-true "${VERBOSE:-false}" && set -x

if main "$@"; then
  exit 0
fi

exit 1
