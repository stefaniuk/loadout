# Prompt regression eval harness

Pytest-based regression suite for prompt files in `.github/prompts/`. Renders each fixtured prompt (resolving include links and canonicalising whitespace), then asserts structural invariants and compares numeric/textual fingerprints against committed snapshots.

## Run

```bash
make test-evals
```

## Update snapshots

```bash
UPDATE_SNAPSHOTS=1 make test-evals
```

Commit the regenerated files under `evals/snapshots/`.

## Layout

```text
evals/
  conftest.py                  # fixtures + UPDATE_SNAPSHOTS helper
  runners/
    render.py                  # frontmatter + include resolution + canonicalisation
    metrics.py                 # token counts, headings, SHA-256
    snapshots.py               # load/save/compare JSON snapshots
  fixtures/*.fixture.json      # one per prompt under test
  snapshots/*.snapshot.json    # generated; tracked in git
  test_prompt_invariants.py    # parametrised pytest module
```

Each fixture declares the prompt path, required frontmatter fields, substrings that must appear in the rendered body, and per-metric tolerances (e.g. `token_count: 0.10` accepts ±10%).
