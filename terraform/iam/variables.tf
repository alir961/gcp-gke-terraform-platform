variable "project_id" {
  type        = string
  description = "Cloud project ID"
}

variable "region" {
  type        = string
  description = "Region for resources"
}

variable "professor" {
  type        = string
  description = "User to give view permissions"
}

variable "members" {
  description = "Map keyed by identity type (user, group, serviceAccount, etc.) to maps of principals and their roles"
  type        = map(map(list(string)))
  default     = {}
}

variable "billing_account_id" {
  type        = string
  description = "Billing account ID (format: XXXXXX-XXXXXX-XXXXXX)"
}
