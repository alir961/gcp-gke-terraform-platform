data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.tasks_cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.tasks_cluster.master_auth[0].cluster_ca_certificate)
}

data "google_secret_manager_secret_version" "db_password" {
  project = var.project_id
  secret  = "tasks-db-password"
  version = "latest"
}

data "google_secret_manager_secret_version" "app_secret_key" {
  project = var.project_id
  secret  = "tasks-api-secret-key"
  version = "latest"
}

resource "kubernetes_secret" "tasks_api" {
  depends_on = [kubernetes_namespace.env]

  metadata {
    name      = "tasks-api-secret"
    namespace = var.env
    labels = {
      "app.kubernetes.io/name"       = "tasks-api"
      "app.kubernetes.io/instance"   = "tasks-api"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  data = {
    DB_PASS    = base64encode(data.google_secret_manager_secret_version.db_password.secret_data)
    SECRET_KEY = base64encode(data.google_secret_manager_secret_version.app_secret_key.secret_data)
  }
}

resource "kubernetes_namespace" "env" {
  depends_on = [google_container_cluster.tasks_cluster]

  metadata {
    name = var.env
  }

  timeouts {
    delete = "15m"
  }
}

resource "kubernetes_namespace" "monitoring" {
  depends_on = [google_container_cluster.tasks_cluster]

  metadata {
    name = "${var.env}-monitoring"
  }

  timeouts {
    delete = "15m"
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
  depends_on = [google_container_cluster.tasks_cluster, google_compute_global_address.ingress_ip]
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

resource "helm_release" "monitoring" {
  depends_on = [google_container_cluster.tasks_cluster, kubernetes_namespace.monitoring]
  name       = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "78.3.2"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  values = [
    file("../../helm/monitoring/values.${var.env}.yaml")
  ]

  timeout = 600
}
