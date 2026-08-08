# Skill-Local Agent Instructions: Spec Consolidation

> **Scope.** This file applies only to the `spec-consolidation` skill subtree.
> The canonical baseline is the [root AGENTS.md](../../../AGENTS.md); nothing
> here may contradict it.

## Inheritance and precedence

- Inherit all rules from [root AGENTS.md](../../../AGENTS.md) and
  [.github/copilot-instructions.md](../../copilot-instructions.md).
- When a conflict exists within this skill's subtree, the closest file applies;
  otherwise root rules win.
- For the full task workflow, read [SKILL.md](SKILL.md). This file captures
  only behavioural constraints, not the workflow itself.

## Skill-local rules

- **Intent-only output.** Final product artefacts must never copy,
  paraphrase, or reference phases, task IDs, implementation order, or other
  scheduling content from `plan.md` or `tasks.md`. You may inspect `plan.md`
  narrowly for architecture boundaries, technical rationale, and trace links
  when that context is missing elsewhere. If a behavioural requirement is only
  expressed in `plan.md` or `tasks.md`, treat it as `Unknown from code -
confirm intent with operator` and surface it in `research.md`
  reconciliation notes.
- **Explore once, then stay local.** For medium or large repos, prefer one
  read-only exploration-agent pass up front to build the artefact matrix,
  overlap map, drift candidates, and likely evidence modules. After that,
  keep reads local to the current step.
- **Derived view, not replacement.** Treat each `specs/NNN-*/` directory as a
  durable feature/change record. The skill writes a product-facing derived
  view under `specs/product/`; it does not replace feature history.
- **Code is the tiebreaker.** When per-feature `spec.md` files disagree, the
  behaviour evidenced in the selected baseline implementation and validation
  artefacts wins. Record the divergence.
- **Single location per concept.** Domain terms, requirements, contracts, and
  checklists must each live in exactly one consolidated file. Replace any
  duplicate with a link.
- **Stable identifiers.** Assign product-level identifiers
  (`REQ-PRD-NNN`, `ENT-PRD-NNN`) when consolidating; preserve a mapping from
  the original per-feature IDs in an appendix.
- **Non-destructive.** Never modify, move, or delete files under
  `specs/NNN-*/`. The skill writes only to `specs/product/`.
- **Optional checklists stay optional.** Only create `specs/product/checklists/`
  when source feature checklists exist to merge.
- **Checklist state is earned.** In consolidated checklists, do not carry
  over `[x]` state mechanically from source feature checklists. Leave items
  unchecked unless the current consolidation run actually validated them.
- **Strict step sequencing.** Dependencies in the SKILL.md step table are
  hard requirements. Block any step whose prerequisites are absent.
- **Evidence-first.** Every requirement cites both the source spec section and
  the implementing code path from the selected baseline, with line range where
  applicable.
- **Validation attribution matters.** Run focused validation on
  `specs/product/**` first, then broader repo gates. If broader gates fail for
  unrelated pre-existing issues, report that separately instead of treating the
  new product docs as the cause.

## Deviations from root AGENTS.md

None.

## References

- [SKILL.md](SKILL.md) - the skill's task workflow.
- [root AGENTS.md](../../../AGENTS.md) - canonical baseline.
- [constitution](../../../.specify/memory/constitution.md) - highest authority.
