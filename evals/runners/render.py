"""Rendering helpers: frontmatter parsing, include resolution, canonicalisation."""

from __future__ import annotations

import re
from pathlib import Path

import yaml

_FRONTMATTER_RE = re.compile(r"\A---\n(.*?)\n---\n?(.*)\Z", re.DOTALL)
_MD_LINK_RE = re.compile(r"\[([^\]]*)\]\(([^)\s]+)\)")

_INCLUDE_PREFIXES = (
    Path(".github/prompts/includes"),
    Path(".github/instructions/includes"),
)


def parse_frontmatter(text: str) -> tuple[dict, str]:
    """Split YAML frontmatter from body. Return ({}, text) if missing."""
    match = _FRONTMATTER_RE.match(text)
    if not match:
        return {}, text
    raw, body = match.group(1), match.group(2)
    data = yaml.safe_load(raw) or {}
    if not isinstance(data, dict):
        data = {}
    return data, body


def canonicalise(text: str) -> str:
    """Normalise line endings, strip trailing whitespace, collapse trailing blank lines."""
    normalised = text.replace("\r\n", "\n").replace("\r", "\n")
    stripped_lines = [line.rstrip() for line in normalised.split("\n")]
    # Drop trailing empty lines, then re-add exactly one newline.
    while stripped_lines and stripped_lines[-1] == "":
        stripped_lines.pop()
    return "\n".join(stripped_lines) + "\n"


def _is_include_target(target: Path, repo_root: Path) -> bool:
    try:
        rel = target.resolve().relative_to(repo_root.resolve())
    except ValueError:
        return False
    rel_str = str(rel).replace("\\", "/")
    return any(
        rel_str.startswith(str(p).replace("\\", "/") + "/") for p in _INCLUDE_PREFIXES
    )


def resolve_includes(
    body: str,
    base: Path,
    repo_root: Path,
    visited: set | None = None,
) -> str:
    """Inline Markdown links that point at include directories.

    Other links pass through unchanged. Cycles and traversal outside the
    repository raise ``ValueError``.
    """
    visited = visited if visited is not None else set()
    repo_resolved = repo_root.resolve()

    def replace(match: re.Match[str]) -> str:
        return _maybe_inline(match, base, repo_root, repo_resolved, visited)

    return _MD_LINK_RE.sub(replace, body)


def _maybe_inline(
    match: re.Match[str],
    base: Path,
    repo_root: Path,
    repo_resolved: Path,
    visited: set,
) -> str:
    link = match.group(2)
    if not link.endswith(".md") or link.startswith(
        ("http://", "https://", "#", "mailto:")
    ):
        return match.group(0)
    target = link.split("#", 1)[0].split("?", 1)[0]
    if not target:
        return match.group(0)
    target_path = (
        (base / target)
        if not target.startswith("/")
        else (repo_root / target.lstrip("/"))
    )
    try:
        resolved = target_path.resolve()
        resolved.relative_to(repo_resolved)
    except (OSError, ValueError) as exc:
        raise ValueError(f"Include target escapes repository: {link}") from exc
    if not _is_include_target(target_path, repo_root):
        return match.group(0)
    if not resolved.exists():
        raise ValueError(f"Include target does not exist: {resolved}")
    if resolved in visited:
        raise ValueError(f"Cyclic include detected: {resolved}")
    visited.add(resolved)
    try:
        raw = resolved.read_text(encoding="utf-8")
        _, inner_body = parse_frontmatter(raw)
        inlined = resolve_includes(inner_body, resolved.parent, repo_root, visited)
    finally:
        visited.discard(resolved)
    return inlined.rstrip("\n")


def render(prompt_path: Path, repo_root: Path) -> tuple[dict, str]:
    """Return (frontmatter, canonicalised body with includes resolved)."""
    text = prompt_path.read_text(encoding="utf-8")
    frontmatter, body = parse_frontmatter(text)
    resolved = resolve_includes(body, prompt_path.parent, repo_root)
    return frontmatter, canonicalise(resolved)
