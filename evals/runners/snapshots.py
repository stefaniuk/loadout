"""Snapshot load/save/compare helpers."""

from __future__ import annotations

import json
from pathlib import Path


def load(path: Path) -> dict | None:
    """Load a JSON snapshot; return ``None`` when missing."""
    if not path.exists():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def save(path: Path, data: dict) -> None:
    """Persist ``data`` as deterministic JSON with a trailing newline."""
    path.parent.mkdir(parents=True, exist_ok=True)
    serialised = json.dumps(data, indent=2, sort_keys=True)
    path.write_text(serialised + "\n", encoding="utf-8")


def compare(actual: dict, expected: dict, tolerances: dict) -> list[str]:
    """Compare ``actual`` against ``expected``. Return diff messages."""
    diffs: list[str] = []
    for key, exp_value in expected.items():
        if key not in actual:
            diffs.append(f"missing key: {key}")
            continue
        act_value = actual[key]
        if (
            key in tolerances
            and isinstance(exp_value, (int, float))
            and isinstance(act_value, (int, float))
        ):
            tol = float(tolerances[key])
            allowed = abs(exp_value) * tol
            if abs(act_value - exp_value) > allowed:
                diffs.append(
                    f"{key}: {act_value} differs from {exp_value} by more than ±{tol:.0%}"
                )
        elif act_value != exp_value:
            diffs.append(f"{key}: {act_value!r} != {exp_value!r}")
    for key in actual:
        if key not in expected:
            diffs.append(f"unexpected key: {key}")
    return diffs
