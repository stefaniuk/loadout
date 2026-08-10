#!/usr/bin/env python3
"""Validate customisation artefact frontmatter and filename conventions.

Discovers instruction packs, prompts, agents, and skills under the standard
parent directories and validates each artefact's YAML frontmatter against
``scripts/quality/schemas/customisation-frontmatter.schema.json``. Also enforces
kebab-case naming rules and ``applyTo`` glob compilability via
``wcmatch.glob.translate``.

Exit code is 0 when zero errors are detected, otherwise 1. Each error is
emitted as ``<path>: <message>``. Run via the shell wrapper or directly with::

    uv run --with jsonschema --with pyyaml --with wcmatch \
        python scripts/quality/validate-customisations.py
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

import yaml
from jsonschema import Draft202012Validator
from wcmatch import glob as wcglob

ROOT = Path(__file__).resolve().parents[2]
SCHEMA_PATH = ROOT / "scripts/quality/schemas/customisation-frontmatter.schema.json"

STANDARD_PARENTS = {
    "instruction": ROOT / ".github/instructions",
    "prompt": ROOT / ".github/prompts",
    "agent": ROOT / ".github/agents",
    "skill": ROOT / ".github/skills",
}

SUFFIX_BY_TYPE = {
    "instruction": ".instructions.md",
    "prompt": ".prompt.md",
    "agent": ".agent.md",
}

KEBAB_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
SKIP_DIR_NAMES = {"includes", "templates"}
SKILLS_CONFIG = ROOT / "scripts/config/skills.yaml"

WC_FLAGS = wcglob.BRACE | wcglob.GLOBSTAR


def synced_skill_names() -> set[str]:
    """Return set of skill names declared in the synced skills manifest."""
    if not SKILLS_CONFIG.is_file():
        return set()
    try:
        data = yaml.safe_load(SKILLS_CONFIG.read_text(encoding="utf-8"))
    except (OSError, yaml.YAMLError):
        return set()
    skills = data.get("skills") if isinstance(data, dict) else None
    if not isinstance(skills, list):
        return set()
    return {s["name"] for s in skills if isinstance(s, dict) and "name" in s}


def is_kebab(value: str) -> bool:
    """Return True if ``value`` matches kebab-case (``a-z0-9`` segments)."""
    return bool(KEBAB_RE.match(value))


def is_in_skipped_dir(path: Path) -> bool:
    """Return True if any path component is a skip directory."""
    return any(part in SKIP_DIR_NAMES for part in path.relative_to(ROOT).parts)


def parse_frontmatter(text: str) -> tuple[dict | None, str | None]:
    """Parse YAML frontmatter; return (data, error_message)."""
    if not text.startswith("---"):
        return None, "missing YAML frontmatter (expected leading '---')"
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None, "missing YAML frontmatter (expected leading '---')"
    end_idx = None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            end_idx = i
            break
    if end_idx is None:
        return None, "unterminated YAML frontmatter (missing closing '---')"
    block = "\n".join(lines[1:end_idx])
    try:
        data = yaml.safe_load(block) if block.strip() else {}
    except yaml.YAMLError as exc:
        return None, f"invalid YAML frontmatter: {exc}"
    if data is None:
        data = {}
    if not isinstance(data, dict):
        return None, "frontmatter must be a YAML mapping"
    return data, None


def discover_instructions() -> list[Path]:
    base = STANDARD_PARENTS["instruction"]
    if not base.is_dir():
        return []
    out: list[Path] = []
    for p in sorted(base.rglob("*.instructions.md")):
        if is_in_skipped_dir(p) or p.name == "README.md":
            continue
        out.append(p)
    return out


def discover_prompts() -> list[Path]:
    base = STANDARD_PARENTS["prompt"]
    if not base.is_dir():
        return []
    out: list[Path] = []
    for p in sorted(base.rglob("*.prompt.md")):
        if is_in_skipped_dir(p) or p.name == "README.md":
            continue
        out.append(p)
    return out


def discover_agents() -> list[Path]:
    base = STANDARD_PARENTS["agent"]
    if not base.is_dir():
        return []
    out: list[Path] = []
    for p in sorted(base.rglob("*.agent.md")):
        if is_in_skipped_dir(p) or p.name == "README.md":
            continue
        out.append(p)
    return out


def discover_skills() -> list[Path]:
    base = STANDARD_PARENTS["skill"]
    if not base.is_dir():
        return []
    synced = synced_skill_names()
    out: list[Path] = []
    for p in sorted(base.rglob("SKILL.md")):
        if is_in_skipped_dir(p):
            continue
        if p.parent.name in synced:
            continue
        out.append(p)
    return out


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def validate_variant(
    data: dict,
    schema: dict,
    artefact_type: str,
) -> list[str]:
    """Validate ``data`` against the named variant in the oneOf schema."""
    variants = {v["title"]: v for v in schema["oneOf"]}
    variant = variants[artefact_type]
    validator = Draft202012Validator(variant)
    msgs: list[str] = []
    for err in sorted(validator.iter_errors(data), key=lambda e: list(e.path)):
        loc = "/".join(str(p) for p in err.path) or "<root>"
        msgs.append(f"frontmatter: {loc}: {err.message}")
    return msgs


def validate_apply_to(value: str) -> str | None:
    """Return error message if ``value`` is not a compilable wcmatch glob."""
    try:
        wcglob.translate(value, flags=WC_FLAGS)
    except Exception as exc:  # noqa: BLE001 -- surface any compilation failure
        return f"applyTo glob does not compile: {exc}"
    return None


def stem_for(path: Path, suffix: str) -> str:
    """Return filename with trailing ``suffix`` removed."""
    name = path.name
    if not name.endswith(suffix):
        return name
    return name[: -len(suffix)]


def validate_artefact(
    path: Path,
    artefact_type: str,
    schema: dict,
) -> list[str]:
    msgs: list[str] = []
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as exc:
        return [f"cannot read file: {exc}"]

    data, err = parse_frontmatter(text)
    if err is not None:
        msgs.append(err)
        return msgs

    msgs.extend(validate_variant(data, schema, artefact_type))

    if artefact_type == "instruction":
        stem = stem_for(path, SUFFIX_BY_TYPE["instruction"])
        if not is_kebab(stem):
            msgs.append(f"filename stem '{stem}' is not kebab-case")
        apply_to = data.get("applyTo")
        if isinstance(apply_to, str) and apply_to:
            err = validate_apply_to(apply_to)
            if err is not None:
                msgs.append(err)
    elif artefact_type == "prompt":
        stem = stem_for(path, SUFFIX_BY_TYPE["prompt"])
        for seg in stem.split("."):
            if not is_kebab(seg):
                msgs.append(f"filename segment '{seg}' is not kebab-case")
    elif artefact_type == "agent":
        stem = stem_for(path, SUFFIX_BY_TYPE["agent"])
        for seg in stem.split("."):
            if not is_kebab(seg):
                msgs.append(f"filename segment '{seg}' is not kebab-case")
    elif artefact_type == "skill":
        folder = path.parent.name
        if not is_kebab(folder):
            msgs.append(f"skill folder '{folder}' is not kebab-case")
        name_field = data.get("name")
        if isinstance(name_field, str):
            if not is_kebab(name_field):
                msgs.append(f"name '{name_field}' is not kebab-case")
            if name_field != folder:
                msgs.append(f"name '{name_field}' does not match folder '{folder}'")

    return msgs


def main() -> int:
    schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))

    artefacts: list[tuple[Path, str]] = []
    for p in discover_instructions():
        artefacts.append((p, "instruction"))
    for p in discover_prompts():
        artefacts.append((p, "prompt"))
    for p in discover_agents():
        artefacts.append((p, "agent"))
    for p in discover_skills():
        artefacts.append((p, "skill"))

    errors: list[tuple[str, str]] = []
    for path, atype in artefacts:
        for msg in validate_artefact(path, atype, schema):
            errors.append((rel(path), msg))

    errors.sort(key=lambda e: (e[0], e[1]))
    for path_str, message in errors:
        print(f"{path_str}: {message}")

    print(
        f"\ncustomisations: {len(artefacts)} artefacts checked, {len(errors)} error(s)",
        file=sys.stderr,
    )
    return 0 if not errors else 1


if __name__ == "__main__":
    sys.exit(main())
