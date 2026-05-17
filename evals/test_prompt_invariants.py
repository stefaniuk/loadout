"""Prompt regression invariants."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from evals.conftest import update_snapshots
from evals.runners import metrics, render, snapshots

FIXTURE_DIR = Path(__file__).parent / "fixtures"
SNAPSHOT_DIR = Path(__file__).parent / "snapshots"


def _discover_fixtures() -> list[Path]:
    return sorted(p for p in FIXTURE_DIR.glob("*.fixture.json"))


@pytest.mark.parametrize("fixture_path", _discover_fixtures(), ids=lambda p: p.name)
def test_prompt_invariants(fixture_path: Path, repo_root: Path) -> None:
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))
    prompt_path = repo_root / fixture["prompt"]
    assert prompt_path.exists(), f"prompt missing: {prompt_path}"

    frontmatter, body = render.render(prompt_path, repo_root)
    assert frontmatter, f"frontmatter missing or empty for {prompt_path}"

    for field in fixture.get("required_frontmatter_fields", []):
        assert field in frontmatter, f"frontmatter field missing: {field}"

    for needle in fixture.get("must_contain_substrings", []):
        assert needle in body, f"rendered body missing required substring: {needle!r}"

    assert metrics.unresolved_include_markers(body) == 0, (
        "unresolved include markers detected"
    )

    actual = {
        "token_count": metrics.token_count(body),
        "body_sha256": metrics.sha256_hex(body),
    }
    snapshot_path = SNAPSHOT_DIR / f"{fixture_path.stem}.snapshot.json"

    if update_snapshots():
        snapshots.save(snapshot_path, actual)
        return

    expected = snapshots.load(snapshot_path)
    assert expected is not None, (
        f"snapshot missing: {snapshot_path}. Run `UPDATE_SNAPSHOTS=1 make test-evals` to create."
    )
    diffs = snapshots.compare(actual, expected, fixture.get("tolerances", {}))
    assert not diffs, "snapshot mismatch:\n  - " + "\n  - ".join(diffs)
