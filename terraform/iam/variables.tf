variable "project_id" {
  type        = string
  description = "Cloud project ID"
}

variable "region" {
  type        = string
  description = "Region for resources"
}

variable "professor" {
  type = string
  description = "User to give view permissions"
}

variable "members" {
  type = map(string)
  description = "Map of users to list of roles"
}

variable "bucket_name" {
  type        = string
  description = "GCS bucket for Terraform state"
}

variable "billing_account_id" {
  type        = string
  description = "Billing account ID (format: XXXXXX-XXXXXX-XXXXXX)"
}