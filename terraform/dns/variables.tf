variable "project_id" {
  description = "GCP project hosting the Cloud DNS zone"
  type        = string
}

variable "dns_managed_zone" {
  description = "Existing Cloud DNS managed zone name"
  type        = string
}

variable "record_name" {
  description = "Fully-qualified domain name for the ingress record"
  type        = string
}

variable "record_type" {
  description = "DNS record type"
  type        = string
  default     = "A"
}

variable "ttl" {
  description = "DNS record TTL in seconds"
  type        = number
  default     = 60
}

variable "cluster_state_bucket" {
  description = "GCS bucket containing the cluster Terraform state"
  type        = string
}

variable "cluster_state_prefix" {
  description = "Prefix to locate the cluster Terraform state"
  type        = string
}

variable "create_static_site" {
  description = "Whether to create a Cloud Storage website bucket for the domain"
  type        = bool
  default     = false
}

variable "static_site_bucket_name" {
  description = "Optional override for the static site bucket name"
  type        = string
  default     = ""
}

variable "bucket_location" {
  description = "Location of the static site bucket"
  type        = string
  default     = "EU"
}

variable "website_main_page" {
  description = "Main page filename for the static website"
  type        = string
  default     = "index.html"
}

variable "website_not_found_page" {
  description = "404 page filename for the static website"
  type        = string
  default     = "404.html"
}

variable "api_http_endpoint" {
  description = "Public URL of the API exposed via Ingress (used in the static page)"
  type        = string
  default     = ""
}
