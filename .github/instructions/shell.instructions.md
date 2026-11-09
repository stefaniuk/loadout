---
applyTo: "**/*.{sh,bash,zsh}"
description: "Shell Script Engineering Instructions (Bash, CLI wrappers, automation)"
---

# Shell Script Engineering Instructions (Bash, CLI wrappers, automation) 🐚

These instructions define the default engineering approach for writing
**production-grade shell scripts** in Bash.

They must remain applicable to:

- Standalone CLI utility scripts
- Git hook scripts
- CI/CD pipeline scripts
- Tool wrapper scripts (native/Docker dual execution)
- Library scripts sourced by other scripts
- Report generation and automation scripts

They are **non-negotiable** unless an exception is explicitly documented (with
rationale and expiry) in an ADR/decision record.

**Cross-references.** For Makefile orchestration conventions that call shell
scripts, see [makefile.instructions.md](./makefile.instructions.md). This file
focuses exclusively on shell script patterns.

**Identifier scheme.** Every normative rule carries a unique tag in the form
`[SH-<prefix>-NNN]`, where the prefix maps to the containing section (for
example `QR` for Quick Reference, `HDR` for Header, `FN` for Functions, `VAR`
for Variables, `ERR` for Error Handling, `DOC` for Documentation). Use these
identifiers when referencing, planning, or validating requirements.

---

## 0. Quick reference (apply first) 🧠

This section exists so humans and AI assistants can reliably apply the most
important rules even when context is tight.

- [SH-QR-001] **Shebang and safety**: start with `#!/usr/bin/env bash` and
  `set -euo pipefail` ([SH-HDR-001], [SH-HDR-003]).
- [SH-QR-002] **Header structure**: safety options, description block, and
  80-character section dividers ([SH-HDR-002]–[SH-HDR-006]).
- [SH-QR-003] **`main()` entry point**: use a `main()` function as the script
  entry point, called at the bottom of the file ([SH-FN-001]).
- [SH-QR-004] **Kebab-case functions**: name functions using `kebab-case`
  (lowercase with hyphens) ([SH-FN-002]).
- [SH-QR-005] **Document all functions**: provide comment blocks describing
  purpose and arguments ([SH-DOC-001]–[SH-DOC-004]).
- [SH-QR-006] **Native/Docker dual execution**: scripts should run tools
  natively if installed, or fall back to Docker ([SH-EXEC-001]–[SH-EXEC-005]).
- [SH-QR-007] **`is-arg-true()` helper**: use a standard boolean-parsing helper
  for environment flags ([SH-VAR-006]).
- [SH-QR-008] **VERBOSE toggle**: support `VERBOSE=true` to enable `set -x` for
  debugging ([SH-DBG-001]–[SH-DBG-003]).
- [SH-QR-009] **Exit 0 at end**: scripts must end with `exit 0` after successful
  execution ([SH-ERR-005]).
- [SH-QR-010] **Test suites**: use the shared harness in
  `scripts/tests/test.lib.sh`, one isolated test per function, with
  Arrange-Act-Assert comments ([SH-TST-001]–[SH-TST-023]).
- [SH-QR-011] **Avoid common anti-patterns**: unquoted variables, `cd` without
  error handling, hardcoded paths (§12).
- [SH-QR-012] **Explicit returns**: finish every function with an explicit
  `return <status>` so intent and requirements stay aligned ([SH-FN-007]).
- [SH-QR-013] **Propagate failures**: end a failing call with `|| return "$?"`
  and never hide a failure with `|| true` ([SH-FN-010], [SH-ERR-002]).
- [SH-QR-014] **Isolated tool containers**: run tool images pinned in
  `mise.toml` with `--rm --platform linux/amd64 --network none` and a read-only
  checkout mount, and document any network or write need ([SH-EXEC-009],
  [SH-EXEC-010], [SH-EXEC-016]).
- [SH-QR-015] **The repository (based on the repository template) is the
  reference**: when a rule here and the repository's own scripts disagree,
  follow the scripts and correct this file
  ([SH-OP-008]).

---

## 1. Operating principles 🧭

These principles extend
[constitution.md §3](../../.specify/memory/constitution.md#3-core-principles-non-negotiable).

- [SH-OP-001] Treat scripts as **contracts**: stable interfaces for developers
  and CI/CD pipelines.
- [SH-OP-002] Prefer **small, explicit, testable** changes over broad rewrites.
- [SH-OP-003] Design for **determinism**: the same inputs and environment
  produce the same outputs.
- [SH-OP-004] Scripts are for **orchestration and automation**. Complex business
  logic belongs elsewhere, e.g. Python, TypeScript, etc. See the [Technology
  Recommendations](../../docs/adr/Technology_Recommendations.md) guide.
- [SH-OP-005] **Fail fast and fail loud**: errors must not be hidden or ignored.
- [SH-OP-006] Optimise for **readability, maintainability, and debugging**, not
  cleverness.
- [SH-OP-007] Scripts must be **independently runnable** for debugging and
  testing purposes.
- [SH-OP-008] Treat the scripts in this repository as the reference
  implementation of these rules, in particular `scripts/quality/*.sh`,
  `scripts/quality/git-files.lib.sh`, `scripts/docker/docker.lib.sh` and
  `scripts/tests/test.lib.sh`. Copy their patterns rather than inventing new
  ones.

---

## 2. Header structure 📋

Every script must begin with a consistent header structure that makes the script
self-documenting.

### 2.1 Shebang and safety options

- [SH-HDR-001] The first line must be `#!/usr/bin/env bash`, selecting GNU Bash
  5.2 or later from `PATH`.
- [SH-HDR-002] Put `set -euo pipefail` after the shebang, separated by one blank
  line. A test suite puts its
  `# shellcheck disable=...` line directly under the shebang ([SH-TST-004]):
  - `-e`: Exit immediately if any command returns non-zero
  - `-u`: Exit if an uninitialised variable is used
  - `-o pipefail`: Pipeline returns the exit status of the first failing command

### 2.2 Description block

- [SH-HDR-003] After the safety options, include a description block with these
  sections, in this order:
  - A summary of what the script does, then how it runs the tool, for example
    "It runs lychee natively when installed, otherwise in a Docker container."
  - `Usage:` with the invocation from the repository root,
    `$ [options] ./scripts/<area>/<name>.sh`, or
    `$ source ./scripts/<area>/<name>.lib.sh` for a library
  - `Options:` for an executable script, one environment variable per entry as
    `name=value` on one line, then the description indented by four more spaces
    on the next, ending with `default is 'value'`. A library uses
    `Arguments (provided as environment variables):` instead
  - `Exit codes:` with every status the script can return, including statuses
    passed through from the wrapped tool ([SH-ERR-009])
  - `Notes:` as a numbered list, with continuation lines aligned under the text.
    Describe a shared concept, such as the Git check modes, once in the library
    that owns it and refer to it from here
- [SH-HDR-006] Quote default values with single quotes, as in
  `default is 'working-tree-changes'`, never with backticks. Keep `VERBOSE=true`
  as the last option.

Example from
[check-markdown-links.sh](../../scripts/quality/check-markdown-links.sh):

```bash
#!/usr/bin/env bash

set -euo pipefail

# Check that links in Markdown files resolve. It runs lychee natively when
# installed, otherwise in a Docker container.
#
# Usage:
#   $ [options] ./scripts/quality/check-markdown-links.sh
#
# Options:
#   check={all,staged-changes,working-tree-changes,branch}
#       Check mode, default is 'working-tree-changes'
#   BRANCH_NAME=base-branch
#       Local base for the branch mode, chosen automatically when unset, as
#       './scripts/quality/git-base.lib.sh' describes
#   FORCE_USE_DOCKER=true
#       Run in a Docker container, default is 'false'
#   VERBOSE=true
#       Show all the executed commands, default is 'false'
#
# Exit codes:
#   0 - All links are valid
#   1 - Lychee failed to run, or the branch to compare with is not found
#   2 - Broken links found
#   126 - The check mode is not recognised
#   Other - Non-zero statuses from Git, lychee, Docker or image pulls
#
# Notes:
#   1) Check modes select existing Markdown files known to Git, as described in
#      './scripts/quality/git-files.lib.sh'. Untracked files are never checked.
#   2) The lychee configuration is in './scripts/config/lychee.toml'. For more
#      information, see https://github.com/lycheeverse/lychee
```

### 2.3 Section dividers

- [SH-HDR-004] Separate the major sections of a script with exactly this
  80-character divider, a `#`, a space and 78 `=` characters:

  ```bash
  # ==============================================================================
  ```

- [SH-HDR-005] Place a divider:
  - after the description block
  - before a group of helper functions, when the script has one
  - before `is-arg-true()`
  - before the invocation section

---

## 3. Function conventions 🔧

### 3.1 Entry point pattern

- [SH-FN-001] Use a `main()` function as the script's entry point:

  ```bash
  # Check the selected files in native or Docker mode.
  function main() {

    cd "$(git rev-parse --show-toplevel)"
    # Script logic here...

    return 0
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
- [SH-FN-006] Functions should be small enough to fit on one screen (~30–50
  lines maximum).

### 3.3 Explicit return statements

- [SH-FN-007] End every function with an explicit `return` (usually `return 0`
  for success, or a non-zero value for failures) so static analysis tools can
  determine the intended exit status and humans can see the control flow
  clearly. Do not rely on implicit fall-through to provide the exit code. A
  final `if ... then return 0; else return 1; fi` counts as an explicit return.
- [SH-FN-009] Assign positional parameters to named `local` variables at the top
  of the function, for example `local file="$1" mode="$2"`, and use the names
  afterwards. SonarQube Cloud reports a function that reads `$1` without doing
  so.
- [SH-FN-010] Propagate failures explicitly, because `set -e` does not apply
  inside a function called from an `if`, `&&` or `||` context:
  - `command || return "$?"` when the failure ends the function
  - `local rc=0`, then `command || rc=$?`, then `return "$rc"` when later steps
    must still run
  - `if command; then :; else rc=$?; rm -f "$tmp"; return "$rc"; fi` when
    cleanup must run before returning
  - `local value` on one line and `value="$(command)" || return "$?"` on the
    next. Never write `local value="$(command)"`, which hides the status
- [SH-FN-011] Return data through stdout, or through an array name reference
  (`local -n result="$1"`) when the caller needs a list. Never return data
  through undeclared globals.

### 3.4 Dual execution pattern (native vs Docker)

- [SH-FN-008] For tool wrapper scripts, implement paired execution functions:
  - `run-<tool>-natively` - runs the tool if installed locally
  - `run-<tool>-in-docker` - runs the tool in a Docker container

Example, from
[check-markdown-format.sh](../../scripts/quality/check-markdown-format.sh):

```bash
# Run markdown format checks in native or Docker mode.
function main() {

  cd "$(git rev-parse --show-toplevel)"

  # shellcheck disable=SC1091
  source ./scripts/quality/git-files.lib.sh
  local -a files=()
  quality-collect-git-files files "${check:-working-tree-changes}" '*.md' || return "$?"

  if [[ ${#files[@]} -gt 0 ]]; then
    if command -v markdownlint > /dev/null 2>&1 && ! is-arg-true "${FORCE_USE_DOCKER:-false}"; then
      run-markdownlint-natively "${files[@]}" || return "$?"
    else
      run-markdownlint-in-docker "${files[@]}" || return "$?"
    fi
  fi

  return 0
}
```

---

## 4. Variable and argument conventions 📝

### 4.1 Naming conventions

- [SH-VAR-001] Use **UPPERCASE** for settings that apply across scripts and for
  constants:
  - `VERBOSE`, `FORCE_USE_DOCKER`, `BRANCH_NAME`, `BUILD_DATETIME`,
    `DOCKER_IMAGE`

- [SH-VAR-002] Use **lowercase** for options that belong to one script, which
  callers pass as environment variables
  (`check=all ./scripts/quality/check-file-format.sh`), and for local variables:
  - `check`, `file`, `dir`, `dry_run`, `files`, `image`

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

- [SH-VAR-006] Use the standard `is-arg-true()` helper for boolean environment
  flags:

  ```bash
  # Check whether the supplied argument represents a true boolean value.
  # Arguments:
  #   $1=[value to evaluate]
  function is-arg-true() {

    local value="$1"
    if [[ "$value" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$ ]]; then
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

- [SH-DOC-001] Document every function with a comment block above it: a one-line
  summary, then an `Arguments:` block when the function takes positional
  arguments. Test functions named `test-*` are exempt, because their names and
  Arrange-Act-Assert comments document them ([SH-TST-011]):

  ```bash
  # Collect unique, existing paths selected by the requested check mode.
  # Arguments:
  #   $1=[name reference of output array]
  #   $2=[check mode]
  #   $3=[optional Git pathspec]
  function quality-collect-git-files() {
    # ...
  }
  ```

- [SH-DOC-002] Document arguments in one of these formats:
  - `#   $1=[description]` for a positional argument, and `#   $@=[description]`
    for a list
  - `#   varname=[description]` or
    `#   varname=[description, default is 'value']` under
    `# Arguments (provided as environment variables):`

- [SH-DOC-003] For library functions that set up environment, document the
  expected variables:

  ```bash
  # Arguments (provided as environment variables):
  #   DOCKER_IMAGE=ghcr.io/org/repo     # Docker image name
  #   DOCKER_TITLE="My Docker image"    # Docker image title
  #   MISE_TOML=$project_dir/mise.toml  # Path to the mise config file
  ```

### 5.2 Inline comments

- [SH-DOC-004] Use inline comments sparingly to explain non-obvious logic:

  ```bash
  # shellcheck disable=SC2086
  docker run --rm --platform linux/amd64 \
    ${args:-} \
    "${tag}"
  ```

- [SH-DOC-005] Disable a ShellCheck warning only on the line that needs it, with
  the directive comment directly above, never file-wide in a production script:

  ```bash
  # shellcheck disable=SC1091
  source ./scripts/docker/docker.lib.sh
  ```

---

## 6. Execution model and script structure 🏗️

### 6.1 Dual execution architecture

- [SH-EXEC-001] Tool wrapper scripts should support both native and Docker
  execution modes.
- [SH-EXEC-002] Check for native tool availability with `command -v`, and fall
  back to Docker when it is missing or when `FORCE_USE_DOCKER` is true:

  ```bash
  if command -v toolname > /dev/null 2>&1 && ! is-arg-true "${FORCE_USE_DOCKER:-false}"; then
    run-toolname-natively "$@" || return "$?"
  else
    run-toolname-in-docker "$@" || return "$?"
  fi
  ```

- [SH-EXEC-003] Respect `FORCE_USE_DOCKER=true` to force Docker execution even
  when native tool exists.
- [SH-EXEC-004] For Docker execution, source the shared Docker library:

  ```bash
  # shellcheck disable=SC1091
  source ./scripts/docker/docker.lib.sh
  ```

- [SH-EXEC-005] Pin every tool image in the `[_.docker]` table of `mise.toml` as
  `"<image>" = "<tag>@sha256:<digest>"`, and resolve it with
  `docker-get-image-version-and-pull`. Never write an image tag inside a script.
  Run the container with the same flag set as the quality scripts:

  ```bash
  local image
  image=$(name=koalaman/shellcheck docker-get-image-version-and-pull) || return "$?"
  docker run --rm --platform linux/amd64 \
    --network none \
    --volume "$PWD:/workdir:ro" \
    --workdir /workdir \
    "$image" \
      command arguments || return "$?"
  ```

- [SH-EXEC-009] Run tool containers with `--network none` by default. Omit it
  only when the tool needs the network to do its job, such as a link checker or
  `npx` downloading an exact package version pinned in `mise.toml`, and say why
  in a one-line comment above `docker run`.
- [SH-EXEC-016] Mount the checkout read-only, for example
  `--volume "$PWD:/workdir:ro"`, so a compromised image cannot change the
  working tree or `.git/hooks`. Mount it read-write only when the tool must
  change files, such as a formatter, and say why in the same comment as
  [SH-EXEC-009].
- [SH-EXEC-010] Forward only the environment variables the tool needs, by name,
  for example `--env GITHUB_ACTIONS --env NO_COLOR`. Never forward secrets into
  a tool container.
- [SH-EXEC-011] `--platform linux/amd64` keeps results identical on every host.
  On Apple silicon the image runs under emulation, which is slower but expected.

### 6.2 Directory handling

- [SH-EXEC-006] Navigate to the repository root at the start of `main()`:

  ```bash
  function main() {
    cd "$(git rev-parse --show-toplevel)"
    # ...
  }
  ```

- [SH-EXEC-007] Use relative paths from the repository root for consistency, and
  source libraries from it, for example
  `source ./scripts/quality/git-files.lib.sh`.
- [SH-EXEC-012] Select files through Git, never through `find` over the working
  tree. Shared check modes (`all`, `staged-changes`, `working-tree-changes`,
  `branch`) come from `quality-collect-git-files` in
  [git-files.lib.sh](../../scripts/quality/git-files.lib.sh), which reads
  NUL-separated output, skips untracked and deleted files, and prefixes paths
  that start with `-` with `./`.

### 6.3 Script invocation section

- [SH-EXEC-008] At the bottom of the script, include the invocation section:

  ```bash
  # ==============================================================================

  is-arg-true "${VERBOSE:-false}" && set -x

  main "$@"

  exit 0
  ```

### 6.4 Portability

- [SH-EXEC-013] Scripts may rely on Bash 5.2 and the GNU userland (`sed -i`,
  `date --date`, `grep -P`), which `make toolchain-verify-gnu` checks and
  `make toolchain-install-gnu-macos` provides on macOS.
- [SH-EXEC-014] Scripts that install or verify that toolchain, under
  `scripts/toolchain/`, must also run on the macOS `/bin/bash` 3.2. Do not use
  associative arrays, `local -n`, `mapfile` or `${var,,}` there. Read lines with
  `while IFS= read -r`.
- [SH-EXEC-015] Use `[[ ]]` for conditions, `$(...)` for command substitution,
  and quote every expansion unless word splitting is intended and marked with a
  ShellCheck directive.

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
- [SH-DBG-005] Never leave debugging `echo` statements in production code unless
  guarded by VERBOSE.

---

## 8. Error handling and exit codes 🚨

### 8.1 Fail-fast behaviour

- [SH-ERR-001] `set -euo pipefail` ensures scripts fail fast on errors. Inside
  functions, propagate failures explicitly as [SH-FN-010] describes.
- [SH-ERR-002] Do not use `|| true` or `||:` to mask errors. Use them only where
  the failure is expected and harmless, with a one-line comment saying why:

  ```bash
  # The image may not exist yet
  docker rmi "${DOCKER_IMAGE}:${version}" > /dev/null 2>&1 ||:
  ```

- [SH-ERR-003] Never use `|| true` after a command whose result decides what
  happens next. Capture the status instead, as [SH-FN-010] shows.
- [SH-ERR-006] Write every error, warning and progress message to stderr with
  `>&2`. Keep stdout for results that a caller may capture.
- [SH-ERR-007] Start an error message with `ERROR:` and a warning with
  `WARNING:`, then say what failed and what to do next, for example
  `ERROR: yq is required to validate workflow security, run 'make config'`.
- [SH-ERR-008] Reject an unrecognised option value with a non-zero status and a
  stderr message that names the value, for example
  `Unrecognised check mode: bogus`.
- [SH-ERR-009] A tool wrapper passes the wrapped tool's exit status through
  unchanged and lists it in the header, as `check-markdown-links.sh` does for
  lychee's `2`. This is the documented exception to [CLI-EXIT-007] in the
  [CLI contract](./includes/cli-contract-baseline.include.md).
- [SH-ERR-010] Create temporary files with `mktemp` and remove them on every
  path, including failure paths, before returning.

### 8.2 Exit codes

- [SH-ERR-004] Document exit codes in the header when the script has specific
  failure modes:

  ```bash
  # Exit codes:
  #   0 - No leaks present
  #   1 - Leaks encountered
  #   126 - The check mode is not recognised
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

- [SH-LIB-001] Library files should use `.lib.sh` suffix: `docker.lib.sh`,
  `git-files.lib.sh`, `test.lib.sh`.
- [SH-LIB-002] Libraries must include the standard header, with a usage line
  that sources the file from the repository root:

  ```bash
  # Usage:
  #   $ source ./scripts/quality/git-files.lib.sh
  ```

- [SH-LIB-003] Libraries should not call `main` or `exit` - they only define
  functions. Every library function returns its status, so the caller decides
  whether to stop.

### 9.2 Function prefixes

- [SH-LIB-004] Library functions should use consistent prefixes for grouping:
  - `docker-build`, `docker-push`, `docker-clean`
  - `quality-collect-git-files`, `quality-git-paths`
  - `test-capture`, `test-stub`, `assert-equal`
  - `version-create-effective-file`

- [SH-LIB-005] Internal/private functions should be prefixed with underscore:
  - `_get-effective-tag`
  - `_create-effective-dockerfile`
  - `_terraform`

---

## 10. Mandatory quality gates ✅

Per
[constitution.md §7.8](../../.specify/memory/constitution.md#78-mandatory-local-quality-gates),
after making **any** change to shell scripts, you must run the repository's
**canonical** quality gates.

### 10.1 ShellCheck

- [SH-QG-001] All shell scripts must pass ShellCheck with no errors or warnings.
- [SH-QG-002] Lint through the repository targets, which run ShellCheck natively
  or in Docker:

  ```bash
  make lint-shell
  make lint-shell check=staged-changes
  ```

- [SH-QG-003] Use directive comments to disable specific warnings only when
  justified ([SH-DOC-005]). A test suite may disable
  `SC1091,SC2034,SC2317,SC2329` file-wide, because the harness calls its
  functions indirectly ([SH-TST-004]).
- [SH-QG-006] Keep scripts free of SonarQube Cloud shell findings. The rules
  seen on this project are: `[[` instead of `[` (S7688), positional parameters
  assigned to locals (S7679, [SH-FN-009]), an explicit return at the end of each
  function (S7682, [SH-FN-007]), a `*)` branch in every `case` (S131), no unused
  locals (S1481), and a `readonly` constant for any string literal used four or
  more times (S1192).
- [SH-QG-007] Run the suite of the script you changed, then `make test`
  ([SH-TST-005]).
- [SH-QG-008] Keep every full-line comment in `*.sh` and `*.mk` files to 80
  characters or fewer, counted in bytes. `make lint-shell` fails a longer one.
  The shebang and comment lines containing a URL (`://`) are exempt. Wrap
  continuation text under the description column, as in [SH-HDR-003] option
  tables, and indent an `Arguments:` continuation by two more spaces.

### 10.2 Iteration requirement

- [SH-QG-004] Follow the shared
  [quality gates baseline](./includes/quality-gates-baseline.include.md) for
  iteration and warning handling rules.
- [SH-QG-005] Follow the shared
  [quality gates baseline](./includes/quality-gates-baseline.include.md) for
  command selection and equivalents.

---

## 11. Test suite patterns 🧪

Every script and library has a test suite that uses the shared harness in
[test.lib.sh](../../scripts/tests/test.lib.sh). Read its header before writing a
suite.
[check-markdown-links.test.sh](../../scripts/quality/tests/check-markdown-links.test.sh)
is a complete example.

### 11.1 Test file structure

- [SH-TST-001] Name a suite `<script>.test.sh` or `<library>.test.sh` and make
  it executable.
- [SH-TST-002] Place test files in a `tests/` subdirectory adjacent to the code
  being tested.
- [SH-TST-003] Test files use the standard header structure
  ([SH-HDR-001]–[SH-HDR-006]), with an `Options:` section listing
  `VERBOSE=true`.
- [SH-TST-004] Put this directive directly under the shebang, because the
  harness calls test functions indirectly:

  ```bash
  #!/usr/bin/env bash
  # shellcheck disable=SC1091,SC2034,SC2317,SC2329
  ```

### 11.2 Test suite organisation

- [SH-TST-005] `make test` runs
  [run-test-suites.sh](../../scripts/tests/run-test-suites.sh), which discovers
  every tracked, executable `*.test.sh` file under `scripts/` and runs the
  suites in parallel. A new suite needs no registration.
- [SH-TST-006] Use a `main()` function that changes to the repository root,
  sources the harness, sets the suite fixtures and passes every test name to
  `test-run-suite`:

  ```bash
  # Set up the suite fixtures and run every test.
  function main() {

    cd "$(git rev-parse --show-toplevel)"
    source ./scripts/tests/test.lib.sh

    # The caller's options must not reach the script under test
    unset -v check file BRANCH_NAME FORCE_USE_DOCKER

    test-run-suite \
      test-feature-rejects-unknown-mode \
      test-feature-uses-docker-when-forced

    return 0
  }
  ```

- [SH-TST-007] `test-run-suite` runs the tests in parallel, each in its own
  subshell with `set -e`, and prints one `PASS` or `FAIL` line per test and a
  `Total: n, Passed: n, Failed: n` summary. Do not write your own loop or
  counters.

### 11.3 Setup and teardown functions

- [SH-TST-008] Define `test-suite-setup()` and `test-suite-teardown()` only when
  the suite needs suite-wide fixtures. The harness calls them, and runs the
  teardown even when a test or the setup fails.
- [SH-TST-009] Keep suite-wide state in `SUITE_TMP` and per-test state in
  `TEST_TMP`. Never write to a fixed path or to the repository.
- [SH-TST-010] Unset in `main()` every option the script under test reads, so
  the developer's environment cannot change the result.

### 11.4 Test function structure (Arrange-Act-Assert)

- [SH-TST-011] Name test functions with `test-` and a description of the
  behaviour, such as `test-check-file-format-rejects-unknown-mode`. Kebab-case
  only.

- [SH-TST-012] Structure each test function using the Arrange-Act-Assert pattern
  with comments:

  ```bash
  function test-check-markdown-links-rejects-unknown-mode() {

    # Arrange
    quality-create-fixture-repo README.md
    test-isolate-path
    test-stub lychee
    test-stub docker
    cd "$TEST_TMP/repo"
    # Act
    test-capture env check=bogus ./scripts/quality/check-markdown-links.sh
    # Assert
    assert-equal 1 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
    assert-contains "$TEST_STDERR" "Unrecognised check mode: bogus"
    assert-stub-not-called lychee
    assert-stub-not-called docker

    return 0
  }
  ```

- [SH-TST-013] A test passes when it returns 0 and fails on the first failing
  command or assertion. Never call `exit` in a test, because the harness treats
  it as a failure.

### 11.5 Assertion patterns

- [SH-TST-014] Use the harness assertions, never
  `grep -q ... && return 0 || return 1`:
  - `assert-equal`, `assert-contains`, `assert-not-contains`, `assert-matches`
    for values
  - `assert-file-exists`, `assert-file-not-exists`, `assert-file-has-line`,
    `assert-files-identical` for files
  - `assert-stub-called`, `assert-stub-not-called` for calls to stubbed commands
- [SH-TST-015] Run the command under test with `test-capture`, which sets
  `TEST_STATUS`, `TEST_STDOUT` and `TEST_STDERR` without failing the test.
  Assert the exit status and the relevant stream every time.

### 11.6 Isolation and stubbing

- [SH-TST-016] Call `test-isolate-path` before creating stubs, so the script
  under test sees only the stubs and the base tools. Pass any extra real tool it
  needs, for example `test-isolate-path python3`.
- [SH-TST-017] Replace external tools with `test-stub <name> [body]` and check
  how they were called with `assert-stub-called`. A unit suite must not need the
  tool or a Docker daemon.
- [SH-TST-018] Build fixtures in a scratch Git repository with
  `test-create-repo`, or a shared helper built on it such as
  `quality-create-fixture-repo`. Never mutate the real repository.
- [SH-TST-019] Point code that reads configuration at a fixture file, for
  example `MISE_TOML="$TEST_REPO_ROOT/scripts/docker/tests/mise.toml.test"`.

### 11.7 Constants and integration suites

- [SH-TST-020] Declare a string used four or more times as a `readonly` constant
  at the top of the suite, for example
  `readonly EXIT_STATUS_LABEL='exit status'`.
- [SH-TST-021] Keep tests that need a real Docker daemon in a separate
  integration suite, for example `docker.test.sh`. Its setup fails with a clear
  `ERROR` on stderr when the daemon is missing.
- [SH-TST-022] Name test images uniquely per run, and remove them in
  `test-suite-teardown`.
- [SH-TST-023] Write a failing test before changing a script's behaviour, then
  make it pass
  ([constitution.md §3.6](../../.specify/memory/constitution.md#36-design-for-testability-tdd)).

---

## 12. Anti-patterns (recognise and avoid) 🚫

These patterns cause recurring issues in shell scripts. Avoid them unless an ADR
documents a justified exception.

- [SH-ANT-001] **Unquoted variables** - causes word splitting and glob
  expansion; always use `"$var"`.
- [SH-ANT-002] **`cd` without error handling** - script continues in wrong
  directory if `cd` fails; inside a function use `cd "$dir" || return "$?"`.
- [SH-ANT-003] **Hardcoded absolute paths** - breaks portability; use
  `$(git rev-parse --show-toplevel)` or relative paths.
- [SH-ANT-004] **Missing `local` for function variables** - pollutes global
  namespace; always declare `local`.
- [SH-ANT-005] **`|| true` or `||:` without comment** - masks failures silently;
  document why it is safe ([SH-ERR-002]).
- [SH-ANT-006] **Parsing `ls` output** - breaks on filenames with spaces/special
  chars; use globs or `find`.
- [SH-ANT-007] **Command substitution in `[[` without quotes** - use
  `[[ -n "$var" ]]` not `[[ -n $var ]]`.
- [SH-ANT-008] **Using `$?` after multiple commands** - `$?` only reflects the
  last command; capture immediately.
- [SH-ANT-009] **`eval` with user input** - code injection risk; avoid `eval`
  unless absolutely necessary.
- [SH-ANT-010] **Missing shebang** - script may run with wrong interpreter;
  always include `#!/usr/bin/env bash`.
- [SH-ANT-011] **Using `echo` for error messages** - errors should go to stderr;
  use `echo "error" >&2`.
- [SH-ANT-012] **Not using `set -euo pipefail`** - allows silent failures;
  always enable safety options.
- [SH-ANT-013] **Inconsistent function naming** - mixing camelCase, snake_case,
  and kebab-case; use kebab-case consistently.
- [SH-ANT-014] **Giant scripts without functions** - hard to test and maintain;
  break into functions.
- [SH-ANT-015] **Forgetting `exit 0`** - script exit code may be non-zero from
  last command; explicitly exit 0.
- [SH-ANT-016] **Tests without Arrange-Act-Assert comments** - harder to
  understand test intent; always include the three comments.
- [SH-ANT-017] **Hand-rolled test runners** - inconsistent isolation and
  reporting; use `test-run-suite` and the harness assertions ([SH-TST-006],
  [SH-TST-014]).
- [SH-ANT-018] **`local value="$(command)"`** - `local` returns 0 and hides the
  command's failure; declare first, then assign ([SH-FN-010]).
- [SH-ANT-019] **Unpinned or tag-only tool images, or floating package versions
  such as `npx prettier@3`** - results drift between machines and new releases
  run unreviewed; pin the image with a digest and the package with an exact
  version in `mise.toml` ([SH-EXEC-005], [SH-EXEC-009]).
- [SH-ANT-020] **Selecting files with `find` or `ls` over the working tree** -
  picks up untracked and ignored files; select through Git ([SH-EXEC-012]).

---

## 13. AI-assisted change expectations 🤖

Per
[constitution.md §3.5](../../.specify/memory/constitution.md#35-ai-assisted-development-discipline),
when you create or modify shell scripts:

- [SH-AI-001] Follow the shared
  [AI change baseline](./includes/ai-assisted-change-baseline.include.md) for
  scope, quality, and governance.
- [SH-AI-002] Use the established patterns: header structure, `main()` entry
  point, kebab-case functions.
- [SH-AI-003] Run `make lint-shell` and the changed script's test suite, and
  iterate until both are clean.

---

## 14. Script template 📝

Use the template at
[templates/shell-script.template.sh](./templates/shell-script.template.sh) when
creating new scripts.
