# Prompts 💬

Auto-generated index of prompt files in this directory. Each prompt is invokable as a slash command (e.g. `/enforce.python`). See [VS Code prompt files docs](https://code.visualstudio.com/docs/copilot/customization/prompt-files).

> **Do not edit by hand.** Regenerate with `make catalogue` (see [scripts/quality/](../../scripts/quality/)).

## Naming convention

Prompts use the **prefix + category + verb** convention:

| Prefix          | Purpose                                         |
| --------------- | ----------------------------------------------- |
| `architecture.` | Evidence-first architecture documentation flows |
| `dev.`          | Development workflow helpers                    |
| `enforce.`      | Instruction compliance enforcement              |
| `review.`       | Review and audit prompts                        |
| `spec.`         | Specification consolidation                     |
| `util.`         | Operational utilities                           |

## Catalogue

Grouped by prefix, alphabetical within each group.

### `architecture.`

| File                                                                                                 | Description                                                                                                                           |
| ---------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| [architecture.01-repository-map.prompt.md](architecture.01-repository-map.prompt.md)                 | Build a repository map to document architecture, technology stack, and repo-level conventions (evidence-first)                        |
| [architecture.02-component-catalogue.prompt.md](architecture.02-component-catalogue.prompt.md)       | Create component-level summaries (responsibilities, interfaces, data, and extension points)                                           |
| [architecture.03-runtime-flows.prompt.md](architecture.03-runtime-flows.prompt.md)                   | Document key runtime flows with diagrams (trigger → orchestration → data lineage), evidence-first                                     |
| [architecture.04-domain-analysis.prompt.md](architecture.04-domain-analysis.prompt.md)               | Domain analysis (DDD) to document bounded contexts, language, events, and context map (evidence-first)                                |
| [architecture.05-c4-model.prompt.md](architecture.05-c4-model.prompt.md)                             | Produce C4 model diagrams (Context, Container, Component) in LikeC4 format (<https://likec4.dev/,> evidence-first, consistent naming) |
| [architecture.06-infrastructure-diagram.prompt.md](architecture.06-infrastructure-diagram.prompt.md) | Produce AWS/Azure infrastructure diagram from Terraform (evidence-first, consistent with C4 container naming)                         |

### `dev.`

| File                                                                                 | Description                                                                       |
| ------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------- |
| [dev.implement-cli-args-parsing.prompt.md](dev.implement-cli-args-parsing.prompt.md) | Evaluate and enforce specific CLI argument parsing discipline across the codebase |
| [dev.implement-commands.prompt.md](dev.implement-commands.prompt.md)                 | Evaluate and enforce specific development commands discipline across the codebase |
| [dev.implement-logging.prompt.md](dev.implement-logging.prompt.md)                   | Evaluate and enforce specific logging discipline across the codebase              |

### `enforce.`

| File                                                                               | Description                                                                   |
| ---------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| [enforce.docker.prompt.md](enforce.docker.prompt.md)                               | Enforce repository-wide compliance with docker.instructions.md                |
| [enforce.go.prompt.md](enforce.go.prompt.md)                                       | Enforce repository-wide compliance with go.instructions.md                    |
| [enforce.makefile.prompt.md](enforce.makefile.prompt.md)                           | Enforce repository-wide compliance with makefile.instructions.md              |
| [enforce.playwright-python.prompt.md](enforce.playwright-python.prompt.md)         | Enforce repository-wide compliance with playwright-python.instructions.md     |
| [enforce.playwright-typescript.prompt.md](enforce.playwright-typescript.prompt.md) | Enforce repository-wide compliance with playwright-typescript.instructions.md |
| [enforce.python.prompt.md](enforce.python.prompt.md)                               | Enforce repository-wide compliance with python.instructions.md                |
| [enforce.reactjs.prompt.md](enforce.reactjs.prompt.md)                             | Enforce repository-wide compliance with reactjs.instructions.md               |
| [enforce.rust.prompt.md](enforce.rust.prompt.md)                                   | Enforce repository-wide compliance with rust.instructions.md                  |
| [enforce.shell.prompt.md](enforce.shell.prompt.md)                                 | Enforce repository-wide compliance with shell.instructions.md                 |
| [enforce.tauri.prompt.md](enforce.tauri.prompt.md)                                 | Enforce repository-wide compliance with tauri.instructions.md                 |
| [enforce.terraform.prompt.md](enforce.terraform.prompt.md)                         | Enforce repository-wide compliance with terraform.instructions.md             |
| [enforce.typescript.prompt.md](enforce.typescript.prompt.md)                       | Enforce repository-wide compliance with typescript.instructions.md            |

### `review.`

| File                                                                             | Description                                                                                                                                  |
| -------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| [review.speckit-code.prompt.md](review.speckit-code.prompt.md)                   | Review the implementation against the entire spec-driven development documentation set (including the constitution) for compliance; detect a |
| [review.speckit-documentation.prompt.md](review.speckit-documentation.prompt.md) | Review the entire spec-driven development documentation set (including the constitution) for consistency, cohesion, coherence, and traceabil |
| [review.speckit-test.prompt.md](review.speckit-test.prompt.md)                   | Review the test automation implementation against the specification and the desired test pyramid shape; detect and explain misalignment - pr |

### `spec.`

| File                                                     | Description                                                                                                                                  |
| -------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| [spec.consolidate.prompt.md](spec.consolidate.prompt.md) | Consolidate per-feature Spec Kit artefacts under specs/ into a product-facing specification set aligned to a selected baseline while excludi |

### `util.`

| File                                                                   | Description                                                                                                            |
| ---------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| [util.doc-system.prompt.md](util.doc-system.prompt.md)                 | Establish, synchronise, audit, or review the repository documentation system by running the system-documentation skill |
| [util.gh-pr-content.prompt.md](util.gh-pr-content.prompt.md)           | Create pull request content from the current branch changes                                                            |
| [util.gh-pr-review.prompt.md](util.gh-pr-review.prompt.md)             | Generate pull request review using architecture overview context                                                       |
| [util.git-commit-message.prompt.md](util.git-commit-message.prompt.md) | Generate conventional commit message and description from the current changes diff                                     |
