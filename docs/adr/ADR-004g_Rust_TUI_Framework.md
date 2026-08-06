# ADR-004g: Rust TUI framework 🧾

> |              |                                                 |
> | ------------ | ----------------------------------------------- |
> | Date         | `2026-02-14` when the decision was last updated |
> | Status       | `Accepted`                                      |
> | Significance | `Interfaces & contracts, Quality attributes`    |

---

- [ADR-004g: Rust TUI framework 🧾](#adr-004g-rust-tui-framework-)
  - [Context 🧭](#context-)
  - [Decision ✅](#decision-)
    - [Assumptions 🧩](#assumptions-)
    - [Drivers 🎯](#drivers-)
    - [Options 🔀](#options-)
      - [Option A: Ratatui (Selected) ✅](#option-a-ratatui-selected-)
      - [Option B: Cursive](#option-b-cursive)
      - [Option C: iocraft](#option-c-iocraft)
      - [Option D: tui-realm](#option-d-tui-realm)
      - [Option E: crossterm](#option-e-crossterm)
    - [Outcome 🏁](#outcome-)
    - [Rationale 🧠](#rationale-)
  - [Consequences ⚖️](#consequences-️)
  - [Compliance 📏](#compliance-)
  - [Notes 🔗](#notes-)
  - [Actions ✅](#actions-)
  - [Tags 🏷️](#tags-️)

## Context 🧭

Rust tools need a standard TUI (Text User Interface) framework for building interactive, full-screen terminal applications. This goes beyond CLI argument parsing (covered by ADR-004f with `clap`); a TUI framework provides layout management, interactive widgets, event handling, and visual theming within the terminal.

Visual styling, richness of output, and end-user usability are the highest-priority criteria. The chosen framework must produce polished, modern-looking terminal interfaces with minimal effort.

Note: unlike the Go ecosystem where Charmbracelet provides a multi-crate "batteries-included" ecosystem (Bubble Tea + Lip Gloss + Bubbles + Huh), the Rust TUI ecosystem is structured differently. The dominant library (Ratatui) acts as a rendering and widget core, with styling integrated directly into its `Style` API. A large third-party widget ecosystem extends the core, rather than a single vendor providing everything.

## Decision ✅

### Assumptions 🧩

- Rust 1.85.0 is the baseline toolchain.
- TUI applications must run cross-platform (macOS, Linux, Windows).
- The framework should integrate well with the existing tech stack (`cargo`, `rustfmt`, `clippy`, `cargo check`, `cargo test`, `clap`, `tracing`).
- Visual polish and UX quality are valued above raw performance or minimal dependencies.
- Idiomatic Rust patterns (ownership, traits, strong typing) are expected.

### Drivers 🎯

- Visual styling and theming (colours, borders, layout, backgrounds)
- Widget richness (inputs, tables, progress bars, lists, charts, trees, viewports)
- End-user usability (keyboard navigation, mouse support, focus management)
- Developer experience (API clarity, documentation, testing support, idiomatic Rust)
- Ecosystem adoption and active maintenance
- Dependency footprint and compatibility with existing stack

Weighted criteria use a 1–5 scale (higher is more important). Scores use ⭐ (1), ⭐⭐ (2), ⭐⭐⭐ (3). Weighted totals exclude Effort and have a maximum of 69.

| Criteria               | Weight | Rationale                                    |
| ---------------------- | ------ | -------------------------------------------- |
| Visual styling/theming | 5      | Highest priority: polished, modern look      |
| Widget richness        | 5      | Core need for interactive applications       |
| End-user usability     | 5      | Keyboard, mouse, focus management            |
| Developer experience   | 4      | API clarity, docs, testing, idiomatic Rust   |
| Ecosystem/maintenance  | 2      | Longevity and community support              |
| Dependency footprint   | 2      | Prefer lighter but not at expense of quality |

### Options 🔀

#### Option A: Ratatui (Selected) ✅

Use [`Ratatui`](https://github.com/ratatui/ratatui) (v0.30.0, 18.4k ⭐, 267 contributors, MIT): the de facto standard Rust TUI library, forked from `tui-rs` in 2023 and actively maintained by a multi-person core team with 124 releases.

**Top criteria**: Visual styling/theming, Widget richness

**Weighted option score**: 4.5 / 5.0

Ratatui provides an immediate-mode rendering model with a comprehensive built-in widget set: Block, Paragraph, List, Table, Tabs, Gauge, LineGauge, BarChart, Sparkline, Canvas (with arbitrary shape drawing), Chart (scatter and line plots), and Calendar. The `Style` API supports true colour (24-bit), 256-colour, and ANSI palettes, with modifiers (bold, italic, underline, blink, reversed, dim, crossed-out). Layout is managed via a constraint-based system (percentage, ratio, min, max, length, fill). Mouse and keyboard events are handled via pluggable backends (crossterm is the default; termion and termwiz are also supported).

The ecosystem is enormous: over 30 dedicated widget crates including `ratatui-textarea` (vim-like editor), `ratatui-image` (sixel/halfblock images), `tui-tree-widget`, `tui-scrollview`, `tui-big-text`, `tui-popup`, `tui-logger`, `tui-prompts`, `edtui` (vim editor widget), `rat-widget` (comprehensive data-input widgets), and `tachyonfx` (shader-like visual effects). Frameworks like `tui-realm` and `rat-salsa` add React/Elm-inspired structure on top. The `awesome-ratatui` list catalogues over 200 applications built with Ratatui, including gitui, Yazi, bottom, spotify-player, atuin, television, and binsider.

Ratatui has a dedicated website ([ratatui.rs](https://ratatui.rs/)) with tutorials, concept guides, recipes, and a forum. The project uses cargo-generate templates for quick bootstrapping.

| Criteria                | Weight | Score/Notes                                                                                                                                             |
| ----------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Visual styling/theming  | 5      | ⭐⭐⭐ True colour, 256-colour, ANSI; Style API with modifiers; no CSS-like theming engine but direct, composable style construction; tachyonfx effects |
| Widget richness         | 5      | ⭐⭐⭐ Most comprehensive widget ecosystem in Rust: 15+ built-in widgets, 30+ third-party crates, rat-widget for data-input                             |
| End-user usability      | 5      | ⭐⭐⭐ Mouse support, keyboard events, scrollable viewports, canvas drawing; `NO_COLOR` via crossterm                                                   |
| Developer experience    | 4      | ⭐⭐⭐ Excellent docs (website + API docs), tutorials, templates, forum, Discord; 100% Rust, strong typing, immediate-mode simplicity                   |
| Ecosystem/maintenance   | 2      | ⭐⭐⭐ 18.4k stars, 267 contributors, 124 releases, 17.4M downloads, multi-person core team, very active Discord and forum                              |
| Dependency footprint    | 2      | ⭐⭐ Core is lean; crossterm backend adds moderate deps; ecosystem crates are opt-in                                                                    |
| Effort                  |        | S: excellent documentation, templates, and tutorials; immediate-mode model is straightforward                                                           |
| Weighted score (max 69) |        | 65                                                                                                                                                      |

#### Option B: Cursive

Use [`Cursive`](https://github.com/gyscos/cursive) (v0.21.1, 4.7k ⭐, 110 contributors, MIT): a mature, ncurses-inspired TUI library with a callback/event-driven architecture and built-in theming.

**Top criteria**: Visual styling/theming, Widget richness

**Weighted option score**: 3.5 / 5.0

Cursive provides a widget-based (retained-mode) architecture where views are composed into a tree and managed by the framework's event loop. Built-in views include Dialog, TextView, EditView, SelectView, ListView, RadioGroup, Checkbox, MenuBar, LinearLayout, StackView, ScrollView, ProgressBar, SliderView, and Canvas. It features TOML-based theming with palette customisation (background, shadow, view, primary, secondary, tertiary, title colours with front/back variants), configurable borders (simple, outset, none), and shadow support. Multiple backends are supported (crossterm is the default; ncurses, pancurses, termion, and blt are also available). There is a healthy third-party ecosystem including cursive-tabs, cursive_table_view, cursive_tree_view, cursive_calendar_view, cursive-markup (HTML rendering), and cursive-multiplex (tmux-like splitting). Used by ncspot (Spotify client), git-branchless, ripasso, wiki-tui, and glues. The project has been actively maintained for 11 years (50 releases, latest October 2025).

| Criteria                | Weight | Score/Notes                                                                                                                   |
| ----------------------- | ------ | ----------------------------------------------------------------------------------------------------------------------------- |
| Visual styling/theming  | 5      | ⭐⭐ TOML-based theming with palette customisation, border styles, shadows; functional but less flexible than direct styling  |
| Widget richness         | 5      | ⭐⭐⭐ Comprehensive built-in views: dialogs, forms, menus, lists, selects, text areas, progress bars; plus third-party views |
| End-user usability      | 5      | ⭐⭐ Keyboard and mouse input; menu bar, dialog system; functional but less modern UX patterns than Ratatui ecosystem         |
| Developer experience    | 4      | ⭐⭐ Callback-based API, tutorials, good docs.rs coverage; API is older-style, less composable than immediate-mode            |
| Ecosystem/maintenance   | 2      | ⭐⭐ 4.7k stars, 110 contributors, 50 releases, 1.2M downloads; active but smaller community than Ratatui                     |
| Dependency footprint    | 2      | ⭐⭐⭐ Lean core; optional backends add ncurses/pancurses; crossterm backend is lightweight                                   |
| Effort                  |        | S: straightforward widget-based API; good tutorials                                                                           |
| Weighted score (max 69) |        | 51                                                                                                                            |

**Why not chosen**: Styling is palette/TOML-based, offering less flexibility than Ratatui's composable `Style` API for fine-grained visual control. The callback-based retained-mode architecture is more rigid than Ratatui's immediate-mode model, making it harder to test and reason about state transitions. The widget ecosystem, whilst decent, is significantly smaller than Ratatui's 30+ third-party crates. Community size and adoption momentum are substantially lower (4.7k vs 18.4k stars, 1.2M vs 17.4M downloads). For the stated priority of visual richness and modern polish, Ratatui's ecosystem (including tachyonfx effects, ratatui-image, and the rat-widget suite) provides more capability.

#### Option C: iocraft

Use [`iocraft`](https://github.com/ccbrown/iocraft) (v0.7.17, 1.1k ⭐, 9 contributors, MIT/Apache-2.0): a React/SwiftUI-inspired declarative TUI library with an `element!` macro, Flexbox layout via taffy, and a hooks-based component model.

**Top criteria**: Visual styling/theming, End-user usability

**Weighted option score**: 2.7 / 5.0

iocraft brings a React-like declarative paradigm to Rust terminal UIs. The `element!` macro provides JSX-like syntax for composing UI trees. Built-in components include `View` (with border styles, colours, backgrounds, Flexbox layout), `Text` (with colour and weight), and `TextInput`. Custom components are defined via the `#[component]` macro with hooks (`use_state`, `use_future`, `use_context`). Layout is powered by taffy (Flexbox). The library supports fullscreen render loops with mouse and keyboard events, and works on both Unix and Windows terminals. Inspired by Ink (TypeScript) and Dioxus, it was created by a single primary author and is still in rapid development (52 releases, pre-1.0 API). Used in some examples for tables, forms, progress bars, and a calculator, but production adoption is very limited (76k total downloads).

| Criteria                | Weight | Score/Notes                                                                                                            |
| ----------------------- | ------ | ---------------------------------------------------------------------------------------------------------------------- |
| Visual styling/theming  | 5      | ⭐⭐ Colours, border styles (round, single, double, thick, etc.), backgrounds; limited to View/Text props, no theming  |
| Widget richness         | 5      | ⭐ Very limited: View, Text, TextInput only; no tables, lists, charts, trees, progress bars as built-in widgets        |
| End-user usability      | 5      | ⭐⭐ Mouse events, keyboard input, fullscreen render loop; but no focus management, scroll views, or navigation system |
| Developer experience    | 4      | ⭐⭐⭐ Clean declarative API, React-familiar paradigm, hooks, good docs.rs coverage; pre-1.0 API instability risk      |
| Ecosystem/maintenance   | 2      | ⭐ 1.1k stars, 9 contributors, 76k downloads; single maintainer, very early stage                                      |
| Dependency footprint    | 2      | ⭐⭐ taffy (Flexbox engine), crossterm; moderate footprint                                                             |
| Effort                  |        | M: familiar if you know React, but very few built-in widgets means building most things from scratch                   |
| Weighted score (max 69) |        | 37                                                                                                                     |

**Why not chosen**: Still pre-1.0 with only 9 contributors and 76k total downloads, too early and risky for production use. The built-in component set is minimal (View, Text, TextInput only), meaning nearly every widget must be custom-built. Whilst the React-like API is clean and promising, the lack of tables, lists, charts, progress bars, trees, and other standard TUI widgets makes it impractical for building polished, feature-rich applications today. The ecosystem is effectively non-existent compared to Ratatui's 30+ widget crates and 200+ applications. Revisit when it reaches 1.0 and develops a broader widget ecosystem.

#### Option D: tui-realm

Use [`tui-realm`](https://github.com/veeso/tui-realm) (v3.3.0, 886 ⭐, 15 contributors, MIT): a framework built on top of Ratatui that adds React/Elm-inspired component architecture with properties, state, messages, events, and a view manager with focus handling.

**Top criteria**: Visual styling/theming, Widget richness

**Weighted option score**: 2.9 / 5.0

tui-realm provides a structural layer over Ratatui, organising UI as `MockComponent` → `Component` trees with properties and state (à la React), and an event/message system (à la Elm). A `View` manager handles mounting/unmounting, focus forwarding, and event dispatch. It comes with a standard library (`tui-realm-stdlib`) providing pre-built components. Community components include `tui-realm-textarea` and `tui-realm-treeview`. Used by termscp, termusic, BugStalker, and matrix-rust-sdk. The derive macro `#[derive(MockComponent)]` reduces boilerplate. Supports crossterm and termion backends. However, it is primarily maintained by a single person (veeso), has only 15 contributors, and 161k total downloads. Being a framework over Ratatui, it adds a significant abstraction layer and learning overhead.

| Criteria                | Weight | Score/Notes                                                                                                                        |
| ----------------------- | ------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| Visual styling/theming  | 5      | ⭐⭐ Inherits Ratatui's Style API; no additional theming layer; same capabilities but behind an abstraction                        |
| Widget richness         | 5      | ⭐⭐ Standard library components plus Ratatui's widgets; narrower than using Ratatui directly with full ecosystem                  |
| End-user usability      | 5      | ⭐⭐ Focus management, event forwarding; adds structure but same raw UX capabilities as Ratatui                                    |
| Developer experience    | 4      | ⭐⭐ React/Elm model adds structure but also boilerplate and abstraction cost; derive macro helps; documentation is adequate       |
| Ecosystem/maintenance   | 2      | ⭐ 886 stars, 15 contributors, 161k downloads; primarily single-maintainer; used by ~13 listed applications                        |
| Dependency footprint    | 2      | ⭐⭐ Adds framework layer on top of Ratatui; moderate additional footprint                                                         |
| Effort                  |        | M: React/Elm familiarity helps, but the framework adds concepts (MockComponent, Component, Msg, Cmd, Sub) that increase onboarding |
| Weighted score (max 69) |        | 43                                                                                                                                 |

**Why not chosen**: Primarily single-maintainer with a small community (15 contributors, 886 stars). Adds a substantial abstraction layer over Ratatui without providing additional visual or widget capabilities; the same styling and widgets are available by using Ratatui directly, with less boilerplate and more flexibility. The framework concepts (MockComponent, Component, Msg, Cmd, Sub, View, Application) increase the learning curve without clear benefit for teams already comfortable with Ratatui's immediate-mode model. Using Ratatui directly gives full access to its ecosystem of 30+ widget crates without an intermediary layer.

#### Option E: crossterm

Use [`crossterm`](https://github.com/crossterm-rs/crossterm) (v0.29.0, 3.5k ⭐, 100 contributors, MIT): a pure Rust, cross-platform terminal manipulation library providing low-level cursor, styling, terminal, event, and screen operations.

**Top criteria**: Visual styling/theming, Widget richness

**Weighted option score**: 1.7 / 5.0

crossterm is a low-level terminal abstraction layer (not a TUI framework) that provides cursor positioning, screen clearing/scrolling, content styling (fg/bg colour, bold, italic, underline, etc.), terminal size queries, raw mode, alternate screen, mouse capture, bracketed paste, keyboard and mouse event reading, and window title setting. It supports true colour, 256-colour, and ANSI palettes. It works on macOS, Linux, and Windows (including legacy Windows). crossterm is the default backend used by Ratatui and Cursive and is very actively maintained (v0.29.0, 3.5k stars, 100 contributors). However, it provides no widgets, no layout system, and no application structure; it operates at the character/escape-sequence level.

| Criteria                | Weight | Score/Notes                                                                                                  |
| ----------------------- | ------ | ------------------------------------------------------------------------------------------------------------ |
| Visual styling/theming  | 5      | ⭐ True colour, fg/bg, style attributes; no layout, no composable styling: raw escape sequences              |
| Widget richness         | 5      | ⭐ No widgets whatsoever; provides cursor, screen, and event primitives only                                 |
| End-user usability      | 5      | ⭐ Mouse/keyboard/paste event reading; but no UX patterns: everything must be hand-built                     |
| Developer experience    | 4      | ⭐⭐ Well-documented low-level API, actively maintained, cross-platform; but very verbose for any UI work    |
| Ecosystem/maintenance   | 2      | ⭐⭐⭐ 3.5k stars, 100 contributors, very active; used as backend by Ratatui, Cursive, and many other crates |
| Dependency footprint    | 2      | ⭐⭐⭐ Pure Rust, zero C dependencies, very lean                                                             |
| Effort                  |        | XL: building a TUI from crossterm alone requires implementing an entire widget/layout system                 |
| Weighted score (max 69) |        | 27                                                                                                           |

**Why not chosen**: crossterm is a terminal abstraction layer, not a TUI framework. It provides no widgets, no layout engine, and no styling system. Using crossterm directly to build polished TUI applications would require implementing an entire framework on top of it, effectively recreating what Ratatui or Cursive already provide. Included here for completeness as it is the foundation underlying Ratatui (default backend) and is frequently encountered in Rust TUI discussions.

### Outcome 🏁

Adopt `Ratatui` as the default TUI framework for Rust. This decision is reversible if the project's needs change or a stronger alternative emerges. The decision should be revisited if iocraft reaches 1.0 with a mature widget ecosystem, or if a fundamentally different paradigm (e.g. GPU-rendered terminal UIs) becomes viable.

### Rationale 🧠

Using the weighted criteria, Ratatui scores 65/69, well ahead of the next option (Cursive at 51). The gap is largest in the three highest-weighted criteria (visual styling, widget richness, end-user usability), which aligns directly with the stated priorities.

Ratatui is the de facto standard for building terminal applications in Rust. Its immediate-mode rendering model is idiomatic Rust: simple to reason about, easy to test (render a frame, assert on the buffer), and naturally composable. The `Style` API provides fine-grained control over every visual aspect: true colour, 256-colour, ANSI palettes, bold, italic, underline, dim, blink, reversed, crossed-out, and background colours. Styles compose via the `.patch()` method, enabling theme-like reuse without a formal theming engine.

The ecosystem is Ratatui's strongest differentiator. Over 30 widget crates cover every common TUI pattern: `ratatui-textarea` for vim-like text editing, `ratatui-image` for sixel/halfblock images, `tui-tree-widget` for tree views, `rat-widget` for comprehensive data-input forms, `tachyonfx` for shader-like visual effects, `tui-scrollview` for scrollable containers, and many more. Over 200 production applications demonstrate real-world viability: GitUI, Yazi, bottom, spotify-player, atuin, television, binsider, and more.

Ratatui also integrates naturally with the existing tech stack: `clap` (ADR-004f) for CLI parsing, `tracing` (ADR-004e) for logging, and standard Cargo tooling for building and testing.

| Criteria                    | Weight | Ratatui | Cursive | iocraft | tui-realm | crossterm |
| --------------------------- | ------ | ------- | ------- | ------- | --------- | --------- |
| Visual styling/theming      | 5      | ⭐⭐⭐  | ⭐⭐    | ⭐⭐    | ⭐⭐      | ⭐        |
| Widget richness             | 5      | ⭐⭐⭐  | ⭐⭐⭐  | ⭐      | ⭐⭐      | ⭐        |
| End-user usability          | 5      | ⭐⭐⭐  | ⭐⭐    | ⭐⭐    | ⭐⭐      | ⭐        |
| Developer experience        | 4      | ⭐⭐⭐  | ⭐⭐    | ⭐⭐⭐  | ⭐⭐      | ⭐⭐      |
| Ecosystem/maintenance       | 2      | ⭐⭐⭐  | ⭐⭐    | ⭐      | ⭐        | ⭐⭐⭐    |
| Dependency footprint        | 2      | ⭐⭐    | ⭐⭐⭐  | ⭐⭐    | ⭐⭐      | ⭐⭐⭐    |
| **Weighted score (max 69)** |        | **65**  | **51**  | **37**  | **43**    | **27**    |

## Consequences ⚖️

- New TUI applications should use Ratatui by default.
- The crossterm backend should be used unless there is a specific reason to choose termion or termwiz.
- Ecosystem widget crates (e.g. `ratatui-textarea`, `tui-tree-widget`, `rat-widget`) should be preferred over building custom widgets from scratch.
- Styles should be composed using the `Style` API and grouped into a module or struct for theme-like consistency across the application.
- Alternatives require explicit justification.
- TUI application architecture should follow the immediate-mode render loop pattern recommended by Ratatui's documentation.

This decision becomes irrelevant if TUI applications are no longer needed, or if a terminal-independent GUI framework is adopted instead.

## Compliance 📏

- TUI applications use Ratatui with the crossterm backend.
- Widget usage follows the immediate-mode `render` pattern within a `terminal.draw(|frame| { ... })` closure.
- Custom styles are centralised in a theme module for consistency.
- TUI logic is unit-tested by asserting on rendered buffer content.

## Notes 🔗

- Tech Radar: `./Tech_Radar.md`
- Related: ADR-004f (CLI argument parsing: `clap`)
- Related: ADR-004e (Logging: `tracing`)
- Related: ADR-001g (Python TUI framework: `textual`)
- Related: ADR-002g (TypeScript TUI framework: `ink`)
- Related: ADR-003g (Go TUI framework: `bubbletea` + `lipgloss`)
- Ratatui website: [ratatui.rs](https://ratatui.rs/)
- Ratatui GitHub: [github.com/ratatui/ratatui](https://github.com/ratatui/ratatui)
- Ratatui API docs: [docs.rs/ratatui](https://docs.rs/ratatui)
- Awesome Ratatui: [github.com/ratatui/awesome-ratatui](https://github.com/ratatui/awesome-ratatui)

## Actions ✅

- [x] Copilot, 2026-02-14, record the TUI framework decision
- [x] Copilot, 2026-02-14, update Tech Radar

## Tags 🏷️

`#usability #interfaces #maintainability #accessibility`
