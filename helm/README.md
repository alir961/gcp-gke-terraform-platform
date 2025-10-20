# Helm Charts Overview

This directory regroups the Helm configuration for the platform. Two charts are maintained:

| Chart | Purpose |
|-------|---------|
| `tasks-api` | Deploys the FastAPI application, its Redis cache, ingress, autoscaling rules and Prometheus scrape configuration. |
| `monitoring` | Wraps `kube-prometheus-stack` with environment-specific resource requests. |

## Values Management

Each chart ships with `values.dev.yaml` and `values.prd.yaml`. Terraform loads the matching file at deploy time and overrides the sensitive fields:

- `secret.create` / `app.db.password` / `app.secretKey` are filled automatically with data read from Secret Manager.
- `serviceAccount.create` & `rbac.create` are forced to `true` to let the chart manage the Kubernetes service account.

If you need to test the chart manually, provide the missing values by copying `values.dev.example.yaml` and exporting:

```bash
export APP_DB_PASSWORD=...
export APP_SECRET_KEY=...
helm upgrade --install tasks-api ./tasks-api \
  --namespace dev \
  --values values.dev.yaml \
  --set secret.create=true \
  --set app.db.password=$APP_DB_PASSWORD \
  --set app.secretKey=$APP_SECRET_KEY
```

## Autoscaling & Resources

Resource requests now follow the teacher guidance (1 vCPU / 1 GiB per pod, limits set to 2 vCPU / 2 GiB). The HorizontalPodAutoscaler still targets 60–70 % CPU. After each change, run `scripts/load_test.py --env dev --duration 120 --concurrency 30` and observe the metrics in Grafana (`scripts/k8r.sh dev grafana`) to demonstrate the scaling behaviour.

## Prometheus Integration

`tasks-api` exposes `/status` for readiness/liveness and metrics. The chart wires a `ServiceMonitor` labelled `release: monitoring` so the `kube-prometheus-stack` release scrapes it automatically.

## Static Assets

Public static pages (landing page & 404) are rendered from Terraform (`terraform/dns`). No files are stored under `helm/`, but the Ingress definition points the domain to the HTTPS load balancer created by GKE. If you customise the HTML template in Terraform, re-run `terraform apply` on the `dns` module.***
