# Quick Reference

A single-page index of all prompts, agents, skills, hooks, and instructions in this repository.

## Customisation layers

```text
┌─────────────────────────────────────────────┐
│  Layer 5: Hooks (deterministic gates)       │
│  .github/hooks/*.json                       │
├─────────────────────────────────────────────┤
│  Layer 4: Skills (reusable capabilities)    │
│  .github/skills/*/SKILL.md                  │
├─────────────────────────────────────────────┤
│  Layer 3: Agents (personas + handoffs)      │
│  .github/agents/*.agent.md                  │
├─────────────────────────────────────────────┤
│  Layer 2: Prompts (one-off tasks)           │
│  .github/prompts/*.prompt.md                │
├─────────────────────────────────────────────┤
│  Layer 1: Instructions (standards + rules)  │
│  .github/instructions/*.instructions.md     │
│  .github/instructions/includes/*.include.md │
├─────────────────────────────────────────────┤
│  Layer 0: Governance (constitution + ADRs)  │
│  .specify/memory/constitution.md            │
│  docs/adr/                                  │
│  AGENTS.md                                  │
└─────────────────────────────────────────────┘
```

## Instructions (14)

File-scoped coding standards that Copilot applies automatically based on `applyTo` glob patterns.

| Instruction                             | Applies to                               | Description                         |
| --------------------------------------- | ---------------------------------------- | ----------------------------------- |
| `docker.instructions.md`                | `Dockerfile`, `compose.yaml`             | Docker and container best practices |
| `go.instructions.md`                    | `*.go`                                   | Go coding standards                 |
| `likec4.instructions.md`                | `*.likec4`, `*.c4`                       | LikeC4 architecture modelling       |
| `makefile.instructions.md`              | `Makefile`, `*.mk`                       | Makefile conventions                |
| `playwright-python.instructions.md`     | `*.py`                                   | Playwright testing with Python      |
| `playwright-typescript.instructions.md` | `*.ts`, `*.tsx`                          | Playwright testing with TypeScript  |
| `python.instructions.md`                | `*.py`                                   | Python coding standards             |
| `reactjs.instructions.md`               | `*.jsx`, `*.tsx`, `*.js`, `*.ts`         | React.js best practices             |
| `readme.instructions.md`                | `**/README.md`                           | README structure and content        |
| `rust.instructions.md`                  | `*.rs`                                   | Rust coding standards               |
| `shell.instructions.md`                 | `*.sh`, `*.bash`, `*.zsh`                | Shell scripting conventions         |
| `tauri.instructions.md`                 | `*.rs`, `*.ts`, `*.tsx`, `*.js`, `*.jsx` | Tauri desktop app development       |
| `terraform.instructions.md`             | `*.tf`                                   | Terraform infrastructure as code    |
| `typescript.instructions.md`            | `*.js`, `*.ts`, `*.tsx`                  | TypeScript coding standards         |

## Include baselines (7)

Shared knowledge blocks referenced by instructions and prompts.

| Include                                  | Purpose                              |
| ---------------------------------------- | ------------------------------------ |
| `ai-assisted-change-baseline.include.md` | AI-assisted change management rules  |
| `architecture-baseline.include.md`       | Architecture documentation standards |
| `cli-contract-baseline.include.md`       | CLI argument parsing contracts       |
| `local-first-dev-baseline.include.md`    | Local-first development patterns     |
| `observability-baseline.include.md`      | Logging and observability standards  |
| `playwright-baseline.include.md`         | Playwright testing patterns          |
| `quality-gates-baseline.include.md`      | Quality gate enforcement rules       |

## Prompts (37)

Slash commands invoked via `/prompt-name` in Copilot chat.

### Spec-kit lifecycle (9)

| Prompt                  | Description                           |
| ----------------------- | ------------------------------------- |
| `speckit.analyze`       | Cross-artifact consistency analysis   |
| `speckit.checklist`     | Generate domain-specific checklist    |
| `speckit.clarify`       | Clarify underspecified requirements   |
| `speckit.constitution`  | Create or update project constitution |
| `speckit.implement`     | Execute implementation tasks          |
| `speckit.plan`          | Create implementation plan            |
| `speckit.specify`       | Draft feature specification           |
| `speckit.tasks`         | Generate task breakdown               |
| `speckit.taskstoissues` | Convert tasks to GitHub issues        |

### Enforcement (12)

Thin wrappers that delegate to the `/enforcement-audit` skill.

| Prompt                          | Technology              |
| ------------------------------- | ----------------------- |
| `enforce.docker`                | Docker                  |
| `enforce.go`                    | Go                      |
| `enforce.makefile`              | Makefile                |
| `enforce.playwright-python`     | Playwright (Python)     |
| `enforce.playwright-typescript` | Playwright (TypeScript) |
| `enforce.python`                | Python                  |
| `enforce.reactjs`               | React.js                |
| `enforce.rust`                  | Rust                    |
| `enforce.shell`                 | Shell                   |
| `enforce.tauri`                 | Tauri                   |
| `enforce.terraform`             | Terraform               |
| `enforce.typescript`            | TypeScript              |

### Architecture (6)

Thin wrappers that delegate to the `/architecture-docs` skill.

| Prompt                                   | Step                   |
| ---------------------------------------- | ---------------------- |
| `architecture.01-repository-map`         | Repository map         |
| `architecture.02-component-catalogue`    | Component catalogue    |
| `architecture.03-runtime-flows`          | Runtime flows          |
| `architecture.04-domain-analysis`        | Domain analysis        |
| `architecture.05-c4-model`               | C4 model               |
| `architecture.06-infrastructure-diagram` | Infrastructure diagram |

### Review (3)

Thin wrappers that delegate to the `/code-review` skill.

| Prompt                         | Focus                 |
| ------------------------------ | --------------------- |
| `review.speckit-code`          | Code compliance       |
| `review.speckit-documentation` | Documentation quality |
| `review.speckit-test`          | Test coverage         |

### Development (3)

| Prompt                           | Purpose                             |
| -------------------------------- | ----------------------------------- |
| `dev.implement-cli-args-parsing` | CLI argument parsing implementation |
| `dev.implement-commands`         | Command implementation              |
| `dev.implement-logging`          | Logging implementation              |

### Utilities (4)

| Prompt                    | Purpose                     |
| ------------------------- | --------------------------- |
| `util.doc-readme-update`  | Update README documentation |
| `util.gh-pr-content`      | Generate PR description     |
| `util.gh-pr-review`       | Review a pull request       |
| `util.git-commit-message` | Generate commit message     |

## Agents (9)

Copilot agent personas with handoffs and tool restrictions. Select from the agent dropdown in VS Code.

| Agent                   | Description                 | Handoffs to                            | Tool restrictions       |
| ----------------------- | --------------------------- | -------------------------------------- | ----------------------- |
| `speckit.analyze`       | Cross-artifact analysis     | `speckit.implement`                    | Read-only               |
| `speckit.checklist`     | Domain checklist generation | `speckit.implement`                    | None                    |
| `speckit.clarify`       | Requirement clarification   | `speckit.plan`                         | Read + ask              |
| `speckit.constitution`  | Constitution management     | `speckit.specify`                      | None                    |
| `speckit.implement`     | Task execution              | `speckit.checklist`                    | None                    |
| `speckit.plan`          | Implementation planning     | `speckit.tasks`, `speckit.checklist`   | None                    |
| `speckit.specify`       | Specification drafting      | `speckit.plan`, `speckit.clarify`      | Read-only               |
| `speckit.tasks`         | Task breakdown              | `speckit.analyze`, `speckit.implement` | None                    |
| `speckit.taskstoissues` | Task-to-issue conversion    | `speckit.implement`                    | GitHub issue write only |

## Skills (6)

Reusable capabilities invoked via `/skill-name` with optional arguments.

| Skill                 | Description                           | Argument hint                                                 |
| --------------------- | ------------------------------------- | ------------------------------------------------------------- |
| `architecture-docs`   | Architecture documentation generation | Specify step: repository-map, component-catalogue, etc.       |
| `code-review`         | Structured spec-kit review            | Specify review type: code, documentation, or test             |
| `django-project`      | Django project scaffolding            | Describe the Django project to scaffold or evolve             |
| `enforcement-audit`   | Technology compliance audit           | Specify the technology to audit: python, typescript, go, etc. |
| `fastapi-project`     | FastAPI project scaffolding           | Describe the FastAPI project to scaffold or evolve            |
| `repository-template` | Repository tooling setup              | Describe what repository tooling to set up or update          |

## Hooks (1 configuration + 2 scripts)

VS Code agent hooks for deterministic quality enforcement.

| Hook                 | Event         | Script              | Purpose                                                  |
| -------------------- | ------------- | ------------------- | -------------------------------------------------------- |
| `quality-gates.json` | `PostToolUse` | `post-edit-lint.sh` | Runs `make lint` after file edits                        |
| `quality-gates.json` | `Stop`        | `stop-gate.sh`      | Blocks completion until `make lint` and `make test` pass |

## Distribution

### Via `make apply` (primary)

```bash
make apply dest=/path/to/target            # Default assets
make apply dest=/path/to/target all=true   # All technologies
make apply dest=/path/to/target revert=true # Remove managed assets
```

### Via plugin installation

1. `Cmd+Shift+P` → **Chat: Install Plugin From Source**
2. Enter: `https://github.com/stefaniuk/awesome-copilot-promptfiles`

Plugin provides skills, agents, and hooks. Use `make apply` for instructions and templates.

## Migration guidance

After modernisation, downstream repositories should:

1. Re-run `make apply dest=/path/to/target` to receive new assets:
   - `AGENTS.md` — cross-agent always-on instructions
   - `.github/hooks/quality-gates.json` — VS Code agent hook configuration
   - `scripts/hooks/post-edit-lint.sh` — post-edit lint hook script
   - `scripts/hooks/stop-gate.sh` — stop gate hook script
   - `.github/skills/enforcement-audit/` — enforcement audit skill
   - `.github/skills/architecture-docs/` — architecture documentation skill
   - `.github/skills/code-review/` — code review skill
2. Verify hook scripts are compatible — they assume `make lint` and `make test` targets exist
3. Review `AGENTS.md` and adjust if the downstream project has different governance requirements
4. Existing assets are preserved unless `clean=true` is passed
