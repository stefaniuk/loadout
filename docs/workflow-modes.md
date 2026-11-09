# Use workflow modes 🔀

- [Use workflow modes 🔀](#use-workflow-modes-)
  - [Overview 🧭](#overview-)
  - [Key files 📁](#key-files-)
  - [The loadout modes 🧩](#the-loadout-modes-)
  - [Choose a mode 🤔](#choose-a-mode-)
  - [Switch modes 🔁](#switch-modes-)
  - [Example sessions 💬](#example-sessions-)
    - [Spec Kit session](#spec-kit-session)
    - [Superpowers session](#superpowers-session)
  - [How the agent keeps to the mode 🚧](#how-the-agent-keeps-to-the-mode-)
    - [What the hook can see](#what-the-hook-can-see)
    - [Limits](#limits)
  - [Add or change a mode 🔧](#add-or-change-a-mode-)
  - [Move from the old workflow switch 🚚](#move-from-the-old-workflow-switch-)
  - [Troubleshooting 🔍](#troubleshooting-)
  - [Testing 🧪](#testing-)

## Overview 🧭

A repository can hold more than one set of agent skills for the same job. Two
lifecycle workflows both say how to go from an idea to merged code, but in
different ways. When an agent mixes them, it writes a specification with one
workflow and a plan with another, and neither set of artefacts is complete.

A workflow mode prevents that. A mode is a named set of skills for one way of
working. One mode is active per worktree. The agent hears which mode is active
when a chat session or a subagent starts, and Copilot refuses a skill that only
another mode owns. Skills that no mode owns, such as `systematic-debugging`,
stay available in every mode.

Loadout installs the skills of two lifecycle workflows,
[Spec Kit](https://github.com/github/spec-kit) and
[Superpowers](https://github.com/obra/superpowers), and defines a mode for each.
`make apply` installs the hook, the script and the modes in the destination
repository, next to the skills.

## Key files 📁

- Scripts
  - [`workflow-mode.sh`](../scripts/hooks/workflow-mode.sh): command line and
    hook handler
  - [`workflow-mode.jq`](../scripts/hooks/workflow-mode.jq): validates the
    configuration and decides what the agent may use
- Configuration
  - [`workflow-modes.yaml`](../scripts/hooks/workflow-modes.yaml): the loadout
    modes, overwritten by every `make apply`
  - `scripts/config/workflow-modes.d/*.yaml`: the changes and modes of a
    project, which `make apply` never touches
  - [`workflow-mode.json`](../.github/hooks/workflow-mode.json): registers the
    hooks
  - [`loadout.ext.mk`](../scripts/loadout.ext.mk): make targets, loaded by the
    repository-template `scripts/init.mk`
- Tests
  - [`workflow-mode.test.sh`](../scripts/tests/workflow-mode.test.sh)

## The loadout modes 🧩

[`workflow-modes.yaml`](../scripts/hooks/workflow-modes.yaml) defines:

```yaml
version: 1

default: superpowers

modes:
  - name: speckit
    description: >-
      Specification-driven delivery. Durable spec, plan and tasks under specs/.
    skills:
      - speckit-*

  - name: superpowers
    description: >-
      Conversation-driven delivery. Design, plan, then test-driven execution.
    skills:
      - brainstorming
      - writing-plans
      - executing-plans
      - subagent-driven-development
```

Check them:

```shell
$ make workflow-list
ACTIVE   NAME                 SKILLS                                   DESCRIPTION
         speckit              speckit-*                                Specification-driven delivery. Durable spec, plan and tasks under specs/.
default  superpowers          brainstorming,writing-plans,...          Conversation-driven delivery. Design, plan, then test-driven execution.
Note: mode speckit owns 10 skills that only the user can start with a slash command, so the hook never checks them.
```

`ACTIVE` shows `default` for the default mode and `chosen` for a mode chosen
with `make workflow-use`. A long skills list is cut short with `...`. The lines
after the table compare the patterns with the skills in `.github/skills`. A
`WARNING` names a pattern that matches no skill, often a typo. A `Note` counts
the skills that only you can start, which the hook never sees, as
[What the hook can see](#what-the-hook-can-see) explains.

A mode owns only the skills that write or read its own artefacts. Skills such as
`test-driven-development`, `systematic-debugging`,
`verification-before-completion`, `using-git-worktrees`,
`dispatching-parallel-agents`, `incremental-implementation` and the code review
skills are in neither list. They help in both workflows, so they stay available
in both modes.

## Choose a mode 🤔

Both workflows take a change from an idea to a pull request. They differ in what
they leave behind and in how much ceremony they need.

| Question                               | Spec Kit                                                        | Superpowers                                                        |
| -------------------------------------- | --------------------------------------------------------------- | ------------------------------------------------------------------ |
| What is the main artefact?             | `specs/<feature>/spec.md`, `plan.md` and `tasks.md`             | `docs/superpowers/specs/*-design.md` and `docs/superpowers/plans/` |
| Who reads it after the change?         | Product, delivery and assurance people, and future teams        | Mainly the engineer and the reviewer                               |
| How are requirements found?            | Written as user stories and acceptance criteria, then clarified | Drawn out in a design conversation, one question at a time         |
| How is the work run?                   | Tasks in order, each with a Show & Tell check                   | Test first, often by subagents, in an isolated worktree            |
| How long does it take to start coding? | Longer, as the spec and the plan come first                     | Shorter, the design and the plan are lighter                       |

Use **Spec Kit** when:

- the change adds or changes behaviour that users, a product owner or an
  assurance process will review
- the feature spans several pull requests, people or teams, and they need one
  agreed description of what to build
- you must trace each requirement to the code and the tests, or check the code
  against the spec later with `speckit-converge`
- the project constitution must be applied or changed

Use **Superpowers** when:

- the change is a refactor, a bug fix, tooling or a technical improvement that
  fits in one pull request
- the design is still open and you want to explore options before you commit to
  one
- you want strict test-driven execution with review between tasks, run by
  subagents in a separate worktree

When in doubt, start in Superpowers. If the design conversation shows that the
change needs a durable specification, switch to Spec Kit before you plan.

## Switch modes 🔁

```shell
make workflow-status                 # show the active mode and how to change it
make workflow-list                   # list the modes and mark the active one
make workflow-use mode=speckit       # make a mode active in this worktree
make workflow-clear                  # forget the choice, so the default applies
```

`make workflow-status` shows the active mode, where it is set and how to change
it. `make workflow-use` and `make workflow-clear` say what they changed, then
show the same:

```text
$ make workflow-status
Workflow mode: superpowers (default)
  Description  Conversation-driven delivery. Design, plan, then test-driven
               execution.
  Skills       brainstorming, writing-plans, executing-plans,
               subagent-driven-development
  Set by       default in scripts/hooks/workflow-modes.yaml
  Other modes  speckit
  To change    make workflow-use mode=speckit, then start a new chat session
```

Start a new chat session after `make workflow-use`. The agent learns the mode
when a session starts, so an open session keeps its old view, although Copilot
refuses the skills of the other mode at once.

The choice is stored in the file that `git rev-parse --git-path workflow-mode`
names, usually `.git/workflow-mode`. It is kept per worktree and is never
committed. `make workflow-clear` removes it. All chat sessions in a worktree
share the mode. To run both workflows at the same time, use two worktrees:

```shell
git worktree add -b feature/payments-spec ../my-repo-spec
cd ../my-repo-spec && make workflow-use mode=speckit
```

A new worktree sees only committed files. The loadout files are git-ignored, so
run `make apply dest=../my-repo-spec` from loadout first, and commit any drop-in
file.

## Example sessions 💬

### Spec Kit session

```shell
make workflow-use mode=speckit
```

Open a new chat session and run the skills in order. In VS Code chat, type the
skill name as a slash command followed by your input.

1. `/speckit-specify Let patients cancel a booked appointment online` writes
   `specs/<nnn>-<feature>/spec.md` with user stories and acceptance criteria.
2. `/speckit-clarify` asks up to five questions and records the answers in the
   spec.
3. `/speckit-plan` writes `plan.md`, with the design and a Show & Tell check for
   each phase.
4. `/speckit-tasks` writes `tasks.md`, ordered by dependency.
5. `/speckit-analyze` checks that the spec, the plan and the tasks agree.
6. `/speckit-implement` works through the tasks.
7. `/speckit-converge` adds any work the code still lacks as new tasks.

Only you can start these skills. The session context lists them, so the agent
can suggest the next one. If the agent tries to load `brainstorming` in this
session, Copilot refuses it and the agent carries on without it.

### Superpowers session

```shell
make workflow-use mode=superpowers
```

Open a new chat session and describe the change. The agent picks the skills as
the work moves on.

1. "Retry failed uploads to the document store with back-off" starts
   `brainstorming`. The agent asks one question at a time and saves the agreed
   design to `docs/superpowers/specs/`.
2. `writing-plans` turns the design into small test-first steps in
   `docs/superpowers/plans/`.
3. `using-git-worktrees` creates an isolated worktree for the work.
4. `subagent-driven-development` runs each step with a fresh subagent and
   reviews it. Use `executing-plans` instead to run the plan in the current
   session.
5. `requesting-code-review` and `receiving-code-review` cover the review.
6. `finishing-a-development-branch` decides how to merge, open a pull request or
   clean up.

The worktree, review and finishing skills belong to no mode, so a Spec Kit
session can use them too. The agent cannot start `speckit-plan` in any mode, as
the Spec Kit skills start only from your slash commands.

## How the agent keeps to the mode 🚧

Three Copilot hooks in
[`workflow-mode.json`](../.github/hooks/workflow-mode.json) run
`workflow-mode.sh hook`:

- **Session or subagent start.** The hook adds the active mode, its skills and
  the skills of the other modes to the agent's context. It names the skills of
  the mode that only you can start, so the agent suggests them instead of
  loading them. With no active mode, it lists the modes and tells the agent to
  ask you to choose one.
- **Before a skill runs.** The hook refuses a call of the `skill` tool when only
  other modes own that skill. The refusal names every mode that owns it and the
  command that would switch, and tells the agent to carry on without the skill.
  It tells the agent not to run that command or read the skill's `SKILL.md`
  itself. The hook allows a skill that the active mode owns, even when other
  modes also own it, and a skill that no mode owns. It allows every skill when
  no mode is active or the chosen mode cannot be used.

The [Copilot instructions](../.github/copilot-instructions.md) tell the agent
that it must never change the mode itself.

### What the hook can see

The hook sees only the skills that the agent loads with the `skill` tool:

- A skill whose front matter sets `disable-model-invocation: true` starts only
  from your slash command, so the hook never sees it. Loadout sets this on every
  `speckit-*` skill. In practice the `speckit` mode refuses the four Superpowers
  lifecycle skills, and the `superpowers` mode refuses nothing the agent could
  otherwise load. There it only adds the context.
- When you start a skill with a slash command, the editor may load it without a
  `skill` tool call. The hook then does not check it, and your choice wins.

### Limits

- The guard stops mistakes. It is not a security control. It reads the working
  tree, so an agent that edits the configuration or runs `make workflow-use` can
  get round it.
- It checks only the `skill` tool. An agent that reads a `SKILL.md` file
  directly is not stopped, although the session context still tells it not to.
- The mode belongs to the worktree, not to a chat session.
- The hook fails open. When it cannot run, for example because `yq` is missing,
  it allows the call and writes the reason to stderr. Copilot would otherwise
  refuse every call while the hook is broken. When a session or a subagent
  starts, it tells the agent that no mode is enforced, so the agent can tell
  you.
- In the Copilot harness, a `PreToolUse` command that cannot start at all denies
  the call. Each hook entry therefore sets `cwd` to the repository root and has
  a PowerShell command that prints `{}`, so on Windows no mode is enforced and
  every skill stays usable.
- Copilot hooks are in preview. The tests use events in the format the VS Code
  Local harness sends. Confirm the hook in your harness with a new session.

## Add or change a mode 🔧

Put changes and new modes in `scripts/config/workflow-modes.d/*.yaml`, not in
`scripts/hooks/workflow-modes.yaml`, which `make apply` overwrites. The fields
are described at the top of
[`workflow-modes.yaml`](../scripts/hooks/workflow-modes.yaml):

- `name` is lower case and is what `make workflow-use mode=<name>` takes
- `skills` lists skill name patterns, where `*` is any characters and `?` is one
  character
- `description` is shown by `make workflow-list` and given to the agent
- `default` names a defined mode used when none was chosen

The merge rules:

- Every file starts with `version: 1`. Both `.yaml` and `.yml` work.
- Drop-in files are read in byte order of their names. A symbolic link is
  skipped with a warning, so copy the file instead.
- A mode name may appear once per file. A later file with the same mode name
  changes only the fields it sets. A list such as `skills` replaces the earlier
  list.
- A later `default` wins, and `default: null` clears it.

For example, this drop-in changes one description and keeps the skills:

```yaml
version: 1
modes:
  - name: speckit
    description: Specification-driven delivery for this team.
```

Run `make workflow-list` after a change. An invalid file stops the command with
the file and the field that are wrong, for example:

```text
ERROR: scripts/config/workflow-modes.d/team.yaml: mode speckit: unknown key(s): skill
```

Commit the drop-in file. A clone or a new worktree sees only committed modes,
and `make workflow-use` there fails with "there is no workflow mode" until it
does.

Do not add a mode check to the skills themselves. The hook enforces the mode for
every skill. A check written inside a skill reads its own state, can disagree
with the hook, and has to be kept in step with each skill update.

## Move from the old workflow switch 🚚

Older loadout versions kept the mode in `.copilot/workflow-mode.json` and put a
"Workflow Mode Guard" section in each lifecycle skill. `make apply` now:

- moves a mode chosen there to the file that `make workflow-use` writes, unless
  a mode is already chosen, and removes the old file
- removes `scripts/hooks/workflow-mode.lib.sh`
- installs skills without the guard sections

`make workflow-switch` is gone. Use `make workflow-use mode=<name>`.
`LOADOUT_WORKFLOW_MODE_FILE` is no longer read.

## Troubleshooting 🔍

- **`make workflow-status` shows `Workflow mode: none`.** Its `Why` line says
  whether no mode is defined or none is chosen and there is no `default`.
- **The chosen mode is not defined.** A mode was removed from the configuration
  after you chose it. Run `make workflow-use mode=<name>` or
  `make workflow-clear`.
- **The chosen mode cannot be read.** The file that holds the choice is not
  readable or is not a file. The error names it. Run `make workflow-clear`, or
  remove it by hand when it is a directory.
- **A drop-in file is skipped as a symbolic link.** Drop-in files must be
  regular files. Replace the link with a copy.
- **The agent did not mention the mode.** The context is added only when a
  session starts. Start a new chat session.
- **A skill was refused that should be shared.** Check its name against the
  patterns with `make workflow-list`. A skill owned by the active mode is always
  allowed, even when another mode also owns it.
- **`make workflow-list` warns that a pattern matches no skill.** Check the
  spelling in the drop-in file, or run `make apply` from loadout when the skill
  is not installed yet.

## Testing 🧪

Run the suite:

```shell
./scripts/tests/workflow-mode.test.sh
```

It runs the script in scratch repositories with two example modes, and covers
the commands, the configuration rules, the three hook events, the skills only
the user can start, failing open and the macOS Bash 3.2. It also checks the
loadout modes and the hook file. `make test` runs it with the other suites, and
`scripts/tests/apply.test.sh` covers the install, the move from the old switch
and revert.
