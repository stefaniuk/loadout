#!/usr/bin/env python3
"""Generate README.md index files for prompts/agents/instructions/skills."""

from __future__ import annotations

import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    import subprocess

    subprocess.check_call([sys.executable, "-m", "pip", "install", "--quiet", "pyyaml"])
    import yaml

ROOT = Path(__file__).resolve().parents[2]


def load_frontmatter(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        return {}
    end = text.find("\n---", 3)
    if end == -1:
        return {}
    fm = text[3:end].strip()
    try:
        return yaml.safe_load(fm) or {}
    except yaml.YAMLError as e:
        print(f"YAML error in {path}: {e}", file=sys.stderr)
        return {}


def short_desc(desc: str, limit: int = 140) -> str:
    if not desc:
        return ""
    d = " ".join(str(desc).split())
    # First sentence
    m = re.match(r"^(.+?[.!?])(\s|$)", d)
    first = m.group(1) if m else d
    if len(first) > limit:
        first = first[:limit].rstrip()
    # Strip trailing punctuation
    return first.rstrip(".!?,;:")


def esc(s: str) -> str:
    text = (s or "").replace("|", "\\|")
    # Wrap bare URLs so markdownlint (MD034) does not flag them in tables.
    return re.sub(r"(?<![<])(https?://[^\s<>\)]+)", r"<\1>", text)


def gen_prompts():
    folder = ROOT / ".github/prompts"
    files = sorted(folder.glob("*.prompt.md"))
    groups: dict[str, list[tuple[str, str]]] = {}
    known = ["speckit", "architecture", "dev", "enforce", "review", "util"]
    for f in files:
        fm = load_frontmatter(f)
        desc = short_desc(fm.get("description", ""))
        prefix = f.name.split(".", 1)[0]
        key = prefix if prefix in known else "other"
        groups.setdefault(key, []).append((f.name, desc))

    out = []
    out.append("# Prompts 💬\n")
    out.append(
        "Auto-generated index of prompt files in this directory. Each prompt is invokable as a slash command (e.g. `/speckit.plan`). See [VS Code prompt files docs](https://code.visualstudio.com/docs/copilot/customization/prompt-files).\n"
    )
    out.append(
        "> **Do not edit by hand.** Regenerate with `make catalogue` (see [scripts/quality/](../../scripts/quality/)).\n"
    )
    out.append("## Naming convention\n")
    out.append("Prompts use the **prefix + category + verb** convention:\n")
    out.append("| Prefix          | Purpose                                         |")
    out.append("| --------------- | ----------------------------------------------- |")
    out.append("| `speckit.`      | Spec-kit lifecycle steps                        |")
    out.append("| `architecture.` | Evidence-first architecture documentation flows |")
    out.append("| `dev.`          | Development workflow helpers                    |")
    out.append("| `enforce.`      | Instruction compliance enforcement              |")
    out.append("| `review.`       | Review and audit prompts                        |")
    out.append("| `util.`         | Operational utilities                           |")
    out.append("")
    out.append("## Catalogue\n")
    out.append("Grouped by prefix, alphabetical within each group.\n")

    count = 0
    for key in known + ["other"]:
        if key not in groups:
            continue
        out.append(f"### `{key}.`\n")
        out.append("| File | Description |")
        out.append("| ---- | ----------- |")
        for name, desc in groups[key]:
            out.append(f"| [{name}]({name}) | {esc(desc)} |")
            count += 1
        out.append("")
    (folder / "README.md").write_text("\n".join(out).rstrip() + "\n", encoding="utf-8")
    return count


def gen_agents():
    folder = ROOT / ".github/agents"
    files = sorted(folder.rglob("*.agent.md"))
    out = []
    out.append("# Agents 🤖\n")
    out.append(
        "Auto-generated index of custom agents in this directory. Each `.agent.md` defines a persistent persona with optional `tools`, `model`, and `handoffs`. See [VS Code custom agents docs](https://code.visualstudio.com/docs/copilot/customization/custom-agents).\n"
    )
    out.append(
        "> **Note:** `.chatmode.md` is the legacy extension; this repository uses `.agent.md` per the VS Code April 2026 release."
    )
    out.append("> **Do not edit by hand.** Regenerate with `make catalogue`.\n")
    out.append("## Catalogue\n")

    # Group by subdirectory (top-level first, then nested folders alphabetically).
    groups: dict[str, list[Path]] = {}
    for f in files:
        rel_parent = f.parent.relative_to(folder).as_posix()
        key = "" if rel_parent == "." else rel_parent
        groups.setdefault(key, []).append(f)

    def render_table(entries: list[Path]) -> None:
        out.append("| File | Description | Handoffs |")
        out.append("| ---- | ----------- | -------- |")
        for f in entries:
            fm = load_frontmatter(f)
            desc = short_desc(fm.get("description", ""))
            handoffs = fm.get("handoffs") or []
            agents = []
            if isinstance(handoffs, list):
                for h in handoffs:
                    if isinstance(h, dict) and h.get("agent"):
                        agents.append(str(h["agent"]))
            handoff_str = ", ".join(agents) if agents else "—"
            rel_path = f.relative_to(folder).as_posix()
            out.append(
                f"| [{rel_path}]({rel_path}) | {esc(desc)} | {esc(handoff_str)} |"
            )
        out.append("")

    count = 0
    has_nested = any(groups)
    if has_nested:
        if "" in groups:
            out.append("### Top-level\n")
            render_table(groups[""])
            count += len(groups[""])
        for key in sorted(k for k in groups if k):
            out.append(f"### `{key}/`\n")
            render_table(groups[key])
            count += len(groups[key])
    else:
        render_table(groups.get("", []))
        count += len(groups.get("", []))

    out.append(
        "`Handoffs` column lists the `agent:` field of each entry in the file's `handoffs:` block, comma-separated. Show `—` if no handoffs declared."
    )
    (folder / "README.md").write_text("\n".join(out).rstrip() + "\n", encoding="utf-8")
    return count


def gen_instructions():
    folder = ROOT / ".github/instructions"
    files = sorted(folder.glob("*.instructions.md"))
    # Skip includes/ templates/ (glob is non-recursive so already skipped, but be safe)
    files = [
        f for f in files if "includes" not in f.parts and "templates" not in f.parts
    ]
    out = []
    out.append("# Instructions 📋\n")
    out.append(
        "Auto-generated index of instruction packs. Each `*.instructions.md` carries an `applyTo` glob so Copilot scopes the rules to matching files automatically. See [VS Code custom instructions docs](https://code.visualstudio.com/docs/copilot/customization/custom-instructions).\n"
    )
    out.append("> **Do not edit by hand.** Regenerate with `make catalogue`.\n")
    out.append(
        "For the language-pack convention that pairs each tech instruction with an enforce prompt, see [docs/conventions.md](../../docs/conventions.md#language-packs).\n"
    )
    out.append("## Catalogue\n")
    out.append("| File | `applyTo` | Description |")
    out.append("| ---- | --------- | ----------- |")
    count = 0
    for f in files:
        fm = load_frontmatter(f)
        desc = short_desc(fm.get("description", ""))
        apply_to = fm.get("applyTo", "")
        apply_str = f"`{apply_to}`" if apply_to else "—"
        out.append(f"| [{f.name}]({f.name}) | {esc(apply_str)} | {esc(desc)} |")
        count += 1
    out.append("")
    out.append("## Subdirectories\n")
    out.append(
        "- [`includes/`](includes/) — shared instruction fragments referenced via markdown file links."
    )
    out.append(
        "- [`templates/`](templates/) — instruction-pack templates used when scaffolding new languages."
    )
    (folder / "README.md").write_text("\n".join(out).rstrip() + "\n", encoding="utf-8")
    return count


def gen_skills():
    folder = ROOT / ".github/skills"
    files = sorted(folder.glob("*/SKILL.md"))
    out = []
    out.append("# Skills 🧠\n")
    out.append(
        "Auto-generated index of agent skills. Each skill is a folder containing `SKILL.md` plus optional `assets/` and `examples/`. See [VS Code agent skills docs](https://code.visualstudio.com/docs/copilot/customization/agent-skills).\n"
    )
    out.append("> **Do not edit by hand.** Regenerate with `make catalogue`.\n")
    out.append("## Catalogue\n")
    out.append("| Skill | Version | Description | Argument hint |")
    out.append("| ----- | ------- | ----------- | ------------- |")
    count = 0
    for f in files:
        fm = load_frontmatter(f)
        name = fm.get("name") or f.parent.name
        version = str(fm.get("version", "—"))
        desc = short_desc(fm.get("description", ""))
        hint = fm.get("argument-hint", "") or "—"
        rel = f"{f.parent.name}/SKILL.md"
        out.append(
            f"| [{name}]({rel}) | {esc(version)} | {esc(desc)} | {esc(str(hint))} |"
        )
        count += 1
    out.append("")
    (folder / "README.md").write_text("\n".join(out).rstrip() + "\n", encoding="utf-8")
    return count


def main():
    counts = {
        "prompts": gen_prompts(),
        "agents": gen_agents(),
        "instructions": gen_instructions(),
        "skills": gen_skills(),
    }
    for k, v in counts.items():
        print(f"{k}: {v} entries")


if __name__ == "__main__":
    main()
