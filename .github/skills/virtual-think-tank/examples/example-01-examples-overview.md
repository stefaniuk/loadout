# Virtual Think Tank Examples

## Overview

- **Skill**: `virtual-think-tank`
- **Focus**: Three realistic ways to run the skill for architecture,
  organisation design, and operating-model debates.
- **Use**: Adapt these examples to your own decision briefs in VS Code Copilot
  Chat or GitHub Copilot CLI.

> [!IMPORTANT]
> These examples use the skill directly. They do not rely on prompt files.

## Usage notes

- In VS Code Copilot Chat, invoke the skill by typing `/virtual-think-tank`
  and then pasting the brief.
- In GitHub Copilot CLI, start an interactive session with
  `copilot --experimental` and invoke the skill by naming it with a leading
  slash in the prompt.
- If the CLI does not already see the workspace skill, use `/skills add` with
  the skills directory, then `/skills reload`.
- For repeatable scripted runs in the CLI, use programmatic mode with
  `copilot -p` and plain-output mode with `-s`.

## Decision topics

1. **Microservices decision**: Under what conditions should a growing,
   business-critical platform evolve from a modular monolith into
   microservices, and what trade-offs must be true for that move to pay off?
2. **Team Topologies decision**: For a large enterprise, when does adopting
   Team Topologies improve ownership, flow, and cognitive load, and what
   organisational conditions make the model succeed or fail?
3. **Product mindset transition**: How do organisations move from project
   delivery habits to product thinking centred on outcomes, customer value, and
   flow, and where do these transformations most often stall?

> [!TIP]
> Use `panel_style: named` only when you want recognisable public voices and
> are willing to check the skill's confidence and verification notes. Use
> `panel_style: stakeholder` when the decision is more about internal change
> than external thought leadership. If you provide any `named_*` field, the
> skill should honour that explicit request even on an organisational topic.

## Example files

1. [Microservices decision, named figures, full mode, VS Code Copilot Chat](./example-02-microservices-named-figures-full-vscode-chat.md)
2. [Team Topologies decision, named figures, interactive mode, GitHub Copilot CLI](./example-03-team-topologies-named-figures-interactive-copilot-cli.md)
3. [Product mindset transition, stakeholder voices, guided mode, VS Code Copilot Chat](./example-04-product-mindset-stakeholder-voices-guided-vscode-chat.md)

## Notes and follow-ups

- If you want a deterministic comparison, keep the same brief and run both
  `panel_style: named` and `panel_style: stakeholder`.
- If the decision depends on evidence that is not yet available, stop after the
  decisive questions and gather the missing data before approving an ADR.
- If you want to automate repeated runs in GitHub Copilot CLI, use the CLI `-p`
  and `-s` options after you are happy with the wording of the brief.
