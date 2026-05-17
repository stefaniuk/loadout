# Example 01 — Scaffold a new Django project with the standard layout

## Scenario metadata

- **Skill**: django-project
- **Scenario**: Greenfield scaffold of a Django service using uv, a `src/` layout, split settings, and the production-ready baselines.
- **Repository context**: An empty repository already seeded with the `repository-template` core (Makefile, `scripts/init.mk`, pre-commit hooks). No Python code yet.
- **User goal**: Stand up a working Django project named `orders` with PostgreSQL, no Celery, structured logging, and health endpoints ready to deploy as a container.
- **Invocation**: `Use the django-project skill to scaffold a new Django project named orders`

## User prompt

> Scaffold a new Django project called `orders` using the django-project skill. Use Python 3.13, PostgreSQL, no Celery for now, target a container deployment, and include health checks and structured logging from day one.

## Argument and intent resolution

- Action resolves to **scaffold** (capability 1).
- Confirmed inputs: project name `orders`, Python `3.13`, database PostgreSQL, no cache, no background jobs, container deployment, three-environment split (`local`, `staging`, `production`).
- Mandatory reads acknowledged: Python instructions, local-first dev baseline, quality gates baseline, observability baseline, AI-assisted change baseline.

## Context gathering

- Listed repository root: `Makefile`, `scripts/init.mk`, `.tool-versions`, `.editorconfig` already present.
- Confirmed `uv` and `python 3.13` declared in `.tool-versions`.
- Read `.github/instructions/templates/pyproject.toml` as the starting point for the new `pyproject.toml`.
- No existing `src/`, `manage.py`, or `tests/` — clean greenfield.

## Execution

1. Created `pyproject.toml` from the template, set `project.name = "orders"`, `requires-python = ">=3.13"`, declared `dev` group with `ruff`, `mypy`, `django-stubs`, `pytest`, `pytest-django`.
2. Wrote `.python-version` pinned to `3.13`.
3. Generated the `src/` layout: `src/config/`, `src/config/settings/{base,local,production,test}.py`, `src/apps/{core,health,users}/`, plus `manage.py` at the repository root.
4. Configured split settings: `base.py` owns shared config; `local.py` enables `DEBUG`, SQLite fallback; `production.py` sets `DEBUG=False`, `ALLOWED_HOSTS`, `SECURE_*` headers, secure cookies; `test.py` uses an in-memory SQLite database.
5. Wired structured logging in `base.py` with JSON formatter and request-ID middleware in `src/apps/core/middleware.py`.
6. Added `health` app with `/healthz` (process liveness) and `/readyz` (DB ping) endpoints, registered in `src/config/urls.py`.
7. Set explicit timeouts on the default database connection and documented the retry/backoff policy in `src/apps/core/README.md`.
8. Added `make` targets `format`, `lint`, `typecheck`, `test`, `check` wired to `uv run ruff`, `uv run mypy`, `uv run pytest`, and `python manage.py check`.
9. Ran `uv sync` to produce `uv.lock`.

## Output artefacts

- `pyproject.toml`, `uv.lock`, `.python-version`
- `manage.py`
- `src/config/__init__.py`, `asgi.py`, `wsgi.py`, `urls.py`
- `src/config/settings/{base,local,production,test}.py`
- `src/apps/core/__init__.py`, `middleware.py`, `README.md`
- `src/apps/health/views.py`, `urls.py`
- `src/apps/users/__init__.py` (empty app placeholder)
- `tests/test_health.py` covering both health endpoints (TDD: written first)
- `Makefile` updated with Python quality-gate targets

## Validation evidence

- `uv run python manage.py check` → `System check identified no issues (0 silenced).`
- `make lint` → ruff clean, markdownlint clean.
- `make typecheck` → mypy with `django-stubs` clean.
- `make test` → 2 passed (health tests).
- `make scan-secrets` → no leaks reported.

## Final assistant response

> Scaffolded the `orders` Django project. Layout uses `src/` with split settings, structured JSON logging, request-ID middleware, and `/healthz` + `/readyz` endpoints backed by tests written first. Quality gates pass: ruff, mypy, pytest, and `python manage.py check` all clean. Next steps: add the first domain app under `src/apps/` and decide on the secrets strategy for staging and production.

## Notes and follow-ups

- Celery deliberately omitted; revisit once the first asynchronous workload is identified.
- PostgreSQL connection pooling is left to the deployment runtime; document the chosen approach in an ADR before going to production.
- Container image build is out of scope for this skill — combine with the `repository-template` Docker capability when ready.
