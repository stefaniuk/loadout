# Skill-Local Agent Instructions: Virtual Think Tank

> **Scope.** This file applies only to the `virtual-think-tank` skill subtree. The canonical baseline is the [root AGENTS.md](../../../AGENTS.md); nothing here may contradict it.

## Inheritance and precedence

- Inherit all rules from [root AGENTS.md](../../../AGENTS.md) and [.github/copilot-instructions.md](../../copilot-instructions.md).
- When a conflict exists within this skill's subtree, the closest file applies; otherwise root rules win.
- For the full task workflow, read [SKILL.md](SKILL.md). This file captures only behavioural constraints, not the workflow itself.

## Skill-local rules

- **Single input contract.** Keep the structured input contract aligned across [SKILL.md](./SKILL.md), [assets/briefing-template.md](./assets/briefing-template.md), and the example briefs under [examples/](./examples/). If one adds, removes, or renames a field, update the others in the same change.
- **Examples are illustrative, not normative.** Example files demonstrate how to use the skill. They must not quietly extend, narrow, or override the behaviour defined in [SKILL.md](./SKILL.md).
- **Overview stays an index.** [examples/example-01-examples-overview.md](./examples/example-01-examples-overview.md) is a landing page only. Keep detailed walkthrough content in the scenario-specific example files.
- **Stable example ordering.** User-facing example labels and filenames under [examples/](./examples/) must follow the same ordering convention: topic → voices → mode → tool.
- **Standalone wording only.** Files in this subtree should read as complete artefacts in their own right. Avoid provenance, migration, or historical framing unless the user explicitly asks for it.
- **Named panels require real disagreement.** When examples or templates use `named_*` fields, the named voices should represent materially different viewpoints, not just famous people from the same school of thought.

## Deviations from root AGENTS.md

None.

## References

- [SKILL.md](./SKILL.md) - the skill workflow and runtime behaviour.
- [assets/briefing-template.md](./assets/briefing-template.md) - the structured input contract.
- [examples/](./examples/) - usage examples and overview index.
- [root AGENTS.md](../../../AGENTS.md) - canonical baseline.
