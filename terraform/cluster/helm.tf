data "google_client_config" "default" {}

provider "helm" {
  kubernetes = {
    host                   = google_container_cluster.tasks_cluster.endpoint
    cluster_ca_certificate = base64decode(google_container_cluster.tasks_cluster.master_auth[0].cluster_ca_certificate)
    token                  = data.google_client_config.default.access_token
  }
}

resource "helm_release" "tasks_api" {
  name      = "tasks-api"
  chart     = "${path.module}/../../helm/tasks-api-0.1.0.tgz"
  namespace = var.env
  values    = [file("${path.module}/../../helm/tasks-api/values.${var.env}.yaml")]

  wait            = true
  timeout         = 600
  atomic          = true
  cleanup_on_fail = true

  depends_on = [google_container_cluster.tasks_cluster]
}

resource "helm_release" "tasks_redis" {
  name      = "tasks_redis"
  chart     = "${path.module}/../../helm/tasks-redis-0.1.0.tgz"
  namespace = var.env
  values    = [file("${path.module}/../../helm/tasks-redis/values.${var.env}.yaml")]

  wait            = true
  timeout         = 600
  atomic          = true
  cleanup_on_fail = true

  depends_on = [google_container_cluster.tasks_cluster]
}
