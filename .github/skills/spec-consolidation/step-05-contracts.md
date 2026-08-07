# Step 05 - Consolidated Contracts

**Output:** `specs/product/contracts/`
**Dependencies:** steps 01–02.

Merge contract files from every `specs/NNN-*/contracts/` directory, and when
needed derive product contracts from inline normative contract sections in
source artefacts, removing overlap and aligning identifiers with the
consolidated spec and data model.

If no source feature provides `contracts/` and no source artefact embeds
normative contract sections, stop and report that there is nothing to
consolidate for this step.

## Discovery

1. Enumerate every file under every `specs/NNN-*/contracts/`. Also enumerate
   inline normative contract sections embedded in source `spec.md`,
   `data-model.md`, or `quickstart.md` when standalone contract files are
   missing or obviously partial.
2. Build a public-surface inventory from the selected baseline: packaging or
   entry-point declarations, exported APIs, emitted schemas, wire formats, or
   equivalent exposed surfaces that users or integrators depend on.
3. Classify by contract type: CLI contracts, NDJSON / JSON schemas, API
   contracts, file format specs, exit-code tables, log event schemas.
4. For each contract or public surface, identify the enforcing code path and
   the narrowest
   enforcing tests or fixtures that prove the contract still holds.
5. Confirm each contract against its enforcing code path (schema validators,
   CLI option parsers, output writers).

## Authoring

1. One file per contract, named by capability not by feature number:
   `<cli-contract>.md`, `<stream-schema>.schema.json`,
   `<service-contract>.md`, `<output-format>.md`, etc.
2. Every shipped public CLI, API, schema, or equivalent exposed surface gets
   exactly one product-facing contract file. If a surface is intentionally
   covered by another contract rather than a separate file, state that
   rationale explicitly in the contracts index and `research.md`.
3. When standalone contract files are missing or incomplete, derive the
   product contract from the narrowest combination of inline normative source
   sections and selected-baseline code or test evidence. Cite the originating
   source section in the product contract.
4. Where two features defined the same contract differently, prefer the
   version matching the code and log the rejected version under
   `research.md` drift.
5. Every path, test name, module name, option name, and exit code referenced in
   a product contract MUST exist in the selected baseline. Do not preserve
   stale references merely because they appeared in the source feature files.
6. JSON schemas: if a source schema is already canonical and code-true, keep it
   machine-readable with minimal reshaping; validate it against fixtures or
   automated checks where they exist.
7. Cross-link from `specs/product/spec.md` (requirements) and
   `specs/product/data-model.md` (entities) into the contract files.
8. Add an index document under `specs/product/contracts/` listing every
   contract with a one-line description, the consuming command or module, and
   the main enforcing test or fixture where practical.

## Definition of Done

- Every contract type appears exactly once under `specs/product/contracts/`.
- Each product contract traces either to a standalone source contract file or
  to a cited inline normative source section when standalone files were absent
  or incomplete.
- Each consolidated contract is evidenced by the code that enforces it in the
  selected baseline.
- Every shipped public surface identified from the selected baseline is
  represented by exactly one product-facing contract file or an explicit
  rationale in the contracts index or `research.md`.
- An index document lists every contract.
- No contract content references obsolete capabilities.
