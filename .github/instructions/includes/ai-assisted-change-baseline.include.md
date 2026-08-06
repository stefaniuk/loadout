# AI-assisted Change Baseline 🤖

Use this shared baseline for AI-assisted changes across instruction sets. Individual files should reference this and add any domain-specific steps.

**Identifier scheme.** Every normative rule carries a unique tag in the form `[AI-BASE-<prefix>-NNN]`, where the prefix maps to the containing section (for example `SCP` for Scope, `QLT` for Quality, `GOV` for Governance). Use these identifiers when referencing, planning, or validating requirements.

---

## 1. Scope and intent 🎯

- [AI-BASE-SCP-001] Do not invent requirements or expand scope beyond what is specified.
- [AI-BASE-SCP-002] Keep changes minimal and aligned with existing conventions and architecture.

## 2. Quality and governance 🛡️

- [AI-BASE-QLT-001] Ensure behaviour matches the specification and is deterministic and testable.
- [AI-BASE-QLT-002] Run the required quality gates for the domain and iterate until clean.
- [AI-BASE-GOV-001] If deviation is required, propose an ADR/decision record with rationale and expiry.
