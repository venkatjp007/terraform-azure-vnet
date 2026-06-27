# Opella DevOps Challenge — Azure Infrastructure with Terraform

Reusable, secure, multi-environment Azure infrastructure provisioned with
Terraform and deployed through a GitHub Actions pipeline.

## What this deploys

Per environment (Dev, Prod):

- A **resource group**.
- A **Virtual Network** with two subnets (`app`, `data`) via the reusable
  [`modules/vnet`](./modules/vnet) module, with optional per-subnet NSGs.
- A **Linux VM** (`Standard_B1s`, SSH-key auth) in the `app` subnet —
  toggleable via `enable_vm`.
- A **Storage Account + private Blob container** (HTTPS-only, TLS1.2, no public
  blob access) — toggleable via `enable_storage`.

> Dev and Prod ship the **same** toggles (`enable_vm = true`,
> `enable_storage = true`) so the environments stay parallel. A toggle set to
> `false` removes that resource from the plan entirely (it's `count`-gated).

## Repository layout

```
modules/
  vnet/          # Reusable VNET + subnets + optional NSGs (the core module)
  stack/         # Environment composition: RG + vnet module + VM + storage
environments/
  dev/           # Dev wiring + dev.tfvars + backend (state key: dev)
  prod/          # Prod wiring + prod.tfvars + backend (state key: prod)
.github/workflows/terraform.yml   # CI/CD: validate, scan, test, plan, gated apply
docs/plan-dev.txt                 # Captured terraform plan output
```

The `stack` module exists so Dev and Prod share **one** composition and differ
only by `*.tfvars` — no copy-pasted resource bodies (DRY).

## Key design decisions

| Topic | Decision | Why |
|-------|----------|-----|
| Env isolation | Separate **Resource Group per env** (single subscription) | Free, clean lifecycle/RBAC; separate *subscriptions* noted as the production-grade boundary. |
| State | **Remote azurerm backend, one state key per env** | Blast-radius isolation + locking. |
| DRY | Variables + per-env `tfvars` + shared `stack` module | No duplicated literals. |
| Naming | `locals`: `<project>-<env>-<region>-<resource>` | Environment & region legible from any resource name. |
| Tagging | Central `common_tags` local merged onto every resource | Enforced via Azure Policy (deny-on-missing) in a real org; CI/tflint as a backstop. |
| Auth | GitHub Actions **OIDC** to Azure | No long-lived secrets in CI. |
| Security | Optional NSGs, secure storage defaults, SSH-key VM | "Secure by default" without leaving the free tier. |
| Flexibility | `enable_vm` / `enable_storage` toggles (`count`-gated) | A resource set to `false` is **absent** from the plan, not "present but empty"; envs stay uniform by default. |

### Resource Groups vs Subscriptions for environments

For this challenge each environment gets its **own Resource Group** within a
**single subscription** (`opella-dev-eus-rg`, `opella-prod-eus-rg`). A Resource
Group is a logical boundary that gives independent RBAC, a clear lifecycle
(deleting the RG removes everything in the environment), and clean cost/tag
filtering — all for free, which keeps us inside the Azure Free tier.

In a **production organization I would use separate subscriptions** for Prod vs
Non-Prod, because the subscription is the stronger boundary:

- **Billing & cost** — each subscription gets its own invoice and budget, so Prod
  spend is isolated and attributable.
- **Quota & limits** — Azure quotas (e.g. vCPU counts) are per-subscription, so a
  runaway Dev workload can't starve Prod of capacity.
- **Policy & governance** — Azure Policy and RBAC assign cleanly at the
  subscription scope, enabling different guardrails for Prod vs Dev.
- **Blast radius & security** — a compromised or misconfigured Dev subscription
  cannot touch Prod resources, identities, or quotas.

The trade-off is operational overhead (more subscriptions to manage), so the rule
of thumb is: **Resource Groups to separate workloads within a trust boundary,
Subscriptions to separate trust/billing/quota boundaries.** The code here is
subscription-agnostic — pointing an environment at a different subscription is
just a provider/backend configuration change, no module edits.

## Usage

Prerequisites: Terraform >= 1.5, Azure CLI logged in, and a storage account for
remote state.

```bash
# Format / validate / lint / scan / test
make fmt validate lint sec test

# Plan an environment (after configuring the backend + Azure creds)
cd environments/dev
terraform init \
  -backend-config="resource_group_name=tfstate-rg" \
  -backend-config="storage_account_name=opellatfstate" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=dev.terraform.tfstate"
terraform plan -var-file=dev.tfvars
```

> For a quick local plan without remote state, comment out the `backend` block
> in `environments/<env>/backend.tf` to fall back to local state.

## Tooling & code quality

| Tool | Purpose |
|------|---------|
| `terraform fmt` / `validate` | Formatting & correctness |
| `tflint` (+ azurerm ruleset) | Linting, naming, documented vars/outputs |
| `tfsec` | Static security scanning |
| `terraform-docs` | Auto-generated module docs (markers in `modules/vnet/README.md`) |
| `pre-commit` | Runs all of the above before each commit |
| `terraform test` | Native plan-time module tests (`modules/vnet/tests`) |

Install hooks with `pre-commit install`.

## CI/CD release lifecycle

1. Open a **PR** → `validate` job runs fmt, validate, tflint, tfsec, and module
   tests (no cloud creds).
2. `plan` job authenticates to Azure via OIDC and runs `terraform plan` for each
   environment; output is uploaded as an artifact (and can be posted to the PR).
3. Reviewer approves and **merges to `main`**.
4. `apply` job runs on push to `main`, gated behind a **GitHub Environment**
   (manual approval) per environment.

## Flexibility & roadmap

Environments must currently be **uniform** (good when dev is a faithful rehearsal
of prod) but should be able to diverge as the platform grows. The evolution path:

1. **Shipped — toggles.** `stack` exposes `enable_vm` / `enable_storage`
   (`count`-gated, default `true`). A toggle set to `false` produces **zero
   instances**, so the resource is *absent* from the plan — not "present but
   empty". Dev and Prod keep identical toggles to stay parallel.
2. **Next — `for_each` maps.** For "0..N of a resource type per environment",
   drive resources from a map in `*.tfvars` (e.g. `virtual_machines = {...}`), so
   an env declares exactly the instances it wants.
3. **At divergence — composition.** When environments genuinely differ in *shape*,
   retire the monolithic `stack` for **single-purpose modules** (`vnet`, `vm`,
   `storage`) plus a thin `foundation` module that owns naming + `common_tags`.
   Each environment's root becomes a **manifest** that includes only the modules
   it needs ("absent unless declared"); governance is preserved because every
   module takes a required `tags` input and Azure Policy enforces tags at the
   platform level. The trade-off: flexibility in exchange for enforced uniformity,
   so it's applied only when divergence is real.

## Documentation

| Doc | What it covers |
|-----|----------------|
| [`modules/vnet/README.md`](./modules/vnet/README.md) | VNET module usage + auto-generated terraform-docs table |
| [`docs/plan-dev.txt`](./docs/plan-dev.txt) | Captured `terraform plan` output for the dev environment |

## Notes for reviewers

- The VM SSH **private key** is exposed as a sensitive output for demo
  convenience only; in production it would come from Key Vault or a managed
  keypair and never touch state in plaintext.
- Prod can be kept **plan-only** to stay within the Azure Free tier — the
  `apply` job is gated and optional.
- `enable_vm` / `enable_storage` let an environment omit a resource without
  touching module code; both default to `true` so envs stay parallel.
- Run `make fmt validate test` to reproduce the validation (fmt clean, all dirs
  valid, 4/4 module tests pass).
