# GCP Platform as Code: GKE, Cloud SQL and a Hardened API

The whole Google Cloud platform for a task-management API, written as code: networking, IAM, a private PostgreSQL database, an autoscaling Kubernetes cluster, DNS and HTTPS, monitoring, and the CI/CD that plans, applies and destroys it. There is a **dev** and a **prd** environment, each in its own GCP project with its own Terraform state.

## Highlights

- **Five Terraform stacks** (`bootstrap`, `iam`, `db`, `cluster`, `dns`) with separate GCS remote states per environment, so one stack can be planned or destroyed without touching the others
- **Private Cloud SQL**: PostgreSQL with no public IP, reachable only from the VPC through Service Networking. Automated backups. Credentials live in **Secret Manager** and reach the pods as a Kubernetes secret created by Terraform
- **Autoscaling on two levels**: a HorizontalPodAutoscaler on the API (up to 15 replicas at 60 % CPU in prd) and a GKE node pool that scales from 1 to 10 nodes
- **Hardened FastAPI service**: JWT authentication on every task route, Redis-backed rate limiting, correlation IDs in logs and responses, Prometheus metrics, and a container that runs as a fixed non-root UID
- **Public HTTPS**: GKE Ingress with a static IP, a Google-managed certificate and a Cloud DNS record per environment
- **Monitoring**: kube-prometheus-stack (Prometheus, Grafana, Alertmanager) deployed by Terraform, with a ServiceMonitor scraping the API's `/metrics`
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
| `terraform/bootstrap` | VPC network and subnet, versioned Terraform state bucket, Artifact Registry repository |
| `terraform/iam` | Project IAM bindings for users and service accounts |
| `terraform/db` | Cloud SQL PostgreSQL with private access, database, user, secrets in Secret Manager |
| `terraform/cluster` | GKE cluster with Workload Identity, autoscaling node pool on a least-privilege service account, namespaces, API secret, Helm releases (API + monitoring) |
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
| Terraform Apply | push to `main`, or manual with `DEPLOY` typed in | API tests, stuck-namespace cleanup, then per environment (dev, then prd): plan and apply the saved plan for `iam`, `bootstrap`, `db`, build and push the API image tagged with the commit SHA, plan and apply `cluster` and `dns` |
| Terraform Destroy | manual only, with `DESTROY` typed in | cleanup, destroy the chosen environment (bootstrap kept unless asked), final cleanup of namespaces and Cloud SQL |

Pre-commit hooks run `ruff`, `ruff-format`, `terraform fmt` and `terraform validate`.

The jobs that talk to GCP (cleanup, plan, apply) only run when the repository variable `GCP_DEPLOY_ENABLED` is `true`, with the Workload Identity secrets configured. Without it, CI still runs the API tests, formatting and validation.

## Supported platforms

| Task | Linux | macOS | Windows |
|---|---|---|---|
| Run the API locally (Docker Compose), API tests | Yes | Yes | Yes (Docker Desktop; activate the venv with `.venv\Scripts\activate`) |
| Deploy with Terraform by hand | Yes | Yes | Through **WSL 2** or Git Bash: the commands and `scripts/*.sh` are bash |
| CI/CD | GitHub Actions on `ubuntu-latest` | | |

## Requirements

**Run the API locally**

- Docker with the Compose plugin
- Python 3.11 or later with `venv`, for the tests and the load test (CI uses 3.11)
- Free ports 8080 (API), 5432 (PostgreSQL) and 6379 (Redis)

**Deploy to GCP**

- Two GCP projects (dev and prd) with billing enabled, and a Cloud DNS managed zone for your domain
- [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) (`gcloud`), logged in with `gcloud auth login` and `gcloud auth application-default login`
- [Terraform](https://developer.hashicorp.com/terraform/install) 1.5 or later (providers: google ~> 6.0, kubernetes ~> 2.38, helm ~> 3.0, downloaded by `terraform init`)
- Docker, to build and push the API image
- `kubectl` with the `gke-gcloud-auth-plugin` (`gcloud components install kubectl gke-gcloud-auth-plugin`), for `scripts/k8r.sh` and debugging. Helm itself is not needed: Terraform installs the charts
- Optional: `pre-commit` for the git hooks

## Run it locally

```bash
git clone https://github.com/alir961/gcp-gke-terraform-platform.git
cd gcp-gke-terraform-platform

docker compose -f app/docker-compose.yml up --build -d   # API, PostgreSQL 16 and Redis 7; API on http://localhost:8080
curl http://localhost:8080/status                        # {"status":"ok","env":"dev"}

python3 -m venv .venv && source .venv/bin/activate
pip install -r app/requirements.txt
python -m pytest app/tests                               # from the repository root, no database needed
```

Every route except `/status` and `/metrics` needs a JWT signed with `SECRET_KEY` (`DevSecretKey` in Compose). The [API guide](app/readme.md#-quick-example) shows how to create one and call the API, and how to run it without Docker. `docker compose -f app/docker-compose.yml down -v` stops it and deletes the database.

## Deploy to GCP

The repository contains placeholder values: replace them with yours before the first run.

| Placeholder | Where | Replace with |
|---|---|---|
| `example-project-dev`, `example-project-prd` | `terraform/environments/*/*.tfvars`, `terraform/*/backends/*.hcl`, `helm/tasks-api/values.*.yaml`, `scripts/k8r.sh`, and the prd test in `terraform/db/main.tf` | your GCP project IDs |
| `example-project-*-tfstate` | backends and tfvars | your state bucket names |
| `example-project.com`, `example-project-com` | `dns.tfvars`, Helm values, `scripts/load_test.py` | your domain and Cloud DNS zone name |
| `*@example.com`, `XXXXXX-XXXXXX-XXXXXX` | `iam.tfvars` | your team's accounts and billing account |

`grep -rn example- terraform helm scripts` lists them all. Then follow the [Terraform guide](terraform/readme.md#️-terraform-workflow): one-time prerequisites (state bucket, Workload Identity for CI, DNS zone), then `iam → bootstrap → db`, build and push the image, then `cluster → dns`.

Once deployed:

```bash
scripts/k8r.sh dev                # sets the kubectl context, then opens k9s if installed, else lists deployments, services, ingress and HPA
scripts/k8r.sh dev grafana        # Grafana on http://localhost:3000
python scripts/load_test.py --env dev --host https://<domain> --token <JWT> --duration 60 --concurrency 20
```

Destroy an environment with the `Terraform Destroy` workflow or the commands in the [guide](terraform/readme.md#2-destroy-an-environment): GKE, Cloud SQL and the load balancer are billed while they run.

## License

[MIT](LICENSE)
