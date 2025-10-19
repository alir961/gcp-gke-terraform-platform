#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT=${1:-dev}
ACTION=${2:-overview}

case "${ENVIRONMENT}" in
  dev)
    PROJECT="example-project-dev"
    ZONE="europe-west9-b"
    NAMESPACE="dev"
    ;;
  prd|prod|production)
    PROJECT="example-project-prd"
    ZONE="europe-west1-b"
    NAMESPACE="prd"
    ;;
  *)
    echo "Usage: $0 [dev|prd] [overview|grafana]"
    exit 1
    ;;
esac

echo ">> Connecting to ${ENVIRONMENT} cluster (project=${PROJECT}, zone=${ZONE})"
gcloud container clusters get-credentials tasks-cluster --zone "${ZONE}" --project "${PROJECT}"
kubectl config set-context --current --namespace="${NAMESPACE}" >/dev/null

if [[ "${ACTION}" == "grafana" ]]; then
  echo ">> Port-forwarding Grafana on http://localhost:3000"
  kubectl -n "${NAMESPACE}-monitoring" port-forward svc/monitoring-grafana 3000:80
  exit 0
fi

if command -v k9s >/dev/null 2>&1; then
  echo ">> Launching k9s (press :q to exit)"
  k9s -n "${NAMESPACE}"
else
  echo ">> k9s not found, showing core resources with kubectl"
  kubectl get deploy,svc,ing -n "${NAMESPACE}"
  kubectl get hpa -n "${NAMESPACE}" || echo "HPA not configured in ${NAMESPACE}"
  kubectl get pods -n "${NAMESPACE}-monitoring"
fi
