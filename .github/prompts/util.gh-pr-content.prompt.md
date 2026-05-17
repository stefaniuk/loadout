---
description: Create pull request content from the current branch changes
---

**Mandatory preparation:**

- Read the [constitution](../../.specify/memory/constitution.md) and honour its non-negotiable rules.
- Read the Pull Request template at [pull_request_template.md](../pull_request_template.md) so the generated content mirrors it exactly.
- Read the technology-specific instructions for every language touched in the diff (for example [python.instructions.md](../instructions/python.instructions.md), [shell.instructions.md](../instructions/shell.instructions.md), [makefile.instructions.md](../instructions/makefile.instructions.md)).
- Review the design context under `docs/prompt-reports/` to describe affected components accurately.

## Goal 🎯

Craft a diff-driven pull request title and body, ready to copy/paste, that compares the current branch (plus staged/unstaged changes) against `main`, summarises behaviour, lists verification evidence, and fills every section of [pull_request_template.md](../pull_request_template.md).

---

## Discovery (run before writing) 🔍

### A. Establish the diff against `main`

Run the labelled batch below **once** from the repository root. Output is written to `docs/prompt-reports/git-pr-content-diff.txt` so that large diffs do not overflow the terminal context.

```bash
_diff_file="docs/prompt-reports/git-pr-content-diff.txt"
: > "$_diff_file"
if ! git show-ref --verify --quiet refs/heads/main; then
  printf '\n>>> %s\n' "git fetch origin main:main" | tee -a "$_diff_file"
  git fetch origin main:main 2>&1 | tee -a "$_diff_file"
fi
for cmd in \
  "git diff --stat main...HEAD" \
  "git diff main...HEAD" \
  "git status -sb" \
  "git rev-parse --abbrev-ref HEAD"; do
    printf '\n>>> %s\n' "$cmd" >> "$_diff_file"
    eval "$cmd" >> "$_diff_file" 2>&1
done
printf '\nDiff captured → %s (%s bytes)\n' "$_diff_file" "$(wc -c < "$_diff_file")"
```

After the script completes, **read the file `docs/prompt-reports/git-pr-content-diff.txt`** in full and use its contents as the authoritative diff evidence for the rest of this review.

- Use `git diff --stat main...HEAD` for the overview and `git diff main...HEAD` for detailed evidence.
- Capture branch/working-tree information from `git status -sb` and `git rev-parse --abbrev-ref HEAD`.
- If there is no diff, stop and report **"No diff vs main – nothing to raise."**

### B. Summarise behavioural impact

1. Enumerate the files, components, and flows touched (map component names to `docs/prompt-reports/*`).
2. Identify change categories (bug fix, feature, refactor, documentation, tooling) and note any public interfaces affected.
3. Record configuration, schema, or dependency updates.
4. Capture open questions as **Unknown from code – {action needed}**.

### C. Quality gates & evidence

1. Run the repository-quality gates (for example `make lint`, `make test`, tool-specific suites) after syncing dependencies.
2. Record the exact commands executed, their status, and any failures (include logs or pointer files when relevant).
3. Note follow-up checks that must still run (for example integration tests in CI).

### D. Detect prior content and determine output file

1. Define the output file path for today:
   - `docs/prompt-reports/pr-content-YYYYMMDD.report.md` (use today's date)
2. If the file already exists:
   - Read it fully.
   - Compare against the current diff to identify what has changed since the last run.
   - Overwrite the file with updated content reflecting the latest branch state.
3. If the file does not exist:
   - Create it with the generated PR content.

---

## Steps 👣

1. **Derive the pull request title**
   - Use Conventional Commit style `type(scope): summary` with lower-case type and bracketed scope (for example `feat(shell): tighten hook logging`).
   - Keep it ≤ 72 characters, action-oriented, British English.
   - Reflect the dominant change category and scope (for example `fix(ci): stabilise markdown lint`).
   - Mention breaking changes explicitly by adding `!` after the type/scope (for example `feat(api)!: ...`).
2. **Populate the Description section**
   - Summarise behaviour changes in 1–2 sentences referencing affected components.
   - Use bullet points for specifics (inputs, outputs, contracts, migrations, configuration).
   - Reference evidence via workspace-relative Markdown links wherever possible.
3. **Populate the Context section**
   - Explain the problem statement, user need, or specification driver.
   - Call out linked specs/ADRs/tasks via Markdown links.
4. **Set the "Type of changes" checkboxes**
   - Choose `x` for every applicable category (Refactoring, New feature, Breaking change, Bug fix) based on the diff.
   - Leave non-applicable items unchecked (`[ ]`). Never delete a line from the template.
5. **Update the Checklist section**
   - Reflect actual work done (`[x]`) vs outstanding (`[ ]`).
   - Always reference whether tests/docs were updated, style guidelines were followed, and collaboration mode (pair/mob/vibe) occurred.
6. **Populate "Sensitive Information Declaration"**
   - Confirm (`[x]`) only if you verified no PII/PID/sensitive data exists in the changes; otherwise leave unchecked and note required remediation.
7. **Highlight verification evidence**
   - Mention commands run (`make lint`, `make test`, bespoke scripts) and their outcomes inside Description or Context bullets.
   - Use **Unknown from code – run {command}** where evidence is missing.
8. **Call out follow-ups**
   - If additional work is deferred, list it succinctly (for example documentation gaps, pending ADRs) under Description or Context as bullet points.
9. **Write the output file (required)**
   - Write all generated PR content to `docs/prompt-reports/pr-content-YYYYMMDD.report.md` (use today's date).
   - If the file exists, overwrite it with the updated content.
   - Include a **Generated** footer with the current timestamp.

---

## Output requirements 📋

- Write the generated content to `docs/prompt-reports/pr-content-YYYYMMDD.report.md`.
- Produce copy-ready raw Markdown using the structure below (include the title and every section in order).
- Replace placeholder ellipses with actual content; never leave template instructions in the final text.
- Use workspace-relative Markdown links (for example `[scripts/apply.sh](scripts/apply.sh#L10-L40)`).
- Maintain ASCII-only content unless evidence requires Unicode.

```markdown
# {pull request title}

## Description

{3-5 bullet points grounded in the diff}

## Context

{why the change is needed, linked artefacts/specs}

## How to test it

{steps to verify the change, commands run, evidence}

## Type of changes

- [ ] Refactoring (non-breaking change)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would change existing functionality)
- [ ] Bug fix (non-breaking change which fixes an issue)

## Checklist

- [ ] I am familiar with the contributing guidelines
- [ ] I have followed the code style of the project
- [ ] I have added tests to cover my changes
- [ ] I have updated the documentation accordingly
- [ ] This PR is a result of pair or mob programming
- [ ] This PR is a result of AI-assisted development sessions

## Sensitive Information Declaration

- [ ] I confirm that neither PII/PID nor sensitive data are included in this PR and the codebase changes.

---

> Generated: YYYY-MM-DD hh:mm:ss
```

Add additional sections (for example "Testing", "Follow-ups") **only** if the template explicitly gains them in future revisions, and keep the order consistent with the template file.

---

> **Version**: 1.1.1
> **Last Amended**: 2026-02-20
