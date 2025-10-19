data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.tasks_cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.tasks_cluster.master_auth[0].cluster_ca_certificate)
}

resource "kubernetes_namespace" "env" {
  depends_on = [google_container_cluster.tasks_cluster]

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
