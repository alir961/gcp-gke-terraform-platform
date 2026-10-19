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
- Chaîne : apply `bootstrap → iam → db → cluster → dns` pour l’environnement choisi.

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

### 1. Initialize Terraform

Each environment (Dev/Prod) and module must be initialized separately.

#### 🧱 Bootstrap (VPC & Bucket)
```bash
# Dev
cd bootstrap
terraform init -backend-config=./backends/dev.config  

# Prod
cd bootstrap
terraform init -backend-config=./backends/prd.config  
```

#### ☸️ Kubernetes Cluster
```bash
# Dev
cd cluster
terraform init -var-file=dev.tfvars

# Prod
cd cluster
terraform init -var-file=prd.tfvars
```

#### 🔐 IAM Settings
```bash
# Dev
cd iam 
terraform init -backend-config=./backends/dev.config  

# Prod
cd iam 
terraform init -backend-config=./backends/prd.config  
```

#### 🗄️ Managed DB Instance
```bash
# Dev
cd db 
terraform init -var-file=dev.tfvars

# Prod
cd db 
terraform init -var-file=prd.tfvars
```

---

### 2. Plan Changes

Use `terraform plan` to preview changes before applying.

#### Example:
```bash
cd cluster
terraform plan -var-file=dev.tfvars
```

Repeat for each environment and module as needed:
- `bootstrap`
- `cluster`
- `iam`
- `db`

---

### 3. Apply Changes

Apply the changes to create or update resources.

```bash
terraform apply -var-file=dev.tfvars
```

Once confirmed, Terraform will provision all required resources.

> 💡 **Tip:** Always validate changes with `terraform plan` before applying in production.

---

### 4. Destroy Infrastructure

To clean up resources and avoid unnecessary costs:

```bash
terraform destroy -var-file=dev.tfvars
```

Repeat for each module as needed.

---

## 🧰 Additional Tips

- Use separate **backend configs** for each environment to isolate state files.
- Keep all `.tfvars` and `.config` files secure — never commit credentials or sensitive data.
- Use `terraform fmt` and `terraform validate` before committing.
- Consider using **Terraform Cloud** or **remote state locking** for team collaboration.

---

## ✅ Example Full Workflow (Dev Environment)

```bash
# Bootstrap resources
cd bootstrap
terraform init -backend-config=./backends/dev.config
terraform apply -var-file=dev.tfvars

# Create IAM roles
cd ../iam
terraform init -backend-config=./backends/dev.config
terraform apply -var-file=dev.tfvars

# Deploy Cluster
cd ../cluster
terraform init -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars

# Create DB
cd ../db
terraform init -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

---

## 📦 Useful Commands

| Command | Description |
|----------|-------------|
| `terraform fmt` | Format Terraform files for readability |
| `terraform validate` | Validate configuration for syntax errors |
| `terraform show` | Display current state or plan |
| `terraform output` | Show output values after apply |
| `terraform state list` | List all tracked resources |
| `terraform state rm <resource>` | Remove specific resource from state |

---

## 🚀 Deployment Notes

- Always **run bootstrap first** (to create VPC and backend buckets).
- Ensure **service accounts** used by Terraform have sufficient permissions.
- Prefer **environment-specific variables** (`dev.tfvars`, `prd.tfvars`) for configuration isolation.

---
