---
applyTo: "**/*.{ts,tsx}"
description: "Playwright TypeScript Test Generation Instructions"
---

# Playwright TypeScript Test Generation Instructions 🎭

These instructions define the default engineering approach for writing **production-grade end-to-end tests** using Playwright with TypeScript.

They must remain applicable to:

- Web application testing with Playwright async API
- Browser automation and UI testing
- Accessibility and regression testing
- Cross-browser testing (Chromium, Firefox, WebKit)
- Component testing with Playwright

They are **non-negotiable** unless an exception is explicitly documented (with rationale and expiry) in an ADR/decision record.

**Cross-references.** For general TypeScript engineering standards (typing, error handling, code organisation), see [typescript.instructions.md](./typescript.instructions.md). This file focuses exclusively on Playwright-specific testing patterns.

**Shared baseline.** For language-agnostic Playwright guidance, see [playwright-baseline.include.md](./includes/playwright-baseline.include.md).

**Identifier scheme.** Every normative rule carries a unique tag in the form `[PW-TS-<prefix>-NNN]`, where the prefix maps to the containing section (for example `QR` for Quick Reference, `LOC` for Locators, `AST` for Assertions, `STR` for Structure). Use these identifiers when referencing, planning, or validating requirements.

---

## 0. Quick reference (apply first) 🧠

This section exists so humans and AI assistants can reliably apply the most important rules even when context is tight.

- [PW-TS-QR-001] **Role-based locators**: prioritise `getByRole`, `getByLabel`, `getByText` for resilience and accessibility ([PW-TS-LOC-001]).
- [PW-TS-QR-002] **Web-first assertions**: use auto-retrying `expect` API with `await`; avoid `.toBeVisible()` unless testing visibility changes ([PW-TS-AST-001]).
- [PW-TS-QR-003] **No hard-coded waits**: rely on Playwright's built-in auto-waiting mechanisms ([PW-TS-LOC-004]).
- [PW-TS-QR-004] **Use test.step()**: group interactions to improve readability and reporting ([PW-TS-LOC-005]).
- [PW-TS-QR-005] **Standard imports**: begin files with `import { test, expect } from '@playwright/test'` ([PW-TS-STR-001]).
- [PW-TS-QR-006] **Consistent file naming**: follow `<feature>.spec.ts` convention ([PW-TS-ORG-002]).
- [PW-TS-QR-007] **Use test.describe()**: group related tests logically ([PW-TS-STR-002]).
- [PW-TS-QR-008] **Avoid common anti-patterns**: `waitForTimeout`, missing `await`, `{ force: true }` clicks, tests without assertions (§9).

---

## 1. Code quality standards 📋

### 1.1 Locators

- [PW-TS-LOC-001] Prioritise user-facing, role-based locators (`getByRole`, `getByLabel`, `getByText`, etc.) for resilience and accessibility.
- [PW-TS-LOC-002] Avoid CSS selectors and XPath where role-based alternatives exist.
- [PW-TS-LOC-003] Use `getByTestId` only when semantic locators are insufficient.
- [PW-TS-LOC-004] Rely on Playwright's built-in auto-waiting mechanisms; avoid hard-coded waits or increased default timeouts.
- [PW-TS-LOC-005] Use `test.step()` to group interactions and improve test readability and reporting.

### 1.2 Assertions

- [PW-TS-AST-001] Use auto-retrying web-first assertions with `await` (for example `await expect(locator).toHaveText()`).
- [PW-TS-AST-002] Avoid `expect(locator).toBeVisible()` unless specifically testing for visibility changes.
- [PW-TS-AST-003] Use `toMatchAriaSnapshot` to verify the accessibility tree structure of a component.
- [PW-TS-AST-004] Use `toHaveCount` to assert the number of elements found by a locator.
- [PW-TS-AST-005] Use `toHaveText` for exact text matches and `toContainText` for partial matches.
- [PW-TS-AST-006] Use `toHaveURL` to verify the page URL after an action.

### 1.3 Clarity

- [PW-TS-CLR-001] Use descriptive test and step titles that clearly state the intent.
- [PW-TS-CLR-002] Follow a clear naming convention, such as `Feature - Specific action or scenario`.
- [PW-TS-CLR-003] Add comments only to explain complex logic or non-obvious interactions.

---

## 2. Test structure 🏗️

- [PW-TS-STR-001] Start files with `import { test, expect } from '@playwright/test';`.
- [PW-TS-STR-002] Group related tests for a feature under a `test.describe()` block.
- [PW-TS-STR-003] Use `beforeEach` for setup actions common to all tests in a `describe` block (for example navigating to a page).
- [PW-TS-STR-004] Follow a clear naming convention, such as `Feature - Specific action or scenario`.
- [PW-TS-STR-005] Keep test functions focused (~30 lines or fewer); split complex scenarios into multiple tests or use helper functions.
- [PW-TS-STR-006] Use `baseURL` in `playwright.config.ts` instead of hardcoding URLs in tests.

---

## 3. File organisation 📁

- [PW-TS-ORG-001] Store all test files in the `tests/` directory.
- [PW-TS-ORG-002] Use the convention `<feature-or-page>.spec.ts` (for example `login.spec.ts`, `search.spec.ts`).
- [PW-TS-ORG-003] Aim for one test file per major application feature or page.

---

## 4. Example test structure 📝

```typescript
import { test, expect } from "@playwright/test";

test.describe("Movie Search Feature", () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the application before each test
    await page.goto("https://debs-obrien.github.io/playwright-movies-app");
  });

  test("Search for a movie by title", async ({ page }) => {
    await test.step("Activate and perform search", async () => {
      await page.getByRole("search").click();
      const searchInput = page.getByRole("textbox", { name: "Search Input" });
      await searchInput.fill("Garfield");
      await searchInput.press("Enter");
    });

    await test.step("Verify search results", async () => {
      // Verify the accessibility tree of the search results
      await expect(page.getByRole("main")).toMatchAriaSnapshot(`
        - main:
          - heading "Garfield" [level=1]
          - heading "search results" [level=2]
          - list "movies":
            - listitem "movie":
              - link "poster of The Garfield Movie The Garfield Movie rating":
                - /url: /playwright-movies-app/movie?id=tt5779228&page=1
                - img "poster of The Garfield Movie"
                - heading "The Garfield Movie" [level=2]
      `);
    });
  });
});
```

---

## 5. Test execution strategy 🚀

- [PW-TS-EXE-001] Initial run: execute tests with `npx playwright test --project=chromium`.
- [PW-TS-EXE-002] Analyse test failures and identify root causes.
- [PW-TS-EXE-003] Refine locators, assertions, or test logic as needed.
- [PW-TS-EXE-004] Ensure tests pass consistently and cover the intended functionality.
- [PW-TS-EXE-005] Use `--ui` flag for interactive debugging.
- [PW-TS-EXE-006] Use `--trace on` to capture traces for failed tests.
- [PW-TS-EXE-007] Use `--workers` to control parallelism in CI; ensure tests are isolated and do not share state.
- [PW-TS-EXE-008] Configure screenshots and videos only on failure (`screenshot: 'only-on-failure'`, `video: 'retain-on-failure'`) to reduce CI time.

---

## 6. Quality checklist ✅

Before finalising tests, ensure:

- [PW-TS-CHK-001] All locators are accessible and specific and avoid strict mode violations
- [PW-TS-CHK-002] Tests are grouped logically and follow a clear structure
- [PW-TS-CHK-003] Assertions are meaningful and reflect user expectations
- [PW-TS-CHK-004] Tests follow consistent naming conventions
- [PW-TS-CHK-005] Code is properly formatted and commented where necessary

---

## 7. Page Object Model (recommended for larger suites) 📄

For test suites with more than ~10 tests or significant UI complexity, use the Page Object Model pattern.

- [PW-TS-POM-001] Encapsulate page-specific locators and actions in dedicated classes (e.g. `LoginPage`, `DashboardPage`).
- [PW-TS-POM-002] Keep page objects focused on a single page or component; avoid "god objects".
- [PW-TS-POM-003] Return `this` or the next page object from action methods to enable chaining.
- [PW-TS-POM-004] Store page objects in a `pages/` directory alongside `tests/`.
- [PW-TS-POM-005] Do not include assertions in page objects; keep assertions in test functions.

---

## 8. Test stability and flakiness mitigation 🛡️

E2E tests are prone to flakiness. Apply these rules to improve reliability.

- [PW-TS-STB-001] Follow the shared [Playwright baseline](./includes/playwright-baseline.include.md) for isolation, data hygiene, retries, and timeout discipline.
- [PW-TS-STB-002] Use Playwright's auto-waiting; never use `page.waitForTimeout()` except for debugging.
- [PW-TS-STB-003] Prefer `page.waitForLoadState('networkidle')` sparingly and only when necessary; auto-wait handles most cases.
- [PW-TS-STB-004] Annotate persistently flaky tests with `test.fixme()` or `test.skip()` and fix or remove them promptly.

---

## 9. Anti-patterns (recognise and avoid) 🚫

These patterns cause recurring issues in Playwright TypeScript tests. Avoid them unless an ADR documents a justified exception.

- [PW-TS-ANT-006] Follow the shared [Playwright baseline](./includes/playwright-baseline.include.md) for common anti-patterns (assertions, shared state, URLs, and CI artefacts).
- [PW-TS-ANT-001] **`page.waitForTimeout()` instead of auto-wait** - Playwright waits automatically; explicit waits cause flakiness and slow tests.
- [PW-TS-ANT-002] **Missing `await` on assertions** - causes silent failures; always `await expect(...)`.
- [PW-TS-ANT-003] **Hardcoded timeouts to fix flakiness** - masks underlying issues; fix the root cause instead.
- [PW-TS-ANT-004] **CSS/XPath when role-based locators exist** - brittle and less accessible; prefer `getByRole`, `getByLabel`.
- [PW-TS-ANT-005] **`{ force: true }` click without justification** - hides real interactivity issues; document why it's necessary.
- [PW-TS-ANT-008] **Overly broad locators** - causes strict mode violations; be specific enough to match exactly one element.
- [PW-TS-ANT-011] **`try/catch` to suppress test failures** - masks bugs; let tests fail and fix the underlying issue.
