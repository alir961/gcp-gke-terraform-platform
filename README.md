# GCP Platform as Code: GKE, Cloud SQL and a Hardened API

The whole Google Cloud platform for a task-management API, written as code: networking, IAM, a private PostgreSQL database, an autoscaling Kubernetes cluster, DNS and HTTPS, monitoring, and the CI/CD that plans, applies and destroys it. There is a **dev** and a **prd** environment, each in its own GCP project with its own Terraform state.

## Highlights

- **Five Terraform stacks** (`bootstrap`, `iam`, `db`, `cluster`, `dns`) with separate GCS remote states per environment, so one stack can be planned or destroyed without touching the others
- **Private Cloud SQL**: PostgreSQL with no public IP, reachable only from the VPC through Service Networking. Automated backups. Credentials live in **Secret Manager** and reach the pods as a Kubernetes secret created by Terraform
- **Autoscaling on two levels**: a HorizontalPodAutoscaler on the API (up to 15 replicas at 60 % CPU in prd) and a GKE node pool that scales from 1 to 10 nodes
- **Hardened FastAPI service**: JWT authentication on every task route, Redis-backed rate limiting, correlation IDs in logs and responses, and a container that runs as a non-root user
- **Public HTTPS**: GKE Ingress with a static IP, a Google-managed certificate and a Cloud DNS record per environment
- **Monitoring**: kube-prometheus-stack (Prometheus, Grafana, Alertmanager) deployed by Terraform, with a ServiceMonitor for the API
- **Least-privilege IAM as code**: role bindings declared per principal. The CI service accounts get scoped roles instead of `roles/owner`
- **Keyless CI/CD**: GitHub Actions authenticates to GCP through Workload Identity Federation (OIDC), so no service-account key is stored anywhere

## Architecture

```
                    GitHub Actions ── OIDC (Workload Identity Federation) ──► GCP
                    plan on PR · apply on main · guarded manual destroy

 Internet ──► Cloud DNS ──► HTTPS Load Balancer (managed certificate, static IP)
                                    │
                    ┌───────────────▼──────────────── GKE cluster (VPC) ─┐
                    │  Ingress ──► tasks-api pods (HPA 1-15) ──► Redis   │
                    │                    │                               │
                    │  Prometheus · Grafana · Alertmanager               │
                    └────────────────────┼───────────────────────────────┘
                                         │ private IP only
                                 Cloud SQL PostgreSQL ◄── Secret Manager
```

| Stack | Creates |
|---|---|
| `terraform/bootstrap` | VPC network and subnet, storage bucket |
| `terraform/iam` | Project IAM bindings for users and service accounts |
| `terraform/db` | Cloud SQL PostgreSQL with private access, database, user, secrets in Secret Manager |
| `terraform/cluster` | GKE cluster and autoscaling node pool, namespaces, API secret, Helm releases (API + monitoring) |
| `terraform/dns` | DNS records pointing the domain to the ingress IP |

Per-environment values are in `terraform/environments/{dev,prd}` and `helm/tasks-api/values.{dev,prd}.yaml`.

## Repository layout

```
app/        FastAPI service: Dockerfile, OpenAPI spec, tests
helm/       tasks-api chart (deployment, HPA, ingress, certificate, RBAC, Redis) and monitoring values
terraform/  the five stacks and the per-environment tfvars and backends
scripts/    async load-test script, kubectl helper
.github/    plan, apply and destroy workflows
```

More detail: [Terraform guide](terraform/readme.md) · [Helm charts](helm/README.md) · [API](app/readme.md)

## CI/CD

| Workflow | Trigger | Steps |
|---|---|---|
| Terraform Plan | pull request to `main` | API tests, `terraform fmt` and `validate`, plan for dev and prd |
| Terraform Apply | push to `main`, or manual with `DEPLOY` typed in | API tests, namespace cleanup, apply dev then prd |
| Terraform Destroy | manual only, with `DESTROY` typed in | cleanup, destroy the chosen environment (bootstrap kept unless asked), final cleanup of namespaces and Cloud SQL |

Pre-commit hooks run `ruff`, `ruff-format`, `terraform fmt` and `terraform validate`.

The jobs that talk to GCP (cleanup, plan, apply) only run when the repository variable `GCP_DEPLOY_ENABLED` is `true`, with the Workload Identity secrets configured. Without it, CI still runs the API tests, formatting and validation.

## Run it

Locally, the API and its PostgreSQL run with Docker Compose:

```bash
cd app
docker compose up --build
pytest tests
```

On GCP, apply the stacks in order for one environment (the backend and tfvars files are in the repository):

```bash
for stack in bootstrap iam db cluster dns; do
  terraform -chdir=terraform/$stack init -backend-config=backends/backend-dev.hcl
  terraform -chdir=terraform/$stack apply -var-file=../environments/dev/$stack.tfvars
done
```

Load test once it is deployed:

```bash
python scripts/load_test.py --env dev --host https://<domain> --token <JWT> --duration 60 --concurrency 20
```
