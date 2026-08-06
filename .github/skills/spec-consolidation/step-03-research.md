# Step 03 - Consolidated Research and Reconciliation

**Output:** `specs/product/research.md`
**Dependencies:** step 01 (`specs/product/spec.md`).

Consolidate decisions, alternatives, and trade-offs from every
`specs/NNN-*/research.md`. Add a dedicated **Reconciliation Notes** section
capturing every divergence found while consolidating the spec and data model.

## Discovery

1. Read every `specs/NNN-*/research.md`.
2. Read existing ADRs, technology guidance, and equivalent ratified decision
   records where present.
3. Collect drift notes recorded during steps 01 and 02.
4. If a design decision appears only in `plan.md`, record it as plan-derived
   technical rationale and decide whether it should become a research entry or
   an ADR recommendation. Do not treat it as behavioural authority.

## Authoring

1. One decision per subsection. Title format:
   `Decision: <what was decided>`.
2. For every decision, capture: context, options considered, decision,
   rationale, consequences, and a link to the ratifying ADR if one exists.
3. Deduplicate: if the same decision appears in two feature research files,
   keep one entry and list both sources.
4. Where a decision was research-only and never elevated to an ADR but is now
   load-bearing, recommend promotion under a `Recommended ADRs` section.
5. Reconciliation Notes section: list every spec/code divergence found.
   For each, record: intent statement, observed code behaviour, evidence
   links from the selected baseline, recommended resolution (update spec,
   update code, or open ADR).

## Template (skeleton)

```markdown
# Product Research and Reconciliation

## Decisions

### Decision: <what was decided>

- Context, Options, Decision, Rationale, Consequences, ADR: <ratifying record link if present>

### Decision: …

## Recommended ADRs

- (decision → suggested ADR title)

## Reconciliation Notes

- **Drift 001**: Spec says X; code does Y. Evidence: …. Resolution: ….

## Appendix - Source Mapping
```

## Definition of Done

- Exactly one `research.md` exists under `specs/product/`.
- Every decision is either linked to an ADR or listed under
  `Recommended ADRs`.
- The Reconciliation Notes section is complete and actionable.
- No duplicate decisions remain.
