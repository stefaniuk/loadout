---
applyTo: "**/*.{sh,bash,zsh}"
description: "Shell Script Engineering Instructions (Bash, CLI wrappers, automation)"
---

# Shell Script Engineering Instructions (Bash, CLI wrappers, automation) 🐚

These instructions define the default engineering approach for writing **production-grade shell scripts** in Bash.

They must remain applicable to:

- Standalone CLI utility scripts
- Git hook scripts
- CI/CD pipeline scripts
- Tool wrapper scripts (native/Docker dual execution)
- Library scripts sourced by other scripts
- Report generation and automation scripts

They are **non-negotiable** unless an exception is explicitly documented (with rationale and expiry) in an ADR/decision record.

**Cross-references.** For Makefile orchestration conventions that call shell scripts, see [makefile.instructions.md](./makefile.instructions.md). This file focuses exclusively on shell script patterns.

**Identifier scheme.** Every normative rule carries a unique tag in the form `[SH-<prefix>-NNN]`, where the prefix maps to the containing section (for example `QR` for Quick Reference, `HDR` for Header, `FN` for Functions, `VAR` for Variables, `ERR` for Error Handling, `DOC` for Documentation). Use these identifiers when referencing, planning, or validating requirements.

---

## 0. Quick reference (apply first) 🧠

This section exists so humans and AI assistants can reliably apply the most important rules even when context is tight.

- [SH-QR-001] **Shebang and safety**: start with `#!/bin/bash` and `set -euo pipefail` ([SH-HDR-001], [SH-HDR-003]).
- [SH-QR-002] **Header structure**: include WARNING comment, safety options, description block, and section dividers ([SH-HDR-002], [SH-HDR-004]).
- [SH-QR-003] **`main()` entry point**: use a `main()` function as the script entry point, called at the bottom of the file ([SH-FN-001]).
- [SH-QR-004] **Kebab-case functions**: name functions using `kebab-case` (lowercase with hyphens) ([SH-FN-002]).
- [SH-QR-005] **Document all functions**: provide comment blocks describing purpose and arguments ([SH-DOC-001]–[SH-DOC-004]).
- [SH-QR-006] **Native/Docker dual execution**: scripts should run tools natively if installed, or fall back to Docker ([SH-EXEC-001]–[SH-EXEC-005]).
- [SH-QR-007] **`is-arg-true()` helper**: use a standard boolean-parsing helper for environment flags ([SH-VAR-006]).
- [SH-QR-008] **VERBOSE toggle**: support `VERBOSE=true` to enable `set -x` for debugging ([SH-DBG-001]–[SH-DBG-003]).
- [SH-QR-009] **Exit 0 at end**: scripts must end with `exit 0` after successful execution ([SH-ERR-005]).
- [SH-QR-010] **Test suite patterns**: use Arrange-Act-Assert structure, setup/teardown functions, and summary reporting ([SH-TST-001]–[SH-TST-015]).
- [SH-QR-011] **Avoid common anti-patterns**: unquoted variables, `cd` without error handling, hardcoded paths (§12).
- [SH-QR-012] **Explicit returns**: finish every function with an explicit `return <status>` so intent and requirements stay aligned ([SH-FN-008]).

---

## 1. Operating principles 🧭

These principles extend [constitution.md §3](../../.specify/memory/constitution.md#3-core-principles-non-negotiable).

- [SH-OP-001] Treat scripts as **contracts**: stable interfaces for developers and CI/CD pipelines.
- [SH-OP-002] Prefer **small, explicit, testable** changes over broad rewrites.
- [SH-OP-003] Design for **determinism**: the same inputs and environment produce the same outputs.
- [SH-OP-004] Scripts are for **orchestration and automation**. Complex business logic belongs elsewhere.
- [SH-OP-005] **Fail fast and fail loud**: errors must not be hidden or ignored.
- [SH-OP-006] Optimise for **readability, maintainability, and debugging**, not cleverness.
- [SH-OP-007] Scripts must be **independently runnable** for debugging and testing purposes.

---

## 2. Header structure (non-negotiable) 📋

Every script must begin with a consistent header structure that makes the script self-documenting.

### 2.1 Shebang and safety options

- [SH-HDR-001] The first line must be `#!/bin/bash` (or `#!/usr/bin/env bash` for portability where required).
- [SH-HDR-002] Include `set -euo pipefail` immediately after the warning (or shebang if no warning):
  - `-e`: Exit immediately if any command returns non-zero
  - `-u`: Exit if an uninitialised variable is used
  - `-o pipefail`: Pipeline returns the exit status of the first failing command

### 2.2 Description block

- [SH-HDR-003] After the safety options, include a description block with:
  - One-line summary of the script's purpose
  - Usage example
  - Arguments/Options section documenting environment variables
  - Exit codes section (when applicable)
  - Notes section (when applicable)

Example:

```bash
#!/bin/bash

set -euo pipefail

# Pre-commit git hook to check the Markdown file formatting rules compliance
# over changed files. This is a markdownlint command wrapper. It will run
# markdownlint natively if it is installed, otherwise it will run it in a Docker
# container.
#
# Usage:
#   $ [options] ./check-markdown-format.sh
#
# Options:
#   check={all,staged-changes,working-tree-changes,branch}  # Check mode, default is 'working-tree-changes'
#   BRANCH_NAME=other-branch-than-main                      # Branch to compare with, default is `origin/main`
#   FORCE_USE_DOCKER=true                                   # If set to true the command is run in a Docker container, default is 'false'
#   VERBOSE=true                                            # Show all the executed commands, default is `false`
#
# Exit codes:
#   0 - All files are formatted correctly
#   1 - Files are not formatted correctly
#
# Notes:
#   1) Please make sure to enable Markdown linting in your IDE.
```

### 2.3 Section dividers

- [SH-HDR-004] Use visual section dividers to separate major sections of the script:

  ```bash
  # ==============================================================================
  ```

- [SH-HDR-005] Typical sections include:
  - Main function section (after header)
  - Helper functions section
  - `is-arg-true()` utility section
  - Script invocation section (VERBOSE toggle and main call)

---

## 3. Function conventions 🔧

### 3.1 Entry point pattern

- [SH-FN-001] Use a `main()` function as the script's entry point:

  ```bash
  function main() {
    cd "$(git rev-parse --show-toplevel)"
    # Script logic here...
  }
  ```

- [SH-FN-002] Name functions using **kebab-case** (lowercase with hyphens):
  - ✅ `run-shellcheck-natively`
  - ✅ `docker-get-image-version`
  - ✅ `create-report`
  - ❌ `runShellcheckNatively` (camelCase)
  - ❌ `run_shellcheck_natively` (snake_case)

- [SH-FN-003] Use the `function` keyword for function definitions:

  ```bash
  function some-function() {
    # Implementation...
  }
  ```

### 3.2 Function organisation

- [SH-FN-004] Order functions logically:
  1. `main()` function first
  2. Primary workflow functions
  3. Execution variant functions (native/Docker)
  4. Helper/utility functions
  5. `is-arg-true()` last (before invocation)

- [SH-FN-005] Keep functions focused on a single responsibility.
- [SH-FN-006] Functions should be small enough to fit on one screen (~30–50 lines maximum).

### 3.3 Explicit return statements

- [SH-FN-007] End every function with an explicit `return` (usually `return 0` for success, or a non-zero value for failures) so static analysis tools can determine the intended exit status and humans can see the control flow clearly. Do not rely on implicit fall-through to provide the exit code.

### 3.4 Dual execution pattern (native vs Docker)

- [SH-FN-008] For tool wrapper scripts, implement paired execution functions:
  - `run-<tool>-natively` — runs the tool if installed locally
  - `run-<tool>-in-docker` — runs the tool in a Docker container

Example:

```bash
function main() {
  if command -v shellcheck > /dev/null 2>&1 && ! is-arg-true "${FORCE_USE_DOCKER:-false}"; then
    run-shellcheck-natively
  else
    run-shellcheck-in-docker
  fi
}
```

---

## 4. Variable and argument conventions 📝

### 4.1 Naming conventions

- [SH-VAR-001] Use **UPPERCASE** for global/environment variables:
  - `VERBOSE`, `FORCE_USE_DOCKER`, `BRANCH_NAME`, `BUILD_DATETIME`

- [SH-VAR-002] Use **lowercase** for local function arguments and loop variables:
  - `file`, `dir`, `check`, `files`, `image`

- [SH-VAR-003] Declare local variables with `local`:

  ```bash
  function some-function() {
    local dir=${dir:-$PWD}
    local file=${file:-./Dockerfile.effective}
    # ...
  }
  ```

### 4.2 Default values

- [SH-VAR-004] Use parameter expansion for default values:

  ```bash
  local dir=${dir:-$PWD}
  local check=${check:-working-tree-changes}
  ```

- [SH-VAR-005] Document default values in the header Options/Arguments section.

### 4.3 Boolean parsing helper

- [SH-VAR-006] Use the standard `is-arg-true()` helper for boolean environment flags:

  ```bash
  function is-arg-true() {
    if [[ "$1" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$ ]]; then
      return 0
    else
      return 1
    fi
  }
  ```

- [SH-VAR-007] Usage pattern for boolean checks:

  ```bash
  if ! is-arg-true "${FORCE_USE_DOCKER:-false}"; then
    run-tool-natively
  else
    run-tool-in-docker
  fi
  ```

---

## 5. Documentation conventions 📖

### 5.1 Function documentation

- [SH-DOC-001] Document every function with a comment block above it:

  ```bash
  # Run hadolint natively.
  # Arguments (provided as environment variables):
  #   file=[path to the Dockerfile to lint, relative to the project's top-level directory]
  function run-hadolint-natively() {
    # ...
  }
  ```

- [SH-DOC-002] For functions that accept arguments via environment variables, use the format:
  - `#   varname=[description]`
  - `#   varname=[description, default is 'value']`

- [SH-DOC-003] For library functions that set up environment, document the expected variables:

  ```bash
  # Arguments (provided as environment variables):
  #   DOCKER_IMAGE=ghcr.io/org/repo             # Docker image name
  #   DOCKER_TITLE="My Docker image"            # Docker image title
  #   TOOL_VERSIONS=$project_dir/.tool-versions # Path to the tool versions file
  ```

### 5.2 Inline comments

- [SH-DOC-004] Use inline comments sparingly to explain non-obvious logic:

  ```bash
  # shellcheck disable=SC2086
  docker run --rm --platform linux/amd64 \
    ${args:-} \
    "${tag}"
  ```

- [SH-DOC-005] When disabling shellcheck warnings, always use the directive comment:

  ```bash
  # shellcheck disable=SC2155
  local image=$(name=ghcr.io/make-ops-tools/gocloc docker-get-image-version-and-pull)
  ```

---

## 6. Execution model and script structure 🏗️

### 6.1 Dual execution architecture

- [SH-EXEC-001] Tool wrapper scripts should support both native and Docker execution modes.
- [SH-EXEC-002] Check for native tool availability using `command -v`:

  ```bash
  if command -v toolname > /dev/null 2>&1; then
    run-toolname-natively
  else
    run-toolname-in-docker
  fi
  ```

- [SH-EXEC-003] Respect `FORCE_USE_DOCKER=true` to force Docker execution even when native tool exists.
- [SH-EXEC-004] For Docker execution, source the shared Docker library:

  ```bash
  # shellcheck disable=SC1091
  source ./scripts/docker/docker.lib.sh
  ```

- [SH-EXEC-005] Use consistent Docker run patterns:

  ```bash
  docker run --rm --platform linux/amd64 \
    --volume "$PWD":/workdir \
    "$image" \
      command arguments
  ```

### 6.2 Directory handling

- [SH-EXEC-006] Navigate to the repository root at the start of `main()`:

  ```bash
  function main() {
    cd "$(git rev-parse --show-toplevel)"
    # ...
  }
  ```

- [SH-EXEC-007] Use relative paths from the repository root for consistency.

### 6.3 Script invocation section

- [SH-EXEC-008] At the bottom of the script, include the invocation section:

  ```bash
  # ==============================================================================

  is-arg-true "${VERBOSE:-false}" && set -x

  main "$@"

  exit 0
  ```

---

## 7. Debugging and verbose mode 🔍

### 7.1 VERBOSE toggle

- [SH-DBG-001] Support the `VERBOSE` environment variable for debugging:

  ```bash
  is-arg-true "${VERBOSE:-false}" && set -x
  ```

- [SH-DBG-002] Place the VERBOSE check immediately before calling `main "$@"`.
- [SH-DBG-003] Document VERBOSE in the header Options section:

  ```bash
  #   VERBOSE=true            # Show all the executed commands, default is 'false'
  ```

### 7.2 Debug output

- [SH-DBG-004] Use `echo` or `printf` for explicit debug output when needed.
- [SH-DBG-005] Never leave debugging `echo` statements in production code unless guarded by VERBOSE.

---

## 8. Error handling and exit codes 🚨

### 8.1 Fail-fast behaviour

- [SH-ERR-001] `set -euo pipefail` ensures scripts fail fast on errors.
- [SH-ERR-002] Do not use `|| true` to mask errors unless explicitly documented:

  ```bash
  # Ignore error if image doesn't exist (expected on first run)
  docker rmi "${DOCKER_IMAGE}:${version}" > /dev/null 2>&1 ||:
  ```

- [SH-ERR-003] Use `||:` (or `|| true`) only when failure is genuinely expected and safe to ignore.

### 8.2 Exit codes

- [SH-ERR-004] Document exit codes in the header when the script has specific failure modes:

  ```bash
  # Exit codes:
  #   0 - All files are formatted correctly
  #   1 - Files are not formatted correctly
  #   126 - Command cannot execute (permission denied or not executable)
  ```

- [SH-ERR-005] Scripts must end with `exit 0` after successful execution:

  ```bash
  main "$@"

  exit 0
  ```

---

## 9. Library scripts (sourced files) 📚

For library scripts intended to be sourced by other scripts.

### 9.1 Library structure

- [SH-LIB-001] Library files should use `.lib.sh` suffix: `docker.lib.sh`, `terraform.lib.sh`.
- [SH-LIB-002] Libraries must include the standard header with usage showing `source` command:

  ```bash
  # Usage:
  #   $ source ./docker.lib.sh
  ```

- [SH-LIB-003] Libraries should not call `main` or `exit` — they only define functions.

### 9.2 Function prefixes

- [SH-LIB-004] Library functions should use consistent prefixes for grouping:
  - `docker-build`, `docker-push`, `docker-clean`
  - `terraform-init`, `terraform-plan`, `terraform-apply`
  - `version-create-effective-file`

- [SH-LIB-005] Internal/private functions should be prefixed with underscore:
  - `_get-effective-tag`
  - `_create-effective-dockerfile`
  - `_terraform`

---

## 10. Mandatory quality gates ✅

Per [constitution.md §7.8](../../.specify/memory/constitution.md#78-mandatory-local-quality-gates), after making **any** change to shell scripts, you must run the repository's **canonical** quality gates.

### 10.1 ShellCheck (mandatory)

- [SH-QG-001] All shell scripts must pass ShellCheck with no errors or warnings.
- [SH-QG-002] Run ShellCheck locally before committing:

  ```bash
  shellcheck scripts/**/*.sh
  ```

- [SH-QG-003] Use directive comments to disable specific warnings only when justified:

  ```bash
  # shellcheck disable=SC2086
  ```

### 10.2 Iteration requirement

- [SH-QG-004] Follow the shared [quality gates baseline](./includes/quality-gates-baseline.include.md) for iteration and warning handling rules.
- [SH-QG-005] Follow the shared [quality gates baseline](./includes/quality-gates-baseline.include.md) for command selection and equivalents.

---

## 11. Test suite patterns 🧪

Shell script libraries and complex scripts should have accompanying test suites to ensure correctness and prevent regressions.

### 11.1 Test file structure

- [SH-TST-001] Test files should follow the naming convention `<library>.test.sh` or `<script>.test.sh`.
- [SH-TST-002] Place test files in a `tests/` subdirectory adjacent to the code being tested.
- [SH-TST-003] Test files must include the standard header structure (shebang, WARNING, `set -euo pipefail`, description block).
- [SH-TST-004] Use shellcheck disable directives at the top when testing patterns require it:

  ```bash
  #!/bin/bash
  # shellcheck disable=SC1091,SC2034,SC2317
  ```

### 11.2 Test suite organisation

- [SH-TST-005] Use a `main()` function to orchestrate the test suite:

  ```bash
  function main() {

    cd "$(git rev-parse --show-toplevel)"
    source ./scripts/docker/docker.lib.sh
    cd ./scripts/docker/tests

    # Set up test fixtures
    DOCKER_IMAGE=repository-template/docker-test
    DOCKER_TITLE="Repository Template Docker Test"

    test-suite-setup
    tests=( \
      test-feature-one \
      test-feature-two \
      test-feature-three \
    )
    local status=0
    for test in "${tests[@]}"; do
      {
        echo -n "$test"
        # shellcheck disable=SC2015
        $test && echo " PASS" || { echo " FAIL"; ((status++)); }
      }
    done
    echo "Total: ${#tests[@]}, Passed: $(( ${#tests[@]} - status )), Failed: $status"
    test-suite-teardown
    [ $status -gt 0 ] && return 1 || return 0
  }
  ```

- [SH-TST-006] Define tests as an array of function names for easy iteration and reporting.
- [SH-TST-007] Track pass/fail counts and print a summary at the end.

### 11.3 Setup and teardown functions

- [SH-TST-008] Provide `test-suite-setup()` and `test-suite-teardown()` functions for suite-level fixtures:

  ```bash
  function test-suite-setup() {

    # Create test fixtures, temporary files, mock data
    :
  }

  function test-suite-teardown() {

    # Clean up test fixtures, remove temporary files
    :
  }
  ```

- [SH-TST-009] Use `:` (no-op) as a placeholder when setup/teardown is not required.
- [SH-TST-010] Always call teardown even if tests fail to prevent resource leaks.

### 11.4 Test function structure (Arrange-Act-Assert)

- [SH-TST-011] Name test functions with `test-` prefix followed by the feature being tested:
  - ✅ `test-docker-build`
  - ✅ `test-version-file`
  - ✅ `test-docker-get-image-version-and-pull`
  - ❌ `testDockerBuild` (camelCase)
  - ❌ `test_docker_build` (snake_case)

- [SH-TST-012] Structure each test function using the Arrange-Act-Assert pattern with comments:

  ```bash
  function test-docker-build() {

    # Arrange
    export BUILD_DATETIME="2023-09-04T15:46:34+0000"
    # Act
    docker-build > /dev/null 2>&1
    # Assert
    docker image inspect "${DOCKER_IMAGE}:$(_get-effective-version)" > /dev/null 2>&1 && return 0 || return 1
  }
  ```

- [SH-TST-013] Return `0` for pass and `1` (or non-zero) for fail.

### 11.5 Assertion patterns

- [SH-TST-014] Use common assertion patterns:

  ```bash
  # String contains check
  echo "$output" | grep -q "expected" && return 0 || return 1

  # Regex match check
  echo "$output" | grep -Eq "Python [0-9]+\.[0-9]+\.[0-9]+" && return 0 || return 1

  # File content check
  grep -q "FROM python:.*-alpine.*@sha256:.*" Dockerfile.effective && return 0 || return 1

  # Multiple conditions (all must pass)
  (
    cat .version | grep -q "expected-1" &&
    cat .version | grep -q "expected-2"
  ) && return 0 || return 1

  # Command existence check
  docker image inspect "${IMAGE}:${VERSION}" > /dev/null 2>&1 && return 0 || return 1

  # Inverse check (command should fail)
  docker image inspect "${IMAGE}:${VERSION}" > /dev/null 2>&1 && return 1 || return 0
  ```

- [SH-TST-015] Suppress output during tests using `> /dev/null 2>&1` when the output is not being checked.

### 11.6 Test execution and output

- [SH-TST-016] Print test name before execution and result (PASS/FAIL) after:

  ```bash
  echo -n "$test"
  $test && echo " PASS" || { echo " FAIL"; ((status++)); }
  ```

- [SH-TST-017] Print a summary line at the end showing total, passed, and failed counts:

  ```bash
  echo "Total: ${#tests[@]}, Passed: $(( ${#tests[@]} - status )), Failed: $status"
  ```

- [SH-TST-018] Exit with non-zero status if any test failed:

  ```bash
  [ $status -gt 0 ] && return 1 || return 0
  ```

### 11.7 Testing library functions

- [SH-TST-019] Source the library being tested at the start of `main()`:

  ```bash
  source ./scripts/docker/docker.lib.sh
  ```

- [SH-TST-020] Change to the test directory before running tests to isolate test fixtures:

  ```bash
  cd ./scripts/docker/tests
  ```

- [SH-TST-021] Set up required environment variables as test fixtures:

  ```bash
  DOCKER_IMAGE=repository-template/docker-test
  DOCKER_TITLE="Repository Template Docker Test"
  TOOL_VERSIONS="$(git rev-parse --show-toplevel)/scripts/docker/tests/.tool-versions.test"
  ```

### 11.8 Test suite template

Use this template when creating test suites:

```bash
#!/bin/bash
# shellcheck disable=SC1091,SC2034,SC2317

# WARNING: Please DO NOT edit this file! It is maintained in the [repository name] (https://github.com/org/repo). Raise a PR instead.

set -euo pipefail

# Test suite for <library/script> functions.
#
# Usage:
#   $ ./<library>.test.sh
#
# Arguments (provided as environment variables):
#   VERBOSE=true  # Show all the executed commands, default is 'false'

# ==============================================================================

function main() {

  cd "$(git rev-parse --show-toplevel)"
  source ./path/to/library.lib.sh
  cd ./path/to/tests

  # Test fixtures
  FIXTURE_VAR="test-value"

  test-suite-setup
  tests=( \
    test-feature-one \
    test-feature-two \
  )
  local status=0
  for test in "${tests[@]}"; do
    {
      echo -n "$test"
      # shellcheck disable=SC2015
      $test && echo " PASS" || { echo " FAIL"; ((status++)); }
    }
  done
  echo "Total: ${#tests[@]}, Passed: $(( ${#tests[@]} - status )), Failed: $status"
  test-suite-teardown
  [ $status -gt 0 ] && return 1 || return 0
}

# ==============================================================================

function test-suite-setup() {

  :
}

function test-suite-teardown() {

  :
}

# ==============================================================================

function test-feature-one() {

  # Arrange
  local input="test-input"
  # Act
  output=$(some-function "$input")
  # Assert
  echo "$output" | grep -q "expected" && return 0 || return 1
}

function test-feature-two() {

  # Arrange
  export SOME_VAR="value"
  # Act
  some-other-function > /dev/null 2>&1
  # Assert
  [ -f "expected-file" ] && return 0 || return 1
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

main "$@"

exit 0
```

---

## 12. Anti-patterns (recognise and avoid) 🚫

These patterns cause recurring issues in shell scripts. Avoid them unless an ADR documents a justified exception.

- [SH-ANT-001] **Unquoted variables** — causes word splitting and glob expansion; always use `"$var"`.
- [SH-ANT-002] **`cd` without error handling** — script continues in wrong directory if `cd` fails; use `cd dir || exit 1` or rely on `set -e`.
- [SH-ANT-003] **Hardcoded absolute paths** — breaks portability; use `$(git rev-parse --show-toplevel)` or relative paths.
- [SH-ANT-004] **Missing `local` for function variables** — pollutes global namespace; always declare `local`.
- [SH-ANT-005] **`|| true` without comment** — masks failures silently; document why it is safe.
- [SH-ANT-006] **Parsing `ls` output** — breaks on filenames with spaces/special chars; use globs or `find`.
- [SH-ANT-007] **Command substitution in `[[` without quotes** — use `[[ -n "$var" ]]` not `[[ -n $var ]]`.
- [SH-ANT-008] **Using `$?` after multiple commands** — `$?` only reflects the last command; capture immediately.
- [SH-ANT-009] **`eval` with user input** — code injection risk; avoid `eval` unless absolutely necessary.
- [SH-ANT-010] **Missing shebang** — script may run with wrong interpreter; always include `#!/bin/bash`.
- [SH-ANT-011] **Using `echo` for error messages** — errors should go to stderr; use `echo "error" >&2`.
- [SH-ANT-012] **Not using `set -euo pipefail`** — allows silent failures; always enable safety options.
- [SH-ANT-013] **Inconsistent function naming** — mixing camelCase, snake_case, and kebab-case; use kebab-case consistently.
- [SH-ANT-014] **Giant scripts without functions** — hard to test and maintain; break into functions.
- [SH-ANT-015] **Forgetting `exit 0`** — script exit code may be non-zero from last command; explicitly exit 0.
- [SH-ANT-016] **Tests without Arrange-Act-Assert comments** — harder to understand test intent; always include the three comments.
- [SH-ANT-017] **Missing test summary** — no visibility into overall results; always print total/passed/failed counts.

---

## 13. AI-assisted change expectations 🤖

Per [constitution.md §3.5](../../.specify/memory/constitution.md#35-ai-assisted-development-discipline--change-governance), when you create or modify shell scripts:

- [SH-AI-001] Follow the shared [AI change baseline](./includes/ai-assisted-change-baseline.include.md) for scope, quality, and governance.
- [SH-AI-002] Use the established patterns: header structure, `main()` entry point, kebab-case functions.
- [SH-AI-003] Run ShellCheck and iterate until clean.

---

## 14. Script template 📝

Use the template at [templates/shell-script.template.sh](./templates/shell-script.template.sh) when creating new scripts.

---

> **Version**: 1.1.0
> **Last Amended**: 2026-01-17
