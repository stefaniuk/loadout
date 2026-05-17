---
applyTo: "{**/Dockerfile,**/Dockerfile.*,**/compose.yaml,**/compose.*.yaml,**/docker-compose.yaml,**/docker-compose.*.yaml}"
description: "Dockerfile Engineering Instructions (container image development)"
---

# Dockerfile Engineering Instructions (container image development) 🐳

These instructions define the default engineering approach for writing **production-grade Dockerfiles** and **Docker Compose files for development**.

They must remain applicable to:

- Application container images
- Base/foundation images
- Tool wrapper images
- Multi-stage build images
- Development and CI/CD images
- Docker Compose multi-service development environments

They are **non-negotiable** unless an exception is explicitly documented (with rationale and expiry) in an ADR/decision record.

**Cross-references.** For Makefile orchestration conventions that build Docker images, see [makefile.instructions.md](./makefile.instructions.md). For shell scripts that wrap Docker commands, see [shell.instructions.md](./shell.instructions.md). This file focuses on Dockerfile patterns and Docker Compose for development.

**Identifier scheme.** Every normative rule carries a unique tag in the form `[DF-<prefix>-NNN]`, where the prefix maps to the containing section (for example `QR` for Quick Reference, `STR` for Structure, `FROM` for Base Image, `ARG` for Build Arguments, `ENV` for Environment Variables, `RUN` for Run Instructions, `COPY` for Copy Instructions, `META` for Metadata, `SEC` for Security, `OPT` for Optimisation, `CMP` for Compose). Use these identifiers when referencing, planning, or validating requirements.

---

## 0. Quick reference (apply first) 🧠

This section exists so humans and AI assistants can reliably apply the most important rules even when context is tight.

- [DF-QR-001] **Pin base image versions**: never use `latest`; pin to specific version with digest where possible ([DF-FROM-001], [DF-FROM-002]).
- [DF-QR-002] **Instruction order**: `FROM` → `ARG` → `ENV` → `RUN` (install) → `COPY` → `RUN` (configure) → `VOLUME` → `EXPOSE` → `WORKDIR` → `USER` → `CMD`/`ENTRYPOINT` → Metadata ([DF-STR-001]).
- [DF-QR-003] **Multi-line RUN with `set -ex`**: start RUN blocks with `set -ex` or `set -ex;` for debugging and fail-fast behaviour ([DF-RUN-001], [DF-RUN-002]).
- [DF-QR-004] **Build dependencies pattern**: define, install, use, then purge build dependencies in a single RUN layer ([DF-RUN-004]–[DF-RUN-006]).
- [DF-QR-005] **Clean up in every RUN**: remove temp files, package manager caches, and build artefacts at the end of each RUN ([DF-RUN-007]).
- [DF-QR-006] **Metadata at the end**: place OCI-compliant LABEL instructions at the very end of the Dockerfile ([DF-META-001]–[DF-META-003]).
- [DF-QR-007] **Use `.tool-versions` for pinning**: define image versions in `.tool-versions` for reproducibility ([DF-FROM-003]).
- [DF-QR-008] **Lint with hadolint**: all Dockerfiles must pass hadolint with no errors or warnings ([DF-QG-001]).
- [DF-QR-009] **Non-root user**: run containers as non-root where possible ([DF-SEC-001]).
- [DF-QR-010] **Minimal layers**: combine related commands to reduce layer count and image size ([DF-OPT-001]).
- [DF-QR-011] **Docker Compose for development**: use `compose.yaml` with healthchecks, secrets, custom networks, and Compose Watch for hot-reload ([DF-CMP-001]–[DF-CMP-030]).
- [DF-QR-012] **Integrity and least privilege**: verify downloaded artefacts and lock down ownership/permissions at build time ([DF-SEC-009]–[DF-SEC-011]).

---

## 1. Operating principles 🧭

These principles extend [constitution.md §3](../../.specify/memory/constitution.md#3-core-principles-non-negotiable).

- [DF-OP-001] Treat Dockerfiles as **reproducible build specifications**: the same Dockerfile must produce functionally identical images.
- [DF-OP-002] Prefer **explicit, version-pinned dependencies** over implicit or floating versions.
- [DF-OP-003] Design for **determinism**: avoid commands that produce non-deterministic output (timestamps, random data) where possible.
- [DF-OP-004] Optimise for **layer caching**: order instructions from least to most frequently changing.
- [DF-OP-005] **Fail fast and fail loud**: use `set -e` in RUN commands; do not mask failures.
- [DF-OP-006] Optimise for **image size, security, and build speed**, in that priority order.
- [DF-OP-007] Images must be **self-documenting** through proper labelling and metadata.

---

## 2. Dockerfile structure (non-negotiable) 📋

### 2.1 Canonical instruction order

- [DF-STR-001] Dockerfiles must follow this canonical instruction order:
  1. `FROM` — base image specification
  2. `ARG` — build-time arguments (proxies, versions, configuration)
  3. `ENV` — environment variables (versions, paths, configuration)
  4. `RUN` — package installation and system setup
  5. `COPY`/`ADD` — application files and assets
  6. `RUN` — application-specific configuration
  7. `VOLUME` — mount points (if applicable)
  8. `EXPOSE` — network ports (if applicable)
  9. `WORKDIR` — working directory (if applicable)
  10. `USER` — non-root user (if applicable)
  11. `CMD`/`ENTRYPOINT` — container startup command
  12. Metadata section (ARG + LABEL block)

- [DF-STR-002] Use section comments to visually separate logical blocks:

  ```dockerfile
  # === Dependencies ===========================================================

  # === Application ============================================================

  # === Metadata ===============================================================
  ```

- [DF-STR-003] Group related instructions together; do not scatter similar concerns.

### 2.2 File naming conventions

- [DF-STR-004] The primary Dockerfile must be named `Dockerfile` (no extension).
- [DF-STR-005] Use `Dockerfile.<variant>` for variant images (for example `Dockerfile.dev`, `Dockerfile.test`).
- [DF-STR-006] The build tooling generates `Dockerfile.effective` with version substitutions and metadata appended — do not edit this file manually.
- [DF-STR-007] Use `Dockerfile.dockerignore` (or `.dockerignore`) to exclude files from the build context.

---

## 3. Base image selection (`FROM`) 🏗️

### 3.1 Version pinning (non-negotiable)

- [DF-FROM-001] Never use `:latest` tag. Always pin to a specific version:

  ```dockerfile
  # ❌ Bad - floating tag
  FROM python:latest

  # ✅ Good - pinned version
  FROM python:3.12.1-alpine3.19
  ```

- [DF-FROM-002] Where security is critical, pin to digest as well as tag:

  ```dockerfile
  FROM python:3.12.1-alpine3.19@sha256:abc123...
  ```

- [DF-FROM-003] Define base image versions in the repository's `.tool-versions` file using the format:

  ```plaintext
  # docker/python 3.12.1-alpine3.19@sha256:abc123...
  ```

  The build tooling will substitute `:latest` references with pinned versions from this file.

### 3.2 Base image selection criteria

- [DF-FROM-004] Prefer minimal base images (Alpine, distroless, scratch) unless specific dependencies require a full distribution.
- [DF-FROM-005] Prefer official images from trusted registries (Docker Hub official, `ghcr.io`, `mcr.microsoft.com`).
- [DF-FROM-006] Document the rationale for base image choice in comments if non-obvious.

### 3.3 Multi-stage builds

- [DF-FROM-007] Use multi-stage builds to separate build-time and runtime dependencies:

  ```dockerfile
  FROM golang:1.21 AS builder
  # Build steps...

  FROM alpine:3.19
  COPY --from=builder /app/binary /usr/local/bin/
  ```

- [DF-FROM-008] Name build stages with meaningful aliases using `AS`:

  ```dockerfile
  FROM node:20-alpine AS deps
  FROM node:20-alpine AS builder
  FROM node:20-alpine AS runner
  ```

---

## 4. Build arguments (`ARG`) 🔧

### 4.1 Common build arguments

- [DF-ARG-001] Define build-time arguments immediately after `FROM`:

  ```dockerfile
  FROM python:3.12-alpine

  ARG APT_PROXY
  ARG APT_PROXY_SSL
  ```

- [DF-ARG-002] Use `ARG` for values that may change between builds but should not persist at runtime:
  - Package manager proxies (`APT_PROXY`, `APT_PROXY_SSL`)
  - Build-time feature flags
  - Version overrides

- [DF-ARG-003] Document the purpose of each ARG with inline comments when not self-evident:

  ```dockerfile
  ARG APT_PROXY  # HTTP proxy for apt package downloads
  ```

### 4.2 Proxy pattern

- [DF-ARG-004] Support optional proxy configuration for restricted build environments:

  ```dockerfile
  ARG APT_PROXY
  ARG APT_PROXY_SSL

  RUN set -ex; \
      if [ -n "$APT_PROXY" ]; then \
        echo "Acquire::http { Proxy \"http://${APT_PROXY}\"; };" > /etc/apt/apt.conf.d/00proxy; \
      fi; \
      if [ -n "$APT_PROXY_SSL" ]; then \
        echo "Acquire::https { Proxy \"https://${APT_PROXY_SSL}\"; };" >> /etc/apt/apt.conf.d/00proxy; \
      fi; \
      # ... package installation ...
      rm -f /etc/apt/apt.conf.d/00proxy
  ```

- [DF-ARG-005] Always remove proxy configuration at the end of the RUN block to avoid leaking into the final image.

---

## 5. Environment variables (`ENV`) 🌍

### 5.1 Version variables

- [DF-ENV-001] Define version numbers as environment variables for visibility and override capability:

  ```dockerfile
  ENV PYTHON_VERSION="3.12.1" \
      PYTHON_PIP_VERSION="24.0" \
      NODE_VERSION="20.11.0"
  ```

- [DF-ENV-002] Use the multi-line backslash format for multiple related variables:

  ```dockerfile
  ENV PYTHON_VERSION="3.12.1" \
      PYTHON_DOWNLOAD_URL="https://www.python.org/ftp/python" \
      PYTHON_PIP_VERSION="24.0" \
      PYTHON_PIP_DOWNLOAD_URL="https://bootstrap.pypa.io/get-pip.py"
  ```

### 5.2 Naming conventions

- [DF-ENV-003] Use UPPERCASE with underscores for environment variable names.
- [DF-ENV-004] Prefix related variables with a common namespace (for example `PYTHON_`, `NODE_`, `APP_`).
- [DF-ENV-005] Quote values containing special characters or spaces.

### 5.3 Runtime vs build-time

- [DF-ENV-006] Use `ENV` for values that must persist at runtime.
- [DF-ENV-007] Use `ARG` for values only needed during build. Convert to `ENV` only if runtime access is required:

  ```dockerfile
  ARG BUILD_VERSION
  ENV APP_VERSION=$BUILD_VERSION
  ```

---

## 6. Run instructions (`RUN`) 🏃

### 6.1 Shell execution model (non-negotiable)

- [DF-RUN-001] Start RUN blocks with `set -ex` for debugging and fail-fast behaviour:

  ```dockerfile
  RUN set -ex; \
      command1; \
      command2; \
      command3
  ```

- [DF-RUN-002] Use semicolons and backslashes for multi-line commands:

  ```dockerfile
  RUN set -ex; \
      \
      apt-get update; \
      apt-get install -y --no-install-recommends \
        package1 \
        package2 \
      ; \
      rm -rf /var/lib/apt/lists/*
  ```

- [DF-RUN-003] Use `&&` for command chaining only when `set -e` is not used. Prefer `set -ex` with semicolons.

### 6.2 Build dependencies pattern

- [DF-RUN-004] Define build dependencies as a shell variable at the start of the RUN block:

  ```dockerfile
  RUN set -ex; \
      \
      buildDependencies=" \
        gcc \
        libffi-dev \
        libssl-dev \
        make \
      "; \
      apt-get update; \
      apt-get install -y --no-install-recommends $buildDependencies; \
      # ... build steps ...
      apt-get purge -y --auto-remove $buildDependencies
  ```

- [DF-RUN-005] Separate build dependencies from runtime dependencies. Only purge build dependencies.
- [DF-RUN-006] Install build dependencies, perform build, and purge in a single RUN to minimise layer size.

### 6.3 Package manager patterns

- [DF-RUN-007] For APT (Debian/Ubuntu):

  ```dockerfile
  RUN set -ex; \
      apt-get update; \
      apt-get install -y --no-install-recommends \
        package1 \
        package2 \
      ; \
      rm -rf /var/lib/apt/lists/*
  ```

- [DF-RUN-008] For APK (Alpine):

  ```dockerfile
  RUN set -ex; \
      apk add --no-cache \
        package1 \
        package2
  ```

- [DF-RUN-009] For pip (Python):

  ```dockerfile
  RUN set -ex; \
      pip install --no-cache-dir \
        package1==1.0.0 \
        package2==2.0.0
  ```

### 6.4 Cleanup requirements (non-negotiable)

- [DF-RUN-010] Remove all temporary files at the end of each RUN block:

  ```dockerfile
  RUN set -ex; \
      # ... installation steps ...
      rm -rf \
        /tmp/* \
        /var/tmp/* \
        /var/lib/apt/lists/* \
        /var/cache/apt/*
  ```

- [DF-RUN-011] Remove proxy configuration files if set during build:

  ```dockerfile
  rm -f /etc/apt/apt.conf.d/00proxy
  ```

- [DF-RUN-012] Remove source code and build artefacts not needed at runtime:

  ```dockerfile
  rm -rf /usr/src/python
  ```

### 6.5 Visual formatting

- [DF-RUN-013] Use blank continuation lines (`\`) to visually separate logical sections within a RUN block:

  ```dockerfile
  RUN set -ex; \
      \
      # Install build dependencies
      buildDependencies="..."; \
      apt-get install -y $buildDependencies; \
      \
      # Download and build
      curl -L "$URL" -o source.tar.gz; \
      tar -xf source.tar.gz; \
      ./configure && make && make install; \
      \
      # Cleanup
      apt-get purge -y --auto-remove $buildDependencies; \
      rm -rf /tmp/*
  ```

---

## 7. Copy and add instructions (`COPY`/`ADD`) 📁

### 7.1 Prefer COPY over ADD

- [DF-COPY-001] Use `COPY` for local files. Use `ADD` only for URL downloads or auto-extracting archives.
- [DF-COPY-002] Be explicit about source and destination paths:

  ```dockerfile
  COPY assets/ /app/assets/
  COPY --chown=appuser:appgroup config.yaml /app/
  ```

### 7.2 Ordering for cache efficiency

- [DF-COPY-003] Copy dependency manifests before source code to maximise cache hits:

  ```dockerfile
  COPY package.json package-lock.json ./
  RUN npm ci

  COPY . .
  RUN npm run build
  ```

- [DF-COPY-004] Copy frequently changing files last.

### 7.3 Ownership and permissions

- [DF-COPY-005] Use `--chown` to set ownership during copy rather than a separate `RUN chown`:

  ```dockerfile
  COPY --chown=1000:1000 app/ /app/
  ```

---

## 8. Container configuration (`VOLUME`, `EXPOSE`, `USER`, `CMD`) ⚙️

### 8.1 Volumes

- [DF-CFG-001] Declare mount points with `VOLUME` for persistent data:

  ```dockerfile
  VOLUME [ "/var/lib/data", "/var/log/app" ]
  ```

- [DF-CFG-002] Place `VOLUME` after installation but before `CMD`.

### 8.2 Port exposure

- [DF-CFG-003] Document exposed ports with `EXPOSE`:

  ```dockerfile
  EXPOSE 8080 8443 9090
  ```

- [DF-CFG-004] Add comments for non-obvious port assignments:

  ```dockerfile
  EXPOSE 1935 # RTMP
  EXPOSE 8080 # HTTP
  EXPOSE 8443 # HTTPS
  ```

### 8.3 Non-root user

- [DF-CFG-005] Create and switch to a non-root user before `CMD`:

  ```dockerfile
  RUN addgroup --system appgroup && \
      adduser --system --ingroup appgroup appuser
  USER appuser
  ```

- [DF-CFG-006] Use numeric UID/GID for better compatibility with orchestrators:

  ```dockerfile
  USER 1000:1000
  ```

### 8.4 Entry point and command

- [DF-CFG-007] Use exec form (JSON array) for `CMD` and `ENTRYPOINT`:

  ```dockerfile
  # ✅ Good - exec form
  CMD [ "nginx", "-g", "daemon off;" ]

  # ❌ Bad - shell form (runs via /bin/sh -c)
  CMD nginx -g daemon off;
  ```

- [DF-CFG-008] Use `ENTRYPOINT` for the main executable and `CMD` for default arguments:

  ```dockerfile
  ENTRYPOINT [ "python" ]
  CMD [ "app.py" ]
  ```

---

## 9. Metadata and labels (`LABEL`) 🏷️

### 9.1 OCI-compliant labels (non-negotiable)

- [DF-META-001] Place the metadata section at the **very end** of the Dockerfile, after all other instructions.

- [DF-META-002] Use section comment to clearly mark the metadata block:

  ```dockerfile
  # === Metadata ===============================================================
  ```

- [DF-META-003] Use OCI Image Spec labels (`org.opencontainers.image.*`). The build tooling appends the standard metadata block from `scripts/docker/Dockerfile.metadata`:

  ```dockerfile
  ARG IMAGE
  ARG TITLE
  ARG DESCRIPTION
  ARG LICENCE
  ARG GIT_URL
  ARG GIT_BRANCH
  ARG GIT_COMMIT_HASH
  ARG BUILD_DATE
  ARG BUILD_VERSION
  LABEL \
      org.opencontainers.image.base.name=$IMAGE \
      org.opencontainers.image.title="$TITLE" \
      org.opencontainers.image.description="$DESCRIPTION" \
      org.opencontainers.image.licenses="$LICENCE" \
      org.opencontainers.image.url=$GIT_URL \
      org.opencontainers.image.ref.name=$GIT_BRANCH \
      org.opencontainers.image.revision=$GIT_COMMIT_HASH \
      org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.version=$BUILD_VERSION
  ```

- [DF-META-004] Do not manually add the metadata block to Dockerfiles — it is appended automatically during the `docker-bake-dockerfile` / `docker-build` lifecycle.

### 9.2 Legacy label schema (deprecated)

- [DF-META-005] For legacy compatibility, the `org.label-schema.*` format may be encountered:

  ```dockerfile
  LABEL \
      org.label-schema.name=$IMAGE \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.version=$VERSION \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url=$VCS_URL \
      org.label-schema.schema-version="1.0"
  ```

  Prefer the OCI format for new images.

---

## 10. Security best practices 🔐

### 10.1 Non-root execution

- [DF-SEC-001] Run containers as non-root user by default. See [DF-CFG-005], [DF-CFG-006].

### 10.2 Minimal attack surface

- [DF-SEC-002] Remove package manager caches and unnecessary tools after installation.
- [DF-SEC-003] Do not install debugging tools or shells in production images unless required.
- [DF-SEC-004] Use multi-stage builds to exclude build tools from final image.

### 10.3 Secrets handling

- [DF-SEC-005] Never embed secrets (passwords, API keys, tokens) in Dockerfiles.
- [DF-SEC-006] Use build secrets or runtime injection for sensitive values:

  ```dockerfile
  # ❌ Bad - secret in image
  ENV API_KEY=secret123

  # ✅ Good - injected at runtime
  # docker run -e API_KEY=secret123 ...
  ```

- [DF-SEC-007] Use Docker BuildKit secrets for build-time secrets:

  ```dockerfile
  RUN --mount=type=secret,id=npmrc,target=/root/.npmrc npm ci
  ```

### 10.4 Image signing and verification

- [DF-SEC-008] Pin base images to digest to prevent supply chain attacks. See [DF-FROM-002].

### 10.5 Artifact integrity and permissions hardening

- [DF-SEC-009] Verify downloaded artefacts with checksums or signatures; avoid `curl | sh` or unverified remote installs.
- [DF-SEC-010] Use `COPY --chown` (and `--chmod` when supported) to enforce least privilege at build time instead of post-copy `chown`/`chmod`.
- [DF-SEC-011] Keep writable paths explicit and minimal; avoid world-writable permissions.

### 10.6 Vulnerability scanning and SBOMs (free tooling)

- [DF-SEC-012] Scan built images with Grype in CI; fail on critical/high vulnerabilities unless an ADR documents the exception.
- [DF-SEC-013] Generate an SBOM using Syft for release images and store it alongside build artefacts.

---

## 11. Optimisation guidelines 🚀

### 11.1 Layer optimisation

- [DF-OPT-001] Combine related commands into single RUN instructions to reduce layers.
- [DF-OPT-002] Order instructions from least to most frequently changing for cache efficiency.
- [DF-OPT-003] Use `.dockerignore` to exclude unnecessary files from build context.

### 11.2 Image size optimisation

- [DF-OPT-004] Use Alpine or distroless base images where compatible.
- [DF-OPT-005] Remove documentation, man pages, and locale data if not needed:

  ```dockerfile
  RUN rm -rf /usr/share/doc /usr/share/man /usr/share/locale
  ```

- [DF-OPT-006] Use `--no-install-recommends` for APT to avoid unnecessary packages.

### 11.3 Build speed optimisation

- [DF-OPT-007] Leverage build cache by ordering COPY instructions appropriately. See [DF-COPY-003].
- [DF-OPT-008] Use BuildKit for parallel stage execution and improved caching.

---

## 12. Mandatory quality gates ✅

Per [constitution.md §7.8](../../.specify/memory/constitution.md#78-mandatory-local-quality-gates), after making **any** change to Dockerfiles, you must run the repository's **canonical** quality gates.

### 12.1 Hadolint (mandatory)

- [DF-QG-001] All Dockerfiles must pass hadolint with no errors or warnings:

  ```bash
  make docker-lint
  ```

- [DF-QG-002] Use directive comments to disable specific warnings only when justified:

  ```dockerfile
  # hadolint ignore=DL3008
  RUN apt-get install -y package
  ```

- [DF-QG-003] Do not use `# hadolint ignore=DL3007` to ignore the `:latest` tag warning — pin your versions instead.

### 12.2 Iteration requirement

- [DF-QG-004] Follow the shared [quality gates baseline](./includes/quality-gates-baseline.include.md) for iteration and warning handling rules.
- [DF-QG-005] Follow the shared [quality gates baseline](./includes/quality-gates-baseline.include.md) for command selection and equivalents.

---

## 13. Build lifecycle integration 🔄

The Docker make targets define the image development lifecycle:

### 13.1 Development targets

- [DF-LC-001] `make docker-bake-dockerfile` — generates `Dockerfile.effective` with version substitutions and appended metadata.
- [DF-LC-002] `make docker-lint` — runs hadolint over `Dockerfile.effective` (depends on `docker-bake-dockerfile`).
- [DF-LC-003] `make docker-build` — builds the image (depends on `docker-lint`).
- [DF-LC-004] `make docker-run` — runs the built image locally.
- [DF-LC-005] `make docker-push` — pushes the image to the registry.

### 13.2 Supporting files

- [DF-LC-006] `VERSION` — contains semantic version(s) for the image (one per line).
- [DF-LC-007] `.tool-versions` — contains pinned versions for base images and tools.
- [DF-LC-008] `Dockerfile.dockerignore` — excludes files from build context.

---

## 14. Anti-patterns (recognise and avoid) 🚫

These patterns cause recurring issues in Dockerfiles. Avoid them unless an ADR documents a justified exception.

- [DF-ANT-001] **Using `:latest` tag** — non-reproducible builds; always pin versions.
- [DF-ANT-002] **Multiple RUN for related commands** — bloated images; combine into single RUN.
- [DF-ANT-003] **Not cleaning up in the same layer** — bloated images; purge build deps and caches in same RUN.
- [DF-ANT-004] **COPY before RUN install** — cache invalidation; copy dependency manifests first.
- [DF-ANT-005] **Running as root** — security risk; use non-root USER.
- [DF-ANT-006] **Secrets in ENV or ARG** — secrets baked into image layers; use runtime injection or BuildKit secrets.
- [DF-ANT-007] **Shell form CMD** — signal handling issues; use exec form (JSON array).
- [DF-ANT-008] **ADD for local files** — unnecessary complexity; use COPY unless extracting archives.
- [DF-ANT-009] **Missing .dockerignore** — slow builds, bloated context; always include.
- [DF-ANT-010] **Ignoring hadolint warnings** — quality debt; fix or document exception.
- [DF-ANT-011] **Manual metadata block** — inconsistent labels; let build tooling append metadata.
- [DF-ANT-012] **Not using `set -e` in RUN** — silent failures; always use `set -ex`.

---

## 15. Docker Compose for development 🐙

Docker Compose simplifies multi-container development by defining services, networks, and volumes in a single YAML file. Use Compose primarily for **local development and testing**; for production, prefer orchestration platforms (e.g. Kubernetes-like cloud managed service) or apply production-specific overrides.

**Cross-reference.** For full Compose file syntax, see [Compose file reference](https://docs.docker.com/reference/compose-file/). For the template, see [templates/compose.yaml.template](./templates/compose.yaml.template).

### 15.1 File naming and structure

- [DF-CMP-001] Name the primary file `compose.yaml` (preferred) or `docker-compose.yaml` (legacy).
- [DF-CMP-002] Use override files for environment-specific config: `compose.override.yaml` (auto-merged), `compose.prod.yaml`, `compose.test.yaml`.
- [DF-CMP-003] Do not include a top-level `version` key — the modern Compose Specification does not require it.
- [DF-CMP-004] Optionally set `name` at the top level to define the project name explicitly.

### 15.2 Service definition best practices

- [DF-CMP-005] Pin image versions; never use `:latest` in Compose (mirrors [DF-FROM-001]).
- [DF-CMP-006] Prefer `build.target` to select a multi-stage Dockerfile stage (for example `target: development`).
- [DF-CMP-007] Use `restart: unless-stopped` for resilience in development; use `restart: always` in production overrides.
- [DF-CMP-008] Use `depends_on` with conditions (`service_healthy`, `service_started`) to control startup order:

```yaml
depends_on:
  db:
    condition: service_healthy
    restart: true
```

- [DF-CMP-009] Define `healthcheck` for each service to enable reliable dependency ordering:

```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 30s
```

### 15.3 Networking

- [DF-CMP-010] Use custom networks to isolate service tiers (for example `frontend`, `backend`).
- [DF-CMP-011] Reference services by their service name (DNS); avoid hard-coded IPs.
- [DF-CMP-012] Bind host ports to `127.0.0.1` for development security:

```yaml
ports:
  - "127.0.0.1:5432:5432"
```

### 15.4 Volumes and data persistence

- [DF-CMP-013] Use named volumes for persistent data; define them in the top-level `volumes` key.
- [DF-CMP-014] Use bind mounts only for development source code sync (prefer read-only `:ro` where possible).
- [DF-CMP-015] Do not bind mount `node_modules/`, `__pycache__/`, or other platform-specific artefacts.

### 15.5 Secrets handling (non-negotiable)

- [DF-CMP-016] Use the top-level `secrets` element for sensitive data; never embed secrets in `environment`:

```yaml
secrets:
  db_password:
    file: ./secrets/db_password.txt

services:
  db:
    secrets:
      - db_password
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
```

- [DF-CMP-017] Use `_FILE` environment variable convention (supported by many official images) to load secrets at runtime.
- [DF-CMP-018] Add secret files to `.gitignore`; never commit plaintext secrets.

### 15.6 Environment variables

- [DF-CMP-019] Prefer `env_file` for non-sensitive, environment-specific config.
- [DF-CMP-020] Use `.env` for Compose variable interpolation (project name, ports, feature flags).
- [DF-CMP-021] Document all required environment variables in `.env.example` (committed) without values.

### 15.7 Profiles for optional services

- [DF-CMP-022] Use `profiles` to group optional or debug services:

```yaml
services:
  pgadmin:
    profiles:
      - debug
```

- [DF-CMP-023] Start profiles explicitly: `docker compose --profile debug up`.

### 15.8 Compose Watch for hot-reload development

- [DF-CMP-024] Use the `develop.watch` attribute for automatic sync and rebuild during development:

```yaml
develop:
  watch:
    - action: sync
      path: ./src
      target: /app/src
      ignore:
        - __pycache__/
    - action: rebuild
      path: pyproject.toml
```

- [DF-CMP-025] Use `action: sync` for source files with hot-reload frameworks.
- [DF-CMP-026] Use `action: rebuild` for dependency manifests (`package.json`, `pyproject.toml`).
- [DF-CMP-027] Use `action: sync+restart` for config files that require process restart.

### 15.9 Production considerations

- [DF-CMP-028] Create a separate `compose.prod.yaml` override that removes volume bindings, sets `restart: always`, and adjusts resource limits.
- [DF-CMP-029] Merge files for production: `docker compose -f compose.yaml -f compose.prod.yaml up -d`.
- [DF-CMP-030] For true production workloads, prefer a managed container platform.

### 15.10 Template

Use the template at [templates/compose.yaml.template](./templates/compose.yaml.template) when scaffolding new multi-service projects.

---

## 16. AI-assisted change expectations 🤖

Per [constitution.md §3.5](../../.specify/memory/constitution.md#35-ai-assisted-development-discipline--change-governance), when you create or modify Dockerfiles:

- [DF-AI-001] Follow the shared [AI change baseline](./includes/ai-assisted-change-baseline.include.md) for scope, quality, and governance.
- [DF-AI-002] Use the established patterns: instruction order, `set -ex`, build dependencies, cleanup.
- [DF-AI-003] Run `make docker-lint` and iterate until clean.

---

## 17. Dockerfile template 📝

Use the template at [templates/Dockerfile.template](./templates/Dockerfile.template) when creating new Dockerfiles.

---

> **Version**: 1.2.1
> **Last Amended**: 2026-01-18
