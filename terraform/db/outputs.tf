output "db_host" {
  value = google_sql_database_instance.tasks_postgres.public_ip_address
}

output "db_name" {
  value = google_sql_database.tasks_db.name
}

output "db_user" {
  value = google_sql_user.tasks_user.name
}

output "db_password" {
  value     = var.db_password
  sensitive = true
}
