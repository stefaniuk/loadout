---
agent: agent
argument-hint: "Optional: step (spec, data-model, research, quickstart, contracts, checklists, all) and baseline (working-tree, HEAD, default-branch) - defaults to all on the working tree"
description: Consolidate per-feature Spec Kit artefacts under specs/ into a product-facing specification set aligned to a selected baseline while excluding plan.md and tasks.md from the final output.
---

This prompt delegates to the **spec-consolidation** skill.

Run the `spec-consolidation` skill. If the user input below names a step
(`spec`, `data-model`, `research`, `quickstart`, `contracts`, `checklists`),
run only that step. Otherwise run **all steps defined in the
`spec-consolidation` skill** in order.

Use the current working tree at `HEAD` as the baseline unless the user
explicitly asks for the default branch or another historical view.

If the user input is invalid or incomplete (for example, an unknown step
name or a baseline reference that cannot be resolved), respond with an
error message that names the offending value and lists the accepted
options, and do not start the consolidation run.

```text
$ARGUMENTS
```

Mandatory behavioural constraints (see
[SKILL.md](../skills/spec-consolidation/SKILL.md) and its
[AGENTS.md](../skills/spec-consolidation/AGENTS.md) for full detail):

**Discovery and inputs**

- For medium or large repos, use one read-only exploration-agent pass up front
  to inventory feature artefacts, overlapping capabilities, likely evidence
  modules, and obvious drift candidates. Reuse that inventory instead of
  remapping the whole repo in every step.
- Output is intent-only. Never copy or paraphrase `tasks.md`. You may inspect
  `plan.md` narrowly for architecture context when that context is not
  recoverable from `spec.md`, `research.md`, `data-model.md`, `quickstart.md`,
  `contracts/`, or the code. Never emit phases, task IDs, or implementation
  order into `specs/product/`.

**Baseline and file-handling rules**

- Reconcile against the selected baseline; the baseline default is set above.
- Write only to `specs/product/`. Never modify, move, or delete any existing
  `specs/NNN-*/` directory.
- Only create `specs/product/checklists/` when source feature checklists exist.
  Otherwise skip step 06 and say so.

**Content rules**

- When per-feature specs disagree, the behaviour evidenced by the selected
  baseline implementation and validation artefacts wins; record divergence in
  `specs/product/research.md`.
- For `quickstart.md`, prefer the current repository bootstrap and operator
  guidance surface, entry-point declarations, runtime or packaging metadata,
  and executable validation artefacts when the source feature quickstarts are
  stale.
- In consolidated checklists, leave items unchecked unless the current
  consolidation run actually validated them.
- Every consolidated requirement, entity, contract, and checklist item must
  appear in exactly one place and cite both its source spec section and the
  implementing code path.

**Validation rules**

- Validate `specs/product/**` first, then run broader repo gates if available.
  If repo-wide validation fails for unrelated pre-existing issues, report that
  separately from any new product-doc failures.

**Final-message rules**

- After completion, include a concise before/after analysis in the final
  assistant message: fragmentation before, improvements after, remaining risks,
  and confidence that the product set matches the selected baseline.
- After completion, list (in the final assistant message) any duplicate
  derived artefacts that now have a product-facing counterpart and could be
  archived after review. Do not recommend deleting the `specs/NNN-*` feature
  histories themselves.
