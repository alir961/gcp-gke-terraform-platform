variable "gcp_project" {
  type        = string
  description = "GCP Project ID"
}

variable "gcp_region" {
  type        = string
  description = "Region for the Cloud SQL instance"
}

variable "vpc_network" {
  description = "Full path of the VPC network"
  type        = string
}

variable "db_password" {
  description = "Initial database password"
  type        = string
  sensitive   = true
}
