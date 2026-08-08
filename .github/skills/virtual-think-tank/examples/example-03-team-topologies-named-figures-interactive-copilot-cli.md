# Example 03 - Team Topologies decision, named figures, interactive mode, GitHub Copilot CLI

## Why this setup works

- GitHub Copilot CLI can use a specific skill when the prompt names it with a
  leading slash.
- The CLI supports skill management commands, which makes it suitable when you
  want a repeatable workshop from a terminal.
- This example uses `named` mode because Team Topologies has a clear set of
  public voices associated with the topic.

## Named figures used in this example

- **Gene Kim** - moderator with a flow and delivery lens.
- **Matthew Skelton** - strong advocate for Team Topologies.
- **Manuel Pais** - advocate focused on cognitive load and interaction modes.
- **Melvin Conway** - historical systems and organisation lens.
- **Ruth Malan** - sceptical architect lens on organisation design slogans and
  trade-offs.

## Step-by-step

**Step 1.** Open a terminal at the repository root.

**Step 2.** Start the CLI:

        copilot --experimental

**Step 3.** Check whether the skill is available:

        /skills list

**Step 4.** If the workspace skills are not already loaded, add and reload them:

        /skills add .github/skills
        /skills reload

**Step 5.** Inspect the skill metadata if you want a quick reminder:

        /skills info virtual-think-tank

**Step 6.** Invoke the skill with a structured brief:

        Use the /virtual-think-tank skill.

        mode: full
        panel_style: named
        decision_subject: Organisation design for a large enterprise platform estate
        current_state: The enterprise has deep silos, functional hand-offs, and
        large shared services. Delivery is slow, ownership is blurred, and teams
        often depend on central groups for routine changes.
        required_state: The organisation should improve flow, reduce cognitive
        overload, and clarify ownership without causing a reorganisation that the
        business cannot absorb.
        problem_statement: For a large enterprise, when does adopting Team
        Topologies improve ownership, flow, and cognitive load, and what
        organisational conditions make the model succeed or fail?
        constraints: Large legacy estate, matrix structures, compliance demands,
        several central platform groups, mixed leadership buy-in.
        non_goals: Renaming every team overnight, copying a book literally, or
        assuming the same topology fits every domain.
        decision_horizon: 12 months
        decision_evidence: Lead time is high in 3 value streams, 6 central approval
        gates affect routine delivery, and team cognitive load surveys show
        repeated overload in shared-service groups.
        named_moderator: Gene Kim
        named_voices: Matthew Skelton, Manuel Pais, Ruth Malan
        named_outside_voice: Melvin Conway

## Potential AI output, first pass

        Phase 1, Frame the Decision

        Decision question:
        Should this enterprise adopt Team Topologies as the primary organisation
        design lens over the next 12 months, and if so where should it be applied
        first to improve flow without triggering unmanageable disruption?

        Success criteria:
        - Clearer team boundaries and ownership.
        - Lower coordination cost across priority value streams.
        - Reduced cognitive load in overloaded teams.

        Failure modes:
        - Topology labels change while incentives and workflows stay the same.
        - Central teams become new bottlenecks under a different name.
        - The organisation treats the model as universal doctrine rather than
            context-sensitive guidance.

## Potential AI output, debate section

        Opening statements:
        - Matthew Skelton: Use Team Topologies to design for flow and manageable
            cognitive load.
        - Manuel Pais: Interaction modes matter as much as reporting lines. The
            operating model must change, not just the org chart.
        - Ruth Malan: Be careful with imported frameworks. The enterprise context,
            power structures, and constraints still decide what works.
        - Melvin Conway: System structure will follow communication structure
            whether you intend it or not.

        Options on the table:
        A. Adopt Team Topologies across the enterprise in one coordinated redesign.
        B. Pilot the model in the three highest-friction value streams first.
        C. Keep the current structure and optimise only governance and process.

## Final user turn in the example

        Choose B. Pilot Team Topologies in the three highest-friction value streams,
        measure flow and cognitive load, then decide whether to expand.

## Potential AI output, decision checkpoint

        ADR draft status: Proposed
        Decision: Run a targeted Team Topologies pilot in the three highest-friction
        value streams rather than a broad enterprise redesign.
        Rationale: The evidence supports trying the model where flow problems are
        measurable, while limiting organisational shock.
        Compliance:
        - Re-measure lead time, approval wait time, and cognitive load after two
            quarters.
        - Confirm whether platform-team interfaces became clearer.

> [!NOTE]
> In the CLI, you can keep the session interactive for the follow-up decision,
> or use the programmatic `-p` mode later if you want to script the same brief
> for repeatable comparisons.
