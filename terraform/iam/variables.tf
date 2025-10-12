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
  type        = map(list(string))
  description = "Map of user emails to the list of project roles they must receive"
}

variable "billing_account_id" {
  type        = string
  description = "Billing account ID (format: XXXXXX-XXXXXX-XXXXXX)"
}
