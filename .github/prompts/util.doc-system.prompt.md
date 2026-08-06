---
agent: agent
argument-hint: "Optional: step (foundation, architecture, reference, explanation, how-to, tutorials, operations, audience-indexes, governance, all), mode (establish, sync, audit, pre-pr-review), and scope (path, feature dir, or changed files)"
description: Establish, synchronise, audit, or review the repository documentation system by running the system-documentation skill.
---

This prompt delegates to the **system-documentation** skill.

Run the `system-documentation` skill and resolve the request in this order:

1. Detect combined produce-and-review requests. If the user asks to create,
   establish, synchronise, update, refresh, regenerate, fix drift in, or
   bring documentation up to date, and also asks to review, audit, check,
   verify, validate, assess, or deep-review it, run a two-phase workflow:
   - first resolve the producing phase through the rules below
   - then run `audit`
   - if `audit` surfaces resolvable drift, re-enter the producing phase to
     fix it, then re-run the documentation validation gates; stop after at
     most one corrective pass and report any drift that remains
   - report the two phases separately
2. Resolve the step. If the user input names a step (`foundation`,
   `architecture`, `reference`, `explanation`, `how-to`, `tutorials`,
   `operations`, `audience-indexes`, `governance`, `all`), use it. Otherwise
   default to `all`.
3. Resolve the mode for a single-phase request, or for the producing phase of
   a combined request:
   - an explicit mode wins
   - an explicit legacy alias (`feature-sync`, `adr-sync`, `surface-sync`,
     `release-sync`) maps through the skill's compatibility rules
   - a diff-based, PR-based, or changed-files-only review resolves to
     `pre-pr-review`
   - a request to review, audit, check, verify, validate, assess, or
     deep-review documentation quality, completeness, placement, or drift
     resolves to `audit`
   - a request to establish missing structure, create the canonical baseline,
     or recover clearly missing anchors resolves to `establish`
   - a request to synchronise, update, refresh, regenerate, or fix drift
     resolves to `sync`
   - when none of the above apply and no diff, PR, or explicit scope narrows
     the run, default to `audit` rather than `sync`; an unbounded `sync` over
     a full repository is edit-heavy and should be requested explicitly
4. Resolve scope. An explicit scope wins. Otherwise use changed files when
   diff or PR context is available; if not, use the repository root.
5. When `all` is resolved, run the ordered step sequence defined by the skill.
   Within each step, create or update only the evidenced outputs and the
   minimal landing pages or indexes allowed by that step and mode. `sync`
   may legitimately produce zero edits when no drift is evidenced; in that
   case report "no changes; no drift detected" and proceed to validation.
6. If the user supplies an unrecognised or contradictory step, mode, alias, or
   scope, respond with an error that names the offending value and lists the
   accepted step and mode values. Do not start the run. Do not error solely
   because step, mode, or scope was omitted when the defaults above resolve it.
7. Before writing, state the resolved step, mode, scope, and whether the run
   is single-phase or combined. `audit` and `pre-pr-review` are non-
   destructive: they MUST NOT create, edit, rename, or delete files, and they
   do not need to execute validation gates. If you delegate either mode to a
   subagent, repeat the read-only contract in the subagent prompt.
8. For repositories with non-trivial documentation systems, prefer
   delegating inventory and drift analysis to a read-only exploration
   subagent before editing. Keep edits in the main agent so the planning
   context stays focused.

```text
$ARGUMENTS
```

Examples:

- `establish`
- `reference sync docs/reference/`
- `audit`
- `pre-pr-review changed files`
- `sync then audit docs/reference/`

Report using this skeleton; omit phase sections that did not run.

```text
## Run report

### Resolved invocation
- step / mode / scope / phase (single or combined)

### Phase 1 - <mode>
- Canonical files created or updated
- Validation gates executed and their exit codes (documentation-scoped only)
- Unresolved drift by class and canonical target

### Phase 2 - audit (or pre-pr-review)
- Findings grouped by canonical target file, with severity and class
- Totals by severity and by class
- Overall verdict
- Recommended follow-ups (out of scope for this run)
```

Treat [SKILL.md](../skills/system-documentation/SKILL.md) and
[AGENTS.md](../skills/system-documentation/AGENTS.md) as the canonical source
of behaviour for this prompt.
