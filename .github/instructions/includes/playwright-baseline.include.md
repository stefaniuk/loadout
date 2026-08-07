# Playwright Testing Baseline 🎭

Use this shared baseline for Playwright test guidance that is language-agnostic. Language-specific instruction files should reference this and keep API-specific details locally.

**Identifier scheme.** Every normative rule carries a unique tag in the form `[PW-BASE-<prefix>-NNN]`, where the prefix maps to the containing section (for example `LOC` for Locators, `AST` for Assertions, `STB` for Stability, `ANT` for Anti-patterns). Use these identifiers when referencing, planning, or validating requirements.

---

## 1. Locator and assertion principles 🎯

- [PW-BASE-LOC-001] Prioritise user-facing, accessible locators; avoid brittle selectors when semantic options exist.
- [PW-BASE-AST-001] Prefer auto-retrying, web-first assertions for UI checks.
- [PW-BASE-AST-002] Avoid visibility assertions unless the visibility transition itself is the test objective.

## 2. Stability and data hygiene 🧹

- [PW-BASE-STB-001] Isolate tests: no shared mutable state or ordering dependencies.
- [PW-BASE-STB-002] Seed test data explicitly; do not rely on existing database state.
- [PW-BASE-STB-003] Use retries only as a last resort and fix flaky tests promptly.
- [PW-BASE-STB-004] Use custom timeouts only for genuine latency, not to mask slowness.

## 3. Anti-patterns (language-agnostic) ⚠️

- [PW-BASE-ANT-001] Tests without assertions.
- [PW-BASE-ANT-002] Shared mutable state between tests.
- [PW-BASE-ANT-003] Hardcoded URLs in tests instead of configured base URLs.
- [PW-BASE-ANT-004] Always-on screenshots/videos in CI.
- [PW-BASE-ANT-005] Giant test functions that are hard to debug; split or use steps/helpers.
