---
applyTo: "**/*.py"
description: "Playwright Python Test Generation Instructions"
---

# Playwright Python Test Generation Instructions 🎭

These instructions define the default engineering approach for writing **production-grade end-to-end tests** using Playwright with Python.

They must remain applicable to:

- Web application testing with Playwright sync API
- Browser automation and UI testing
- Accessibility and regression testing
- Cross-browser testing (Chromium, Firefox, WebKit)

They are **non-negotiable** unless an exception is explicitly documented (with rationale and expiry) in an ADR/decision record.

**Cross-references.** For general Python engineering standards (typing, error handling, code organisation), see [python.instructions.md](./python.instructions.md). This file focuses exclusively on Playwright-specific testing patterns.

**Shared baseline.** For language-agnostic Playwright guidance, see [playwright-baseline.include.md](./includes/playwright-baseline.include.md).

**Identifier scheme.** Every normative rule carries a unique tag in the form `[PW-PY-<prefix>-NNN]`, where the prefix maps to the containing section (for example `QR` for Quick Reference, `LOC` for Locators, `AST` for Assertions, `STR` for Structure). Use these identifiers when referencing, planning, or validating requirements.

---

## 0. Quick reference (apply first) 🧠

This section exists so humans and AI assistants can reliably apply the most important rules even when context is tight.

- [PW-PY-QR-001] **Role-based locators**: prioritise `get_by_role`, `get_by_label`, `get_by_text` for resilience and accessibility ([PW-PY-LOC-001]).
- [PW-PY-QR-002] **Web-first assertions**: use auto-retrying `expect` API; avoid `.to_be_visible()` unless testing visibility changes ([PW-PY-AST-001]).
- [PW-PY-QR-003] **No hard-coded waits**: rely on Playwright's built-in auto-waiting mechanisms ([PW-PY-LOC-004]).
- [PW-PY-QR-004] **Descriptive test titles**: use clear, intent-revealing function names ([PW-PY-STR-004]).
- [PW-PY-QR-005] **Standard imports**: begin files with `from playwright.sync_api import Page, expect` ([PW-PY-STR-001]).
- [PW-PY-QR-006] **Consistent file naming**: follow `test_<feature>.py` convention ([PW-PY-ORG-002]).
- [PW-PY-QR-007] **Prefer expect over assert**: use Playwright's `expect` for more reliable UI tests ([PW-PY-AST-004]).
- [PW-PY-QR-008] **Avoid common anti-patterns**: `time.sleep()`, `force=True` clicks, shared mutable state, tests without assertions (§9).

---

## 1. Code quality standards 📋

### 1.1 Locators

- [PW-PY-LOC-001] Prioritise user-facing, role-based locators (`get_by_role`, `get_by_label`, `get_by_text`) for resilience and accessibility.
- [PW-PY-LOC-002] Avoid CSS selectors and XPath where role-based alternatives exist.
- [PW-PY-LOC-003] Use `get_by_test_id` only when semantic locators are insufficient.
- [PW-PY-LOC-004] Rely on Playwright's built-in auto-waiting mechanisms; avoid hard-coded waits or increased default timeouts.

### 1.2 Assertions

- [PW-PY-AST-001] Use auto-retrying web-first assertions via the `expect` API (for example `expect(page).to_have_title(...)`).
- [PW-PY-AST-002] Avoid `expect(locator).to_be_visible()` unless specifically testing for a change in an element's visibility.
- [PW-PY-AST-003] Use `expect(locator).to_have_count()` to assert the number of elements found by a locator.
- [PW-PY-AST-004] Prefer `expect` over `assert` for more reliable UI tests.
- [PW-PY-AST-005] Use `expect(locator).to_have_text()` for exact text matches and `expect(locator).to_contain_text()` for partial matches.
- [PW-PY-AST-006] Use `expect(page).to_have_url()` to verify the page URL.

### 1.3 Clarity

- [PW-PY-CLR-001] Use descriptive test titles (for example `def test_navigation_link_works():`) that clearly state their intent.
- [PW-PY-CLR-002] Add comments only to explain complex logic, not to describe simple actions like "click a button".

---

## 2. Test structure 🏗️

- [PW-PY-STR-001] Every test file should begin with `from playwright.sync_api import Page, expect`.
- [PW-PY-STR-002] Use the `page: Page` fixture as an argument in your test functions to interact with the browser page.
- [PW-PY-STR-003] Place navigation steps like `page.goto()` at the beginning of each test function.
- [PW-PY-STR-004] For setup actions shared across multiple tests, use standard Pytest fixtures.
- [PW-PY-STR-005] Keep test functions focused (~30 lines or fewer); split complex scenarios into multiple tests or use helper functions.
- [PW-PY-STR-006] Use `base_url` in `pytest.ini` or `conftest.py` instead of hardcoding URLs in tests.

---

## 3. File organisation 📁

- [PW-PY-ORG-001] Store test files in a dedicated `tests/` directory or follow the existing project structure.
- [PW-PY-ORG-002] Test files must follow the `test_<feature-or-page>.py` naming convention to be discovered by Pytest.
- [PW-PY-ORG-003] Aim for one test file per major application feature or page.

---

## 4. Example 📝

```python
import re
import pytest
from playwright.sync_api import Page, expect

@pytest.fixture(scope="function", autouse=True)
def before_each_after_each(page: Page):
    # Go to the starting url before each test.
    page.goto("https://playwright.dev/")

def test_main_navigation(page: Page):
    expect(page).to_have_url("https://playwright.dev/")

def test_has_title(page: Page):
    # Expect a title "to contain" a substring.
    expect(page).to_have_title(re.compile("Playwright"))

def test_get_started_link(page: Page):
    page.get_by_role("link", name="Get started").click()

    # Expects page to have a heading with the name of Installation.
    expect(page.get_by_role("heading", name="Installation")).to_be_visible()
```

---

## 5. Test execution strategy 🚀

- [PW-PY-EXE-001] Run tests from the terminal using the `pytest` command.
- [PW-PY-EXE-002] Analyse test failures and identify root causes before making changes.
- [PW-PY-EXE-003] Use `--headed` flag for debugging visual issues.
- [PW-PY-EXE-004] Use `--trace on` to capture traces for failed tests.
- [PW-PY-EXE-005] Use `pytest-xdist` with `--numprocesses auto` for parallel execution in CI; ensure tests are isolated.
- [PW-PY-EXE-006] Enable screenshots and videos only on failure (`--screenshot only-on-failure`, `--video retain-on-failure`) to reduce CI time.

---

## 6. Quality checklist ✅

Before finalising tests, ensure:

- [PW-PY-CHK-001] All locators are accessible and specific
- [PW-PY-CHK-002] Tests are grouped logically and follow a clear structure
- [PW-PY-CHK-003] Assertions are meaningful and reflect user expectations
- [PW-PY-CHK-004] Tests follow consistent naming conventions
- [PW-PY-CHK-005] Code is properly formatted and commented where necessary

---

## 7. Page Object Model (recommended for larger suites) 📄

For test suites with more than ~10 tests or significant UI complexity, use the Page Object Model pattern.

- [PW-PY-POM-001] Encapsulate page-specific locators and actions in dedicated classes (e.g. `LoginPage`, `DashboardPage`).
- [PW-PY-POM-002] Keep page objects focused on a single page or component; avoid "god objects".
- [PW-PY-POM-003] Return `self` or the next page object from action methods to enable chaining.
- [PW-PY-POM-004] Store page objects in a `pages/` directory alongside `tests/`.
- [PW-PY-POM-005] Do not include assertions in page objects; keep assertions in test functions.

---

## 8. Test stability and flakiness mitigation 🛡️

E2E tests are prone to flakiness. Apply these rules to improve reliability.

- [PW-PY-STB-001] Follow the shared [Playwright baseline](./includes/playwright-baseline.include.md) for isolation, data hygiene, retries, and timeout discipline.
- [PW-PY-STB-002] Use Playwright's auto-waiting; never use `time.sleep()` or `page.wait_for_timeout()` except for debugging.
- [PW-PY-STB-003] Prefer `wait_for_load_state("networkidle")` sparingly and only when necessary; auto-wait handles most cases.
- [PW-PY-STB-004] Quarantine persistently flaky tests (move to a `@pytest.mark.flaky` marker) and fix or remove them promptly.

---

## 9. Anti-patterns (recognise and avoid) 🚫

These patterns cause recurring issues in Playwright Python tests. Avoid them unless an ADR documents a justified exception.

- [PW-PY-ANT-006] Follow the shared [Playwright baseline](./includes/playwright-baseline.include.md) for common anti-patterns (assertions, shared state, URLs, and CI artefacts).
- [PW-PY-ANT-001] **`time.sleep()` instead of auto-wait** - Playwright waits automatically; explicit sleeps cause flakiness and slow tests.
- [PW-PY-ANT-002] **`assert` instead of `expect`** - loses auto-retry; use Playwright's `expect` API for UI assertions.
- [PW-PY-ANT-003] **Hardcoded timeouts to fix flakiness** - masks underlying issues; fix the root cause instead.
- [PW-PY-ANT-004] **CSS/XPath when role-based locators exist** - brittle and less accessible; prefer `get_by_role`, `get_by_label`.
- [PW-PY-ANT-005] **`force=True` click without justification** - hides real interactivity issues; document why it's necessary.
- [PW-PY-ANT-008] **Overly broad locators** - causes strict mode violations; be specific enough to match exactly one element.
- [PW-PY-ANT-011] **Catching exceptions to avoid test failure** - masks bugs; let tests fail and fix the underlying issue.
