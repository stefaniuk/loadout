# ADR-003g: Go TUI framework 🧾

> |              |                                                 |
> | ------------ | ----------------------------------------------- |
> | Date         | `2026-02-14` when the decision was last updated |
> | Status       | `Accepted`                                      |
> | Significance | `Interfaces & contracts, Quality attributes`    |

---

- [ADR-003g: Go TUI framework 🧾](#adr-003g-go-tui-framework-)
  - [Context 🧭](#context-)
  - [Decision ✅](#decision-)
    - [Assumptions 🧩](#assumptions-)
    - [Drivers 🎯](#drivers-)
    - [Options 🔀](#options-)
      - [Option A: Bubble Tea + Lip Gloss (Selected) ✅](#option-a-bubble-tea--lip-gloss-selected-)
      - [Option B: tview](#option-b-tview)
      - [Option C: termui](#option-c-termui)
      - [Option D: gocui](#option-d-gocui)
      - [Option E: tcell](#option-e-tcell)
    - [Outcome 🏁](#outcome-)
    - [Rationale 🧠](#rationale-)
  - [Consequences ⚖️](#consequences-️)
  - [Compliance 📏](#compliance-)
  - [Notes 🔗](#notes-)
  - [Actions ✅](#actions-)
  - [Tags 🏷️](#tags-️)

## Context 🧭

Go tools need a standard TUI (Text User Interface) framework for building interactive, full-screen terminal applications. This goes beyond CLI argument parsing (covered by ADR-003f with `cobra` + `fatih/color`); a TUI framework provides layout management, interactive widgets, event handling, and visual theming within the terminal.

Visual styling, richness of output, and end-user usability are the highest-priority criteria. The chosen framework must produce polished, modern-looking terminal interfaces with minimal effort.

## Decision ✅

### Assumptions 🧩

- Go 1.25.7 is the baseline toolchain.
- TUI applications must run cross-platform (macOS, Linux, Windows).
- The framework should integrate well with the existing tech stack (`go mod`, `gofmt`, `golangci-lint`, `staticcheck`, `go test`, `cobra`, `fatih/color`).
- Visual polish and UX quality are valued above raw performance or minimal dependencies.
- Idiomatic Go patterns and clean architecture are expected.

### Drivers 🎯

- Visual styling and theming (colours, borders, layout, backgrounds)
- Widget richness (inputs, spinners, tables, progress bars, select lists, viewports)
- End-user usability (keyboard navigation, mouse support, focus management)
- Developer experience (API clarity, documentation, testing support, idiomatic Go)
- Ecosystem adoption and active maintenance
- Dependency footprint and compatibility with existing stack

Weighted criteria use a 1–5 scale (higher is more important). Scores use ⭐ (1), ⭐⭐ (2), ⭐⭐⭐ (3). Weighted totals exclude Effort and have a maximum of 69.

| Criteria               | Weight | Rationale                                    |
| ---------------------- | ------ | -------------------------------------------- |
| Visual styling/theming | 5      | Highest priority: polished, modern look      |
| Widget richness        | 5      | Core need for interactive applications       |
| End-user usability     | 5      | Keyboard, mouse, focus management            |
| Developer experience   | 4      | API clarity, docs, testing, idiomatic Go     |
| Ecosystem/maintenance  | 2      | Longevity and community support              |
| Dependency footprint   | 2      | Prefer lighter but not at expense of quality |

### Options 🔀

#### Option A: Bubble Tea + Lip Gloss (Selected) ✅

Use the [Charm](https://charm.sh/) ecosystem: [`Bubble Tea`](https://github.com/charmbracelet/bubbletea) (v1.3.10, 39.4k ⭐, 139 contributors, MIT) as the TUI framework, [`Lip Gloss`](https://github.com/charmbracelet/lipgloss) (v1.1.0, 10.5k ⭐, 39 contributors, MIT) for styling, [`Bubbles`](https://github.com/charmbracelet/bubbles) (v1.0.0, 7.8k ⭐, 91 contributors, MIT) for pre-built components, and [`Huh`](https://github.com/charmbracelet/huh) (v0.8.0, 6.5k ⭐, 53 contributors, MIT) for interactive forms.

**Top criteria**: Visual styling/theming, Widget richness

**Weighted option score**: 4.8 / 5.0

Bubble Tea is a Go framework based on The Elm Architecture (Model-Update-View), providing a functional, composable approach to building terminal applications. Lip Gloss provides CSS-like styling with true colour support, adaptive colours (light/dark detection), padding, margins, borders (7+ styles), text alignment, and layout composition. Bubbles supplies production-ready components: text input, text area, table, list (with fuzzy filtering and pagination), progress bar, spinner, viewport, paginator, file picker, timer, stopwatch, and help. Huh adds themed forms (Charm, Dracula, Catppuccin, Base 16, Default) with inputs, selects, multi-selects, confirms, and first-class accessibility. Used in production by Microsoft Azure (Aztify), AWS (eks-node-viewer), CockroachDB, Truffle Security (TruffleHog), MinIO, Ubuntu (Authd), Daytona, chezmoi, gh-dash, Glow, Superfile, and over 18,000 other projects. Bubbles just reached v1.0.0, signalling API stability.

| Criteria                | Weight | Score/Notes                                                                                                       |
| ----------------------- | ------ | ----------------------------------------------------------------------------------------------------------------- |
| Visual styling/theming  | 5      | ⭐⭐⭐ Lip Gloss: CSS-like API, true/256/ANSI colour, adaptive light/dark, 7+ border styles, padding/margins      |
| Widget richness         | 5      | ⭐⭐⭐ Bubbles: text input/area, table, list, progress, spinner, viewport, file picker, timer + Huh forms/themes  |
| End-user usability      | 5      | ⭐⭐⭐ Mouse support, keyboard/focus management, Huh accessibility mode (screen readers), `NO_COLOR` support      |
| Developer experience    | 4      | ⭐⭐⭐ Elm Architecture, composable models, excellent docs, tutorials, debug logging, idiomatic Go                |
| Ecosystem/maintenance   | 2      | ⭐⭐⭐ 39.4k stars, 139 contributors, 70 releases, active Discord, 18.1k dependents, Bubbles v1.0.0 just released |
| Dependency footprint    | 2      | ⭐⭐ Multiple packages (bubbletea, lipgloss, bubbles, huh); moderate footprint but all from same maintainer       |
| Effort                  |        | S: excellent documentation, tutorials, and examples; Elm Architecture is intuitive                                |
| Weighted score (max 69) |        | 67                                                                                                                |

#### Option B: tview

Use [`tview`](https://github.com/rivo/tview) (v0.42.0, 13.5k ⭐, 102 contributors, MIT): a terminal UI library with rich, interactive widgets built on top of tcell.

**Top criteria**: Visual styling/theming, Widget richness

**Weighted option score**: 3.7 / 5.0

tview provides the most comprehensive built-in widget set of any single Go TUI library: input forms (text input, selections, checkboxes, buttons), navigable multi-colour text views, editable multi-line text areas, sophisticated navigable table views, flexible tree views, selectable lists, images, grid/flexbox/page layouts, modal message windows, and an application wrapper. It is built on `tcell` (5.1k ⭐) for terminal abstraction. Used by K9s, GitHub CLI (`gh`), lazysql, podman-tui, gdu, and over 5,800 other projects. Maintained primarily by a single author (rivo), who has been responsive and active (commits from 5 months ago).

| Criteria                | Weight | Score/Notes                                                                                               |
| ----------------------- | ------ | --------------------------------------------------------------------------------------------------------- |
| Visual styling/theming  | 5      | ⭐⭐ tcell colour palette, tag-based markup, ANSI themes; functional but no CSS-like styling engine       |
| Widget richness         | 5      | ⭐⭐⭐ Most comprehensive single-package widget set: forms, tables, trees, lists, images, modals, layouts |
| End-user usability      | 5      | ⭐⭐ Keyboard navigation, mouse support; functional UX but less polished than Charm ecosystem             |
| Developer experience    | 4      | ⭐⭐ Callback-based API, good docs (pkg.go.dev + wiki), no built-in testing framework                     |
| Ecosystem/maintenance   | 2      | ⭐⭐ 13.5k stars, 102 contributors, 5.8k dependents; primarily single-maintainer                          |
| Dependency footprint    | 2      | ⭐⭐⭐ Single package + tcell; lightweight                                                                |
| Effort                  |        | S: straightforward widget-based API; good documentation and examples                                      |
| Weighted score (max 69) |        | 53                                                                                                        |

**Why not chosen**: Styling is tag-based and less expressive than Lip Gloss's CSS-like approach. The visual output is functional but lacks the modern polish that Lip Gloss delivers out of the box. Primarily maintained by a single person, which poses a bus-factor risk. The callback-based API is more imperative and less composable than Bubble Tea's Elm Architecture. No built-in theming engine (Charm, Dracula, etc.) or accessibility mode.

#### Option C: termui

Use [`termui`](https://github.com/gizak/termui) (v3.1.0, 13.5k ⭐, 48 contributors, MIT): a cross-platform terminal dashboard and widget library built on termbox-go.

**Top criteria**: Visual styling/theming, Widget richness

**Weighted option score**: 2.2 / 5.0

termui is a dashboard-focused library providing visualisation widgets: BarChart, Canvas (braille dots), Gauge, Image, List, Tree, Paragraph, PieChart, Plot (scatter/line), Sparkline, StackedBarChart, Table, and Tabs. It supports grid-based and absolute positioning, keyboard/mouse/resize events, and basic colours. However, it is built on `termbox-go` (deprecated), the maintainer has publicly acknowledged fluctuating availability, the `go.mod` still declares Go 1.15 compatibility (very outdated), and the last release (v3.1.0) was 7 years ago.

| Criteria                | Weight | Score/Notes                                                                                              |
| ----------------------- | ------ | -------------------------------------------------------------------------------------------------------- |
| Visual styling/theming  | 5      | ⭐ Basic colour support, theming via style.go; no modern styling engine                                  |
| Widget richness         | 5      | ⭐⭐ Strong dashboard/charting widgets (BarChart, PieChart, Plot, Sparkline); weak on interactive inputs |
| End-user usability      | 5      | ⭐ Keyboard/mouse events; designed for dashboards not interactive applications                           |
| Developer experience    | 4      | ⭐ Outdated API, built on deprecated termbox-go, Go 1.15 in go.mod, no testing framework                 |
| Ecosystem/maintenance   | 2      | ⭐ Last release 7 years ago, maintainer flagged low availability, 48 contributors, 482 dependents        |
| Dependency footprint    | 2      | ⭐⭐ Built on deprecated termbox-go; moderate footprint                                                  |
| Effort                  |        | M: reasonable for dashboards; limited for interactive TUI applications                                   |
| Weighted score (max 69) |        | 29                                                                                                       |

**Why not chosen**: Built on `termbox-go`, which is deprecated. Last release was 7 years ago. The maintainer has publicly acknowledged limited availability. The `go.mod` declares Go 1.15 compatibility, far behind the current Go toolchain. Designed for dashboards and data visualisation, not interactive TUI applications with rich input handling. Lacks modern styling, theming, form inputs, and accessibility.

#### Option D: gocui

Use [`gocui`](https://github.com/jroimartin/gocui) (no semver releases, 10.5k ⭐, 20 contributors, BSD-3-Clause): a minimalist Go package for creating console user interfaces.

**Top criteria**: Visual styling/theming, Widget richness

**Weighted option score**: 1.9 / 5.0

gocui provides a minimalist view-based system where "views" act as windows in the GUI, implementing `io.ReadWriter`. It supports overlapping views, runtime GUI modification (concurrent-safe), global and view-level keybindings, mouse support, coloured text, and customisable editing modes. However, the project has seen essentially no development for approximately 9 years (examples last updated 9 years ago, most source files untouched for 8–10 years). It has only 20 contributors, no semantic versioned releases, and a very limited widget set.

| Criteria                | Weight | Score/Notes                                                                                |
| ----------------------- | ------ | ------------------------------------------------------------------------------------------ |
| Visual styling/theming  | 5      | ⭐ Basic coloured text; no theming, no styling engine, no borders/padding API              |
| Widget richness         | 5      | ⭐ Views (windows) only; no pre-built widgets for inputs, tables, lists, progress bars     |
| End-user usability      | 5      | ⭐ Mouse support and keybindings; no focus management, no modern UX patterns               |
| Developer experience    | 4      | ⭐ Minimal API but requires building everything from scratch; documentation is sparse      |
| Ecosystem/maintenance   | 2      | ⭐ Effectively abandoned for 9 years; 20 contributors; no semver releases; 1.1k dependents |
| Dependency footprint    | 2      | ⭐⭐⭐ Lightweight; minimal dependencies                                                   |
| Effort                  |        | L: everything must be built from scratch on top of the minimal view system                 |
| Weighted score (max 69) |        | 27                                                                                         |

**Why not chosen**: Effectively abandoned: no meaningful development for 9 years. Provides only a bare-bones view system with no pre-built widgets, theming, or styling. Building a polished TUI would require implementing every widget from scratch. The 10.5k star count reflects historical popularity, not current viability. No semver releases, no accessibility support, and only 20 contributors.

#### Option E: tcell

Use [`tcell`](https://github.com/gdamore/tcell) (v3.1.2, 5.1k ⭐, 106 contributors, Apache-2.0): a cell-based terminal package providing low-level screen, keyboard, mouse, and colour handling.

**Top criteria**: Visual styling/theming, Widget richness

**Weighted option score**: 1.7 / 5.0

tcell is a low-level terminal abstraction layer (not a TUI framework) that provides screen management, 24-bit colour, mouse tracking, bracketed paste, wide character support, and cross-platform compatibility (POSIX, Windows, WASM, Plan 9). It is very actively maintained (v3.1.2 released 3 weeks ago, 55 releases total) and serves as the foundation for `tview` and other higher-level frameworks. However, it provides no widgets, no layout system, and no styling abstractions; it operates at the cell (character) level.

| Criteria                | Weight | Score/Notes                                                                                                 |
| ----------------------- | ------ | ----------------------------------------------------------------------------------------------------------- |
| Visual styling/theming  | 5      | ⭐ 24-bit colour, style attributes; no layout or styling engine: raw cell-based rendering                   |
| Widget richness         | 5      | ⭐ No widgets whatsoever; provides screen, keyboard, and mouse primitives only                              |
| End-user usability      | 5      | ⭐ Rich keyboard/mouse/paste support; but no UX patterns: everything must be hand-built                     |
| Developer experience    | 4      | ⭐⭐ Well-documented low-level API, actively maintained, v3 with modern features; but very verbose          |
| Ecosystem/maintenance   | 2      | ⭐⭐⭐ Very active (55 releases, 3-week-old release), 106 contributors, 8.4k dependents, commercial support |
| Dependency footprint    | 2      | ⭐⭐⭐ Pure Go, no CGO, very lean                                                                           |
| Effort                  |        | XL: building a TUI from tcell alone requires implementing an entire widget/layout system                    |
| Weighted score (max 69) |        | 27                                                                                                          |

**Why not chosen**: tcell is a terminal abstraction layer, not a TUI framework. It provides no widgets, no layout engine, and no styling system. Using tcell directly to build polished TUI applications would require implementing an entire framework on top of it, effectively recreating what tview or Bubble Tea already provide. Included here for completeness as it is the foundation underlying tview and is frequently encountered in Go TUI discussions.

### Outcome 🏁

Adopt `Bubble Tea` + `Lip Gloss` (with `Bubbles` and `Huh`) as the default TUI framework for Go. This decision is reversible if the project's needs change or a stronger alternative emerges. The decision should be revisited if the Charm ecosystem's maintenance model changes or if tview reaches feature parity on styling and theming.

### Rationale 🧠

Using the weighted criteria, Bubble Tea + Lip Gloss scores 67/69, well ahead of the next option (tview at 53). The gap is largest in the three highest-weighted criteria (visual styling, widget richness, end-user usability), which aligns directly with the stated priorities.

The Charm ecosystem is the de facto standard for building modern terminal applications in Go. Bubble Tea's Elm Architecture provides a clean, composable, and testable approach that aligns with Go's preference for explicit, functional patterns. Lip Gloss's CSS-like styling API delivers rich visual output with minimal code: true colour, adaptive colours (automatic light/dark detection), multiple border styles, padding, margins, alignment, and layout composition. Bubbles provides production-ready components that cover the most common TUI patterns, and Huh adds themed interactive forms with first-class accessibility.

The ecosystem's adoption validates its production-readiness: Microsoft Azure, AWS, CockroachDB, Truffle Security, MinIO, Ubuntu, Daytona, and over 18,000 other projects depend on Bubble Tea. The recent Bubbles v1.0.0 release signals API stability and long-term commitment.

Lip Gloss also integrates naturally with the existing tech stack: `fatih/color` (adopted per ADR-003f) can coexist for simple CLI output colouring, whilst Lip Gloss handles sophisticated TUI layout and styling.

| Criteria                    | Weight | Bubble Tea + Lip Gloss | tview  | termui | gocui  | tcell  |
| --------------------------- | ------ | ---------------------- | ------ | ------ | ------ | ------ |
| Visual styling/theming      | 5      | ⭐⭐⭐                 | ⭐⭐   | ⭐     | ⭐     | ⭐     |
| Widget richness             | 5      | ⭐⭐⭐                 | ⭐⭐⭐ | ⭐⭐   | ⭐     | ⭐     |
| End-user usability          | 5      | ⭐⭐⭐                 | ⭐⭐   | ⭐     | ⭐     | ⭐     |
| Developer experience        | 4      | ⭐⭐⭐                 | ⭐⭐   | ⭐     | ⭐     | ⭐⭐   |
| Ecosystem/maintenance       | 2      | ⭐⭐⭐                 | ⭐⭐   | ⭐     | ⭐     | ⭐⭐⭐ |
| Dependency footprint        | 2      | ⭐⭐                   | ⭐⭐⭐ | ⭐⭐   | ⭐⭐⭐ | ⭐⭐⭐ |
| **Weighted score (max 69)** |        | **67**                 | **53** | **29** | **27** | **27** |

## Consequences ⚖️

- New TUI applications should use Bubble Tea with Lip Gloss for styling by default.
- The Charm ecosystem introduces multiple dependencies (bubbletea, lipgloss, bubbles, huh); these are all from the same organisation (Charmbracelet) and share a consistent API philosophy.
- `fatih/color` (ADR-003f) remains appropriate for simple CLI output colouring; Lip Gloss is for TUI layout and styling.
- Alternatives require explicit justification.
- Developers should follow Bubble Tea's Model-Update-View pattern and use Lip Gloss styles for all visual output within TUI applications.
- Interactive forms should use Huh with a consistent theme (e.g. Charm or Catppuccin).
- Testing should use Bubble Tea's `tea.Send` approach and model unit testing.

This decision becomes irrelevant if TUI applications are no longer needed, or if a terminal-independent GUI framework is adopted instead.

## Compliance 📏

- TUI applications use Bubble Tea and Lip Gloss for styling.
- Widget usage follows the Model-Update-View pattern from The Elm Architecture.
- Forms use Huh with a predefined theme.
- TUI models are unit-tested via their `Update` and `View` methods.

## Notes 🔗

- Tech Radar: `./Tech_Radar.md`
- Related: ADR-003f (CLI argument parsing: `cobra` + `fatih/color`)
- Related: ADR-001g (Python TUI framework: `textual`)
- Related: ADR-002g (TypeScript TUI framework: `ink`)
- Bubble Tea: [github.com/charmbracelet/bubbletea](https://github.com/charmbracelet/bubbletea)
- Lip Gloss: [github.com/charmbracelet/lipgloss](https://github.com/charmbracelet/lipgloss)
- Bubbles: [github.com/charmbracelet/bubbles](https://github.com/charmbracelet/bubbles)
- Huh: [github.com/charmbracelet/huh](https://github.com/charmbracelet/huh)
- Charm ecosystem: [charm.sh](https://charm.sh/)

## Actions ✅

- [x] Copilot, 2026-02-14, record the TUI framework decision
- [x] Copilot, 2026-02-14, update Tech Radar

## Tags 🏷️

`#usability #interfaces #maintainability #accessibility`
