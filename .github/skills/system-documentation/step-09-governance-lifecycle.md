# Step 09 - Governance and Lifecycle

**Outputs:** `CHANGELOG.md`, `.github/SECURITY.md`,
`.github/contributing.md` (or root `CONTRIBUTING.md` where the repository
already uses that location), `.github/CODE_OF_CONDUCT.md`, and any
upgrade-guide pages under `docs/how-to/` or `docs/operations/runbooks/`.
**Dependencies:** step 01 (`README.md`, `docs/README.md`,
`docs/conventions.md`, `docs/onboarding.md`).

This step maintains the cross-cutting governance, security, contribution, and
change-history artefacts that mature open-source repositories (for example
Django, FastAPI, Kubernetes, and Backstage) store in Git as first-class
documentation alongside the Diátaxis core.

## Artefact contracts

| Artefact                     | Canonical role                               | Required content                                                                            | Must not contain                                                |
| ---------------------------- | -------------------------------------------- | ------------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| `CHANGELOG.md`               | Chronological record of user-visible changes | versioned entries, added/changed/deprecated/removed/fixed/security sections, upgrade hints  | design rationale, task lists, reference tables                  |
| `.github/SECURITY.md`        | Security policy and vulnerability reporting  | supported versions, private reporting path, disclosure expectations, remediation commitment | hardening tutorials, runtime operations, ADR debate             |
| `.github/contributing.md`    | Contribution process                         | how to propose changes, branch and review workflow, quality gates, doc contribution rules   | architecture explanation, user tutorials, exhaustive reference  |
| `.github/CODE_OF_CONDUCT.md` | Community behaviour policy                   | scope, expected behaviour, enforcement contact and process                                  | technical guidance                                              |
| Upgrade guides               | Safe transition between significant versions | scope, breaking changes, ordered upgrade steps, verification, rollback                      | new-feature tutorials, conceptual essays, full reference tables |

If the repository tracks releases through Git tags only, prefer
`CHANGELOG.md` at the repository root with `Keep a Changelog`-style sections.
If the repository publishes long-form release notes, store the templated
notes under `docs/operations/` and reference them from `CHANGELOG.md`.

Upgrade guides live under `docs/how-to/` when they are version-agnostic
recipes, and under `docs/operations/runbooks/` when they are
safety-sensitive operator procedures. Link both directions from
`CHANGELOG.md`.

## Discovery

1. Confirm the current state of `CHANGELOG.md`, `.github/SECURITY.md`,
   `.github/contributing.md`, and `.github/CODE_OF_CONDUCT.md`.
2. Inspect release tags, release notes, and `.github/` workflows to derive
   the supported versions and the change-tracking style already in use.
3. Identify any vulnerability reporting channel that the project relies on
   (private advisory, dedicated email, security team handle).
4. Inventory breaking changes since the last documented release.

## Mode-specific workflow

### `establish`

1. Create the four governance files if they are missing, using minimal,
   honest content backed by current repository practice.
2. Seed `CHANGELOG.md` with the present unreleased section and any
   already-shipped versions reconstructable from tags and release notes.
3. Do not invent supported-version windows or disclosure SLAs that the
   maintainers have not committed to; mark them as `TBD` and flag.

### `sync`

1. Update `CHANGELOG.md` whenever a user-visible change ships; group entries
   by type and reference the relevant feature spec, ADR, or PR.
2. Update `.github/SECURITY.md` when the supported version window, the
   reporting path, or the disclosure policy changes.
3. Update `.github/contributing.md` when the contribution workflow, quality
   gates, or documentation rules change.
4. Add or update upgrade guides whenever a release introduces breaking
   changes, configuration migrations, or required operator action.

### `audit` and `pre-pr-review`

1. Detect user-visible behaviour changes without matching `CHANGELOG.md`
   entries.
2. Flag missing or outdated supported-version statements in
   `.github/SECURITY.md`.
3. Flag contribution-workflow drift between `.github/contributing.md`,
   `docs/onboarding.md`, and the actual repository automation.
4. Detect breaking changes without an upgrade guide.

## Standardised expectations

### `CHANGELOG.md`

Prefer these sections per release:

1. Version and date
2. Highlights
3. Added
4. Changed
5. Deprecated
6. Removed
7. Fixed
8. Security
9. Upgrade notes

### `.github/SECURITY.md`

Prefer these sections:

1. Supported versions
2. Reporting a vulnerability
3. Disclosure process
4. Remediation expectations
5. Public acknowledgements policy

### `.github/contributing.md`

Prefer these sections:

1. Ways to contribute
2. Development environment
3. Branching and commits
4. Quality gates
5. Documentation expectations
6. Review and merge process

### Upgrade guides

Prefer these sections:

1. Scope and affected versions
2. Breaking changes
3. Required configuration or data migrations
4. Ordered upgrade steps
5. Verification
6. Rollback or fallback

## Definition of Done

- Governance artefacts exist in their canonical locations and reflect actual
  project policy rather than aspirational claims.
- Every shipped user-visible change is reflected in `CHANGELOG.md` before the
  release is cut.
- Breaking changes carry an upgrade guide that an operator or integrator can
  follow without reading source code.
- Vulnerability reporters can find the supported-version window and the
  reporting channel without leaving the repository.
