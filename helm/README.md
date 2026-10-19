# Helm Charts Overview

This directory regroups the Helm configuration for the platform. Two charts are maintained:

| Chart | Purpose |
|-------|---------|
| `tasks-api` | Deploys the FastAPI application, its Redis cache, ingress, autoscaling rules and Prometheus scrape configuration. |
| `monitoring` | Wraps `kube-prometheus-stack` with environment-specific resource requests. |

## Values Management

`tasks-api` ships with `values.dev.yaml` and `values.prd.yaml` (and `values.dev.example.yaml` for a manual install); `monitoring/values.<env>.yaml` configures the upstream `kube-prometheus-stack` chart. Terraform (`terraform/cluster/helm.tf`) installs both and adds:

- the Cloud SQL host, database and user, read from the `db` state;
- the `tasks-api-secret` Kubernetes secret (`DB_PASS`, `SECRET_KEY`), created by Terraform from Secret Manager, which is why the values files set `secret.create: false`;
- the image repository and the immutable commit-SHA tag built by CI.

To install the chart by hand, let it create the secret instead:

```bash
helm upgrade --install tasks-api helm/tasks-api \
  --namespace dev --create-namespace \
  --values helm/tasks-api/values.dev.example.yaml \
  --set app.db.host=<cloudsql-private-ip> \
  --set secret.create=true \
  --set app.db.password="$APP_DB_PASSWORD" \
  --set app.secretKey="$APP_SECRET_KEY"
```

## Autoscaling & Resources

API pods request 250m CPU / 512 MiB and are limited to 500m / 1 GiB. The HorizontalPodAutoscaler targets 70 % CPU in dev (1–10 replicas) and 60 % in prd (1–15). After a change, run `python scripts/load_test.py --env dev --duration 120 --concurrency 30` and watch the scaling in Grafana (`scripts/k8r.sh dev grafana`).

Pods run as UID 10001 with `runAsNonRoot`, no privilege escalation, all capabilities dropped and the RuntimeDefault seccomp profile.

## Prometheus Integration

`tasks-api` serves `/status` for the liveness, readiness and load-balancer health checks, and Prometheus metrics on `/metrics`. The chart creates a `ServiceMonitor` labelled `release: monitoring`, so the `kube-prometheus-stack` release scrapes it automatically.

## Static Assets

Public static pages (landing page & 404) are rendered from Terraform (`terraform/dns`). No files are stored under `helm/`, but the Ingress definition points the domain to the HTTPS load balancer created by GKE. If you customise the HTML template in Terraform, re-run `terraform apply` on the `dns` module.***
