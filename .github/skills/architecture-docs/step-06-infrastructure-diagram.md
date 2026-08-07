# Step 06 - Infrastructure Diagram

Author cloud infrastructure diagrams in `draw.io` (one diagram per cloud provider), evidence-first.

## Goal

Create (or update) infrastructure diagrams at `docs/prompt-reports/infrastructure/`.

Also ensure they are linked from the architecture overview at `docs/prompt-reports/README.md`.

## Discovery (run before writing)

### A. Refresh what is already known

1. Re-read:
   - `docs/prompt-reports/repository-map.md`
   - `docs/prompt-reports/component-*.md`
   - `docs/prompt-reports/likec4/**`
2. Extract into working notes:
   - Deployable units and what they need at runtime (compute, storage, network, secrets)
   - Datastores and managed services already evidenced
   - Identity providers and external SaaS

### B. Locate infrastructure-as-code (evidence-driven)

Look for IaC and deployment artefacts:

1. Terraform (`*.tf`, modules, environments)
2. Helm charts and Kubernetes manifests
3. CloudFormation / AWS CDK
4. Azure Bicep / ARM templates
5. Pulumi
6. Serverless framework / SAM
7. Docker Compose (typically dev/test only - note as such)
8. CI/CD deployment workflows

Identify which cloud provider(s) are used. Common signals:

- AWS: `aws_*` Terraform resources, AWS SDK clients, `aws cli` in scripts
- Azure: `azurerm_*` resources, Azure SDK, `az cli`, Bicep
- GCP: `google_*` resources, GCP SDK, `gcloud cli`
- Multiple providers: model separately

## Steps

### 1) One diagram per cloud provider

For each cloud provider in use, create:

- `docs/prompt-reports/infrastructure/infra-{provider}.drawio` (editable source)
- `docs/prompt-reports/infrastructure/infra-{provider}.drawio.svg` (rendered export, committed)

Examples:

- `infra-aws.drawio` / `infra-aws.drawio.svg`
- `infra-azure.drawio` / `infra-azure.drawio.svg`

Use the **draw.io / diagrams.net** format. Both files must be committed so the diagram is renderable in the browser without tooling.

### 2) Use official cloud icon shapes

- For AWS, use the **AWS Icons** shape library (current set, e.g. "AWS19" or later).
- For Azure, use the **Azure** shape library.
- For GCP, use the **GCP** shape library.
- Use the most recent official icon set available in draw.io at the time of authoring.

Do not invent icons or substitute generic shapes when an official one exists.

### 3) Layout conventions

1. **Group by account/subscription/project** at the outermost level if multiple are in scope.
2. **Group by region** at the next level.
3. **Group by network** (VPC/VNet/Project network) at the next level.
4. **Group by availability zone / subnet** where it materially affects the architecture.
5. Place **external actors and external systems** outside the cloud boundary.
6. Place **identity providers** outside the cloud boundary unless they are cloud-native (e.g. AWS IAM Identity Center / Entra ID - these may be inside).
7. Use **clear left-to-right** or **top-to-bottom** flow. Pick one and stick to it.
8. Use **swimlanes** if the architecture spans multiple environments shown side-by-side (avoid if a single diagram becomes too dense - split instead).

### 4) Required elements (only if evidenced)

Model:

- **Compute** (containers/serverless/VMs/Kubernetes clusters/managed services)
- **Storage** (object stores, file shares, block storage)
- **Databases** (managed SQL/NoSQL/data warehouses)
- **Messaging** (queues, topics, event buses, streaming)
- **Networking** (load balancers, API gateways, CDNs, DNS, private endpoints, peering)
- **Security** (WAF, secrets manager, KMS, IAM/RBAC boundaries - at high level)
- **Observability** (metrics/logs/tracing services in use)
- **External SaaS** (third-party services this infrastructure depends on)

For each element, include in the icon label:

- Service name (cloud-native term)
- Resource name from IaC (short)
- One-line purpose (optional)

### 5) Required relationships (only if evidenced)

Draw arrows for:

- **Network ingress paths** (DNS → CDN → WAF → Load Balancer → Compute)
- **Compute → datastore** connections
- **Compute → managed service** connections (queue/cache/storage)
- **Outbound integrations** (compute → external SaaS)
- **Authentication flows** at high level (compute ↔ identity provider)
- **Cross-region/cross-account** boundaries with explicit annotations

Annotate arrows with:

- Protocol (HTTPS, TLS, TCP, AMQP, gRPC, etc.)
- Port (if non-standard)
- Direction (default: from initiator to target)

### 6) Annotations and legend

Include on the diagram:

- A **title** (system name + environment if scoped, e.g. "{System} – Production")
- A **legend** explaining colours, line styles, and any tags used
- A **source-of-truth note** listing the IaC paths the diagram is derived from (e.g. `/infra/terraform/`, `/charts/`, `/.github/workflows/deploy.yml`)
- A **revision date** (manual; updated whenever the diagram changes)

### 7) Evidence (mandatory)

In `docs/prompt-reports/infrastructure/README.md`:

1. For each cloud provider diagram, list the evidence:
   - IaC files and modules used to derive the diagram
   - Deployment workflows that provision/update these resources
   - Config keys / parameter files that supply environment-specific values
2. Where a resource is implied (e.g. "DNS is managed externally") but not in IaC, record:
   - **Unknown from code - confirm with platform team / external doc**

### 8) Update the architecture index

Update `docs/prompt-reports/README.md` with an **Infrastructure** section that:

- Links to each `infra-{provider}.drawio.svg` for inline rendering
- Links to the corresponding `.drawio` source for editing
- Links to `docs/prompt-reports/infrastructure/README.md` for evidence and notes

## Operating principles (must follow)

- **Evidence first** - every resource and connection on the diagram must trace back to IaC or deployment configuration.
- **Official icons** - use the cloud provider's official shape library; do not substitute.
- **One provider per diagram** - keep diagrams focused; if multiple clouds are involved, produce one diagram each plus a small inter-cloud overview if needed.
- **High-level, not exhaustive** - show architecturally significant resources; do not draw every IAM policy or every subnet unless they matter to the architecture.
- **Names match IaC** - use resource names that match the IaC so reviewers can grep.
- **Commit both source and SVG** - `.drawio` for editing, `.drawio.svg` for in-browser rendering.

## Common pitfalls (avoid)

- Drawing logical components (from the C4 Component view) on the infrastructure diagram - that's the wrong altitude
- Mixing providers in a single diagram
- Showing every subnet, every NAT gateway, every route table - keep it readable
- Inventing managed services that the code does not actually use
- Forgetting to export and commit the SVG (diagram becomes invisible in the browser)
- Letting the diagram drift silently from IaC - update it whenever the IaC changes materially
