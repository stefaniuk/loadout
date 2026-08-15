# Step 05 - C4 Model (LikeC4)

Author the C4 model in LikeC4 (Context, Container, Component) - evidence-first.

## Goal

Create (or update) the C4 model in `.copilot/analysis/likec4/` using LikeC4 DSL.

Also ensure the model is linked from the architecture overview at `.copilot/analysis/README.md`.

## Discovery (run before writing)

### A. Refresh what is already known

1. Re-read:
   - `.copilot/analysis/repository-map.md`
   - `.copilot/analysis/component-*.md`
   - `.copilot/analysis/runtime-flow-*.md`
   - `.copilot/analysis/domain-*.md`
2. Extract into working notes:
   - Deployable units → candidate **containers**
   - Components within each unit → candidate **components**
   - External services → candidate **external systems**
   - Human actors / external automated actors → **actors**
   - Key inbound/outbound interfaces

### B. Decide model scope (explicit)

1. Decide:
   - One **system** in scope (most repositories) **or** a small set of cooperating systems if the repo really contains them
2. Decide whether to model:
   - **Context** (always)
   - **Container** (always)
   - **Component** (for the most architecturally significant containers - not all)

## Steps

### 1) Lay out the LikeC4 workspace

Create or update the following structure under `.copilot/analysis/likec4/`:

```text
.copilot/analysis/likec4/
  README.md              # short, links to views and explains naming
  model.c4               # high-level model: systems, actors, top-level relationships
  containers.c4          # containers per system, top-level relationships between containers
  components/
    container-XXX-name.c4  # one file per container modelled at component level
  views.c4               # all views (Context, Container, Component, Dynamic)
  styles.c4              # tags, colours, line styles (optional but recommended)
```

Naming rules:

- File names use kebab-case
- Identifiers in DSL use camelCase or snake_case consistently (pick one and stick to it)
- Reuse the **same names** as in `component-*.md` and `domain-*.md` (consistency rule)

### 2) Model - Context level

In `model.c4`:

1. Define **actors** (people, external automated systems) that interact with the system.
2. Define the **system** in scope.
3. Define **external systems** (other systems the system in scope depends on).
4. Define **relationships** between actors/systems and the system in scope:
   - Direction (who initiates)
   - Purpose (one short phrase)
   - Protocol/technology (if evidenced - HTTPS, gRPC, AMQP, etc.)

Each relationship must be **evidenced** by code/config in the architecture docs (link to evidence in DSL comments).

### 3) Model - Container level

In `containers.c4`:

1. Inside the system in scope, define **containers**:
   - One per deployable unit (service, web app, API, worker, scheduled job, CLI, mobile app, etc.)
   - Optionally one per major persistent store (databases, caches, queues) - model them as containers within the system if owned, or as external systems if managed externally
2. For each container, capture:
   - Technology (e.g. "Python FastAPI", "TypeScript Next.js", "PostgreSQL 15")
   - Short description (one line)
3. Define **relationships** between containers, and between containers and external systems/actors:
   - Direction, purpose, protocol/technology
   - Evidence-based

### 4) Model - Component level (for selected containers only)

For each architecturally significant container, create `components/container-[XXX]-[name].c4`:

1. Inside that container, define **components**:
   - One per significant component identified in `component-*.md`
   - Keep numbers manageable - aim for 5–12 components per container
2. For each component, capture:
   - Technology (if different from container default)
   - Short description (one line)
3. Define **relationships** between components, and from components to other containers/external systems/actors:
   - Direction, purpose, protocol/technology
   - Evidence-based

Do **not** model every internal class/function - keep to architectural components.

### 5) Views

In `views.c4`:

1. Define one **Context view** of the system in scope.
2. Define one **Container view** of the system in scope.
3. Define one **Component view** per modelled container.
4. Optionally define **Dynamic views** for 1–3 of the most important runtime flows (those already in `runtime-flow-*.md`).

For each view:

- Include only relevant nodes
- Add a short description in DSL comments explaining what the view shows

### 6) Styles and tags (optional but recommended)

In `styles.c4`:

1. Define tags for cross-cutting categories:
   - `external` (for external systems and actors)
   - `database`, `queue`, `cache` (for stores)
   - `legacy`, `deprecated`, `new` (for lifecycle)
2. Assign tags to model elements in the relevant files.
3. Define style rules (colours, line styles) for tags to make views readable.

### 7) README for the LikeC4 model

In `.copilot/analysis/likec4/README.md`:

1. Briefly explain:
   - What is modelled (system, containers, components)
   - Naming conventions used
   - How to render views (link to LikeC4 CLI/docs)
2. Link to:
   - `.copilot/analysis/repository-map.md`
   - `.copilot/analysis/component-*.md`
   - `.copilot/analysis/runtime-flow-*.md`
   - `.copilot/analysis/domain-*.md`

### 8) Update the architecture index

Update `.copilot/analysis/README.md` with a **C4 Model (LikeC4)** section linking to the LikeC4 README and the main views.

## Operating principles (must follow)

- **Evidence first** - every model element and relationship must trace back to code/config. Add evidence as comments inside the DSL (`// evidence: /path#L10-L40`).
- **Names match other docs** - use the same component names as `component-*.md` and the same domain names as `domain-*.md`.
- **Scope discipline** - Context = systems, Container = deployable units, Component = significant internal building blocks. Do **not** mix levels.
- **External vs internal** - only model as "external system" what is genuinely outside your team's ownership/repository.
- **Minimal but complete** - prefer fewer, meaningful elements over an exhaustive (and unreadable) diagram.
- **Unknowns visible** - if something is implied but not evidenced, add a DSL comment: `// unknown from code - {action to confirm}`.

## Common pitfalls (avoid)

- Modelling internal classes/functions as components (too low-level)
- Treating every folder as a component (folder ≠ component)
- Duplicating containers as components in the same view
- Inventing relationships not present in code/config
- Hiding external systems that the code actually calls
- Modelling planned-but-not-built containers without marking them as such

## Template skeletons

### `model.c4`

```text
specification {
  element actor
  element system
  element externalSystem

  tag external
  tag legacy
}

model {
  actor user {
    title "End user"
    description "..."
  }

  system mySystem {
    title "My System"
    description "..."
    // evidence: /path#L10-L40
  }

  externalSystem identityProvider {
    title "Identity Provider"
    description "..."
    #external
    // evidence: /path/to/config#L1-L20
  }

  user -> mySystem "uses"
  mySystem -> identityProvider "authenticates via" "HTTPS/OIDC"
}
```

### `containers.c4`

```text
model {
  extend mySystem {
    container webApp {
      title "Web App"
      description "..."
      technology "TypeScript, Next.js"
      // evidence: /apps/web/package.json
    }

    container api {
      title "API"
      description "..."
      technology "Python, FastAPI"
      // evidence: /services/api/pyproject.toml
    }

    container db {
      title "Primary DB"
      description "..."
      technology "PostgreSQL 15"
      #database
      // evidence: /infra/terraform/db.tf
    }
  }

  webApp -> api "calls" "HTTPS/JSON"
  api -> db "reads/writes" "TCP/SQL"
}
```

### `components/container-001-api.c4`

```text
model {
  extend api {
    component router {
      title "HTTP Router"
      description "..."
      // evidence: /services/api/src/router.py
    }

    component ordersHandler {
      title "Orders Handler"
      description "..."
      // evidence: /services/api/src/orders/handler.py
    }

    component ordersRepository {
      title "Orders Repository"
      description "..."
      // evidence: /services/api/src/orders/repository.py
    }
  }

  router -> ordersHandler "routes /orders to"
  ordersHandler -> ordersRepository "uses"
  ordersRepository -> db "reads/writes" "SQL"
}
```

### `views.c4`

```text
views {
  view contextOfMySystem of mySystem {
    title "System Context"
    include *
  }

  view containersOfMySystem of mySystem {
    title "Containers"
    include *
  }

  view componentsOfApi of api {
    title "API Components"
    include *
  }
}
```
