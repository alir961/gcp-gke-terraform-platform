# gcloud container clusters get-credentials tasks-cluster --zone <ZONE> --project <PROJECT> avant terraform apply
# helm package tasks-redis & helm package tasks-api avant terraform apply à /helm

data "google_client_config" "default" {}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "gke_${var.project_id}_${var.zone}_tasks-cluster"
}

resource "kubernetes_namespace" "env" {
  metadata {
    name = var.env
  }
}

provider "helm" {
  kubernetes = {
    config_path    = "~/.kube/config"
    config_context = "gke_${var.project_id}_${var.zone}_tasks-cluster"
  }
}

resource "helm_release" "tasks_api" {
  name      = "tasks-api"
  chart     = "${path.module}/../../helm/tasks-api-0.1.0.tgz"
  namespace = kubernetes_namespace.env.metadata[0].name
  values    = [file("${path.module}/../../helm/tasks-api/values.${var.env}.yaml")]

  wait            = true
  timeout         = 600
  atomic          = true
  cleanup_on_fail = true

  depends_on = [kubernetes_namespace.env]
}

resource "helm_release" "tasks_redis" {
  name      = "tasks-redis"
  chart     = "${path.module}/../../helm/tasks-redis-0.1.0.tgz"
  namespace = kubernetes_namespace.env.metadata[0].name
  values    = [file("${path.module}/../../helm/tasks-redis/values.${var.env}.yaml")]

  wait            = true
  timeout         = 600
  atomic          = true
  cleanup_on_fail = true

  depends_on = [kubernetes_namespace.env]
}
