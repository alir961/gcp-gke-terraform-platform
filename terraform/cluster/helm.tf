data "google_client_config" "default" {}

provider "helm" {
  kubernetes {
    host                   = google_container_cluster.tasks_cluster.endpoint
    cluster_ca_certificate = base64decode(google_container_cluster.tasks_cluster.master_auth[0].cluster_ca_certificate)
    token                  = data.google_client_config.default.access_token
  }
}

resource "helm_release" "tasks_api" {
  depends_on = [google_container_cluster.tasks_cluster]
  name       = "tasks-api"
  repository = "file://../../helm/tasks-api"
  chart      = "tasks-api"
  namespace  = var.env
 values = [
    file("../../helm/tasks-api/values.${var.env}.yaml")
  ]
  wait             = true
  timeout          = 600
  atomic           = true
  cleanup_on_fail  = true
}

resource "helm_release" "task_redis" {
  depends_on = [helm_release.tasks_api]
  name       = "task-redis"
  repository = "file://../../helm/task-redis"
  chart      = "task-redis"
  namespace  = var.env
  values     = [
    file("../../helm/task-redis/values.${var.env}.yaml")
  ]

  wait             = true
  timeout          = 600
  atomic           = true
  cleanup_on_fail  = true
}
