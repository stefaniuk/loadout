"""Metrics for prompt regression testing."""

from __future__ import annotations

import hashlib
import re

import tiktoken

_HEADING_RE = re.compile(r"^(#{2,3})\s+(.+?)\s*$", re.MULTILINE)
_INCLUDE_MARKER_RE = re.compile(r"\{\{\s*INCLUDE:")


def token_count(text: str, model: str = "gpt-4o") -> int:
    """Count tokens using ``tiktoken``; fall back to cl100k_base."""
    try:
        enc = tiktoken.encoding_for_model(model)
    except (KeyError, ValueError):
        enc = tiktoken.get_encoding("cl100k_base")
    return len(enc.encode(text))


def heading_outline(body: str) -> list[str]:
    """Return ``##`` and ``###`` headings in document order."""
    return [f"{m.group(1)} {m.group(2)}" for m in _HEADING_RE.finditer(body)]


def unresolved_include_markers(body: str) -> int:
    """Count occurrences of ``{{ INCLUDE: ...}}`` style markers."""
    return len(_INCLUDE_MARKER_RE.findall(body))


def sha256_hex(text: str) -> str:
    """Return the hex-encoded SHA-256 of ``text``."""
    return hashlib.sha256(text.encode("utf-8")).hexdigest()
