# v2 Dogfooding Guide

A diligent, copy-pasteable runbook for validating the v2 refactor (skills, hooks, AGENTS.md) before merging `v2` → `main`. Run every step in order. Tick each checklist item as you go.

> **Assumes**: macOS/Linux, zsh or bash, git ≥ 2.40, `make`, `shellcheck`, `lychee`, `editorconfig-checker`, and a working VS Code with the GitHub Copilot Chat extension. The repo's existing `make` targets pull these in via `scripts/init.mk` if missing.

---

## Phase 0 — Pre-flight

### Goal

Verify your local checkout is clean and the toolchain is healthy before doing anything destructive.

### Commands

```bash
# 1. Move to the repo
cd ~/Projects/stefaniuk/awesome-copilot-promptfiles

# 2. Confirm working tree state
git status -sb
git log --oneline -5

# 3. Confirm tooling is on PATH
command -v make shellcheck lychee editorconfig-checker bash zsh git code

# 4. Confirm gates are green on the current tree
make lint
make test
```

### Checklist

- [ ] `git status -sb` shows no unexpected untracked or modified files outside the v2 change set.
- [ ] All required tools resolve to a real path.
- [ ] `make lint` exits 0 with `file format: ok / markdown format: ok / markdown links: ok / shell lint: ok`.
- [ ] `make test` exits 0 and prints `apply: ok` and `import: ok` (71/71 cases).

---

## Phase 1 — Move v2 work off `main`

### Goal

Park the 45-file change set on a long-lived `v2` integration branch and restore `main` to track `origin/main`.

### Commands

```bash
# 1. Confirm what is staged vs committed
git status -sb
git diff --cached --stat | tail -5

# 2. Create the v2 branch from current HEAD (carries staged changes)
git switch -c v2

# 3. Commit the staged changes with a conventional message
git commit -m "feat(v2)!: migrate prompts to skills, add hooks and AGENTS.md

BREAKING CHANGE: 21 prompts replaced by skill wrappers; downstream
consumers using direct prompt names must invoke via the new wrappers."

# 4. Push v2 and set upstream
git push -u origin v2

# 5. Reset local main to remote main (no force-push needed: main never diverged)
git switch main
git fetch origin
git reset --hard origin/main

# 6. Verify
git status -sb
git log --oneline -3
```

### Checklist

- [ ] `v2` branch exists locally and on `origin`.
- [ ] `git log v2 --oneline -1` shows the new commit.
- [ ] `git status -sb` on `main` reports `## main...origin/main` with no ahead/behind.
- [ ] `git diff main..v2 --stat` shows the full 45-file change set.

---

## Phase 2 — Switch back to `v2` for testing

### Commands

```bash
git switch v2
git status -sb
make lint
make test
```

### Checklist

- [ ] On branch `v2`, working tree clean.
- [ ] `make lint` and `make test` both green.

---

## Phase 3 — Self-apply smoke test (clean target)

### Goal

Verify `apply.sh` lands every v2 artefact correctly into a pristine target project, and that `revert=true` removes them cleanly.

### Commands

```bash
# 1. Create a throwaway target
SMOKE=/tmp/v2-smoke-$(date +%Y%m%d-%H%M%S)
mkdir -p "$SMOKE"
cd "$SMOKE"
git init -q
echo "# v2 smoke" > README.md
git add . && git commit -q -m "init"

# 2. Return to repo and run apply with all technologies
cd ~/Projects/stefaniuk/awesome-copilot-promptfiles
all=true ./scripts/apply.sh "$SMOKE"

# 3. Inspect what landed
cd "$SMOKE"
ls -la
ls -la .github/
ls -la .github/agents .github/hooks .github/instructions .github/prompts .github/skills
ls -la scripts/hooks
test -f AGENTS.md && echo "AGENTS.md present"
test -f .github/copilot-instructions.md && echo "copilot-instructions.md present"
test -f .github/hooks/quality-gates.json && echo "hooks JSON present"
test -x scripts/hooks/post-edit-lint.sh && echo "post-edit-lint.sh executable"
test -x scripts/hooks/stop-gate.sh && echo "stop-gate.sh executable"
test -d .github/skills/code-review && echo "code-review skill present"
test -d .github/skills/enforcement-audit && echo "enforcement-audit skill present"
test -d .github/skills/architecture-docs && echo "architecture-docs skill present"
test -d .github/skills/repository-template && echo "repository-template skill present"

# 4. Sanity-check the .gitignore managed block
grep -A1 "promptfiles:begin" .gitignore || echo "WARN: managed gitignore block missing"

# 5. Count copied artefacts (should be non-zero in each)
find .github/agents -name '*.md' | wc -l
find .github/instructions -name '*.md' | wc -l
find .github/prompts -name '*.md' | wc -l
find .github/skills -mindepth 2 -name 'SKILL.md' | wc -l

# 6. Verify managed files are tracked correctly by git in target
cd "$SMOKE"
git status -sb | head -30
```

### Checklist

- [ ] `apply.sh` exits 0.
- [ ] Every `test -f` / `test -d` / `test -x` line above prints its success message.
- [ ] `.gitignore` contains the `promptfiles:begin … promptfiles:end` managed section.
- [ ] All four `find … | wc -l` counts are > 0 and roughly match expectations (agents: 9, skills: ≥4, prompts: ≥30).
- [ ] No files dropped outside `.github/`, `scripts/`, `.specify/`, `docs/`, `AGENTS.md`, `Makefile`, `project.code-workspace` (per `apply.sh` contract).

---

## Phase 4 — Revert smoke test

### Goal

Confirm `revert=true` removes only managed artefacts and leaves the user's own files untouched.

### Commands

```bash
# 1. Snapshot pre-revert tree
cd "$SMOKE"
find . -type f ! -path './.git/*' | sort > /tmp/v2-pre-revert.txt

# 2. Revert
cd ~/Projects/stefaniuk/awesome-copilot-promptfiles
revert=true ./scripts/apply.sh "$SMOKE"

# 3. Snapshot post-revert tree and diff
cd "$SMOKE"
find . -type f ! -path './.git/*' | sort > /tmp/v2-post-revert.txt
diff /tmp/v2-pre-revert.txt /tmp/v2-post-revert.txt | head -80

# 4. Confirm only README.md (your own file) remains under tracked content
ls -la
git status -sb
```

### Checklist

- [ ] `revert=true ./scripts/apply.sh` exits 0.
- [ ] Diff shows only managed artefacts removed (lines prefixed `<`); no `>` lines except expected ignorables.
- [ ] `README.md` (the user's file) is still present and unchanged.
- [ ] `.gitignore` either is back to original or contains an empty managed block (no orphan content).
- [ ] `.github/`, `.specify/`, `scripts/hooks/`, `AGENTS.md` all gone if not user-authored.

---

## Phase 5 — Per-technology apply matrix

### Goal

Catch any technology-flag regression (e.g. `django=true` failing to auto-enable `python`).

### Commands

```bash
cd ~/Projects/stefaniuk/awesome-copilot-promptfiles
for tech in python typescript go reactjs rust terraform tauri django fastapi; do
  T=/tmp/v2-tech-$tech-$(date +%s)
  mkdir -p "$T" && (cd "$T" && git init -q)
  echo "=== Testing tech=$tech ==="
  $tech=true ./scripts/apply.sh "$T" || { echo "FAIL: $tech"; break; }
  ls "$T/.github/instructions" | grep -i "$tech" || echo "  (no $tech instruction file — check if expected)"
  revert=true ./scripts/apply.sh "$T" >/dev/null
  rm -rf "$T"
  echo "=== OK: $tech ==="
done
```

### Checklist

- [ ] Every technology flag exits 0.
- [ ] Auto-enable rules verified manually for `tauri` (pulls rust + typescript + reactjs), `django` and `fastapi` (pull python), `playwright` (requires python or typescript).
- [ ] No leftover files after each revert.

---

## Phase 6 — Round-trip with `import.sh`

### Goal

Verify the inverse direction: a downstream change can be imported back into the source repo without surprise.

### Commands

```bash
# 1. Apply to a fresh target
cd ~/Projects/stefaniuk/awesome-copilot-promptfiles
TRIP=/tmp/v2-roundtrip-$(date +%s)
mkdir -p "$TRIP" && (cd "$TRIP" && git init -q && echo "# rt" > README.md && git add . && git commit -q -m init)
all=true ./scripts/apply.sh "$TRIP"

# 2. Make a tiny intentional edit in the target
echo "" >> "$TRIP/.github/skills/code-review/SKILL.md"
echo "<!-- dogfood marker $(date +%s) -->" >> "$TRIP/.github/skills/code-review/SKILL.md"

# 3. Dry-run / preview an import (will copy the modified file back)
./scripts/import.sh "$TRIP"

# 4. Inspect what came back
git status -sb
git diff -- .github/skills/code-review/SKILL.md | head -20

# 5. Roll back the source-side change so we don't pollute v2
git checkout -- .github/skills/code-review/SKILL.md
```

### Checklist

- [ ] `import.sh` runs without error.
- [ ] The marker line appears in the source repo's `SKILL.md` after import.
- [ ] `git checkout --` cleanly reverts the import.
- [ ] No stray files appear outside the expected paths.

---

## Phase 7 — Open the smoke target in VS Code (manual)

### Goal

Validate that VS Code Copilot actually loads skills, prompts, and hooks correctly from a freshly-applied target.

### Commands

```bash
SMOKE=/tmp/v2-vscode-$(date +%s)
mkdir -p "$SMOKE" && (cd "$SMOKE" && git init -q && echo "# vscode test" > README.md && git add . && git commit -q -m init)
cd ~/Projects/stefaniuk/awesome-copilot-promptfiles
all=true ./scripts/apply.sh "$SMOKE"
code "$SMOKE"
```

### Manual checklist (perform inside VS Code)

- [ ] Copilot Chat shows `AGENTS.md` and `.github/copilot-instructions.md` loaded (check the context panel).
- [ ] Typing `/` in chat lists the v2 prompt wrappers (e.g. `/architecture.01-…`, `/enforce.python`, `/review.speckit-…`).
- [ ] Selecting one wrapper produces a session that names the corresponding skill (`code-review`, `enforcement-audit`, `architecture-docs`).
- [ ] Asking Copilot to "review the staged changes" actually invokes the `code-review` skill (verify by content, not just name).
- [ ] Edit any file in the target via Copilot → confirm `PostToolUse` hook runs `make lint` (visible in terminal output panel within 60 s).
- [ ] Ask Copilot to "complete the task" while a deliberate lint error is present → confirm `Stop` hook blocks completion.
- [ ] Fix the lint error, retry → confirm completion is now allowed.

---

## Phase 8 — Real-project dogfooding (≥ 1 week)

### Goal

Use v2 on a real working project for a sustained period to surface friction the synthetic tests miss.

### Commands

```bash
# Pick a low-risk personal project
TARGET=~/Projects/<your-real-project>
cd ~/Projects/stefaniuk/awesome-copilot-promptfiles
git switch v2

# Apply with the technology flags that match the project
python=true ./scripts/apply.sh "$TARGET"   # adjust flags

cd "$TARGET"
git status -sb
git add .github AGENTS.md scripts/hooks .specify
git commit -m "chore: trial v2 promptfiles artefacts"
```

### Checklist (track over the trial period)

- [ ] At least 5 real coding sessions completed on the trial project using v2 artefacts.
- [ ] No hook timeout failures (60 s PostToolUse, 30 s Stop).
- [ ] Skill delegation works for at least 3 distinct prompt wrappers (record which).
- [ ] No spurious `Stop` blocks (false positives).
- [ ] No silent skill loads — every invocation either succeeds or surfaces a clear error.
- [ ] Notes captured in `docs/prompts/v2-dogfood-notes.md` (or similar) for any friction.

---

## Phase 9 — Cross-cutting validation

### Commands

```bash
cd ~/Projects/stefaniuk/awesome-copilot-promptfiles

# 1. Confirm prompt counts in quick-reference are accurate
PROMPT_COUNT=$(find .github/prompts -name '*.prompt.md' | wc -l | tr -d ' ')
AGENT_COUNT=$(find .github/agents -name '*.agent.md' | wc -l | tr -d ' ')
SKILL_COUNT=$(find .github/skills -mindepth 2 -name 'SKILL.md' | wc -l | tr -d ' ')
echo "prompts: $PROMPT_COUNT  agents: $AGENT_COUNT  skills: $SKILL_COUNT"
grep -E "[0-9]+ prompts|[0-9]+ agents" docs/guides/quick-reference.md

# 2. Verify every wrapper references a real skill
for p in .github/prompts/{architecture.0,enforce.,review.speckit-}*.prompt.md; do
  skill=$(grep -oE 'skills/[a-z-]+' "$p" | head -1)
  [[ -n "$skill" && -d ".github/$skill" ]] || echo "BROKEN: $p → $skill"
done

# 3. Hooks JSON is valid
python3 -m json.tool .github/hooks/quality-gates.json >/dev/null && echo "hooks JSON: ok"
python3 -m json.tool hooks.json >/dev/null && echo "root hooks.json: ok"
python3 -m json.tool plugin.json >/dev/null && echo "plugin.json: ok"

# 4. Hook scripts are executable and shellcheck-clean
shellcheck scripts/hooks/post-edit-lint.sh scripts/hooks/stop-gate.sh

# 5. Final gates
make lint
make test
```

### Checklist

- [ ] Prompt / agent / skill counts in `docs/guides/quick-reference.md` match actual filesystem counts (or the guide is updated).
- [ ] Every wrapper's referenced skill directory exists.
- [ ] All three JSON manifests parse without error.
- [ ] `shellcheck` is clean on both hook scripts.
- [ ] `make lint` and `make test` green one final time.

---

## Phase 10 — Pre-merge gates

### Goal

Final go/no-go review before squash-merging `v2` → `main`.

### Checklist

- [ ] All outstanding review findings either resolved or accepted with rationale recorded in [docs/adr/](../adr/).
- [ ] Phases 1–9 above all green.
- [ ] At least 1 week of Phase 8 dogfooding completed without blocker-class issues.
- [ ] CHANGELOG entry drafted listing the breaking change (prompt → skill wrapper migration).
- [ ] `plugin.json` version bumped: `1.0.0` → `2.0.0` (semver major; structural breaking change).
- [ ] CI runs `make lint` and `make test` on a fresh clone of `v2` and is green.
- [ ] Tag plan agreed: `v2.0.0` to be applied immediately after merge.

---

## Phase 11 — Merge and tag

### Commands

```bash
# 1. Final rebase on top of latest main
cd ~/Projects/stefaniuk/awesome-copilot-promptfiles
git fetch origin
git switch v2
git rebase origin/main          # resolve any drift

# 2. Squash-merge to main locally (preserves a single, auditable commit)
git switch main
git merge --squash v2
git commit -m "feat(v2)!: migrate prompts to skills, add hooks and AGENTS.md

BREAKING CHANGE: 21 prompts replaced by skill wrappers."

# 3. Push and tag
git push origin main
git tag -a v2.0.0 -m "v2.0.0 — skills, hooks, AGENTS.md"
git push origin v2.0.0

# 4. Keep v2 alive for one bug-fix cycle, then archive
# (deferred: do NOT delete v2 immediately after merge)
```

### Checklist

- [ ] `git rebase origin/main` clean (no conflicts).
- [ ] Squash-merge produced exactly one commit on `main`.
- [ ] `v2.0.0` tag pushed to `origin`.
- [ ] `v2` branch retained until next minor release.

---

## Rollback plan

If a regression is discovered post-merge:

```bash
# Revert the squash-merge commit
git switch main
git revert -m 1 <merge-or-squash-sha>
git push origin main

# Move tag pointer or publish a v2.0.1 with the fix instead of revert if possible
```

### Rollback checklist

- [ ] Decide between revert vs forward-fix within 24 h of regression report.
- [ ] If reverting: tag `v1.last-known-good` for downstream pinning.
- [ ] If forward-fixing: cut `v2.0.1` from `v2` branch with the fix.

---

> **Last Amended**: 2026-05-07
