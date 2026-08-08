# Project Constitution

## 1. Purpose

This constitution defines the **non-negotiable engineering guardrails** for this project.

It applies to:

- Specifications and documentation
- Design and architecture
- Implementation and refactoring
- Reviews and operational changes
- All contributors, including AI-assisted development tools

It exists to ensure:

- Long-term maintainability
- Deterministic and testable behaviour
- High-signal specifications suitable for automation
- Safe, controlled evolution of the system
- Fast, safe delivery in small increments ("flow")

---

## 2. Constitutional Status

### 2.1 Authority and Scope

- This document has higher authority than:
  - Feature specifications
  - User stories
  - Plans, tasks, and checklists
  - Implementation details
- Any artefact that conflicts with this constitution is invalid.
- Changes to this constitution must be explicit and deliberate and are treated as governance changes (see §11.4).

---

## 3. Core Principles (Non-Negotiable)

### 3.1 Specification-First, Testable Behaviour

- All behaviour **must** be defined in a specification before implementation.
- Code is an implementation of specifications, never the primary source of truth.
- If behaviour is not specified, it does not exist.
- Specifications describe observable behaviour (what the system does), not implementation steps (how it does it). Implementation choices belong in plans, not specifications.
- Behaviour must be deterministic and testable, with clear acceptance criteria.
- A specification is not ready for implementation until it defines: observable behaviour, acceptance criteria, boundary conditions, and error or edge cases. Underspecified areas must be marked explicitly.
- A unit of work is only "done" when it is specified, deterministic, testable, and understandable by a new engineer.
- Existing specified behaviour is preserved unless the specification explicitly changes it with rationale and impact assessment.
- Specifications must be retained after implementation and used as the authoritative basis for future evolution, maintenance, and refactoring.
- The specification library is cumulative: every feature specification under `/specs/*` forms part of the single source of truth, so later work must remain compatible with earlier features unless the specification set itself is deliberately revised.
- Documentation and tooling outside `/specs` (for example prompts, READMEs, ADRs, plans, and checklists) must always reference and reflect the complete specification set, not just the latest feature.

**Divergence rule (must choose explicitly):**

If code and specification diverge, you must explicitly choose one path and document it:

- **Option A - Fix implementation:** bring code/tests back into alignment with the specification.
- **Option B - Approve a behavioural change:** amend the specification (with rationale and impact), then update code/tests to match.

Updating the specification solely to legitimise accidental behaviour is prohibited.

---

### 3.2 Determinism, Explicitness, and No Hidden State

- Given identical inputs and environment, the system must produce identical outputs.
- Non-deterministic behaviour is forbidden unless explicitly specified and normalised.
- Ordering, timestamps, hashes, and outputs must be deterministic or explicitly normalised.
- All behaviour, errors, fallbacks, and edge cases must be explicit, documented, and intentional.
- Hidden or implicit state (including global mutable state) is prohibited unless explicitly specified and justified.
- Side effects must be explicit and documented.

---

### 3.3 Human-First, Clean Code

- Code and outputs are written for human readers first while remaining fully machine-processable.
- Readability and clarity take precedence over cleverness, premature optimisation, or convenience.
- Naming, structure, and abstractions must be intention-revealing and aligned with the domain language.
- Clean Code principles apply continuously: small focused functions, honest abstractions, clear error handling, and active removal of code smells.

---

### 3.4 Safe Architecture and Dependencies

- Responsibilities must be clearly separated with single-purpose components.
- Components interact only through well-defined, stable contracts.
- Architecture must support replaceability: components can be swapped without rewriting the system.
- No external library may define the core behaviour of the system.
- Performance, scalability, and cross-platform consistency are explicit requirements, not afterthoughts.

---

### 3.5 AI-Assisted Development Discipline

During specification, planning, and implementation, AI must work within the specification boundary. Scope decisions belong to the specification stage, not the implementation stage.

- Every behavioural change must be intentional, documented, and reviewable, with backwards-incompatible changes called out explicitly.
- When trade-offs exist between speed and correctness, convenience and clarity, or cleverness and simplicity, this constitution is final authority.
- See [.github/copilot-instructions.md](../../.github/copilot-instructions.md) for the operational implementation-discipline rules used in this repository's Copilot workflows.

---

### 3.6 Design for Testability (TDD)

For any change that introduces or modifies behaviour, work must follow a test-first approach aligned to the specification:

- Write (or update) a unit test **from the specification** first.
- The test must **fail for the right reason** before implementation changes are made.
- Implement the minimal change to make the test pass.
- Refactor only after tests pass, preserving behaviour.

Tasks and plans must be structured to reflect this flow: test → implement → refactor (🔴 RED → 🟢 GREEN → 🔵 REFACTOR). If they are not, they must be reworded to follow the TDD approach before implementation. Tests must not introduce behaviour that is not specified.

---

### 3.7 Required Test Types

All production systems must include the following test types:

- **Unit tests**: Verify individual functions, methods, and classes in isolation. Must cover core logic, edge cases, and error paths.
- **Integration tests**: Verify that components work correctly together, including interactions with databases, file systems, message queues, and external services (using test doubles where appropriate).
- **Contract tests**: Verify that service boundaries (APIs, events, messages) conform to their documented contracts. Both provider and consumer perspectives must be covered where applicable.

Additional test types (end-to-end, performance, security) are encouraged where risk or complexity warrants them but are not mandated by this constitution.

Test coverage must be meaningful, not just numerical. Focus on behaviour, boundaries, and failure modes rather than chasing coverage percentages.

---

### 3.8 Engineer for Flow, Led by User Needs

Deliver high-quality software rapidly and safely, with strong automation and continuous improvement.

Non-negotiables:

- Engineering decisions must be led by **user needs and service outcomes**, not internal convenience.
- Delivery must be **iterative and incremental** ("small batches"), optimising for fast learning and low risk.
- Delivery teams must be **empowered and accountable** for what they build and run.
- Products must be **actively maintained for their whole lifecycle**, not treated as "done after release".
- Operational reliability is part of engineering ("everything fails"): operate, measure, improve.
- Prioritisation must be based on **data and evidence**, not sentiment.

---

### 3.9 Architect for Flow

Design architecture to enable fast, safe flow of change. The goal is not theoretical purity or maximum reuse. The goal is that teams can deliver small, incremental changes frequently with confidence.

- Prefer designs that minimise cross-team coordination and hand-offs.
- Align domain boundaries, team ownership, and interfaces deliberately.
- Optimise for independent change and independent deployment where practical.
- Accept duplication where it reduces coupling and improves flow.
- Avoid over-fragmentation: a well-structured modular monolith is valid when it improves cognitive load and operability.

---

## 4. Architecture Guardrails

### 4.1 Separation of Concerns

- Components at all levels must have a single, clear responsibility.
- Discovery, classification, validation, metadata extraction, and output must not be conflated.
- Cross-cutting concerns (for example logging and error handling) must be isolated.

### 4.2 Loose Coupling, Strong Contracts

- Components must interact only through well-defined contracts.
- Internal representations must not leak across boundaries.
- Changes in one component must not require implicit changes elsewhere.

### 4.3 Replaceability

- Any component must be replaceable without rewriting the system.
- External libraries must not become architectural dependencies that "define the system".
- Replaceability must be preserved as the system evolves.

### 4.4 Bounded Contexts and Domain Alignment

- Split systems vertically by bounded context / domain, not purely by technical layers.
- Avoid shared databases across bounded contexts; data ownership must be explicit.
- Integration seams must be explicit, versioned, and testable.

### 4.5 API-first and Consumer Parity

- Where interfaces are exposed (internal or external), adopt API-first thinking.
- Treat internal and external consumers equally: no "special hidden" internal-only behaviour.

### 4.6 Architecture Decision Records

- Significant architectural decisions must be recorded with rationale and alternatives considered.
- See [.github/copilot-instructions.md](../../.github/copilot-instructions.md) for the operational ADR process and template requirements used in this repository's Copilot workflows.

---

## 5. Error Handling and Failure Semantics

### 5.1 Fail Explicitly, Not Silently

- Errors must be captured, classified, and surfaced.
- Silent failure is forbidden.
- Silent coercion or silent misclassification is forbidden.
- Partial success must be reported as partial success.

### 5.2 Failure Isolation

- Failure of one unit of work must not cascade.
- The system must continue operating wherever safely possible.
- Error handling must be local and deterministic.

### 5.3 Confidence and Uncertainty

- When confidence is insufficient to make a safe determination, the system must say so explicitly.
- Any fallback behaviour must be specified and testable.

---

## 6. Data and Output Principles

### 6.1 Deterministic Data Models

- Data structures must have stable, documented schemas.
- Field presence, naming, types, and optionality must be explicit and consistent.

### 6.2 Human-First, Machine-Compatible Outputs

- Outputs must be readable by humans and suitable for automation.
- Output formats must be stable and deterministic.
- Any output ordering rules must be specified (for example stable sorting).

---

## 7. Code Quality Guardrails

### 7.1 Readability and Intent

- Code must make intent obvious at every level.
- Where a trade-off exists, prefer human readability.
- Abstractions must be honest and not hide complexity.

### 7.2 Naming

- Names must be intention-revealing.
- Avoid ambiguity, unnecessary abbreviations, and mental mapping.
- Naming must match the ubiquitous language.

### 7.3 Static Typing Requirements

- All code must use the language's typing facilities consistently. Public APIs, function parameters, return values, and data models must have explicit types.
- Avoid `any`-style escape hatches or implicit dynamic typing except where explicitly justified and documented.
- Any exception must be explicitly documented with rationale, limited in scope, and removed as soon as practicable (see §11.4).
- Language-specific typing details belong in the relevant technology instruction file, not this constitution.

### 7.4 Functions and Methods

- Functions must be small and focused on a single responsibility.
- Functions must operate at a single level of abstraction where practical.
- Happy-path logic must be separated from error handling where practical.

### 7.5 Comments (Intent-Focused)

- Comments must explain intent and reasoning, not mechanics.
- Comments must explain why something exists, not what the code already states.
- Comments are required where they add clarity, including:
  - File/module purpose and responsibility
  - Public API/class invariants and collaboration
  - Non-obvious trade-offs, edge cases, and reasoning
- Comments that merely restate code are prohibited.

### 7.6 Code Smells

- Code smells must be actively identified and removed.

### 7.7 Incremental Improvement

- Refactoring must focus on readability and maintainability.
- Small, incremental improvements are preferred over large rewrites.
- Improvements must not widen scope or introduce new behaviour.

### 7.8 Mandatory Local Quality Gates

- Quality must be protected by **robust and comprehensive automation** (tests, checks, policies), not by hope or manual vigilance.
- Where CI exists, CI quality gates are authoritative for merge readiness; local gates must mirror them as closely as practical.

---

## 8. Performance and Scalability Principles

### 8.1 Bounded Resource Usage

- The system must not assume unlimited memory or compute.
- Processing must be incremental or streaming where applicable.
- Resource usage must scale predictably with input size.

### 8.2 Performance Is a Requirement (and Must Be Testable)

- Performance characteristics must be specifiable and testable where relevant.
- Performance optimisations must not change observable behaviour.
- Premature optimisation is prohibited.
- Unbounded inefficiency is also prohibited.

### 8.3 Flow-aware Trade-Offs

- Flow must not compromise quality: automation, operability, and safety are mandatory.
- "More services" is not automatically "better": avoid needless distribution that increases cognitive load and operational risk.

---

## 9. Cross-Platform and Environmental Consistency

- Behaviour must be consistent across operating systems and file systems as far as reasonably possible.
- Platform-specific behaviour must be explicitly documented.
- Environment-dependent behaviour must not be implicit.

---

## 10. Dependency and Tooling Policy

### 10.1 Dependency Discipline

- Dependencies must be justified by capability, not convenience.
- No dependency may define core behaviour of the system.
- Dependencies must be replaceable without changing specifications.

### 10.2 Tooling Is Non-Authoritative

- Tools, frameworks, and libraries are implementation details.
- Specifications must not depend on a specific toolchain.
- AI-assisted tools must follow the specification and this constitution, never infer beyond them.

---

## 11. Change Management

### 11.1 Explicit Change

- All behavioural changes must be reflected in the specification.
- Changes must be intentional, documented, and reviewable.
- Backwards-incompatible changes must be explicit.

### 11.2 No Accidental Complexity

- Complexity must be justified by requirements.
- Accidental complexity is a defect.
- If something cannot be explained clearly, it is not ready to exist.

### 11.3 Single Source of Truth per Concern

- Each rule, constraint, or fact has exactly one canonical location.
- Other documents reference it rather than restating it.
- When duplication is discovered, consolidate to one location and add a link from the other.

### 11.4 Exceptions (Escape Hatch)

Deviations from this constitution are permitted only when they are:

- Explicitly documented
- Justified
- Time-bounded
- Reviewed regularly, with a clear owner and an explicit expiry date
- Removed as soon as practicable

Any exception must be treated as a governance decision and recorded in the repository.
