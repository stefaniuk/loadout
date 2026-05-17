"""Pytest configuration for the prompt regression eval harness."""

from __future__ import annotations

import os
import sys
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent

# Ensure `evals` is importable as a package for the runners modules.
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))


@pytest.fixture(scope="session")
def repo_root() -> Path:
    """Return the absolute path to the repository root."""
    return REPO_ROOT


def update_snapshots() -> bool:
    """Return True when the harness should (re)write snapshots."""
    return os.environ.get("UPDATE_SNAPSHOTS", "") not in ("", "0", "false")
