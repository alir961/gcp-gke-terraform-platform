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

### Plan (PR)
- Workflow : `.github/workflows/terraform-plan.yml`
- Déclencheur : chaque pull request vers `main` (plan dev **et** prod), ou manuel.
- Actions : `terraform fmt` + `terraform validate` (en local sans backend), puis `terraform plan` pour **chaque module** sur l’environnement concerné.
- Authentification : via Workload Identity Federation (actions `google-github-actions/auth@v2`) en récupérant les secrets d’environnement.
- Artefacts : les plans (`tfplan-dev` / `tfplan-prd`) sont publiés pour revue hors ligne.

### Apply (Merges + relance manuelle)
- Workflow : `.github/workflows/terraform-apply.yml`
- Déclencheur automatique : `push` sur `main` → apply **dev** puis **prod** (protéger l’environnement GitHub `prd` avec des reviewers obligatoires pour valider l’apply prod).
- Déclencheur manuel : `Actions → Terraform Apply → Run workflow` (sélectionner `dev` ou `prd` et saisir `DEPLOY` pour rejouer un déploiement).
- Chaîne : plan puis apply du plan exact pour `iam → bootstrap → db`, build + push de l’image API (tag = SHA du commit) dans Artifact Registry, puis `cluster → dns` (le résumé du job affiche chaque plan).

### Destroy (Manuel)
- Workflow : `.github/workflows/terraform-destroy.yml`
- Déclencheur : `Actions → Terraform Destroy → Run workflow`.
- Paramètres : `environment` (`dev` ou `prd`) + confirmation `DESTROY`.
- Paramètre optionnel `destroy_bootstrap` (`false` par défaut) : passer à `true` uniquement si vous souhaitez supprimer le module `bootstrap` (et donc le bucket de state).
- Chaîne : destroy `dns → cluster → db → iam` (et `bootstrap` uniquement si `destroy_bootstrap=true`), avec authentification OIDC identique aux autres workflows.

### Secrets GitHub à définir (environnements)
| Secret | Valeur |
|--------|--------|
| `GCP_PROJECT_DEV` / `PRD` | ID projet GCP (`example-project-dev`, `example-project-prd`) |
| `GCP_SERVICE_ACCOUNT_DEV` / `PRD` | Comptes de service GitHub Actions |
| `GCP_WORKLOAD_IDENTITY_PROVIDER_DEV` / `PRD` | Identifiants complets des providers OIDC |
| `TF_BUCKET_DEV` / `PRD` | Buckets de state |
| `TF_BILLING_ACCOUNT` | ID du compte de facturation, format `XXXXXX-XXXXXX-XXXXXX` (optionnel mais recommandé) |
| `TF_VAR_db_password` | Mot de passe Postgres injecté dans Secret Manager & Kubernetes |
| `TF_VAR_app_secret_key` | Clé secrète FastAPI (JWT) synchronisée via Secret Manager |

> ℹ️ **Documentation soutenance** : préciser que prod est déployé après merge sur `main` (avec validation éventuelle côté environnement GitHub) et qu’un workflow manuel existe pour rejouer un apply si besoin.
> ⚠️ **Limites IAM GCP** : les rôles `roles/owner` et `roles/billing.admin` se gèrent hors Terraform (console GCP / commande `gcloud`). GCP impose une invitation manuelle pour les owners et n’autorise pas `roles/billing.*` au niveau projet. L’équipe conserve donc des rôles techniques (`roles/editor`, `container.admin`, `dns.admin`, etc.) et les owners existants ne sont pas pilotés par Terraform.
> ⚠️ **Réseau Cloud SQL** : tant que l’instance PostgreSQL existe, la connexion Service Networking liée au VPC historique `vpc-network` ne peut pas être supprimée. Les `tfvars` dev restent donc pointés sur ce réseau. Toute migration vers `iac-dev-vpc` devra recréer la base.

---

## ⚙️ Terraform Workflow

All commands run from the repository root. Each stack has its own backend file
(`terraform/<stack>/backends/backend-<env>.hcl`) and tfvars file
(`terraform/environments/<env>/<stack>.tfvars`). Copy the `*.tfvars.example`
files and replace the placeholders before the first run.

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
