# Coding-Agent Skills: Ranked List

**Research date:** 8 August 2026
**Scope:** day-to-day software engineering for CLI tools, websites and systems, plus secure development, static analysis, dynamic analysis and authorised penetration-testing workflows.

## How this list is ranked

Each item is assessed against five criteria:

1. **Practical engineering value** — how often it can improve real CLI, web or systems work.
2. **Technical specificity** — concrete workflow, tools, checks, outputs and stopping conditions rather than generic advice.
3. **Source credibility** — preference for skills maintained by established engineering/security organisations or projects, or repositories with substantial and active community adoption.
4. **Evidence of engineering use** — production use, evaluations/tests, maintained releases, community adoption, or a workflow grounded in established engineering/security tools and standards.
5. **Safety and reproducibility** — especially for security workflows: explicit scope/authorisation, evidence capture, false-positive validation, deterministic artefacts and review gates.

For an enterprise setup, vendor or pin reviewed versions of skills rather than automatically following `main`. Skills are executable instructions for an agent and should be treated as code/configuration in your software supply chain.

---

## 1. systematic-debugging

- **What it does:** Enforces a structured debugging process: reproduce the problem, gather evidence, isolate the failure, form and test hypotheses, identify the root cause, then implement and verify the fix. 4-phase root cause process with defence-in-depth and condition-based-waiting techniques.
- **Why useful:** Prevents speculative edits and "try random changes until tests pass". Structured diagnosis is essential for CLI tools and systems where bugs are non-obvious.
- **Link:** <https://github.com/obra/superpowers/blob/main/skills/systematic-debugging/SKILL.md>

## 2. test-driven-development (Superpowers)

- **What it does:** Drives implementation using a red-green-refactor cycle, requiring the agent to create a failing test before implementing behaviour and to keep the test suite green while refactoring.
- **Why useful:** Converts agent output from plausible-looking code into code backed by executable evidence. Useful for CLI commands, APIs, libraries and web application behaviour alike.
- **Link:** <https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md>

## 3. verification-before-completion

- **What it does:** Requires fresh verification evidence before an agent claims work is complete, fixed, passing or ready to merge.
- **Why useful:** Coding agents are prone to reporting success based on reasoning rather than execution. This skill makes completion evidence-based by requiring actual tests, builds, linters or other relevant checks.
- **Link:** <https://github.com/obra/superpowers/blob/main/skills/verification-before-completion/SKILL.md>

## 4. Spec Kit workflow

- **What it does:** GitHub's structured workflow turns an idea into principles, specification, clarification, implementation plan, tasks and implementation using coding-agent commands/skills.
- **Why useful:** Particularly valuable for medium-sized changes where an agent needs durable requirements and architecture decisions rather than a long conversational prompt. Reduces requirement drift and makes generated work easier to review.
- **Link:** <https://github.com/github/spec-kit>

## 5. writing-plans

- **What it does:** Converts an agreed design into a detailed implementation plan with small steps (2-5 minutes each), precise file targets, commands and verification activities.
- **Why useful:** A good implementation plan materially improves agent reliability on multi-file changes and makes it easier to review the intended change before allowing the agent to execute it.
- **Link:** <https://github.com/obra/superpowers/blob/main/skills/writing-plans/SKILL.md>

## 6. using-git-worktrees

- **What it does:** Creates isolated Git worktrees for feature work so an agent can work on separate branches without disturbing the current working tree.
- **Why useful:** Isolation is especially useful for autonomous coding agents, parallel experiments and security analysis. Makes destructive mistakes easier to contain.
- **Link:** <https://github.com/obra/superpowers/blob/main/skills/using-git-worktrees/SKILL.md>

## 7. security-and-hardening

- **What it does:** OWASP Top 10 prevention, auth patterns, secrets management, dependency auditing, three-tier boundary system (public, internal, sensitive).
- **Why useful:** Applies to every web app, API, and CLI tool handling user input. Prevents agents from writing insecure code by default. Activates automatically during implementation.
- **Link:** <https://github.com/addyosmani/agent-skills/tree/main/skills/security-and-hardening>

## 8. grill-with-docs

- **What it does:** Grilling session that extracts what you actually want, builds a shared domain model, sharpens terminology, and updates CONTEXT.md and ADRs inline.
- **Why useful:** Prevents the most common failure: building the wrong thing. Forces alignment before code starts flowing. Reduces verbosity by establishing a ubiquitous language.
- **Link:** <https://github.com/mattpocock/skills/tree/main/skills/engineering/grill-with-docs>

## 9. test-driven-development (Addy Osmani)

- **What it does:** Enforces RED-GREEN-REFACTOR cycle with test pyramid (80/15/5 unit/integration/e2e), test sizes, DAMP over DRY patterns, and the Beyonce Rule. Ecosystem-neutral.
- **Why useful:** Complements the Superpowers TDD skill with Google engineering-derived practices. Includes anti-rationalisation tables and browser testing guidance.
- **Link:** <https://github.com/addyosmani/agent-skills/tree/main/skills/test-driven-development>

## 10. incremental-implementation

- **What it does:** Thin vertical slices: implement, test, verify, commit. Feature flags, safe defaults, rollback-friendly changes for any change touching more than one file.
- **Why useful:** Prevents sprawling changes that break everything. Each commit is deployable and verifiable. Essential discipline for multi-file CLI tools and systems.
- **Link:** <https://github.com/addyosmani/agent-skills/tree/main/skills/incremental-implementation>

## 11. CodeQL static analysis

- **What it does:** Guides an agent through CodeQL database creation, query execution, data-flow/taint analysis, security query use and results analysis.
- **Why useful:** Excellent for deeper SAST and variant analysis where simple pattern matching is insufficient. Traces untrusted data through systems and proves exploit paths across functions and modules.
- **Link:** <https://github.com/trailofbits/skills/blob/main/plugins/static-analysis/skills/codeql/SKILL.md>

## 12. Semgrep static analysis

- **What it does:** Guides Semgrep-based static analysis, including ruleset selection, scanning, result interpretation and security-focused pattern analysis.
- **Why useful:** Fast enough for everyday use and CI while remaining expressive enough for organisation-specific insecure patterns. Complements CodeQL: Semgrep for rapid pattern checks, CodeQL for deeper semantic/data-flow analysis.
- **Link:** <https://github.com/trailofbits/skills/blob/main/plugins/static-analysis/skills/semgrep/SKILL.md>

## 13. differential-review

- **What it does:** Performs a security-focused review of a code change using the diff, Git history, blast-radius analysis and test coverage, then produces a structured report.
- **Why useful:** Most day-to-day security review should focus on what changed. Combines code-review context with security reasoning for PR review.
- **Link:** <https://github.com/trailofbits/skills/blob/main/plugins/differential-review/skills/differential-review/SKILL.md>

## 14. variant-analysis

- **What it does:** Starts from a known vulnerability, extracts its root cause and identifying pattern, generalises that pattern and searches the wider codebase for related instances.
- **Why useful:** Once one real defect or security weakness is found, searching for variants is often more valuable than treating it as an isolated bug. Useful for incident remediation and security reviews.
- **Link:** <https://github.com/trailofbits/skills/blob/main/plugins/variant-analysis/skills/variant-analysis/SKILL.md>

## 15. playwright-cli

- **What it does:** Gives coding agents a browser automation workflow for navigating applications, interacting with elements, inspecting pages, capturing screenshots/traces and exercising real user journeys.
- **Why useful:** Closes the loop between generated frontend/backend code and what actually happens in a browser. Useful for functional verification, regression testing and dynamic security investigation.
- **Link:** <https://github.com/microsoft/playwright-cli/blob/main/skills/playwright-cli/SKILL.md>

## 16. subagent-driven-development

- **What it does:** Breaks an implementation plan into independent tasks, delegates them to fresh subagents and applies two-stage review (spec compliance, then code quality) between tasks.
- **Why useful:** Fresh subcontexts reduce accumulated context noise. Explicit review gates make this a much safer form of parallel agent coding than unconstrained dispatch.
- **Link:** <https://github.com/obra/superpowers/blob/main/skills/subagent-driven-development/SKILL.md>

## 17. planning-and-task-breakdown

- **What it does:** Decompose specs into small, verifiable tasks with acceptance criteria and dependency ordering. Generates implementable units.
- **Why useful:** Turns vague requirements into actionable work items for CLI tools, web features, and system components. Works across the entire development lifecycle.
- **Link:** <https://github.com/addyosmani/agent-skills/tree/main/skills/planning-and-task-breakdown>

## 18. code-review-and-quality

- **What it does:** Five-axis review with change sizing (~100 lines), severity labels (Nit/Optional/FYI), review speed norms, and splitting strategies. Staff engineer bar.
- **Why useful:** Catches issues before merge. Useful as a self-review step for every change, especially for systems code where correctness matters.
- **Link:** <https://github.com/addyosmani/agent-skills/tree/main/skills/code-review-and-quality>

## 19. requesting-code-review

- **What it does:** Adds an explicit code-review stage after implementation, asking a separate reviewer to compare the implementation with the plan/requirements and identify issues.
- **Why useful:** Separating implementation and review reduces self-confirmation by the coding agent. Simple, high-value control for agent-generated changes before human PR review.
- **Link:** <https://github.com/obra/superpowers/blob/main/skills/requesting-code-review/SKILL.md>

## 20. find-bugs

- **What it does:** Reviews local branch changes to identify correctness bugs, security vulnerabilities and code-quality problems.
- **Why useful:** Sentry uses this skill in its own engineering workflow. Practical second-pass check after implementation, especially suitable for reviewing an agent's own branch before PR creation.
- **Link:** <https://github.com/getsentry/skills/blob/main/skills/find-bugs/SKILL.md>

## 21. code-review (Sentry)

- **What it does:** Performs engineering code review using the review practices used by Sentry's development teams.
- **Why useful:** Production-derived review workflow rather than generic instructions. Useful as an independent reviewer agent for CLI, backend and frontend changes.
- **Link:** <https://github.com/getsentry/skills/blob/main/skills/code-review/SKILL.md>

## 22. tdd (Matt Pocock)

- **What it does:** Red-green-refactor loop that builds features or fixes bugs one vertical slice at a time. Focused on real engineering, not vibe coding.
- **Why useful:** Lightweight and composable with other skills. Optimised for agent session flow. Integrates with grilling and domain-modelling skills.
- **Link:** <https://github.com/mattpocock/skills/tree/main/skills/engineering/tdd>

## 23. react-best-practices

- **What it does:** Encodes Vercel engineering guidance for React and Next.js performance, including data fetching, rendering, bundling and component-performance patterns.
- **Why useful:** For React/Next.js websites, this gives the agent framework-specific engineering judgement that generic coding guidance lacks.
- **Link:** <https://github.com/vercel-labs/agent-skills/blob/main/skills/react-best-practices/SKILL.md>

## 24. supabase-postgres-best-practices

- **What it does:** Guides PostgreSQL schema design, SQL performance, indexes, connection management, concurrency, security/RLS, monitoring and operational practices.
- **Why useful:** Database mistakes are a common source of both performance and security problems. The guidance is useful for PostgreSQL generally, not only Supabase-hosted databases.
- **Link:** <https://github.com/supabase/agent-skills/blob/main/skills/supabase-postgres-best-practices/SKILL.md>

## 25. supply-chain-risk-auditor

- **What it does:** Audits the supply-chain threat landscape of a project's dependencies, highlighting packages or dependency relationships that merit closer security review.
- **Why useful:** Modern applications inherit a large attack surface from third-party packages. Encourages risk assessment rather than treating vulnerability feeds as the whole supply-chain problem.
- **Link:** <https://github.com/trailofbits/skills/tree/main/plugins/supply-chain-risk-auditor>

## 26. insecure-defaults

- **What it does:** Audits for fail-open behaviour and insecure defaults such as fallback secrets, default credentials, permissive access, weak cryptography and debug-oriented behaviour.
- **Why useful:** These weaknesses often survive normal static analysis because the code is syntactically correct. Particularly useful during security review of configuration-heavy services and CLI tools.
- **Link:** <https://github.com/trailofbits/skills/tree/main/plugins/insecure-defaults>

## 27. security-review (Sentry)

- **What it does:** Performs a security-focused source-code review for vulnerabilities using Sentry's internal agent-skill workflow.
- **Why useful:** Provides a broad manual-review layer around specialised SAST tools. Useful before release or alongside CodeQL/Semgrep for logic and trust-boundary issues.
- **Link:** <https://github.com/getsentry/skills/blob/main/skills/security-review/SKILL.md>

## 28. api-to-agent-cli

- **What it does:** AWS's workflow converts an API into an agent-friendly CLI through inventory, workflow consolidation, CLI stubbing, skill creation and an audit phase. Includes a Python/Typer reference implementation.
- **Why useful:** Unusually relevant to building modern CLI tools used by both humans and agents. Explicitly focuses on command design, structured outputs and workflow-oriented interfaces.
- **Link:** <https://github.com/aws-samples/sample-aws-ops-skills-for-agents/blob/main/api-to-agent-cli/SKILL.md>

## 29. api-and-interface-design

- **What it does:** Contract-first design, Hyrum's Law, One-Version Rule, error semantics, boundary validation for APIs, module boundaries, and public interfaces.
- **Why useful:** Every CLI tool exposes an interface, every web app has APIs. Prevents accidental coupling and breaking changes.
- **Link:** <https://github.com/addyosmani/agent-skills/tree/main/skills/api-and-interface-design>

## 30. modern-python

- **What it does:** Applies a modern Python toolchain and engineering practices using tools such as `uv`, `ruff` and `pytest`.
- **Why useful:** Python is a strong choice for engineering CLIs, automation and security tooling. Helps an agent produce a coherent modern project rather than mixing legacy approaches.
- **Link:** <https://github.com/trailofbits/skills/tree/main/plugins/modern-python>

## 31. agentic-actions-auditor

- **What it does:** Statically audits GitHub Actions workflows that invoke AI coding agents, looking for attacker-controlled inputs, dangerous privileges, weak isolation and exploitable workflow construction.
- **Why useful:** Agentic CI introduces a new trust boundary: untrusted PR/issue content can become instructions to an agent with repository or workflow permissions.
- **Link:** <https://github.com/trailofbits/skills/blob/main/plugins/agentic-actions-auditor/skills/agentic-actions-auditor/SKILL.md>

## 32. semgrep-rule-creator

- **What it does:** Creates, tests and refines custom Semgrep rules for project- or organisation-specific vulnerability patterns.
- **Why useful:** The biggest value from SAST often comes after turning a real defect into a reusable automated control. Converts security-review knowledge into repeatable CI checks.
- **Link:** <https://github.com/trailofbits/skills/tree/main/plugins/semgrep-rule-creator>

## 33. audit-context-building

- **What it does:** Builds detailed codebase understanding for security auditing, analysing functions, callers/callees, invariants, assumptions and relevant execution context before searching for vulnerabilities.
- **Why useful:** Good security analysis depends on understanding intended behaviour. Reduces shallow pattern matching, particularly useful when analysing unfamiliar repositories.
- **Link:** <https://github.com/trailofbits/skills/tree/main/plugins/audit-context-building>

## 34. property-based-testing

- **What it does:** Guides property-based testing across multiple languages, focusing on invariants and automatically generated inputs rather than only hand-written examples.
- **Why useful:** Excellent for parsers, CLI input handling, APIs, state machines and security-sensitive logic where edge cases are difficult to enumerate manually.
- **Link:** <https://github.com/trailofbits/skills/tree/main/plugins/property-based-testing>

## 35. atheris

- **What it does:** Builds and runs coverage-guided fuzzing for Python code and Python C extensions using Google's Atheris/libFuzzer ecosystem, including AddressSanitizer support.
- **Why useful:** Strong match for Python CLI parsers, file-processing code, protocol handlers and security tools that consume untrusted data. Exposes paths that ordinary tests never exercise.
- **Link:** <https://github.com/trailofbits/skills/blob/main/plugins/testing-handbook-skills/skills/atheris/SKILL.md>

## 36. mutation-testing

- **What it does:** Configures and executes mutation-testing campaigns, changes code deliberately and checks whether the test suite detects the introduced faults.
- **Why useful:** Passing tests do not prove tests are strong. Gives the coding agent a way to measure test effectiveness around important business logic and security controls.
- **Link:** <https://github.com/trailofbits/skills/tree/main/plugins/mutation-testing>

## 37. spec-to-code-compliance

- **What it does:** Compares implementation code against the documentation or specification that defines its required behaviour and identifies mismatches.
- **Why useful:** Highly valuable for APIs, protocols, platform services and regulated systems. Catches defects where code works internally but does not implement the agreed contract.
- **Link:** <https://github.com/trailofbits/skills/tree/main/plugins/spec-to-code-compliance>

## 38. sharp-edges

- **What it does:** Searches APIs, configurations and designs for dangerous defaults, easy-to-misuse interfaces and "footguns" that can cause security or reliability failures.
- **Why useful:** Shifts review from "is this currently exploitable?" to "is this likely to be misused later?". Useful when designing reusable libraries, platform APIs and CLI commands.
- **Link:** <https://github.com/trailofbits/skills/tree/main/plugins/sharp-edges>

## 39. gha-security-review

- **What it does:** Reviews GitHub Actions for exploitable workflow patterns, unsafe handling of untrusted input and permissions/security weaknesses.
- **Why useful:** CI workflows are production code with powerful credentials, yet often receive less review than application code.
- **Link:** <https://github.com/getsentry/skills/blob/main/skills/gha-security-review/SKILL.md>

## 40. skill-scanner

- **What it does:** Scans agent skills for prompt injection, malicious scripts, excessive permissions, secret exposure and software-supply-chain risks.
- **Why useful:** If agent skills become part of the engineering toolchain, the skills themselves become a new supply-chain dependency. Use before approving any third-party skill.
- **Link:** <https://github.com/getsentry/skills/blob/main/skills/skill-scanner/SKILL.md>

## 41. ci-cd-and-automation

- **What it does:** Shift Left, Faster is Safer, feature flags, quality gate pipelines, failure feedback loops for build and deploy pipelines.
- **Why useful:** Every CLI tool, web app, and system needs CI/CD. Builds pipelines that catch issues early with trunk-based development.
- **Link:** <https://github.com/addyosmani/agent-skills/tree/main/skills/ci-cd-and-automation>

## 42. vulnerability-triage-brocards

- **What it does:** Triage vulnerability reports using 7 brocards to accept, dismiss, or request more info before deeper analysis.
- **Why useful:** Efficient prioritisation during pen testing or when processing scanner results. Prevents wasting time on false positives.
- **Link:** <https://github.com/trailofbits/skills/tree/main/plugins/vulnerability-triage-brocards>

## 43. fp-check

- **What it does:** Systematic false positive verification for security bug analysis with mandatory gate reviews.
- **Why useful:** After running SAST tools, eliminates noise and confirms real vulnerabilities, saving hours of manual triage.
- **Link:** <https://github.com/trailofbits/skills/tree/main/plugins/fp-check>

## 44. performing-web-application-penetration-test

- **What it does:** Provides a systematic authorised web penetration-testing workflow based on OWASP WSTG and Burp Suite, covering authentication, authorisation, input handling, sessions and business logic.
- **Why useful:** Automated scanners are not enough. Gives an agent a structured manual-testing methodology for logic flaws and access-control issues commonly missed.
- **Link:** <https://github.com/mukul975/Anthropic-Cybersecurity-Skills/blob/main/skills/performing-web-application-penetration-test/SKILL.md>

## 45. dast-zap

- **What it does:** Automates dynamic application security testing with OWASP ZAP, including passive/active web scans, OpenAPI/GraphQL API scanning, authentication handling, reports and CI/CD integration.
- **Why useful:** Provides a repeatable DAST layer for development/staging environments and a security regression gate. Complements source-level SAST by testing the running application.
- **Link:** <https://github.com/AgentSecOps/SecOpsAgentKit/blob/main/skills/appsec/dast-zap/SKILL.md>

## 46. burpsuite-project-parser

- **What it does:** Searches and extracts useful information from Burp Suite project files so an agent can analyse captured HTTP traffic and penetration-test evidence programmatically.
- **Why useful:** Bridges a human penetration-testing tool and an analysis agent. Valuable when reviewing large Burp histories or correlating dynamic-test evidence with source-code findings.
- **Link:** <https://github.com/trailofbits/skills/tree/main/plugins/burpsuite-project-parser>

## 47. api-mitmproxy

- **What it does:** Uses mitmproxy to intercept, inspect, modify, record and replay HTTP/HTTPS, HTTP/2, HTTP/3 and WebSocket API traffic, with Python automation and HAR export.
- **Why useful:** Excellent for dynamic API analysis, thick-client/mobile backends and reproducing authorisation or input-validation weaknesses. Scriptable for repeatable security regression tests.
- **Link:** <https://github.com/AgentSecOps/SecOpsAgentKit/blob/main/skills/appsec/api-mitmproxy/SKILL.md>

## 48. recon-nmap

- **What it does:** Provides an authorised Nmap reconnaissance workflow for host discovery, port scanning, service/version enumeration, OS detection, NSE checks, segmentation validation and reporting.
- **Why useful:** Establishes the real externally reachable attack surface before analysing application code. Includes explicit authorisation/scope checks and false-positive validation.
- **Link:** <https://github.com/AgentSecOps/SecOpsAgentKit/blob/main/skills/offsec/recon-nmap/SKILL.md>

## 49. performing-kubernetes-penetration-testing

- **What it does:** Tests Kubernetes security across the API server, kubelet, etcd, pods, RBAC, network policies and secrets using kube-hunter, Kubescape and controlled `kubectl` techniques.
- **Why useful:** Modern systems frequently depend on containers and Kubernetes, where an application-level review alone misses control-plane and workload-isolation risks.
- **Link:** <https://github.com/mukul975/Anthropic-Cybersecurity-Skills/blob/main/skills/performing-kubernetes-penetration-testing/SKILL.md>

## 50. performing-dynamic-analysis-with-any-run

- **What it does:** Guides interactive malware detonation in ANY.RUN, capturing runtime process trees, network traffic, filesystem/system changes and interactive behaviour.
- **Why useful:** Adds true behavioural dynamic analysis. Useful when investigating suspicious binaries, scripts or URLs in a controlled sandbox.
- **Link:** <https://github.com/mukul975/Anthropic-Cybersecurity-Skills/blob/main/skills/performing-dynamic-analysis-with-any-run/SKILL.md>

## 51. analyzing-linux-elf-malware

- **What it does:** Analyses suspicious Linux ELF binaries using static analysis, dynamic tracing and reverse-engineering techniques across x86-64 and ARM samples.
- **Why useful:** Linux servers, containers and cloud workloads make ELF analysis relevant. Useful for investigating suspicious executables beyond simple antivirus signatures.
- **Link:** <https://github.com/mukul975/Anthropic-Cybersecurity-Skills/blob/main/skills/analyzing-linux-elf-malware/SKILL.md>

## 52. conducting-mobile-app-penetration-test

- **What it does:** Uses OWASP MASTG-style mobile security testing across static binary analysis, runtime dynamic analysis, local storage, communications, authentication, cryptography and backend APIs.
- **Why useful:** Mobile clients introduce additional storage, certificate, runtime and API attack surfaces. Provides a coherent end-to-end mobile methodology.
- **Link:** <https://github.com/mukul975/Anthropic-Cybersecurity-Skills/blob/main/skills/conducting-mobile-app-penetration-test/SKILL.md>

## 53. yara-authoring

- **What it does:** Guides creation of maintainable YARA detection rules with linting, atom analysis and rule-quality best practices.
- **Why useful:** When analysis produces stable indicators, YARA turns that knowledge into reusable detection. Bridges one-off analysis and repeatable defensive control.
- **Link:** <https://github.com/trailofbits/skills/tree/main/plugins/yara-authoring>

## 54. c-review

- **What it does:** Runs a comprehensive parallel C/C++ security review and produces structured findings/SARIF, including consolidation and false-positive/severity judgement stages.
- **Why useful:** C/C++ needs specialist review because memory safety, integer behaviour and low-level resource handling differ materially from web-language review. Essential for system tooling and native libraries.
- **Link:** <https://github.com/trailofbits/skills/tree/main/plugins/c-review>

## 55. rust-review

- **What it does:** Reviews Rust code for unsafe-boundary issues, memory safety, concurrency hazards, panic-driven denial of service, FFI problems and async-runtime mistakes, with structured reporting.
- **Why useful:** Rust removes many classes of memory bug but does not remove security review requirements. Focuses on where real Rust security failures still occur.
- **Link:** <https://github.com/trailofbits/skills/blob/main/plugins/rust-review/skills/rust-review/SKILL.md>

## 56. terraform-style-guide

- **What it does:** Encodes HashiCorp's guidance for writing clear, idiomatic Terraform/HCL and structuring Terraform code consistently.
- **Why useful:** Official HashiCorp skill. Prevents an agent from inventing idiosyncratic Terraform patterns and improves reviewability of infrastructure changes.
- **Link:** <https://github.com/hashicorp/agent-skills/blob/main/terraform/code-generation/skills/terraform-style-guide/SKILL.md>

## 57. terraform-code-generation

- **What it does:** Write HCL code, build modules, develop providers, and run tests following Terraform conventions. Full code-generation workflow.
- **Why useful:** Infrastructure as code for deploying web apps and systems. Goes beyond style into module structure, provider development and testing.
- **Link:** <https://github.com/hashicorp/agent-skills/tree/main/terraform/code-generation>

## 58. wa-review (AWS Well-Architected)

- **What it does:** Performs a structured AWS Well-Architected review across the six pillars using evidence-based discovery and pillar-specific playbooks.
- **Why useful:** Broadens the agent from coding into system architecture review: reliability, security, operational excellence, performance, cost and sustainability.
- **Link:** <https://github.com/aws-samples/sample-well-architected-skills-and-steering/blob/main/skills/wa-review/SKILL.md>

## 59. otel-instrumentation

- **What it does:** Guides vendor-neutral OpenTelemetry instrumentation for backend and browser applications, covering traces, metrics, logs, SDK setup and telemetry quality.
- **Why useful:** Observability is essential for debugging and operating systems after deployment. Helps build telemetry into the implementation instead of bolting it on after incidents.
- **Link:** <https://github.com/dash0hq/agent-skills/blob/main/skills/otel-instrumentation/SKILL.md>

## 60. observability-and-instrumentation

- **What it does:** Structured logging, RED metrics, OpenTelemetry tracing, symptom-based alerting. Instrument as you build.
- **Why useful:** Complements the Dash0 OTel skill with higher-level guidance on alerting philosophy, metric selection and production readiness. Systems and web apps need observability from day one.
- **Link:** <https://github.com/addyosmani/agent-skills/tree/main/skills/observability-and-instrumentation>

## 61. k8s-api-conventions

- **What it does:** Encodes Kubernetes community API conventions for CRDs/controllers, including spec/status separation, conditions, field semantics, label limits, scalability and downstream-impact review.
- **Why useful:** Captures conventions that generic coding agents routinely miss and which can create difficult runtime/controller bugs in Kubernetes systems.
- **Link:** <https://github.com/kubernetes-sigs/agent-sandbox/blob/main/.agents/skills/k8s-api-conventions/SKILL.md>

## 62. otel-semantic-conventions

- **What it does:** Guides agents to use OpenTelemetry semantic conventions correctly for resource attributes, spans, metrics, logs and service relationships.
- **Why useful:** Instrumentation can technically "work" while producing inconsistent telemetry that breaks service maps, dashboards and cross-service queries. Improves interoperability.
- **Link:** <https://github.com/dash0hq/agent-skills/blob/main/skills/otel-semantic-conventions/SKILL.md>

## 63. OpenSpec workflow

- **What it does:** Provides a lightweight spec-driven workflow that stores proposals, requirements/scenarios, designs and implementation tasks as version-controlled Markdown.
- **Why useful:** A strong alternative to the heavier Spec Kit workflow when a change needs durable requirements but not extensive ceremony. Large community adoption and cross-agent support.
- **Link:** <https://github.com/Fission-AI/OpenSpec>

## 64. frontend-ui-engineering

- **What it does:** Component architecture, design systems, state management, responsive design, WCAG 2.1 AA accessibility for any UI work.
- **Why useful:** For building web applications with proper architecture, not just throwing components together. Activates automatically during frontend work.
- **Link:** <https://github.com/addyosmani/agent-skills/tree/main/skills/frontend-ui-engineering>

## 65. webapp-testing

- **What it does:** Test local web applications using Playwright. Browser automation, assertions, visual testing, and accessibility checks.
- **Why useful:** Official Anthropic skill for end-to-end testing of web apps. Integrates with the agent's ability to launch and interact with browsers.
- **Link:** <https://github.com/anthropics/skills/tree/main/skills/webapp-testing>

## 66. performance-optimization

- **What it does:** Measure-first approach with Core Web Vitals targets, profiling workflows, bundle analysis, and anti-pattern detection.
- **Why useful:** Web performance directly affects user experience and SEO. Prevents premature optimisation while ensuring real issues are caught.
- **Link:** <https://github.com/addyosmani/agent-skills/tree/main/skills/performance-optimization>

## 67. browser-testing-with-devtools

- **What it does:** Chrome DevTools MCP for live runtime data: DOM inspection, console logs, network traces, performance profiling during development.
- **Why useful:** Real-time feedback loop for web development. Agents can inspect live state rather than guessing.
- **Link:** <https://github.com/addyosmani/agent-skills/tree/main/skills/browser-testing-with-devtools>

## 68. frontend-design

- **What it does:** Production-grade frontend interface design and UI/UX development. Official Anthropic skill for building visual interfaces.
- **Why useful:** Generates well-structured, accessible frontend code following modern design principles.
- **Link:** <https://github.com/anthropics/skills/tree/main/skills/frontend-design>

## 69. git-workflow-and-versioning

- **What it does:** Trunk-based development, atomic commits, change sizing (~100 lines), commit-as-save-point pattern.
- **Why useful:** Clean git history makes debugging easier, rollbacks safer, and collaboration smoother for any project.
- **Link:** <https://github.com/addyosmani/agent-skills/tree/main/skills/git-workflow-and-versioning>

## 70. constant-time-analysis

- **What it does:** Detect compiler-induced timing side-channels in cryptographic code. Has found real vulnerabilities (trophy case: ML-DSA signing).
- **Why useful:** For anyone implementing or reviewing cryptographic code in systems or security tools.
- **Link:** <https://github.com/trailofbits/skills/tree/main/plugins/constant-time-analysis>

## 71. zeroize-audit

- **What it does:** Detect missing or compiler-eliminated zeroisation of secrets in C/C++ and Rust.
- **Why useful:** Secrets left in memory are exploitable. Essential for security tools, credential managers, and CLI tools handling sensitive data.
- **Link:** <https://github.com/trailofbits/skills/tree/main/plugins/zeroize-audit>

## 72. code-simplification

- **What it does:** Chesterton's Fence principle, Rule of 500, reduce complexity while preserving exact behaviour. Simplify without breaking.
- **Why useful:** Codebases accumulate complexity. Refactors safely, preserving behaviour while reducing cognitive load.
- **Link:** <https://github.com/addyosmani/agent-skills/tree/main/skills/code-simplification>

## 73. doubt-driven-development

- **What it does:** Adversarial fresh-context review of every non-trivial decision: CLAIM, EXTRACT, DOUBT, RECONCILE, STOP. Optional cross-model escalation.
- **Why useful:** For high-stakes production code, security implementations, and irreversible changes. Catches overconfident agent mistakes.
- **Link:** <https://github.com/addyosmani/agent-skills/tree/main/skills/doubt-driven-development>

## 74. improve-codebase-architecture

- **What it does:** Surveys a codebase for deepening opportunities (modules that should be simplified), presents them as a visual HTML report, then grills through each candidate.
- **Why useful:** Periodic architecture health checks prevent entropy. Run every few days on active projects.
- **Link:** <https://github.com/mattpocock/skills/tree/main/skills/engineering/improve-codebase-architecture>

## 75. diagnosing-bugs

- **What it does:** Disciplined diagnosis loop: build a feedback loop that goes red on this bug, minimise, hypothesise, instrument, fix, regression-test.
- **Why useful:** Structured debugging for hard bugs and performance regressions. Complements Superpowers' systematic-debugging with a different phase structure.
- **Link:** <https://github.com/mattpocock/skills/tree/main/skills/engineering/diagnosing-bugs>

## 76. spec-driven-development (Addy Osmani)

- **What it does:** Write a PRD covering objectives, commands, structure, code style, testing, and boundaries before any code. Full specification workflow.
- **Why useful:** For CLI tools and systems, having a spec prevents scope creep and ensures all edge cases are considered upfront.
- **Link:** <https://github.com/addyosmani/agent-skills/tree/main/skills/spec-driven-development>

## 77. context-engineering

- **What it does:** Feed agents the right information at the right time: rules files, context packing, MCP integrations. Reduces output quality drops.
- **Why useful:** Agents degrade when context is wrong. Teaches structured context management for long sessions and complex codebases.
- **Link:** <https://github.com/addyosmani/agent-skills/tree/main/skills/context-engineering>

## 78. mcp-builder

- **What it does:** Create MCP servers to integrate external APIs and services. Official Anthropic skill for extending agent capabilities.
- **Why useful:** Build custom tool integrations for CLI tools, internal services, and web applications. Enables agents to interact with external systems.
- **Link:** <https://github.com/anthropics/skills/tree/main/skills/mcp-builder>

## 79. documentation-and-adrs

- **What it does:** Architecture Decision Records, API docs, inline documentation standards. Document the why, not the what.
- **Why useful:** Decisions in CLI tools and systems need traceability. ADRs prevent re-litigating past decisions.
- **Link:** <https://github.com/addyosmani/agent-skills/tree/main/skills/documentation-and-adrs>

## 80. shipping-and-launch

- **What it does:** Pre-launch checklists, feature flag lifecycle, staged rollouts, rollback procedures, monitoring setup.
- **Why useful:** Deploying CLI tools and web apps safely. Prevents the "it works on my machine" failure at release time.
- **Link:** <https://github.com/addyosmani/agent-skills/tree/main/skills/shipping-and-launch>

## 81. open-sourcing

- **What it does:** Prepare a repository for public release: secrets hygiene, licensing, CI readiness, and release automation.
- **Why useful:** For CLI tools and libraries you plan to open-source. Catches leaked secrets, missing licences, and CI gaps.
- **Link:** <https://github.com/trailofbits/skills/tree/main/plugins/open-sourcing>

---

## Recommended adoption order

Do not install all skills globally. Start with layers appropriate to your current work:

### Core engineering layer

`systematic-debugging`, `test-driven-development`, `verification-before-completion`, `writing-plans`, `using-git-worktrees`, `requesting-code-review`, `incremental-implementation`, `security-and-hardening`, `grill-with-docs`, plus either **Spec Kit** or **OpenSpec**.

### Core code-security layer

`codeql`, `semgrep`, `differential-review`, `variant-analysis`, `supply-chain-risk-auditor`, `insecure-defaults`, `security-review`, `agentic-actions-auditor`, `gha-security-review`, `vulnerability-triage-brocards`, `fp-check`.

### Web/API dynamic-analysis layer

`playwright-cli`, `performing-web-application-penetration-test`, `dast-zap`, `burpsuite-project-parser`, `api-mitmproxy`, `browser-testing-with-devtools`, `webapp-testing`.

### Language/stack layer (install only where relevant)

- Python/CLI: `modern-python`, `atheris`, `api-to-agent-cli`
- React/Next.js: `react-best-practices`, `frontend-ui-engineering`, `frontend-design`
- PostgreSQL: `supabase-postgres-best-practices`
- C/C++: `c-review`, `constant-time-analysis`, `zeroize-audit`
- Rust: `rust-review`
- Terraform: `terraform-style-guide`, `terraform-code-generation`
- Kubernetes: `k8s-api-conventions`, `performing-kubernetes-penetration-testing`
- Distributed systems: `otel-instrumentation`, `otel-semantic-conventions`, `observability-and-instrumentation`

### Deep security/authorised assessment layer

Use penetration-testing, network-reconnaissance and malware-analysis skills only in explicitly authorised scopes and isolated environments. They are useful specialist tools but should not be globally auto-triggerable.

---

## Source repositories

| Repository                                                                                                      | Stars | Focus                                                    | Install                                                       |
| --------------------------------------------------------------------------------------------------------------- | ----- | -------------------------------------------------------- | ------------------------------------------------------------- |
| [obra/superpowers](https://github.com/obra/superpowers)                                                         | 269k  | Agentic SDD methodology, subagent orchestration          | `/plugin install superpowers@claude-plugins-official`         |
| [mattpocock/skills](https://github.com/mattpocock/skills)                                                       | 210k  | Pragmatic engineering, grilling, domain modelling        | `/plugin install matt-pocock-skills`                          |
| [anthropics/skills](https://github.com/anthropics/skills)                                                       | 167k  | Official Claude skills, document creation, web testing   | `/plugin marketplace add anthropics/skills`                   |
| [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills)                                           | 84k   | Full development lifecycle, Google engineering practices | `npx skills add addyosmani/agent-skills`                      |
| [VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills)                             | 30k   | Curated catalogue of 1,497+ skills from official teams   | Reference list                                                |
| [vercel-labs/skills](https://github.com/vercel-labs/skills)                                                     | 28k   | Skills CLI tool (installer for all skills above)         | `npx skills add <owner/repo>`                                 |
| [trailofbits/skills](https://github.com/trailofbits/skills)                                                     | 6.5k  | Security research, auditing, vulnerability detection     | `/plugin marketplace add trailofbits/skills`                  |
| [getsentry/skills](https://github.com/getsentry/skills)                                                         | —     | Sentry engineering: code review, bugs, security review   | `npx skills add getsentry/skills`                             |
| [hashicorp/agent-skills](https://github.com/hashicorp/agent-skills)                                             | 788   | Terraform, Packer, infrastructure as code                | `npx skills add hashicorp/agent-skills`                       |
| [dash0hq/agent-skills](https://github.com/dash0hq/agent-skills)                                                 | —     | Vendor-neutral OpenTelemetry instrumentation             | `npx skills add dash0hq/agent-skills`                         |
| [aws-samples/sample-aws-ops-skills-for-agents](https://github.com/aws-samples/sample-aws-ops-skills-for-agents) | —     | AWS agent CLI design and operations                      | `npx skills add aws-samples/sample-aws-ops-skills-for-agents` |
| [kubernetes-sigs/agent-sandbox](https://github.com/kubernetes-sigs/agent-sandbox)                               | —     | Kubernetes API conventions                               | `npx skills add kubernetes-sigs/agent-sandbox`                |
| [Fission-AI/OpenSpec](https://github.com/Fission-AI/OpenSpec)                                                   | —     | Lightweight spec-driven workflow                         | Clone or `npx skills add Fission-AI/OpenSpec`                 |
| [AgentSecOps/SecOpsAgentKit](https://github.com/AgentSecOps/SecOpsAgentKit)                                     | —     | DAST, mitmproxy, Nmap agent skills                       | `npx skills add AgentSecOps/SecOpsAgentKit`                   |
| [mukul975/Anthropic-Cybersecurity-Skills](https://github.com/mukul975/Anthropic-Cybersecurity-Skills)           | —     | Web/mobile/K8s pen testing, malware analysis             | `npx skills add mukul975/Anthropic-Cybersecurity-Skills`      |
| [supabase/agent-skills](https://github.com/supabase/agent-skills)                                               | —     | PostgreSQL best practices                                | `npx skills add supabase/agent-skills`                        |
| [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills)                                         | —     | React/Next.js best practices                             | `npx skills add vercel-labs/agent-skills`                     |
| [github/spec-kit](https://github.com/github/spec-kit)                                                           | —     | Specification-driven development workflow                | Reference workflow                                            |

---

## Important security note

An agent skill is part of your execution/control plane. Before enterprise adoption:

1. Pin or vendor a reviewed commit rather than blindly following upstream `main`.
2. Scan the skill, its referenced scripts and any remote resources.
3. Review allowed tools and shell/network permissions.
4. Separate development skills from active penetration-testing skills.
5. Require explicit target/scope authorisation for active scanning.
6. Sandbox dynamic-analysis and malware workflows.
7. Log agent commands and retain scan/test evidence.
8. Periodically re-review pinned skills as the agent runtime itself changes.

---

## Installation

The universal installer for skills:

```sh
npx skills add addyosmani/agent-skills       # Full lifecycle pack (24 skills)
npx skills add obra/superpowers              # SDD methodology
npx skills add mattpocock/skills             # Pragmatic engineering
npx skills add trailofbits/skills            # Security analysis
npx skills add hashicorp/agent-skills        # Terraform/Packer
npx skills add anthropics/skills             # Official Claude skills
npx skills add getsentry/skills              # Sentry engineering
npx skills add dash0hq/agent-skills          # OpenTelemetry
```

Use `--list` to browse before installing, `--skill <name>` to install individual skills.

## Recommendation

### Adoption strategy legend

- ✅ Imported and present in this repository
- 🟢 Full: keep the upstream skill available with no repository-specific behavioural restriction
- 🟡 Patch: keep the upstream skill, but add a repository-specific guard or overlay
- 🔵 Manual: keep installed, but use only by explicit invocation
- 🟣 Bundled: managed through the Spec Kit import flow rather than `scripts/config/skills.yaml`
- 🟠 Mode-gated: imported and supported, but active only when the repository workflow mode selects that lifecycle lane

### Adoption progress

| Rank | Skill                            | Status | Strategy      | Auto-invoke | Mode Guard | Patch | Notes                     |
| ---- | -------------------------------- | ------ | ------------- | ----------- | ---------- | ----- | ------------------------- |
| 1    | `systematic-debugging`           | ✅     | 🟢 Full       | Yes         | No         | No    | Core debugger             |
| 2    | `test-driven-development`        | ✅     | 🟢 Full       | Yes         | No         | No    | Primary TDD               |
| 3    | `verification-before-completion` | ✅     | 🟢 Full       | Yes         | No         | No    | Completion gate           |
| 4    | All `speckit-*` skills           | ✅     | 🟣 Bundled    | Blocked     | Yes        | Yes   | Spec Kit workflow         |
| 7    | `security-and-hardening`         | ✅     | 🟢 Full       | Yes         | No         | No    | Security default          |
| 10   | `incremental-implementation`     | ✅     | 🟠 Mode-gated | Yes         | Yes        | Yes   | Superpowers discipline    |
| 12   | `semgrep`                        | ✅     | 🔵 Manual     | Blocked     | No         | No    | Rapid SAST                |
| 20   | `find-bugs`                      | ✅     | 🟢 Full       | Yes         | No         | No    | Main review skill         |
| 25   | `supply-chain-risk-auditor`      | ✅     | 🔵 Manual     | Blocked     | No         | No    | Dependency posture        |
| 26   | `insecure-defaults`              | ✅     | 🔵 Manual     | Blocked     | No         | No    | Fail-open audit           |
| 37   | `spec-to-code-compliance`        | ✅     | 🟢 Full       | Yes         | No         | No    | Spec compliance           |
| 38   | `sharp-edges`                    | ✅     | 🔵 Manual     | Blocked     | No         | No    | Footgun review            |
| 39   | `gha-security-review`            | ✅     | 🔵 Manual     | Blocked     | No         | No    | Actions security          |
| 40   | `skill-scanner`                  | ✅     | 🔵 Manual     | Blocked     | No         | No    | Skill supply chain        |
| 5    | `writing-plans`                  | ✅     | 🟠 Mode-gated | Yes         | Yes        | Yes   | Superpowers lane          |
| 6    | `using-git-worktrees`            | ✅     | 🟠 Mode-gated | Yes         | Yes        | Yes   | Superpowers cross-cutting |
| 16   | `subagent-driven-development`    | ✅     | 🟠 Mode-gated | Yes         | Yes        | Yes   | Superpowers lane          |
| 19   | `requesting-code-review`         | ✅     | 🟠 Mode-gated | Yes         | Yes        | Yes   | Superpowers review        |
| 21   | `brainstorming`                  | ✅     | 🟠 Mode-gated | Yes         | Yes        | Yes   | Superpowers entry         |
| 22   | `dispatching-parallel-agents`    | ✅     | 🟠 Mode-gated | Yes         | Yes        | Yes   | Superpowers orchestration |
| 23   | `executing-plans`                | ✅     | 🟠 Mode-gated | Yes         | Yes        | Yes   | Superpowers execution     |
| 24   | `receiving-code-review`          | ✅     | 🟠 Mode-gated | Blocked     | Yes        | Yes   | Superpowers review        |
| 25   | `finishing-a-development-branch` | ✅     | 🟠 Mode-gated | Blocked     | Yes        | Yes   | Superpowers finish        |
| 14   | `writing-skills`                 | ✅     | 🔵 Manual     | Blocked     | No         | No    | Skills maintenance        |
| 15   | `playwright-cli`                 | ✅     | 🟢 Full       | Yes         | No         | No    | Browser automation        |
| 29   | `api-and-interface-design`       | ✅     | 🟢 Full       | Yes         | No         | No    | Contract-first design     |
| 34   | `property-based-testing`         | ✅     | 🟢 Full       | Yes         | No         | No    | Invariant testing         |
| 41   | `ci-cd-and-automation`           | ✅     | 🟢 Full       | Yes         | No         | No    | Pipeline guidance         |
| 36   | `mutation-testing`               | ✅     | 🔵 Manual     | Blocked     | No         | No    | Test-suite measurement    |
| 67   | `browser-testing-with-devtools`  | ✅     | 🔵 Manual     | Blocked     | No         | No    | DevTools MCP companion    |
| 78   | `mcp-builder`                    | ✅     | 🔵 Manual     | Blocked     | No         | No    | MCP server creation       |
| 79   | `documentation-and-adrs`         | ✅     | 🔵 Manual     | Blocked     | No         | No    | ADR guidance              |

Adoption notes:

- ✅ `systematic-debugging`, `test-driven-development`, `verification-before-completion`, `security-and-hardening`, `find-bugs`, and `spec-to-code-compliance` are imported and kept as full upstream skills.
- ✅ All `speckit-*` skills are bundled through `make speckit-sync` and remain the primary Spec Kit workflow.
- ✅ `incremental-implementation` is imported through `scripts/config/skills.yaml` and now uses the standard workflow-mode guard, so it runs only in the `superpowers` lane.
- ✅ The Superpowers workflow lane is now imported through `scripts/config/skills.yaml`, including `brainstorming`, `writing-plans`, `dispatching-parallel-agents`, `executing-plans`, `subagent-driven-development`, `requesting-code-review`, `receiving-code-review`, and `finishing-a-development-branch`.
- ✅ `semgrep`, `supply-chain-risk-auditor`, `insecure-defaults`, `sharp-edges`, `gha-security-review`, and `skill-scanner` are now imported as manual-only specialist skills for shell, CI, and skill supply-chain review.
- ✅ Those Superpowers workflow skills, plus `incremental-implementation`, are intentionally mode-gated rather than always active. Use `make workflow-status` to inspect the current lane and `make workflow-use mode=speckit|superpowers` to switch lanes.
- ✅ `using-git-worktrees` and `brainstorming` are now auto-invocable with a mode guard, so the agent triggers them automatically in the `superpowers` lane.
- ✅ `writing-skills` remains manual alongside the newly imported specialist review skills.

### Recommended core set with Spec Kit

| Rank | Skill                            | Status      | Recommended adoption |
| ---- | -------------------------------- | ----------- | -------------------- |
| 1    | `systematic-debugging`           | ✅ Imported | Keep active          |
| 2    | `test-driven-development`        | ✅ Imported | Keep active          |
| 3    | `verification-before-completion` | ✅ Imported | Keep active          |
| 7    | `security-and-hardening`         | ✅ Imported | Keep active          |
| 20   | `find-bugs`                      | ✅ Imported | Keep active          |
| 37   | `spec-to-code-compliance`        | ✅ Imported | Keep active          |

Core-set notes:

- ✅ The imported core set is already in place for this repository.
- 🟠 `incremental-implementation` now sits outside the Spec Kit core and only activates in the `superpowers` lane.
- 🟣 The Spec Kit path for planned work remains `speckit-plan` → `speckit-tasks` → `speckit-implement`.

### Recommended workflow lanes

- `speckit`: all `speckit-*` skills, plus the shared full-adoption core set.
- `superpowers`: `brainstorming`, `writing-plans`, `dispatching-parallel-agents`, `executing-plans`, `subagent-driven-development`, `incremental-implementation`, `requesting-code-review`, `receiving-code-review`, `finishing-a-development-branch`, plus the shared full-adoption core set.

Lane notes:

- Use one workflow family per session or worktree.
- `incremental-implementation` now follows the same workflow-mode switch as the rest of the `superpowers` lane.
- The repository now supports both lanes explicitly, so the recommendation is no longer to avoid these Superpowers skills entirely.
- The constraint is mode isolation, not non-adoption. Keep Spec Kit and Superpowers lifecycle commands separated by the workflow-mode switch.

### Compatible specialist skills

| Area            | Compatible skills                                                                                                                                                                                                                                      |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Static analysis | `codeql`, `semgrep`, `semgrep-rule-creator`                                                                                                                                                                                                            |
| Security review | `differential-review`, `variant-analysis`, `supply-chain-risk-auditor`, `insecure-defaults`, `security-review`, `agentic-actions-auditor`, `audit-context-building`, `sharp-edges`, `gha-security-review`, `vulnerability-triage-brocards`, `fp-check` |
| Testing         | `property-based-testing`, `atheris`, `mutation-testing`                                                                                                                                                                                                |
| Python          | `modern-python`, `atheris`                                                                                                                                                                                                                             |
| React/frontend  | `react-best-practices`, `frontend-ui-engineering`, `frontend-design`, `performance-optimization`                                                                                                                                                       |
| Browser testing | `playwright-cli`, `browser-testing-with-devtools`                                                                                                                                                                                                      |
| PostgreSQL      | `supabase-postgres-best-practices`                                                                                                                                                                                                                     |
| API design      | `api-and-interface-design`                                                                                                                                                                                                                             |
| C/C++           | `c-review`, `constant-time-analysis`, `zeroize-audit`                                                                                                                                                                                                  |
| Rust            | `rust-review`                                                                                                                                                                                                                                          |
| Terraform       | `terraform-style-guide`, `terraform-code-generation`                                                                                                                                                                                                   |
| Kubernetes      | `k8s-api-conventions`                                                                                                                                                                                                                                  |
| Observability   | `otel-instrumentation`, `otel-semantic-conventions`, `observability-and-instrumentation`                                                                                                                                                               |
| CI/CD           | `ci-cd-and-automation`                                                                                                                                                                                                                                 |
| Documentation   | `documentation-and-adrs`                                                                                                                                                                                                                               |
| MCP development | `mcp-builder`                                                                                                                                                                                                                                          |

### Choose only one from each group

| Function           | Options                                                                                         | Recommendation                                                                      |
| ------------------ | ----------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| TDD                | Superpowers `test-driven-development`; Addy Osmani `test-driven-development`; Matt Pocock `tdd` | Choose Superpowers                                                                  |
| Debugging          | `systematic-debugging`; `diagnosing-bugs`                                                       | Choose `systematic-debugging`                                                       |
| General review     | `code-review-and-quality`; `find-bugs`; Sentry `code-review`                                    | Choose `find-bugs`                                                                  |
| Browser automation | `playwright-cli`; `webapp-testing`                                                              | Choose `playwright-cli`; add `browser-testing-with-devtools` separately if required |

### Do not combine in the same active workflow lane

These should not run as peers inside one active session or worktree because they represent alternative lifecycle coordinators:

- Rank 5, `writing-plans`: alternative planning lane to `speckit-plan` and `speckit-tasks`.
- Rank 16, `subagent-driven-development`: alternative execution lane to `speckit-implement`.
- Rank 17, `planning-and-task-breakdown`: duplicates `speckit-tasks`.
- Rank 63, `OpenSpec`: alternative specification framework.
- Rank 76, `spec-driven-development`: alternative end-to-end specification workflow.

### Keep manually invocable

| Rank | Skill                           | Reason                                                                  |
| ---- | ------------------------------- | ----------------------------------------------------------------------- |
| 8    | `grill-with-docs`               | Overlaps with specification and clarification                           |
| 28   | `api-to-agent-cli`              | Special-purpose workflow                                                |
| 40   | `skill-scanner`                 | Use when adding or updating skills                                      |
| 58   | `wa-review`                     | Run explicitly for an AWS architecture review                           |
| 69   | `git-workflow-and-versioning`   | Its trunk-based assumptions may conflict with Spec Kit feature branches |
| 72   | `code-simplification`           | Could expand work beyond the approved specification                     |
| 73   | `doubt-driven-development`      | Valuable for high-risk decisions but too intrusive by default           |
| 74   | `improve-codebase-architecture` | Periodic architecture assessment, not normal implementation             |
| 77   | `context-engineering`           | Project-setup and maintenance activity                                  |
| 80   | `shipping-and-launch`           | Invoke during release preparation                                       |
| 81   | `open-sourcing`                 | Invoke only when preparing a public release                             |

Use this frontmatter for those skills in VS Code Copilot:

```yaml
user-invocable: true
disable-model-invocation: true
```

### Keep active-security skills manual and isolated

| Skills                                        |
| --------------------------------------------- |
| `performing-web-application-penetration-test` |
| `dast-zap`                                    |
| `burpsuite-project-parser`                    |
| `api-mitmproxy`                               |
| `recon-nmap`                                  |
| `performing-kubernetes-penetration-testing`   |
| `performing-dynamic-analysis-with-any-run`    |
| `analyzing-linux-elf-malware`                 |
| `conducting-mobile-app-penetration-test`      |
| `yara-authoring`                              |

### Final recommended starting installation

```text
All speckit-* skills

Shared active core:

systematic-debugging
test-driven-development
verification-before-completion
security-and-hardening
find-bugs
spec-to-code-compliance

Mode-gated in `superpowers`:

brainstorming
writing-plans
dispatching-parallel-agents
executing-plans
subagent-driven-development
incremental-implementation
requesting-code-review
receiving-code-review
finishing-a-development-branch
using-git-worktrees

Manual but already imported:
writing-skills
semgrep
supply-chain-risk-auditor
insecure-defaults
sharp-edges
gha-security-review
skill-scanner
```

Then add stack-specific and security-analysis skills only where the project actually needs them. For this repository, the full Superpowers lane is mode-gated and auto-invocable, with `brainstorming` and `using-git-worktrees` now included. `writing-skills`, `semgrep`, `supply-chain-risk-auditor`, `insecure-defaults`, `sharp-edges`, `gha-security-review`, and `skill-scanner` remain manual specialist imports.
