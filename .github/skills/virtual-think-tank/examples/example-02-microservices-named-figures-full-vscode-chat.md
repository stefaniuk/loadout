# Example 02 - Microservices decision, named figures, full mode, VS Code Copilot Chat

## Why this setup works

- VS Code Copilot Chat supports skills as slash commands in the chat input.
- This example uses `full` mode because the brief is complete enough to run
  phases 1 to 4 in one pass.
- This example uses `named` mode because the topic has strong public thought
  leaders and the user explicitly wants named voices.

## Named figures used in this example

- **Martin Fowler** - moderator and architecture context.
- **Sam Newman** - strong advocate for microservices when the operational
  preconditions are real.
- **Simon Brown** - sceptical of premature distribution and unnecessary
  complexity.
- **James Lewis** - pragmatic middle voice on service boundaries and
  evolutionary design.
- **Werner Vogels** - outside lens on scale, operational autonomy, and
  resilience.

## Step-by-step

**Step 1.** Open Copilot Chat in VS Code from the repository workspace.

**Step 2.** Start a fresh chat so the debate stays scoped to one decision.

**Step 3.** Type `/virtual-think-tank`.

**Step 4.** Paste a structured brief like this:

        mode: full
        panel_style: named
        decision_subject: Architecture direction for a growing digital platform
        current_state: The platform is a modular monolith used by several product teams.
        Delivery is accelerating, but release coordination, scaling hotspots, and
        team coupling are becoming harder to manage.
        required_state: The architecture should support faster independent delivery,
        bounded operational risk, and clearer ownership without exploding complexity.
        problem_statement: Under what conditions should a growing, business-critical
        platform evolve from a modular monolith into microservices, and what
        trade-offs must be true for that move to pay off?
        constraints: Several teams, mixed platform maturity, strict uptime
        expectations, limited SRE capacity, existing investment in the monolith,
        regulatory audit needs.
        non_goals: Rewriting the whole estate in one programme, chasing
        microservices as a status symbol, or assuming every domain needs independent
        deployment.
        decision_horizon: 18 months
        decision_evidence: Release train delays average 8 days per quarter, two
        scaling hotspots have caused incidents, and 4 teams now touch the same
        deployment pipeline.
        named_moderator: Martin Fowler
        named_voices: Sam Newman, Simon Brown, James Lewis
        named_outside_voice: Werner Vogels

## Potential AI output, first pass

        Phase 1, Frame the Decision

        Decision question:
        Should this platform stay as a modular monolith for now, or split selected
        domains into microservices over the next 18 months, and what evidence
        justifies the added operational cost?

        Success criteria:
        - Teams ship changes with less release coordination.
        - Incident blast radius falls for the known hotspots.
        - Service ownership becomes clearer without creating a large platform tax.

        Failure modes:
        - Distribution complexity grows faster than delivery gains.
        - Teams create service boundaries around org charts rather than domain seams.
        - Runtime and compliance overhead outpace the value gained.

## Potential AI output, debate section

        Opening statements:
        - Sam Newman: Split only where team autonomy and scaling pressure justify it.
            Microservices are a means to independent delivery, not a branding exercise.
        - Simon Brown: Most organisations underestimate the operational cost of
            distributed systems. A well-structured monolith is often the better
            near-term answer.
        - James Lewis: Focus on service boundaries that map to real domain seams
            and measurable friction points.
        - Werner Vogels: If autonomy is the goal, the operating model and
            resilience posture matter as much as the code structure.

        Options on the table:
        A. Stay with a modular monolith and invest in stronger module boundaries.
        B. Extract only the two hotspot domains into services first.
        C. Commit to a broad microservices migration programme.

## Final user turn in the example

        Choose B. We will extract only the two hotspot domains first, keep the rest
        in the modular monolith, and review in 9 months.

## Potential AI output, decision checkpoint

        ADR draft status: Proposed
        Decision: Selective extraction of hotspot domains into microservices, while
        retaining the modular monolith as the primary architecture.
        Outcome: Reversible. Revisit if release coupling remains high after the
        first two extractions.
        Actions:
        - Validate domain boundaries against incident and dependency data.
        - Define operational readiness checks before the first extraction.
        - Review impact after 9 months.
