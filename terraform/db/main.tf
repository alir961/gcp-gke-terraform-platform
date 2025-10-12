resource "google_sql_database_instance" "tasks_postgres" {
  name             = "tasks-db"
  database_version = "POSTGRES_16"
  region           = var.gcp_region

  settings {
    tier    = "db-f1-micro"
    edition = "ENTERPRISE"

    backup_configuration {
      enabled = true
    }

    ip_configuration {
      ipv4_enabled = true
    }
  }
}

resource "google_sql_user" "tasks_user" {
  name     = "tasks_user"
  instance = google_sql_database_instance.tasks_postgres.name
  password = var.db_password
}

resource "google_sql_database" "tasks_db" {
  name     = "tasks_db"
  instance = google_sql_database_instance.tasks_postgres.name
}
