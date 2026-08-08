# Example 04 - Product mindset transition, stakeholder voices, guided mode, VS Code Copilot Chat

## Why this setup works

- This topic is mostly about internal behaviour change, incentives, and flow.
- Stakeholder voices are usually more useful than public named figures for this
  kind of transformation.
- `guided` mode is better because teams often start with an incomplete brief
  and need sharper framing before the debate.

## Step-by-step

**Step 1.** Open a fresh chat in VS Code.

**Step 2.** Type `/virtual-think-tank`.

**Step 3.** Start with a thin brief:

        mode: guided
        panel_style: stakeholder
        decision_subject: Product operating model transition
        problem_statement: How do organisations move from project delivery habits to
        product thinking centred on outcomes, customer value, and flow, and where
        do these transformations most often stall?
        constraints: Existing project funding cycles, annual planning, PMO controls,
        mixed product capability, delivery pressure.

## Potential AI output, guided intake

        Phase 1, Frame the Decision

        Assumption: This is a business and operating-model decision, so stakeholder
        voices are the right panel style.
        Unknown: current state, required state, non-goals, horizon, and evidence.

        I need three focused clarifications before the debate:
        1. What does the current project-led model look like in practice, and what
             friction is it causing?
        2. What evidence do you already have, for example missed outcome targets,
             hand-off delays, or customer-value gaps?
        3. What is out of scope for this change over the next 12 months?

**Step 4.** Answer briefly:

        Current state: Teams are funded as temporary projects, success is tracked
        by delivery milestones, and ownership often ends at launch.
        Required state: Persistent teams should own outcomes, live metrics, and
        continuous improvement.
        Non-goals: Replacing every governance process in one quarter, removing all
        project controls immediately.
        Decision horizon: 12 months
        Decision evidence: Teams ship features, but customer adoption is patchy and
        hand-offs after launch cause long delays in learning.

## Potential AI output, next phase

        Phase 2, Build a Neutral Baseline

        Definitions:
        - Project mindset: temporary funding, temporary teams, success measured
            mainly by delivery.
        - Product mindset: persistent ownership, outcome tracking, ongoing
            prioritisation and learning.

        Typical failure modes:
        - Funding stays project-based, so behaviour never really changes.
        - Teams inherit product labels but not product authority.
        - Metrics stay activity-based rather than outcome-based.

## Potential AI output, stakeholder panel

        Panel:
        - Product leader
        - Engineering leader
        - Finance partner
        - PMO or governance lead
        - Customer support or operations lead
        - Neutral moderator

        Decisive questions:
        - Who owns outcomes after launch?
        - Which funding and planning rules would block product-style ownership?
        - What evidence would show better flow, not just more work in progress?

## Potential AI output, final checkpoint

        Choose A, B, C, or defer.

        A. Keep the project model and improve hand-offs.
        B. Move selected value streams to persistent product teams first.
        C. Reorganise the full portfolio around products in one broad change.
