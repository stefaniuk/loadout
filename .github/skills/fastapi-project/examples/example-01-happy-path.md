# Example 01 - Scaffold a new FastAPI project with the standard layout

## Scenario metadata

- **Skill**: fastapi-project
- **Scenario**: Greenfield scaffold of a FastAPI service using uv, a `src/` layout, pydantic-settings, and the production-ready baselines.
- **Repository context**: An empty repository already seeded with the `repository-template` core (Makefile, `scripts/init.mk`, pre-commit hooks). No Python code yet.
- **User goal**: Stand up a working FastAPI service named `payments-api` targeting a container deployment, with health endpoints, structured logging, and outbound HTTP via `httpx`.
- **Invocation**: `Use the fastapi-project skill to scaffold a new FastAPI service named payments-api`

## User prompt

> Scaffold a new FastAPI project named `payments-api` using the fastapi-project skill. Python 3.13, PostgreSQL, no Redis, no background jobs yet, container deployment, three-environment split.

## Argument and intent resolution

- Action resolves to **scaffold** (capability 1).
- Confirmed inputs: project name `payments-api`, Python `3.13`, REST-only API, PostgreSQL, no cache, no background jobs, container deployment, environment split `local`/`staging`/`production`.
- Mandatory reads acknowledged: Python instructions, local-first dev baseline, quality gates baseline, observability baseline, AI-assisted change baseline.

## Context gathering

- Listed repository root: `Makefile`, `scripts/init.mk`, `.tool-versions`, `.editorconfig` already present.
- Confirmed `uv` and `python 3.13` declared in `.tool-versions`.
- Read `.github/instructions/templates/pyproject.toml` as the starting point for the new `pyproject.toml`.
- No existing `src/app/`, `tests/`, or ASGI entrypoint - clean greenfield.

## Execution

1. Wrote `pyproject.toml` from the template; set `project.name = "payments-api"`, `requires-python = ">=3.13"`; added runtime deps `fastapi`, `uvicorn[standard]`, `pydantic-settings`, `httpx`; dev group: `ruff`, `mypy`, `pytest`, `pytest-asyncio`, `httpx[testing]`.
2. Pinned `.python-version` to `3.13`.
3. Generated the `src/app/` layout: `main.py`, `api/v1/routes/`, `api/v1/schemas/`, `core/{config.py,logging.py,observability.py}`, `services/`, `adapters/`, `health.py`.
4. `core/config.py` exposes a `Settings` class using `pydantic-settings`, with separate `.env`, `.env.staging`, `.env.production` loaders selected by `APP_ENV`.
5. `core/logging.py` configures structured JSON logging; `core/observability.py` wires a request-ID middleware and `/healthz` + `/readyz` endpoints (the latter pings the database via the adapter).
6. `main.py` keeps the ASGI entrypoint thin: builds settings, configures logging, mounts the v1 router, registers middleware, and exposes the health router.
7. Added an `httpx.AsyncClient` factory in `adapters/http_client.py` with explicit timeouts and connection limits; documented retry expectations in `adapters/README.md`.
8. Wrote `tests/test_health.py` (TDD: written first), `tests/test_main.py` (smoke import), and `tests/conftest.py` providing an `httpx.AsyncClient` against the ASGI app.
9. Updated `Makefile` with `format`, `lint`, `typecheck`, `test`, `check` targets wired to `uv run ruff`, `uv run mypy`, `uv run pytest`, plus a `make startup-check` that imports the app and instantiates settings.
10. Ran `uv sync` to produce `uv.lock`.

## Output artefacts

- `pyproject.toml`, `uv.lock`, `.python-version`
- `src/app/main.py`, `health.py`
- `src/app/api/v1/__init__.py`, `routes/__init__.py`, `schemas/__init__.py`
- `src/app/core/{config.py,logging.py,observability.py}`
- `src/app/services/__init__.py`
- `src/app/adapters/{__init__.py,http_client.py,README.md}`
- `tests/{conftest.py,test_health.py,test_main.py}`
- `Makefile` updated with Python quality-gate targets and `startup-check`

## Validation evidence

- `make startup-check` → app imports and settings load without error.
- `make lint` → ruff clean, markdownlint clean.
- `make typecheck` → mypy clean.
- `make test` → 3 passed (health × 2, smoke × 1).
- `make scan-secrets` → no leaks reported.

## Final assistant response

> Scaffolded the `payments-api` FastAPI service. The `src/app/` layout includes a v1 router skeleton, structured logging, request-ID middleware, `/healthz` and `/readyz` endpoints, and an `httpx.AsyncClient` factory with explicit timeouts. Tests were written first and pass. Quality gates (ruff, mypy, pytest, startup-check) are all green. Next steps: add the first domain router under `api/v1/routes/`, and decide on secrets management for staging and production.

## Notes and follow-ups

- Background jobs were deliberately omitted; revisit when the first asynchronous workload is identified.
- Database connection pooling parameters should be tuned per deployment target before going live.
- Container image build is out of scope here - combine with the `repository-template` Docker capability when ready.
