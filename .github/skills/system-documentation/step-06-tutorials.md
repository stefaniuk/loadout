# Step 06 - Tutorials

**Outputs:** `docs/tutorials/**`
**Dependencies:** step 03 (`docs/reference/**`) and step 05 (`docs/how-to/**`).

This step maintains guided learning journeys for readers who are new to a
workflow and need a safe, happy-path introduction.

## Artefact contracts

| Artefact                      | Canonical role       | Required content                                                                      | Must not contain                                         |
| ----------------------------- | -------------------- | ------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| `docs/tutorials/README.md`    | Tutorial index       | learning paths, expected skill level, outcomes, links to next docs                    | exhaustive troubleshooting, raw reference tables         |
| `docs/tutorials/<journey>.md` | Guided learning path | outcome, prerequisites, time estimate, staged steps, checkpoints, cleanup, next steps | broad task catalogues, design debate, runbook escalation |

## Discovery

1. Identify workflows that merit a newcomer learning path.
2. Confirm there is a stable happy path with limited branching.
3. Reuse exact commands and expectations from reference and how-to docs.
4. Decide whether the reader needs a tutorial or a how-to guide.

## Mode-specific workflow

### `establish`

1. Create `docs/tutorials/README.md` when the repository needs a teaching
   layer.
2. Create tutorials only for supported journeys that a newcomer can complete
   end-to-end.

### `sync`

1. Update tutorials when the happy path changed materially.
2. Keep troubleshooting minimal; move detailed problem handling to how-to or
   runbooks.

### `audit` and `pre-pr-review`

1. Detect tutorials that no longer complete successfully against the current
   repo state.
2. Flag tutorials that are trying to teach too many branches or tasks.

## Standardised expectations

Every `docs/tutorials/<journey>.md` should, when practical, include:

1. Outcome
2. Prerequisites and expected starting state
3. Time or effort expectation
4. Ordered steps with checkpoints
5. Cleanup if relevant
6. Next steps into how-to, reference, or explanation docs

## Definition of Done

- The tutorial is runnable on the current repository state.
- The reader can finish one coherent journey without needing external
  interpretation.
- Tutorials remain teaching material rather than reference or operational
  guidance.
