output "db_private_ip" {
  description = "Private IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.tasks_postgres.private_ip_address
}

output "db_name" {
  description = "Database name"
  value       = google_sql_database.tasks_db.name
}

output "db_user" {
  description = "Database user name"
  value       = google_sql_user.tasks_user.name
}

output "db_password" {
  description = "Database user password"
  value       = var.db_password
  sensitive   = true
}
