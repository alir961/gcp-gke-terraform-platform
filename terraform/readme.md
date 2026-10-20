# Terraform Infrastructure Deployment Guide

This document provides a detailed step-by-step guide for managing **development** and **production** environments using **Terraform**.  
It covers workflows for initialization, planning, applying, and destroying infrastructure components across multiple modules.

---

## 🏗️ Infrastructure Modules Overview

| Module | Purpose |
|--------|----------|
| `bootstrap` | Creates foundational resources like **VPC**, **subnets**, and **Cloud Storage buckets** for state management. |
| `cluster` | Deploys **Kubernetes (GKE)** clusters and node pools. |
| `iam` | Manages **Identity and Access Management (IAM)** roles, service accounts, and permissions. |
| `db` | Provisions **managed PostgreSQL** database instances. |
| `dns` | Points the API record at the ingress IP and hosts the static landing page. |

---

## 🤖 GitHub Actions Automation

### Plan (pull request)
- Workflow: `.github/workflows/terraform-plan.yml`
- Trigger: every pull request to `main` (plans dev **and** prd), or manual.
- Steps: API tests, `terraform fmt` and `terraform validate` (locally, without a backend), then `terraform plan` for **every stack** of each environment.
- Authentication: Workload Identity Federation (`google-github-actions/auth@v2`) with the environment secrets below.
- Artifacts: the plans (`tfplan-dev` / `tfplan-prd`) are uploaded for offline review.

### Apply (merge, or manual re-run)
- Workflow: `.github/workflows/terraform-apply.yml`
- Automatic trigger: `push` to `main` → apply **dev**, then **prd** (protect the GitHub environment `prd` with required reviewers so the production apply waits for approval).
- Manual trigger: `Actions → Terraform Apply → Run workflow`, pick `dev` or `prd` and type `DEPLOY` to re-run a deployment.
- Chain: plan, then apply that exact plan, for `iam → bootstrap → db`; build and push the API image (tagged with the commit SHA) to Artifact Registry; then `cluster → dns`. The job summary shows every plan.

### Destroy (manual)
- Workflow: `.github/workflows/terraform-destroy.yml`
- Trigger: `Actions → Terraform Destroy → Run workflow`.
- Inputs: `environment` (`dev` or `prd`) and the confirmation `DESTROY`.
- Optional input `destroy_bootstrap` (`false` by default): set it to `true` only to also delete the `bootstrap` stack, and with it the state bucket.
- Chain: destroy `dns → cluster → db → iam` (and `bootstrap` only when `destroy_bootstrap=true`), with the same OIDC authentication as the other workflows.

### GitHub secrets (per environment)
| Secret | Value |
|--------|-------|
| `GCP_PROJECT_DEV` / `PRD` | GCP project ID (`example-project-dev`, `example-project-prd`) |
| `GCP_SERVICE_ACCOUNT_DEV` / `PRD` | GitHub Actions service accounts |
| `GCP_WORKLOAD_IDENTITY_PROVIDER_DEV` / `PRD` | Full resource names of the OIDC providers |
| `TF_BUCKET_DEV` / `PRD` | State buckets |
| `TF_BILLING_ACCOUNT` | Billing account ID, format `XXXXXX-XXXXXX-XXXXXX` (optional but recommended) |
| `TF_VAR_db_password` | PostgreSQL password, stored in Secret Manager and Kubernetes |
| `TF_VAR_app_secret_key` | FastAPI JWT signing key, synced through Secret Manager |

Also set the repository variable `GCP_DEPLOY_ENABLED=true`; without it the GCP jobs are skipped.

> ⚠️ **GCP IAM limits**: `roles/owner` and `roles/billing.admin` are managed outside Terraform (GCP console or `gcloud`). GCP requires a manual invitation for owners and does not allow `roles/billing.*` at project level. The team therefore keeps technical roles (`roles/editor`, `container.admin`, `dns.admin`, etc.), and existing owners are not managed by Terraform.
> ⚠️ **Cloud SQL network**: dev and prd use the VPC and subnet created by `bootstrap` (`iac-<env>-vpc`, `iac-<env>-vpc-subnet`), in the same region as the cluster. An existing PostgreSQL instance stays bound to its VPC through the Service Networking connection: changing `vpc_network` afterwards means recreating the database.

---

## ⚙️ Terraform Workflow

All commands run from the repository root, in bash (Linux, macOS, or WSL 2 on Windows). Each stack has its own backend file
(`terraform/<stack>/backends/backend-<env>.hcl`) and tfvars file
(`terraform/environments/<env>/<stack>.tfvars`). The committed tfvars and backend files are complete but use
placeholder values (`example-project-dev`, `example-project-prd`, `example-project.com`...): replace them with
your own before the first run (see [Deploy to GCP](../README.md#deploy-to-gcp)). The `*.tfvars.example` files
are shorter templates and do not list every variable.

Authenticate first: `gcloud auth login` and `gcloud auth application-default login` (Terraform uses the
application-default credentials).

### 0. One-time prerequisites (per environment)

These are not managed by Terraform:

1. **GCP project** with billing enabled, and a **Cloud DNS managed zone** for your domain (`dns_managed_zone`).
2. **State bucket.** Every stack, including `bootstrap`, stores its state in the bucket that `bootstrap` manages, so create it first and import it:
   ```bash
   gcloud storage buckets create gs://<state-bucket> --project <project> --location EU --uniform-bucket-level-access
   terraform -chdir=terraform/bootstrap init -backend-config=backends/backend-dev.hcl
   terraform -chdir=terraform/bootstrap import -var-file=../environments/dev/bootstrap.tfvars \
     google_storage_bucket.state_bucket <state-bucket>
   ```
3. **CI identity** (only for GitHub Actions): a service account for the workflows, a Workload Identity pool and an OIDC provider for `token.actions.githubusercontent.com` restricted to this repository, and `roles/iam.workloadIdentityUser` for that provider on the service account. Give the account `roles/resourcemanager.projectIamAdmin` once by hand; the `iam` stack grants the rest. Store the values as GitHub environment secrets (table above) and set the repository variable `GCP_DEPLOY_ENABLED=true`.
4. **GitHub environments** `dev` and `prd`. Add required reviewers on `prd` so production applies wait for approval.
5. If an Artifact Registry repository `tasks-registry` already exists in the project, import it once:
   ```bash
   terraform -chdir=terraform/bootstrap import -var-file=../environments/dev/bootstrap.tfvars \
     google_artifact_registry_repository.tasks projects/<project>/locations/<region>/repositories/tasks-registry
   ```

### 1. Apply an environment

Order matters: `iam` grants the CI account the roles the other stacks need, `cluster` reads the `bootstrap` and `db` states, and `dns` reads the ingress IP created by `cluster`.

```bash
ENV=dev
export TF_VAR_db_password='<postgres password>'      # db stack
export TF_VAR_app_secret_key='<JWT signing key>'     # db stack

apply() {
  terraform -chdir=terraform/$1 init -backend-config=backends/backend-$ENV.hcl
  terraform -chdir=terraform/$1 plan -var-file=../environments/$ENV/$1.tfvars -out=tfplan-$ENV
  terraform -chdir=terraform/$1 apply tfplan-$ENV
}

apply iam; apply bootstrap; apply db

# Build and push the API image, then deploy that exact tag
IMAGE=$(terraform -chdir=terraform/bootstrap output -raw image_repository)
gcloud auth configure-docker "${IMAGE%%/*}"
docker build -t "$IMAGE:$(git rev-parse HEAD)" app && docker push "$IMAGE:$(git rev-parse HEAD)"
export TF_VAR_image_repository=$IMAGE TF_VAR_image_tag=$(git rev-parse HEAD)

apply cluster; apply dns
```

GitHub Actions does exactly this on every push to `main` (`scripts/tf-plan-apply.sh`).
When planning `cluster` by hand without `TF_VAR_image_tag`, the plan shows the image falling back to the tag in `helm/tasks-api/values.<env>.yaml`; set it to the deployed SHA to get a clean plan.

### 2. Destroy an environment

Reverse order, keeping `bootstrap` (it holds the state bucket and the image registry) unless you really want everything gone:

```bash
for stack in dns cluster db iam; do
  terraform -chdir=terraform/$stack init -backend-config=backends/backend-$ENV.hcl
  terraform -chdir=terraform/$stack destroy -var-file=../environments/$ENV/$stack.tfvars
done
```

The `Terraform Destroy` workflow does the same and also removes stuck namespaces and the Cloud SQL user and database.

### 3. Upgrade notes

- **tasks-api Deployment selector**: the API selector now includes `app.kubernetes.io/component: api`. Selectors are immutable, so on an existing cluster run `kubectl delete deployment tasks-api -n <env>` once before the next apply.
- **GKE node service account**: nodes now run as `tasks-gke-nodes`; the first apply after this change recreates the node pool.
- **State bucket rename**: handled by a `moved` block, no manual step.

## 📦 Useful Commands

| Command | Description |
|----------|-------------|
| `terraform fmt -recursive terraform` | Format every stack |
| `terraform -chdir=terraform/<stack> validate` | Validate a stack (after `init -backend=false`) |
| `terraform -chdir=terraform/<stack> output` | Show a stack's outputs |
| `terraform -chdir=terraform/<stack> state list` | List tracked resources |
| `pre-commit run --all-files` | ruff, ruff-format, terraform fmt and validate |
