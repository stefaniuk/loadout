# Virtual Think Tank ADR Profile

Use the repository [ADR template](../../../../docs/adr/ADR-nnn_Any_Decision_Record_Template.md) as the canonical decision record structure.

This file is a drafting profile for the think-tank workflow. It keeps the first pass short while staying aligned with the full ADR template.

## Populate First

- Header metadata: `Date`, `Status`, `Significance`
- `Context`
- `Decision`
  - `Assumptions`
  - `Drivers`
  - `Options`
  - `Outcome`
  - `Rationale`
- `Consequences`
- `Compliance`
- `Notes`
- `Actions`
- `Tags`

## Drafting Rules

- Default `Status` to `Proposed` unless the user specified another state.
- Choose `Significance` from the ADR template taxonomy.
- Carry the decisive questions into `Actions` or `Notes` when they remain unresolved.
- Use weighted scoring when the brief contains enough evidence. Otherwise mark the scoring inputs as `TBD`.
- Write `Unknown from current brief` or `TBD` instead of inventing facts.
- Keep the first pass concise. Expand it only when the user asks for a full ADR.
