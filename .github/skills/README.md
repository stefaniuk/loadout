# Skills 🧠

Auto-generated index of agent skills. Each skill is a folder containing `SKILL.md` plus optional `assets/` and `examples/`. See [VS Code agent skills docs](https://code.visualstudio.com/docs/copilot/customization/agent-skills).

> **Do not edit by hand.** Regenerate with `make catalogue`.

## Catalogue

| Skill | Version | Description | Argument hint |
| ----- | ------- | ----------- | ------------- |
| [architecture-docs](architecture-docs/SKILL.md) | 1.0.0 | Generate architecture documentation for a repository, producing structured artefacts from repository maps to C4 models and infrastructure di | Specify step: repository-map, component-catalogue, runtime-flows, domain-analysis, c4-model, infrastructure-diagram, or all |
| [code-review](code-review/SKILL.md) | 1.0.0 | Run a structured Spec Kit review focused on code compliance, documentation quality, or test coverage, positioned within the spec-driven deve | Specify review type: code, documentation, or test |
| [django-project](django-project/SKILL.md) | 1.0.0 | Scaffold and evolve Django projects with uv-based tooling, structured settings, and production-ready observability, resilience, availability | Describe the Django project action: scaffold, add capability, or evolve an existing project |
| [enforcement-audit](enforcement-audit/SKILL.md) | 1.0.0 | Run a compliance audit against a technology instruction file, detecting discrepancies, planning workstreams, implementing fixes, and validat | Specify the technology to audit: python, typescript, go, docker, rust, shell, makefile, terraform, reactjs, tauri, playwright-python, or playwright-typescript |
| [fastapi-project](fastapi-project/SKILL.md) | 1.0.0 | Scaffold and evolve FastAPI projects with uv-based tooling, structured settings, and production-ready observability, resilience, availabilit | Describe the FastAPI project action: scaffold, add capability, or evolve an existing project |
| [repository-template](repository-template/SKILL.md) | 1.0.0 | Create code repository from template, or/and update it in parts from the content of the template that contains example of use of tools like | Name the capability to add, remove, or improve from the repository template |
| [spec-consolidation](spec-consolidation/SKILL.md) | 1.2.0 | Consolidate per-feature Spec Kit artefacts under specs/ into a product-facing specification set aligned to a selected baseline, excluding pl | Specify step: spec, data-model, research, quickstart, contracts, checklists, or all. Optional baseline: working-tree, HEAD, or default-branch |
| [system-documentation](system-documentation/SKILL.md) | 1.2.0 | Establish, synchronise, audit, and review an opinionated repository documentation system across entrypoints, architecture, reference, explan | Optional: step (foundation, architecture, reference, explanation, how-to, tutorials, operations, audience-indexes, governance, all), mode (establish, sync, audit, pre-pr-review), and scope (path, feature dir, or changed files) |
