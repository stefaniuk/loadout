---
name: virtual-think-tank
description: Run a structured multi-step think tank for engineering, architecture, product, process, policy, vendor, or organisational decisions. Use when the user needs conflicting viewpoints, explicit trade-offs, and a forced human decision rather than a one-shot answer.
argument-hint: "Paste a decision brief, or say guided and answer the questions step by step"
license: MIT
version: 1.0.0
---

# Virtual Think Tank

Use this skill when the user needs a disciplined decision workshop rather than a direct recommendation.

## Core Rules

1. Do not make the final decision for the user.
2. Ask only the minimum missing questions needed to frame the decision well.
3. Separate facts, assumptions, and role-play clearly.
4. State uncertainties and what evidence would change the conclusion.
5. Prefer role-based voices over named people by default.
6. Use named people only when the user explicitly asks for them, or when they are clearly relevant and you can give a confidence level plus a verification path.
7. Prefer stakeholder voices when the decision is mainly organisational, commercial, or process-driven.
8. End by forcing an explicit human choice, or a time-boxed defer decision.

## Input Contract

Parse `$ARGUMENTS` first.

If the user pasted a structured brief, use it. Otherwise ask for the missing fields from the [briefing template](./assets/briefing-template.md).

Resolve these fields:

- `mode`: `guided` or `full`, default `guided`
- `panel_style`: `archetype`, `stakeholder`, or `named`, default `archetype`
- `decision_subject`
- `current_state`
- `required_state`
- `problem_statement`
- `constraints`
- `non_goals`
- `decision_horizon`
- optional `decision_evidence`, such as incident counts, timing data, cost bounds, revenue at risk, or adoption metrics
- optional `context`
- optional `sources`
- optional `outside_lens`
- optional `named_moderator`, when `panel_style: named`
- optional `named_voices`, a comma-separated list of 2 to 4 public voices when `panel_style: named`
- optional `named_outside_voice`, when `panel_style: named`

Interpretation rules:

- If `panel_style` is omitted and any `named_*` field is present, resolve `panel_style` to `named`.
- If the user explicitly asks for named voices, or provides any `named_*` field, honour that request even for organisational or process decisions.
- If the user asks for `panel_style: named` without supplying names, propose a balanced panel with substantive disagreement.
- If 3 or more critical fields are missing, stop and ask focused questions.
- If 1 or 2 non-critical fields are missing, make explicit assumptions.
- If the user asks for `full` mode but the brief is too thin, refuse to fabricate and switch to clarification.
- If the user provides earlier phase outputs and asks to continue, resume from the next missing phase.
- In guided mode, when `decision_subject`, `problem_statement`, and `constraints` are already present, ask no more than 3 compound clarification questions before stopping.

## Phase Model

The workflow runs in five operational phases.

### Phase 1, Frame the Decision

Produce:

- Clarifying questions, only if still needed
- Decision question
- Success criteria
- Failure modes

Do not ask broad questionnaires. Ask the fewest discriminating questions that sharpen the decision.

Prefer quantitative missing questions when the user has not provided any evidence, for example timings, incident counts, cost ceilings, revenue at risk, adoption figures, or operational load.

### Phase 2, Build a Neutral Baseline

Explain the decision space in neutral terms.

Output shape:

- Definitions
- Typical benefits
- Typical costs and risks
- When it is a bad idea
- Open questions

### Phase 3, Build the Panel

Choose the panel according to `panel_style`.

If the user supplied named participants, use those as anchors unless the panel is one-sided enough that it cannot produce a meaningful debate. In that case, keep the requested names where possible and add one contrasting voice rather than silently replacing the panel.

For `archetype`:

- Moderator
- Voice A
- Voice B
- Middle voice
- Optional outside lens

For `stakeholder`:

- Product or business owner
- Engineering or delivery lead
- Platform or operations
- Security, privacy, or risk
- Finance or commercial
- Support or live operations
- Neutral moderator

For `named`:

- Use real public voices only if clearly useful
- Prefer a balanced panel: one moderator, at least two substantively conflicting voices, one pragmatic or middle voice, and an optional outside lens
- If the user supplied names, honour them and rebalance only when the panel lacks genuine disagreement
- Avoid panels made of near-identical advocates or adjacent commentators who would say the same thing
- Mark each suggestion with confidence: `high`, `medium`, or `low`
- Add a verification path for each named person

For every voice, provide:

- stance
- why this voice is useful
- likely bias
- what they would challenge

### Phase 4, Run the Debate

Run one structured debate round.

Output shape:

1. Opening statements
2. Cross-examination
3. Moderator synthesis
4. Options on the table, usually `A`, `B`, and optional `C`
5. Decisive questions the user must answer

Rules:

- The voices must disagree in substance.
- They must challenge hidden costs, assumptions, and failure cases.
- They may propose a compromise if it is materially different from `A` and `B`.
- If one option starts to look obviously dominant, force the strongest counterargument against it before the moderator synthesis.
- Avoid vague platitudes and generic balance.

### Phase 5, Force the Human Decision

Summarise the options and require the user to choose `A`, `B`, `C`, or `defer` with a date.

Ask the user to state:

1. why they chose it
2. what they are giving up
3. what would make them reverse the decision
4. the review date

Then draft a short first-pass decision record using the repository [ADR template](../../../docs/adr/ADR-nnn_Any_Decision_Record_Template.md) and the [virtual think tank ADR profile](./assets/decision-record-template.md).

- Use the ADR template as the canonical structure.
- Keep the first draft proportionate and concise.
- Default `Status` to `Proposed` unless the user says otherwise.
- Use `TBD` for missing metadata rather than inventing it.

If the user has not chosen yet, leave the decision as pending and stop after the questions.

## Mode Behaviour

### Guided Mode

- Default mode
- Complete one phase at a time
- Stop after each phase and ask whether to continue, correct, or switch panel style

### Full Mode

- Run phases 1 to 4 in one response only if the brief is complete enough
- Stop at phase 5 and wait for the user to choose

## Output Discipline

- Keep each phase clearly headed
- Mark assumptions as `Assumption:`
- Mark gaps as `Unknown:`
- Mark decisive evidence as `Would change the conclusion if:`
- Keep the writing direct, concrete, and short
- Do not present role-play as evidence

## Recommended Invocation

Ask the user to paste the [briefing template](./assets/briefing-template.md) when they need a clean starting point.

Prefer `panel_style: stakeholder` for people, governance, and process decisions.

Prefer `panel_style: archetype` for technical and architectural decisions.

Use `panel_style: named` only when the value of real public viewpoints is worth the verification overhead.

If you want public figures on an organisational or process decision, set `panel_style: named` and fill one or more `named_*` fields. That explicit request overrides the default stakeholder recommendation.

## Examples

- [Examples overview](./examples/example-01-examples-overview.md)
- [Microservices decision, named figures, full mode, VS Code Copilot Chat](./examples/example-02-microservices-named-figures-full-vscode-chat.md)
- [Team Topologies decision, named figures, interactive mode, GitHub Copilot CLI](./examples/example-03-team-topologies-named-figures-interactive-copilot-cli.md)
- [Product mindset transition, stakeholder voices, guided mode, VS Code Copilot Chat](./examples/example-04-product-mindset-stakeholder-voices-guided-vscode-chat.md)
