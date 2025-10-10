variable "gcp_project" {
  type        = string
  description = "GCP Project ID"
}

variable "gcp_region" {
  type        = string
  description = "GCP region for resources"
  default     = "us-central1"
}

variable "db_password" {
  type        = string
  description = "Password for PostgreSQL user"
  sensitive   = true
}
