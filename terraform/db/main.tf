locals {
  private_ip_name = var.gcp_project == "example-project-prd" ? "tasks-db-private-ip-prd" : "tasks-db-private-ip"
}

resource "google_project_service" "service_networking" {
  service = "servicenetworking.googleapis.com"
}

resource "google_project_service" "secret_manager" {
  service = "secretmanager.googleapis.com"
}

resource "google_compute_global_address" "private_ip_address" {
  name          = local.private_ip_name
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.vpc_network
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.vpc_network
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]

  depends_on = [
    google_project_service.service_networking
  ]
}

resource "google_secret_manager_secret" "db_password_secret" {
  secret_id = "tasks-db-password"

  replication {
    auto {}
  }

  depends_on = [
    google_project_service.secret_manager
  ]
}

resource "google_secret_manager_secret_version" "db_password_secret_version" {
  secret      = google_secret_manager_secret.db_password_secret.id
  secret_data = var.db_password

  depends_on = [
    google_project_service.secret_manager
  ]
}

resource "google_secret_manager_secret" "app_secret_key" {
  secret_id = "tasks-api-secret-key"

  replication {
    auto {}
  }

  depends_on = [
    google_project_service.secret_manager
  ]
}

resource "google_secret_manager_secret_version" "app_secret_key_version" {
  secret      = google_secret_manager_secret.app_secret_key.id
  secret_data = var.app_secret_key

  depends_on = [
    google_project_service.secret_manager
  ]
}

resource "google_sql_database_instance" "tasks_postgres" {
  name                = "tasks-db"
  database_version    = "POSTGRES_16"
  region              = var.gcp_region
  deletion_protection = false

  depends_on = [
    google_service_networking_connection.private_vpc_connection
  ]

  settings {
    tier    = "db-f1-micro"
    edition = "ENTERPRISE"

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.vpc_network
    }

    backup_configuration {
      enabled = true
    }
  }
}

resource "google_sql_user" "tasks_user" {
  name     = "tasks_user"
  instance = google_sql_database_instance.tasks_postgres.name
  password = var.db_password

  depends_on = [
    google_sql_database.tasks_db
  ]
}

resource "google_sql_database" "tasks_db" {
  name     = "tasks_db"
  instance = google_sql_database_instance.tasks_postgres.name
}
