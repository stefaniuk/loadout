#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2016,SC2034,SC2317,SC2329

set -euo pipefail

# Test suite for the workflow mode script. Each test runs the script in a
# scratch Git repository with the real jq and yq. The fixture replaces the
# loadout modes with two modes, 'alpha', the default, and 'beta', which share
# the skill 'shared'. The suite needs neither Docker nor the network.
#
# Usage:
#   $ ./scripts/tests/workflow-mode.test.sh
#
# Options:
#   VERBOSE=true  # Show all the executed commands, default is 'false'

# ==============================================================================

readonly EXIT_STATUS_LABEL='exit status'
readonly SCRIPT=./scripts/hooks/workflow-mode.sh
readonly BASE_CONFIG=scripts/hooks/workflow-modes.yaml
readonly DROP_IN=scripts/config/workflow-modes.d/test.yaml
readonly GUIDE=https://github.com/stefaniuk/loadout/blob/main/docs/workflow-modes.md
readonly TWO_MODES=$'version: 1\ndefault: alpha\nmodes:\n  - name: alpha\n    description: First way of working\n    skills: [alpha-*, shared]\n  - name: beta\n    skills: [beta-?, shared]'
readonly SESSION_START='{"hook_event_name":"SessionStart","session_id":"s1","source":"new"}'
readonly DENY='.permissionDecision'
readonly DEFAULT_STATUS=$'Workflow mode: alpha (default)\n  Description  First way of working\n  Skills       alpha-*, shared\n  Set by       default in scripts/config/workflow-modes.d/test.yaml\n  Other modes  beta\n  To change    make workflow-use mode=beta, then start a new chat session'

# Set up the suite fixtures and run every test.
function main() {

  cd "$(git rev-parse --show-toplevel)"
  source ./scripts/tests/test.lib.sh

  # The caller's options must not reach the script under test
  unset -v mode

  test-run-suite \
    test-workflow-mode-status-prints-none-without-modes \
    test-workflow-mode-status-prints-the-default-mode \
    test-workflow-mode-status-explains-why-no-mode-is-active \
    test-workflow-mode-status-wraps-long-rows \
    test-workflow-mode-use-sets-the-active-mode \
    test-workflow-mode-use-requires-a-mode \
    test-workflow-mode-use-rejects-a-malformed-name \
    test-workflow-mode-use-rejects-an-undefined-mode \
    test-workflow-mode-clear-restores-the-default \
    test-workflow-mode-status-fails-when-the-chosen-mode-is-not-defined \
    test-workflow-mode-fails-when-the-state-file-cannot-be-read \
    test-workflow-mode-reports-a-state-path-that-is-not-a-file \
    test-workflow-mode-keeps-the-mode-per-worktree \
    test-workflow-mode-lists-the-modes-and-marks-the-active-one \
    test-workflow-mode-list-shortens-long-skill-lists \
    test-workflow-mode-list-says-when-no-mode-is-defined \
    test-workflow-mode-list-checks-the-patterns-against-installed-skills \
    test-workflow-mode-drop-ins-override-modes-by-name-in-byte-order \
    test-workflow-mode-warns-about-a-symlinked-drop-in \
    test-workflow-mode-rejects-an-unknown-configuration-key \
    test-workflow-mode-rejects-a-default-that-names-no-mode \
    test-workflow-mode-rejects-an-unsafe-skill-pattern \
    test-workflow-mode-rejects-an-empty-drop-in \
    test-workflow-mode-rejects-a-mode-repeated-in-one-file \
    test-workflow-mode-rejects-drop-in-names-that-are-not-plain-ascii \
    test-workflow-mode-rejects-an-unknown-command \
    test-workflow-mode-hook-describes-the-active-mode-at-session-start \
    test-workflow-mode-hook-describes-the-active-mode-to-a-subagent \
    test-workflow-mode-hook-names-the-skills-only-the-user-can-start \
    test-workflow-mode-hook-never-forbids-a-skill-of-the-active-mode-with-three-modes \
    test-workflow-mode-hook-asks-for-a-mode-when-none-is-active \
    test-workflow-mode-hook-says-nothing-without-modes \
    test-workflow-mode-hook-reports-an-undefined-chosen-mode \
    test-workflow-mode-hook-reports-an-unreadable-state-file \
    test-workflow-mode-hook-denies-a-skill-of-another-mode \
    test-workflow-mode-hook-names-every-mode-that-owns-a-refused-skill \
    test-workflow-mode-hook-allows-a-skill-of-the-active-mode \
    test-workflow-mode-hook-allows-a-skill-that-two-modes-share \
    test-workflow-mode-hook-allows-a-skill-no-mode-owns \
    test-workflow-mode-hook-allows-every-skill-without-an-active-mode \
    test-workflow-mode-hook-allows-skills-when-the-chosen-mode-is-not-defined \
    test-workflow-mode-hook-ignores-other-tools \
    test-workflow-mode-hook-fails-open-on-an-invalid-payload \
    test-workflow-mode-hook-fails-open-on-an-invalid-configuration \
    test-workflow-mode-hook-tells-the-agent-when-the-check-cannot-run \
    test-workflow-mode-hook-tells-the-agent-when-only-the-loadout-modes-exist \
    test-workflow-mode-hook-fails-open-when-jq-cannot-run \
    test-workflow-mode-hook-tells-the-agent-when-jq-cannot-run \
    test-workflow-mode-hook-runs-with-the-system-bash \
    test-workflow-mode-registers-the-hook-events \
    test-workflow-mode-loadout-defines-speckit-and-superpowers

  return 0
}

# ==============================================================================
# Helpers

# Build the committed fixture repository once, every test starts from a copy.
function test-suite-setup() {

  local repo="$SUITE_TMP/repo-template"
  test-create-repo "$repo" \
    scripts/hooks/workflow-mode.sh \
    scripts/hooks/workflow-mode.jq \
    "$BASE_CONFIG"
  printf 'version: 1\nmodes: []\n' > "$repo/$BASE_CONFIG"
  mkdir -p "$repo/${DROP_IN%/*}"
  printf '%s\n' "$TWO_MODES" > "$repo/$DROP_IN"
  git -C "$repo" add -A
  git -C "$repo" commit -q -m modes

  return 0
}

# Copy the fixture repository to "$TEST_TMP/repo", keep only the base tools,
# jq and yq on PATH and change into it.
function mode-create-repo() {

  cp -Rp "$SUITE_TMP/repo-template" "$TEST_TMP/repo"
  test-isolate-path jq yq
  cd "$TEST_TMP/repo"

  return 0
}

# Replace the fixture drop-in file.
# Arguments:
#   $1=[YAML content]
function mode-write-drop-in() {

  printf '%s\n' "$1" > "$DROP_IN"

  return 0
}

# Send a hook event to the script on stdin.
# Arguments:
#   $1=[event JSON]
function mode-hook() {

  printf '%s\n' "$1" | "$SCRIPT" hook

  return 0
}

# Print a PreToolUse event for a call of the skill tool.
# Arguments:
#   $1=[skill name]
function mode-skill-event() {

  jq -nc --arg skill "$1" '{hook_event_name: "PreToolUse", session_id: "s1", tool_name: "skill", tool_input: {skill: $skill}}'

  return 0
}

# Fail unless the hook output is valid JSON with no permission decision and no
# context.
# Arguments:
#   $1=[hook output]
function assert-hook-allows() {

  assert-equal '{}' "$(jq -c . <<< "$1")" 'hook output'

  return 0
}

# Install a skill in the repository.
# Arguments:
#   $1=[skill name]
#   $2=[extra front matter line, optional]
function mode-install-skill() {

  mkdir -p ".github/skills/$1"
  printf -- '---\nname: %s\ndescription: Test skill\n%s\n---\n\n# %s\n' "$1" "${2:-}" "$1" > ".github/skills/$1/SKILL.md"

  return 0
}

# ==============================================================================
# Commands

function test-workflow-mode-status-prints-none-without-modes() {

  # Arrange
  mode-create-repo
  rm "$DROP_IN"
  # Act
  test-capture "$SCRIPT" status
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-equal $'Workflow mode: none\n  Why          no modes are defined\n  To add       create scripts/config/workflow-modes.d/<name>.yaml, see\n               '"$GUIDE" "$TEST_STDOUT"
  assert-equal "" "$TEST_STDERR" 'stderr'

  return 0
}

function test-workflow-mode-status-prints-the-default-mode() {

  # Arrange
  mode-create-repo
  # Act
  test-capture "$SCRIPT" status
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-equal "$DEFAULT_STATUS" "$TEST_STDOUT"
  assert-equal "" "$TEST_STDERR" 'stderr'

  return 0
}

function test-workflow-mode-status-explains-why-no-mode-is-active() {

  # Arrange
  mode-create-repo
  mode-write-drop-in $'version: 1\nmodes:\n  - name: alpha\n  - name: beta'
  # Act
  test-capture "$SCRIPT" status
  # Assert
  assert-equal $'Workflow mode: none\n  Why          no mode is chosen and no default is set\n  Modes        alpha, beta\n  To choose    make workflow-use mode=<name>, then start a new chat session' "$TEST_STDOUT"

  return 0
}

function test-workflow-mode-status-wraps-long-rows() {

  # Arrange
  mode-create-repo
  mode-write-drop-in $'version: 1\ndefault: gamma\nmodes:\n  - name: gamma\n    skills: [first-long-skill-name, second-long-skill-name, third-long-skill-name, fourth]'
  # Act
  test-capture "$SCRIPT" status
  # Assert
  assert-contains "$TEST_STDOUT" $'\n  Skills       first-long-skill-name, second-long-skill-name,\n               third-long-skill-name, fourth\n'

  return 0
}

function test-workflow-mode-use-sets-the-active-mode() {

  # Arrange
  mode-create-repo
  # Act
  test-capture env mode=beta "$SCRIPT" use
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-equal $'Chose beta for this worktree. Start a new chat session so that the agent uses it.\n\nWorkflow mode: beta (chosen for this worktree)\n  Skills       beta-?, shared\n  Set by       make workflow-use (make workflow-clear returns to alpha)\n  Other modes  alpha\n  To change    make workflow-use mode=alpha, then start a new chat session' "$TEST_STDOUT"
  assert-file-has-line "$(git rev-parse --git-path workflow-mode)" beta
  test-capture env mode=beta "$SCRIPT" use
  assert-contains "$TEST_STDOUT" $'beta is already chosen for this worktree.\n\nWorkflow mode: beta'

  return 0
}

function test-workflow-mode-use-requires-a-mode() {

  # Arrange
  mode-create-repo
  # Act
  test-capture "$SCRIPT" use
  # Assert
  assert-equal 1 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-equal "ERROR: name the mode to use, as in 'make workflow-use mode=<name>'. The modes are: alpha, beta." "$TEST_STDERR"
  assert-file-not-exists "$(git rev-parse --git-path workflow-mode)"

  return 0
}

function test-workflow-mode-use-rejects-a-malformed-name() {

  # Arrange
  mode-create-repo
  # Act
  test-capture env mode=../beta "$SCRIPT" use
  # Assert
  assert-equal 1 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-equal "ERROR: there is no workflow mode '../beta'. The modes are: alpha, beta." "$TEST_STDERR"
  assert-file-not-exists "$(git rev-parse --git-path workflow-mode)"

  return 0
}

function test-workflow-mode-use-rejects-an-undefined-mode() {

  # Arrange
  mode-create-repo
  rm "$DROP_IN"
  # Act
  test-capture env mode=gamma "$SCRIPT" use
  # Assert
  assert-equal 1 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-equal "ERROR: there is no workflow mode 'gamma'. No modes are defined, add them in scripts/config/workflow-modes.d/<name>.yaml." "$TEST_STDERR"
  assert-file-not-exists "$(git rev-parse --git-path workflow-mode)"

  return 0
}

function test-workflow-mode-clear-restores-the-default() {

  # Arrange
  mode-create-repo
  env mode=beta "$SCRIPT" use > /dev/null 2>&1
  # Act
  test-capture "$SCRIPT" clear
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-equal $'Cleared the mode chosen for this worktree. Start a new chat session so that the agent uses the mode below.\n\n'"$DEFAULT_STATUS" "$TEST_STDOUT"
  assert-file-not-exists "$(git rev-parse --git-path workflow-mode)"
  test-capture "$SCRIPT" clear
  assert-contains "$TEST_STDOUT" $'No mode was chosen for this worktree, so nothing changed.\n\nWorkflow mode: alpha (default)'

  return 0
}

function test-workflow-mode-status-fails-when-the-chosen-mode-is-not-defined() {

  # Arrange
  mode-create-repo
  printf 'gamma\n' > "$(git rev-parse --git-path workflow-mode)"
  # Act
  test-capture "$SCRIPT" status
  # Assert
  assert-equal 1 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-equal "" "$TEST_STDOUT"
  assert-contains "$TEST_STDERR" "'gamma', is not defined. The modes are: alpha, beta."
  assert-contains "$TEST_STDERR" "make workflow-clear"

  return 0
}

function test-workflow-mode-fails-when-the-state-file-cannot-be-read() {

  # Arrange
  mode-create-repo
  env mode=beta "$SCRIPT" use > /dev/null 2>&1
  local file
  file="$(git rev-parse --git-path workflow-mode)"
  chmod 000 "$file"
  # Act
  test-capture "$SCRIPT" status
  # Assert
  assert-equal 1 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-equal "" "$TEST_STDOUT"
  assert-contains "$TEST_STDERR" "ERROR: cannot read the workflow mode chosen for this worktree from $file"
  assert-contains "$TEST_STDERR" "make workflow-clear"
  test-capture "$SCRIPT" clear
  assert-equal 0 "$TEST_STATUS" 'clear recovers'

  return 0
}

function test-workflow-mode-reports-a-state-path-that-is-not-a-file() {

  # Arrange
  mode-create-repo
  local file
  file="$(git rev-parse --git-path workflow-mode)"
  mkdir "$file"
  # Act
  test-capture env mode=beta "$SCRIPT" use
  local use_status="$TEST_STATUS" use_stderr="$TEST_STDERR"
  test-capture "$SCRIPT" clear
  # Assert
  assert-equal 1 "$use_status" 'use exit status'
  assert-contains "$use_stderr" "ERROR: $file is not a file. Remove it, then run the command again."
  assert-equal 1 "$TEST_STATUS" 'clear exit status'
  assert-contains "$TEST_STDERR" "ERROR: $file is not a file. Remove it, then run the command again."

  return 0
}

function test-workflow-mode-keeps-the-mode-per-worktree() {

  # Arrange
  mode-create-repo
  git worktree add -q "$TEST_TMP/other" 2> /dev/null
  # Act
  (cd "$TEST_TMP/other" && env mode=beta "$SCRIPT" use > /dev/null 2>&1)
  test-capture "$SCRIPT" status
  # Assert
  assert-contains "$TEST_STDOUT" "Workflow mode: alpha (default)" 'mode of the main worktree'
  test-capture bash -c 'cd "$1" && "$2" status' _ "$TEST_TMP/other" "$SCRIPT"
  assert-contains "$TEST_STDOUT" "Workflow mode: beta (chosen for this worktree)" 'mode of the linked worktree'

  return 0
}

function test-workflow-mode-lists-the-modes-and-marks-the-active-one() {

  # Arrange
  mode-create-repo
  # Act
  test-capture "$SCRIPT" list
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-matches "$TEST_STDOUT" '^ACTIVE +NAME +SKILLS +DESCRIPTION'
  assert-matches "$TEST_STDOUT" $'\ndefault +alpha +alpha-\\*,shared +First way of working'
  assert-matches "$TEST_STDOUT" $'\n +beta +beta-\\?,shared'
  env mode=beta "$SCRIPT" use > /dev/null 2>&1
  test-capture "$SCRIPT" list
  assert-matches "$TEST_STDOUT" $'\nchosen +beta +beta-\\?,shared'

  return 0
}

function test-workflow-mode-list-shortens-long-skill-lists() {

  # Arrange
  mode-create-repo
  mode-write-drop-in $'version: 1\nmodes:\n  - name: gamma\n    description: Long\n    skills: [first-long-skill-name, second-long-skill-name, third]'
  # Act
  test-capture "$SCRIPT" list
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-matches "$TEST_STDOUT" $'\n +gamma +first-long-skill-name,\\.\\.\\. +Long$'

  return 0
}

function test-workflow-mode-list-says-when-no-mode-is-defined() {

  # Arrange
  mode-create-repo
  rm "$DROP_IN"
  # Act
  test-capture "$SCRIPT" list
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-equal "No workflow modes are defined. Add them in scripts/config/workflow-modes.d/<name>.yaml, see $GUIDE." "$TEST_STDOUT"

  return 0
}

function test-workflow-mode-list-checks-the-patterns-against-installed-skills() {

  # Arrange
  mode-create-repo
  mode-install-skill alpha-guide 'disable-model-invocation: true'
  mode-install-skill alpha-tool
  mode-install-skill shared
  # A later line that only looks like the setting is not front matter
  printf 'disable-model-invocation: true\n' >> .github/skills/alpha-tool/SKILL.md
  # Act
  test-capture "$SCRIPT" list
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-matches "$TEST_STDOUT" $'\ndefault +alpha +alpha-\\*,shared +First way of working'
  assert-equal $'Note: mode alpha owns 1 skill that only the user can start with a slash command, so the hook never checks it.\nWARNING: mode beta: the pattern \'beta-?\' matches no skill in .github/skills.' "$TEST_STDERR"

  return 0
}

function test-workflow-mode-drop-ins-override-modes-by-name-in-byte-order() {

  # Arrange
  # In byte order 'Zz.yaml' sorts before 'test.yaml' and 'u.yaml' after it,
  # while a case-insensitive order puts 'Zz.yaml' last
  mode-create-repo
  printf 'version: 1\nmodes:\n  - name: alpha\n    description: Lower\n' > scripts/config/workflow-modes.d/Zz.yaml
  printf 'version: 1\nmodes:\n  - name: alpha\n    description: Upper\n' > scripts/config/workflow-modes.d/u.yaml
  # Act
  test-capture "$SCRIPT" list
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-matches "$TEST_STDOUT" $'\ndefault +alpha +alpha-\\*,shared +Upper'

  return 0
}

function test-workflow-mode-warns-about-a-symlinked-drop-in() {

  # Arrange
  mode-create-repo
  mv "$DROP_IN" "$TEST_TMP/modes.yaml"
  ln -s "$TEST_TMP/modes.yaml" "$DROP_IN"
  # Act
  test-capture "$SCRIPT" status
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-contains "$TEST_STDOUT" "Workflow mode: none"
  assert-contains "$TEST_STDERR" "WARNING: $DROP_IN is a symbolic link, so it is skipped."

  return 0
}

function test-workflow-mode-rejects-an-unknown-configuration-key() {

  # Arrange
  mode-create-repo
  mode-write-drop-in $'version: 1\nmodes:\n  - name: alpha\n    skill: [x]'
  # Act
  test-capture "$SCRIPT" status
  # Assert
  assert-equal 2 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-contains "$TEST_STDERR" "ERROR: $DROP_IN: mode alpha: unknown key(s): skill. Allowed keys: name, skills, description"

  return 0
}

function test-workflow-mode-rejects-a-default-that-names-no-mode() {

  # Arrange
  mode-create-repo
  mode-write-drop-in $'version: 1\ndefault: gamma\nmodes:\n  - name: alpha'
  # Act
  test-capture "$SCRIPT" status
  # Assert
  assert-equal 2 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-contains "$TEST_STDERR" "ERROR: $DROP_IN: default 'gamma' must name a defined mode, which is one of: alpha"

  return 0
}

function test-workflow-mode-rejects-an-unsafe-skill-pattern() {

  # Arrange
  mode-create-repo
  mode-write-drop-in $'version: 1\nmodes:\n  - name: alpha\n    skills: ["a|b"]'
  # Act
  test-capture "$SCRIPT" status
  # Assert
  assert-equal 2 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-contains "$TEST_STDERR" "ERROR: $DROP_IN: mode alpha: skills must be a list of skill name patterns"

  return 0
}

function test-workflow-mode-rejects-an-empty-drop-in() {

  # Arrange
  mode-create-repo
  : > "$DROP_IN"
  # Act
  test-capture "$SCRIPT" status
  # Assert
  assert-equal 2 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-contains "$TEST_STDERR" "ERROR: $DROP_IN: the file must be a mapping that starts with 'version: 1'"

  return 0
}

function test-workflow-mode-rejects-a-mode-repeated-in-one-file() {

  # Arrange
  mode-create-repo
  mode-write-drop-in $'version: 1\nmodes:\n  - name: alpha\n  - name: alpha'
  # Act
  test-capture "$SCRIPT" status
  # Assert
  assert-equal 2 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-contains "$TEST_STDERR" "ERROR: $DROP_IN: mode alpha is defined more than once"

  return 0
}

function test-workflow-mode-rejects-drop-in-names-that-are-not-plain-ascii() {

  # Arrange
  mode-create-repo
  printf 'version: 1\n' > 'scripts/config/workflow-modes.d/bad name.yaml'
  # Act
  test-capture "$SCRIPT" status
  # Assert
  assert-equal 2 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-contains "$TEST_STDERR" "bad name.yaml: drop-in file names may use only"

  return 0
}

function test-workflow-mode-rejects-an-unknown-command() {

  # Arrange
  mode-create-repo
  # Act
  test-capture "$SCRIPT" switch
  # Assert
  assert-equal 126 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-contains "$TEST_STDERR" "Unrecognised command: 'switch'"

  return 0
}

# ==============================================================================
# Hook

function test-workflow-mode-hook-describes-the-active-mode-at-session-start() {

  # Arrange
  mode-create-repo
  # Act
  test-capture mode-hook "$SESSION_START"
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  local context
  context="$(jq -r .additionalContext <<< "$TEST_STDOUT")"
  assert-contains "$context" "'alpha' is active in this worktree"
  assert-contains "$context" "First way of working"
  assert-contains "$context" "Skills of this mode: alpha-*, shared"
  assert-contains "$context" $'unless this mode also owns them:\n- beta: beta-?\n'
  assert-not-contains "$context" "beta-?, shared" 'shared skill listed as forbidden'
  assert-equal "$context" "$(jq -r .hookSpecificOutput.additionalContext <<< "$TEST_STDOUT")" 'Local harness context'
  assert-equal SessionStart "$(jq -r .hookSpecificOutput.hookEventName <<< "$TEST_STDOUT")"
  assert-not-contains "$context" "slash commands" 'user-only skills without any installed'

  return 0
}

function test-workflow-mode-hook-describes-the-active-mode-to-a-subagent() {

  # Arrange
  mode-create-repo
  # Act
  test-capture mode-hook '{"hook_event_name":"SubagentStart","agent_id":"a1","agent_type":"Plan"}'
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-contains "$(jq -r .additionalContext <<< "$TEST_STDOUT")" "'alpha' is active in this worktree"
  assert-equal SubagentStart "$(jq -r .hookSpecificOutput.hookEventName <<< "$TEST_STDOUT")"

  return 0
}

function test-workflow-mode-hook-names-the-skills-only-the-user-can-start() {

  # Arrange
  mode-create-repo
  mode-install-skill alpha-guide 'disable-model-invocation: true'
  mode-install-skill alpha-tool
  mode-install-skill beta-1 'disable-model-invocation: true'
  # Act
  test-capture mode-hook "$SESSION_START"
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  local context
  context="$(jq -r .additionalContext <<< "$TEST_STDOUT")"
  assert-contains "$context" $'\nThe user starts these skills of this mode with slash commands: /alpha-guide. Suggest the next one when it fits. Do not load them or read their SKILL.md files yourself.\n'
  assert-not-contains "$context" "/alpha-tool" 'skill the agent may load'
  assert-not-contains "$context" "/beta-1" 'user-only skill of another mode'

  return 0
}

function test-workflow-mode-hook-never-forbids-a-skill-of-the-active-mode-with-three-modes() {

  # Arrange
  mode-create-repo
  mode-write-drop-in "$TWO_MODES"$'\n  - name: gamma\n    skills: [shared, alpha-1, gamma-*]\n  - name: delta\n    skills: [shared]'
  # Act
  test-capture mode-hook "$SESSION_START"
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  local context
  context="$(jq -r .additionalContext <<< "$TEST_STDOUT")"
  assert-contains "$context" $'- beta: beta-?\n- gamma: alpha-1, gamma-*\n'
  assert-not-contains "$context" "delta" 'mode whose skills the active mode all owns'
  test-capture mode-hook "$(mode-skill-event alpha-1)"
  assert-hook-allows "$TEST_STDOUT"

  return 0
}

function test-workflow-mode-hook-asks-for-a-mode-when-none-is-active() {

  # Arrange
  mode-create-repo
  mode-write-drop-in $'version: 1\nmodes:\n  - name: alpha\n    skills: [alpha-*]\n  - name: beta\n    skills: [beta-*]'
  # Act
  test-capture mode-hook "$SESSION_START"
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  local context
  context="$(jq -r .additionalContext <<< "$TEST_STDOUT")"
  assert-contains "$context" "Workflow mode: no workflow mode is active in this worktree."
  assert-contains "$context" $'- alpha: alpha-*\n- beta: beta-*\n'
  assert-contains "$context" "make workflow-use mode=<name>"

  return 0
}

function test-workflow-mode-hook-says-nothing-without-modes() {

  # Arrange
  mode-create-repo
  rm "$DROP_IN"
  # Act
  test-capture mode-hook "$SESSION_START"
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-hook-allows "$TEST_STDOUT"

  return 0
}

function test-workflow-mode-hook-reports-an-undefined-chosen-mode() {

  # Arrange
  mode-create-repo
  printf 'gamma\n' > "$(git rev-parse --git-path workflow-mode)"
  # Act
  test-capture mode-hook "$SESSION_START"
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  local context
  context="$(jq -r .additionalContext <<< "$TEST_STDOUT")"
  assert-contains "$context" "the workflow mode chosen for this worktree, 'gamma', is not defined, so no mode is enforced"
  assert-contains "$context" "The defined modes are: alpha, beta."
  assert-contains "$context" "Do not run these commands yourself."

  return 0
}

function test-workflow-mode-hook-reports-an-unreadable-state-file() {

  # Arrange
  mode-create-repo
  env mode=beta "$SCRIPT" use > /dev/null 2>&1
  chmod 000 "$(git rev-parse --git-path workflow-mode)"
  # Act
  test-capture mode-hook "$SESSION_START"
  local context
  context="$(jq -r .additionalContext <<< "$TEST_STDOUT")"
  test-capture mode-hook "$(mode-skill-event beta-1)"
  # Assert
  assert-contains "$context" "cannot be read, so no mode is enforced"
  assert-hook-allows "$TEST_STDOUT"

  return 0
}

function test-workflow-mode-hook-denies-a-skill-of-another-mode() {

  # Arrange
  mode-create-repo
  # Act
  test-capture mode-hook "$(mode-skill-event beta-1)"
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-equal deny "$(jq -r "$DENY" <<< "$TEST_STDOUT")" 'Copilot decision'
  assert-equal deny "$(jq -r ".hookSpecificOutput$DENY" <<< "$TEST_STDOUT")" 'Local harness decision'
  assert-equal PreToolUse "$(jq -r .hookSpecificOutput.hookEventName <<< "$TEST_STDOUT")"
  local reason
  reason="$(jq -r .permissionDecisionReason <<< "$TEST_STDOUT")"
  assert-contains "$reason" "'beta-1' belongs to the workflow mode 'beta'"
  assert-contains "$reason" "'alpha' is active"
  assert-contains "$reason" "make workflow-use mode=beta"
  assert-contains "$reason" "even if this session started in another mode"
  assert-contains "$reason" "Continue the task without this skill. If the user wants it, they can run 'make workflow-use mode=beta' and start a new chat session."
  assert-contains "$reason" "Do not run that command yourself or read the skill's SKILL.md instead."
  assert-not-contains "$reason" "stop" 'a refused skill must not end the task'
  assert-not-contains "$reason" "Use the skills of" 'the active mode may have no skill the agent can load'

  return 0
}

function test-workflow-mode-hook-names-every-mode-that-owns-a-refused-skill() {

  # Arrange
  mode-create-repo
  mode-write-drop-in "$TWO_MODES"$'\n  - name: gamma\n    skills: [beta-1]'
  # Act
  test-capture mode-hook "$(mode-skill-event beta-1)"
  # Assert
  local reason
  reason="$(jq -r .permissionDecisionReason <<< "$TEST_STDOUT")"
  assert-contains "$reason" "belongs to the workflow modes 'beta' and 'gamma'"
  assert-contains "$reason" "'make workflow-use mode=<name>' with one of beta, gamma"

  return 0
}

function test-workflow-mode-hook-allows-a-skill-of-the-active-mode() {

  # Arrange
  mode-create-repo
  env mode=beta "$SCRIPT" use > /dev/null 2>&1
  # Act
  test-capture mode-hook "$(mode-skill-event beta-1)"
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-hook-allows "$TEST_STDOUT"

  return 0
}

function test-workflow-mode-hook-allows-a-skill-that-two-modes-share() {

  # Arrange
  mode-create-repo
  # Act
  test-capture mode-hook "$(mode-skill-event shared)"
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-hook-allows "$TEST_STDOUT"

  return 0
}

function test-workflow-mode-hook-allows-a-skill-no-mode-owns() {

  # Arrange
  mode-create-repo
  # Act
  # 'beta-12' is outside the one-character pattern 'beta-?', and 'Xbeta-1'
  # shows that patterns are anchored
  test-capture mode-hook "$(mode-skill-event beta-12)"
  local long="$TEST_STDOUT"
  test-capture mode-hook "$(mode-skill-event Xbeta-1)"
  # Assert
  assert-hook-allows "$long"
  assert-hook-allows "$TEST_STDOUT"

  return 0
}

function test-workflow-mode-hook-allows-every-skill-without-an-active-mode() {

  # Arrange
  mode-create-repo
  mode-write-drop-in $'version: 1\nmodes:\n  - name: alpha\n    skills: [alpha-*]\n  - name: beta\n    skills: [beta-*]'
  # Act
  test-capture mode-hook "$(mode-skill-event beta-1)"
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-hook-allows "$TEST_STDOUT"

  return 0
}

function test-workflow-mode-hook-allows-skills-when-the-chosen-mode-is-not-defined() {

  # Arrange
  mode-create-repo
  printf 'gamma\n' > "$(git rev-parse --git-path workflow-mode)"
  # Act
  test-capture mode-hook "$(mode-skill-event beta-1)"
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-hook-allows "$TEST_STDOUT"

  return 0
}

function test-workflow-mode-hook-ignores-other-tools() {

  # Arrange
  mode-create-repo
  # Act
  test-capture mode-hook '{"hook_event_name":"PreToolUse","tool_name":"read_file","tool_input":{"skill":"beta-1"}}'
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-hook-allows "$TEST_STDOUT"

  return 0
}

function test-workflow-mode-hook-fails-open-on-an-invalid-payload() {

  # Arrange
  mode-create-repo
  # Act
  test-capture mode-hook 'not json'
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-hook-allows "$TEST_STDOUT"
  assert-contains "$TEST_STDERR" "ERROR: workflow mode hook: the event is not valid JSON"

  return 0
}

function test-workflow-mode-hook-fails-open-on-an-invalid-configuration() {

  # Arrange
  mode-create-repo
  mode-write-drop-in 'version: 2'
  # Act
  test-capture mode-hook "$(mode-skill-event beta-1)"
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-hook-allows "$TEST_STDOUT"
  assert-contains "$TEST_STDERR" "version must be 1"

  return 0
}

function test-workflow-mode-hook-tells-the-agent-when-the-check-cannot-run() {

  # Arrange
  mode-create-repo
  mode-write-drop-in 'version: 2'
  # Act
  test-capture mode-hook "$SESSION_START"
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-contains "$(jq -r .additionalContext <<< "$TEST_STDOUT")" "the workflow mode check could not run, so no mode is enforced. Tell the user to run 'make workflow-status' to see why."

  return 0
}

# Loadout defines its modes in the base file, so a destination may have no
# drop-in file at all
function test-workflow-mode-hook-tells-the-agent-when-only-the-loadout-modes-exist() {

  # Arrange
  mode-create-repo
  rm "$DROP_IN"
  cp "$TEST_REPO_ROOT/$BASE_CONFIG" "$BASE_CONFIG"
  test-stub jq 'exit 1'
  # Act
  test-capture mode-hook '{"hook_event_name": "SubagentStart"}'
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-contains "$TEST_STDOUT" '"additionalContext":"Workflow mode: the workflow mode check could not run'
  assert-contains "$TEST_STDOUT" '"hookEventName":"SubagentStart"'

  return 0
}

function test-workflow-mode-hook-fails-open-when-jq-cannot-run() {

  # Arrange
  mode-create-repo
  local event
  event="$(mode-skill-event beta-1)"
  test-stub jq 'exit 1'
  # Act
  test-capture mode-hook "$event"
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-equal '{}' "$TEST_STDOUT"
  assert-contains "$TEST_STDERR" "cannot run jq"

  return 0
}

function test-workflow-mode-hook-tells-the-agent-when-jq-cannot-run() {

  # Arrange
  mode-create-repo
  test-stub jq 'exit 1'
  # Act
  test-capture mode-hook '{"hook_event_name": "SessionStart"}'
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-contains "$TEST_STDOUT" '"additionalContext":"Workflow mode: the workflow mode check could not run'
  assert-contains "$TEST_STDOUT" '"hookEventName":"SessionStart"'

  return 0
}

function test-workflow-mode-hook-runs-with-the-system-bash() {

  # Arrange
  # On macOS /bin/bash is Bash 3.2, which the editor may start
  mode-create-repo
  local event
  event="$(mode-skill-event beta-1)"
  # Act
  test-capture bash -c 'printf "%s\n" "$1" | /bin/bash "$2" hook' _ "$event" "$SCRIPT"
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-equal deny "$(jq -r "$DENY" <<< "$TEST_STDOUT")"
  assert-equal "" "$TEST_STDERR" 'stderr'

  return 0
}

function test-workflow-mode-registers-the-hook-events() {

  # Arrange
  local file="$TEST_REPO_ROOT/.github/hooks/workflow-mode.json"
  # Act
  test-capture jq -r '[.version, (.hooks | keys | join(" ")), ([.hooks[][].command] | unique | join(" ")), .hooks.PreToolUse[0].matcher] | join("|")' "$file"
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-equal "1|PreToolUse SessionStart SubagentStart|$SCRIPT hook|skill" "$TEST_STDOUT"
  # Without Bash on Windows a failed PreToolUse hook would deny every skill,
  # and a hook started outside the repository root would not find the script
  test-capture jq -r '[.hooks[][] | "\(.powershell)|\(.cwd)"] | unique | join(" ")' "$file"
  assert-equal "Write-Output '{}'|." "$TEST_STDOUT"

  return 0
}

function test-workflow-mode-loadout-defines-speckit-and-superpowers() {

  # Arrange
  mode-create-repo
  rm "$DROP_IN"
  cp "$TEST_REPO_ROOT/$BASE_CONFIG" "$BASE_CONFIG"
  # Act
  test-capture "$SCRIPT" list
  # Assert
  assert-equal 0 "$TEST_STATUS" "$EXIT_STATUS_LABEL"
  assert-matches "$TEST_STDOUT" $'\n +speckit +speckit-\\* +Specification-driven delivery'
  assert-matches "$TEST_STDOUT" $'\ndefault +superpowers +brainstorming,'
  # Superpowers owns only the skills that write or read its own artefacts
  test-capture yq -r '.modes[] | select(.name == "superpowers") | .skills | join(",")' "$BASE_CONFIG"
  assert-equal "brainstorming,writing-plans,executing-plans,subagent-driven-development" "$TEST_STDOUT"

  return 0
}

# ==============================================================================

main "$@"

exit 0
