---
name: django-project
description: Scaffold and evolve Django projects with uv-based tooling, structured settings, and production-ready observability, resilience, availability, and security patterns aligned with python.instructions.md.
argument-hint: "Describe the Django project action: scaffold, add capability, or evolve an existing project"
---

# Django Project Skill 🧩

This skill scaffolds new Django projects or upgrades existing ones with a production-ready layout and operational practices suitable for large systems.

## Scope and alignment 🧭

Mandatory reads (must be loaded before using this skill):

- [Python instructions](../../instructions/python.instructions.md) — use its identifiers when describing compliance.
- [Local-first dev baseline](../../instructions/includes/local-first-dev-baseline.include.md)
- [Quality gates baseline](../../instructions/includes/quality-gates-baseline.include.md)
- [Observability logging baseline](../../instructions/includes/observability-baseline.include.md)
- [AI-assisted change baseline](../../instructions/includes/ai-assisted-change-baseline.include.md)

## Inputs to confirm ✅

- Project name and Python version
- Database (SQLite/PostgreSQL) and cache (Redis/none)
- API surface (Django REST Framework, HTML templates, or both)
- Background jobs (Celery/none) and async worker needs
- Deployment target (container, PaaS, serverless)
- Environment split (local/staging/prod) and secrets strategy

## Quick reference 🧠

| Capability                  | Purpose                                                             | Key Outputs                                                |
| --------------------------- | ------------------------------------------------------------------- | ---------------------------------------------------------- |
| Project scaffold            | Create a working Django foundation aligned with Python instructions | `pyproject.toml`, `src/` layout, settings split, core apps |
| Large-system structure      | Keep growth manageable with clear boundaries                        | Domain apps, service/selectors, thin views                 |
| Observability baseline      | Operational visibility from day one                                 | Structured logs, request IDs, health endpoints             |
| Security baseline           | Protect data and reduce risk                                        | Secure defaults, secrets handling, dependency scanning     |
| Resilience and availability | Survive failures and scale safely                                   | Timeouts, retries, graceful degradation                    |
| Quality gates               | Enforce fast feedback                                               | `make` targets or uv commands for lint/typecheck/test      |

---

## Capabilities 🧰

### 1. Project scaffold (foundation)

Use this for new projects or to align an existing project with the standard layout.

Core requirements:

- Use `pyproject.toml` as the single source of truth. If available, start from [the template](../../instructions/templates/pyproject.toml) and set:
  - project metadata (name, version, requires-python)
  - dependency groups for dev tooling
  - ruff, mypy, pytest configuration
- Use `uv` for deterministic installs and lockfile management.
- Pin Python in `.python-version` and `requires-python`.
- Scaffold with a `src/` layout so imports are explicit and testable.
- Split settings into `base.py`, `local.py`, `production.py`, and `test.py`.
- Provide a minimal `apps/` structure for domain growth.
- Ensure `manage.py` defaults to local settings and can switch via `DJANGO_SETTINGS_MODULE`.

Recommended layout:

```text
.
├── .python-version
├── manage.py
├── pyproject.toml
├── src/
│   ├── config/
│   │   ├── __init__.py
│   │   ├── asgi.py
│   │   ├── urls.py
│   │   ├── wsgi.py
│   │   └── settings/
│   │       ├── __init__.py
│   │       ├── base.py
│   │       ├── local.py
│   │       ├── production.py
│   │       └── test.py
│   └── apps/
│       ├── core/
│       ├── health/
│       └── users/
└── tests/
```

Dependency defaults (adjust to requirements):

- `Django`
- `django-environ` (or a small local env parser if you want to avoid extra deps)
- `pytest`, `pytest-django`
- `ruff`, `mypy`, `django-stubs`

### 2. Large-system structure and boundaries

Use these patterns when the system is expected to grow:

- Group code by domain in `src/apps/<domain>`; avoid a single monolithic `app`.
- Keep views thin; put business logic in services and selectors.
- Use serializers/forms as boundary validators; keep DB access inside selectors or repositories.
- Separate external integrations behind adapters to allow testing and swapping implementations.
- Avoid global mutable state; wire dependencies explicitly.

### 3. Observability baseline

Observability is non-negotiable for production workloads:

- Configure structured logging and include required fields from the structured logging baseline.
- Add request ID/correlation ID middleware and propagate IDs into logs.
- Provide health endpoints (`/healthz`, `/readyz`) with clear dependency checks.
- Add optional hooks for metrics and tracing (Prometheus or OpenTelemetry) but keep them toggled by configuration.
- Never log secrets or raw personal data.

### 4. Security baseline

Protect data and enforce secure defaults:

- Load secrets from environment or a secret manager; never commit or log secrets.
- Enable Django security middleware and set production hardening settings (`DEBUG=false`, explicit `ALLOWED_HOSTS`, `SECURE_SSL_REDIRECT`, `SECURE_HSTS_SECONDS`, secure cookies).
- Keep CSRF and CORS explicit; avoid permissive wildcards in production.
- Use dependency pinning and vulnerability scanning; keep lock files updated.
- Ensure audit/access logs follow the structured logging baseline without sensitive data.

### 5. Resilience and availability baseline

Build for failure and recovery:

- Set explicit timeouts on all outbound HTTP/DB calls; never rely on defaults.
- Use retries with bounded backoff and jitter for transient failures; avoid retrying non-idempotent operations without safeguards.
- Use transaction boundaries for multi-step writes; prefer idempotent background jobs.
- Provide graceful shutdown and ensure long-running tasks are interruptible.
- Use caching for hot paths and provide safe fallbacks when caches fail.

### 6. Quality gates and verification

Align with Python quality gates:

- Prefer `make format`, `make lint`, `make typecheck`, `make test` when Makefile targets exist.
- Otherwise use `uv run ruff format .`, `uv run ruff check .`, `uv run mypy .`, `uv run pytest`.
- Add `python manage.py check` to validate Django configuration before shipping.

---

## Output expectations 📦

When executing this skill, produce:

- A scaffolded Django project or a concrete refactor plan for an existing codebase
- A list of decisions made for observability, security, resilience, and availability
- A short validation checklist using the canonical quality gates

When information is missing, record **Unknown from code – {suggested action}** instead of guessing.

---

> **Version**: 1.0.0
> **Last Amended**: 2026-01-18
