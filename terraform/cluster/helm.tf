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
    host                   = google_container_cluster.tasks_cluster.endpoint
    cluster_ca_certificate = base64decode(google_container_cluster.tasks_cluster.master_auth[0].cluster_ca_certificate)
    token                  = data.google_client_config.default.access_token
  }
}

resource "helm_release" "tasks_api" {
  depends_on = [google_container_cluster.tasks_cluster]
  name       = "tasks-api"
  chart      = "../../helm/tasks-api"
  namespace  = var.env
  values = [
    file("../../helm/tasks-api/values.${var.env}.yaml")
  ]
  wait            = false
  timeout         = 300
  atomic          = false
  cleanup_on_fail = false
}

resource "helm_release" "tasks_redis" {
  depends_on = [helm_release.tasks_api]
  name       = "tasks-redis"
  chart      = "../../helm/tasks-redis"
  namespace  = var.env
  values = [
    file("../../helm/tasks-redis/values.${var.env}.yaml")
  ]

  wait            = false
  timeout         = 300
  atomic          = false
  cleanup_on_fail = false
}
