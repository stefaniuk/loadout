#!/usr/bin/env python3
"""Generate the artefact catalogue (catalogue.json + docs/catalogue.md).

Discovers instructions, prompts, agents, skills, and hooks under the repository
and emits a machine-readable JSON file plus a human-readable Markdown rendering
built from the same in-memory model.
"""

from __future__ import annotations

import datetime as _dt
import json
import re
import subprocess
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "--quiet", "pyyaml"])
    import yaml

ROOT = Path(__file__).resolve().parents[2]

TYPE_ORDER = ["instruction", "prompt", "agent", "skill", "hook"]
STANDARD_PARENTS = {
    "instruction": ".github/instructions",
    "prompt": ".github/prompts",
    "agent": ".github/agents",
    "skill": ".github/skills",
}

SUFFIX_BY_TYPE = {
    "instruction": ".instructions.md",
    "prompt": ".prompt.md",
    "agent": ".agent.md",
}

# Language-pack convention (see docs/conventions.md).
PACK_CLASS = {
    "python": "language",
    "typescript": "language",
    "go": "language",
    "rust": "language",
    "docker": "tool",
    "makefile": "tool",
    "shell": "tool",
    "terraform": "tool",
    "reactjs": "framework",
    "tauri": "framework",
    "playwright-python": "framework",
    "playwright-typescript": "framework",
}
# Instruction-only artefacts: not language packs.
FOUNDATION_PACKS = {"likec4", "readme"}
PACK_SKILLS = {
    "python": ["django-project", "fastapi-project"],
}
PACK_ADR = {
    "python": "ADR-001",
    "typescript": "ADR-002",
    "go": "ADR-003",
    "rust": "ADR-004",
}

# Plugin-pack classification (see docs/conventions.md#plugin-packs).
# Artefacts belong to either the optional `speckit` pack or the default `core`
# pack. The split is documentation-only — plugin.json installs both together;
# selective install is via `make apply subset=…`.
SPECKIT_PACK = "speckit"
CORE_PACK = "core"


def classify_pack(rec: dict) -> str:
    """Return the plugin pack (`speckit` or `core`) for an artefact record.

    Rules applied in order:

    1. Path under `.specify/` -> speckit (future-proofing).
    2. Agent named `speckit.*` -> speckit.
    3. Prompt named `speckit.*` or `review.speckit-*` -> speckit.
    4. Otherwise -> core.
    """
    path = rec.get("path", "")
    if path.startswith(".specify/"):
        return SPECKIT_PACK
    name = rec.get("name", "")
    type_ = rec.get("type")
    if type_ == "agent" and name.startswith("speckit."):
        return SPECKIT_PACK
    if type_ == "prompt" and name.startswith(("speckit.", "review.speckit-")):
        return SPECKIT_PACK
    return CORE_PACK


def load_frontmatter(path: Path) -> dict:
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as exc:
        print(f"warn: cannot read {path}: {exc}", file=sys.stderr)
        return {}
    if not text.startswith("---"):
        print(f"warn: missing frontmatter in {path}", file=sys.stderr)
        return {}
    end = text.find("\n---", 3)
    if end == -1:
        print(f"warn: unterminated frontmatter in {path}", file=sys.stderr)
        return {}
    try:
        return yaml.safe_load(text[3:end].strip()) or {}
    except yaml.YAMLError as exc:
        print(f"warn: YAML error in {path}: {exc}", file=sys.stderr)
        return {}


def rel(path: Path) -> str:
    return path.resolve().relative_to(ROOT).as_posix()


def name_from_filename(path: Path, type_: str) -> str:
    suffix = SUFFIX_BY_TYPE.get(type_)
    if suffix and path.name.endswith(suffix):
        return path.name[: -len(suffix)]
    return path.stem


def parent_tag(path: Path, type_: str) -> str | None:
    expected = STANDARD_PARENTS.get(type_)
    if expected is None:
        return None
    rel_path = rel(path)
    parent = rel_path.rsplit("/", 1)[0]
    if parent == expected:
        return None
    # Strip the standard prefix to keep tag short.
    if parent.startswith(expected + "/"):
        return parent[len(expected) + 1 :]
    return parent


def build_tags(path: Path, type_: str, extras: list[str] | None = None) -> list[str]:
    tags: set[str] = set()
    if type_ in SUFFIX_BY_TYPE:
        prefix = path.name.split(".", 1)[0]
        if prefix:
            tags.add(prefix)
    pt = parent_tag(path, type_)
    if pt:
        tags.add(pt)
    if extras:
        for t in extras:
            if t:
                tags.add(t)
    return sorted(tags)


def safe_str(value) -> str:
    if value is None:
        return ""
    return str(value)


def collect_instructions() -> list[dict]:
    folder = ROOT / ".github/instructions"
    records = []
    for path in sorted(folder.glob("*.instructions.md")):
        fm = load_frontmatter(path)
        rp = rel(path)
        records.append(
            {
                "id": f"instruction:{rp}",
                "type": "instruction",
                "path": rp,
                "name": name_from_filename(path, "instruction"),
                "description": safe_str(fm.get("description", "")).strip(),
                "applyTo": fm.get("applyTo") or None,
                "tags": build_tags(path, "instruction"),
                "metadata": {},
            }
        )
    return records


def collect_prompts() -> list[dict]:
    folder = ROOT / ".github/prompts"
    records = []
    for path in sorted(folder.glob("*.prompt.md")):
        fm = load_frontmatter(path)
        rp = rel(path)
        records.append(
            {
                "id": f"prompt:{rp}",
                "type": "prompt",
                "path": rp,
                "name": name_from_filename(path, "prompt"),
                "description": safe_str(fm.get("description", "")).strip(),
                "applyTo": None,
                "tags": build_tags(path, "prompt"),
                "metadata": {
                    "agent": fm.get("agent") or None,
                    "argumentHint": fm.get("argument-hint") or None,
                },
            }
        )
    return records


def collect_agents() -> list[dict]:
    folder = ROOT / ".github/agents"
    records = []
    for path in sorted(folder.rglob("*.agent.md")):
        fm = load_frontmatter(path)
        rp = rel(path)
        handoffs = fm.get("handoffs") or []
        handoff_agents: list[str] = []
        if isinstance(handoffs, list):
            for h in handoffs:
                if isinstance(h, dict) and h.get("agent"):
                    handoff_agents.append(str(h["agent"]))
        tools = fm.get("tools") or []
        if isinstance(tools, str):
            tools = [tools]
        records.append(
            {
                "id": f"agent:{rp}",
                "type": "agent",
                "path": rp,
                "name": name_from_filename(path, "agent"),
                "description": safe_str(fm.get("description", "")).strip(),
                "applyTo": None,
                "tags": build_tags(path, "agent"),
                "metadata": {
                    "argumentHint": fm.get("argument-hint") or None,
                    "tools": sorted({str(t) for t in tools}) if tools else [],
                    "handoffAgents": handoff_agents,
                },
            }
        )
    return records


def collect_skills() -> list[dict]:
    folder = ROOT / ".github/skills"
    records = []
    for path in sorted(folder.glob("*/SKILL.md")):
        fm = load_frontmatter(path)
        rp = rel(path)
        allowed = fm.get("allowed-tools") or []
        if isinstance(allowed, str):
            allowed = [allowed]
        records.append(
            {
                "id": f"skill:{rp}",
                "type": "skill",
                "path": rp,
                "name": fm.get("name") or path.parent.name,
                "description": safe_str(fm.get("description", "")).strip(),
                "applyTo": None,
                "tags": build_tags(path, "skill", extras=[path.parent.name]),
                "metadata": {
                    "version": safe_str(fm.get("version", "")) or None,
                    "license": safe_str(fm.get("license", "")) or None,
                    "allowedTools": [str(t) for t in allowed],
                    "argumentHint": fm.get("argument-hint") or None,
                },
            }
        )
    return records


def collect_hooks() -> list[dict]:
    candidates = [
        ROOT / "hooks.json",
        ROOT / ".github/hooks/quality-gates.json",
    ]
    records = []
    for path in candidates:
        if not path.exists():
            continue
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            print(f"warn: invalid JSON in {path}: {exc}", file=sys.stderr)
            continue
        hooks_obj = data.get("hooks") if isinstance(data, dict) else None
        events = sorted(hooks_obj.keys()) if isinstance(hooks_obj, dict) else []
        rp = rel(path)
        records.append(
            {
                "id": f"hook:{rp}",
                "type": "hook",
                "path": rp,
                "name": path.stem,
                "description": "",
                "applyTo": None,
                "tags": list(events),
                "metadata": {"events": events},
            }
        )
    records.sort(key=lambda r: r["path"])
    return records


def collect_all() -> list[dict]:
    all_records = (
        collect_instructions()
        + collect_prompts()
        + collect_agents()
        + collect_skills()
        + collect_hooks()
    )
    for rec in all_records:
        rec["pack"] = classify_pack(rec)
    type_index = {t: i for i, t in enumerate(TYPE_ORDER)}
    all_records.sort(key=lambda r: (type_index.get(r["type"], 999), r["path"]))
    return all_records


def derive_packs(artefacts: list[dict]) -> tuple[list[dict], list[dict]]:
    """Derive language-pack and foundation-pack views from collected artefacts.

    See docs/conventions.md for the convention. Returns (packs, foundation_packs)
    sorted by tech slug.
    """
    instructions_by_slug: dict[str, str] = {}
    prompts_by_slug: dict[str, str] = {}
    skills_by_name: dict[str, str] = {}
    for rec in artefacts:
        if rec["type"] == "instruction":
            instructions_by_slug[rec["name"]] = rec["path"]
        elif rec["type"] == "prompt" and rec["name"].startswith("enforce."):
            slug = rec["name"][len("enforce.") :]
            prompts_by_slug[slug] = rec["path"]
        elif rec["type"] == "skill":
            skills_by_name[rec["name"]] = rec["path"]

    packs: list[dict] = []
    foundation: list[dict] = []
    for slug in sorted(instructions_by_slug):
        instruction_path = instructions_by_slug[slug]
        if slug in FOUNDATION_PACKS:
            foundation.append({"tech": slug, "instruction": instruction_path})
            continue
        enforce_path = prompts_by_slug.get(slug)
        skill_paths = sorted(
            skills_by_name[name]
            for name in PACK_SKILLS.get(slug, [])
            if name in skills_by_name
        )
        packs.append(
            {
                "id": f"language-pack.{slug}",
                "class": PACK_CLASS.get(slug, "framework"),
                "tech": slug,
                "instruction": instruction_path,
                "enforcePrompt": enforce_path,
                "skills": skill_paths,
                "adrCluster": PACK_ADR.get(slug),
                "complete": bool(instruction_path) and bool(enforce_path),
            }
        )
    return packs, foundation


def source_revision() -> str | None:
    try:
        out = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
            timeout=5,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if out.returncode != 0:
        return None
    rev = out.stdout.strip()
    return rev or None


def esc(value) -> str:
    if value is None:
        return "—"
    s = str(value).strip()
    if not s:
        return "—"
    # Collapse whitespace + escape pipe and newline for table cells.
    s = " ".join(s.split())
    s = s.replace("|", "\\|")
    # Wrap bare URLs so markdownlint (MD034) does not flag them in tables.
    return re.sub(r"(?<!<)(?<!\]\()(https?://[^\s<>\)]+)", r"<\1>", s)


def code(value) -> str:
    if value is None or value == "":
        return "—"
    return f"`{value}`"


def render_markdown(model: dict) -> str:
    counts = model["counts"]
    artefacts_by_type: dict[str, list[dict]] = {t: [] for t in TYPE_ORDER}
    for rec in model["artefacts"]:
        artefacts_by_type.setdefault(rec["type"], []).append(rec)

    lines: list[str] = []
    lines.append("# Artefact Catalogue 📚")
    lines.append("")
    lines.append(
        "Auto-generated index of every Copilot customisation artefact in this repository."
    )
    lines.append("")
    lines.append("> **Do not edit by hand.** Regenerate with `make catalogue`.")
    lines.append("")
    by_pack = counts.get("byPack", {})
    lines.append(
        f"Pack breakdown: core={by_pack.get(CORE_PACK, 0)}, "
        f"speckit={by_pack.get(SPECKIT_PACK, 0)} "
        "(see [docs/conventions.md#plugin-packs](conventions.md#plugin-packs) "
        "for the boundary)."
    )
    lines.append("")

    lines.append("## Summary")
    lines.append("")
    lines.append("| Type | Count |")
    lines.append("| ---- | ----- |")
    for t in TYPE_ORDER:
        lines.append(f"| {t.capitalize()}s | {counts.get(t, 0)} |")
    lines.append(f"| **Total** | **{counts['total']}** |")
    lines.append("")

    type_renderers = {
        "instruction": ("Instructions", _render_instructions),
        "prompt": ("Prompts", _render_prompts),
        "agent": ("Agents", _render_agents),
        "skill": ("Skills", _render_skills),
        "hook": ("Hooks", _render_hooks),
    }
    for t in TYPE_ORDER:
        title, renderer = type_renderers[t]
        lines.append(f"## {title}")
        lines.append("")
        records = artefacts_by_type.get(t, [])
        if not records:
            lines.append("_None._")
            lines.append("")
            continue
        lines.extend(renderer(records))
        lines.append("")

    lines.extend(
        _render_packs(model.get("packs", []), model.get("foundationPacks", []))
    )

    lines.append("---")
    lines.append("")
    rev = model.get("sourceRevision") or "unknown"
    lines.append(f"_Generated at {model['generatedAt']} from revision `{rev}`._")
    lines.append("")
    return "\n".join(lines)


def _link(rec: dict) -> str:
    rel_from_docs = "../" + rec["path"]
    return f"[{rec['name']}]({rel_from_docs})"


def _render_instructions(records: list[dict]) -> list[str]:
    out = [
        "| Name | Path | applyTo | Description |",
        "| ---- | ---- | ------- | ----------- |",
    ]
    for r in records:
        out.append(
            f"| {esc(r['name'])} | {_link(r)} | {code(r.get('applyTo'))} | {esc(r['description'])} |"
        )
    return out


def _render_prompts(records: list[dict]) -> list[str]:
    out = [
        "| Name | Path | Agent | Pack | Tags | Description |",
        "| ---- | ---- | ----- | ---- | ---- | ----------- |",
    ]
    for r in records:
        meta = r.get("metadata", {})
        tags = ", ".join(r.get("tags", [])) or "—"
        out.append(
            f"| {esc(r['name'])} | {_link(r)} | {code(meta.get('agent'))} "
            f"| {esc(r.get('pack'))} | {esc(tags)} | {esc(r['description'])} |"
        )
    return out


def _render_agents(records: list[dict]) -> list[str]:
    out = [
        "| Name | Path | Pack | Handoffs | Tools | Description |",
        "| ---- | ---- | ---- | -------- | ----- | ----------- |",
    ]
    for r in records:
        meta = r.get("metadata", {})
        handoffs = ", ".join(meta.get("handoffAgents") or []) or "—"
        tools = ", ".join(meta.get("tools") or []) or "—"
        out.append(
            f"| {esc(r['name'])} | {_link(r)} | {esc(r.get('pack'))} "
            f"| {esc(handoffs)} | {esc(tools)} | {esc(r['description'])} |"
        )
    return out


def _render_skills(records: list[dict]) -> list[str]:
    out = [
        "| Name | Path | Version | Allowed tools | Description |",
        "| ---- | ---- | ------- | ------------- | ----------- |",
    ]
    for r in records:
        meta = r.get("metadata", {})
        allowed = ", ".join(meta.get("allowedTools") or []) or "—"
        out.append(
            f"| {esc(r['name'])} | {_link(r)} | {esc(meta.get('version'))} | {esc(allowed)} | {esc(r['description'])} |"
        )
    return out


def _render_hooks(records: list[dict]) -> list[str]:
    out = ["| Path | Events | Description |", "| ---- | ------ | ----------- |"]
    for r in records:
        meta = r.get("metadata", {})
        events = ", ".join(meta.get("events") or []) or "—"
        out.append(f"| {_link(r)} | {esc(events)} | {esc(r['description'])} |")
    return out


def _path_link(path: str | None) -> str:
    if not path:
        return "—"
    return f"[{path}](../{path})"


def _render_packs(packs: list[dict], foundation: list[dict]) -> list[str]:
    out: list[str] = []
    out.append("## Language packs")
    out.append("")
    out.append(
        "Composable units keyed by tech slug — see [conventions.md](conventions.md#language-packs)."
    )
    out.append("")
    if not packs:
        out.append("_None._")
        out.append("")
    else:
        out.append(
            "| Pack ID | Class | Instruction | Enforce prompt | Skills | ADR cluster | Complete |"
        )
        out.append(
            "| ------- | ----- | ----------- | -------------- | ------ | ----------- | -------- |"
        )
        for p in packs:
            skills = ", ".join(_path_link(s) for s in p.get("skills") or []) or "—"
            adr = p.get("adrCluster") or "—"
            complete = "✓" if p.get("complete") else "✗"
            out.append(
                f"| `{p['id']}` | {p['class']} | {_path_link(p.get('instruction'))} "
                f"| {_path_link(p.get('enforcePrompt'))} | {skills} | {esc(adr)} | {complete} |"
            )
        out.append("")

    out.append("## Foundation packs")
    out.append("")
    out.append(
        "Instruction-only artefacts without an enforce prompt — see [conventions.md](conventions.md#foundation-packs-orphan-policy)."
    )
    out.append("")
    if not foundation:
        out.append("_None._")
        out.append("")
    else:
        out.append("| Tech | Instruction |")
        out.append("| ---- | ----------- |")
        for f in foundation:
            out.append(f"| `{f['tech']}` | {_path_link(f.get('instruction'))} |")
        out.append("")
    return out


def main() -> int:
    artefacts = collect_all()
    counts = {t: 0 for t in TYPE_ORDER}
    for rec in artefacts:
        counts[rec["type"]] = counts.get(rec["type"], 0) + 1
    counts["total"] = len(artefacts)
    packs, foundation_packs = derive_packs(artefacts)
    counts["packs"] = len(packs)
    by_pack = {CORE_PACK: 0, SPECKIT_PACK: 0}
    for rec in artefacts:
        by_pack[rec["pack"]] = by_pack.get(rec["pack"], 0) + 1
    counts["byPack"] = by_pack

    generated_at = (
        _dt.datetime.now(tz=_dt.timezone.utc)
        .replace(microsecond=0)
        .isoformat()
        .replace("+00:00", "Z")
    )

    model = {
        "generatedAt": generated_at,
        "sourceRevision": source_revision(),
        "counts": counts,
        "artefacts": artefacts,
        "packs": packs,
        "foundationPacks": foundation_packs,
    }

    json_path = ROOT / "catalogue.json"
    md_path = ROOT / "docs/catalogue.md"

    json_path.write_text(
        json.dumps(model, indent=2, sort_keys=False, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    md_path.parent.mkdir(parents=True, exist_ok=True)
    md_path.write_text(render_markdown(model), encoding="utf-8")

    summary = ", ".join(f"{t}={counts.get(t, 0)}" for t in TYPE_ORDER)
    print(
        f"catalogue: {summary}, total={counts['total']}, "
        f"packs={counts['packs']}, foundationPacks={len(foundation_packs)}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
