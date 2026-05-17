---
applyTo: "**/*.{jsx,tsx,js,ts}"
description: "ReactJS Engineering Instructions"
---

# ReactJS Engineering Instructions ⚛️

These instructions define **React-specific patterns** for building high-quality applications with modern hooks and component architecture.

They must remain applicable to:

- React 19+ functional components with hooks
- Single Page Applications (SPA) and Server-Side Rendering (SSR)
- Component libraries and design systems
- Mobile-responsive web applications

For general language and tooling guidance, defer to:

- [typescript.instructions.md](./typescript.instructions.md) — strict typing, quality gates, testing tiers

This file covers **only** what that file does not: React component design, hooks patterns, state management, and UI-specific concerns.

They are **non-negotiable** unless an exception is explicitly documented (with rationale and expiry) in an ADR/decision record.

**Identifier scheme.** Every normative rule carries a unique tag in the form `[RJS-<prefix>-NNN]`, where the prefix maps to the containing section (for example `QR` for Quick Reference, `CMP` for Component Design, `HK` for Hooks, `STM` for State Management). Use these identifiers when referencing, planning, or validating requirements.

---

## 0. Quick reference (apply first) 🧠

This section exists so humans and AI assistants can reliably apply the most important rules even when context is tight.

- [RJS-QR-001] **Functional components only**: no class components; use hooks for all stateful logic ([RJS-CMP-001]).
- [RJS-QR-002] **Component size limit**: split components exceeding ~150 lines or 3 responsibilities ([RJS-CMP-003]).
- [RJS-QR-003] **Hooks at top level**: never call hooks inside loops, conditions, or nested functions ([RJS-HK-001]).
- [RJS-QR-004] **Exhaustive deps**: include all referenced values in dependency arrays; use ESLint rule ([RJS-HK-002]).
- [RJS-QR-005] **Cleanup effects**: return cleanup functions from effects that subscribe, listen, or allocate ([RJS-HK-004]).
- [RJS-QR-006] **Props as interface**: define props as a TypeScript `interface` (not `type` alias); avoid `React.FC` ([RJS-CMP-005]).
- [RJS-QR-007] **Error boundaries**: wrap feature boundaries with Error Boundaries; provide fallback UI ([RJS-ERR-001]).
- [RJS-QR-008] **Semantic HTML first**: use native elements before ARIA; `<button>` not `<div onClick>` ([RJS-A11Y-001]).
- [RJS-QR-009] **No inline object/array props**: define outside render or memoize to prevent child re-renders ([RJS-PERF-001]).
- [RJS-QR-010] **Controlled forms**: use controlled inputs with explicit value/onChange; avoid uncontrolled refs for form state ([RJS-FRM-001]).

---

## 1. Component design 🧩

### 1.1 Structure and size

- [RJS-CMP-001] Use **functional components** with hooks; class components are prohibited for new code.
- [RJS-CMP-002] One component per file; co-locate styles, tests, and types in the same directory.
- [RJS-CMP-003] **Split when**: component exceeds ~150 lines, handles > 3 distinct responsibilities, or requires > 5 props that could be grouped.
- [RJS-CMP-004] **Do not split prematurely**: if extraction creates prop-drilling through 3+ levels, reconsider the boundary.

### 1.2 Naming and organisation

- [RJS-CMP-005] Define props as a TypeScript `interface` named `<ComponentName>Props`; avoid `React.FC` (it adds implicit `children` and is discouraged since React 18).
- [RJS-CMP-006] Use **PascalCase** for component names; **camelCase** for hooks (`useSomething`).
- [RJS-CMP-007] Organise by feature/domain (`features/user/UserProfile.tsx`), not by type (`components/`, `containers/`).

### 1.3 Composition

- [RJS-CMP-008] Prefer **composition via children** over render props or HOCs for most cases.
- [RJS-CMP-009] Use **compound components** (for example `<Tabs>`, `<Tabs.Panel>`) when children share implicit state.
- [RJS-CMP-010] HOCs are acceptable only for cross-cutting concerns (auth wrappers, analytics); document their behaviour.

---

## 2. Hooks ⚡

### 2.1 Rules (non-negotiable)

- [RJS-HK-001] Call hooks **only at the top level** of a component or custom hook; never inside loops, conditions, or nested functions.
- [RJS-HK-002] Provide **exhaustive dependency arrays**; enable `react-hooks/exhaustive-deps` ESLint rule and treat violations as errors.
- [RJS-HK-003] If a dependency causes unwanted re-runs, fix the root cause (memoize the value, hoist it, or rethink the effect) — do not suppress the lint rule.

### 2.2 Effects

- [RJS-HK-004] Return a **cleanup function** from any effect that subscribes, adds listeners, or allocates resources.
- [RJS-HK-005] Avoid effects for derived state; compute inline or use `useMemo`.
- [RJS-HK-006] For data fetching, prefer a data-fetching library (React Query, SWR, RTK Query) over raw `useEffect` + `fetch`.

### 2.3 Custom hooks

- [RJS-HK-007] Extract a custom hook when: logic is reused across 2+ components, or logic exceeds 15 lines in the component body.
- [RJS-HK-008] Name custom hooks `use<Purpose>` (for example `useDebounce`, `useLocalStorage`).
- [RJS-HK-009] Custom hooks must be pure of side effects except via `useEffect`; they must not directly mutate external state.

---

## 3. State management 📊

### 3.1 Choosing the right tool

| Scenario                                                      | Tool                             |
| ------------------------------------------------------------- | -------------------------------- |
| UI-local state (toggle, input value)                          | `useState`                       |
| Complex local state with actions                              | `useReducer`                     |
| Shared state across < 5 components in a subtree               | `useContext` + `useReducer`      |
| Server/cache state (fetched data)                             | React Query, SWR, or RTK Query   |
| Global client state across unrelated trees, or > 10 consumers | Zustand, Jotai, or Redux Toolkit |

- [RJS-STM-001] Default to the **simplest tool** that meets the requirement; escalate only when criteria are met.
- [RJS-STM-002] Use `useReducer` when state transitions are **> 3 distinct actions** or when next state depends on previous state in complex ways.
- [RJS-STM-003] Avoid `useContext` for frequently changing values (for example cursor position) — it triggers re-renders of all consumers.

### 3.2 Context usage

- [RJS-STM-004] Split contexts by **update frequency**: separate `UserContext` (rarely changes) from `ThemeContext` (may change on user action).
- [RJS-STM-005] Provide a **custom hook** for each context (for example `useUser()`) that throws if used outside the provider.

### 3.3 Prop drilling threshold

- [RJS-STM-006] If props pass through **> 2 intermediate components** that do not use them, consider context or composition (`children` pattern).

---

## 4. Performance 🚀

### 4.1 Memoisation decision criteria

- [RJS-PERF-001] **Avoid inline object/array/function props** passed to child components; define outside render or wrap in `useMemo`/`useCallback`.
- [RJS-PERF-002] Use `React.memo` when: the component is **expensive to render** (> 50 ms in DevTools profiler) **and** receives stable-ish props from parent.
- [RJS-PERF-003] Use `useMemo` for **expensive computations** (O(n²)+, large array transforms); not for simple derivations.
- [RJS-PERF-004] Use `useCallback` when passing callbacks to **memoised children** or to dependencies of other hooks.
- [RJS-PERF-005] Do **not** memoize everything by default; memoisation has memory cost and adds complexity.

### 4.2 Rendering

- [RJS-PERF-006] Virtualise lists exceeding **100 items** (for example `react-window`, `@tanstack/virtual`).
- [RJS-PERF-007] Use `React.lazy` + `Suspense` for route-level code splitting; aim for initial bundle < 200 KB (gzipped JS).
- [RJS-PERF-008] Avoid layout thrashing: batch DOM reads before writes; prefer CSS transforms over layout-triggering properties.

---

## 5. Data fetching 📡

- [RJS-DATA-001] Use a **data-fetching library** (React Query, SWR, RTK Query) for server state; it handles caching, deduplication, and background refetch.
- [RJS-DATA-002] Model fetch state explicitly: `idle | loading | success | error`; never infer state from `data === undefined`.
- [RJS-DATA-003] Handle **race conditions**: cancel in-flight requests on unmount or dependency change; libraries do this by default.
- [RJS-DATA-004] For mutations, use **optimistic updates** where rollback is cheap; show pending state otherwise.
- [RJS-DATA-005] Disable automatic refetch in tests to avoid flakiness; mock at the network layer (MSW) or provide a test query client.

---

## 6. Forms 📝

- [RJS-FRM-001] Use **controlled components** (`value` + `onChange`); avoid uncontrolled (`defaultValue` + ref) except for performance-critical cases (document why).
- [RJS-FRM-002] For forms with > 5 fields or complex validation, use a form library (React Hook Form, Formik); avoid hand-rolling validation.
- [RJS-FRM-003] Validate on **blur** for immediate feedback; re-validate on submit; debounce async validation (300–500 ms).
- [RJS-FRM-004] Associate every input with a `<label>` via `htmlFor`/`id`; use `aria-describedby` for error messages.

---

## 7. Error handling ⚠️

- [RJS-ERR-001] Wrap **feature boundaries** (routes, modals, widgets) with Error Boundaries; provide meaningful fallback UI.
- [RJS-ERR-002] Log caught errors to a monitoring service (Sentry, Datadog) with context (user ID, route, component stack).
- [RJS-ERR-003] Handle async errors in event handlers explicitly (`try/catch`); unhandled promise rejections do not trigger Error Boundaries.
- [RJS-ERR-004] Display **user-safe messages**; hide stack traces in production.

---

## 8. Accessibility ♿

Follow the TypeScript UI accessibility baseline in [typescript.instructions.md](./typescript.instructions.md) for comprehensive requirements.

- [RJS-A11Y-001] Prefer native semantics over custom widgets; reach for ARIA only when required.
- [RJS-A11Y-002] Ensure all interactive elements are keyboard accessible with visible focus states.
- [RJS-A11Y-003] Validate accessibility with automated tooling (for example axe) and keyboard-only navigation.

---

## 9. Styling 🎨

- [RJS-STY-001] Choose **one** styling approach per project (CSS Modules, Tailwind, CSS-in-JS); document in README.
- [RJS-STY-002] Co-locate styles with components; avoid global stylesheets except for resets and design tokens.
- [RJS-STY-003] Use **CSS custom properties** for theming (colours, spacing, typography); change values, not class names, for theme switching.
- [RJS-STY-004] Design **mobile-first**: base styles for narrow viewports, progressive enhancement via `min-width` media queries.

---

## 10. Testing 🧪

- [RJS-TST-001] Test **behaviour**, not implementation: assert on visible output, ARIA roles, and user interactions; avoid testing internal state.
- [RJS-TST-002] Use **React Testing Library**; prefer `getByRole`, `getByLabelText` over `getByTestId`.
- [RJS-TST-003] Mock network at the boundary (MSW); avoid mocking React internals or hooks.
- [RJS-TST-004] Provide a **test wrapper** with required providers (router, query client, theme) to avoid boilerplate.
- [RJS-TST-005] Aim for **80%+ behavioural coverage** of user journeys; 100% line coverage is not a goal.

---

## 11. Anti-patterns ❌

- [RJS-ANT-001] **Do not use class components** for new code; refactor legacy class components opportunistically.
- [RJS-ANT-002] **Do not use `React.FC`**; it is discouraged since React 18 (implicit `children`, poor generics support).
- [RJS-ANT-003] **Do not suppress `exhaustive-deps`** without a code comment explaining why and an ADR for systemic cases.
- [RJS-ANT-004] **Do not store derived state** in `useState`; compute inline or memoize.
- [RJS-ANT-005] **Do not fetch in `useEffect`** without a data-fetching library or explicit race-condition handling.
- [RJS-ANT-006] **Do not use `index` as `key`** for dynamic lists where items can reorder, be inserted, or be deleted.
- [RJS-ANT-007] **Do not use `<div onClick>`** for interactive elements; use `<button>` or `<a>`.
- [RJS-ANT-008] **Do not mix styling approaches** (for example Tailwind + Styled Components) in the same component tree.
- [RJS-ANT-009] **Do not prop-drill through > 3 levels**; refactor to context, composition, or state library.
- [RJS-ANT-010] **Do not inline large objects/arrays in JSX**; they break memoisation and cause unnecessary re-renders.

---

## 12. Quality checklist ✅

Before shipping React code, verify:

- [RJS-CHK-001] Components are functional with hooks; no class components
- [RJS-CHK-002] No component exceeds ~150 lines or 3 responsibilities
- [RJS-CHK-003] `exhaustive-deps` lint rule is enabled and passing
- [RJS-CHK-004] Effects have cleanup functions where needed
- [RJS-CHK-005] Error Boundaries wrap feature boundaries
- [RJS-CHK-006] All interactive elements are keyboard accessible
- [RJS-CHK-007] Colour contrast meets WCAG 2.2 AA
- [RJS-CHK-008] Tests cover user behaviour, not implementation
- [RJS-CHK-009] No anti-patterns from §11 are present
- [RJS-CHK-010] TypeScript code follows [typescript.instructions.md](./typescript.instructions.md)

---

> **Version**: 1.2.0
> **Last Amended**: 2026-01-17
