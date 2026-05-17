# Step 05 — Consolidated Contracts

**Output:** `specs/product/contracts/`
**Dependencies:** steps 01–02.

Merge contract files from every `specs/NNN-*/contracts/` directory, removing
overlap and aligning identifiers with the consolidated spec and data model.

If no source feature provides `contracts/`, stop and report that there is
nothing to consolidate for this step.

## Discovery

1. Enumerate every file under every `specs/NNN-*/contracts/`.
2. Classify by contract type: CLI contracts, NDJSON / JSON schemas, API
   contracts, file format specs, exit-code tables, log event schemas.
3. For each contract, identify the enforcing code path and the narrowest
   enforcing tests or fixtures that prove the contract still holds.
4. Confirm each contract against its enforcing code path (schema validators,
   CLI option parsers, output writers).

## Authoring

1. One file per contract, named by capability not by feature number:
   `<cli-contract>.md`, `<stream-schema>.schema.json`,
   `<service-contract>.md`, `<output-format>.md`, etc.
2. Where two features defined the same contract differently, prefer the
   version matching the code and log the rejected version under
   `research.md` drift.
3. Every path, test name, module name, option name, and exit code referenced in
   a product contract MUST exist in the selected baseline. Do not preserve
   stale references merely because they appeared in the source feature files.
4. JSON schemas: if a source schema is already canonical and code-true, keep it
   machine-readable with minimal reshaping; validate it against fixtures or
   automated checks where they exist.
5. Cross-link from `specs/product/spec.md` (requirements) and
   `specs/product/data-model.md` (entities) into the contract files.
6. Add an index document under `specs/product/contracts/` listing every
   contract with a one-line description, the consuming command or module, and
   the main enforcing test or fixture where practical.

## Definition of Done

- Every contract type appears exactly once under `specs/product/contracts/`.
- Each consolidated contract is evidenced by the code that enforces it in the
  selected baseline.
- An index document lists every contract.
- No contract content references obsolete capabilities.
